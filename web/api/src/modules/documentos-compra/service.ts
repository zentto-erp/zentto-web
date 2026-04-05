import { callSp, callSpOut, sql } from "../../db/query.js";
import { objectToXml, arrayToXml } from "../../utils/xml.js";
import { getActiveScope } from "../_shared/scope.js";

export type TipoOperacionCompra = "ORDEN" | "COMPRA";

// ---------------------------------------------------------------------------
// Helpers de acceso a campos (se conservan del servicio original)
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

function asString(v: unknown, fallback = "") {
  if (v === null || v === undefined) return fallback;
  return String(v);
}

function asNumber(v: unknown, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

// ---------------------------------------------------------------------------
// Normalizador de tipo de operacion
// ---------------------------------------------------------------------------

export function normalizeTipoOperacionCompra(value?: string): TipoOperacionCompra {
  const raw = String(value || "COMPRA").trim().toUpperCase();
  const v = raw.replace(/[\s\-]/g, "_");
  const map: Record<string, TipoOperacionCompra> = {
    ORDEN: "ORDEN",
    ORDENES: "ORDEN",
    ORDEN_COMPRA: "ORDEN",
    ORDENES_COMPRA: "ORDEN",
    ORDC: "ORDEN",
    OC: "ORDEN",
    COMPRA: "COMPRA",
    COMPRAS: "COMPRA",
    FACT: "COMPRA",
    FACTURA: "COMPRA"
  };

  return map[v] ?? map[raw] ?? "COMPRA";
}

// ---------------------------------------------------------------------------
// Mapeo de documento entrante -> nombres canonicos (JSON para el SP)
// ---------------------------------------------------------------------------

function mapHeader(tipoOperacion: TipoOperacionCompra, documento: Record<string, unknown>, docOrigen?: string) {
  const numDoc = asString(getValue(documento, "NUM_DOC", "NUM_FACT", "DocumentNumber")).trim();
  const total = asNumber(getValue(documento, "TOTAL", "TotalAmount"), 0);

  return {
    DocumentNumber: numDoc,
    SerialType: asString(getValue(documento, "SERIALTIPO", "SerialType"), ""),
    OperationType: tipoOperacion,
    SupplierCode: getValue(documento, "COD_PROVEEDOR", "CODIGO", "SupplierCode"),
    SupplierName: getValue(documento, "NOMBRE", "SupplierName"),
    FiscalId: getValue(documento, "RIF", "FiscalId"),
    DocumentDate: getValue(documento, "FECHA", "DocumentDate") ?? new Date(),
    DueDate: getValue(documento, "FECHA_VENCE", "FECHAVENCE", "DueDate"),
    ReceiptDate: getValue(documento, "FECHA_RECIBO", "FECHARECIBO", "ReceiptDate"),
    PaymentDate: getValue(documento, "FECHA_PAGO", "PaymentDate"),
    DocumentTime: getValue(documento, "HORA", "DocumentTime"),
    SubTotal: getValue(documento, "SUBTOTAL", "MONTO_GRA", "SubTotal", "TOTAL"),
    TaxableAmount: getValue(documento, "MONTO_GRA", "TaxableAmount"),
    ExemptAmount: getValue(documento, "MONTO_EXE", "EXENTO", "ExemptAmount"),
    TaxAmount: getValue(documento, "IVA", "TaxAmount"),
    TaxRate: getValue(documento, "ALICUOTA", "TaxRate"),
    TotalAmount: total,
    DiscountAmount: getValue(documento, "DESCUENTO", "DiscountAmount"),
    IsVoided: getValue(documento, "ANULADA", "IsVoided") ?? 0,
    IsPaid: asString(getValue(documento, "CANCELADA", "IsPaid"), "N"),
    IsReceived: asString(getValue(documento, "RECIBIDA", "IsReceived"), "N"),
    IsLegal: getValue(documento, "LEGAL", "IsLegal"),
    OriginDocumentNumber: docOrigen ?? getValue(documento, "DOC_ORIGEN", "PEDIDO", "OriginDocumentNumber"),
    ControlNumber: getValue(documento, "NUM_CONTROL", "ControlNumber"),
    WithholdingCertNumber: getValue(documento, "NRO_COMPROBANTE", "WithholdingCertNumber"),
    WithholdingCertDate: getValue(documento, "FECHA_COMPROBANTE", "WithholdingCertDate"),
    WithheldTaxAmount: getValue(documento, "IVA_RETENIDO", "IvaRetenido", "WithheldTaxAmount"),
    IncomeTaxCode: getValue(documento, "ISLR", "ISRL", "IncomeTaxCode"),
    IncomeTaxAmount: getValue(documento, "MONTO_ISLR", "MontoISRL", "IncomeTaxAmount"),
    IncomeTaxPercent: getValue(documento, "CODIGO_ISLR", "CodigoISLR", "IncomeTaxPercent"),
    IsSubjectToIncomeTax: getValue(documento, "SUJETO_ISLR", "IsSubjectToIncomeTax"),
    WithholdingRate: getValue(documento, "TASA_RETENCION", "WithholdingRate"),
    IsImport: getValue(documento, "IMPORTACION", "IsImport"),
    ImportTaxAmount: getValue(documento, "IVA_IMPORT", "IVAIMPORT", "ImportTaxAmount"),
    ImportTaxBase: getValue(documento, "BASE_IMPORT", "BASEIMPORT", "ImportTaxBase"),
    FreightAmount: getValue(documento, "FLETE", "FreightAmount"),
    Notes: getValue(documento, "OBSERV", "obs", "Notes"),
    Concept: getValue(documento, "CONCEPTO", "Concept"),
    OrderNumber: getValue(documento, "PEDIDO", "OrderNumber"),
    ReceivedBy: getValue(documento, "RECIBIDO", "ReceivedBy"),
    WarehouseCode: getValue(documento, "ALMACEN", "Almacen", "WarehouseCode"),
    CurrencyCode: getValue(documento, "MONEDA", "CurrencyCode"),
    ExchangeRate: getValue(documento, "TASA_CAMBIO", "ExchangeRate"),
    DollarPrice: getValue(documento, "PRECIO_DOLLAR", "DollarPrice"),
    UserCode: getValue(documento, "COD_USUARIO", "UserCode"),
    ShortUserCode: getValue(documento, "CO_USUARIO", "ShortUserCode"),
    ReportDate: getValue(documento, "FECHA_REPORTE", "ReportDate") ?? new Date(),
    HostName: getValue(documento, "COMPUTER", "HostName")
  };
}

function mapDetalle(tipoOperacion: TipoOperacionCompra, numDoc: string, detalle: Record<string, unknown>[]) {
  return detalle.map((d, i) => {
    const cantidad = asNumber(getValue(d, "CANTIDAD", "Quantity"), 0);
    const precio = asNumber(getValue(d, "PRECIO", "PRECIO_COSTO", "UnitPrice"), 0);
    const descuento = asNumber(getValue(d, "DESCUENTO", "DiscountAmount"), 0);
    const subtotal = cantidad * precio;
    const total = asNumber(getValue(d, "TOTAL", "TotalAmount"), subtotal - descuento);
    const alicuota = asNumber(getValue(d, "ALICUOTA", "TaxRate"), 0);

    return {
      DocumentNumber: numDoc,
      OperationType: tipoOperacion,
      LineNumber: i + 1,
      ProductCode: getValue(d, "COD_SERV", "CODIGO", "REFERENCIA", "ProductCode"),
      Description: getValue(d, "DESCRIPCION", "Description"),
      Quantity: cantidad,
      UnitPrice: precio,
      UnitCost: getValue(d, "COSTO", "COSTO_REFERENCIA", "PRECIO_COSTO", "UnitCost"),
      SubTotal: subtotal,
      DiscountAmount: descuento,
      TotalAmount: total,
      TaxRate: alicuota,
      TaxAmount: asNumber(getValue(d, "MONTO_IVA", "TaxAmount"), total * (alicuota / 100)),
      IsVoided: getValue(d, "ANULADA", "IsVoided") ?? 0,
      UserCode: getValue(d, "CO_USUARIO", "UserCode"),
      LineDate: getValue(d, "FECHA", "LineDate") ?? new Date()
    };
  });
}

function mapPagos(tipoOperacion: TipoOperacionCompra, numDoc: string, formasPago: Record<string, unknown>[]) {
  return formasPago.map((fp) => ({
    DocumentNumber: numDoc,
    OperationType: tipoOperacion,
    PaymentMethod: getValue(fp, "tipo", "TIPO_PAGO", "FORMA_PAGO", "PaymentMethod"),
    BankCode: getValue(fp, "banco", "BANCO", "BankCode"),
    PaymentNumber: getValue(fp, "numero", "NUMERO", "numCheque", "PaymentNumber"),
    Amount: asNumber(getValue(fp, "monto", "MONTO", "Amount"), 0),
    PaymentDate: getValue(fp, "fecha", "FECHA", "PaymentDate") ?? new Date(),
    DueDate: getValue(fp, "fechaVence", "FECHA_VENCE", "fechaVencimiento", "DueDate"),
    ReferenceNumber: getValue(fp, "referencia", "REFERENCIA", "ReferenceNumber"),
    UserCode: getValue(fp, "CO_USUARIO", "UserCode")
  }));
}

// ---------------------------------------------------------------------------
// Funciones de servicio exportadas
// ---------------------------------------------------------------------------

function mapCompraRow(r: any) {
  return {
    documentId:    r.DocumentId    ?? r.documentId    ?? r.PurchaseDocumentId ?? 0,
    documentNumber:r.DocumentNumber?? r.documentNumber?? "",
    supplierCode:  r.SupplierCode  ?? r.supplierCode  ?? null,
    supplierName:  r.SupplierName  ?? r.supplierName  ?? null,
    fiscalId:      r.FiscalId      ?? r.fiscalId      ?? null,
    issueDate:     r.IssueDate     ?? r.issueDate     ?? null,
    totalAmount:   r.TotalAmount   ?? r.totalAmount   ?? 0,
    documentType:  r.DocumentType  ?? r.documentType  ?? null,
    status:        r.Status        ?? r.status        ?? null,
    isVoided:      r.IsVoided      ?? r.isVoided      ?? false,
  };
}

export async function listDocumentosCompra(input: {
  tipoOperacion: TipoOperacionCompra;
  search?: string;
  codigo?: string;
  proveedor?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: string;
  limit?: string;
}) {
  const page = Math.max(Number(input.page || 1), 1);
  const limit = Math.min(Math.max(Number(input.limit || 50), 1), 500);

  const scope = getActiveScope();
  const { rows, output } = await callSpOut<any>(
    "usp_Doc_PurchaseDocument_List",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: input.tipoOperacion,
      Search: input.search || null,
      Codigo: input.proveedor ?? input.codigo ?? null,
      FromDate: input.fechaDesde || null,
      ToDate: input.fechaHasta || null,
      Page: page,
      Limit: limit
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: (output.TotalCount as number) ?? 0,
    rows: rows.map(mapCompraRow),
    executionMode: "unified" as const
  };
}

export async function getDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  const scope = getActiveScope();
  const rows = await callSp<any>(
    "usp_Doc_PurchaseDocument_Get",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: tipoOperacion,
      NumDoc: numFact
    }
  );

  return {
    row: rows[0] ?? null,
    executionMode: "unified" as const
  };
}

