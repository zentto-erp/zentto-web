import { getPool, sql } from "../../db/mssql.js";

export function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
}

export function buildInsert(tableName: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row);
  if (keys.length === 0) {
    throw new Error("empty_row");
  }

  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");

  return {
    statement: `INSERT INTO ${tableName} (${cols}) VALUES (${vals})`,
    params: keys.map((k) => ({ key: `${prefix}_${k}`, value: row[k] }))
  };
}

export async function runHeaderDetailTx(input: {
  headerTable: string;
  detailTable: string;
  header: Record<string, unknown>;
  details: Record<string, unknown>[];
  linkFields?: string[];
}) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const reqHeader = new sql.Request(tx);
    const insHeader = buildInsert(input.headerTable, input.header, "h");
    for (const p of insHeader.params) {
      reqHeader.input(p.key, p.value as any);
    }
    await reqHeader.query(insHeader.statement);

    for (let i = 0; i < input.details.length; i += 1) {
      const detail = { ...input.details[i] };

      for (const lf of input.linkFields ?? []) {
        const headerValue = input.header[lf];
        if (detail[lf] === undefined && headerValue !== undefined) {
          detail[lf] = headerValue;
        }
      }

      const reqDetail = new sql.Request(tx);
      const insDetail = buildInsert(input.detailTable, detail, `d${i}`);
      for (const p of insDetail.params) {
        reqDetail.input(p.key, p.value as any);
      }
      await reqDetail.query(insDetail.statement);
    }

    await tx.commit();
    return { ok: true, detailRows: input.details.length };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}
