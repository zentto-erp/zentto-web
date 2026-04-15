/**
 * Circuit breaker minimal — un breaker por (baseUrl, path-prefix).
 *
 * Estados:
 *   closed  → pasa tráfico. Cuenta fallos consecutivos.
 *   open    → rechaza inmediato. Despeja tras cooldown.
 *   half    → deja pasar 1 request de prueba. Si falla, vuelve a open.
 *             Si pasa, vuelve a closed.
 *
 * Evita cascade failures cuando un servicio upstream se cae.
 */

export interface CircuitOptions {
  /** Fallos consecutivos antes de abrir. Default 5. */
  failureThreshold?: number;
  /** Tiempo en open antes de probar half. Default 30s. */
  cooldownMs?: number;
}

type State = "closed" | "open" | "half";

interface Slot {
  state: State;
  consecutiveFailures: number;
  openedAt: number;
  halfInFlight: boolean;
}

export class CircuitBreaker {
  private readonly failureThreshold: number;
  private readonly cooldownMs: number;
  private readonly slots = new Map<string, Slot>();

  constructor(opts: CircuitOptions = {}) {
    this.failureThreshold = Math.max(1, opts.failureThreshold ?? 5);
    this.cooldownMs = Math.max(1000, opts.cooldownMs ?? 30_000);
  }

  private slot(key: string): Slot {
    let s = this.slots.get(key);
    if (!s) {
      s = { state: "closed", consecutiveFailures: 0, openedAt: 0, halfInFlight: false };
      this.slots.set(key, s);
    }
    return s;
  }

  /** Llamado antes de disparar un request. Retorna false si el circuito está abierto. */
  allow(key: string): boolean {
    const s = this.slot(key);
    if (s.state === "closed") return true;
    if (s.state === "open") {
      if (Date.now() - s.openedAt >= this.cooldownMs) {
        s.state = "half";
        s.halfInFlight = false;
      } else {
        return false;
      }
    }
    // half: solo 1 in-flight a la vez
    if (s.halfInFlight) return false;
    s.halfInFlight = true;
    return true;
  }

  recordSuccess(key: string): void {
    const s = this.slot(key);
    s.consecutiveFailures = 0;
    s.halfInFlight = false;
    s.state = "closed";
  }

  recordFailure(key: string): void {
    const s = this.slot(key);
    s.consecutiveFailures++;
    s.halfInFlight = false;
    if (s.state === "half") {
      s.state = "open";
      s.openedAt = Date.now();
      return;
    }
    if (s.consecutiveFailures >= this.failureThreshold) {
      s.state = "open";
      s.openedAt = Date.now();
    }
  }

  /** Sólo para tests/debug. */
  _state(key: string): State {
    return this.slot(key).state;
  }
}
