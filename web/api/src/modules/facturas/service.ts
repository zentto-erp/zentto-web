import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import type { Factura, DetalleFactura } from "../../contracts/facturas.js";

const BASE_SELECT = "SELECT * FROM Facturas";

export type GetFacturasParams = {
  numFact?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export type GetFacturasResult = {
  page: number;
  pageSize: number;
  rows: Factura[];
  total?: number;
  executionMode?: "sp" | "ts_fallback";
};

export async function getFacturas(params: GetFacturasParams): Promise<GetFacturasResult> {
  const pageSize = Math.min(Number(params.pageSize || 50), 500);
  const page = Math.max(Number(params.page || 1), 1);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("NumFact", sql.NVarChar(20), params.numFact ?? null);
    req.input("CodUsuario", sql.NVarChar(10), params.codUsuario ?? null);
    req.input("From", sql.Date, params.from ?? null);
    req.input("To", sql.Date, params.to ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, pageSize);
    req.output("TotalCount", sql.Int);

    const result = await req.execute("usp_Facturas_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as Factura[];
    return { page, pageSize, rows, total, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};

  if (params.numFact) {
    where.push("NUM_FACT = @numFact");
    sqlParams.numFact = params.numFact;
  }
  if (params.codUsuario) {
    where.push("COD_USUARIO = @codUsuario");
    sqlParams.codUsuario = params.codUsuario;
  }
  if (params.from) {
    where.push("FECHA >= @from");
    sqlParams.from = params.from;
  }
  if (params.to) {
    where.push("FECHA <= @to");
    sqlParams.to = params.to;
  }

  const offset = (page - 1) * pageSize;
  const clause = where.length ? ` WHERE ${where.join(" AND ")}` : "";
  const statement = `${BASE_SELECT}${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${pageSize} ROWS ONLY`;

  const rows = await query<Factura>(statement, sqlParams);
  return { page, pageSize, rows, executionMode: "ts_fallback" };
}

export async function getFacturaByNumero(numFact: string): Promise<{ row: Factura | null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("NumFact", sql.NVarChar(20), numFact);
    const result = await req.execute("usp_Facturas_GetByNumFact");
    const rows = (result.recordset ?? []) as Factura[];
    const row = rows[0] ?? null;
    return { row, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const rows = await query<Factura>(
    "SELECT TOP 1 * FROM Facturas WHERE NUM_FACT = @numFact",
    { numFact }
  );
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function getDetalleFactura(numFact: string) {
  const rows = await query<DetalleFactura>(
    "SELECT * FROM Detalle_facturas WHERE NUM_FACT = @numFact ORDER BY RENGLON",
    { numFact }
  );

  return rows;
}

function quoteIdent(name: string) {
  return `[${name.replace(/]/g, "]]")}]`;
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

function escapeXml(value: unknown) {
  const s = asString(value, "");
  return s
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/'/g, "&apos;");
}

function recordToXmlAttrs(row: Record<string, unknown>) {
  return Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escapeXml(v)}"`)
    .join(" ");
}

function facturaPayloadToXml(payload: EmitirFacturaPayload) {
  const facturaAttrs = recordToXmlAttrs(payload.factura ?? {});
  const detalleRows = (payload.detalle ?? [])
    .map((r) => `<row ${recordToXmlAttrs(r)} />`)
    .join("");
  const formasRows = (payload.formasPago ?? [])
    .map((r) => `<row ${recordToXmlAttrs(r)} />`)
    .join("");

  return {
    facturaXml: `<factura ${facturaAttrs} />`,
    detalleXml: `<detalles>${detalleRows}</detalles>`,
    formasPagoXml: `<formasPago>${formasRows}</formasPago>`
  };
}

function buildInsert(table: string, row: Record<string, unknown>, prefix: string) {
  const keys = Object.keys(row);
  if (keys.length === 0) {
    throw new Error("empty_row");
  }

  const cols = keys.map((k) => quoteIdent(k)).join(", ");
  const vals = keys.map((k) => `@${prefix}_${k}`).join(", ");
  return {
    statement: `INSERT INTO ${table} (${cols}) VALUES (${vals})`,
    params: keys.map((k) => ({ key: `${prefix}_${k}`, value: row[k] }))
  };
}

async function txQuery<T>(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) req.input(k, v as any);
    }
  }
  const result = await req.query<T>(statement);
  return result.recordset;
}

async function txExec(tx: sql.Transaction, statement: string, params?: Record<string, unknown>) {
  const req = new sql.Request(tx);
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) req.input(k, v as any);
    }
  }
  return req.query(statement);
}

