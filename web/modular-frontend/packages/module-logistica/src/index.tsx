"use client";

export const MODULE_ID = "logistica";
export const MODULE_TITLE = "Logistica";

// ── Hooks ────────────────────────────────────────────────────
export {
  useCarriersList,
  useCarrierDetail,
  useCreateCarrier,
  useUpdateCarrier,
  useDriversList,
  useCreateDriver,
  useUpdateDriver,
  useReceiptsList,
  useReceiptDetail,
  useCreateReceipt,
  useCompleteReceipt,
  useReturnsList,
  useReturnDetail,
  useCreateReturn,
  useDeliveryNotesList,
  useDeliveryNoteDetail,
  useCreateDeliveryNote,
  useDispatchDeliveryNote,
  useDeliverDeliveryNote,
  useLogisticaDashboard,
} from "./hooks/useLogistica";

export type {
  CarrierFilter,
  CarrierListResponse,
  DriverFilter,
  DriverListResponse,
  ReceiptFilter,
  ReceiptListResponse,
  ReturnFilter,
  ReturnListResponse,
  DeliveryFilter,
  DeliveryListResponse,
  LogisticaDashboard,
} from "./hooks/useLogistica";

// ── Components ───────────────────────────────────────────────
export { default as RecepcionMercanciaPage } from "./components/RecepcionMercanciaPage";
export { default as DevolucionesPage } from "./components/DevolucionesPage";
export { default as AlbaranesPage } from "./components/AlbaranesPage";
export { default as TransportistasPage } from "./components/TransportistasPage";
export { default as ConductoresPage } from "./components/ConductoresPage";

// ── Pages ────────────────────────────────────────────────────
export { default as LogisticaHome } from "./pages/LogisticaHome";
