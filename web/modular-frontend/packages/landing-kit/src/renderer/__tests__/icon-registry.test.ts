/**
 * Tests del icon registry — valida que todos los iconIds usados en el seed
 * real del hotel resuelvan a algo !== null.
 */

import { describe, it, expect } from "vitest";
import { hasIcon, resolveIcon, ICON_MAP } from "../icon-registry";
import hotelSeed from "../seeds/hotel.seed.json";

function collectIconIds(obj: unknown, acc: Set<string> = new Set()): Set<string> {
  if (obj === null || typeof obj !== "object") return acc;
  if (Array.isArray(obj)) {
    obj.forEach((item) => collectIconIds(item, acc));
    return acc;
  }
  for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
    if (
      (key === "iconId" || key === "logoIconId") &&
      typeof value === "string"
    ) {
      acc.add(value);
    } else {
      collectIconIds(value, acc);
    }
  }
  return acc;
}

describe("icon-registry", () => {
  it("resolveIcon devuelve null para keys undefined/null/vacíos", () => {
    expect(resolveIcon(undefined)).toBeNull();
    expect(resolveIcon(null)).toBeNull();
    expect(resolveIcon("")).toBeNull();
  });

  it("resolveIcon devuelve null para iconIds inexistentes (sin lanzar)", () => {
    expect(resolveIcon("ThisIconDoesNotExist_XYZ")).toBeNull();
  });

  it("resolveIcon devuelve un nodo para iconIds conocidos", () => {
    expect(resolveIcon("HotelOutlined")).not.toBeNull();
    expect(resolveIcon("EventSeatOutlined")).not.toBeNull();
    expect(resolveIcon("X")).not.toBeNull();
  });

  it("todos los iconIds del seed del hotel están registrados", () => {
    const iconIds = collectIconIds(hotelSeed);
    const missing = [...iconIds].filter((id) => !hasIcon(id));
    expect(missing).toEqual([]);
  });

  it("ICON_MAP tiene al menos 50 iconos", () => {
    expect(Object.keys(ICON_MAP).length).toBeGreaterThanOrEqual(50);
  });
});
