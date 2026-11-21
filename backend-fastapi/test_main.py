import os
import unittest
from unittest.mock import MagicMock, patch

import jwt
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

import main


class FastApiAuthTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(
            os.environ,
            {
                "JWT_ADMIN_SECRET": "test-admin-secret",
                "JWT_PARENT_SECRET": "test-parent-secret",
            },
        )
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_issued_parent_token_resolves_to_parent_identity(self):
        user = {
            "id": 17,
            "email": "parent@example.com",
            "role": "parent",
        }

        token = main._issue_token(user)
        resolved = main.get_current_user(
            HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        )

        self.assertEqual(
            resolved,
            {"id": 17, "email": "parent@example.com", "role": "parent"},
        )

    def test_google_token_verification_uses_configured_audience_and_verified_email(self):
        claims = {
            "email": "parent@example.com",
            "email_verified": True,
            "sub": "google-user-id",
        }
        with (
            patch.dict(os.environ, {"GOOGLE_OAUTH_CLIENT_ID": "web-client-id"}),
            patch.object(
                main.google_id_token,
                "verify_oauth2_token",
                return_value=claims,
            ) as verify_token,
        ):
            verified = main._verified_google_claims("google-id-token")

        self.assertEqual(verified, claims)
        self.assertEqual(verify_token.call_args.kwargs["audience"], "web-client-id")

    def test_google_token_verification_rejects_unverified_email(self):
        with (
            patch.dict(os.environ, {"GOOGLE_OAUTH_CLIENT_ID": "web-client-id"}),
            patch.object(
                main.google_id_token,
                "verify_oauth2_token",
                return_value={
                    "email": "parent@example.com",
                    "email_verified": False,
                    "sub": "google-user-id",
                },
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                main._verified_google_claims("google-id-token")

        self.assertEqual(raised.exception.status_code, 401)

    def test_login_persists_successful_activity_and_returns_token(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            None,
            {
                "id": 17,
                "email": "parent@example.com",
                "name": "Parent",
                "password_hash": main.bcrypt.hashpw(
                    b"correct-password", main.bcrypt.gensalt()
                ).decode(),
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            response = main.login(
                main.LoginRequest(
                    email="Parent@example.com",
                    password="correct-password",
                )
            )

        self.assertEqual(response["role"], "parent")
        self.assertEqual(response["email"], "parent@example.com")
        self.assertTrue(response["token"])
        activity_actions = [
            call.args[1][3]
            for call in cursor.execute.call_args_list
            if "INSERT INTO activity_log" in call.args[0]
        ]
        self.assertIn(
            "auth.login.succeeded",
            activity_actions,
        )
        connection.commit.assert_called_once()
        connection.close.assert_called_once()

    def test_parent_signup_sends_a_hashed_password_and_verification_code(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [None, None]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(main, "get_connection", return_value=connection),
            patch.object(main, "_send_parent_verification_email") as send_email,
        ):
            response = main.register_parent(
                main.ParentSignupRequest(
                    name=" Parent Name ",
                    email=" Parent@Example.com ",
                    password="safe-password",
                )
            )

        self.assertEqual(
            response,
            {"verification_required": True, "email": "parent@example.com"},
        )
        self.assertRegex(send_email.call_args.args[1], r"^\d{6}$")
        self.assertEqual(send_email.call_args.args[0], "parent@example.com")
        password_hash = cursor.execute.call_args_list[2].args[1][2]
        self.assertTrue(main.bcrypt.checkpw(b"safe-password", password_hash.encode()))
        connection.commit.assert_called_once()
        connection.close.assert_called_once()

    def test_email_verification_creates_a_parent_and_returns_a_session(self):
        verification_hash = main.bcrypt.hashpw(b"123456", main.bcrypt.gensalt()).decode()
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {
                "name": "Parent Name",
                "password_hash": main.bcrypt.hashpw(
                    b"safe-password", main.bcrypt.gensalt()
                ).decode(),
                "verification_code_hash": verification_hash,
                "expires_at": main.datetime.now(main.timezone.utc)
                + main.timedelta(minutes=10),
                "attempts_remaining": 5,
            },
            None,
            {"id": 23, "email": "parent@example.com", "name": "Parent Name"},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            response = main.verify_parent_email(
                main.EmailVerificationRequest(
                    email="parent@example.com",
                    code="123456",
                )
            )

        self.assertEqual(response["role"], "parent")
        self.assertEqual(response["email"], "parent@example.com")
        self.assertTrue(response["token"])
        connection.commit.assert_called_once()
        connection.close.assert_called_once()

    def test_parent_signup_rejects_existing_account_email(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"id": 1}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            with self.assertRaises(HTTPException) as raised:
                main.register_parent(
                    main.ParentSignupRequest(
                        name="Parent",
                        email="parent@example.com",
                        password="safe-password",
                    )
                )

        self.assertEqual(raised.exception.status_code, 409)
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_parent_signup_does_not_resend_code_within_one_minute(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            None,
            {"last_sent_at": main.datetime.now(main.timezone.utc)},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(main, "get_connection", return_value=connection),
            patch.object(main, "_send_parent_verification_email") as send_email,
        ):
            response = main.register_parent(
                main.ParentSignupRequest(
                    name="Parent",
                    email="parent@example.com",
                    password="safe-password",
                )
            )

        self.assertEqual(
            response,
            {"verification_required": True, "email": "parent@example.com"},
        )
        send_email.assert_not_called()
        connection.commit.assert_called_once()

    def test_email_verification_rejects_incorrect_code_and_decrements_attempts(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "name": "Parent Name",
            "password_hash": "unused",
            "verification_code_hash": main.bcrypt.hashpw(
                b"123456", main.bcrypt.gensalt()
            ).decode(),
            "expires_at": main.datetime.now(main.timezone.utc)
            + main.timedelta(minutes=10),
            "attempts_remaining": 5,
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            with self.assertRaises(HTTPException) as raised:
                main.verify_parent_email(
                    main.EmailVerificationRequest(
                        email="parent@example.com",
                        code="000000",
                    )
                )

        self.assertEqual(raised.exception.status_code, 400)
        self.assertIn(
            "attempts_remaining = attempts_remaining - 1",
            cursor.execute.call_args.args[0],
        )
        connection.commit.assert_called_once()

    def test_google_signin_creates_a_parent_for_a_verified_google_identity(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            None,
            None,
            {"id": 23, "email": "parent@example.com", "name": "Parent Name"},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(
                main,
                "_verified_google_claims",
                return_value={
                    "email": "parent@example.com",
                    "name": "Parent Name",
                    "sub": "google-user-id",
                },
            ),
            patch.object(main, "get_connection", return_value=connection),
        ):
            response = main.sign_in_with_google(
                main.GoogleSignInRequest(id_token="verified-id-token")
            )

        self.assertEqual(response["role"], "parent")
        self.assertEqual(response["email"], "parent@example.com")
        self.assertTrue(response["token"])
        password_hash = cursor.execute.call_args_list[2].args[1][1]
        self.assertNotEqual(password_hash, "verified-id-token")
        connection.commit.assert_called_once()
        connection.close.assert_called_once()

    def test_google_signin_cannot_authenticate_an_admin_account(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"id": 1}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(main, "_verified_google_claims", return_value={"email": "admin@example.com"}),
            patch.object(main, "get_connection", return_value=connection),
        ):
            with self.assertRaises(HTTPException) as raised:
                main.sign_in_with_google(
                    main.GoogleSignInRequest(id_token="verified-id-token")
                )

        self.assertEqual(raised.exception.status_code, 403)
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_parent_profile_rejects_admin_email(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"id": 17, "email": "parent@example.com", "name": "Parent"},
            {"id": 1},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            with self.assertRaises(HTTPException) as raised:
                main.update_profile(
                    main.ProfileUpdate(
                        name="Parent",
                        email="admin@example.com",
                    ),
                    user={
                        "id": 17,
                        "email": "parent@example.com",
                        "role": "parent",
                    },
                )

        self.assertEqual(raised.exception.status_code, 409)
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_parent_email_update_keeps_linked_students_in_sync(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"id": 17, "email": "parent@example.com", "name": "Parent"},
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            response = main.update_profile(
                main.ProfileUpdate(
                    name="Parent",
                    email="new-parent@example.com",
                ),
                user={
                    "id": 17,
                    "email": "parent@example.com",
                    "role": "parent",
                },
            )

        self.assertEqual(response["email"], "new-parent@example.com")
        statements = [call.args[0] for call in cursor.execute.call_args_list]
        self.assertTrue(
            any("UPDATE student SET parent_email = %s" in sql for sql in statements)
        )
        connection.commit.assert_called_once()

    def test_role_guard_rejects_access_to_another_roles_activity(self):
        with self.assertRaises(HTTPException) as raised:
            main.require_role({"role": "parent"}, "admin")

        self.assertEqual(raised.exception.status_code, 403)

    def test_admin_statistics_returns_student_and_daily_log_counts(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "total_students": 25,
            "students_on_campus": 8,
            "entries_today": 12,
            "exits_today": 4,
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(main, "get_connection", return_value=connection):
            response = main.admin_statistics(
                user={"id": 1, "email": "admin@example.com", "role": "admin"}
            )

        self.assertEqual(
            response,
            {
                "totalStudents": 25,
                "studentsOnCampus": 8,
                "entriesToday": 12,
                "exitsToday": 4,
            },
        )
        self.assertIn("Asia/Manila", cursor.execute.call_args.args[0])
        connection.close.assert_called_once()

    def test_admin_statistics_rejects_parent_access(self):
        with patch.object(main, "get_connection") as get_connection:
            with self.assertRaises(HTTPException) as raised:
                main.admin_statistics(
                    user={"id": 17, "email": "parent@example.com", "role": "parent"}
                )

        self.assertEqual(raised.exception.status_code, 403)
        get_connection.assert_not_called()

    def test_push_device_registration_uses_authenticated_account(self):
        connection = MagicMock()
        cursor = connection.cursor.return_value
        installation_id = "fcm-installation-id-1234567890"

        with patch.object(main, "get_connection", return_value=connection):
            response = main.register_push_device(
                main.PushDeviceRequest(fcm_installation_id=installation_id),
                user={"id": 17, "email": "parent@example.com", "role": "parent"},
            )

        self.assertEqual(response, {"registered": True})
        self.assertIn(
            "ON CONFLICT (fcm_installation_id) DO UPDATE",
            cursor.execute.call_args.args[0],
        )
        self.assertEqual(
            cursor.execute.call_args.args[1],
            (installation_id, "parent", 17),
        )
        connection.commit.assert_called_once()

    def test_push_device_removal_is_scoped_to_authenticated_account(self):
        connection = MagicMock()
        cursor = connection.cursor.return_value
        cursor.rowcount = 0

        with patch.object(main, "get_connection", return_value=connection):
            response = main.unregister_push_device(
                main.PushDeviceRequest(
                    fcm_installation_id="fcm-installation-id-1234567890"
                ),
                user={"id": 17, "email": "parent@example.com", "role": "parent"},
            )

        self.assertEqual(response, {"removed": False})
        self.assertEqual(
            cursor.execute.call_args.args[1],
            ("fcm-installation-id-1234567890", "parent", 17),
        )
        connection.commit.assert_called_once()


if __name__ == "__main__":
    unittest.main()