export async function createFacturaTx(payload: {
  factura: Record<string, unknown>;
  detalle: Record<string, unknown>[];
}) {
  const factura = payload.factura ?? {};
  const detalle = payload.detalle ?? [];

  if (!factura.NUM_FACT) {
    throw new Error("missing_num_fact");
  }

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const reqFactura = new sql.Request(tx);
    const facturaInsert = buildInsert("[dbo].[Facturas]", factura, "f");
    for (const p of facturaInsert.params) {
      reqFactura.input(p.key, p.value as any);
    }
    await reqFactura.query(facturaInsert.statement);

    for (let i = 0; i < detalle.length; i += 1) {
      const row = { ...detalle[i] };
      if (!row.NUM_FACT) row.NUM_FACT = factura.NUM_FACT;
      if (!row.SERIALTIPO && factura.SERIALTIPO) row.SERIALTIPO = factura.SERIALTIPO;

      const reqDet = new sql.Request(tx);
      const detInsert = buildInsert("[dbo].[Detalle_facturas]", row, `d${i}`);
      for (const p of detInsert.params) {
        reqDet.input(p.key, p.value as any);
      }
      await reqDet.query(detInsert.statement);
    }

    await tx.commit();
    return { ok: true, numFact: String(factura.NUM_FACT), detalleRows: detalle.length };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}

type FormaPagoInput = Record<string, unknown>;
export type EmitirFacturaPayload = {
  factura: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: FormaPagoInput[];
  options?: {
    actualizarInventario?: boolean;
    generarCxC?: boolean;
    cxcTable?: "P_Cobrar" | "P_CobrarC";
    formaPagoTable?: string;
    actualizarSaldosCliente?: boolean;
  };
};

function mapFormaPagoRow(
  forma: FormaPagoInput,
  numFact: string,
  memoria: string,
  serialFiscal: string,
  tasaCambioDefault: number
) {
  return {
    tasacambio: asNumber(getValue(forma, "tasacambio", "TASACAMBIO"), tasaCambioDefault),
    TIPO: asString(getValue(forma, "tipo", "TIPO")).trim(),
    NUM_FACT: numFact,
    MONTO: asNumber(getValue(forma, "monto", "MONTO")),
    BANCO: asString(getValue(forma, "banco", "BANCO"), " "),
    CUENTA: asString(getValue(forma, "cuenta", "CUENTA"), " "),
    FECHA_RETENCION: getValue(forma, "fecha", "FECHA", "FECHA_RETENCION") ?? null,
    NUMERO: asString(getValue(forma, "numero", "NUMERO"), "0"),
    MEMORIA: asString(getValue(forma, "memoria", "MEMORIA"), memoria),
    SERIALFISCAL: asString(getValue(forma, "serialfiscal", "SERIALFISCAL"), serialFiscal)
  };
}

