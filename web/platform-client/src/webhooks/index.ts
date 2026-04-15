/**
 * Helpers para consumir webhooks firmados por Zentto.
 *
 * Cuando Zentto dispara un webhook, incluye el header
 * `X-Zentto-Signature: sha256=<hmac>` donde el HMAC es:
 *
 *   hmacSha256(secretHash, rawBody)
 *
 * Nota importante: el firmado se hace con el **secretHash** (lo que Zentto
 * guarda en BD), NO con el secret plain que el admin vio al crear el webhook.
 * El secret plain se mantiene como identificador opaco para la UI del admin;
 * la verificación HMAC usa el hash. Esta nota aplica porque el SDK necesita
 * que el caller sepa cuál usar.
 *
 * Uso típico (Express):
 *
 *   app.post("/incoming", bodyParser.raw({ type: "application/json" }), (req, res) => {
 *     const sig = req.headers["x-zentto-signature"];
 *     const raw = req.body.toString("utf-8");
 *     if (!verifySignature(raw, sig, WEBHOOK_SECRET_HASH)) return res.status(401).end();
 *     const envelope = JSON.parse(raw);
 *     // procesar envelope.eventType, envelope.data, ...
 *   });
 */
import crypto from "node:crypto";

/**
 * Verifica que el header `X-Zentto-Signature` matchee el HMAC-SHA256 del
 * body crudo con la clave dada. Usa `timingSafeEqual` para prevenir timing
 * attacks.
 *
 * @param rawBody   string UTF-8 del body del POST (NO el parseado JSON).
 * @param signature valor del header X-Zentto-Signature (formato "sha256=<hex>").
 * @param key       secret o secretHash según convención del publisher.
 */
export function verifySignature(
  rawBody: string,
  signature: string | string[] | undefined,
  key: string,
): boolean {
  if (!signature || Array.isArray(signature) || !key) return false;
  const match = signature.match(/^sha256=([0-9a-f]{64})$/i);
  if (!match) return false;
  const expected = crypto.createHmac("sha256", key).update(rawBody).digest();
  const received = Buffer.from(match[1], "hex");
  if (expected.length !== received.length) return false;
  try {
    return crypto.timingSafeEqual(expected, received);
  } catch {
    return false;
  }
}

/** Firma un body con la misma convención (útil para tests y mocks). */
export function signBody(rawBody: string, key: string): string {
  const hmac = crypto.createHmac("sha256", key).update(rawBody).digest("hex");
  return `sha256=${hmac}`;
}
