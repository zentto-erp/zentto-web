import path from "node:path";

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
    secret: process.env.JWT_SECRET || "change_me",
    expires: process.env.JWT_EXPIRES || "12h",
  },
  redisUrl: process.env.REDIS_URL || "",
  media: {
    storagePath: process.env.MEDIA_STORAGE_PATH || path.resolve(process.cwd(), "storage", "media"),
    publicBaseUrl: process.env.MEDIA_PUBLIC_BASE_URL || "",
    maxFileSizeMb: Number(process.env.MEDIA_MAX_FILE_SIZE_MB || 5),
  },
};

