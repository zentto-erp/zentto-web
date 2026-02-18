import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

async function listDoc(table: "NOTACREDITO" | "NOTADEBITO", params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("CODIGO = @codigo");
    sqlParams.codigo = params.codigo;
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM ${table} ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM ${table} ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

async function getDoc(table: "NOTACREDITO" | "NOTADEBITO", numFact: string) {
  const rows = await query<any>(`SELECT TOP 1 * FROM ${table} WHERE NUM_FACT = @numFact`, { numFact });
  return rows[0] ?? null;
}

async function getDocDetalle(detailTable: "Detalle_notacredito" | "Detalle_notadebito", numFact: string) {
  return query<any>(`SELECT * FROM ${detailTable} WHERE NUM_FACT = @numFact ORDER BY ID`, { numFact });
}

function normalizeKey(key: string) {
  return key.trim().toUpperCase();
}

function getValue(row: Record<string, unknown>, ...candidates: string[]) {
  const keys = Object.keys(row);
  for (const candidate of candidates) {
    const k = keys.find((x) => normalizeKey(x) === normalizeKey(candidate));
    if (k) return row[k];
  }
  return undefined;
}

function asNumber(v: unknown, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function asString(v: unknown, fallback = "") {
  if (v === null || v === undefined) return fallback;
  return String(v);
}

function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
}

function buildInsert(table: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row);
  if (!keys.length) throw new Error("empty_row");
  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");
  return {
    statement: `INSERT INTO ${table} (${cols}) VALUES (${vals})`,
    params: keys.map((k) => ({ key: `${prefix}_${k}`, value: row[k] }))
  };
}

async function txQuery<T>(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  const result = await req.query<T>(statement);
  return result.recordset;
}

async function txExec(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) for (const [k, v] of Object.entries(params)) if (v !== undefined) req.input(k, v as any);
  return req.query(statement);
}

async function actualizarSaldosCliente(tx: sql.Transaction, codigo: string) {
  const agg = await txQuery<{
    saldo_tot: number;
    saldo_30: number;
    saldo_60: number;
    saldo_90: number;
    saldo_91: number;
  }>(
    tx,
    `SELECT
       COALESCE(SUM(CASE WHEN TIPO = 'FACT' THEN PEND ELSE 0 END), 0) AS saldo_tot,
       COALESCE(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) <= 30 THEN PEND ELSE 0 END), 0) AS saldo_30,
       COALESCE(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) > 30 AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) <= 60 THEN PEND ELSE 0 END), 0) AS saldo_60,
       COALESCE(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) > 60 AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) <= 90 THEN PEND ELSE 0 END), 0) AS saldo_90,
       COALESCE(SUM(CASE WHEN TIPO = 'FACT' AND DATEDIFF(DAY, FECHA, CAST(GETDATE() AS date)) > 90 THEN PEND ELSE 0 END), 0) AS saldo_91
     FROM [dbo].[P_Cobrar]
     WHERE CODIGO = @codigo`,
    { codigo }
  );

  const a = agg[0] ?? { saldo_tot: 0, saldo_30: 0, saldo_60: 0, saldo_90: 0, saldo_91: 0 };
  await txExec(
    tx,
    `UPDATE [dbo].[Clientes]
        SET SALDO_TOT = @saldoTot,
            SALDO_30 = @saldo30,
            SALDO_60 = @saldo60,
            SALDO_90 = @saldo90,
            SALDO_91 = @saldo91
      WHERE CODIGO = @codigo`,
    {
      codigo,
      saldoTot: asNumber(a.saldo_tot, 0),
      saldo30: asNumber(a.saldo_30, 0),
      saldo60: asNumber(a.saldo_60, 0),
      saldo90: asNumber(a.saldo_90, 0),
      saldo91: asNumber(a.saldo_91, 0)
    }
  );
}

