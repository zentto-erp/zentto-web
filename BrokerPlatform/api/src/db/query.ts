import { sql, getPool } from "./mssql.js";

export async function query<T>(statement: string, params?: Record<string, unknown>) {
    const pool = await getPool();
    const request = pool.request();

    if (params) {
        for (const [key, value] of Object.entries(params)) {
            request.input(key, value as any);
        }
    }

    const result = await request.query<T>(statement);
    return result.recordset;
}

export async function execute(statement: string, params?: Record<string, unknown>) {
    const pool = await getPool();
    const request = pool.request();

    if (params) {
        for (const [key, value] of Object.entries(params)) {
            request.input(key, value as any);
        }
    }

    const result = await request.query(statement);
    return {
        rowsAffected: result.rowsAffected,
        recordset: result.recordset,
    };
}

export { sql };
