import path from "node:path";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value === "change_me" || value === "dev-secret-change-me") {
    throw new Error(
      `[env] ${name} is required and must not be a default placeholder. Set it in your .env or deployment environment.`
    );
  }
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  /** "sqlserver" | "postgres" — conmutador de motor de BD */
  dbType: (process.env.DB_TYPE || "sqlserver").toLowerCase() as "sqlserver" | "postgres",
  db: {
    server: process.env.DB_SERVER || "(local)\\SQLEXPRESS",
    database: process.env.DB_DATABASE || "DatqBoxExpress",
    user: process.env.DB_USER || "sa",
    password: process.env.DB_PASSWORD || "",
    encrypt: String(process.env.DB_ENCRYPT || "false").toLowerCase() === "true",
    trustServerCertificate: String(process.env.DB_TRUST_CERT || "true").toLowerCase() !== "false",
    poolMin: Number(process.env.DB_POOL_MIN || 0),
    poolMax: Number(process.env.DB_POOL_MAX || 10),
  },
  pg: {
    host: process.env.PG_HOST || "localhost",
    port: Number(process.env.PG_PORT || 5432),
    database: process.env.PG_DATABASE || "datqboxweb",
    user: process.env.PG_USER || "postgres",
    password: process.env.PG_PASSWORD || "",
    poolMin: Number(process.env.PG_POOL_MIN || 0),
    // ALERT-4: default subido de 10 → 40. Con 30+ requests concurrentes el
    // pool quedaba exhausto y generaba latencias altas. 40 deja margen
    // razonable para el pico de producción. Override con PG_POOL_MAX.
    poolMax: Number(process.env.PG_POOL_MAX || 40),
    ssl: String(process.env.PG_SSL || "false").toLowerCase() === "true",
    /**
     * ALERT-4: logging de `pool.waitingCount` cada N segundos. Útil en dev y
     * producción inicial para detectar pool exhaustion. `0` apaga el monitor.
     */
    poolStatsIntervalSec: Number(process.env.PG_POOL_STATS_INTERVAL_SEC || 30),
  },
  jwt: {
    // OBLIGATORIO: debe coincidir con el JWT_SECRET de zentto-auth y de todos los API hijos.
    // Fail-fast: lanza al cargar si no está seteado o es un placeholder.
    secret: requireEnv("JWT_SECRET"),
    /**
     * ALERT-1 (transición HS256 → RS256/JWKS):
     *
     * `secretFallback` permite validar tokens HS256 firmados con un secret
     * distinto al primario (p.ej. el secret histórico de zentto-auth cuando
     * ambos servicios quedaron desincronizados). Solo se usa en `verifyJwt`
     * como *segundo intento* si la verificación con el secret primario falla
     * por `invalid signature`. Los tokens nuevos se siguen firmando con el
     * `secret` primario.
     *
     * Esta es una salvaguarda temporal: el destino final es que TODO el
     * ecosistema valide tokens RS256 vs el JWKS de zentto-auth (ya soportado
     * en `auth/jwt.ts`). Dejar vacío apaga el fallback sin riesgo.
     */
    secretFallback: (process.env.JWT_SECRET_FALLBACK ?? "").trim() || null,
    expires: process.env.JWT_EXPIRES || "12h",
  },
  redisUrl: process.env.REDIS_URL || "",
  media: {
    storagePath: process.env.MEDIA_STORAGE_PATH || path.resolve(process.cwd(), "storage", "media"),
    publicBaseUrl: process.env.MEDIA_PUBLIC_BASE_URL || "",
    maxFileSizeMb: Number(process.env.MEDIA_MAX_FILE_SIZE_MB || 5),
  },
  /**
   * Hetzner S3 bucket para imágenes de productos del ecommerce (público, con CORS).
   * Declarado como objeto opcional: si las vars no existen, el upload cae a disk
   * storage (ver admin-products.routes.ts). Documentado en:
   *   docs/integration/ecommerce-2026-04-review.md (Ola 2 aplicada: storage de imágenes)
   */
  productImagesS3: {
    bucket: process.env.HETZNER_S3_PRODUCT_IMAGES_BUCKET || "",
    endpoint: process.env.HETZNER_S3_PRODUCT_IMAGES_ENDPOINT || "",
    accessKey: process.env.HETZNER_S3_PRODUCT_IMAGES_ACCESS_KEY || "",
    secretKey: process.env.HETZNER_S3_PRODUCT_IMAGES_SECRET_KEY || "",
    region: process.env.HETZNER_S3_PRODUCT_IMAGES_REGION || "nbg1",
    publicUrl: process.env.HETZNER_S3_PRODUCT_IMAGES_PUBLIC_URL || "",
  },
  storeDefaultCompanyId: (() => {
    const raw = process.env.STORE_DEFAULT_COMPANY_ID;
    if (!raw) return undefined;
    const n = Number(raw);
    return Number.isFinite(n) && n > 0 ? n : undefined;
  })() as number | undefined,
  /**
   * MASTER_KEY — passphrase para cifrado PII con pgcrypto.
   *
   * Se usa como key simétrica para pgp_sym_encrypt / pgp_sym_decrypt sobre
   * columnas sensibles (IBAN, account_number, tax_id en store.Affiliate y
   * store.Merchant). La app la expone a cada transacción PG vía
   * `SET LOCAL zentto.master_key = '...'` (ver setPiiMasterKey en db/query.ts).
   *
   * Opcional en dev/test: si no está seteada, los SPs que intenten cifrar
   * fallan con error explícito, y los que sólo descifran (variante _safe)
   * retornan NULL.
   */
  masterKey: (process.env.MASTER_KEY ?? "") as string,
  /**
   * Feature flag para activar endpoints/flows de payouts reales.
   * Antes de activarlo en prod, la migración 00155 y la paridad T-SQL
   * deben estar aplicadas (bloqueador del integration reviewer).
   */
  storeAffiliatePayoutEnabled:
    String(process.env.STORE_AFFILIATE_PAYOUT_ENABLED || "false").toLowerCase() === "true",
  /**
   * Landing Schemas CMS — revalidate webhook (opt-in).
   *
   * Al publicar un landing en `/v1/cms/landings/:id/publish`, la API hace fire-and-forget
   * POST al endpoint de revalidate del frontend vertical correspondiente para invalidar
   * el cache Next.js. Default OFF para dev/test.
   *
   * LANDING_REVALIDATE_ENABLED: 'true' activa el disparo.
   * LANDING_REVALIDATE_SECRET:  shared secret enviado como header `x-revalidate-token`.
   * LANDING_REVALIDATE_URLS:    JSON string `{"hotel": "https://hotel.zentto.net/api/revalidate", ...}`
   *                             con endpoint por vertical. Claves no mapeadas se ignoran.
   */
  landingRevalidate: {
    enabled:
      String(process.env.LANDING_REVALIDATE_ENABLED || "false").toLowerCase() === "true",
    secret: (process.env.LANDING_REVALIDATE_SECRET ?? "") as string,
    urls: ((): Record<string, string> => {
      const raw = process.env.LANDING_REVALIDATE_URLS;
      if (!raw) return {};
      try {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
          const out: Record<string, string> = {};
          for (const [k, v] of Object.entries(parsed)) {
            if (typeof v === "string" && v) out[k] = v;
          }
          return out;
        }
        return {};
      } catch {
        return {};
      }
    })(),
  },
};
