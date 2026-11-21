# Firebase attendance push notifications

The app registers the signed-in device with the FastAPI backend. When the
Mini PC posts an `ENTRY` or `EXIT` event to the Node.js backend, Node sends an
FCM notification to every registered administrator and to registered devices
for that student's linked parent. Parents can turn attendance alerts off in
their app settings.

## 1. Create and configure a Firebase project

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. In **Project settings**, note the project ID, Web API key, and Cloud
   Messaging sender ID. Enable Cloud Messaging.
3. Register these app IDs in Firebase:
   - Android: `com.example.example`
   - iOS: `com.example.example`
   - Web: create a Web app for the hosted Flutter site.
4. For iOS, upload an APNs authentication key under **Project settings →
   Cloud Messaging**. In Xcode, enable **Push Notifications** for the Runner
   target and test on a physical Apple device.
5. In **Project settings → Cloud Messaging → Web configuration**, generate a
   Web Push certificate and copy its public key (VAPID key).

The current Android and iOS bundle IDs are example identifiers. Before
publishing, choose permanent unique IDs and register those exact IDs in Firebase.

## 2. Configure Flutter

Copy `firebase-config.example.json` to the ignored `firebase-config.json` and
fill it with the values from the three Firebase app registrations. The iOS
bundle ID must match the registered iOS app. The VAPID value is the Web Push
public key; it is not the Firebase service-account credential.

Run or build the app with that config:

```powershell
flutter run --dart-define-from-file=firebase-config.json
flutter build apk --dart-define-from-file=firebase-config.json
flutter build web --dart-define-from-file=firebase-config.json
```

Web push requires HTTPS (or localhost during development) and browser
notification permission. Replace the `REPLACE_WITH_FIREBASE_...` values in
`web/firebase-messaging-sw.js` with the same Firebase Web app config. Parents
can enable or disable attendance alerts in **Settings**; administrators are
registered for alerts after sign-in.

## 2a. Enable parent sign-up with Google

The login screen provides email/password registration and Google sign-up for
**parent accounts only**. Admin accounts remain administrator-created. FastAPI
verifies Google ID tokens directly; Firebase Authentication is not required.

1. In Google Cloud Console, configure the OAuth consent screen and create a
   **Web application** OAuth client. Configure the app's web origin if using
   Flutter Web.
2. Set that Web client ID as `GOOGLE_OAUTH_CLIENT_ID` in the FastAPI service's
   Render environment and provide the same public client ID when building
   Flutter:

   ```powershell
   flutter build apk --dart-define-from-file=firebase-config.json `
     --dart-define=GOOGLE_OAUTH_CLIENT_ID=YOUR-WEB-CLIENT-ID.apps.googleusercontent.com `
     --dart-define=API_BASE_URL=https://YOUR-FASTAPI.onrender.com/api
   ```

3. Configure platform OAuth clients in the same Google Cloud project. For
   Android, use the app's package ID and signing certificate SHA-1; for iOS,
   use its bundle ID and register the reversed client ID URL scheme. Download
   fresh Firebase Android/iOS configuration files after registering the app
   IDs. Do not publish with the current `com.example.example` IDs.
4. Rebuild and install the app. A successful Google sign-up creates a parent
   account using Google's verified email; an admin still needs to associate
   that parent with their student. Email/password sign-up sends a six-digit
   code that must be verified before an account is created.

## 3. Deploy the APIs to Render

The project includes a `render.yaml` blueprint for the Node attendance API
and FastAPI app API. In Render, create a Blueprint from this repository and
select `render.yaml`. The services use the free plan; they may spin down while
idle, so the first request can take longer.

Set the prompted `DATABASE_URL` for both services to the Supabase **Session
pooler** connection string (including its database password). Use the same
URL for both services. Do not commit the password or send it in chat. The
pooler is appropriate for API hosts that need IPv4 connectivity.

Set the same strong, randomly generated `JWT_ADMIN_SECRET` and
`JWT_PARENT_SECRET` in both services. Set `DEVICE_API_KEY` on the Node service
and use that exact value in the Mini PC's private `.env` file. Set
`FIREBASE_SERVICE_ACCOUNT_JSON` on the Node service to the contents of the
Firebase Admin service-account JSON file; keep that file out of Git and out
of the Flutter app. Set `GOOGLE_OAUTH_CLIENT_ID` on FastAPI to the Google Web
OAuth client ID used by Flutter. Set `FRONTEND_URL` to the deployed Flutter web
origin on each service (or `http://localhost:3000` while testing locally). Set
`GMAIL_USER` and `GMAIL_APP_PASSWORD` to a Gmail account and its App Password;
these are used to send email verification codes and must be kept in Render
secrets.

After deploying, copy the Node service's HTTPS URL into the Mini PC's `API_URL`
and copy the FastAPI service's HTTPS URL with `/api` appended into the Flutter
build's `API_BASE_URL`, for example:

```powershell
flutter build apk --dart-define-from-file=firebase-config.json `
  --dart-define=API_BASE_URL=https://YOUR-FASTAPI.onrender.com/api
```

The Mini PC should use `API_URL=https://YOUR-NODE.onrender.com`. Restart the
services after changing secrets. The Node `/health` response should report
`pushNotifications: configured`.

Render's free service filesystem is temporary. Keep source photos and other
uploads in durable object storage before relying on them in production.

## 4. Configure the Node sender

Create a Firebase service-account private key in **Project settings → Service
accounts → Generate new private key**. Keep the downloaded JSON outside the
repository and never put it in the Flutter app.

For local development, set `GOOGLE_APPLICATION_CREDENTIALS` in
`backend-node/.env` to the absolute path of that file. For a hosted Node backend, put the complete JSON contents in its secret named
`FIREBASE_SERVICE_ACCOUNT_JSON`. Configure the hosted `DATABASE_URL` and the
same `DEVICE_API_KEY` used by the Mini PC. Restart/redeploy Node after adding
secrets. Its `/health` endpoint reports whether FCM is configured.

The Mini PC must post attendance logs to the deployed Node API (not
`localhost`) using HTTPS and the matching device API key. The FastAPI backend
used by the app and the Node attendance API must point at the same hosted
PostgreSQL database.

## 5. Database and delivery checks

Apply the pending-parent-sign-up migration before enabling email registration:

```powershell
npx supabase db push --remote
```

The Supabase migration for device tokens is
`supabase/migrations/20261121032200_push_device_tokens.sql`. Apply pending
migrations to the local and linked hosted project:

```powershell
npx supabase db push
npx supabase db push --remote
```

Sign in on a device and allow notifications. Trigger a real test entry/exit
from the Mini PC. An administrator should receive it; a parent should receive
it only for a student linked to that parent. Real delivery also requires valid
Firebase app configuration, an APNs key for iOS, and a service-account
credential on the Node server.
