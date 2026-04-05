/** Configuration for creating an obs instance */
export interface ObsConfig {
  /** Service name — used as Kafka clientId and in all log entries */
  service: string;
  /** Kafka configuration */
  kafka?: {
    /** Enable Kafka producer (default: false) */
    enabled?: boolean;
    /** Broker addresses (default: ['localhost:9092']) */
    brokers?: string[];
  };
  /** Slow request threshold in ms (default: 1000) */
  slowThresholdMs?: number;
  /** Custom business event mapping for Express middleware: path prefix → event name */
  businessEvents?: Record<string, string>;
  /** Paths to skip in audit middleware (regex patterns) */
  auditSkipPatterns?: RegExp[];
}

/** Resolved topics for a service */
export interface ObsTopics {
  logs: string;
  errors: string;
  audit: string;
  performance: string;
  events: string;
}

/** HTTP request log entry */
export interface HttpRequestEntry {
  method: string;
  path: string;
  statusCode: number;
  durationMs: number;
  userId?: number | string;
  companyId?: number;
  ip?: string;
  userAgent?: string;
  body?: unknown;
  query?: unknown;
}

/** Audit entry details */
export interface AuditDetails {
  userId?: number | string | null;
  userName?: string;
  companyId?: number;
  module?: string;
  entity?: string;
  entityId?: number | string | null;
  before?: unknown;
  after?: unknown;
  ip?: string;
  [key: string]: unknown;
}

/** The public obs API */
export interface ObsInstance {
  /** Service name */
  readonly service: string;
  /** Topic names for this service */
  readonly topics: ObsTopics;

  /** General log */
  log(level: 'info' | 'warn' | 'debug', message: string, meta?: Record<string, unknown>): void;
  /** Error tracking */
  error(error: Error | string, context?: Record<string, unknown>): void;
  /** Audit trail */
  audit(action: string, details: AuditDetails): void;
  /** Performance metric */
  perf(operation: string, durationMs: number, meta?: Record<string, unknown>): void;
  /** Business event */
  event(eventName: string, data?: Record<string, unknown>): void;
  /** HTTP request log (used by middleware) */
  httpRequest(entry: HttpRequestEntry): void;
  /** Graceful shutdown */
  disconnect(): Promise<void>;
}
