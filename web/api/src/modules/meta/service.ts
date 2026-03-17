import { callSp } from "../../db/query.js";
import { env } from "../../config/env.js";

const usePg = () => env.dbType === "postgres";

export async function getRelations() {
  return callSp<{
    fkName: string;
    parentSchema: string;
    parentTable: string;
    parentColumn: string;
    refSchema: string;
    refTable: string;
    refColumn: string;
  }>("usp_Sys_Meta_Relations");
}

export async function getTablesAndColumns() {
  if (usePg()) {
    // PG: 2 funciones separadas en lugar de 1 SP multi-recordset
    const [tables, columns] = await Promise.all([
      callSp<{ schema: string; table: string }>("usp_Sys_Meta_TablesAndColumns_Tables"),
      callSp<{ schema: string; table: string; column: string; type: string; nullable: string }>("usp_Sys_Meta_TablesAndColumns_Columns"),
    ]);
    return { tables, columns };
  }

  // SQL Server: multi-recordset
  const { getPool } = await import("../../db/mssql.js");
  const pool = await getPool();
  const request = pool.request();
  const result = await request.execute("usp_Sys_Meta_TablesAndColumns");

  const recordsets = result.recordsets as any[];
  const tables = (recordsets[0] ?? []) as Array<{ schema: string; table: string }>;
  const columns = (recordsets[1] ?? []) as Array<{ schema: string; table: string; column: string; type: string; nullable: string }>;

  return { tables, columns };
}
