import { describe, it, expect } from "vitest";
import { verifySignature, signBody } from "../src/webhooks/index.js";

describe("webhooks signature", () => {
  const key = "zws_0123456789abcdef";
  const body = JSON.stringify({ eventId: "evt_1", data: { x: 1 } });

  it("signBody + verifySignature roundtrip OK", () => {
    const sig = signBody(body, key);
    expect(sig).toMatch(/^sha256=[0-9a-f]{64}$/);
    expect(verifySignature(body, sig, key)).toBe(true);
  });

  it("rechaza signature con clave distinta", () => {
    const sig = signBody(body, key);
    expect(verifySignature(body, sig, "otro-secret")).toBe(false);
  });

  it("rechaza si el body fue modificado", () => {
    const sig = signBody(body, key);
    expect(verifySignature(body + "x", sig, key)).toBe(false);
  });

  it("rechaza formato inválido", () => {
    expect(verifySignature(body, "md5=abc", key)).toBe(false);
    expect(verifySignature(body, "abc", key)).toBe(false);
    expect(verifySignature(body, undefined, key)).toBe(false);
    expect(verifySignature(body, [], key)).toBe(false);
  });

  it("rechaza key vacío", () => {
    const sig = signBody(body, key);
    expect(verifySignature(body, sig, "")).toBe(false);
  });
});
