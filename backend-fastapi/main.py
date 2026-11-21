import logging
import os
import re
import secrets
import smtplib
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from pathlib import Path
from typing import Any, Optional

import bcrypt
import jwt
import psycopg
from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request
from google.oauth2 import id_token as google_id_token
from psycopg.errors import UniqueViolation
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

load_dotenv(Path(__file__).parent / ".env")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

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
    allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

bearer_scheme = HTTPBearer(auto_error=False)
MAX_ACTIVITY_LOGS = 500


class LoginRequest(BaseModel):
    email: str
    password: str


class ParentSignupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=8, max_length=128)


class EmailVerificationRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    code: str = Field(min_length=6, max_length=6)


class GoogleSignInRequest(BaseModel):
    id_token: str = Field(min_length=1, max_length=8192)


class ProfileUpdate(BaseModel):
    name: str
    email: str


class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str


class PushDeviceRequest(BaseModel):
    fcm_installation_id: str = Field(min_length=20, max_length=4096)


def get_connection():
    database_url = os.getenv("DATABASE_URL", "").strip()
    if not database_url:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DATABASE_URL is not configured",
        )
    try:
        return psycopg.connect(
            database_url,
            connect_timeout=5,
            row_factory=dict_row,
        )
    except psycopg.Error as exc:
        logger.exception("Could not connect to PostgreSQL")
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
                Jsonb(details or {}),
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


def _verified_google_claims(token: str) -> dict[str, Any]:
    client_id = os.getenv("GOOGLE_OAUTH_CLIENT_ID", "").strip()
    if not client_id:
        raise HTTPException(
            status_code=503,
            detail="Google sign-in is not configured",
        )
    try:
        claims = google_id_token.verify_oauth2_token(
            token,
            Request(),
            audience=client_id,
        )
    except (ValueError, GoogleAuthError) as exc:
        raise HTTPException(status_code=401, detail="Invalid Google sign-in") from exc

    email = claims.get("email")
    if (
        not claims.get("sub")
        or not isinstance(email, str)
        or claims.get("email_verified") is not True
    ):
        raise HTTPException(status_code=401, detail="Google email is not verified")
    return claims


def _send_parent_verification_email(email: str, code: str) -> None:
    sender = os.getenv("GMAIL_USER", "").strip()
    app_password = os.getenv("GMAIL_APP_PASSWORD", "").strip()
    if not sender or not app_password:
        raise HTTPException(
            status_code=503,
            detail="Email verification is not configured",
        )

    message = EmailMessage()
    message["Subject"] = "Verify your SFHSI parent account"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        f"Your SFHSI verification code is {code}. "
        "It expires in 15 minutes. If you did not request this, ignore this email."
    )
    try:
        with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as smtp:
            smtp.starttls()
            smtp.login(sender, app_password)
            smtp.send_message(message)
    except (OSError, smtplib.SMTPException) as exc:
        logger.exception("Could not send parent account verification email")
        raise HTTPException(
            status_code=503,
            detail="Could not send verification email",
        ) from exc


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


