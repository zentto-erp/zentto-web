
import { callSp } from "../../db/query.js";
import { getPool } from "../../db/mssql.js";
import { getActiveScope } from "../_shared/scope.js";

interface DefaultScope {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
}

let scopeCache: DefaultScope | null = null;

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (scopeCache && activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (scopeCache) return scopeCache;

  const rows = await callSp<{ companyId: number; branchId: number; systemUserId: number | null }>(
    "usp_Cfg_Scope_GetDefault"
  );

  const row = rows[0];
  scopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };
  if (activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  return scopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  if (!code) return (await getDefaultScope()).systemUserId;

  const rows = await callSp<{ userId: number }>(
    "usp_Sec_User_ResolveByCode",
    { Code: code }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getDefaultScope()).systemUserId;
}

async function resolveSupplierId(value?: string) {
  const scope = await getDefaultScope();
  const key = String(value ?? "").trim();
  if (!key) return null;

  const rows = await callSp<{ supplierId: number }>(
    "usp_Rest_Admin_ResolveSupplier",
    { CompanyId: scope.companyId, Key: key }
  );

  return rows[0]?.supplierId == null ? null : Number(rows[0].supplierId);
}

async function resolveInventoryProductId(value?: string) {
  const scope = await getDefaultScope();
  const key = String(value ?? "").trim();
  if (!key) return null;

  const rows = await callSp<{ productId: number }>(
    "usp_Rest_Admin_ResolveProduct",
    { CompanyId: scope.companyId, Key: key }
  );

  return rows[0]?.productId == null ? null : Number(rows[0].productId);
}

async function resolveMenuCategoryId(value?: number) {
  if (!value || value <= 0) return null;
  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_ResolveMenuCategory",
    { MenuCategoryId: value }
  );
  return rows[0]?.id == null ? null : Number(rows[0].id);
}

async function recalcPurchaseTotals(purchaseId: number) {
  await callSp("usp_Rest_Admin_Compra_RecalcTotals", { PurchaseId: purchaseId });
}

async function adjustStock(inventoryProductId: number | null, deltaQty: number) {
  if (!inventoryProductId || !Number.isFinite(deltaQty) || deltaQty === 0) return;

  await callSp("usp_Rest_Admin_AdjustStock", {
    ProductId: inventoryProductId,
    DeltaQty: deltaQty,
  });
}

function toCode(name: string, fallback: string) {
  const normalized = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toUpperCase();
  return (normalized || fallback).slice(0, 30);
}

function extractStorageKeyFromUrl(url?: string | null) {
  const value = String(url ?? "").trim();
  const prefix = "/media-files/";
  const idx = value.indexOf(prefix);
  if (idx < 0) return null;
  return value.slice(idx + prefix.length).replace(/\\/g, "/").replace(/^\/+/, "");
}

async function syncMenuProductImageLink(
  companyId: number,
  branchId: number,
  menuProductId: number,
  imageUrl: string | null | undefined,
  userId: number | null
) {
  const storageKey = extractStorageKeyFromUrl(imageUrl);
  if (!storageKey) return;

  await callSp("usp_Rest_Admin_SyncMenuProductImage", {
    CompanyId: companyId,
    BranchId: branchId,
    MenuProductId: menuProductId,
    StorageKey: storageKey,
    UserId: userId,
  });
}

export async function listAmbientes() {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "usp_Rest_Admin_Ambiente_List",
    { CompanyId: scope.companyId, BranchId: scope.branchId }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function upsertAmbiente(data: { id?: number; nombre: string; color?: string; orden?: number }) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Ambiente_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Code: toCode(nombre, "AMBIENTE"),
      Nombre: nombre,
      Color: data.color ?? null,
      Orden: Number(data.orden ?? 0),
      UserId: userId,
    }
  );

  return { ok: true, id: Number(rows[0]?.id ?? data.id ?? 0) };
}

export async function listCategoriasMenu() {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "usp_Rest_Admin_Categoria_List",
    { CompanyId: scope.companyId, BranchId: scope.branchId }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function upsertCategoriaMenu(data: { id?: number; nombre: string; descripcion?: string; color?: string; orden?: number }) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Categoria_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Code: toCode(nombre, "CATEGORIA"),
      Nombre: nombre,
      Descripcion: data.descripcion ?? null,
      Color: data.color ?? null,
      Orden: Number(data.orden ?? 0),
      UserId: userId,
    }
  );

  return { ok: true, id: Number(rows[0]?.id ?? data.id ?? 0) };
}

