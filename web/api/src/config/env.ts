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
    poolMax: Number(process.env.PG_POOL_MAX || 10),
    ssl: String(process.env.PG_SSL || "false").toLowerCase() === "true",
  },
  jwt: {
    // OBLIGATORIO: debe coincidir con el JWT_SECRET de zentto-auth y de todos los API hijos.
    // Fail-fast: lanza al cargar si no está seteado o es un placeholder.
    secret: requireEnv("JWT_SECRET"),
    expires: process.env.JWT_EXPIRES || "12h",
  },
  redisUrl: process.env.REDIS_URL || "",
  media: {
    storagePath: process.env.MEDIA_STORAGE_PATH || path.resolve(process.cwd(), "storage", "media"),
    publicBaseUrl: process.env.MEDIA_PUBLIC_BASE_URL || "",
    maxFileSizeMb: Number(process.env.MEDIA_MAX_FILE_SIZE_MB || 5),
  },
};

