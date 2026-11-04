import json
import logging
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Optional

import bcrypt
import jwt
import mysql.connector
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

load_dotenv(Path(__file__).parent / ".env")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="SCMCIES API")
origins = {
    os.getenv("FRONTEND_URL", "http://localhost:3000"),
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:8080",
}
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(origins),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

bearer_scheme = HTTPBearer(auto_error=False)
MAX_ACTIVITY_LOGS = 500


class LoginRequest(BaseModel):
    email: str
    password: str


class ProfileUpdate(BaseModel):
    name: str
    email: str


class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str


class MessageCreate(BaseModel):
    receiver_email: str
    message: str


def get_connection():
    try:
        return mysql.connector.connect(
            host=os.getenv("DB_HOST", "127.0.0.1"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", "scmcies_db"),
            connection_timeout=5,
        )
    except mysql.connector.Error as exc:
        logger.exception("Could not connect to MySQL")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database unavailable",
        ) from exc


def record_activity(
    connection,
    *,
    actor_role: str,
    action: str,
    actor_id: Optional[int] = None,
    actor_email: Optional[str] = None,
    entity_type: Optional[str] = None,
    entity_id: Optional[Any] = None,
    parent_id: Optional[int] = None,
    details: Optional[dict[str, Any]] = None,
) -> None:
    cursor = connection.cursor()
    try:
        cursor.execute(
            """
            INSERT INTO activity_log
                (actor_role, actor_id, actor_email, action, entity_type, entity_id, parent_id, details)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                actor_role,
                actor_id,
                actor_email,
                action,
                entity_type,
                None if entity_id is None else str(entity_id),
                parent_id,
                json.dumps(details or {}),
            ),
        )
    finally:
        cursor.close()


def _secret_for_role(role: str) -> str:
    secret_name = "JWT_ADMIN_SECRET" if role == "admin" else "JWT_PARENT_SECRET"
    secret = os.getenv(secret_name, "").strip()
    if not secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"{secret_name} is not configured",
        )
    return secret


def _issue_token(user: dict[str, Any]) -> str:
    return jwt.encode(
        {
            "id": user["id"],
            "email": user["email"],
            "role": user["role"],
            "exp": datetime.now(timezone.utc) + timedelta(days=7),
        },
        _secret_for_role(user["role"]),
        algorithm="HS256",
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict[str, Any]:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required")

    for role, secret_name in (
        ("admin", "JWT_ADMIN_SECRET"),
        ("parent", "JWT_PARENT_SECRET"),
    ):
        secret = os.getenv(secret_name, "").strip()
        if not secret:
            continue
        try:
            payload = jwt.decode(credentials.credentials, secret, algorithms=["HS256"])
            if payload.get("role") != role or not payload.get("id"):
                continue
            return {
                "id": int(payload["id"]),
                "email": str(payload["email"]),
                "role": role,
            }
        except (jwt.InvalidTokenError, TypeError, ValueError):
            continue

    raise HTTPException(status_code=401, detail="Invalid or expired token")


def require_role(user: dict[str, Any], role: str) -> None:
    if user["role"] != role:
        raise HTTPException(status_code=403, detail="Forbidden")


def _user_response(user: dict[str, Any], token: str | None = None) -> dict[str, Any]:
    response = {
        "id": user["id"],
        "email": user["email"],
        "role": user["role"],
        "name": user.get("name") or ("Administrator" if user["role"] == "admin" else ""),
    }
    if token is not None:
        response["token"] = token
    return response


@app.get("/health")
def health():
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        return {"status": "ok", "database": "connected"}
    finally:
        connection.close()


@app.post("/api/auth/login")
def login(request: LoginRequest):
    email = request.email.strip().lower()
    if not email or len(email) > 255 or not request.password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, email, name, password_hash FROM admin WHERE LOWER(email) = %s LIMIT 1",
            (email,),
        )
        user = cursor.fetchone()
        role = "admin"
        if user is None:
            cursor.execute(
                "SELECT id, email, name, password_hash FROM parent WHERE LOWER(email) = %s LIMIT 1",
                (email,),
            )
            user = cursor.fetchone()
            role = "parent"

        password_matches = False
        if user is not None:
            try:
                password_matches = bcrypt.checkpw(
                    request.password.encode("utf-8"),
                    user["password_hash"].encode("utf-8"),
                )
            except (TypeError, ValueError):
                password_matches = False

        if user is None or not password_matches:
            record_activity(
                connection,
                actor_role=role if user is not None else "system",
                actor_id=user["id"] if user is not None else None,
                actor_email=user["email"] if user is not None else email,
                action="auth.login.failed",
                entity_type=role if user is not None else None,
                entity_id=user["id"] if user is not None else None,
                parent_id=user["id"] if role == "parent" and user is not None else None,
            )
            connection.commit()
            raise HTTPException(status_code=401, detail="Invalid email or password")

        account = {**user, "role": role}
        record_activity(
            connection,
            actor_role=role,
            actor_id=user["id"],
            actor_email=user["email"],
            action="auth.login.succeeded",
            entity_type=role,
            entity_id=user["id"],
            parent_id=user["id"] if role == "parent" else None,
        )
        token = _issue_token(account)
        connection.commit()
        return _user_response(account, token)
    except HTTPException:
        raise
    except mysql.connector.Error as exc:
        connection.rollback()
        logger.exception("Login database operation failed")
        raise HTTPException(status_code=503, detail="Login service unavailable") from exc
    finally:
        connection.close()


@app.get("/api/auth/profile")
def get_profile(user: dict[str, Any] = Depends(get_current_user)):
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        table = "admin" if user["role"] == "admin" else "parent"
        cursor.execute(
            f"SELECT id, email, name FROM {table} WHERE id = %s",
            (user["id"],),
        )
        account = cursor.fetchone()
        cursor.close()
        if account is None:
            raise HTTPException(status_code=404, detail="Account not found")
        account["role"] = user["role"]
        return _user_response(account)
    finally:
        connection.close()


@app.patch("/api/auth/profile")
def update_profile(
    update: ProfileUpdate,
    user: dict[str, Any] = Depends(get_current_user),
):
    name = update.name.strip()
    email = update.email.strip().lower()
    if (
        not name
        or len(name) > 255
        or len(email) > 255
        or "@" not in email
        or any(char.isspace() for char in email)
    ):
        raise HTTPException(status_code=400, detail="Name and a valid email are required")

    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        table = "admin" if user["role"] == "admin" else "parent"
        cursor.execute(f"SELECT id, email, name FROM {table} WHERE id = %s", (user["id"],))
        account = cursor.fetchone()
        if account is None:
            raise HTTPException(status_code=404, detail="Account not found")
        other_table = "parent" if user["role"] == "admin" else "admin"
        cursor.execute(
            f"SELECT id FROM {other_table} WHERE email = %s LIMIT 1",
            (email,),
        )
        if cursor.fetchone() is not None:
            raise HTTPException(status_code=409, detail="Email is already in use")
        cursor.execute(
            f"UPDATE {table} SET email = %s, name = %s WHERE id = %s",
            (email, name, user["id"]),
        )
        if user["role"] == "parent" and account["email"] != email:
            cursor.execute(
                "UPDATE student SET parent_email = %s WHERE parent_id = %s",
                (email, user["id"]),
            )
        record_activity(
            connection,
            actor_role=user["role"],
            actor_id=user["id"],
            actor_email=account["email"],
            action="account.profile.updated",
            entity_type=user["role"],
            entity_id=user["id"],
            parent_id=user["id"] if user["role"] == "parent" else None,
            details={"changed_fields": [
                field
                for field, old_value, new_value in (
                    ("email", account["email"], email),
                    ("name", account.get("name") or "", name),
                )
                if old_value != new_value
            ]},
        )
        connection.commit()
        updated = {**account, "email": email, "name": name, "role": user["role"]}
        return _user_response(updated, _issue_token(updated))
    except HTTPException:
        connection.rollback()
        raise
    except mysql.connector.IntegrityError as exc:
        connection.rollback()
        raise HTTPException(status_code=409, detail="Email is already in use") from exc
    except mysql.connector.Error as exc:
        connection.rollback()
        logger.exception("Profile update failed")
        raise HTTPException(status_code=503, detail="Profile update failed") from exc
    finally:
        connection.close()


@app.patch("/api/auth/profile/password")
def update_password(
    update: PasswordUpdate,
    user: dict[str, Any] = Depends(get_current_user),
):
    if len(update.new_password.strip()) < 8:
        raise HTTPException(status_code=400, detail="New password must be at least 8 characters")

    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        table = "admin" if user["role"] == "admin" else "parent"
        cursor.execute(
            f"SELECT password_hash FROM {table} WHERE id = %s",
            (user["id"],),
        )
        account = cursor.fetchone()
        if account is None:
            raise HTTPException(status_code=404, detail="Account not found")
        try:
            valid = bcrypt.checkpw(
                update.current_password.encode("utf-8"),
                account["password_hash"].encode("utf-8"),
            )
        except (TypeError, ValueError):
            valid = False
        if not valid:
            raise HTTPException(status_code=401, detail="Current password is incorrect")

        password_hash = bcrypt.hashpw(
            update.new_password.strip().encode("utf-8"),
            bcrypt.gensalt(),
        ).decode("utf-8")
        cursor.execute(
            f"UPDATE {table} SET password_hash = %s WHERE id = %s",
            (password_hash, user["id"]),
        )
        record_activity(
            connection,
            actor_role=user["role"],
            actor_id=user["id"],
            actor_email=user["email"],
            action="account.password.changed",
            entity_type=user["role"],
            entity_id=user["id"],
            parent_id=user["id"] if user["role"] == "parent" else None,
        )
        connection.commit()
        return {"message": "Password updated"}
    except HTTPException:
        connection.rollback()
        raise
    except mysql.connector.Error as exc:
        connection.rollback()
        logger.exception("Password update failed")
        raise HTTPException(status_code=503, detail="Password update failed") from exc
    finally:
        connection.close()


@app.get("/api/parents")
def list_parents(user: dict[str, Any] = Depends(get_current_user)):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, email, name FROM parent ORDER BY name, email")
        return cursor.fetchall()
    finally:
        connection.close()


@app.get("/api/students")
def list_students(user: dict[str, Any] = Depends(get_current_user)):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT s.id, s.student_id, s.first_name, s.last_name, s.grade_level,
                   s.section, s.parent_id, p.email AS parent_email, p.name AS parent_name,
                   s.image_path,
                   CASE
                     WHEN (
                       SELECT event_type FROM entry_exit_log
                       WHERE student_id = s.id
                       ORDER BY timestamp DESC, id DESC LIMIT 1
                     ) = 'ENTRY' THEN 'IN_CAMPUS'
                     ELSE 'NOT_IN_CAMPUS'
                   END AS status,
                   (
                     SELECT timestamp FROM entry_exit_log
                     WHERE student_id = s.id
                     ORDER BY timestamp DESC, id DESC LIMIT 1
                   ) AS last_seen
            FROM student s
            JOIN parent p ON p.id = s.parent_id
            ORDER BY s.first_name, s.last_name
            """
        )
        return cursor.fetchall()
    finally:
        connection.close()


