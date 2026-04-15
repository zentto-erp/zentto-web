import { describe, it, expect } from "vitest";
import {
  AuthError, ValidationError, NotFoundError, RateLimitedError,
  ServiceError, NetworkError, mapHttpError,
} from "../src/internal/errors.js";

describe("mapHttpError", () => {
  const mk = (status: number, body: Record<string, unknown> = {}) =>
    mapHttpError(status, body, "/x", 0);

  it("401 → AuthError", () => expect(mk(401)).toBeInstanceOf(AuthError));
  it("403 → AuthError", () => expect(mk(403)).toBeInstanceOf(AuthError));
  it("404 → NotFoundError", () => expect(mk(404)).toBeInstanceOf(NotFoundError));
  it("422 → ValidationError", () => expect(mk(422)).toBeInstanceOf(ValidationError));
  it("400 → ValidationError", () => expect(mk(400)).toBeInstanceOf(ValidationError));
  it("500 → ServiceError", () => expect(mk(500)).toBeInstanceOf(ServiceError));
  it("502 → ServiceError", () => expect(mk(502)).toBeInstanceOf(ServiceError));
  it("undefined → NetworkError", () => expect(mapHttpError(undefined, {}, "/x", 0)).toBeInstanceOf(NetworkError));

  it("429 extrae retryAfter", () => {
    const err = mk(429, { retryAfter: 30 });
    expect(err).toBeInstanceOf(RateLimitedError);
    expect((err as RateLimitedError).retryAfterSec).toBe(30);
  });

  it("usa body.error como mensaje", () => {
    const err = mk(400, { error: "nombre requerido" });
    expect(err.message).toBe("nombre requerido");
  });
});
