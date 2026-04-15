/**
 * Token bucket client-side.
 *
 * Cada cliente HTTP puede configurar un rate limiter que bloquea (awaits)
 * si se agotaron los tokens, hasta que se refilen. Previene que el SDK
 * dispare ráfagas a servicios upstream con políticas estrictas y el server
 * empiece a 429.
 *
 * Ejemplo:
 *   const rl = new TokenBucket({ capacity: 60, refillPerSec: 10 });
 *   await rl.take();  // bloquea si no hay tokens
 */

export interface TokenBucketOptions {
  /** Tokens máximos en el bucket (ráfaga máx). */
  capacity: number;
  /** Tokens añadidos por segundo (tasa sostenida). */
  refillPerSec: number;
}

export class TokenBucket {
  private readonly capacity: number;
  private readonly refillPerMs: number;
  private tokens: number;
  private lastRefill: number;

  constructor(opts: TokenBucketOptions) {
    if (opts.capacity <= 0) throw new Error("capacity must be > 0");
    if (opts.refillPerSec <= 0) throw new Error("refillPerSec must be > 0");
    this.capacity = opts.capacity;
    this.refillPerMs = opts.refillPerSec / 1000;
    this.tokens = opts.capacity;
    this.lastRefill = Date.now();
  }

  /** Mide tokens disponibles ahora (sin consumir). */
  available(): number {
    this.refill();
    return this.tokens;
  }

  /**
   * Toma 1 token. Si no hay disponibles, espera hasta que haya.
   * Resuelve inmediatamente si hay tokens.
   */
  async take(count = 1): Promise<void> {
    if (count <= 0) return;
    while (true) {
      this.refill();
      if (this.tokens >= count) {
        this.tokens -= count;
        return;
      }
      // Tiempo para acumular `count` tokens
      const needed = count - this.tokens;
      const waitMs = Math.ceil(needed / this.refillPerMs);
      await new Promise((r) => setTimeout(r, waitMs));
    }
  }

  /** Reset manual (útil para tests). */
  reset(): void {
    this.tokens = this.capacity;
    this.lastRefill = Date.now();
  }

  private refill(): void {
    const now = Date.now();
    const elapsed = now - this.lastRefill;
    if (elapsed <= 0) return;
    const add = elapsed * this.refillPerMs;
    this.tokens = Math.min(this.capacity, this.tokens + add);
    this.lastRefill = now;
  }
}