@app.post("/api/auth/register")
def register_parent(request: ParentSignupRequest):
    name = request.name.strip()
    email = request.email.strip().lower()
    password = request.password
    if (
        not name
        or not EMAIL_PATTERN.fullmatch(email)
        or any(char.isspace() for char in password)
        or len(password.encode("utf-8")) > 72
    ):
        raise HTTPException(status_code=400, detail="Enter valid sign-up details")

    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT id FROM admin WHERE LOWER(email) = %s
            UNION ALL
            SELECT id FROM parent WHERE LOWER(email) = %s
            LIMIT 1
            """,
            (email, email),
        )
        if cursor.fetchone() is not None:
            raise HTTPException(status_code=409, detail="Email is already in use")

        now = datetime.now(timezone.utc)
        cursor.execute(
            "SELECT last_sent_at FROM pending_parent_signup WHERE email = %s FOR UPDATE",
            (email,),
        )
        pending = cursor.fetchone()
        if (
            pending is not None
            and (now - pending["last_sent_at"]).total_seconds() < 60
        ):
            connection.commit()
            return {"verification_required": True, "email": email}

        code = f"{secrets.randbelow(1_000_000):06d}"
        password_hash = bcrypt.hashpw(
            password.encode("utf-8"),
            bcrypt.gensalt(),
        ).decode("utf-8")
        cursor.execute(
            """
            INSERT INTO pending_parent_signup
                (email, name, password_hash, verification_code_hash, expires_at, last_sent_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (email) DO UPDATE SET
                name = EXCLUDED.name,
                password_hash = EXCLUDED.password_hash,
                verification_code_hash = EXCLUDED.verification_code_hash,
                expires_at = EXCLUDED.expires_at,
                last_sent_at = EXCLUDED.last_sent_at,
                attempts_remaining = 5
            """,
            (
                email,
                name,
                password_hash,
                bcrypt.hashpw(code.encode("ascii"), bcrypt.gensalt()).decode("ascii"),
                now + timedelta(minutes=15),
                now,
            ),
        )
        _send_parent_verification_email(email, code)
        connection.commit()
        return {"verification_required": True, "email": email}
    except HTTPException:
        connection.rollback()
        raise
    except UniqueViolation as exc:
        connection.rollback()
        raise HTTPException(status_code=409, detail="Email is already in use") from exc
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Parent sign-up failed")
        raise HTTPException(status_code=503, detail="Sign-up service unavailable") from exc
    finally:
        connection.close()


@app.post("/api/auth/verify-email")
def verify_parent_email(request: EmailVerificationRequest):
    email = request.email.strip().lower()
    if (
        not EMAIL_PATTERN.fullmatch(email)
        or not request.code.isascii()
        or not request.code.isdigit()
    ):
        raise HTTPException(status_code=400, detail="Enter a valid email and six-digit code")

    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT name, password_hash, verification_code_hash,
                   expires_at, attempts_remaining
            FROM pending_parent_signup
            WHERE email = %s
            FOR UPDATE
            """,
            (email,),
        )
        pending = cursor.fetchone()
        if pending is None:
            raise HTTPException(status_code=400, detail="Verification request not found")

        if pending["expires_at"] <= datetime.now(timezone.utc):
            cursor.execute("DELETE FROM pending_parent_signup WHERE email = %s", (email,))
            connection.commit()
            raise HTTPException(status_code=400, detail="Verification code expired")
        if pending["attempts_remaining"] <= 0:
            raise HTTPException(
                status_code=429,
                detail="Too many incorrect codes. Request a new code later.",
            )
        if not bcrypt.checkpw(
            request.code.encode("ascii"),
            pending["verification_code_hash"].encode("ascii"),
        ):
            cursor.execute(
                """
                UPDATE pending_parent_signup
                SET attempts_remaining = attempts_remaining - 1
                WHERE email = %s
                """,
                (email,),
            )
            connection.commit()
            raise HTTPException(status_code=400, detail="Verification code is incorrect")

        cursor.execute(
            """
            SELECT id FROM admin WHERE LOWER(email) = %s
            UNION ALL
            SELECT id FROM parent WHERE LOWER(email) = %s
            LIMIT 1
            """,
            (email, email),
        )
        if cursor.fetchone() is not None:
            cursor.execute("DELETE FROM pending_parent_signup WHERE email = %s", (email,))
            connection.commit()
            raise HTTPException(status_code=409, detail="Email is already in use")

        cursor.execute(
            """
            INSERT INTO parent (email, password_hash, name)
            VALUES (%s, %s, %s)
            RETURNING id, email, name
            """,
            (email, pending["password_hash"], pending["name"]),
        )
        account = {**cursor.fetchone(), "role": "parent"}
        cursor.execute("DELETE FROM pending_parent_signup WHERE email = %s", (email,))
        record_activity(
            connection,
            actor_role="parent",
            actor_id=account["id"],
            actor_email=account["email"],
            action="auth.signup.succeeded",
            entity_type="parent",
            entity_id=account["id"],
            parent_id=account["id"],
        )
        token = _issue_token(account)
        connection.commit()
        return _user_response(account, token)
    except HTTPException:
        connection.rollback()
        raise
    except UniqueViolation as exc:
        connection.rollback()
        raise HTTPException(status_code=409, detail="Email is already in use") from exc
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Parent email verification failed")
        raise HTTPException(status_code=503, detail="Email verification failed") from exc
    finally:
        connection.close()


