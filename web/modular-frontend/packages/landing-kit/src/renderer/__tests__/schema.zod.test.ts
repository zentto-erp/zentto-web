/**
 * Tests del Zod schema — ejecutables con vitest o jest.
 *
 * No requiere DOM. Valida que el seed real del hotel pase la validación.
 *
 * NOTA: al momento de crear este PR el package no tenía vitest instalado —
 * este test quedará como "documentación ejecutable" hasta que se añada
 * infraestructura de tests al package. Ver PR #3 body para detalles.
 */

import { describe, it, expect } from "vitest";
import { LandingSchemaZod, safeParseSchema } from "../schema.zod";
import hotelSeed from "../seeds/hotel.seed.json";

describe("LandingSchemaZod", () => {
  it("parsea el seed real del hotel sin errores", () => {
    const result = LandingSchemaZod.safeParse(hotelSeed);
    expect(result.success).toBe(true);
  });

  it("safeParseSchema retorna el data parseado en happy path", () => {
    const data = safeParseSchema(hotelSeed);
    expect(data).toBeDefined();
    expect(data?.id).toBe("zentto-hotel-landing");
    expect(data?.appMode).toBe("landing");
    expect(data?.landingConfig?.sections?.length).toBeGreaterThan(0);
  });

  it("safeParseSchema retorna undefined con schemas inválidos", () => {
    const bogus = { not: "a landing" };
    const data = safeParseSchema(bogus);
    expect(data).toBeUndefined();
  });

  it("safeParseSchema es permisivo con campos adicionales (passthrough)", () => {
    const withExtra = {
      ...(hotelSeed as any),
      extraTopLevelField: "future-extension",
      landingConfig: {
        ...(hotelSeed as any).landingConfig,
        unknownField: { foo: "bar" },
      },
    };
    const data = safeParseSchema(withExtra);
    expect(data).toBeDefined();
  });

  it("rechaza schemas sin appMode: 'landing'", () => {
    const notLanding = {
      ...(hotelSeed as any),
      appMode: "ecommerce",
    };
    const data = safeParseSchema(notLanding);
    expect(data).toBeUndefined();
  });
});
