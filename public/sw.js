// version: 2025-10-10-13:47
/* eslint-disable no-restricted-globals, no-console */
/* globals clients */

// 🧠 Estado temporal (vive mientras el SW esté activo)
const activeConversations = {};
const COOLDOWN_MS = 60 * 1000; // 1 minuto

self.addEventListener('push', event => {
  let notificationData = {};
  try {
    notificationData = event.data?.json() || {};
  } catch (error) {
    console.error('❌ Error al parsear notificación JSON:', error);
    return;
  }

  const { title, tag, url } = notificationData;
  if (!tag || !url) return;

  console.log('📩 Notificación recibida:', tag, notificationData);

  // 🧩 1. Detectar conversación y tipo de evento
  let conversationId = null;
  let type = null;

  // Extraer el conversationId (funciona tanto para ambos tipos)
  const match = tag.match(/_(\d+)_/);
  if (match) conversationId = match[1];

  // Clasificar el tipo según el prefijo
  if (tag.startsWith('assigned_conversation_new_message')) {
    type = 'new_message';
  } else if (tag.startsWith('conversation_assignment')) {
    type = 'assignment';
  }

  console.log(`📦 Tipo detectado: ${type} — Conversación: ${conversationId}`);

  // 🚫 Si no tiene ID, mostrar normal y salir
  if (!conversationId) {
    console.log('⚠️ No se detectó conversationId, mostrando notificación normal.');
    event.waitUntil(
      self.registration.showNotification(title || 'Nuevo mensaje', {
        tag,
        data: { url },
      })
    );
    return;
  }

  const now = Date.now();
  const lastTime = activeConversations[conversationId] || 0;
  const diff = now - lastTime;

  // 🧠 2. Si llega un "assignment", registramos la interacción sin bloquearlo
  if (type === 'assignment') {
    console.log(`📝 Registro de asignación para conversación #${conversationId}`);
    activeConversations[conversationId] = now; // guarda timestamp

    // ✅ Mostramos notificación de asignación
    event.waitUntil(
      self.registration.showNotification(title || 'Nueva asignación', {
        tag,
        data: { url },
      })
    );
    return;
  }

  // 🧠 3. Si llega un "new_message" de una conversación activa → ignorar si dentro del minuto
  if (type === 'new_message') {
    if (diff < COOLDOWN_MS) {
      console.log(`⏸️ Ignorando mensaje repetido de conversación #${conversationId}`);
      return;
    }

    // ✅ Si ya pasó 1 minuto, actualiza el timestamp y muestra
    activeConversations[conversationId] = now;
    console.log(`✅ Mostrando nuevo mensaje de conversación #${conversationId}`);

    event.waitUntil(
      self.registration.showNotification(title || 'Nuevo mensaje', {
        tag,
        data: { url },
      })
    );
    return;
  }

  // 🧩 4. Si es otro tipo, mostrar normalmente
  console.log('ℹ️ Tipo de notificación no controlado, se muestra normal.');
  event.waitUntil(
    self.registration.showNotification(title || 'Notificación', {
      tag,
      data: { url },
    })
  );
});

// 🔗 Click en notificación
self.addEventListener('notificationclick', event => {
  const { notification } = event;
  const { url } = notification.data || {};
  notification.close();

  if (!url) return;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(windowClients => {
      console.log('🪟 Ventanas actuales:', windowClients.map(c => c.url));

      const existingClient = windowClients.find(client =>
        client.url.includes('https://agent.sdsigma.com/app')
      );

      if (existingClient) {
        console.log('✅ Foco en ventana existente y navegación');
        existingClient.focus();
        existingClient.navigate(url);
      } else {
        console.log('🆕 Abriendo nueva pestaña');
        clients.openWindow(url);
      }
    })
  );
});