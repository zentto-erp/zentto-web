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
    recordset: result.recordset
  };
}

/**
 * Ejecuta un stored procedure y retorna el recordset.
 * Uso: const rows = await callSp<MyType>('usp_Cfg_AppSetting_List', { module: 'POS' });
 */
export async function callSp<T>(spName: string, inputs?: Record<string, unknown>): Promise<T[]> {
  const pool = await getPool();
  const request = pool.request();

  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }

  const result = await request.execute<T>(spName);
  return result.recordset;
}

/**
 * Ejecuta un stored procedure con parámetros OUTPUT.
 * Uso:
 *   const { rows, output } = await callSpOut<Row>(
 *     'usp_Master_Product_List',
 *     { Search: 'abc', Page: 1, Limit: 50 },
 *     { TotalCount: sql.Int }
 *   );
 *   const total = output.TotalCount as number;
 */
export async function callSpOut<T>(
  spName: string,
  inputs?: Record<string, unknown>,
  outputs?: Record<string, any>
): Promise<{ rows: T[]; output: Record<string, unknown>; rowsAffected: number[] }> {
  const pool = await getPool();
  const request = pool.request();

  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }

  if (outputs) {
    for (const [key, sqlType] of Object.entries(outputs)) {
      request.output(key, sqlType);
    }
  }

  const result = await request.execute<T>(spName);
  return {
    rows: result.recordset,
    output: result.output,
    rowsAffected: result.rowsAffected
  };
}

/**
 * Ejecuta un stored procedure dentro de una transacción existente.
 * Uso dentro de transacciones manuales cuando se necesitan múltiples SPs
 * en la misma TX (caso raro, ya que la TX debe estar dentro del SP).
 */
export async function callSpTx<T>(
  tx: sql.Transaction,
  spName: string,
  inputs?: Record<string, unknown>
): Promise<T[]> {
  const request = new sql.Request(tx);

  if (inputs) {
    for (const [key, value] of Object.entries(inputs)) {
      if (value !== undefined) request.input(key, value as any);
    }
  }

  const result = await request.execute<T>(spName);
  return result.recordset;
}

export { sql };
