export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  db: {
    server: process.env.DB_SERVER || "(local)\\SQLEXPRESS",
    database: process.env.DB_DATABASE || "DatqBoxExpress",
    user: process.env.DB_USER || "sa",
    password: process.env.DB_PASSWORD || "",
    encrypt: String(process.env.DB_ENCRYPT || "false").toLowerCase() === "true",
    trustServerCertificate: String(process.env.DB_TRUST_CERT || "true").toLowerCase() !== "false",
    poolMin: Number(process.env.DB_POOL_MIN || 0),
    poolMax: Number(process.env.DB_POOL_MAX || 10)
  },
  jwt: {
    secret: process.env.JWT_SECRET || "change_me",
    expires: process.env.JWT_EXPIRES || "12h"
  },
  redisUrl: process.env.REDIS_URL || ""
};
