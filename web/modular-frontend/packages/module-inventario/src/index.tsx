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

// ── Hooks Avanzados (Seriales, Lotes, WMS) ──────────────────
export {
  useLotesList,
  useCreateLote,
  useSerialsList,
  useSerialByNumber,
  useCreateSerial,
  useUpdateSerialStatus,
  useWarehousesList,
  useWarehouseZones,
  useWarehouseBins,
  useCreateWarehouse,
  useBinStock,
} from "./hooks/useInventarioAvanzado";

export type {
  LotFilter,
  SerialFilter,
} from "./hooks/useInventarioAvanzado";

// ── Components Avanzados ─────────────────────────────────────
export { default as LotesPage } from "./components/LotesPage";
export { default as SerialesPage } from "./components/SerialesPage";
export { default as AlmacenesWMSPage } from "./components/AlmacenesWMSPage";

// ── Conteo físico / Albaranes / Traslados MP / Kardex ────────
export {
  useConteoList, useCrearConteo, useUpsertLineaConteo, useCerrarConteo,
  useAlbaranesList, useCrearAlbaran, useAddLineaAlbaran, useEmitirAlbaran, useFirmarAlbaran,
  useTrasladosMPList, useCrearTrasladoMP, useAvanzarTrasladoMP,
  useKardex,
} from "./hooks/useConteoAlbaranes";

export type { HojaConteoRow, AlbaranRow, TrasladoMPRow, KardexRow } from "./hooks/useConteoAlbaranes";

export { default as ConteoFisicoPage }       from "./components/ConteoFisicoPage";
export { default as AlbaranesPage }          from "./components/AlbaranesPage";
export { default as TrasladosMultiPasoPage } from "./components/TrasladosMultiPasoPage";
export { default as KardexPage }             from "./components/KardexPage";
