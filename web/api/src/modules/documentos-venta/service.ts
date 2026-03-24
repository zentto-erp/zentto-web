import { callSp, callSpOut, callSpTx, sql } from "../../db/query.js";
import { getPool } from "../../db/mssql.js";
import mssql from "mssql";

export type TipoOperacionVenta = "FACT" | "PRESUP" | "PEDIDO" | "COTIZ" | "NOTACRED" | "NOTADEB" | "NOTA_ENT";

// ---------------------------------------------------------------------------
// Helpers puros (sin SQL)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Mapping functions: VB6 field names -> canonical column names
// ---------------------------------------------------------------------------

function mapHeaderUnified(
  tipoOperacion: TipoOperacionVenta,
  documento: Record<string, unknown>,
  docOrigen?: string,
  tipoDocOrigen?: string
) {
  const numDoc = asString(getValue(documento, "NUM_DOC", "NUM_FACT")).trim();
  const fecha = getValue(documento, "FECHA") ?? new Date();
  const total = asNumber(getValue(documento, "TOTAL"), 0);
  const subtotal = asNumber(getValue(documento, "SUBTOTAL"), total);
  const iva = asNumber(getValue(documento, "IVA"), 0);
  const observ = getValue(documento, "OBSERV", "OBSERVACIONES");
  const pago = asString(getValue(documento, "PAGO"), "");
  const cancelada = ["CONTADO", "EFECTIVO", "PAGADA", "S"].includes(pago.toUpperCase()) ? "S" : "N";

  return {
    DocumentNumber: numDoc,
    SerialType: asString(getValue(documento, "SERIALTIPO"), ""),
    OperationType: tipoOperacion,
    CustomerCode: getValue(documento, "CODIGO", "COD_CLIENTE"),
    CustomerName: getValue(documento, "NOMBRE"),
    FiscalId: getValue(documento, "RIF"),
    DocumentDate: fecha,
    DueDate: getValue(documento, "FECHA_VENCE"),
    SubTotal: subtotal,
    TaxableAmount: getValue(documento, "MONTO_GRA"),
    ExemptAmount: getValue(documento, "MONTO_EXE"),
    TaxAmount: iva,
    TaxRate: asNumber(getValue(documento, "ALICUOTA"), 0),
    TotalAmount: total,
    DiscountAmount: getValue(documento, "DESCUENTO"),
    IsVoided: asNumber(getValue(documento, "ANULADA"), 0),
    IsPaid: asString(getValue(documento, "CANCELADA"), cancelada),
    IsInvoiced: asString(getValue(documento, "FACTURADA"), "N"),
    IsDelivered: asString(getValue(documento, "ENTREGADA"), "N"),
    OriginDocumentNumber: docOrigen ?? getValue(documento, "DOC_ORIGEN"),
    OriginDocumentType: tipoDocOrigen ?? getValue(documento, "TIPO_DOC_ORIGEN"),
    ControlNumber: getValue(documento, "NUM_CONTROL"),
    IsLegal: getValue(documento, "LEGAL"),
    IsPrinted: getValue(documento, "IMPRESA"),
    Notes: observ,
    Concept: getValue(documento, "CONCEPTO"),
    PaymentTerms: getValue(documento, "TERMINOS"),
    ShipToAddress: getValue(documento, "DESPACHAR"),
    SellerCode: getValue(documento, "VENDEDOR"),
    DepartmentCode: getValue(documento, "DEPARTAMENTO"),
    LocationCode: getValue(documento, "LOCACION"),
    CurrencyCode: getValue(documento, "MONEDA"),
    ExchangeRate: getValue(documento, "TASA_CAMBIO"),
    UserCode: getValue(documento, "COD_USUARIO"),
    ReportDate: getValue(documento, "FECHA_REPORTE") ?? new Date(),
    HostName: getValue(documento, "COMPUTER"),
    VehiclePlate: getValue(documento, "PLACAS"),
    Mileage: getValue(documento, "KILOMETROS"),
    TollAmount: getValue(documento, "PEAJE")
  };
}

