import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { AuthClient } from "../src/auth/client.js";

type Resp = { status: number; body?: unknown };

function sequenceFetch(flow: Resp[]) {
  let i = 0;
  return vi.fn(async () => {
    const r = flow[i++];
    if (!r) throw new Error("out of responses");
    return {
      ok: r.status >= 200 && r.status < 300,
      status: r.status,
      json: async () => r.body ?? {},
    } as Response;
  });
}

describe("AuthClient auto-refresh", () => {
  const origFetch = globalThis.fetch;
  afterEach(() => { globalThis.fetch = origFetch; vi.restoreAllMocks(); });
  beforeEach(() => { vi.useRealTimers(); });

  it("401 en /auth/me → refresh automático → retry con nuevo token", async () => {
    globalThis.fetch = sequenceFetch([
      { status: 401, body: { error: "expired" } },                 // me() inicial
      { status: 200, body: { ok: true, accessToken: "NEW" } },     // refresh()
      { status: 200, body: { user: { email: "x@x.com" } } },       // me() reintento
    ]) as unknown as typeof fetch;

    const c = new AuthClient({ baseUrl: "https://auth.test", accessToken: "OLD", retries: 1 });
    const r = await c.me();
    expect(r.ok).toBe(true);
    expect((r.data as { user: { email: string } }).user.email).toBe("x@x.com");
    expect(globalThis.fetch).toHaveBeenCalledTimes(3);
  });

  it("si el refresh falla, el 401 original se propaga", async () => {
    globalThis.fetch = sequenceFetch([
      { status: 401, body: { error: "expired" } },  // me()
      { status: 401, body: { error: "no refresh cookie" } }, // refresh() también falla
    ]) as unknown as typeof fetch;

    const c = new AuthClient({ baseUrl: "https://auth.test", accessToken: "OLD", retries: 1 });
    const r = await c.me();
    expect(r.ok).toBe(false);
    expect(r.status).toBe(401);
  });

  it("el endpoint /auth/refresh no se reintenta a sí mismo", async () => {
    globalThis.fetch = sequenceFetch([
      { status: 401, body: {} }, // refresh() falla directo
    ]) as unknown as typeof fetch;

    const c = new AuthClient({ baseUrl: "https://auth.test", retries: 3 });
    const r = await c.refresh();
    expect(r.ok).toBe(false);
    expect(globalThis.fetch).toHaveBeenCalledTimes(1); // sin loop recursivo
  });
});