export async function getDetalleDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  const scope = getActiveScope();
  return callSp<any>(
    "usp_Doc_PurchaseDocument_GetDetail",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: tipoOperacion,
      NumDoc: numFact
    }
  );
}

export async function getIndicadoresDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  const scope = getActiveScope();
  const rows = await callSp<any>(
    "usp_Doc_PurchaseDocument_GetIndicadores",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: tipoOperacion,
      NumDoc: numFact
    }
  );

  return rows[0] ?? null;
}

export async function emitirDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  const headerData = mapHeader(payload.tipoOperacion, payload.documento);
  const numDoc = headerData.DocumentNumber;
  if (!numDoc) throw new Error("missing_num_doc");

  const detalleData = mapDetalle(payload.tipoOperacion, numDoc, payload.detalle);
  const pagosData = mapPagos(payload.tipoOperacion, numDoc, []);

  const scope = getActiveScope();
  const rows = await callSp<{
    ok: boolean;
    numDoc: string;
    detalleRows: number;
    formasPagoRows: number;
    pendingAmount: number;
    mensaje?: string;
  }>(
    "usp_Doc_PurchaseDocument_Upsert",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: payload.tipoOperacion,
      HeaderXml: objectToXml(headerData),
      DetailXml: arrayToXml(detalleData),
      PaymentsXml: pagosData.length > 0 ? arrayToXml(pagosData) : null
    }
  );

  const result = rows[0];
  if (!result?.ok) {
    throw new Error(result?.mensaje ?? "upsert_failed");
  }

  return {
    ok: true,
    numFact: result.numDoc,
    detalleRows: result.detalleRows,
    formaPagoRows: result.formasPagoRows,
    saldoPendiente: result.pendingAmount,
    executionMode: "unified"
  };
}