async function upsertFormaPagoYTotales(
  tx: sql.Transaction,
  factura: Record<string, unknown>,
  formasPago: FormaPagoInput[],
  formaPagoTable: string
) {
  const numFact = asString(getValue(factura, "NUM_FACT"));
  const memoria = asString(getValue(factura, "TIPO_ORDEN", "MEMORIA"), "");
  const serialFiscal = asString(getValue(factura, "SERIALTIPO"), "");
  const tasaCambio = asNumber(getValue(factura, "Tasacambio", "TASACAMBIO"), 1);

  const formaTableSql = `[dbo].[${formaPagoTable.replace(/]/g, "]]")}]`;

  await txExec(
    tx,
    `DELETE FROM ${formaTableSql} WHERE NUM_FACT = @numFact AND MEMORIA = @memoria AND SERIALFISCAL = @serialFiscal`,
    { numFact, memoria, serialFiscal }
  );

  let montoEfectivo = 0;
  let montoCheque = 0;
  let montoTarjeta = 0;
  let saldoPendiente = 0;
  let cta = " ";
  let bancoCheque = " ";
  let bancoTarjeta = " ";
  let numTarjeta = "0";

  for (let i = 0; i < formasPago.length; i += 1) {
    const mapped = mapFormaPagoRow(formasPago[i], numFact, memoria, serialFiscal, tasaCambio);
    if (!mapped.TIPO || mapped.MONTO === 0) continue;

    const ins = buildInsert(formaTableSql, mapped, `fp${i}`);
    const req = new sql.Request(tx);
    for (const p of ins.params) req.input(p.key, p.value as any);
    await req.query(ins.statement);

    const tipo = mapped.TIPO.toUpperCase();
    if (tipo === "EFECTIVO") {
      montoEfectivo += mapped.MONTO;
    } else if (tipo === "CHEQUE") {
      montoCheque += mapped.MONTO;
      cta = mapped.CUENTA || cta;
      bancoCheque = mapped.BANCO || bancoCheque;

      await txExec(tx, "DELETE FROM [dbo].[DETALLE_DEPOSITO] WHERE CHEQUE = @cheque", { cheque: mapped.NUMERO });
      await txExec(
        tx,
        `INSERT INTO [dbo].[DETALLE_DEPOSITO] (TOTAL, CHEQUE, CTA_BANCO, CLIENTE, RELACIONADA, BANCO)
         VALUES (@total, @cheque, @cta, @cliente, 0, @banco)`,
        {
          total: mapped.MONTO,
          cheque: mapped.NUMERO,
          cta: mapped.CUENTA,
          cliente: asString(getValue(factura, "CODIGO")),
          banco: mapped.BANCO
        }
      );
    } else if (tipo.startsWith("TARJETA") || tipo.startsWith("TICKET")) {
      montoTarjeta += mapped.MONTO;
      bancoTarjeta = mapped.BANCO || bancoTarjeta;
      cta = mapped.CUENTA || cta;
      if (mapped.NUMERO && mapped.NUMERO !== "0") numTarjeta = mapped.NUMERO;
    } else if (tipo === "SALDO PENDIENTE") {
      saldoPendiente += mapped.MONTO;
    }
  }

  const totalFactura = asNumber(getValue(factura, "TOTAL"), 0);
  const abono = totalFactura - saldoPendiente;
  const cancelada = saldoPendiente > 0 ? "N" : "S";
  const fechaPago = getValue(factura, "FECHA_REPORTE", "FECHA") ?? new Date();

  await txExec(
    tx,
    `UPDATE [dbo].[Facturas]
       SET MONTO_EFECT = @montoEfectivo,
           MONTO_CHEQUE = @montoCheque,
           MONTO_TARJETA = @montoTarjeta,
           ABONO = @abono,
           SALDO = @saldoPendiente,
           OBSERV = COALESCE(@observ, OBSERV),
           TARJETA = @numTarjeta,
           CTA = @cta,
           BANCO_CHEQUE = @bancoCheque,
           BANCO_TARJETA = @bancoTarjeta,
           FECHA_RETENCION = NULL,
           CANCELADA = @cancelada,
           FECHA_REPORTE = @fechaPago
     WHERE NUM_FACT = @numFact`,
    {
      numFact,
      montoEfectivo,
      montoCheque,
      montoTarjeta,
      abono,
      saldoPendiente,
      observ: getValue(factura, "OBSERV", "OBSERVACIONES") ?? null,
      numTarjeta,
      cta,
      bancoCheque,
      bancoTarjeta,
      cancelada,
      fechaPago
    }
  );

  return {
    montoEfectivo,
    montoCheque,
    montoTarjeta,
    saldoPendiente,
    abono
  };
}