async function impactarInventarioNotaCredito(tx: sql.Transaction, nota: Record<string, unknown>, detalle: Record<string, unknown>[]) {
  const numFact = asString(getValue(nota, "NUM_FACT"));
  const usuario = asString(getValue(nota, "COD_USUARIO"), "API");
  const byCodigo = new Map<string, number>();

  for (const d of detalle) {
    const codigo = asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")).trim();
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    if (!codigo || cantidad <= 0) continue;
    byCodigo.set(codigo, asNumber(byCodigo.get(codigo), 0) + cantidad);
  }

  for (const [codigo, cantidad] of byCodigo.entries()) {
    const inv = await txQuery<{ EXISTENCIA: number; COSTO_REFERENCIA: number; PRECIO_VENTA: number }>(
      tx,
      "SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, PRECIO_VENTA FROM [dbo].[Inventario] WHERE CODIGO = @codigo",
      { codigo }
    );
    const actual = asNumber(inv[0]?.EXISTENCIA, 0);
    await txExec(tx, "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) + @cantidad WHERE CODIGO = @codigo", { codigo, cantidad });
    await txExec(
      tx,
      `INSERT INTO [dbo].[MovInvent] (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, PRECIO_VENTA)
       VALUES (@codigo, @codigo, @numFact, GETDATE(), @motivo, 'Ingreso', @actual, @cantidad, @nueva, @usuario, @pc, @pv)`,
      {
        codigo,
        numFact,
        motivo: `NotaCredito:${numFact}`,
        actual,
        cantidad,
        nueva: actual + cantidad,
        usuario,
        pc: asNumber(inv[0]?.COSTO_REFERENCIA, 0),
        pv: asNumber(inv[0]?.PRECIO_VENTA, 0)
      }
    );
  }
}

async function aplicarAjusteCxCNotaCredito(tx: sql.Transaction, nota: Record<string, unknown>) {
  const codigo = asString(getValue(nota, "CODIGO", "COD_CLIENTE")).trim();
  const monto = asNumber(getValue(nota, "TOTAL"), 0);
  const numNota = asString(getValue(nota, "NUM_FACT")).trim();
  const docRef = asString(getValue(nota, "NUM_FACT_REF", "FACTURA_REF", "DOCUMENTO_REF"), "").trim();
  if (!codigo || monto <= 0) return { adjusted: false };

  const prev = await txQuery<{ SALDO: number }>(
    tx,
    "SELECT TOP 1 SALDO FROM [dbo].[P_Cobrar] WHERE CODIGO = @codigo ORDER BY FECHA DESC",
    { codigo }
  );
  const saldoPrevio = asNumber(prev[0]?.SALDO, 0);

  if (docRef) {
    await txExec(
      tx,
      `UPDATE [dbo].[P_Cobrar]
          SET HABER = COALESCE(HABER, 0) + @monto,
              PEND = CASE WHEN COALESCE(PEND,0) - @monto < 0 THEN 0 ELSE COALESCE(PEND,0) - @monto END,
              PAID = CASE WHEN COALESCE(PEND,0) - @monto <= 0 THEN 1 ELSE COALESCE(PAID,0) END
        WHERE CODIGO = @codigo AND DOCUMENTO = @docRef AND TIPO = 'FACT'`,
      { codigo, docRef, monto }
    );
  }

  await txExec(
    tx,
    `INSERT INTO [dbo].[P_Cobrar] (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, HABER, PEND, SALDO, TIPO)
     VALUES (@codigo, @usuario, GETDATE(), @documento, 0, @haber, 0, @saldo, 'NCR')`,
    {
      codigo,
      usuario: asString(getValue(nota, "COD_USUARIO"), "API"),
      documento: numNota,
      haber: monto,
      saldo: saldoPrevio - monto
    }
  );

  await actualizarSaldosCliente(tx, codigo);
  return { adjusted: true, codigo, monto, docRef };
}