export async function anularDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  const scope = getActiveScope();
  const rows = await callSp<{
    ok: boolean;
    numDoc: string;
    codProveedor: string | null;
    mensaje: string;
  }>(
    "usp_Doc_PurchaseDocument_Void",
    {
      CompanyId: scope?.companyId ?? 1,
      TipoOperacion: payload.tipoOperacion,
      NumDoc: payload.numFact,
      CodUsuario: payload.codUsuario ?? "API",
      Motivo: payload.motivo ?? ""
    }
  );

  const result = rows[0];
  if (!result?.ok) {
    throw new Error(result?.mensaje ?? "documento_no_encontrado");
  }

  return {
    ok: true,
    numFact: result.numDoc,
    executionMode: "unified" as const
  };
}

export async function cerrarOrdenConCompraDocumentoTx(payload: {
  numFactOrden: string;
  compra: Record<string, unknown>;
  detalle?: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxP?: boolean;
    actualizarSaldosProveedor?: boolean;
  };
}) {
  const numFactOrden = asString(payload.numFactOrden).trim();
  const numFactCompra = asString(getValue(payload.compra ?? {}, "NUM_DOC", "NUM_FACT", "DocumentNumber")).trim();
  if (!numFactOrden) throw new Error("missing_num_fact_orden");
  if (!numFactCompra) throw new Error("missing_num_fact_compra");

  // Construir JSON de overrides para la compra (campos canonicos)
  const compraOverride: Record<string, unknown> = {};
  const c = payload.compra ?? {};
  const supplierCode = getValue(c, "COD_PROVEEDOR", "SupplierCode");
  if (supplierCode !== undefined) compraOverride.SupplierCode = supplierCode;
  const supplierName = getValue(c, "NOMBRE", "SupplierName");
  if (supplierName !== undefined) compraOverride.SupplierName = supplierName;
  const fiscalId = getValue(c, "RIF", "FiscalId");
  if (fiscalId !== undefined) compraOverride.FiscalId = fiscalId;
  const fecha = getValue(c, "FECHA", "DocumentDate");
  if (fecha !== undefined) compraOverride.DocumentDate = fecha;
  const total = getValue(c, "TOTAL", "TotalAmount");
  if (total !== undefined) compraOverride.TotalAmount = total;
  const notes = getValue(c, "OBSERV", "Notes");
  if (notes !== undefined) compraOverride.Notes = notes;
  const codUsuario = getValue(c, "COD_USUARIO", "UserCode") ?? "API";

  // Construir JSON de detalle (si se proporcionaron)
  let detalleXml: string | null = null;
  if (payload.detalle && payload.detalle.length > 0) {
    const detalleData = mapDetalle("COMPRA", numFactCompra, payload.detalle);
    detalleXml = arrayToXml(detalleData);
  }

  const scope = getActiveScope();
  const rows = await callSp<{
    ok: boolean;
    orden: string;
    compra: string;
    detalleRows: number;
    formasPagoRows: number;
    pendingAmount: number;
    mensaje: string;
  }>(
    "usp_Doc_PurchaseDocument_ConvertOrder",
    {
      CompanyId: scope?.companyId ?? 1,
      NumDocOrden: numFactOrden,
      NumDocCompra: numFactCompra,
      CompraOverrideXml: Object.keys(compraOverride).length > 0 ? objectToXml(compraOverride) : null,
      DetalleXml: detalleXml,
      CodUsuario: asString(codUsuario, "API")
    }
  );

  const result = rows[0];
  if (!result?.ok) {
    throw new Error(result?.mensaje ?? "conversion_failed");
  }

  return {
    ok: true,
    orden: result.orden,
    compra: result.compra,
    compraResult: {
      ok: true,
      numFact: result.compra,
      detalleRows: result.detalleRows,
      formaPagoRows: result.formasPagoRows,
      saldoPendiente: result.pendingAmount,
      executionMode: "unified"
    }
  };
}
