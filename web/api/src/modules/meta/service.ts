import { callSp } from "../../db/query.js";
import { getPool } from "../../db/mssql.js";

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
  const pool = await getPool();
  const request = pool.request();
  const result = await request.execute("usp_Sys_Meta_TablesAndColumns");

  const recordsets = result.recordsets as any[];
  const tables = (recordsets[0] ?? []) as Array<{ schema: string; table: string }>;
  const columns = (recordsets[1] ?? []) as Array<{ schema: string; table: string; column: string; type: string; nullable: string }>;

  return { tables, columns };
}
