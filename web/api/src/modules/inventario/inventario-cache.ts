/**
 * inventario-cache.ts
 * Cache de alto rendimiento para la tabla Inventario (~64k registros).
 *
 * Estrategia:
 *  - warmUp() carga TODO el catalogo y lo guarda en memoria + Redis.
 *  - Un intervalo automatico recarga cada REFRESH_INTERVAL_MS (5 min).
 *  - Las busquedas se resuelven contra la memoria local (NO parsea Redis cada vez).
 *  - Redis solo se usa como respaldo para reinicio rapido del servidor.
 *  - Las mutaciones invalidan y recargan inmediatamente.
 *
 * Rendimiento esperado: <10ms por busqueda paginada sobre 64k registros.
 */

import { query } from "../../db/query.js";
import { getRedis } from "../../db/redis.js";

// ===================== Tipos =====================

/** Articulo cacheado - campos para listado, busqueda y filtros avanzados */
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
  FECHA: string | null;        // Fecha ultima compra (ISO string)
  FechaVence: string | null;   // Fecha vencimiento (ISO string)
  Servicio: boolean;
  Eliminado: boolean;
  COSTO_PROMEDIO: number;
  Id: number;
  /** Campo calculado: Categoria + Tipo + Descripcion + Marca + Clase */
  DescripcionCompleta: string;
  /** Campo pre-calculado para busqueda rapida (minusculas, un solo string) */
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
  /** Filtro por estado: 'activo' | 'inactivo' | 'todos' (default: todos) */
  estado?: string;
  /** Rango de precio venta: min */
  precioMin?: number;
  /** Rango de precio venta: max */
  precioMax?: number;
  /** Rango de existencia: min */
  stockMin?: number;
  /** Rango de existencia: max */
  stockMax?: number;
  /** Filtrar solo servicios */
  servicio?: boolean;
  /** Busqueda con comodines (* y ?) */
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

// ===================== Constantes =====================

const REDIS_KEY = "datqbox:inventario:all";
const REDIS_TTL_SECONDS = 600;           // TTL en Redis: 10 min
const REFRESH_INTERVAL_MS = 5 * 60_000;  // Auto-refresh: 5 min
const LOG_PREFIX = "[inventario-cache]";

// ===================== Estado en memoria =====================

/** Array principal ordenado por CODIGO (viene de SQL con ORDER BY) */
let _cache: CachedArticulo[] = [];

/** Indice por codigo para busquedas O(1) */
let _indexByCodigo: Map<string, CachedArticulo> = new Map();

/** Opciones de filtro pre-calculadas */
let _filterOptions: FilterOptionsResult | null = null;

/** Timestamp de la ultima carga exitosa */
let _loadedAt = 0;

/** Indica si el cache tiene datos */
let _ready = false;

/** Handle del intervalo de auto-refresh */
let _refreshTimer: ReturnType<typeof setInterval> | null = null;

// ===================== Helpers =====================

/** Construye la descripcion completa concatenando los campos descriptivos */
function buildDescripcionCompleta(r: Record<string, any>): string {
  return [r.Categoria, r.Tipo, r.DESCRIPCION, r.Marca, r.Clase]
    .map((s: string | null | undefined) => (s ?? "").trim())
    .filter(Boolean)
    .join(" ");
}

/** Convierte un Date/string SQL a ISO string o null */
function toISOorNull(val: any): string | null {
  if (!val) return null;
  try {
    const d = new Date(val);
    return isNaN(d.getTime()) ? null : d.toISOString();
  } catch { return null; }
}