async function aplicarAjusteCxCNotaDebito(tx: sql.Transaction, nota: Record<string, unknown>) {
  const codigo = asString(getValue(nota, "CODIGO", "COD_CLIENTE")).trim();
  const monto = asNumber(getValue(nota, "TOTAL"), 0);
  const numNota = asString(getValue(nota, "NUM_FACT")).trim();
  if (!codigo || monto <= 0) return { adjusted: false };

  const prev = await txQuery<{ SALDO: number }>(
    tx,
    "SELECT TOP 1 SALDO FROM [dbo].[P_Cobrar] WHERE CODIGO = @codigo ORDER BY FECHA DESC",
    { codigo }
  );
  const saldoPrevio = asNumber(prev[0]?.SALDO, 0);

  await txExec(
    tx,
    `INSERT INTO [dbo].[P_Cobrar] (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, HABER, PEND, SALDO, TIPO)
     VALUES (@codigo, @usuario, GETDATE(), @documento, @debe, 0, @pend, @saldo, 'NDB')`,
    {
      codigo,
      usuario: asString(getValue(nota, "COD_USUARIO"), "API"),
      documento: numNota,
      debe: monto,
      pend: monto,
      saldo: saldoPrevio + monto
    }
  );

  await actualizarSaldosCliente(tx, codigo);
  return { adjusted: true, codigo, monto };
}

