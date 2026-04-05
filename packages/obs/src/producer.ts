import { Kafka, Producer, logLevel } from 'kafkajs';

let producer: Producer | null = null;
let connected = false;
let connecting = false;

/**
 * Lazy-initialized Kafka producer singleton.
 * Returns null if Kafka is disabled or unavailable.
 */
export async function getProducer(
  clientId: string,
  brokers: string[],
): Promise<Producer | null> {
  if (producer && connected) return producer;
  if (connecting) return null;

  connecting = true;
  try {
    const kafka = new Kafka({
      clientId,
      brokers,
      logLevel: logLevel.WARN,
      retry: { initialRetryTime: 1000, retries: 3 },
    });

    producer = kafka.producer();
    await producer.connect();
    connected = true;
    console.log(`[@zentto/obs] Kafka producer connected (${clientId})`);
    return producer;
  } catch {
    console.warn(`[@zentto/obs] Kafka not available for ${clientId}, using console fallback`);
    return null;
  } finally {
    connecting = false;
  }
}

/**
 * Send a structured message to a Kafka topic.
 * Falls back to console if Kafka is unavailable.
 */
export async function sendToKafka(
  topic: string,
  data: Record<string, unknown>,
  kafkaEnabled: boolean,
  clientId: string,
  brokers: string[],
): Promise<void> {
  const message = {
    ...data,
    timestamp: new Date().toISOString(),
    topic,
  };

  if (kafkaEnabled) {
    const prod = await getProducer(clientId, brokers);
    if (prod) {
      try {
        await prod.send({
          topic,
          messages: [{ value: JSON.stringify(message) }],
        });
        return;
      } catch {
        // Fall through to console
      }
    }
  }

  // Console fallback
  const level = (data.level as string) || 'info';
  const prefix = `[${topic}]`;
  if (level === 'error') {
    console.error(prefix, JSON.stringify(message));
  } else {
    console.log(prefix, JSON.stringify(message));
  }
}

/**
 * Disconnect the Kafka producer gracefully.
 */
export async function disconnectProducer(): Promise<void> {
  if (producer && connected) {
    await producer.disconnect();
    connected = false;
    producer = null;
  }
}