@app.post("/api/auth/google")
def sign_in_with_google(request: GoogleSignInRequest):
    claims = _verified_google_claims(request.id_token)
    email = claims["email"].strip().lower()
    google_name = claims.get("name")
    name = google_name.strip()[:255] if isinstance(google_name, str) else ""
    name = name or email.split("@", 1)[0]

    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM admin WHERE LOWER(email) = %s LIMIT 1", (email,))
        if cursor.fetchone() is not None:
            raise HTTPException(
                status_code=403,
                detail="Google sign-in is available for parent accounts only",
            )

        cursor.execute(
            "SELECT id, email, name FROM parent WHERE LOWER(email) = %s LIMIT 1",
            (email,),
        )
        account = cursor.fetchone()
        action = "auth.google.signed_in"
        if account is None:
            password_hash = bcrypt.hashpw(
                secrets.token_bytes(32),
                bcrypt.gensalt(),
            ).decode("utf-8")
            cursor.execute(
                """
                INSERT INTO parent (email, password_hash, name)
                VALUES (%s, %s, %s)
                RETURNING id, email, name
                """,
                (email, password_hash, name),
            )
            account = cursor.fetchone()
            action = "auth.google.signed_up"

        cursor.execute("DELETE FROM pending_parent_signup WHERE email = %s", (email,))
        account = {**account, "role": "parent"}
        record_activity(
            connection,
            actor_role="parent",
            actor_id=account["id"],
            actor_email=account["email"],
            action=action,
            entity_type="parent",
            entity_id=account["id"],
            parent_id=account["id"],
        )
        token = _issue_token(account)
        connection.commit()
        return _user_response(account, token)
    except HTTPException:
        connection.rollback()
        raise
    except UniqueViolation as exc:
        connection.rollback()
        raise HTTPException(
            status_code=409,
            detail="Account changed during sign-in. Please try again.",
        ) from exc
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Google sign-in failed")
        raise HTTPException(status_code=503, detail="Sign-in service unavailable") from exc
    finally:
        connection.close()


@app.post("/api/auth/login")
def login(request: LoginRequest):
    email = request.email.strip().lower()
    if not email or len(email) > 255 or not request.password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    connection = get_connection()
    try:
        cursor = connection.cursor()
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
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Login database operation failed")
        raise HTTPException(status_code=503, detail="Login service unavailable") from exc
    finally:
        connection.close()


@app.get("/api/auth/profile")
def get_profile(user: dict[str, Any] = Depends(get_current_user)):
    connection = get_connection()
    try:
        cursor = connection.cursor()
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
        cursor = connection.cursor()
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
    except UniqueViolation as exc:
        connection.rollback()
        raise HTTPException(status_code=409, detail="Email is already in use") from exc
    except psycopg.Error as exc:
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
        cursor = connection.cursor()
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
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Password update failed")
        raise HTTPException(status_code=503, detail="Password update failed") from exc
    finally:
        connection.close()


