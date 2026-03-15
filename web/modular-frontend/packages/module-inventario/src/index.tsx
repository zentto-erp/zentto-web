"use client";

// ── Hooks ────────────────────────────────────────────────────
export {
  useInventarioList,
  useInventarioById,
  useInventarioDashboard,
  useMovimientosList,
  useLibroInventario,
  useCreateMovimiento,
  useCreateTraslado,
  useUpdateInventario,
  useDeleteInventario,
} from "./hooks/useInventario";

export type {
  InventarioListFilter,
  InventarioListResponse,
  DashboardData,
  MovimientosFilter,
  MovimientosResponse,
  LibroFilter,
} from "./hooks/useInventario";

export {
  useArticulosList,
  useArticuloById,
  useCreateArticulo,
  useUpdateArticulo,
  useDeleteArticulo,
  useArticuloFilterOptions,
} from "./hooks/useArticulos";

// ── Types ────────────────────────────────────────────────────
export type {
  CatalogField,
  CatalogRow,
  CatalogResponse,
  CatalogMetadataColumn,
  CatalogTableMetadata,
  CatalogoCrudApiClient,
} from "./components/CatalogoCrudBase";

// ── Components ───────────────────────────────────────────────
export { default as InventarioTable } from "./components/InventarioTable";
export { default as AjusteInventarioForm } from "./components/AjusteInventarioForm";
export { default as MovimientosTable } from "./components/MovimientosTable";
export { default as TrasladoForm } from "./components/TrasladoForm";
export { default as LibroInventarioPage } from "./components/LibroInventarioPage";
export { default as EtiquetasPage } from "./components/EtiquetasPage";
export { default as CatalogoCrudBase } from "./components/CatalogoCrudBase";
export { default as CatalogoCrudPage } from "./components/CatalogoCrudPage";

// ── Pages ────────────────────────────────────────────────────
export { default as InventarioHome } from "./pages/InventarioHome";
