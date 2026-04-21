/**
 * Smoke tests para los 3 nuevos submódulos del Lote 1.C2.
 * Verifica:
 *   - Construcción del cliente sin error.
 *   - Métodos invocables que retornan promesa.
 *   - URL + query construidos correctamente (mock fetch).
 *
 * Tests funcionales contra API real viven en e2e (fuera de este suite).
 */
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { CatalogClient } from "../src/catalog/index.js";
import { LicenseClient } from "../src/license/index.js";
import { SubscriptionsClient } from "../src/subscriptions/index.js";

interface FetchCall {
  url: string;
  method: string;
  headers: Record<string, string>;
  body?: string;
  credentials?: string;
}

let calls: FetchCall[] = [];

function mockFetch(responseStatus = 200, responseJson: unknown = { ok: true }): void {
  globalThis.fetch = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input.toString();
    calls.push({
      url,
      method: init?.method ?? "GET",
      headers: (init?.headers ?? {}) as Record<string, string>,
      body: init?.body ? String(init.body) : undefined,
      credentials: init?.credentials,
    });
    return new Response(JSON.stringify(responseJson), {
      status: responseStatus,
      headers: { "Content-Type": "application/json" },
    });
  }) as typeof fetch;
}

beforeEach(() => {
  calls = [];
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("CatalogClient", () => {
  it("listPlans construye URL con query y sin auth", async () => {
    mockFetch(200, []);
    const client = new CatalogClient({ baseUrl: "https://api.test" });
    const res = await client.listPlans({ vertical: "pos", includeTrial: false });
    expect(res.ok).toBe(true);
    expect(calls[0].url).toContain("/v1/catalog/plans");
    expect(calls[0].url).toContain("vertical=pos");
    expect(calls[0].url).toContain("includeTrial=false");
    expect(calls[0].method).toBe("GET");
  });

  it("getPlanBySlug encodea el slug", async () => {
    mockFetch(200, { Slug: "erp-starter" });
    const client = new CatalogClient({ baseUrl: "https://api.test" });
    await client.getPlanBySlug("erp-starter");
    expect(calls[0].url).toContain("/v1/catalog/plans/erp-starter");
  });

  it("listProducts respeta filtro vertical", async () => {
    mockFetch(200, []);
    const client = new CatalogClient({ baseUrl: "https://api.test" });
    await client.listProducts({ vertical: "hotel" });
    expect(calls[0].url).toContain("/v1/catalog/products");
    expect(calls[0].url).toContain("vertical=hotel");
  });

  it("checkSubdomain construye path correcto", async () => {
    mockFetch(200, { slug: "acme", available: true });
    const client = new CatalogClient({ baseUrl: "https://api.test" });
    const res = await client.checkSubdomain("acme");
    expect(res.ok).toBe(true);
    expect(calls[0].url).toContain("/v1/catalog/subdomain-check/acme");
  });
});

describe("LicenseClient", () => {
  it("validate envia code y key como query params", async () => {
    mockFetch(200, { ok: true });
    const client = new LicenseClient({ baseUrl: "https://api.test" });
    await client.validate({ code: "LIC-001", key: "secret-key" });
    expect(calls[0].url).toContain("/v1/license/validate");
    expect(calls[0].url).toContain("code=LIC-001");
    expect(calls[0].url).toContain("key=secret-key");
  });
});

describe("SubscriptionsClient", () => {
  it("getMe envia credentials include por default", async () => {
    mockFetch(200, { ok: true, subscription: null });
    const client = new SubscriptionsClient({ baseUrl: "https://api.test" });
    await client.getMe();
    expect(calls[0].url).toContain("/v1/subscriptions/me");
    expect(calls[0].credentials).toBe("include");
  });

  it("getMe agrega X-Company-Id si se configura", async () => {
    mockFetch(200, { ok: true, subscription: null });
    const client = new SubscriptionsClient({ baseUrl: "https://api.test", companyId: 42 });
    await client.getMe();
    expect(calls[0].headers["X-Company-Id"]).toBe("42");
  });

  it("addItem envia body con addonSlug y billingCycle por default monthly", async () => {
    mockFetch(200, { ok: true, mode: "direct_add" });
    const client = new SubscriptionsClient({ baseUrl: "https://api.test" });
    await client.addItem({ addonSlug: "advanced-analytics" });
    expect(calls[0].method).toBe("POST");
    expect(calls[0].body).toContain('"addonSlug":"advanced-analytics"');
    expect(calls[0].body).toContain('"billingCycle":"monthly"');
  });

  it("removeItem usa DELETE con itemId en path", async () => {
    mockFetch(200, { ok: true });
    const client = new SubscriptionsClient({ baseUrl: "https://api.test" });
    await client.removeItem(99);
    expect(calls[0].method).toBe("DELETE");
    expect(calls[0].url).toContain("/v1/subscriptions/items/99");
  });

  it("Cookie header opcional se inyecta para SSR", async () => {
    mockFetch(200, { ok: true, entitlements: { CompanyId: 1, ModuleCodes: [], Plans: [], ExpiresAt: null, IsActive: true } });
    const client = new SubscriptionsClient({
      baseUrl: "https://api.test",
      credentials: "omit",
      cookieHeader: "zentto_session=abc; path=/",
    });
    await client.getEntitlements();
    expect(calls[0].headers["Cookie"]).toBe("zentto_session=abc; path=/");
    expect(calls[0].credentials).toBe("omit");
  });
});
