import sql from "mssql";
import { env } from "../config/env.js";

let pool: sql.ConnectionPool | null = null;

export async function getPool() {
    if (pool && pool.connected) return pool;

    pool = await sql.connect({
        server: env.db.server,
        database: env.db.database,
        user: env.db.user,
        password: env.db.password,
        options: {
            encrypt: env.db.encrypt,
            trustServerCertificate: env.db.trustServerCertificate,
        },
        pool: {
            min: env.db.poolMin,
            max: env.db.poolMax,
        },
    });

    return pool;
}

export { sql };
