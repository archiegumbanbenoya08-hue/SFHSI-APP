import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

export async function sendEntryNotification(parentEmail, parentName, studentName, studentId, grade, eventTime) {
  return transporter.sendMail({
    from: process.env.GMAIL_USER,
    to: parentEmail,
    subject: `Student Entry Notification - ${studentName}`,
    html: `
      <h2>Campus Entry Notification</h2>
      <p>Dear ${parentName},</p>
      <p><strong>${studentName}</strong> has entered the campus.</p>
      <ul>
        <li><strong>Student ID:</strong> ${studentId}</li>
        <li><strong>Grade:</strong> ${grade}</li>
        <li><strong>Date & Time:</strong> ${new Date(eventTime).toLocaleString()}</li>
      </ul>
      <p>Best regards,<br>SCMCIES Campus Monitoring System</p>
    `
  });
}

export async function sendExitNotification(parentEmail, parentName, studentName, studentId, grade, eventTime) {
  return transporter.sendMail({
    from: process.env.GMAIL_USER,
    to: parentEmail,
    subject: `Student Exit Notification - ${studentName}`,
    html: `
      <h2>Campus Exit Notification</h2>
      <p>Dear ${parentName},</p>
      <p><strong>${studentName}</strong> has exited the campus.</p>
      <ul>
        <li><strong>Student ID:</strong> ${studentId}</li>
        <li><strong>Grade:</strong> ${grade}</li>
        <li><strong>Date & Time:</strong> ${new Date(eventTime).toLocaleString()}</li>
      </ul>
      <p>Best regards,<br>SCMCIES Campus Monitoring System</p>
    `
  });
}

export async function sendAdminEntryNotification(adminEmail, studentName, studentId, grade, parentEmail, eventTime) {
  return transporter.sendMail({
    from: process.env.GMAIL_USER,
    to: adminEmail,
    subject: `Campus Entry - ${studentName}`,
    html: `
      <h2>Campus Entry Log</h2>
      <ul>
        <li><strong>Student Name:</strong> ${studentName}</li>
        <li><strong>Student ID:</strong> ${studentId}</li>
        <li><strong>Grade:</strong> ${grade}</li>
        <li><strong>Parent Email:</strong> ${parentEmail}</li>
        <li><strong>Date & Time:</strong> ${new Date(eventTime).toLocaleString()}</li>
      </ul>
      <p>Logged by SCMCIES Campus Monitoring System</p>
    `
  });
}

export async function sendAdminExitNotification(adminEmail, studentName, studentId, grade, parentEmail, eventTime) {
  return transporter.sendMail({
    from: process.env.GMAIL_USER,
    to: adminEmail,
    subject: `Campus Exit - ${studentName}`,
    html: `
      <h2>Campus Exit Log</h2>
      <ul>
        <li><strong>Student Name:</strong> ${studentName}</li>
        <li><strong>Student ID:</strong> ${studentId}</li>
        <li><strong>Grade:</strong> ${grade}</li>
        <li><strong>Parent Email:</strong> ${parentEmail}</li>
        <li><strong>Date & Time:</strong> ${new Date(eventTime).toLocaleString()}</li>
      </ul>
      <p>Logged by SCMCIES Campus Monitoring System</p>
    `
  });
}