@app.get("/api/parents/{parent_id}/children")
def list_children(
    parent_id: int,
    user: dict[str, Any] = Depends(get_current_user),
):
    require_role(user, "parent")
    if user["id"] != parent_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, student_id, first_name, last_name, grade_level, section, image_path
            FROM student
            WHERE parent_id = %s
            ORDER BY first_name, last_name
            """,
            (parent_id,),
        )
        return cursor.fetchall()
    finally:
        connection.close()


def _find_account(cursor, role: str, email: str):
    table = "admin" if role == "admin" else "parent"
    cursor.execute(
        f"SELECT id, email, name FROM {table} WHERE LOWER(email) = %s LIMIT 1",
        (email.strip().lower(),),
    )
    return cursor.fetchone()


@app.get("/api/messages")
def get_messages(
    with_email: str = Query(min_length=3, max_length=255),
    user: dict[str, Any] = Depends(get_current_user),
):
    peer_role = "parent" if user["role"] == "admin" else "admin"
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        peer = _find_account(cursor, peer_role, with_email)
        if peer is None:
            raise HTTPException(status_code=404, detail="Conversation account not found")
        cursor.execute(
            """
            SELECT id, sender_email AS sender, receiver_email AS receiver, message AS text,
                   created_at AS createdAt, sender_role = 'admin' AS isAdmin
            FROM app_message
            WHERE (sender_role = %s AND sender_id = %s AND receiver_role = %s AND receiver_id = %s)
               OR (sender_role = %s AND sender_id = %s AND receiver_role = %s AND receiver_id = %s)
            ORDER BY created_at, id
            LIMIT 500
            """,
            (
                user["role"], user["id"], peer_role, peer["id"],
                peer_role, peer["id"], user["role"], user["id"],
            ),
        )
        return cursor.fetchall()
    finally:
        connection.close()


@app.post("/api/messages", status_code=201)
def send_message(
    request: MessageCreate,
    user: dict[str, Any] = Depends(get_current_user),
):
    message = request.message.strip()
    if not message or len(message) > 5000 or len(request.receiver_email) > 255:
        raise HTTPException(status_code=400, detail="A message of 1–5000 characters is required")

    peer_role = "parent" if user["role"] == "admin" else "admin"
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        peer = _find_account(cursor, peer_role, request.receiver_email)
        if peer is None:
            raise HTTPException(status_code=404, detail="Conversation account not found")
        cursor.execute(
            """
            INSERT INTO app_message
                (sender_role, sender_id, sender_email, receiver_role, receiver_id,
                 receiver_email, message)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                user["role"], user["id"], user["email"], peer_role, peer["id"],
                peer["email"], message,
            ),
        )
        message_id = cursor.lastrowid
        parent_id = user["id"] if user["role"] == "parent" else peer["id"]
        record_activity(
            connection,
            actor_role=user["role"],
            actor_id=user["id"],
            actor_email=user["email"],
            action="message.sent",
            entity_type="message",
            entity_id=message_id,
            parent_id=parent_id,
            details={"recipient_role": peer_role},
        )
        connection.commit()
        return {
            "id": message_id,
            "sender": user["email"],
            "receiver": peer["email"],
            "text": message,
            "createdAt": datetime.now(timezone.utc),
            "isAdmin": user["role"] == "admin",
        }
    except HTTPException:
        connection.rollback()
        raise
    except mysql.connector.Error as exc:
        connection.rollback()
        logger.exception("Message could not be saved")
        raise HTTPException(status_code=503, detail="Message could not be saved") from exc
    finally:
        connection.close()


@app.get("/api/activity/admin")
def admin_activity(
    limit: int = Query(default=100, ge=1, le=MAX_ACTIVITY_LOGS),
    user: dict[str, Any] = Depends(get_current_user),
):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, actor_role, actor_id, actor_email, action, entity_type,
                   entity_id, parent_id, details, created_at
            FROM activity_log ORDER BY created_at DESC, id DESC LIMIT %s
            """,
            (limit,),
        )
        return cursor.fetchall()
    finally:
        connection.close()


@app.get("/api/activity/parent")
def parent_activity(
    limit: int = Query(default=100, ge=1, le=MAX_ACTIVITY_LOGS),
    user: dict[str, Any] = Depends(get_current_user),
):
    require_role(user, "parent")
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, actor_role, actor_id, actor_email, action, entity_type,
                   entity_id, parent_id, details, created_at
            FROM activity_log
            WHERE parent_id = %s OR (actor_role = 'parent' AND actor_id = %s)
            ORDER BY created_at DESC, id DESC LIMIT %s
            """,
            (user["id"], user["id"], limit),
        )
        return cursor.fetchall()
    finally:
        connection.close()
