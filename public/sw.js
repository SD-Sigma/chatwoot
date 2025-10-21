// version: 2025-10-10-13:47
/* eslint-disable no-restricted-globals, no-console */
/* globals clients */

// 🧠 Estado temporal (vive mientras el SW esté activo)
const activeConversations = {};
const COOLDOWN_MS = 60 * 1000; // 1 minuto

// 🔧 VARIABLES BOOLEANAS DE CONTROL
const ENABLE_PUSH_CONTROL = true; // Cambia a false para desactivar el control por intervalo
const ENABLE_LOGS = false; // Cambia a false para desactivar los logs

// 🔧 Función de logging condicional
function log(message, emoji = '📝') {
  if (ENABLE_LOGS) {
    console.log(`${emoji} ${message}`);
  }
}

self.addEventListener('push', event => {
  let notificationData = {};
  try {
    notificationData = event.data?.json() || {};
  } catch (error) {
    if (ENABLE_LOGS) {
      console.error('❌ Error al parsear notificación JSON:', error);
    }
    return;
  }

  const { title, tag, url } = notificationData;
  if (!tag || !url) return;

  log('Notificación recibida: ' + tag, '📩');
  log(`Control de push: ${ENABLE_PUSH_CONTROL ? 'ACTIVADO' : 'DESACTIVADO'}`, '🔧');
  log(`Logs: ${ENABLE_LOGS ? 'ACTIVADOS' : 'DESACTIVADOS'}`, '📋');

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

  log(`Tipo detectado: ${type} — Conversación: ${conversationId}`, '📦');

  // 🚫 Si no tiene ID, mostrar normal y salir
  if (!conversationId) {
    log('No se detectó conversationId, mostrando notificación normal.', '⚠️');
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

  if (ENABLE_LOGS) {
    console.log(`⏰ Timestamp actual: ${now}, último: ${lastTime}, diferencia: ${diff}ms, límite: ${COOLDOWN_MS}ms`);
  }

  // 🧠 2. Si llega un "assignment", registramos la interacción sin bloquearlo
  if (type === 'assignment') {
    log(`Registro de asignación para conversación #${conversationId}`, '📝');
    
    // Solo actualizar timestamp si el control está activado
    if (ENABLE_PUSH_CONTROL) {
      activeConversations[conversationId] = now;
      log(`Timestamp actualizado para conversación #${conversationId}: ${now}`, '⏰');
    }

    // ✅ Mostramos notificación de asignación
    event.waitUntil(
      self.registration.showNotification(title || 'Nueva asignación', {
        tag,
        data: { url },
      })
    );
    return;
  }

  // 🧠 3. Si llega un "new_message" y el control está ACTIVADO
  if (type === 'new_message' && ENABLE_PUSH_CONTROL) {
    if (diff < COOLDOWN_MS) {
      log(`Ignorando mensaje repetido de conversación #${conversationId} (${diff}ms < ${COOLDOWN_MS}ms)`, '⏸️');
      return;
    }

    // ✅ Si ya pasó 1 minuto, actualiza el timestamp y muestra
    activeConversations[conversationId] = now;
    log(`Mostrando nuevo mensaje de conversación #${conversationId} (pasaron ${diff}ms)`, '✅');

    event.waitUntil(
      self.registration.showNotification(title || 'Nuevo mensaje', {
        tag,
        data: { url },
      })
    );
    return;
  }

  // 🧠 4. Si llega un "new_message" y el control está DESACTIVADO
  if (type === 'new_message' && !ENABLE_PUSH_CONTROL) {
    log(`Control desactivado - Mostrando todos los mensajes de conversación #${conversationId}`, '🔓');
    
    event.waitUntil(
      self.registration.showNotification(title || 'Nuevo mensaje', {
        tag,
        data: { url },
      })
    );
    return;
  }

  // 🧩 5. Si es otro tipo, mostrar normalmente
  log('Tipo de notificación no controlado, se muestra normal.', 'ℹ️');
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
      if (ENABLE_LOGS) {
        console.log('🪟 Ventanas actuales:', windowClients.map(c => c.url));
      }

      const existingClient = windowClients.find(client =>
        client.url.includes('https://agent.sdsigma.com/app')
      );

      if (existingClient) {
        log('Foco en ventana existente y navegación', '✅');
        existingClient.focus();
        existingClient.navigate(url);
      } else {
        log('Abriendo nueva pestaña', '🆕');
        clients.openWindow(url);
      }
    })
  );
});

// 📊 Log inicial al cargar el Service Worker
if (ENABLE_LOGS) {
  console.log('🚀 Service Worker iniciado');
  console.log('🔧 Configuración:');
  console.log('   - Control de push: ' + (ENABLE_PUSH_CONTROL ? 'ACTIVADO' : 'DESACTIVADO'));
  console.log('   - Logs: ' + (ENABLE_LOGS ? 'ACTIVADOS' : 'DESACTIVADOS'));
  console.log('   - Cooldown: ' + COOLDOWN_MS + 'ms');
}