function mapDetalleUnified(
  tipoOperacion: TipoOperacionVenta,
  numDoc: string,
  detalle: Record<string, unknown>[]
) {
  return detalle.map((d, i) => {
    const cantidad = asNumber(getValue(d, "CANTIDAD"), 0);
    const precio = asNumber(getValue(d, "PRECIO", "PRECIO_VENTA", "PRECIO_COSTO"), 0);
    const descuento = asNumber(getValue(d, "DESCUENTO"), 0);
    const subtotal = cantidad * precio;
    const total = asNumber(getValue(d, "TOTAL"), subtotal - descuento);
    const alicuota = asNumber(getValue(d, "ALICUOTA"), 0);

    return {
      DocumentNumber: numDoc,
      OperationType: tipoOperacion,
      LineNumber: i + 1,
      ProductCode: getValue(d, "COD_SERV", "CODIGO", "REFERENCIA"),
      Description: getValue(d, "DESCRIPCION"),
      AlternateCode: getValue(d, "COD_ALTERNO"),
      Quantity: cantidad,
      UnitPrice: precio,
      DiscountedPrice: getValue(d, "PRECIO_DESCUENTO"),
      UnitCost: getValue(d, "COSTO", "COSTO_REFERENCIA"),
      SubTotal: subtotal,
      DiscountAmount: descuento,
      TotalAmount: total,
      TaxRate: alicuota,
      TaxAmount: asNumber(getValue(d, "MONTO_IVA"), total * (alicuota / 100)),
      IsVoided: asNumber(getValue(d, "ANULADA"), 0),
      RelatedRef: getValue(d, "RELACIONADA"),
      UserCode: getValue(d, "CO_USUARIO"),
      LineDate: getValue(d, "FECHA") ?? new Date()
    };
  });
}

function mapPagosUnified(
  tipoOperacion: TipoOperacionVenta,
  numDoc: string,
  formasPago: Record<string, unknown>[]
) {
  return formasPago.map((fp) => ({
    DocumentNumber: numDoc,
    OperationType: tipoOperacion,
    PaymentMethod: getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"),
    BankCode: getValue(fp, "banco", "BANCO"),
    PaymentNumber: getValue(fp, "numero", "NUMERO", "numCheque"),
    Amount: asNumber(getValue(fp, "monto", "MONTO"), 0),
    AmountBs: asNumber(getValue(fp, "montoBs", "MONTO_BS"), asNumber(getValue(fp, "monto", "MONTO"), 0)),
    ExchangeRate: asNumber(getValue(fp, "tasa", "TASA_CAMBIO"), 1),
    PaymentDate: getValue(fp, "fecha", "FECHA") ?? new Date(),
    DueDate: getValue(fp, "fechaVence", "FECHA_VENCE", "fechaVencimiento"),
    ReferenceNumber: getValue(fp, "referencia", "REFERENCIA"),
    UserCode: getValue(fp, "CO_USUARIO")
  }));
}

function calculatePendingAmount(
  total: number,
  documento: Record<string, unknown>,
  formasPago: Record<string, unknown>[] | undefined
) {
  const pendienteDoc = asNumber(getValue(documento, "PEND", "SALDO", "SALDO_PENDIENTE"), Number.NaN);
  if (Number.isFinite(pendienteDoc) && pendienteDoc >= 0) {
    return pendienteDoc;
  }

  const totalPagado = (formasPago ?? []).reduce((acc, fp) => {
    const tipo = asString(getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO"), "").toUpperCase();
    if (tipo.includes("SALDO")) return acc;
    return acc + asNumber(getValue(fp, "monto", "MONTO"), 0);
  }, 0);

  return Math.max(total - totalPagado, 0);
}

export function normalizeTipoOperacionVenta(value: string): TipoOperacionVenta {
  const raw = String(value || "").trim().toUpperCase();
  const v = raw.replace(/[\s\-]/g, "_");
  const map: Record<string, TipoOperacionVenta> = {
    FACT: "FACT",
    FACTURA: "FACT",
    FACTURAS: "FACT",
    PRESUP: "PRESUP",
    PRESUPUESTO: "PRESUP",
    PRESUPUESTOS: "PRESUP",
    PEDIDO: "PEDIDO",
    PEDIDOS: "PEDIDO",
    COTIZ: "COTIZ",
    COTIZACION: "COTIZ",
    COTIZACIONES: "COTIZ",
    NOTACRED: "NOTACRED",
    NOTA_CRED: "NOTACRED",
    NOTA_CREDITO: "NOTACRED",
    NOTA_CREDITOS: "NOTACRED",
    NOTADEB: "NOTADEB",
    NOTA_DEB: "NOTADEB",
    NOTA_DEBITO: "NOTADEB",
    NOTA_DEBITOS: "NOTADEB",
    NOTA_ENT: "NOTA_ENT",
    NOTA_ENTREGA: "NOTA_ENT",
    NOTAS_ENTREGA: "NOTA_ENT"
  };
  const normalized = map[v] ?? map[raw];
  if (!normalized) throw new Error("tipo_operacion_invalido");
  return normalized;
}

// ---------------------------------------------------------------------------
// Exported service functions (all via stored procedures)
// ---------------------------------------------------------------------------

export async function listDocumentosVenta(input: {
  tipoOperacion: TipoOperacionVenta;
  search?: string;
  codigo?: string;
  page?: string;
  limit?: string;
  from?: string;
  to?: string;
  estado?: string;
}) {
  const page = Math.max(Number(input.page || 1), 1);
  const limit = Math.min(Math.max(Number(input.limit || 50), 1), 500);

  const { rows, output } = await callSpOut<any>(
    "usp_Doc_SalesDocument_List",
    {
      TipoOperacion: input.tipoOperacion,
      Search: input.search || null,
      Codigo: input.codigo || null,
      FromDate: input.from || null,
      ToDate: input.to || null,
      Estado: input.estado || null,
      Page: page,
      Limit: limit
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: Number(output.TotalCount ?? 0),
    rows,
    executionMode: "unified" as const
  };
}

export async function getDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  const rows = await callSp<any>("usp_Doc_SalesDocument_Get", {
    TipoOperacion: tipoOperacion,
    NumDoc: numFact
  });

  return {
    row: rows[0] ?? null,
    executionMode: "unified" as const
  };
}

export async function getDetalleDocumentoVenta(tipoOperacion: TipoOperacionVenta, numFact: string) {
  return callSp<any>("usp_Doc_SalesDocument_GetDetail", {
    TipoOperacion: tipoOperacion,
    NumDoc: numFact
  });
}

export async function emitirDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  const header = mapHeaderUnified(
    payload.tipoOperacion,
    payload.documento,
    asString(getValue(payload.documento, "DOC_ORIGEN"), "").trim() || undefined,
    asString(getValue(payload.documento, "TIPO_DOC_ORIGEN"), "").trim() || undefined
  );

  const numDoc = header.DocumentNumber;
  if (!numDoc) throw new Error("missing_num_doc");

  const detail = mapDetalleUnified(payload.tipoOperacion, numDoc, payload.detalle);
  const payments = mapPagosUnified(payload.tipoOperacion, numDoc, payload.formasPago ?? []);

  const headerJson = JSON.stringify(header);
  const detailJson = JSON.stringify(detail);
  const paymentsJson = payments.length > 0 ? JSON.stringify(payments) : null;

  const rows = await callSp<{
    ok: boolean;
    numDoc: string;
    detalleRows: number;
    formasPagoRows: number;
    pendingAmount: number;
  }>("usp_Doc_SalesDocument_Upsert", {
    TipoOperacion: payload.tipoOperacion,
    HeaderJson: headerJson,
    DetailJson: detailJson,
    PaymentsJson: paymentsJson
  });

  const result = rows[0];

  return {
    ok: !!result?.ok,
    numFact: result?.numDoc ?? numDoc,
    detalleRows: result?.detalleRows ?? detail.length,
    formaPagoRows: result?.formasPagoRows ?? payments.length,
    saldoPendiente: result?.pendingAmount ?? 0,
    executionMode: "unified"
  };
}

