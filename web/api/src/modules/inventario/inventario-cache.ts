import { query } from "../../db/query.js";

export interface CachedArticulo {
  CODIGO: string;
  Referencia: string;
  Categoria: string;
  Marca: string;
  Tipo: string;
  Unidad: string;
  Clase: string;
  DESCRIPCION: string;
  Linea: string;
  EXISTENCIA: number;
  MINIMO: number;
  MAXIMO: number;
  PRECIO_COMPRA: number;
  PRECIO_VENTA: number;
  PORCENTAJE: number;
  PRECIO_VENTA1: number;
  PRECIO_VENTA2: number;
  PRECIO_VENTA3: number;
  Alicuota: number;
  PLU: number;
  Barra: string;
  N_PARTE: string;
  UBICACION: string;
  UbicaFisica: string;
  Garantia: string;
  FECHA: string | null;
  FechaVence: string | null;
  Servicio: boolean;
  Eliminado: boolean;
  COSTO_PROMEDIO: number;
  Id: number;
  ImagenUrl: string;
  imagen: string;
  DescripcionCompleta: string;
  _searchable: string;
}

export interface ArticuloCacheFilter {
  search?: string;
  categoria?: string;
  marca?: string;
  linea?: string;
  tipo?: string;
  clase?: string;
  unidad?: string;
  ubicacion?: string;
  estado?: string;
  precioMin?: number;
  precioMax?: number;
  stockMin?: number;
  stockMax?: number;
  servicio?: boolean;
  wildcard?: string;
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface ArticuloCacheResult {
  page: number;
  limit: number;
  total: number;
  rows: CachedArticulo[];
  fromCache: boolean;
}

interface FilterOptionsResult {
  lineas: string[];
  categorias: string[];
  marcas: string[];
  tipos: string[];
  clases: string[];
  unidades: string[];
  ubicaciones: string[];
  garantias: string[];
  precioMin: number;
  precioMax: number;
}

const REFRESH_INTERVAL_MS = 5 * 60_000;
const LOG_PREFIX = "[inventario-cache-canonical]";

let _cache: CachedArticulo[] = [];
let _indexByCodigo: Map<string, CachedArticulo> = new Map();
let _filterOptions: FilterOptionsResult | null = null;
let _loadedAt = 0;
let _ready = false;
let _refreshTimer: ReturnType<typeof setInterval> | null = null;

async function getDefaultCompanyId() {
  const rows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  return companyId;
}

function rowToCache(r: Record<string, any>): CachedArticulo {
  const descripcion = String(r.ProductName ?? "").trim();
  const categoria = String(r.CategoryCode ?? "").trim();
  const unidad = String(r.UnitCode ?? "").trim();
  const codigo = String(r.ProductCode ?? "").trim();
  const searchable = `${codigo} ${descripcion} ${categoria} ${unidad}`.toLowerCase();

  return {
    CODIGO: codigo,
    Referencia: "",
    Categoria: categoria,
    Marca: "",
    Tipo: r.IsService ? "SERVICIO" : "PRODUCTO",
    Unidad: unidad,
    Clase: "",
    DESCRIPCION: descripcion,
    Linea: "",
    EXISTENCIA: Number(r.StockQty ?? 0),
    MINIMO: 0,
    MAXIMO: 0,
    PRECIO_COMPRA: Number(r.CostPrice ?? 0),
    PRECIO_VENTA: Number(r.SalesPrice ?? 0),
    PORCENTAJE: 0,
    PRECIO_VENTA1: Number(r.SalesPrice ?? 0),
    PRECIO_VENTA2: 0,
    PRECIO_VENTA3: 0,
    Alicuota: Number(r.DefaultTaxRate ?? 0),
    PLU: 0,
    Barra: "",
    N_PARTE: "",
    UBICACION: "",
    UbicaFisica: "",
    Garantia: "",
    FECHA: r.UpdatedAt ? new Date(r.UpdatedAt).toISOString() : null,
    FechaVence: null,
    Servicio: Boolean(r.IsService),
    Eliminado: Boolean(r.IsDeleted),
    COSTO_PROMEDIO: Number(r.CostPrice ?? 0),
    Id: Number(r.ProductId ?? 0),
    ImagenUrl: "",
    imagen: "",
    DescripcionCompleta: `${categoria} ${descripcion}`.trim(),
    _searchable: searchable
  };
}

async function loadAllFromDB(): Promise<CachedArticulo[]> {
  const companyId = await getDefaultCompanyId();
  const rows = await query<Record<string, any>>(
    `SELECT
        ProductId,
        ProductCode,
        ProductName,
        CategoryCode,
        UnitCode,
        SalesPrice,
        CostPrice,
        DefaultTaxRate,
        StockQty,
        IsService,
        IsDeleted,
        UpdatedAt
       FROM [master].Product
      WHERE CompanyId = @companyId
      ORDER BY ProductCode`,
    { companyId }
  );

  return rows.map(rowToCache);
}

function rebuildIndexes(data: CachedArticulo[]) {
  _cache = data;
  _indexByCodigo = new Map(data.map((item) => [item.CODIGO, item]));
  _filterOptions = null;
  _loadedAt = Date.now();
  _ready = true;
}

function computeFilterOptions(): FilterOptionsResult {
  const categorias = new Set<string>();
  const tipos = new Set<string>();
  const unidades = new Set<string>();
  let precioMin = Infinity;
  let precioMax = 0;

  for (const item of _cache) {
    if (item.Categoria) categorias.add(item.Categoria);
    if (item.Tipo) tipos.add(item.Tipo);
    if (item.Unidad) unidades.add(item.Unidad);
    if (item.PRECIO_VENTA > 0) {
      if (item.PRECIO_VENTA < precioMin) precioMin = item.PRECIO_VENTA;
      if (item.PRECIO_VENTA > precioMax) precioMax = item.PRECIO_VENTA;
    }
  }

  return {
    lineas: [],
    categorias: [...categorias].sort((a, b) => a.localeCompare(b, "es")),
    marcas: [],
    tipos: [...tipos].sort((a, b) => a.localeCompare(b, "es")),
    clases: [],
    unidades: [...unidades].sort((a, b) => a.localeCompare(b, "es")),
    ubicaciones: [],
    garantias: [],
    precioMin: precioMin === Infinity ? 0 : precioMin,
    precioMax
  };
}

function startAutoRefresh() {
  if (_refreshTimer) return;

  _refreshTimer = setInterval(async () => {
    try {
      await warmUp();
    } catch {
      // keep interval alive
    }
  }, REFRESH_INTERVAL_MS);

  if (_refreshTimer && typeof _refreshTimer === "object" && "unref" in _refreshTimer) {
    (_refreshTimer as NodeJS.Timeout).unref();
  }
}

async function ensureReady() {
  if (_ready && _cache.length > 0) return;
  await warmUp();
}

export async function warmUp(): Promise<number> {
  const start = Date.now();
  const rows = await loadAllFromDB();
  rebuildIndexes(rows);
  startAutoRefresh();
  const elapsed = Date.now() - start;
  console.log(`${LOG_PREFIX} Cargados ${rows.length} productos canónicos en ${elapsed}ms`);
  return rows.length;
}

export async function search(filter: ArticuloCacheFilter): Promise<ArticuloCacheResult> {
  await ensureReady();

  const page = Math.max(filter.page ?? 1, 1);
  const limit = Math.min(Math.max(filter.limit ?? 50, 1), 500);
  const sortBy = filter.sortBy ?? "CODIGO";
  const sortOrder = filter.sortOrder ?? "asc";

  let results = _cache;

  if (filter.estado === "activo") results = results.filter((item) => !item.Eliminado);
  if (filter.estado === "inactivo") results = results.filter((item) => item.Eliminado);

  if (filter.servicio !== undefined) results = results.filter((item) => item.Servicio === filter.servicio);
  if (filter.categoria) results = results.filter((item) => item.Categoria.toUpperCase() === filter.categoria!.toUpperCase());
  if (filter.tipo) results = results.filter((item) => item.Tipo.toUpperCase() === filter.tipo!.toUpperCase());
  if (filter.unidad) results = results.filter((item) => item.Unidad.toUpperCase() === filter.unidad!.toUpperCase());

  if (filter.precioMin !== undefined) results = results.filter((item) => item.PRECIO_VENTA >= filter.precioMin!);
  if (filter.precioMax !== undefined) results = results.filter((item) => item.PRECIO_VENTA <= filter.precioMax!);
  if (filter.stockMin !== undefined) results = results.filter((item) => item.EXISTENCIA >= filter.stockMin!);
  if (filter.stockMax !== undefined) results = results.filter((item) => item.EXISTENCIA <= filter.stockMax!);

  if (filter.wildcard && filter.wildcard.trim()) {
    const pattern = filter.wildcard
      .toLowerCase()
      .replace(/[.+^${}()|[\]\\]/g, "\\$&")
      .replace(/\*/g, ".*")
      .replace(/\?/g, ".");

    try {
      const re = new RegExp(pattern);
      results = results.filter((item) => re.test(item._searchable));
    } catch {
      // invalid wildcard pattern
    }
  }

  if (filter.search && filter.search.trim()) {
    const terms = filter.search.toLowerCase().split(/\s+/).filter(Boolean);
    results = results.filter((item) => terms.every((term) => item._searchable.includes(term)));
  }

  const key = sortBy as keyof CachedArticulo;
  results = [...results].sort((a, b) => {
    const va = a[key];
    const vb = b[key];

    if (typeof va === "number" && typeof vb === "number") {
      return sortOrder === "asc" ? va - vb : vb - va;
    }

    const sa = String(va ?? "").toUpperCase();
    const sb = String(vb ?? "").toUpperCase();
    const cmp = sa < sb ? -1 : sa > sb ? 1 : 0;
    return sortOrder === "asc" ? cmp : -cmp;
  });

  const total = results.length;
  const offset = (page - 1) * limit;
  const rows = results.slice(offset, offset + limit);

  return { page, limit, total, rows, fromCache: true };
}

export async function getByCode(codigo: string): Promise<CachedArticulo | null> {
  await ensureReady();
  const normalized = codigo.trim();
  const found = _indexByCodigo.get(normalized);
  if (found) return found;

  const companyId = await getDefaultCompanyId();
  const rows = await query<Record<string, any>>(
    `SELECT TOP 1
        ProductId,
        ProductCode,
        ProductName,
        CategoryCode,
        UnitCode,
        SalesPrice,
        CostPrice,
        DefaultTaxRate,
        StockQty,
        IsService,
        IsDeleted,
        UpdatedAt
       FROM [master].Product
      WHERE CompanyId = @companyId
        AND ProductCode = @codigo`,
    { companyId, codigo: normalized }
  );

  return rows[0] ? rowToCache(rows[0]) : null;
}

export async function invalidate() {
  _cache = [];
  _indexByCodigo = new Map();
  _filterOptions = null;
  _loadedAt = 0;
  _ready = false;
}

export async function invalidateAndReload() {
  await invalidate();
  await warmUp();
}

export async function getFilterOptions(): Promise<FilterOptionsResult> {
  await ensureReady();
  if (!_filterOptions) _filterOptions = computeFilterOptions();
  return _filterOptions;
}

export function getCacheStats() {
  return {
    ready: _ready,
    count: _cache.length,
    loadedAt: _loadedAt ? new Date(_loadedAt).toISOString() : null,
    ageSec: _loadedAt ? Math.round((Date.now() - _loadedAt) / 1000) : null,
    refreshIntervalSec: REFRESH_INTERVAL_MS / 1000,
    hasRedis: false,
    source: "master.Product"
  };
}
