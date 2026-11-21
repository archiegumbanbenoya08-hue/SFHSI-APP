#!/usr/bin/env python3
"""Copy the legacy SCMCIES MySQL database into the isolated Supabase schema."""

import argparse
import json
import math
import os
from pathlib import Path
from typing import Any

import mysql.connector
import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

ROOT = Path(__file__).resolve().parents[1]
TABLES: dict[str, tuple[str, ...]] = {
    "users": ("id", "email", "password", "name", "user_type", "created_at"),
    "students": (
        "id",
        "student_id",
        "name",
        "grade",
        "parent_emails",
        "face_data",
        "created_at",
    ),
}


def load_configuration() -> None:
    load_dotenv(ROOT / "backend-node" / ".env")


def source_connection() -> mysql.connector.MySQLConnection:
    return mysql.connector.connect(
        host=os.getenv("SOURCE_DB_HOST", "127.0.0.1"),
        port=int(os.getenv("SOURCE_DB_PORT", "3307")),
        user=os.getenv("SOURCE_DB_USER", "root"),
        password=os.getenv("SOURCE_DB_PASSWORD", ""),
        database=os.getenv("SOURCE_DB_NAME", "scmcies"),
        connection_timeout=5,
    )


def face_vector(value: Any) -> str | None:
    if not value:
        return None
    try:
        embedding = json.loads(value)
    except (TypeError, json.JSONDecodeError):
        return None
    if (
        not isinstance(embedding, list)
        or len(embedding) != 128
        or not all(
            isinstance(item, (int, float))
            and not isinstance(item, bool)
            and math.isfinite(item)
            for item in embedding
        )
    ):
        return None
    return "[" + ",".join(str(float(item)) for item in embedding) + "]"


def check_empty_target(connection: psycopg.Connection[Any]) -> None:
    for table in TABLES:
        row = connection.execute(
            f"SELECT COUNT(*) AS count FROM legacy_scmcies.{table}"
        ).fetchone()
        if row["count"]:
            raise RuntimeError(
                f"Target table legacy_scmcies.{table} is not empty. "
                "Refusing to merge or overwrite rows."
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Copy rows. Without this flag, only counts and target state are checked.",
    )
    args = parser.parse_args()
    load_configuration()

    database_url = os.getenv("DATABASE_URL", "").strip()
    if not database_url:
        parser.error("Set DATABASE_URL in backend-node/.env or the environment.")

    source = None
    target = None
    try:
        source = source_connection()
        source_cursor = source.cursor(dictionary=True)
        source_counts: dict[str, int] = {}
        source_rows: dict[str, list[dict[str, Any]]] = {}
        for table, columns in TABLES.items():
            column_list = ", ".join(f"`{column}`" for column in columns)
            source_cursor.execute(f"SELECT {column_list} FROM `{table}` ORDER BY id")
            source_rows[table] = source_cursor.fetchall()
            source_counts[table] = len(source_rows[table])
            print(f"MySQL scmcies.{table}: {source_counts[table]} rows")

        target = psycopg.connect(
            database_url,
            connect_timeout=5,
            autocommit=True,
            row_factory=dict_row,
        )
        check_empty_target(target)
        if not args.apply:
            print(
                "Dry run only. Re-run with --apply to copy into the empty "
                "legacy_scmcies schema."
            )
            return 0

        with target.transaction():
            target_cursor = target.cursor()
            for table, columns in TABLES.items():
                fields = list(columns)
                if table == "students":
                    fields.append("face_embedding")
                placeholders = ["%s"] * len(fields)
                if table == "students":
                    placeholders[-1] = "%s::extensions.vector"
                statement = (
                    f"INSERT INTO legacy_scmcies.{table} ({', '.join(fields)}) "
                    f"VALUES ({', '.join(placeholders)})"
                )
                values = []
                for row in source_rows[table]:
                    row_values = [row[column] for column in columns]
                    if table == "students":
                        row_values.append(face_vector(row["face_data"]))
                    values.append(row_values)
                if values:
                    target_cursor.executemany(statement, values)
                    target.execute(
                        f"""
                        SELECT setval(
                            pg_get_serial_sequence('legacy_scmcies.{table}', 'id'),
                            (SELECT MAX(id) FROM legacy_scmcies.{table})
                        )
                        """
                    )
                print(f"Copied {source_counts[table]} rows to legacy_scmcies.{table}")
            target_cursor.close()

            for table, expected_count in source_counts.items():
                row = target.execute(
                    f"SELECT COUNT(*) AS count FROM legacy_scmcies.{table}"
                ).fetchone()
                if row["count"] != expected_count:
                    raise RuntimeError(
                        f"Row-count verification failed for {table}: "
                        f"expected {expected_count}, got {row['count']}."
                    )

        source_cursor.close()
        print("Migration completed and row counts verified. The source copy was not modified.")
        return 0
    except (mysql.connector.Error, psycopg.Error, RuntimeError, ValueError) as error:
        print(f"Migration failed: {error}")
        return 1
    finally:
        if source is not None:
            source.close()
        if target is not None:
            target.close()


if __name__ == "__main__":
    raise SystemExit(main())