export async function listProductosMenu(params: { categoriaId?: number; search?: string; soloDisponibles?: boolean }) {
  const scope = await getDefaultScope();
  const search = params.search?.trim() ? `%${params.search.trim()}%` : null;

  const rows = await callSp<any>(
    "usp_Rest_Admin_Producto_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      MenuCategoryId: params.categoriaId && params.categoriaId > 0 ? params.categoriaId : null,
      Search: search,
      SoloDisponibles: (params.soloDisponibles ?? true) ? 1 : 0,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function getProductoMenu(id: number) {
  const scope = await getDefaultScope();

  const pool = await getPool();
  const request = pool.request();
  request.input("Id", id);
  request.input("BranchId", scope.branchId);
  const result = await request.execute("usp_Rest_Admin_Producto_Get");

  const recordsets = result.recordsets as any[];
  const productoRows = (recordsets[0] ?? []) as any[];
  const componentRows = (recordsets[1] ?? []) as any[];
  const receta = (recordsets[2] ?? []) as any[];

  const producto = productoRows[0] ?? null;
  if (!producto) {
    return { producto: null, componentes: [], receta: [], executionMode: "ts_canonical" as const };
  }

  const componentMap: Record<number, any> = {};
  for (const row of componentRows) {
    const componentId = Number(row.id);
    if (!componentMap[componentId]) {
      componentMap[componentId] = {
        id: componentId,
        nombre: row.nombre,
        obligatorio: Boolean(row.obligatorio),
        orden: Number(row.orden ?? 0),
        opciones: [],
      };
    }
    if (row.opcionId != null) {
      componentMap[componentId].opciones.push({
        id: Number(row.opcionId),
        nombre: row.opcionNombre,
        precioExtra: Number(row.precioExtra ?? 0),
        orden: Number(row.opcionOrden ?? 0),
      });
    }
  }

  return {
    producto,
    componentes: Object.values(componentMap),
    receta,
    executionMode: "ts_canonical" as const,
  };
}

export async function upsertProductoMenu(data: {
  id?: number;
  codigo: string;
  nombre: string;
  descripcion?: string;
  categoriaId?: number;
  precio?: number;
  costoEstimado?: number;
  iva?: number;
  esCompuesto?: boolean;
  tiempoPreparacion?: number;
  imagen?: string;
  esSugerenciaDelDia?: boolean;
  disponible?: boolean;
  articuloInventarioId?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const code = String(data.codigo ?? "").trim().toUpperCase();
  const name = String(data.nombre ?? "").trim();
  if (!code || !name) throw new Error("codigo y nombre son obligatorios");

  const menuCategoryId = await resolveMenuCategoryId(data.categoriaId);
  const inventoryProductId = await resolveInventoryProductId(data.articuloInventarioId);

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Producto_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Code: code,
      Name: name,
      Description: data.descripcion ?? null,
      MenuCategoryId: menuCategoryId,
      Price: Number(data.precio ?? 0),
      EstimatedCost: Number(data.costoEstimado ?? 0),
      TaxRatePercent: Number(data.iva ?? 16),
      IsComposite: Boolean(data.esCompuesto ?? false) ? 1 : 0,
      PrepMinutes: Number(data.tiempoPreparacion ?? 0),
      ImageUrl: data.imagen ?? null,
      IsDailySuggestion: Boolean(data.esSugerenciaDelDia ?? false) ? 1 : 0,
      IsAvailable: (data.disponible !== false) ? 1 : 0,
      InventoryProductId: inventoryProductId,
      UserId: userId,
    }
  );

  const resultId = Number(rows[0]?.id ?? data.id ?? 0);
  if (resultId > 0) {
    await syncMenuProductImageLink(scope.companyId, scope.branchId, resultId, data.imagen ?? null, userId);
  }
  return { ok: true, id: resultId };
}

export async function deleteProductoMenu(id: number) {
  await callSp("usp_Rest_Admin_Producto_Delete", { Id: id });
  return { ok: true };
}

export async function upsertComponente(data: { id?: number; productoId: number; nombre: string; obligatorio?: boolean; orden?: number }) {
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Componente_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      ProductoId: data.productoId,
      Nombre: nombre,
      Obligatorio: Boolean(data.obligatorio ?? false) ? 1 : 0,
      Orden: Number(data.orden ?? 0),
    }
  );

  return { ok: true, id: Number(rows[0]?.id ?? data.id ?? 0) };
}