@app.put("/api/push/devices/current")
def register_push_device(
    request: PushDeviceRequest,
    user: dict[str, Any] = Depends(get_current_user),
):
    installation_id = request.fcm_installation_id.strip()
    if len(installation_id) < 20:
        raise HTTPException(status_code=400, detail="Invalid push installation ID")

    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO push_device_token (fcm_installation_id, user_role, user_id)
            VALUES (%s, %s, %s)
            ON CONFLICT (fcm_installation_id) DO UPDATE
            SET user_role = EXCLUDED.user_role,
                user_id = EXCLUDED.user_id,
                updated_at = now()
            """,
            (installation_id, user["role"], user["id"]),
        )
        connection.commit()
        return {"registered": True}
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Push device registration failed")
        raise HTTPException(
            status_code=503,
            detail="Push device registration failed",
        ) from exc
    finally:
        connection.close()


@app.delete("/api/push/devices/current")
def unregister_push_device(
    request: PushDeviceRequest,
    user: dict[str, Any] = Depends(get_current_user),
):
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            DELETE FROM push_device_token
            WHERE fcm_installation_id = %s AND user_role = %s AND user_id = %s
            """,
            (request.fcm_installation_id, user["role"], user["id"]),
        )
        connection.commit()
        return {"removed": cursor.rowcount > 0}
    except psycopg.Error as exc:
        connection.rollback()
        logger.exception("Push device removal failed")
        raise HTTPException(
            status_code=503,
            detail="Push device removal failed",
        ) from exc
    finally:
        connection.close()


@app.get("/api/parents")
def list_parents(user: dict[str, Any] = Depends(get_current_user)):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT id, email, name FROM parent ORDER BY name, email")
        return cursor.fetchall()
    finally:
        connection.close()


@app.get("/api/students")
def list_students(user: dict[str, Any] = Depends(get_current_user)):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor()
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


@app.get("/api/admin/statistics")
def admin_statistics(user: dict[str, Any] = Depends(get_current_user)):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                (SELECT COUNT(*)::int FROM student) AS total_students,
                (
                    SELECT COUNT(*)::int
                    FROM (
                        SELECT DISTINCT ON (student_id) student_id, event_type
                        FROM entry_exit_log
                        ORDER BY student_id, timestamp DESC, id DESC
                    ) latest
                    WHERE latest.event_type = 'ENTRY'
                ) AS students_on_campus,
                (
                    SELECT COUNT(*)::int
                    FROM entry_exit_log
                    WHERE event_type = 'ENTRY'
                      AND timestamp >=
                          date_trunc('day', now() AT TIME ZONE 'Asia/Manila')
                          AT TIME ZONE 'Asia/Manila'
                      AND timestamp <
                          (date_trunc('day', now() AT TIME ZONE 'Asia/Manila')
                           + INTERVAL '1 day') AT TIME ZONE 'Asia/Manila'
                ) AS entries_today,
                (
                    SELECT COUNT(*)::int
                    FROM entry_exit_log
                    WHERE event_type = 'EXIT'
                      AND timestamp >=
                          date_trunc('day', now() AT TIME ZONE 'Asia/Manila')
                          AT TIME ZONE 'Asia/Manila'
                      AND timestamp <
                          (date_trunc('day', now() AT TIME ZONE 'Asia/Manila')
                           + INTERVAL '1 day') AT TIME ZONE 'Asia/Manila'
                ) AS exits_today
            """
        )
        statistics = cursor.fetchone()
        cursor.close()
        return {
            "totalStudents": statistics["total_students"],
            "studentsOnCampus": statistics["students_on_campus"],
            "entriesToday": statistics["entries_today"],
            "exitsToday": statistics["exits_today"],
        }
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
        cursor = connection.cursor()
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


@app.get("/api/activity/admin")
def admin_activity(
    limit: int = Query(default=100, ge=1, le=MAX_ACTIVITY_LOGS),
    user: dict[str, Any] = Depends(get_current_user),
):
    require_role(user, "admin")
    connection = get_connection()
    try:
        cursor = connection.cursor()
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
        cursor = connection.cursor()
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
