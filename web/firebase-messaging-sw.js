/* Firebase Cloud Messaging service worker for the TaybGo Admin web app. */
importScripts(
  'https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyAx-JBKCauLhDIvMMLjztSVvq3k5PVc8CE',
  authDomain: 'taybgoadmin.firebaseapp.com',
  projectId: 'taybgoadmin',
  storageBucket: 'taybgoadmin.firebasestorage.app',
  messagingSenderId: '927010248626',
  appId: '1:927010248626:web:e5c454c0568e9cff7636ab',
  measurementId: 'G-3VMC8YVSYF',
});

const messaging = firebase.messaging();

const SUPPORT_NOTIFICATION_TYPES = new Set([
  'support_ticket_created',
  'support_message_from_requester',
  'support_ticket_assigned',
]);

function positiveInteger(value) {
  const text = String(value || '').trim();
  return /^[1-9]\d*$/.test(text) ? text : null;
}

// Only derive destinations from the notification contract. Never honor an
// arbitrary URL supplied by a push payload.
function notificationPath(data) {
  const type = String(data.type || '').trim();
  const ticketId = positiveInteger(data.ticket_id);
  if (SUPPORT_NOTIFICATION_TYPES.has(type) && ticketId) {
    return `/support/${ticketId}`;
  }
  return '/notifications';
}

messaging.onBackgroundMessage((payload) => {
  // FCM automatically displays notification payloads in the background. For
  // data-only messages, provide a browser notification ourselves.
  if (payload.notification) return;

  const data = payload.data || {};
  const title = data.title || 'TaybGo Admin';
  const options = {
    body: data.body || 'You have a new notification.',
    icon: '/icons/Icon-192.png',
    data,
  };
  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  const data = event.notification?.data || {};
  const destination = new URL(self.registration.scope);
  destination.hash = notificationPath(data);
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(
      (clientList) => {
        const existingClient = clientList.find((client) =>
          client.url.startsWith(self.registration.scope),
        );
        if (existingClient) {
          return existingClient.focus().then(() =>
            existingClient.navigate(destination.href),
          );
        }
        return clients.openWindow(destination.href);
      },
    ),
  );
});