async function generarCxC(
  tx: sql.Transaction,
  factura: Record<string, unknown>,
  saldoPendiente: number,
  cxcTable: "P_Cobrar" | "P_CobrarC"
) {
  if (saldoPendiente <= 0) return { generated: false };

  const codigo = asString(getValue(factura, "CODIGO"));
  const numFact = asString(getValue(factura, "NUM_FACT"));
  const fecha = getValue(factura, "FECHA") ?? new Date();

  const tableSql = `[dbo].[${cxcTable}]`;
  await txExec(
    tx,
    `DELETE FROM ${tableSql} WHERE CODIGO = @codigo AND DOCUMENTO = @numFact AND TIPO = 'FACT'`,
    { codigo, numFact }
  );

  const current = await txQuery<{ saldo: number }>(
    tx,
    `SELECT TOP 1 SALDO as saldo FROM ${tableSql} WHERE CODIGO = @codigo ORDER BY FECHA DESC`,
    { codigo }
  );
  const saldoPrevio = asNumber(current[0]?.saldo, 0);

  await txExec(
    tx,
    `INSERT INTO ${tableSql} (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO)
     VALUES (@codigo, @codUsuario, @fecha, @numFact, @debe, @pend, @saldo, 'FACT')`,
    {
      codigo,
      codUsuario: asString(getValue(factura, "COD_USUARIO"), "FACTURAS"),
      fecha,
      numFact,
      debe: saldoPendiente,
      pend: saldoPendiente,
      saldo: saldoPrevio + saldoPendiente
    }
  );

  return { generated: true, cxcTable, saldoPendiente };
}

