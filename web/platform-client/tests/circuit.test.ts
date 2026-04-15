import { describe, it, expect, vi } from "vitest";
import { CircuitBreaker } from "../src/internal/circuit.js";

describe("CircuitBreaker", () => {
  it("allows requests when closed", () => {
    const b = new CircuitBreaker();
    expect(b.allow("a")).toBe(true);
    expect(b._state("a")).toBe("closed");
  });

  it("opens after N consecutive failures", () => {
    const b = new CircuitBreaker({ failureThreshold: 3 });
    for (let i = 0; i < 3; i++) {
      expect(b.allow("a")).toBe(true);
      b.recordFailure("a");
    }
    expect(b._state("a")).toBe("open");
    expect(b.allow("a")).toBe(false);
  });

  it("success resets failure counter", () => {
    const b = new CircuitBreaker({ failureThreshold: 3 });
    b.allow("a"); b.recordFailure("a");
    b.allow("a"); b.recordFailure("a");
    b.allow("a"); b.recordSuccess("a");
    b.allow("a"); b.recordFailure("a");
    expect(b._state("a")).toBe("closed");
  });

  it("goes half-open after cooldown", async () => {
    vi.useFakeTimers();
    const b = new CircuitBreaker({ failureThreshold: 1, cooldownMs: 1000 });
    b.allow("a"); b.recordFailure("a");
    expect(b._state("a")).toBe("open");
    expect(b.allow("a")).toBe(false);
    vi.advanceTimersByTime(1001);
    expect(b.allow("a")).toBe(true);
    expect(b._state("a")).toBe("half");
    vi.useRealTimers();
  });

  it("keys are independent", () => {
    const b = new CircuitBreaker({ failureThreshold: 1 });
    b.allow("a"); b.recordFailure("a");
    expect(b.allow("a")).toBe(false);
    expect(b.allow("b")).toBe(true);
  });
});
