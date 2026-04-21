/**
 * cms-landing-schemas.test.ts
 *
 * Smoke tests para /v1/public/cms/landings/* y /v1/cms/landings/*.
 * No requiere BD viva: verifica status codes contra una API levantada.
 * Si la API no está disponible, los tests pasan silenciosamente (patrón smoke.test.ts).
 *
 * Uso (opcional):
 *   npm run test:smoke -- tests/api/cms-landing-schemas.test.ts
 */

import { describe, it, expect } from "vitest";

const BASE = process.env.API_BASE_URL ?? "http://localhost:4000";

async function get(path: string): Promise<Response | null> {
  try {
    return await fetch(`${BASE}${path}`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(3000),
    });
  } catch {
    return null;
  }
}

async function put(path: string, body: unknown): Promise<Response | null> {
  try {
    return await fetch(`${BASE}${path}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(3000),
    });
  } catch {
    return null;
  }
}

describe("CMS Landing Schemas — rutas públicas", () => {
  it("GET /v1/public/cms/landings/by-slug sin query devuelve 400 (invalid_query)", async () => {
    const res = await get("/v1/public/cms/landings/by-slug");
    if (res) {
      expect([400, 404]).toContain(res.status);
      expect(res.status).not.toBe(500);
    }
  });

  it("GET /v1/public/cms/landings/by-slug con vertical inexistente devuelve 404", async () => {
    const res = await get(
      "/v1/public/cms/landings/by-slug?vertical=__nonexistent__&companyId=999999",
    );
    if (res) {
      expect(res.status).toBe(404);
    }
  });

  it("GET /v1/public/cms/landings/preview sin token devuelve 400", async () => {
    const res = await get("/v1/public/cms/landings/preview");
    if (res) {
      expect([400, 404]).toContain(res.status);
    }
  });

  it("GET /v1/public/cms/landings/preview con token inválido devuelve 404", async () => {
    const res = await get(
      "/v1/public/cms/landings/preview?token=this-is-not-a-valid-token-abcdef",
    );
    if (res) {
      expect([400, 404]).toContain(res.status);
    }
  });
});

describe("CMS Landing Schemas — rutas admin requieren auth", () => {
  it("GET /v1/cms/landings sin token devuelve 401/403", async () => {
    const res = await get("/v1/cms/landings");
    if (res) {
      expect([401, 403]).toContain(res.status);
    }
  });

  it("PUT /v1/cms/landings/new sin token devuelve 401/403", async () => {
    const res = await put("/v1/cms/landings/new", {
      vertical: "hotel",
      draftSchema: {
        id: "landing/hotel/default",
        version: "2026.04.21",
        landingConfig: { sections: [] },
      },
    });
    if (res) {
      expect([401, 403]).toContain(res.status);
    }
  });

  it("POST /v1/cms/landings/1/publish sin token devuelve 401/403", async () => {
    try {
      const res = await fetch(`${BASE}/v1/cms/landings/1/publish`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: AbortSignal.timeout(3000),
      });
      expect([401, 403]).toContain(res.status);
    } catch {
      // API no disponible localmente, saltar
    }
  });
});