export async function anularDocumentoVentaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  const rows = await callSp<{
    ok: boolean;
    numFact: string;
    codCliente: string | null;
    mensaje: string;
  }>("usp_Doc_SalesDocument_Void", {
    TipoOperacion: payload.tipoOperacion,
    NumDoc: payload.numFact,
    CodUsuario: payload.codUsuario ?? "API",
    Motivo: payload.motivo ?? ""
  });

  const result = rows[0];
  if (!result?.ok) {
    throw new Error(result?.mensaje ?? "documento_no_encontrado");
  }

  return {
    ok: true,
    numFact: payload.numFact,
    executionMode: "unified" as const
  };
}

export async function facturarDesdePedidoTx(payload: {
  numFactPedido: string;
  factura: Record<string, unknown>;
  formasPago?: Record<string, unknown>[];
  options?: { generarCxC?: boolean; actualizarSaldosCliente?: boolean };
}) {
  const numFactPedido = asString(payload.numFactPedido).trim();
  const numFactFactura = asString(getValue(payload.factura ?? {}, "NUM_FACT", "NUM_DOC")).trim();
  if (!numFactPedido) throw new Error("missing_num_fact_pedido");
  if (!numFactFactura) throw new Error("missing_num_fact_factura");

  // Map payments to canonical format for the SP
  const payments = mapPagosUnified("FACT", numFactFactura, payload.formasPago ?? []);
  const paymentsJson = payments.length > 0 ? JSON.stringify(payments) : null;

  const rows = await callSp<{
    ok: boolean;
    pedido: string;
    factura: string;
    mensaje: string;
  }>("usp_Doc_SalesDocument_InvoiceFromOrder", {
    NumDocPedido: numFactPedido,
    NumDocFactura: numFactFactura,
    FormasPagoJson: paymentsJson,
    CodUsuario: asString(getValue(payload.factura ?? {}, "COD_USUARIO"), "API")
  });

  const result = rows[0];
  if (!result?.ok) {
    throw new Error(result?.mensaje ?? "facturacion_fallida");
  }

  return {
    ok: true,
    pedido: numFactPedido,
    factura: numFactFactura,
    inventarioReDescontado: false,
    facturaResult: {
      ok: true,
      numFact: numFactFactura,
      detalleRows: 0,
      formaPagoRows: payments.length,
      saldoPendiente: 0,
      executionMode: "unified"
    }
  };
}
