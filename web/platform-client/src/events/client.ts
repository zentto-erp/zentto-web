/**
 * EventBusClient — producer + consumer de eventos Zentto sobre Kafka.
 *
 * `kafkajs` es una dependencia OPCIONAL. El paquete es zero-deps para callers
 * que no usan eventos. Si un caller importa este submódulo sin kafkajs
 * instalado, el constructor lanza con un mensaje claro.
 *
 * Uso:
 *   import { EventBusClient } from "@zentto/platform-client/events";
 *
 *   const bus = new EventBusClient({
 *     brokers: ["kafka:9092"],
 *     source: "zentto-hotel",
 *     tenantCode: "ACME",
 *   });
 *
 *   // Producer
 *   await bus.connect();
 *   await bus.publish({ eventType: "hotel.reservation.confirmed", data: {...} });
 *
 *   // Consumer (otro proceso)
 *   bus.on("crm.lead.created", async (evt) => { ... });
 *   bus.on(/crm\..+/, async (evt) => { ... });
 *   await bus.start();
 */
import { buildEnvelope, topicName, type EventEnvelope } from "./envelope.js";

export interface EventBusConfig {
  brokers: string[];
  source: string;
  /** TenantCode por default para `publish`. Override por-llamada con `.publish({ tenantCode })`. */
  tenantCode: string;
  clientId?: string;
  groupId?: string;
  /** Log level: default "warn". */
  logLevel?: "debug" | "info" | "warn" | "error" | "nothing";
  /** Dedup por eventId. Default: en memoria con TTL 10min. */
  dedup?: EventDedup;
  onError?: (err: Error, ctx: { where: string; topic?: string; eventId?: string }) => void;
}

export interface EventDedup {
  seen(eventId: string): Promise<boolean>;
  mark(eventId: string): Promise<void>;
}

type Handler = (evt: EventEnvelope, raw: { topic: string; partition: number; offset: string }) => Promise<void> | void;
type Subscription = { pattern: string | RegExp; handler: Handler };

export class EventBusClient {
  private readonly cfg: EventBusConfig;
  private readonly subs: Subscription[] = [];
  private producer: unknown | undefined;
  private consumer: unknown | undefined;
  private started = false;
  private connected = false;

  constructor(cfg: EventBusConfig) {
    this.cfg = {
      clientId: `zentto-${cfg.source}-${process.pid}`,
      groupId: `zentto-${cfg.source}`,
      logLevel: "warn",
      dedup: new InMemoryDedup(),
      onError: () => {},
      ...cfg,
    };
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  async connect(): Promise<void> {
    if (this.connected) return;
    const { Kafka } = await loadKafka();
    const kafka = new Kafka({
      clientId: this.cfg.clientId,
      brokers: this.cfg.brokers,
      logLevel: mapLogLevel(this.cfg.logLevel!),
      retry: { initialRetryTime: 2000, retries: 5 },
    });
    this.producer = kafka.producer({ idempotent: true, maxInFlightRequests: 1 });
    this.consumer = kafka.consumer({ groupId: this.cfg.groupId! });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await (this.producer as any).connect();
    this.connected = true;
  }

  async disconnect(): Promise<void> {
    if (!this.connected) return;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if (this.producer) await (this.producer as any).disconnect().catch(() => {});
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if (this.consumer && this.started) await (this.consumer as any).disconnect().catch(() => {});
    this.connected = false;
    this.started = false;
  }

  // ── Producer ─────────────────────────────────────────────────────────────
  async publish<T>(params: {
    eventType: string;
    data: T;
    tenantCode?: string;
    tenantId?: number;
    correlationId?: string;
    version?: number;
    eventId?: string;
  }): Promise<EventEnvelope<T>> {
    if (!this.connected) await this.connect();
    const tenantCode = (params.tenantCode ?? this.cfg.tenantCode).toUpperCase();
    const envelope = buildEnvelope<T>({
      eventType: params.eventType,
      tenantCode,
      tenantId: params.tenantId,
      source: this.cfg.source,
      data: params.data,
      version: params.version,
      correlationId: params.correlationId,
      eventId: params.eventId,
    });
    const topic = topicName(tenantCode, params.eventType);
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (this.producer as any).send({
        topic,
        messages: [{ key: tenantCode, value: JSON.stringify(envelope) }],
      });
    } catch (err) {
      this.cfg.onError!(err as Error, { where: "publish", topic, eventId: envelope.eventId });
      throw err;
    }
    return envelope;
  }

