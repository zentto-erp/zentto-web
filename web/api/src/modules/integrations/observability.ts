// Zentto Observability — powered by @zentto/obs SDK
// Re-exports a configured obs instance for the API service

import { createObs } from '@zentto/obs';

const KAFKA_BROKERS = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const KAFKA_ENABLED = process.env.KAFKA_ENABLED === 'true';
const SERVICE_NAME = process.env.SERVICE_NAME || 'zentto-api';

export const obs = createObs({
  service: SERVICE_NAME,
  kafka: {
    enabled: KAFKA_ENABLED,
    brokers: KAFKA_BROKERS,
  },
  slowThresholdMs: 1000,
});

// Backward-compatible TOPICS (uppercase keys as before)
export const TOPICS = {
  LOGS: obs.topics.logs,
  ERRORS: obs.topics.errors,
  AUDIT: obs.topics.audit,
  PERFORMANCE: obs.topics.performance,
  EVENTS: obs.topics.events,
  NOTIFICATIONS: 'zentto-notifications',
} as const;
