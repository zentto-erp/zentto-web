// Kafka Notification Consumer
// Listens to Kafka topics and auto-populates Sys_Notificaciones + Sys_Tareas
// Best-effort: never blocks API startup or request processing

import { Kafka, Consumer, logLevel, EachMessagePayload } from 'kafkajs';
import { TOPICS } from './observability.js';
import { callSp } from '../../db/query.js';

// ── Configuration ────────────────────────────────────────────────────────────

const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const KAFKA_ENABLED = process.env.KAFKA_ENABLED === 'true';
const GROUP_ID = 'zentto-notifications';

// ── Types ────────────────────────────────────────────────────────────────────

interface NotificationConfig {
  tipo: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR';
  titulo: string;
  mensaje: (data: Record<string, any>) => string;
  ruta: string | null;
  crearTarea?: boolean;
  tarea?: {
    titulo: (data: Record<string, any>) => string;
    color: string;
  };
}

// ── Event → Notification map ─────────────────────────────────────────────────

const EVENT_NOTIFICATION_MAP: Record<string, NotificationConfig> = {
  // --- LOGÍSTICA ---
  'logistics.receipt.created': {
    tipo: 'INFO',
    titulo: 'Recepción de mercancía creada',
    mensaje: (data) => `Recepción ${data.receiptNumber || ''} registrada`,
    ruta: '/logistica/recepciones',
  },
  'logistics.receipt.approved': {
    tipo: 'SUCCESS',
    titulo: 'Recepción aprobada',
    mensaje: (data) => `Recepción ${data.receiptNumber || ''} aprobada y stock actualizado`,
    ruta: '/logistica/recepciones',
  },
  'logistics.return.created': {
    tipo: 'INFO',
    titulo: 'Devolución creada',
    mensaje: (data) => `Devolución ${data.returnNumber || ''} registrada`,
    ruta: '/logistica/devoluciones',
  },
  'logistics.return.approved': {
    tipo: 'SUCCESS',
    titulo: 'Devolución aprobada',
    mensaje: (data) => `Devolución ${data.returnNumber || ''} aprobada`,
    ruta: '/logistica/devoluciones',
  },
  'logistics.delivery.created': {
    tipo: 'INFO',
    titulo: 'Albarán creado',
    mensaje: (data) => `Albarán ${data.deliveryNumber || ''} registrado`,
    ruta: '/logistica/albaranes',
  },
  'logistics.delivery.dispatched': {
    tipo: 'WARNING',
    titulo: 'Albarán despachado',
    mensaje: (data) => `Despacho ${data.deliveryNumber || ''} en camino`,
    ruta: '/logistica/albaranes',
  },
  'logistics.delivery.delivered': {
    tipo: 'SUCCESS',
    titulo: 'Entrega completada',
    mensaje: (data) => `Entrega ${data.deliveryNumber || ''} confirmada`,
    ruta: '/logistica/albaranes',
  },

  // --- FLOTA ---
  'fleet.vehicle.upserted': {
    tipo: 'INFO',
    titulo: 'Vehículo actualizado',
    mensaje: (data) => `Vehículo ${data.licensePlate || ''} registrado/actualizado`,
    ruta: '/flota/vehiculos',
  },
  'fleet.fuel.created': {
    tipo: 'INFO',
    titulo: 'Carga de combustible registrada',
    mensaje: (data) => `Carga de combustible para ${data.licensePlate || ''}`,
    ruta: '/flota/combustible',
  },
  'fleet.maintenance.created': {
    tipo: 'INFO',
    titulo: 'Mantenimiento programado',
    mensaje: (data) => `Orden de mantenimiento creada para vehículo ${data.licensePlate || ''}`,
    ruta: '/flota/mantenimiento',
    crearTarea: true,
    tarea: {
      titulo: (data) => `Mantenimiento: ${data.licensePlate || ''}`,
      color: 'orange',
    },
  },
  'fleet.maintenance.completed': {
    tipo: 'SUCCESS',
    titulo: 'Mantenimiento completado',
    mensaje: (data) => `Mantenimiento de ${data.licensePlate || ''} finalizado`,
    ruta: '/flota/mantenimiento',
  },
  'fleet.trip.created': {
    tipo: 'INFO',
    titulo: 'Viaje iniciado',
    mensaje: (data) => `Viaje ${data.origin || ''} → ${data.destination || ''} registrado`,
    ruta: '/flota/viajes',
  },
  'fleet.trip.completed': {
    tipo: 'SUCCESS',
    titulo: 'Viaje completado',
    mensaje: (data) => `Viaje ${data.origin || ''} → ${data.destination || ''} finalizado`,
    ruta: '/flota/viajes',
  },

  // --- MANUFACTURA ---
  'mfg.bom.created': {
    tipo: 'INFO',
    titulo: 'Lista de materiales creada',
    mensaje: (data) => `BOM ${data.bomCode || ''} registrada`,
    ruta: '/manufactura/bom',
  },
  'mfg.bom.activated': {
    tipo: 'SUCCESS',
    titulo: 'Lista de materiales activada',
    mensaje: (data) => `BOM ${data.bomCode || ''} activada`,
    ruta: '/manufactura/bom',
  },
  'mfg.workorder.created': {
    tipo: 'INFO',
    titulo: 'Orden de producción creada',
    mensaje: (data) => `Orden ${data.workOrderNumber || ''} lista para iniciar`,
    ruta: '/manufactura/ordenes',
    crearTarea: true,
    tarea: {
      titulo: (data) => `Producir: ${data.productName || data.workOrderNumber || ''}`,
      color: 'blue',
    },
  },
  'mfg.workorder.started': {
    tipo: 'WARNING',
    titulo: 'Producción en curso',
    mensaje: (data) => `Orden ${data.workOrderNumber || ''} iniciada`,
    ruta: '/manufactura/ordenes',
  },
  'mfg.workorder.material_consumed': {
    tipo: 'INFO',
    titulo: 'Material consumido',
    mensaje: (data) => `Material consumido en orden ${data.workOrderNumber || ''}`,
    ruta: '/manufactura/ordenes',
  },
  'mfg.workorder.completed': {
    tipo: 'SUCCESS',
    titulo: 'Producción completada',
    mensaje: (data) => `Orden ${data.workOrderNumber || ''} finalizada`,
    ruta: '/manufactura/ordenes',
  },

  // --- AUDIT / SEGURIDAD ---
  'auth.login.failed': {
    tipo: 'ERROR',
    titulo: 'Intento de login fallido',
    mensaje: (data) => `Login fallido desde IP ${data.ip || 'desconocida'}`,
    ruta: null,
  },
};

