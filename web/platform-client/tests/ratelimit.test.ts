import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { TokenBucket } from "../src/internal/ratelimit.js";

describe("TokenBucket", () => {
  afterEach(() => vi.useRealTimers());

  it("arranca con capacity tokens", () => {
    const b = new TokenBucket({ capacity: 5, refillPerSec: 1 });
    expect(b.available()).toBe(5);
  });

  it("take consume tokens inmediatos si hay", async () => {
    const b = new TokenBucket({ capacity: 3, refillPerSec: 1 });
    const t0 = Date.now();
    await b.take();
    await b.take();
    await b.take();
    expect(Date.now() - t0).toBeLessThan(50);
    expect(b.available()).toBe(0);
  });

  it("take bloquea si no hay tokens y los espera", async () => {
    const b = new TokenBucket({ capacity: 1, refillPerSec: 100 }); // 1 token / 10ms
    await b.take(); // consume el único
    const t0 = Date.now();
    await b.take();
    expect(Date.now() - t0).toBeGreaterThanOrEqual(5); // al menos ~10ms
  });

  it("refill suma tokens proporcionalmente al tiempo", async () => {
    const b = new TokenBucket({ capacity: 10, refillPerSec: 10 }); // 1 cada 100ms
    await b.take(5);
    expect(b.available()).toBeCloseTo(5, 0);
    await new Promise((r) => setTimeout(r, 200)); // ~2 tokens
    const after = b.available();
    expect(after).toBeGreaterThanOrEqual(6);
    expect(after).toBeLessThanOrEqual(10);
  });

  it("no excede capacity en refill largo", async () => {
    const b = new TokenBucket({ capacity: 5, refillPerSec: 100 });
    await new Promise((r) => setTimeout(r, 200));
    expect(b.available()).toBe(5);
  });

  it("rechaza capacity/refill <= 0", () => {
    expect(() => new TokenBucket({ capacity: 0, refillPerSec: 1 })).toThrow();
    expect(() => new TokenBucket({ capacity: 1, refillPerSec: 0 })).toThrow();
  });
});