async function actualizarSaldosCliente(tx: sql.Transaction, codigo: string, cxcTable: "P_Cobrar" | "P_CobrarC") {
  const suffix = cxcTable === "P_CobrarC" ? "C" : "";
  const saldoTotCol = `SALDO_TOT${suffix}`;
  const saldo30Col = `SALDO_30${suffix}`;
  const saldo60Col = `SALDO_60${suffix}`;
  const saldo90Col = `SALDO_90${suffix}`;
  const saldo91Col = `SALDO_91${suffix}`;
  const tableSql = `[dbo].[${cxcTable}]`;

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
     FROM ${tableSql}
     WHERE CODIGO = @codigo`,
    { codigo }
  );

  const a = agg[0] ?? { saldo_tot: 0, saldo_30: 0, saldo_60: 0, saldo_90: 0, saldo_91: 0 };

  await txExec(
    tx,
    `UPDATE [dbo].[Clientes]
        SET ${quoteIdent(saldoTotCol)} = @saldoTot,
            ${quoteIdent(saldo30Col)} = @saldo30,
            ${quoteIdent(saldo60Col)} = @saldo60,
            ${quoteIdent(saldo90Col)} = @saldo90,
            ${quoteIdent(saldo91Col)} = @saldo91
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

async function impactarInventarioYMov(tx: sql.Transaction, factura: Record<string, unknown>, detalle: Record<string, unknown>[]) {
  const numFact = asString(getValue(factura, "NUM_FACT"));
  const fecha = getValue(factura, "FECHA") ?? new Date();
  const usuario = asString(getValue(factura, "COD_USUARIO"), "API");

  const byCodigo = new Map<string, number>();
  const byAltRelacionada = new Map<string, number>();

  for (const row of detalle) {
    const codigo = asString(getValue(row, "COD_SERV", "REFERENCIA")).trim();
    const cantidad = asNumber(getValue(row, "CANTIDAD"));
    if (!codigo || cantidad <= 0) continue;

    byCodigo.set(codigo, asNumber(byCodigo.get(codigo), 0) + cantidad);

    const rel = asNumber(getValue(row, "RELACIONADA"), 0);
    const codAlterno = asString(getValue(row, "COD_ALTERNO", "CODIGO"), "").trim();
    if (rel === 1 && codAlterno) {
      byAltRelacionada.set(codAlterno, asNumber(byAltRelacionada.get(codAlterno), 0) + cantidad);
    }

    const prod = await txQuery<{
      EXISTENCIA: number;
      COSTO_REFERENCIA: number;
      ALICUOTA: number;
      PRECIO_VENTA: number;
    }>(
      tx,
      `SELECT TOP 1 EXISTENCIA, COSTO_REFERENCIA, ALICUOTA, PRECIO_VENTA
         FROM [dbo].[Inventario]
        WHERE CODIGO = @codigo`,
      { codigo }
    );

    const p = prod[0];
    if (!p) continue;

    const cantidadActual = asNumber(p.EXISTENCIA, 0);
    const precioVenta = asNumber(getValue(row, "PRECIO", "PRECIO_DESCUENTO"), asNumber(p.PRECIO_VENTA, 0));
    const insMov = buildInsert(
      "[dbo].[MovInvent]",
      {
        CODIGO: codigo,
        PRODUCT: codigo,
        DOCUMENTO: numFact,
        FECHA: fecha,
        MOTIVO: `Doc:${numFact}`,
        TIPO: "Egreso",
        CANTIDAD_ACTUAL: cantidadActual,
        CANTIDAD: cantidad,
        CANTIDAD_NUEVA: cantidadActual - cantidad,
        CO_USUARIO: usuario,
        PRECIO_COMPRA: asNumber(p.COSTO_REFERENCIA, 0),
        ALICUOTA: asNumber(getValue(row, "ALICUOTA"), asNumber(p.ALICUOTA, 0)),
        PRECIO_VENTA: precioVenta
      },
      `mov_${codigo.replace(/[^a-zA-Z0-9]/g, "")}`
    );
    const reqMov = new sql.Request(tx);
    for (const pMov of insMov.params) reqMov.input(pMov.key, pMov.value as any);
    await reqMov.query(insMov.statement);
  }

  for (const [codigo, total] of byCodigo.entries()) {
    await txExec(
      tx,
      "UPDATE [dbo].[Inventario] SET EXISTENCIA = COALESCE(EXISTENCIA, 0) - @cantidad WHERE CODIGO = @codigo",
      { codigo, cantidad: total }
    );
  }

  for (const [codigo, total] of byAltRelacionada.entries()) {
    await txExec(
      tx,
      "UPDATE [dbo].[Inventario_Aux] SET CANTIDAD = COALESCE(CANTIDAD, 0) - @cantidad WHERE CODIGO = @codigo",
      { codigo, cantidad: total }
    );
  }
}

export async function emitirFacturaTx(payload: EmitirFacturaPayload) {
  const factura = payload.factura ?? {};
  const detalle = payload.detalle ?? [];
  const formasPago = payload.formasPago ?? [];
  const options = payload.options ?? {};

  const numFact = asString(getValue(factura, "NUM_FACT"));
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const actualizarInventario = options.actualizarInventario !== false;
  const generarCxCFlag = options.generarCxC !== false;
  const cxcTable: "P_Cobrar" | "P_CobrarC" = options.cxcTable === "P_CobrarC" ? "P_CobrarC" : "P_Cobrar";
  const formaPagoTable = options.formaPagoTable?.trim() || "Detalle_FormaPagoFacturas";
  const actualizarSaldos = options.actualizarSaldosCliente !== false;

  // Fast path: execute SQL Server stored procedure (single round-trip).
  try {
    const pool = await getPool();
    const { facturaXml, detalleXml, formasPagoXml } = facturaPayloadToXml(payload);
    const req = pool.request();
    req.input("FacturaXml", sql.NVarChar(sql.MAX), facturaXml);
    req.input("DetalleXml", sql.NVarChar(sql.MAX), detalleXml);
    req.input("FormasPagoXml", sql.NVarChar(sql.MAX), formasPagoXml);
    req.input("ActualizarInventario", sql.Bit, actualizarInventario ? 1 : 0);
    req.input("GenerarCxC", sql.Bit, generarCxCFlag ? 1 : 0);
    req.input("CxcTable", sql.NVarChar(20), cxcTable);
    req.input("FormaPagoTable", sql.NVarChar(128), formaPagoTable);
    req.input("ActualizarSaldosCliente", sql.Bit, actualizarSaldos ? 1 : 0);

    const spResult = await req.execute("dbo.sp_emitir_factura_tx");
    const row = spResult.recordset?.[0] as
      | {
          ok?: boolean;
          numFact?: string;
          detalleRows?: number;
          montoEfectivo?: number;
          montoCheque?: number;
          montoTarjeta?: number;
          saldoPendiente?: number;
          abono?: number;
        }
      | undefined;

    if (row?.ok) {
      return {
        ok: true,
        numFact: row.numFact ?? numFact,
        detalleRows: row.detalleRows ?? detalle.length,
        formaPagoRows: formasPago.length,
        montoEfectivo: row.montoEfectivo ?? 0,
        montoCheque: row.montoCheque ?? 0,
        montoTarjeta: row.montoTarjeta ?? 0,
        saldoPendiente: row.saldoPendiente ?? 0,
        abono: row.abono ?? 0,
        cxc: {
          generated: generarCxCFlag && (asString(getValue(factura, "PAGO")).toUpperCase() === "CREDITO" || (row.saldoPendiente ?? 0) > 0),
          cxcTable,
          saldoPendiente: row.saldoPendiente ?? 0
        },
        inventoryUpdated: actualizarInventario,
        executionMode: "sp"
      };
    }
  } catch {
    // Fallback to legacy TS transactional flow.
  }

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const reqFactura = new sql.Request(tx);
    const facturaInsert = buildInsert("[dbo].[Facturas]", factura, "ef");
    for (const p of facturaInsert.params) reqFactura.input(p.key, p.value as any);
    await reqFactura.query(facturaInsert.statement);

    for (let i = 0; i < detalle.length; i += 1) {
      const row = { ...detalle[i] };
      if (!getValue(row, "NUM_FACT")) row.NUM_FACT = numFact;
      if (!getValue(row, "SERIALTIPO") && getValue(factura, "SERIALTIPO")) {
        row.SERIALTIPO = getValue(factura, "SERIALTIPO");
      }
      const reqDet = new sql.Request(tx);
      const detInsert = buildInsert("[dbo].[Detalle_facturas]", row, `efd${i}`);
      for (const p of detInsert.params) reqDet.input(p.key, p.value as any);
      await reqDet.query(detInsert.statement);
    }

    const totalesFormaPago = await upsertFormaPagoYTotales(tx, factura, formasPago, formaPagoTable);

    let cxcResult: { generated: boolean; cxcTable?: string; saldoPendiente?: number } = { generated: false };
    const tipoPago = asString(getValue(factura, "PAGO")).toUpperCase();
    if (generarCxCFlag && (tipoPago === "CREDITO" || totalesFormaPago.saldoPendiente > 0)) {
      cxcResult = await generarCxC(tx, factura, totalesFormaPago.saldoPendiente, cxcTable);
    }

    if (actualizarInventario) {
      await impactarInventarioYMov(tx, factura, detalle);
    }

    if (actualizarSaldos) {
      const codigo = asString(getValue(factura, "CODIGO"));
      if (codigo) await actualizarSaldosCliente(tx, codigo, cxcTable);
    }

    await tx.commit();
    return {
      ok: true,
      numFact,
      detalleRows: detalle.length,
      formaPagoRows: formasPago.length,
      ...totalesFormaPago,
      cxc: cxcResult,
      inventoryUpdated: actualizarInventario,
      executionMode: "ts_fallback"
    };
  } catch (err) {
    await tx.rollback();
    throw err;
  }
}


// ============================================
// ANULACIÓN DE FACTURAS - Stored Procedure
// ============================================

export interface AnularFacturaInput {
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}

export interface AnularFacturaResult {
  success: boolean;
  numFact?: string;
  codCliente?: string;
  message: string;
}

/**
 * Anula una factura usando Stored Procedure (SQL Server 2012 compatible)
 * Revierte inventario, anula CxC y registra movimiento de anulación
 */
export async function anularFacturaTx(input: AnularFacturaInput): Promise<AnularFacturaResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  // Configurar parámetros
  request.input("NumFact", sql.NVarChar(60), input.numFact);
  request.input("CodUsuario", sql.NVarChar(60), input.codUsuario || "API");
  request.input("Motivo", sql.NVarChar(500), input.motivo || "");

  // Ejecutar SP
  const result = await request.execute("sp_anular_factura_tx");
  const output = result.recordset?.[0];

  return {
    success: output?.ok === true,
    numFact: output?.numFact,
    codCliente: output?.codCliente,
    message: output?.mensaje || "Factura anulada",
  };
}
