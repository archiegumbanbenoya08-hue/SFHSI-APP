importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAf3pm8zRYBkMvRuwzHWze_4SsZ5EvvT4s',
  authDomain: 'sfhsi-app.firebaseapp.com',
  projectId: 'sfhsi-app',
  storageBucket: 'sfhsi-app.firebasestorage.app',
  messagingSenderId: '294827724924',
  appId: '1:294827724924:web:bc9d16564790a228b3f9f9',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Campus ENTRY/EXIT update';
  const options = {
    body: payload.notification?.body || 'Student entry or exit was recorded.',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
