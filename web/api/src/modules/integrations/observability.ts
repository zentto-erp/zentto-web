// Zentto Observability — Kafka-based logging & event streaming
// Sends structured logs to Kafka topics for Elasticsearch/Kibana processing

import { Kafka, Producer, logLevel } from 'kafkajs';

const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const KAFKA_ENABLED = process.env.KAFKA_ENABLED === 'true';
const SERVICE_NAME = process.env.SERVICE_NAME || 'zentto-api';

// Kafka topics
export const TOPICS = {
  LOGS: 'zentto-api-logs',
  ERRORS: 'zentto-api-errors',
  AUDIT: 'zentto-api-audit',
  PERFORMANCE: 'zentto-api-performance',
  EVENTS: 'zentto-api-events',
  NOTIFICATIONS: 'zentto-notifications',
} as const;

let producer: Producer | null = null;
let connected = false;

async function getProducer(): Promise<Producer | null> {
  if (!KAFKA_ENABLED) return null;
  if (producer && connected) return producer;

  try {
    const kafka = new Kafka({
      clientId: SERVICE_NAME,
      brokers: KAFKA_BROKERS,
      logLevel: logLevel.WARN,
      retry: { initialRetryTime: 1000, retries: 3 },
    });

    producer = kafka.producer();
    await producer.connect();
    connected = true;
    console.log('[observability] Kafka producer connected');
    return producer;
  } catch (err) {
    console.warn('[observability] Kafka not available, using console fallback');
    return null;
  }
}

async function send(topic: string, data: Record<string, any>): Promise<void> {
  const message = {
    ...data,
    service: SERVICE_NAME,
    timestamp: new Date().toISOString(),
    topic,
  };

  const prod = await getProducer();
  if (prod) {
    try {
      await prod.send({
        topic,
        messages: [{ value: JSON.stringify(message) }],
      });
    } catch {
      console.error(`[observability] Failed to send to ${topic}`, message);
    }
  } else {
    // Fallback: console
    if (topic === TOPICS.ERRORS) {
      console.error(`[${topic}]`, JSON.stringify(message));
    } else {
      console.log(`[${topic}]`, JSON.stringify(message));
    }
  }
}

// --- Public API ---

export const obs = {
  // Standard log
  log(level: 'info' | 'warn' | 'debug', message: string, meta?: Record<string, any>) {
    send(TOPICS.LOGS, { level, message, ...meta });
  },

  // Error tracking
  error(error: Error | string, context?: Record<string, any>) {
    const err = error instanceof Error ? error : new Error(String(error));
    send(TOPICS.ERRORS, {
      message: err.message,
      stack: err.stack,
      name: err.name,
      ...context,
    });
  },

  // Audit trail (who did what)
  audit(action: string, details: {
    userId?: number | string;
    userName?: string;
    companyId?: number;
    module?: string;
    entity?: string;
    entityId?: number | string;
    before?: any;
    after?: any;
    ip?: string;
    [key: string]: any;
  }) {
    send(TOPICS.AUDIT, { action, ...details });
  },

  // Performance metrics
  perf(operation: string, durationMs: number, meta?: Record<string, any>) {
    send(TOPICS.PERFORMANCE, { operation, durationMs, ...meta });
  },

  // Business events
  event(eventName: string, data?: Record<string, any>) {
    send(TOPICS.EVENTS, { event: eventName, ...data });
  },

  // HTTP request log (for middleware)
  httpRequest(req: {
    method: string;
    path: string;
    statusCode: number;
    durationMs: number;
    userId?: number;
    companyId?: number;
    ip?: string;
    userAgent?: string;
    body?: any;
    query?: any;
  }) {
    const topic = req.statusCode >= 500 ? TOPICS.ERRORS : TOPICS.LOGS;
    send(topic, {
      type: 'http',
      ...req,
    });

    // Also send to performance topic if slow
    if (req.durationMs > 1000) {
      send(TOPICS.PERFORMANCE, {
        type: 'slow-request',
        operation: `${req.method} ${req.path}`,
        durationMs: req.durationMs,
        statusCode: req.statusCode,
      });
    }
  },

  // Direct notification (writes to zentto-notifications topic)
  notify(config: { tipo: string; titulo: string; mensaje: string; usuarioId?: string; ruta?: string }) {
    send(TOPICS.NOTIFICATIONS, config);
  },

  // Graceful shutdown
  async disconnect() {
    if (producer && connected) {
      await producer.disconnect();
      connected = false;
    }
  },
};
