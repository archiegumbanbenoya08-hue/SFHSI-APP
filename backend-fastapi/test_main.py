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
