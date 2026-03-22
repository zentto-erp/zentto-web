"use client";

export const MODULE_ID = "manufactura";
export const MODULE_TITLE = "Manufactura";

// ── Hooks ────────────────────────────────────────────────────
export {
  useBOMList,
  useBOMDetail,
  useCreateBOM,
  useActivateBOM,
  useObsoleteBOM,
  useWorkCentersList,
  useUpsertWorkCenter,
  useWorkOrdersList,
  useWorkOrderDetail,
  useCreateWorkOrder,
  useStartWorkOrder,
  useCompleteWorkOrder,
  useCancelWorkOrder,
  useManufacturaDashboard,
} from "./hooks/useManufactura";

export type {
  BOMFilter,
  BOMListResponse,
  WorkCenterFilter,
  WorkCenterListResponse,
  WorkOrderFilter,
  WorkOrderListResponse,
  ManufacturaDashboard,
} from "./hooks/useManufactura";

// ── Components ───────────────────────────────────────────────
export { default as BOMPage } from "./components/BOMPage";
export { default as CentrosTrabajoPage } from "./components/CentrosTrabajoPage";
export { default as OrdenesProduccionPage } from "./components/OrdenesProduccionPage";

// ── Pages ────────────────────────────────────────────────────
export { default as ManufacturaHome } from "./pages/ManufacturaHome";