  // ── Consumer ─────────────────────────────────────────────────────────────
  on(pattern: string | RegExp, handler: Handler): void {
    this.subs.push({ pattern, handler });
  }

  async start(opts?: { fromBeginning?: boolean; topics?: (string | RegExp)[] }): Promise<void> {
    if (this.started) return;
    if (!this.connected) await this.connect();

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const consumer = this.consumer as any;
    await consumer.connect();
    const topics: (string | RegExp)[] = opts?.topics ?? [/^zentto\..+/];
    for (const t of topics) {
      await consumer.subscribe({ topic: t, fromBeginning: opts?.fromBeginning ?? false });
    }

    await consumer.run({
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      eachMessage: async ({ topic, partition, message }: any) => {
        const raw = message.value?.toString("utf-8");
        if (!raw) return;
        let envelope: EventEnvelope;
        try {
          envelope = JSON.parse(raw) as EventEnvelope;
        } catch (err) {
          this.cfg.onError!(err as Error, { where: "decode", topic });
          return;
        }
        // Dedup
        if (await this.cfg.dedup!.seen(envelope.eventId)) return;
        await this.cfg.dedup!.mark(envelope.eventId);

        // Dispatch a handlers que matcheen el eventType o el topic
        for (const sub of this.subs) {
          const ok = typeof sub.pattern === "string"
            ? envelope.eventType === sub.pattern || topic === sub.pattern
            : sub.pattern.test(envelope.eventType) || sub.pattern.test(topic);
          if (!ok) continue;
          try {
            await sub.handler(envelope, { topic, partition, offset: message.offset });
          } catch (err) {
            this.cfg.onError!(err as Error, { where: "handler", topic, eventId: envelope.eventId });
          }
        }
      },
    });
    this.started = true;
  }
}

// ── Dedup in-memory (default) ───────────────────────────────────────────────
export class InMemoryDedup implements EventDedup {
  private readonly seenAt = new Map<string, number>();
  constructor(private readonly ttlMs = 10 * 60 * 1000) {}

  async seen(eventId: string): Promise<boolean> {
    this.sweep();
    return this.seenAt.has(eventId);
  }
  async mark(eventId: string): Promise<void> {
    this.seenAt.set(eventId, Date.now());
  }
  private sweep() {
    const cutoff = Date.now() - this.ttlMs;
    for (const [k, t] of this.seenAt) {
      if (t < cutoff) this.seenAt.delete(k);
    }
  }
}

// ── Kafka loading (optional dep) ────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadKafka(): Promise<{ Kafka: any }> {
  try {
    // optional peer dep — resolve dinámico para no requerir tipos/install.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const mod: any = await import(/* @vite-ignore */ "kafkajs" as string);
    return { Kafka: mod.Kafka };
  } catch (err) {
    throw new Error(
      "EventBusClient requires `kafkajs` to be installed.\n" +
      "Run: npm install kafkajs\n" +
      "(kafkajs es una optional dependency de @zentto/platform-client — se carga solo si importás el submódulo /events)",
    );
  }
}

function mapLogLevel(l: NonNullable<EventBusConfig["logLevel"]>): number {
  // kafkajs logLevel: NOTHING=0, ERROR=1, WARN=2, INFO=4, DEBUG=5
  return { nothing: 0, error: 1, warn: 2, info: 4, debug: 5 }[l] ?? 2;
}

/**
 * Factory desde env vars:
 *   KAFKA_BROKERS — CSV (obligatoria)
 *   ZENTTO_SERVICE_NAME — source (obligatoria)
 *   ZENTTO_TENANT_CODE — tenantCode default
 */
export function eventsFromEnv(overrides?: Partial<EventBusConfig>): EventBusClient {
  const brokers = (process.env.KAFKA_BROKERS ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  const source = process.env.ZENTTO_SERVICE_NAME ?? "unknown-service";
  const tenantCode = process.env.ZENTTO_TENANT_CODE ?? "ZENTTO";
  return new EventBusClient({ brokers, source, tenantCode, ...overrides });
}
