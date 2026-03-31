import { sendToKafka, disconnectProducer } from './producer.js';
import type { ObsConfig, ObsInstance, ObsTopics, HttpRequestEntry, AuditDetails } from './types.js';

/**
 * Build topic names for a service.
 * Pattern: zentto-{service}-{category}
 */
function buildTopics(service: string): ObsTopics {
  const base = service.startsWith('zentto-') ? service : `zentto-${service}`;
  return {
    logs: `${base}-logs`,
    errors: `${base}-errors`,
    audit: `${base}-audit`,
    performance: `${base}-performance`,
    events: `${base}-events`,
  };
}

/**
 * Create an obs instance for a service.
 *
 * @example
 * ```ts
 * import { createObs } from '@zentto/obs';
 *
 * const obs = createObs({
 *   service: 'zentto-api',
 *   kafka: { enabled: true, brokers: ['localhost:9092'] },
 * });
 *
 * obs.log('info', 'Server started', { port: 4000 });
 * obs.error(new Error('oops'), { handler: 'getUsers' });
 * obs.audit('user.login', { userId: 1, ip: '1.2.3.4' });
 * obs.perf('db.query', 150, { query: 'SELECT ...' });
 * obs.event('invoice.created', { companyId: 1 });
 * ```
 */
export function createObs(config: ObsConfig): ObsInstance {
  const service = config.service;
  const kafkaEnabled = config.kafka?.enabled ?? false;
  const brokers = config.kafka?.brokers ?? ['localhost:9092'];
  const slowThresholdMs = config.slowThresholdMs ?? 1000;
  const topics = buildTopics(service);

  function send(topic: string, data: Record<string, unknown>): void {
    // Fire-and-forget — never block the caller
    sendToKafka(topic, { ...data, service }, kafkaEnabled, service, brokers).catch(() => {});
  }

  const instance: ObsInstance = {
    service,
    topics,

    log(level, message, meta) {
      send(topics.logs, { level, message, ...meta });
    },

    error(error, context) {
      const err = error instanceof Error ? error : new Error(String(error));
      send(topics.errors, {
        level: 'error',
        message: err.message,
        stack: err.stack,
        name: err.name,
        ...context,
      });
    },

    audit(action, details) {
      send(topics.audit, { action, ...details });
    },

    perf(operation, durationMs, meta) {
      send(topics.performance, { operation, durationMs, ...meta });
    },

    event(eventName, data) {
      send(topics.events, { event: eventName, ...data });
    },

    httpRequest(entry: HttpRequestEntry) {
      const topic = entry.statusCode >= 500 ? topics.errors : topics.logs;
      send(topic, { type: 'http', ...entry });

      // Also track slow requests
      if (entry.durationMs > slowThresholdMs) {
        send(topics.performance, {
          type: 'slow-request',
          operation: `${entry.method} ${entry.path}`,
          durationMs: entry.durationMs,
          statusCode: entry.statusCode,
          userId: entry.userId,
          companyId: entry.companyId,
        });
      }
    },

    async disconnect() {
      await disconnectProducer();
    },
  };

  return instance;
}
