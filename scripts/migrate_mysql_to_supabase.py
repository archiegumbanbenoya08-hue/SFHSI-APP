#!/usr/bin/env python3
"""Copy the active SCMCIES MySQL schema into an empty local Supabase database."""

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
from psycopg.types.json import Jsonb

ROOT = Path(__file__).resolve().parents[1]
TABLES: dict[str, tuple[str, ...]] = {
    "admin": ("id", "email", "name", "password_hash", "created_at"),
    "parent": ("id", "email", "password_hash", "name", "created_at"),
    "student": (
        "id",
        "student_id",
        "first_name",
        "last_name",
        "grade_level",
        "section",
        "parent_id",
        "parent_email",
        "face_encoding",
        "image_path",
        "status",
        "created_at",
    ),
    "entry_exit_log": (
        "id",
        "student_id",
        "event_type",
        "timestamp",
        "location",
        "confidence_score",
    ),
    "activity_log": (
        "id",
        "actor_role",
        "actor_id",
        "actor_email",
        "action",
        "entity_type",
        "entity_id",
        "parent_id",
        "details",
        "created_at",
    ),
}


def load_configuration() -> None:
    load_dotenv(ROOT / "backend-node" / ".env")
    load_dotenv(ROOT / "backend-fastapi" / ".env")


def source_connection() -> mysql.connector.MySQLConnection:
    return mysql.connector.connect(
        host=os.getenv("SOURCE_DB_HOST", os.getenv("DB_HOST", "127.0.0.1")),
        port=int(os.getenv("SOURCE_DB_PORT", os.getenv("DB_PORT", "3306"))),
        user=os.getenv("SOURCE_DB_USER", os.getenv("DB_USER", "root")),
        password=os.getenv("SOURCE_DB_PASSWORD", os.getenv("DB_PASSWORD", "")),
        database=os.getenv("SOURCE_DB_NAME", os.getenv("DB_NAME", "scmcies_db")),
        connection_timeout=5,
    )


def face_vector(value: Any) -> str | None:
    if not value:
        return None
    try:
        encoding = json.loads(value)
    except (TypeError, json.JSONDecodeError):
        return None
    if (
        not isinstance(encoding, list)
        or len(encoding) != 128
        or not all(
            isinstance(item, (int, float))
            and not isinstance(item, bool)
            and math.isfinite(item)
            for item in encoding
        )
    ):
        return None
    return "[" + ",".join(str(float(item)) for item in encoding) + "]"


def check_empty_target(connection: psycopg.Connection[Any]) -> None:
    for table in TABLES:
        row = connection.execute(f"SELECT COUNT(*) AS count FROM {table}").fetchone()
        if row["count"]:
            raise RuntimeError(
                f"Target table {table} is not empty. Refusing to merge or overwrite rows."
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Copy rows. Without this flag, only source and target row counts are shown.",
    )
    args = parser.parse_args()
    load_configuration()

    database_url = os.getenv("DATABASE_URL", "").strip()
    if not database_url:
        parser.error("Set DATABASE_URL in backend-fastapi/.env or the environment.")

    source = None
    target = None
    try:
        source = source_connection()
        source_cursor = source.cursor(dictionary=True)
        source_cursor.execute("SHOW TABLES")
        source_tables = {next(iter(row.values())) for row in source_cursor.fetchall()}

        missing_tables = [name for name in TABLES if name not in source_tables]
        if missing_tables:
            raise RuntimeError(
                "The source MySQL database is missing required tables: "
                + ", ".join(missing_tables)
            )

        source_counts: dict[str, int] = {}
        for table, columns in TABLES.items():
            source_cursor.execute(f"SELECT COUNT(*) AS count FROM `{table}`")
            source_counts[table] = source_cursor.fetchone()["count"]
            print(f"MySQL {table}: {source_counts[table]} rows")

        target = psycopg.connect(
            database_url,
            connect_timeout=5,
            autocommit=True,
            row_factory=dict_row,
        )
        check_empty_target(target)
        if not args.apply:
            print("Dry run only. Re-run with --apply to copy into the empty Supabase database.")
            return 0

        with target.transaction():
            target_cursor = target.cursor()
            for table, columns in TABLES.items():
                column_list = ", ".join(f"`{column}`" for column in columns)
                fields = list(columns)
                if table == "student":
                    fields.append("face_embedding")
                placeholders = ["%s"] * len(fields)
                if table == "student":
                    placeholders[-1] = "%s::extensions.vector"
                placeholder_list = ", ".join(placeholders)
                target_columns = ", ".join(fields)
                statement = (
                    f"INSERT INTO {table} ({target_columns}) VALUES ({placeholder_list})"
                )
                source_cursor.execute(f"SELECT {column_list} FROM `{table}` ORDER BY id")
                while batch := source_cursor.fetchmany(500):
                    values = []
                    for row in batch:
                        row_values = [row[column] for column in columns]
                        if table == "activity_log":
                            details = row["details"]
                            if isinstance(details, str):
                                details = json.loads(details)
                            row_values[8] = Jsonb(details or {})
                        if table == "student":
                            row_values.append(face_vector(row["face_encoding"]))
                        values.append(row_values)
                    target_cursor.executemany(statement, values)
                if source_counts[table]:
                    target.execute(
                        f"""
                        SELECT setval(
                            pg_get_serial_sequence('{table}', 'id'),
                            (SELECT MAX(id) FROM {table})
                        )
                        """
                    )
                print(f"Copied {source_counts[table]} rows to {table}")
            target_cursor.close()
        source_cursor.close()

        print("Migration completed. The MySQL source was not modified.")
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