/** Proyecta una fila SQL cruda al tipo CachedArticulo */
function rowToCache(r: Record<string, any>): CachedArticulo {
  const item: CachedArticulo = {
    CODIGO: (r.CODIGO ?? "").trim(),
    Referencia: (r.Referencia ?? "").trim(),
    Categoria: (r.Categoria ?? "").trim(),
    Marca: (r.Marca ?? "").trim(),
    Tipo: (r.Tipo ?? "").trim(),
    Unidad: (r.Unidad ?? "").trim(),
    Clase: (r.Clase ?? "").trim(),
    DESCRIPCION: (r.DESCRIPCION ?? "").trim(),
    Linea: (r.Linea ?? "").trim(),
    EXISTENCIA: parseFloat(r.EXISTENCIA) || 0,
    MINIMO: parseInt(r.MINIMO) || 0,
    MAXIMO: parseInt(r.MAXIMO) || 0,
    PRECIO_COMPRA: parseFloat(r.PRECIO_COMPRA) || 0,
    PRECIO_VENTA: parseFloat(r.PRECIO_VENTA) || 0,
    PORCENTAJE: parseFloat(r.PORCENTAJE) || 0,
    PRECIO_VENTA1: parseFloat(r.PRECIO_VENTA1) || 0,
    PRECIO_VENTA2: parseFloat(r.PRECIO_VENTA2) || 0,
    PRECIO_VENTA3: parseFloat(r.PRECIO_VENTA3) || 0,
    Alicuota: parseFloat(r.Alicuota) || 0,
    PLU: parseInt(r.PLU) || 0,
    Barra: (r.Barra ?? "").trim(),
    N_PARTE: (r.N_PARTE ?? "").trim(),
    UBICACION: (r.UBICACION ?? "").trim(),
    UbicaFisica: (r.UbicaFisica ?? "").trim(),
    Garantia: (r.Garantia ?? "").trim(),
    FECHA: toISOorNull(r.FECHA),
    FechaVence: toISOorNull(r.FechaVence),
    Servicio: Boolean(r.Servicio),
    Eliminado: Boolean(r.Eliminado),
    COSTO_PROMEDIO: parseFloat(r.COSTO_PROMEDIO) || 0,
    Id: parseInt(r.Id) || 0,
    DescripcionCompleta: r.DescripcionCompleta ?? buildDescripcionCompleta(r),
    _searchable: "",
  };
  // Pre-calcular string de busqueda (una sola vez, no en cada request)
  item._searchable = [
    item.CODIGO, item.Referencia, item.DescripcionCompleta,
    item.Categoria, item.Tipo, item.Marca, item.Clase,
    item.Linea, item.Barra, item.N_PARTE,
    item.UBICACION, item.UbicaFisica, item.Garantia,
  ].join(" ").toLowerCase();
  return item;
}

// ===================== Carga desde BD =====================

async function loadAllFromDB(): Promise<CachedArticulo[]> {
  const descExpr = `LTRIM(RTRIM(
    ISNULL(RTRIM(Categoria), '') +
    CASE WHEN RTRIM(ISNULL(Tipo, '')) <> '' THEN ' ' + RTRIM(Tipo) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(DESCRIPCION) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(Marca, '')) <> '' THEN ' ' + RTRIM(Marca) ELSE '' END +
    CASE WHEN RTRIM(ISNULL(Clase, '')) <> '' THEN ' ' + RTRIM(Clase) ELSE '' END
  )) AS DescripcionCompleta`;

  const selectCols = `
    CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION,
    Linea, EXISTENCIA, MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA, PORCENTAJE,
    PRECIO_VENTA1, PRECIO_VENTA2, PRECIO_VENTA3,
    Alicuota, PLU, Barra, N_PARTE, UBICACION, UbicaFisica, Garantia,
    FECHA, FechaVence, Servicio, Eliminado, COSTO_PROMEDIO, Id,
    ${descExpr}
  `;

  const rows = await query<Record<string, any>>(
    `SELECT ${selectCols} FROM Inventario ORDER BY CODIGO`
  );

  return rows.map(rowToCache);
}

// ===================== Redis helpers =====================

let _redis: any = null;
let _redisChecked = false;

async function redis(): Promise<any | null> {
  if (_redisChecked) return _redis;
  _redisChecked = true;
  try {
    _redis = await getRedis();
    if (_redis) {
      console.log(`${LOG_PREFIX} Redis conectado`);
    } else {
      console.log(`${LOG_PREFIX} Redis no disponible, usando solo memoria`);
    }
  } catch {
    console.log(`${LOG_PREFIX} Redis no disponible, usando solo memoria`);
  }
  return _redis;
}

