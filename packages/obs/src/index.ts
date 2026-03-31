/**
 * @zentto/obs — Zentto Observability SDK
 *
 * Kafka-based structured logging, audit trail, performance metrics & business events.
 * Drop-in for any Node.js/Express backend in the Zentto ecosystem.
 *
 * @example
 * ```ts
 * import { createObs, httpMiddleware, auditMiddleware, errorHandlerMiddleware } from '@zentto/obs';
 *
 * const obs = createObs({
 *   service: 'zentto-api',
 *   kafka: {
 *     enabled: process.env.KAFKA_ENABLED === 'true',
 *     brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
 *   },
 * });
 *
 * // Express middleware
 * app.use(httpMiddleware(obs));
 * app.use('/v1', auditMiddleware(obs, { persistFn: insertAuditLog }));
 * app.use(errorHandlerMiddleware(obs));
 *
 * // Manual usage
 * obs.log('info', 'Server started', { port: 4000 });
 * obs.error(new Error('oops'));
 * obs.audit('user.login', { userId: 1 });
 * obs.perf('db.query', 150);
 * obs.event('invoice.created', { companyId: 1 });
 *
 * // Shutdown
 * await obs.disconnect();
 * ```
 */

export { createObs } from './obs.js';
export { httpMiddleware, auditMiddleware, errorHandlerMiddleware } from './middleware.js';
export type {
  ObsConfig,
  ObsInstance,
  ObsTopics,
  HttpRequestEntry,
  AuditDetails,
} from './types.js';
export type {
  HttpMiddlewareOptions,
  AuditMiddlewareOptions,
  AuditLogEntry,
} from './middleware.js';
