import fs from 'fs';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getConnection } from '../db.js';

let messaging;

export function initializePushNotifications() {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();

  try {
    let credential;
    if (serviceAccountJson) {
      credential = cert(JSON.parse(serviceAccountJson));
    } else if (credentialsPath && fs.existsSync(credentialsPath)) {
      credential = cert(
        JSON.parse(fs.readFileSync(credentialsPath, 'utf8')),
      );
    } else {
      console.warn('FCM is not configured.');
      return false;
    }

    if (getApps().length === 0) {
      initializeApp({ credential });
    }
    messaging = getMessaging();
    return true;
  } catch (error) {
    console.error('Could not initialize Firebase Admin:', error);
    return false;
  }
}

export async function sendAttendancePush({
  parentId,
  studentId,
  studentName,
  eventType,
  location,
  timestamp,
}) {
  if (!messaging) return;

  const conn = await getConnection();
  const { rows } = await conn.query(
    `SELECT fcm_installation_id
       FROM push_device_token
      WHERE user_role = 'admin'
         OR (user_role = 'parent' AND user_id = $1)`,
    [parentId],
  );
  conn.release();

  const tokens = rows
    .map((row) => row.fcm_installation_id)
    .filter(Boolean);
  if (tokens.length === 0) return;

  const entered = eventType === 'ENTRY';
  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: entered ? 'Student arrived' : 'Student left campus',
      body: `${studentName} (${studentId}) ${entered ? 'entered' : 'exited'} at ${location}.`,
    },
    data: {
      event_type: eventType,
      student_id: String(studentId),
      student_name: studentName,
      location: location || '',
      timestamp: timestamp.toISOString(),
    },
  });

  if (response.failureCount > 0) {
    console.warn('Some ENTRY/EXIT push notifications failed', {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
}