// ===================== Funciones internas =====================

/** Actualiza los indices internos despues de cargar datos */
function rebuildIndexes(data: CachedArticulo[]): void {
  _cache = data;
  _indexByCodigo = new Map(data.map((item) => [item.CODIGO, item]));
  _filterOptions = null; // se recalcula lazy
  _loadedAt = Date.now();
  _ready = true;
}

/** Calcula las opciones de filtro (lazy, se cachea hasta siguiente warmUp) */
function computeFilterOptions(): FilterOptionsResult {
  const lineas = new Set<string>();
  const categorias = new Set<string>();
  const marcas = new Set<string>();
  const tipos = new Set<string>();
  const clases = new Set<string>();
  const unidades = new Set<string>();
  const ubicaciones = new Set<string>();
  const garantias = new Set<string>();
  let precioMin = Infinity, precioMax = 0;

  for (const item of _cache) {
    if (item.Linea) lineas.add(item.Linea);
    if (item.Categoria) categorias.add(item.Categoria);
    if (item.Marca) marcas.add(item.Marca);
    if (item.Tipo) tipos.add(item.Tipo);
    if (item.Clase) clases.add(item.Clase);
    if (item.Unidad) unidades.add(item.Unidad);
    if (item.UBICACION) ubicaciones.add(item.UBICACION);
    if (item.UbicaFisica && !ubicaciones.has(item.UbicaFisica)) ubicaciones.add(item.UbicaFisica);
    if (item.Garantia) garantias.add(item.Garantia);
    if (item.PRECIO_VENTA > 0) {
      if (item.PRECIO_VENTA < precioMin) precioMin = item.PRECIO_VENTA;
      if (item.PRECIO_VENTA > precioMax) precioMax = item.PRECIO_VENTA;
    }
  }

  const sortES = (a: string, b: string) => a.localeCompare(b, "es");

  return {
    lineas: [...lineas].sort(sortES),
    categorias: [...categorias].sort(sortES),
    marcas: [...marcas].sort(sortES),
    tipos: [...tipos].sort(sortES),
    clases: [...clases].sort(sortES),
    unidades: [...unidades].sort(sortES),
    ubicaciones: [...ubicaciones].sort(sortES),
    garantias: [...garantias].sort(sortES),
    precioMin: precioMin === Infinity ? 0 : precioMin,
    precioMax,
  };
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

// ===================== API publica =====================

/**
 * Precalienta el cache cargando todos los articulos de la BD.
 * Se llama al iniciar el servidor y automaticamente cada 5 min.
 */
export async function warmUp(): Promise<number> {
  const start = Date.now();
  const rows = await loadAllFromDB();
  const elapsed = Date.now() - start;
  console.log(`${LOG_PREFIX} Cargados ${rows.length} articulos de BD en ${elapsed}ms`);

  // Actualizar memoria local (fuente principal de verdad para busquedas)
  rebuildIndexes(rows);

  // Guardar en Redis como backup para reinicio rapido
  const r = await redis();
  if (r) {
    try {
      // Excluir _searchable del JSON de Redis para ahorrar espacio
      const redisData = rows.map(({ _searchable, ...rest }) => rest);
      await r.set(REDIS_KEY, JSON.stringify(redisData), "EX", REDIS_TTL_SECONDS);
      console.log(`${LOG_PREFIX} Cache guardado en Redis (TTL ${REDIS_TTL_SECONDS}s)`);
    } catch (err) {
      console.error(`${LOG_PREFIX} Error guardando en Redis:`, err);
    }
  }

  // Iniciar auto-refresh si no esta activo
  startAutoRefresh();

  return rows.length;
}

/**
 * Inicia el intervalo de auto-refresh (cada 5 min).
 * Si ya esta corriendo, no crea uno nuevo.
 */
function startAutoRefresh(): void {
  if (_refreshTimer) return;
  _refreshTimer = setInterval(async () => {
    try {
      console.log(`${LOG_PREFIX} Auto-refresh iniciado...`);
      await warmUp();
    } catch (err) {
      console.error(`${LOG_PREFIX} Error en auto-refresh:`, err);
    }
  }, REFRESH_INTERVAL_MS);
  // No bloquear el cierre del proceso
  if (_refreshTimer && typeof _refreshTimer === "object" && "unref" in _refreshTimer) {
    (_refreshTimer as NodeJS.Timeout).unref();
  }
  console.log(`${LOG_PREFIX} Auto-refresh programado cada ${REFRESH_INTERVAL_MS / 1000}s`);
}

/**
 * Asegura que el cache este listo. Si no hay datos, intenta cargar
 * desde Redis (rapido) o desde BD.
 */
async function ensureReady(): Promise<void> {
  if (_ready && _cache.length > 0) return;

  // Intentar carga rapida desde Redis
  const r = await redis();
  if (r) {
    try {
      const cached = await r.get(REDIS_KEY);
      if (cached) {
        const parsed = JSON.parse(cached) as Record<string, any>[];
        const rows = parsed.map(rowToCache);
        rebuildIndexes(rows);
        console.log(`${LOG_PREFIX} Cargados ${rows.length} articulos desde Redis`);
        startAutoRefresh();
        return;
      }
    } catch { /* continuar a BD */ }
  }

  // Cargar desde BD
  await warmUp();
}

/**
 * Busca articulos en el cache con filtros, paginacion y orden.
 * Rendimiento optimizado: <10ms para 64k registros.
 */
export async function search(filter: ArticuloCacheFilter): Promise<ArticuloCacheResult> {
  await ensureReady();

  const page = Math.max(filter.page ?? 1, 1);
  const limit = Math.min(Math.max(filter.limit ?? 50, 1), 500);
  const sortBy = filter.sortBy ?? "CODIGO";
  const sortOrder = filter.sortOrder ?? "asc";

  let results: CachedArticulo[] = _cache;
  let needsSort = false;

  // --- Filtro por estado (activo/inactivo) ---
  if (filter.estado === "activo") {
    results = results.filter((item) => !item.Eliminado);
    needsSort = true;
  } else if (filter.estado === "inactivo") {
    results = results.filter((item) => item.Eliminado);
    needsSort = true;
  }

  // --- Filtro servicios ---
  if (filter.servicio !== undefined) {
    results = results.filter((item) => item.Servicio === filter.servicio);
    needsSort = true;
  }

  // --- Filtros exactos (selectores) ---
  if (filter.linea) {
    const v = filter.linea.toUpperCase();
    results = results.filter((item) => item.Linea.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.categoria) {
    const v = filter.categoria.toUpperCase();
    results = results.filter((item) => item.Categoria.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.marca) {
    const v = filter.marca.toUpperCase();
    results = results.filter((item) => item.Marca.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.tipo) {
    const v = filter.tipo.toUpperCase();
    results = results.filter((item) => item.Tipo.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.clase) {
    const v = filter.clase.toUpperCase();
    results = results.filter((item) => item.Clase.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.unidad) {
    const v = filter.unidad.toUpperCase();
    results = results.filter((item) => item.Unidad.toUpperCase() === v);
    needsSort = true;
  }
  if (filter.ubicacion) {
    const v = filter.ubicacion.toUpperCase();
    results = results.filter((item) =>
      item.UBICACION.toUpperCase() === v || item.UbicaFisica.toUpperCase() === v
    );
    needsSort = true;
  }

  // --- Rango de precios ---
  if (filter.precioMin !== undefined && filter.precioMin > 0) {
    results = results.filter((item) => item.PRECIO_VENTA >= filter.precioMin!);
    needsSort = true;
  }
  if (filter.precioMax !== undefined && filter.precioMax > 0) {
    results = results.filter((item) => item.PRECIO_VENTA <= filter.precioMax!);
    needsSort = true;
  }

  // --- Rango de existencia ---
  if (filter.stockMin !== undefined) {
    results = results.filter((item) => item.EXISTENCIA >= filter.stockMin!);
    needsSort = true;
  }
  if (filter.stockMax !== undefined) {
    results = results.filter((item) => item.EXISTENCIA <= filter.stockMax!);
    needsSort = true;
  }

  // --- Busqueda con comodines (wildcard: * = cualquiera, ? = un caracter) ---
  if (filter.wildcard && filter.wildcard.trim()) {
    const pattern = filter.wildcard
      .toLowerCase()
      .replace(/[.+^${}()|[\]\\]/g, "\\$&")  // escapar regex excepto * y ?
      .replace(/\*/g, ".*")
      .replace(/\?/g, ".");
    try {
      const re = new RegExp(pattern);
      results = results.filter((item) => re.test(item._searchable));
      needsSort = true;
    } catch { /* patron invalido, ignorar */ }
  }

  // --- Busqueda de texto libre (usa _searchable pre-calculado) ---
  if (filter.search && filter.search.trim()) {
    const terms = filter.search.toLowerCase().split(/\s+/).filter(Boolean);
    results = results.filter((item) =>
      terms.every((term) => item._searchable.includes(term))
    );
    needsSort = true;
  }

  const total = results.length;

  // --- Ordenar solo si es necesario ---
  // Si no hay filtros y el sort es CODIGO asc (default), el array ya viene ordenado
  const isDefaultSort = sortBy === "CODIGO" && sortOrder === "asc";
  if (!isDefaultSort || needsSort) {
    const key = sortBy as keyof CachedArticulo;
    // Comparacion rapida sin localeCompare (evita el costo de 2.5s en 64k items)
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
  }

  // --- Paginar ---
  const offset = (page - 1) * limit;
  const rows = results.slice(offset, offset + limit);

  return { page, limit, total, rows, fromCache: true };
}

/**
 * Obtiene un articulo por codigo desde el cache (O(1) con Map).
 */
export async function getByCode(codigo: string): Promise<CachedArticulo | null> {
  await ensureReady();

  const found = _indexByCodigo.get(codigo) ?? null;
  if (found) return found;

  // Fallback: buscar en BD directamente
  const rows = await query<Record<string, any>>(
    `SELECT *, LTRIM(RTRIM(
      ISNULL(RTRIM(Categoria), '') +
      CASE WHEN RTRIM(ISNULL(Tipo, '')) <> '' THEN ' ' + RTRIM(Tipo) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(DESCRIPCION) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(Marca, '')) <> '' THEN ' ' + RTRIM(Marca) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(Clase, '')) <> '' THEN ' ' + RTRIM(Clase) ELSE '' END
    )) AS DescripcionCompleta FROM Inventario WHERE CODIGO = @codigo`,
    { codigo }
  );
  return rows[0] ? rowToCache(rows[0]) : null;
}

/**
 * Invalida el cache completo.
 */
export async function invalidate(): Promise<void> {
  console.log(`${LOG_PREFIX} Invalidando cache`);

  const r = await redis();
  if (r) {
    try { await r.del(REDIS_KEY); } catch { /* ignorar */ }
  }

  _cache = [];
  _indexByCodigo = new Map();
  _filterOptions = null;
  _ready = false;
  _loadedAt = 0;
}

/**
 * Invalida y recarga inmediatamente.
 */
export async function invalidateAndReload(): Promise<void> {
  await invalidate();
  await warmUp();
}

/**
 * Obtiene las listas unicas de valores para filtros (combos del frontend).
 * Se calcula una vez y se cachea hasta el siguiente warmUp.
 */
export async function getFilterOptions(): Promise<FilterOptionsResult> {
  await ensureReady();
  if (!_filterOptions) {
    _filterOptions = computeFilterOptions();
  }
  return _filterOptions;
}

/**
 * Devuelve info de diagnostico del cache.
 */
export function getCacheStats() {
  return {
    ready: _ready,
    count: _cache.length,
    loadedAt: _loadedAt ? new Date(_loadedAt).toISOString() : null,
    ageSec: _loadedAt ? Math.round((Date.now() - _loadedAt) / 1000) : null,
    refreshIntervalSec: REFRESH_INTERVAL_MS / 1000,
    hasRedis: !!_redis,
  };
}
