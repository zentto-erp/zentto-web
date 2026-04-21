/**
 * Tests del SECTION_MAP — verifica que todos los tipos del seed del hotel
 * estén cubiertos.
 */

import { describe, it, expect } from "vitest";
import { SECTION_MAP, resolveSection } from "../section-map";
import hotelSeed from "../seeds/hotel.seed.json";

describe("SECTION_MAP", () => {
  it("cubre todos los types usados en el seed del hotel", () => {
    const sectionTypes = ((hotelSeed as any).landingConfig.sections ?? []).map(
      (s: any) => s.type,
    ) as string[];
    const uniqueTypes = Array.from(new Set(sectionTypes));
    const missing = uniqueTypes.filter((t) => !(t in SECTION_MAP));
    expect(missing).toEqual([]);
  });

  it("resolveSection retorna null para types desconocidos", () => {
    expect(resolveSection("quantum-teleport-section")).toBeNull();
  });

  it("expone los 9 adapters esperados", () => {
    expect(Object.keys(SECTION_MAP).sort()).toEqual(
      [
        "hero",
        "features",
        "pricing",
        "testimonials",
        "cta",
        "logos",
        "blog-preview",
        "timeline",
        "custom",
      ].sort(),
    );
  });
});