export async function upsertOpcion(data: { id?: number; componenteId: number; nombre: string; precioExtra?: number; orden?: number }) {
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Opcion_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      ComponenteId: data.componenteId,
      Nombre: nombre,
      PrecioExtra: Number(data.precioExtra ?? 0),
      Orden: Number(data.orden ?? 0),
    }
  );

  return { ok: true, id: Number(rows[0]?.id ?? data.id ?? 0) };
}

export async function upsertRecetaItem(data: { id?: number; productoId: number; inventarioId: string; cantidad: number; unidad?: string; comentario?: string }) {
  const ingredientProductId = await resolveInventoryProductId(data.inventarioId);
  if (!ingredientProductId) {
    throw new Error("Insumo no encontrado");
  }

  const rows = await callSp<{ id: number }>(
    "usp_Rest_Admin_Receta_Upsert",
    {
      Id: data.id && data.id > 0 ? data.id : 0,
      ProductoId: data.productoId,
      IngredientProductId: ingredientProductId,
      Quantity: Number(data.cantidad ?? 0),
      UnitCode: data.unidad ?? null,
      Notes: data.comentario ?? null,
    }
  );

  return { ok: true, id: Number(rows[0]?.id ?? data.id ?? 0) };
}

export async function deleteRecetaItem(id: number) {
  await callSp("usp_Rest_Admin_Receta_Delete", { Id: id });
  return { ok: true };
}

