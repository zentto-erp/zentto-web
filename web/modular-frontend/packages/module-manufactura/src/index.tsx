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
  useConsumeMaterial,
  useReportOutput,
  useManufacturaDashboard,
  useRoutingList,
  useUpsertRouting,
} from "./hooks/useManufactura";

export type {
  BOMFilter,
  BOMListResponse,
  WorkCenterFilter,
  WorkCenterListResponse,
  WorkOrderFilter,
  WorkOrderListResponse,
  ManufacturaDashboard,
  RoutingRow,
  ConsumeMaterialPayload,
  ReportOutputPayload,
} from "./hooks/useManufactura";

// ── Components ───────────────────────────────────────────────
export { default as BOMPage } from "./components/BOMPage";
export { default as CentrosTrabajoPage } from "./components/CentrosTrabajoPage";
export { default as OrdenesProduccionPage } from "./components/OrdenesProduccionPage";
export { default as OrdenDetalleDialog } from "./components/OrdenDetalleDialog";
export { default as RutasProduccionPage } from "./components/RutasProduccionPage";
export { default as RoutingPage } from "./components/RoutingPage";
export { default as MaterialConsumptionPanel } from "./components/MaterialConsumptionPanel";
export { default as OutputReportPanel } from "./components/OutputReportPanel";

// ── Pages ────────────────────────────────────────────────────
export { default as ManufacturaHome } from "./pages/ManufacturaHome";