// ── Consumer logic ───────────────────────────────────────────────────────────

let consumer: Consumer | null = null;

async function processMessage(payload: EachMessagePayload): Promise<void> {
  const { topic, message } = payload;
  if (!message.value) return;

  try {
    const data = JSON.parse(message.value.toString()) as Record<string, any>;

    // Direct notifications from zentto-notifications topic
    if (topic === TOPICS.NOTIFICATIONS) {
      await insertNotification(
        data.tipo || 'INFO',
        data.titulo || 'Notificación',
        data.mensaje || '',
        data.usuarioId || null,
        data.ruta || null,
      );
      return;
    }

    // Event-based notifications from events/audit topics
    const eventName: string = data.event || data.action || '';
    if (!eventName) return;

    const config = EVENT_NOTIFICATION_MAP[eventName];
    if (!config) {
      // No mapping — skip silently (too noisy to log every unmatched event)
      return;
    }

    // 1. Insert notification
    const mensajeText = safeCall(config.mensaje, data);
    await insertNotification(
      config.tipo,
      config.titulo,
      mensajeText,
      data.userId?.toString() || data.usuarioId || null,
      config.ruta,
    );

    // 2. Optionally create a task
    if (config.crearTarea && config.tarea) {
      const tareaTitulo = safeCall(config.tarea.titulo, data);
      await insertTarea(
        tareaTitulo,
        mensajeText,
        config.tarea.color,
        data.userId?.toString() || data.usuarioId || null,
        null, // fecha vencimiento — no la tenemos desde el evento
      );
    }
  } catch (err) {
    console.error('[kafka-consumer] Error processing message:', (err as Error).message);
  }
}

function safeCall(fn: (data: Record<string, any>) => string, data: Record<string, any>): string {
  try {
    return fn(data);
  } catch {
    return '';
  }
}

async function insertNotification(
  tipo: string,
  titulo: string,
  mensaje: string,
  usuarioId: string | null,
  ruta: string | null,
): Promise<void> {
  try {
    await callSp('usp_Sys_Notificacion_Insert', {
      Tipo: tipo,
      Titulo: titulo,
      Mensaje: mensaje,
      UsuarioId: usuarioId,
      RutaNavegacion: ruta,
    });
  } catch (err) {
    console.error('[kafka-consumer] Failed to insert notification:', (err as Error).message);
  }
}

async function insertTarea(
  titulo: string,
  descripcion: string,
  color: string,
  asignadoA: string | null,
  fechaVencimiento: string | null,
): Promise<void> {
  try {
    await callSp('usp_Sys_Tarea_Insert', {
      Titulo: titulo,
      Descripcion: descripcion,
      Color: color,
      AsignadoA: asignadoA,
      FechaVencimiento: fechaVencimiento,
    });
  } catch (err) {
    console.error('[kafka-consumer] Failed to insert tarea:', (err as Error).message);
  }
}

// ── Public API ───────────────────────────────────────────────────────────────

export async function startNotificationConsumer(): Promise<void> {
  if (!KAFKA_ENABLED) {
    console.log('[kafka-consumer] Kafka disabled (KAFKA_ENABLED != true), skipping');
    return;
  }

  try {
    const kafka = new Kafka({
      clientId: 'zentto-notification-consumer',
      brokers: KAFKA_BROKERS,
      logLevel: logLevel.WARN,
      retry: { initialRetryTime: 2000, retries: 5 },
    });

    consumer = kafka.consumer({ groupId: GROUP_ID });
    await consumer.connect();

    // Subscribe to event, audit and direct notification topics
    await consumer.subscribe({ topics: [TOPICS.EVENTS, TOPICS.AUDIT, TOPICS.NOTIFICATIONS], fromBeginning: false });

    await consumer.run({
      eachMessage: processMessage,
    });

    console.log('[kafka-consumer] Notification consumer started — listening to events, audit, notifications');
  } catch (err) {
    console.warn('[kafka-consumer] Failed to start:', (err as Error).message);
  }
}

export async function stopNotificationConsumer(): Promise<void> {
  if (consumer) {
    try {
      await consumer.disconnect();
      consumer = null;
      console.log('[kafka-consumer] Disconnected');
    } catch (err) {
      console.error('[kafka-consumer] Error disconnecting:', (err as Error).message);
    }
  }
}