export async function listCompras(params: { estado?: string; from?: string; to?: string }) {
  const scope = await getDefaultScope();

  let fromDate: Date | null = null;
  let toDate: Date | null = null;
  if (params.from) {
    const d = new Date(params.from);
    if (!Number.isNaN(d.getTime())) fromDate = d;
  }
  if (params.to) {
    const d = new Date(params.to);
    if (!Number.isNaN(d.getTime())) toDate = d;
  }

  const rows = await callSp<any>(
    "usp_Rest_Admin_Compra_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Status: params.estado?.trim() ? params.estado.trim().toUpperCase() : null,
      FromDate: fromDate,
      ToDate: toDate,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function getCompraDetalle(compraId: number) {
  const pool = await getPool();
  const request = pool.request();
  request.input("CompraId", compraId);
  const result = await request.execute("usp_Rest_Admin_Compra_GetDetalle");

  const recordsets2 = result.recordsets as any[];
  const headerRows = (recordsets2[0] ?? []) as any[];
  const detalle = (recordsets2[1] ?? []) as any[];

  return {
    compra: headerRows[0] ?? null,
    detalle,
  };
}

export async function upsertCompraDetalle(data: {
  id?: number;
  compraId: number;
  inventarioId?: string;
  descripcion: string;
  cantidad: number;
  precioUnit: number;
  iva?: number;
}) {
  const ingredientProductId = await resolveInventoryProductId(data.inventarioId);
  const quantity = Number(data.cantidad ?? 0);
  const unitPrice = Number(data.precioUnit ?? 0);
  const iva = Number(data.iva ?? 16);
  const subtotal = Number((quantity * unitPrice).toFixed(2));

  if (data.id && data.id > 0) {
    const prev = await callSp<{ ingredientProductId: number | null; quantity: number }>(
      "usp_Rest_Admin_CompraLinea_GetPrev",
      { Id: data.id, CompraId: data.compraId }
    );

    const rows = await callSp<{ id: number }>(
      "usp_Rest_Admin_CompraLinea_Upsert",
      {
        Id: data.id,
        CompraId: data.compraId,
        IngredientProductId: ingredientProductId,
        Descripcion: String(data.descripcion ?? "").trim() || "SIN DESCRIPCION",
        Quantity: quantity,
        UnitPrice: unitPrice,
        TaxRatePercent: iva,
        Subtotal: subtotal,
      }
    );

    const prevProductId = prev[0]?.ingredientProductId == null ? null : Number(prev[0].ingredientProductId);
    const prevQty = Number(prev[0]?.quantity ?? 0);

    if (prevProductId && ingredientProductId && prevProductId === ingredientProductId) {
      await adjustStock(ingredientProductId, quantity - prevQty);
    } else {
      await adjustStock(prevProductId, -prevQty);
      await adjustStock(ingredientProductId, quantity);
    }

    await recalcPurchaseTotals(data.compraId);
    return { ok: true, id: data.id, compraId: data.compraId };
  }

  const inserted = await callSp<{ id: number }>(
    "usp_Rest_Admin_CompraLinea_Upsert",
    {
      Id: 0,
      CompraId: data.compraId,
      IngredientProductId: ingredientProductId,
      Descripcion: String(data.descripcion ?? "").trim() || "SIN DESCRIPCION",
      Quantity: quantity,
      UnitPrice: unitPrice,
      TaxRatePercent: iva,
      Subtotal: subtotal,
    }
  );

  await adjustStock(ingredientProductId, quantity);
  await recalcPurchaseTotals(data.compraId);

  return {
    ok: true,
    id: Number(inserted[0]?.id ?? 0),
    compraId: data.compraId,
  };
}

export async function deleteCompraDetalle(compraId: number, detalleId: number) {
  const pool = await getPool();
  const request = pool.request();
  request.input("CompraId", compraId);
  request.input("DetalleId", detalleId);
  const result = await request.execute("usp_Rest_Admin_CompraLinea_Delete");

  const prev = (result.recordset ?? []) as Array<{ ingredientProductId: number | null; quantity: number }>;

  const prevProductId = prev[0]?.ingredientProductId == null ? null : Number(prev[0].ingredientProductId);
  const prevQty = Number(prev[0]?.quantity ?? 0);
  await adjustStock(prevProductId, -prevQty);
  await recalcPurchaseTotals(compraId);

  return { ok: true, compraId, detalleId };
}

export async function crearCompra(data: {
  proveedorId?: string;
  observaciones?: string;
  codUsuario?: string;
  detalle: Array<{ descripcion: string; cantidad: number; precioUnit: number; iva?: number; inventarioId?: string }>;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(data.codUsuario);
  const supplierId = await resolveSupplierId(data.proveedorId);

  const seqRows = await callSp<{ seq: number }>(
    "usp_Rest_Admin_Compra_GetNextSeq",
    { CompanyId: scope.companyId, BranchId: scope.branchId }
  );

  const now = new Date();
  const yyyymm = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}`;
  const purchaseNumber = `RC-${yyyymm}-${String(Number(seqRows[0]?.seq ?? 1)).padStart(4, "0")}`;

  const inserted = await callSp<{ id: number }>(
    "usp_Rest_Admin_Compra_Insert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PurchaseNumber: purchaseNumber,
      SupplierId: supplierId,
      Notes: data.observaciones ?? null,
      UserId: userId,
    }
  );

  const compraId = Number(inserted[0]?.id ?? 0);

  for (const item of data.detalle ?? []) {
    await upsertCompraDetalle({
      compraId,
      inventarioId: item.inventarioId,
      descripcion: item.descripcion,
      cantidad: item.cantidad,
      precioUnit: item.precioUnit,
      iva: item.iva,
    });
  }

  await recalcPurchaseTotals(compraId);
  return { ok: true, compraId };
}

export async function updateCompra(
  compraId: number,
  data: { proveedorId?: string; estado?: string; observaciones?: string }
) {
  const supplierId = await resolveSupplierId(data.proveedorId);

  await callSp(
    "usp_Rest_Admin_Compra_Update",
    {
      CompraId: compraId,
      SupplierId: supplierId,
      Status: data.estado ? String(data.estado).trim().toUpperCase() : null,
      Notes: data.observaciones ?? null,
    }
  );

  return { ok: true, compraId };
}

export async function searchProveedores(search?: string, limit = 20) {
  const scope = await getDefaultScope();
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(100, Number(limit))) : 20;

  const rows = await callSp<any>(
    "usp_Rest_Admin_Proveedor_Search",
    {
      CompanyId: scope.companyId,
      Search: search?.trim() ? `%${search.trim()}%` : null,
      Limit: safeLimit,
    }
  );

  return { rows };
}

export async function searchInsumosRestaurante(search?: string, limit = 30) {
  const scope = await getDefaultScope();
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(100, Number(limit))) : 30;

  const rows = await callSp<any>(
    "usp_Rest_Admin_Insumo_Search",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Search: search?.trim() ? `%${search.trim()}%` : null,
      Limit: safeLimit,
    }
  );

  return { rows };
}