async function emitirNotaTx(input: {
  tableHeader: "[dbo].[NOTACREDITO]" | "[dbo].[NOTADEBITO]";
  tableDetail: "[dbo].[Detalle_notacredito]" | "[dbo].[Detalle_notadebito]";
  nota: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: { impactarInventario?: boolean; ajustarCxC?: boolean; actualizarSaldosCliente?: boolean };
}) {
  const nota = input.nota ?? {};
  const detalle = input.detalle ?? [];
  const numFact = asString(getValue(nota, "NUM_FACT")).trim();
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const reqNota = new sql.Request(tx);
    const insNota = buildInsert(input.tableHeader, nota, "n");
    for (const p of insNota.params) reqNota.input(p.key, p.value as any);
    await reqNota.query(insNota.statement);

    for (let i = 0; i < detalle.length; i += 1) {
      const row = { ...detalle[i] };
      if (!getValue(row, "NUM_FACT")) row.NUM_FACT = numFact;
      const reqDet = new sql.Request(tx);
      const insDet = buildInsert(input.tableDetail, row, `d${i}`);
      for (const p of insDet.params) reqDet.input(p.key, p.value as any);
      await reqDet.query(insDet.statement);
    }

    let cxResult: any = { adjusted: false };
    if (input.tableHeader === "[dbo].[NOTACREDITO]" && input.options?.impactarInventario !== false) {
      await impactarInventarioNotaCredito(tx, nota, detalle);
    }
    if (input.options?.ajustarCxC !== false) {
      cxResult =
        input.tableHeader === "[dbo].[NOTACREDITO]"
          ? await aplicarAjusteCxCNotaCredito(tx, nota)
          : await aplicarAjusteCxCNotaDebito(tx, nota);
    }

    await tx.commit();
    return {
      ok: true,
      numFact,
      detalleRows: detalle.length,
      inventarioImpactado: input.tableHeader === "[dbo].[NOTACREDITO]" && input.options?.impactarInventario !== false,
      cxc: cxResult
    };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function tableExistsTx(tx: sql.Transaction, tableName: string) {
  const rows = await txQuery<{ cnt: number }>(
    tx,
    "SELECT COUNT(1) AS cnt FROM sys.tables WHERE name = @tableName",
    { tableName }
  );
  return Number(rows[0]?.cnt ?? 0) > 0;
}

async function columnExistsTx(tx: sql.Transaction, tableName: string, columnName: string) {
  const rows = await txQuery<{ cnt: number }>(
    tx,
    `SELECT COUNT(1) AS cnt
       FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @tableName AND COLUMN_NAME = @columnName`,
    { tableName, columnName }
  );
  return Number(rows[0]?.cnt ?? 0) > 0;
}

async function marcarAnuladaSiExiste(tx: sql.Transaction, tableName: string, numFact: string) {
  const hasAnulada = await columnExistsTx(tx, tableName, "ANULADA");
  if (!hasAnulada) return false;
  await txExec(
    tx,
    `UPDATE [dbo].[${tableName.replace(/]/g, "]]")}]
        SET ANULADA = 1
      WHERE NUM_FACT = @numFact`,
    { numFact }
  );
  return true;
}

async function impactarInventarioNotaEntrega(tx: sql.Transaction, nota: Record<string, unknown>, detalle: Record<string, unknown>[]) {
  const numFact = asString(getValue(nota, "NUM_FACT"));
  const usuario = asString(getValue(nota, "COD_USUARIO"), "API");
  const byCodigo = new Map<string, number>();

  for (const d of detalle) {
    const codigo = asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")).trim();
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    if (!codigo || cantidad <= 0) continue;
    byCodigo.set(codigo, asNumber(byCodigo.get(codigo), 0) + cantidad);
  }

  for (const [codigo, cantidad] of byCodigo.entries()) {
    const inv = await txQuery<{ EXISTENCIA: number; COSTO_REFERENCIA: number; PRECIO_VENTA: number }>(
      tx,
      "SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, PRECIO_VENTA FROM [dbo].[Inventario] WHERE CODIGO = @codigo",
      { codigo }
    );
    const actual = asNumber(inv[0]?.EXISTENCIA, 0);
    await txExec(tx, "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) - @cantidad WHERE CODIGO = @codigo", { codigo, cantidad });
    await txExec(
      tx,
      `INSERT INTO [dbo].[MovInvent] (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, PRECIO_VENTA)
       VALUES (@codigo, @codigo, @numFact, GETDATE(), @motivo, 'Egreso', @actual, @cantidad, @nueva, @usuario, @pc, @pv)`,
      {
        codigo,
        numFact,
        motivo: `NotaEntrega:${numFact}`,
        actual,
        cantidad,
        nueva: actual - cantidad,
        usuario,
        pc: asNumber(inv[0]?.COSTO_REFERENCIA, 0),
        pv: asNumber(inv[0]?.PRECIO_VENTA, 0)
      }
    );
  }
}

async function revertirInventarioNotaEntrega(tx: sql.Transaction, nota: Record<string, unknown>, detalle: Record<string, unknown>[]) {
  const numFact = asString(getValue(nota, "NUM_FACT"));
  const usuario = asString(getValue(nota, "COD_USUARIO"), "API");
  const byCodigo = new Map<string, number>();

  for (const d of detalle) {
    const codigo = asString(getValue(d, "CODIGO", "COD_SERV", "REFERENCIA")).trim();
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    if (!codigo || cantidad <= 0) continue;
    byCodigo.set(codigo, asNumber(byCodigo.get(codigo), 0) + cantidad);
  }

  for (const [codigo, cantidad] of byCodigo.entries()) {
    const inv = await txQuery<{ EXISTENCIA: number; COSTO_REFERENCIA: number; PRECIO_VENTA: number }>(
      tx,
      "SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, PRECIO_VENTA FROM [dbo].[Inventario] WHERE CODIGO = @codigo",
      { codigo }
    );
    const actual = asNumber(inv[0]?.EXISTENCIA, 0);
    await txExec(tx, "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) + @cantidad WHERE CODIGO = @codigo", { codigo, cantidad });
    await txExec(
      tx,
      `INSERT INTO [dbo].[MovInvent] (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, PRECIO_VENTA)
       VALUES (@codigo, @codigo, @numFact, GETDATE(), @motivo, 'Ingreso', @actual, @cantidad, @nueva, @usuario, @pc, @pv)`,
      {
        codigo,
        numFact,
        motivo: `AnularNotaEntrega:${numFact}`,
        actual,
        cantidad,
        nueva: actual + cantidad,
        usuario,
        pc: asNumber(inv[0]?.COSTO_REFERENCIA, 0),
        pv: asNumber(inv[0]?.PRECIO_VENTA, 0)
      }
    );
  }
}

async function resolverTablaNotaEntregaTx(tx: sql.Transaction) {
  const headers = ["NOTA_ENTREGA", "Nota_Entrega", "NOTAENTREGA", "NOTAENT"];
  const details = ["Detalle_notaentrega", "DETALLE_NOTA_ENTREGA", "Detalle_NotaEntrega", "DETALLE_NOTAENTREGA"];
  for (const h of headers) {
    if (await tableExistsTx(tx, h)) {
      for (const d of details) {
        if (await tableExistsTx(tx, d)) return { header: h, detail: d };
      }
    }
  }
  return null;
}

async function emitirNotaEntregaTx(input: {
  nota: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: { impactarInventario?: boolean };
}) {
  const nota = input.nota ?? {};
  const detalle = input.detalle ?? [];
  const numFact = asString(getValue(nota, "NUM_FACT")).trim();
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const resolved = await resolverTablaNotaEntregaTx(tx);
    if (!resolved) throw new Error("tabla_nota_entrega_no_encontrada");

    const reqNota = new sql.Request(tx);
    const insNota = buildInsert(`[dbo].[${resolved.header}]`, nota, "n");
    for (const p of insNota.params) reqNota.input(p.key, p.value as any);
    await reqNota.query(insNota.statement);

    for (let i = 0; i < detalle.length; i += 1) {
      const row = { ...detalle[i] };
      if (!getValue(row, "NUM_FACT")) row.NUM_FACT = numFact;
      const reqDet = new sql.Request(tx);
      const insDet = buildInsert(`[dbo].[${resolved.detail}]`, row, `d${i}`);
      for (const p of insDet.params) reqDet.input(p.key, p.value as any);
      await reqDet.query(insDet.statement);
    }

    if (input.options?.impactarInventario !== false) {
      await impactarInventarioNotaEntrega(tx, nota, detalle);
    }

    await tx.commit();
    return { ok: true, numFact, detalleRows: detalle.length, inventarioImpactado: input.options?.impactarInventario !== false };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function anularNotaCreditoTx(input: { numFact: string; codUsuario?: string; motivo?: string }) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const notaRows = await txQuery<any>(tx, "SELECT TOP 1 * FROM [dbo].[NOTACREDITO] WHERE NUM_FACT = @numFact", { numFact: input.numFact });
    const nota = notaRows[0];
    if (!nota) throw new Error("not_found");

    const detalle = await txQuery<any>(tx, "SELECT * FROM [dbo].[Detalle_notacredito] WHERE NUM_FACT = @numFact", { numFact: input.numFact });
    await revertirInventarioNotaEntrega(tx, nota, detalle);

    const codigo = asString(getValue(nota, "CODIGO", "COD_CLIENTE")).trim();
    const monto = asNumber(getValue(nota, "TOTAL"), 0);
    const docRef = asString(getValue(nota, "NUM_FACT_REF", "FACTURA_REF", "DOCUMENTO_REF"), "").trim();
    if (codigo && monto > 0) {
      if (docRef) {
        await txExec(
          tx,
          `UPDATE [dbo].[P_Cobrar]
              SET HABER = CASE WHEN COALESCE(HABER,0) - @monto < 0 THEN 0 ELSE COALESCE(HABER,0) - @monto END,
                  PEND = COALESCE(PEND,0) + @monto,
                  PAID = 0
            WHERE CODIGO = @codigo AND DOCUMENTO = @docRef AND TIPO = 'FACT'`,
          { codigo, docRef, monto }
        );
      }
      await txExec(tx, "DELETE FROM [dbo].[P_Cobrar] WHERE CODIGO = @codigo AND DOCUMENTO = @numFact AND TIPO = 'NCR'", { codigo, numFact: input.numFact });
      await actualizarSaldosCliente(tx, codigo);
    }

    await marcarAnuladaSiExiste(tx, "NOTACREDITO", input.numFact);
    await tx.commit();
    return { ok: true, numFact: input.numFact, revertedInventario: true, revertedCxC: true };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function anularNotaDebitoTx(input: { numFact: string; codUsuario?: string; motivo?: string }) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const notaRows = await txQuery<any>(tx, "SELECT TOP 1 * FROM [dbo].[NOTADEBITO] WHERE NUM_FACT = @numFact", { numFact: input.numFact });
    const nota = notaRows[0];
    if (!nota) throw new Error("not_found");

    const codigo = asString(getValue(nota, "CODIGO", "COD_CLIENTE")).trim();
    if (codigo) {
      await txExec(tx, "DELETE FROM [dbo].[P_Cobrar] WHERE CODIGO = @codigo AND DOCUMENTO = @numFact AND TIPO = 'NDB'", { codigo, numFact: input.numFact });
      await actualizarSaldosCliente(tx, codigo);
    }

    await marcarAnuladaSiExiste(tx, "NOTADEBITO", input.numFact);
    await tx.commit();
    return { ok: true, numFact: input.numFact, revertedCxC: true };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function listNotaEntrega(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const resolved = await resolverTablaNotaEntregaTx(tx);
    if (!resolved) throw new Error("tabla_nota_entrega_no_encontrada");

    const where: string[] = [];
    const sqlParams: Record<string, unknown> = {};
    if (params.search) {
      where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
      sqlParams.search = `%${params.search}%`;
    }
    if (params.codigo) {
      where.push("CODIGO = @codigo");
      sqlParams.codigo = params.codigo;
    }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await txQuery<any>(tx, `SELECT * FROM [dbo].[${resolved.header}] ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
    const total = await txQuery<{ total: number }>(tx, `SELECT COUNT(1) AS total FROM [dbo].[${resolved.header}] ${clause}`, sqlParams);
    await tx.commit();
    return { page, limit, total: Number(total[0]?.total ?? 0), rows };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function getNotaEntrega(numFact: string) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const resolved = await resolverTablaNotaEntregaTx(tx);
    if (!resolved) throw new Error("tabla_nota_entrega_no_encontrada");
    const rows = await txQuery<any>(tx, `SELECT TOP 1 * FROM [dbo].[${resolved.header}] WHERE NUM_FACT = @numFact`, { numFact });
    await tx.commit();
    return rows[0] ?? null;
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function getNotaEntregaDetalle(numFact: string) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const resolved = await resolverTablaNotaEntregaTx(tx);
    if (!resolved) throw new Error("tabla_nota_entrega_no_encontrada");
    const rows = await txQuery<any>(tx, `SELECT * FROM [dbo].[${resolved.detail}] WHERE NUM_FACT = @numFact`, { numFact });
    await tx.commit();
    return rows;
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

async function anularNotaEntregaTx(input: { numFact: string; codUsuario?: string; motivo?: string }) {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const resolved = await resolverTablaNotaEntregaTx(tx);
    if (!resolved) throw new Error("tabla_nota_entrega_no_encontrada");

    const rows = await txQuery<any>(tx, `SELECT TOP 1 * FROM [dbo].[${resolved.header}] WHERE NUM_FACT = @numFact`, { numFact: input.numFact });
    const nota = rows[0];
    if (!nota) throw new Error("not_found");
    const detalle = await txQuery<any>(tx, `SELECT * FROM [dbo].[${resolved.detail}] WHERE NUM_FACT = @numFact`, { numFact: input.numFact });

    await revertirInventarioNotaEntrega(tx, nota, detalle);
    await marcarAnuladaSiExiste(tx, resolved.header, input.numFact);
    await tx.commit();
    return { ok: true, numFact: input.numFact, revertedInventario: true };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

export const notasService = {
  listCredito: (p: any) => listDoc("NOTACREDITO", p),
  getCredito: (n: string) => getDoc("NOTACREDITO", n),
  getCreditoDetalle: (n: string) => getDocDetalle("Detalle_notacredito", n),
  createCredito: (b: Record<string, unknown>) => createRow("dbo", "NOTACREDITO", b),
  updateCredito: (n: string, b: Record<string, unknown>) => updateRow("dbo", "NOTACREDITO", encodeKeyObject({ NUM_FACT: n }), b),
  deleteCredito: (n: string) => deleteRow("dbo", "NOTACREDITO", encodeKeyObject({ NUM_FACT: n })),
  txCredito: (p: { nota: Record<string, unknown>; detalle: Record<string, unknown>[] }) =>
    runHeaderDetailTx({ headerTable: "[dbo].[NOTACREDITO]", detailTable: "[dbo].[Detalle_notacredito]", header: p.nota ?? {}, details: p.detalle ?? [], linkFields: ["NUM_FACT", "SERIALTIPO"] }),
  emitirCreditoTx: (p: { nota: Record<string, unknown>; detalle: Record<string, unknown>[]; options?: { impactarInventario?: boolean; ajustarCxC?: boolean; actualizarSaldosCliente?: boolean } }) =>
    emitirNotaTx({
      tableHeader: "[dbo].[NOTACREDITO]",
      tableDetail: "[dbo].[Detalle_notacredito]",
      nota: p.nota ?? {},
      detalle: p.detalle ?? [],
      options: p.options ?? {}
    }),
  anularCreditoTx: (p: { numFact: string; codUsuario?: string; motivo?: string }) => anularNotaCreditoTx(p),

  listDebito: (p: any) => listDoc("NOTADEBITO", p),
  getDebito: (n: string) => getDoc("NOTADEBITO", n),
  getDebitoDetalle: (n: string) => getDocDetalle("Detalle_notadebito", n),
  createDebito: (b: Record<string, unknown>) => createRow("dbo", "NOTADEBITO", b),
  updateDebito: (n: string, b: Record<string, unknown>) => updateRow("dbo", "NOTADEBITO", encodeKeyObject({ NUM_FACT: n }), b),
  deleteDebito: (n: string) => deleteRow("dbo", "NOTADEBITO", encodeKeyObject({ NUM_FACT: n })),
  txDebito: (p: { nota: Record<string, unknown>; detalle: Record<string, unknown>[] }) =>
    runHeaderDetailTx({ headerTable: "[dbo].[NOTADEBITO]", detailTable: "[dbo].[Detalle_notadebito]", header: p.nota ?? {}, details: p.detalle ?? [], linkFields: ["NUM_FACT", "SERIALTIPO"] }),
  emitirDebitoTx: (p: { nota: Record<string, unknown>; detalle: Record<string, unknown>[]; options?: { ajustarCxC?: boolean; actualizarSaldosCliente?: boolean } }) =>
    emitirNotaTx({
      tableHeader: "[dbo].[NOTADEBITO]",
      tableDetail: "[dbo].[Detalle_notadebito]",
      nota: p.nota ?? {},
      detalle: p.detalle ?? [],
      options: { ...p.options, impactarInventario: false }
    }),
  anularDebitoTx: (p: { numFact: string; codUsuario?: string; motivo?: string }) => anularNotaDebitoTx(p),

  listEntrega: (p: any) => listNotaEntrega(p),
  getEntrega: (n: string) => getNotaEntrega(n),
  getEntregaDetalle: (n: string) => getNotaEntregaDetalle(n),
  emitirEntregaTx: (p: { nota: Record<string, unknown>; detalle: Record<string, unknown>[]; options?: { impactarInventario?: boolean } }) =>
    emitirNotaEntregaTx({
      nota: p.nota ?? {},
      detalle: p.detalle ?? [],
      options: p.options ?? {}
    }),
  anularEntregaTx: (p: { numFact: string; codUsuario?: string; motivo?: string }) => anularNotaEntregaTx(p)
};
