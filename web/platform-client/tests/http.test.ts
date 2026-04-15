import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { httpRequest, defaultHttpConfig } from "../src/internal/http.js";
import { AuthError, RateLimitedError, ServiceError, NetworkError, CircuitOpenError } from "../src/internal/errors.js";

function mockFetch(responses: Array<{ status: number; body?: unknown } | Error>) {
  let i = 0;
  return vi.fn(async () => {
    const r = responses[i++];
    if (r instanceof Error) throw r;
    return {
      ok: r.status >= 200 && r.status < 300,
      status: r.status,
      json: async () => r.body ?? {},
    } as Response;
  });
}

describe("httpRequest", () => {
  const baseUrl = "https://svc.test";
  const origFetch = globalThis.fetch;

  beforeEach(() => {
    vi.useRealTimers();
  });
  afterEach(() => {
    globalThis.fetch = origFetch;
    vi.restoreAllMocks();
  });

  it("ok: respuesta 200 retorna { ok: true, data }", async () => {
    globalThis.fetch = mockFetch([{ status: 200, body: { hello: "world" } }]) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 0 });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.ok).toBe(true);
    expect(r.data).toEqual({ hello: "world" });
  });

  it("401: sin retry, errorInstance=AuthError", async () => {
    globalThis.fetch = mockFetch([{ status: 401, body: { error: "invalid" } }]) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 3 });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.ok).toBe(false);
    expect(r.status).toBe(401);
    expect(r.errorInstance).toBeInstanceOf(AuthError);
    expect(globalThis.fetch).toHaveBeenCalledTimes(1); // sin retry
  });

  it("429: errorInstance=RateLimitedError con retryAfter", async () => {
    globalThis.fetch = mockFetch([{ status: 429, body: { error: "too many", retryAfter: 15 } }]) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 0 });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.errorInstance).toBeInstanceOf(RateLimitedError);
    expect((r.errorInstance as RateLimitedError).retryAfterSec).toBe(15);
  });

  it("5xx: reintenta hasta `retries` veces", async () => {
    globalThis.fetch = mockFetch([
      { status: 502, body: {} },
      { status: 502, body: {} },
      { status: 200, body: { ok: true } },
    ]) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 2 });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.ok).toBe(true);
    expect(globalThis.fetch).toHaveBeenCalledTimes(3);
  });

  it("network error: reintenta y si persiste retorna NetworkError", async () => {
    globalThis.fetch = mockFetch([
      new Error("ECONNRESET"),
      new Error("ECONNRESET"),
    ]) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 1 });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.ok).toBe(false);
    expect(r.errorInstance).toBeInstanceOf(NetworkError);
  });

  it("circuit breaker: tras N 5xx rechaza sin llamar fetch", async () => {
    globalThis.fetch = mockFetch(Array(10).fill({ status: 500, body: {} })) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 0, circuit: { failureThreshold: 3, cooldownMs: 60_000 } });
    // 3 fallos → breaker abre
    await httpRequest(cfg, { method: "GET", path: "/x" });
    await httpRequest(cfg, { method: "GET", path: "/x" });
    await httpRequest(cfg, { method: "GET", path: "/x" });
    const fourth = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(fourth.errorInstance).toBeInstanceOf(CircuitOpenError);
    expect(globalThis.fetch).toHaveBeenCalledTimes(3); // 4a no llega
  });

  it("4xx NO cuenta para el breaker (es error del caller, no del servicio)", async () => {
    globalThis.fetch = mockFetch(Array(10).fill({ status: 400, body: {} })) as unknown as typeof fetch;
    const cfg = defaultHttpConfig({ baseUrl, retries: 0, circuit: { failureThreshold: 3, cooldownMs: 60_000 } });
    for (let i = 0; i < 5; i++) await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(globalThis.fetch).toHaveBeenCalledTimes(5); // ninguna bloqueada por breaker
  });

  it("beforeRetry: 401 → refresh + retry UNA vez con nuevo header", async () => {
    globalThis.fetch = mockFetch([
      { status: 401, body: { error: "expired" } },
      { status: 200, body: { ok: true, me: "x" } },
    ]) as unknown as typeof fetch;
    const beforeRetry = vi.fn(async () => ({ retry: true, headers: { Authorization: "Bearer NEW" } }));
    const cfg = defaultHttpConfig({ baseUrl, retries: 1, beforeRetry });
    const r = await httpRequest(cfg, { method: "GET", path: "/x" });
    expect(r.ok).toBe(true);
    expect(beforeRetry).toHaveBeenCalledOnce();
    expect(globalThis.fetch).toHaveBeenCalledTimes(2);
  });
});
