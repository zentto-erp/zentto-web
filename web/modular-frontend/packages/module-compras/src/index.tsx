"use client";

// --- Hooks ---
export {
  useComprasList,
  useCompraById,
  useDetalleCompra,
  useIndicadoresCompra,
  useEmitirCompraTx,
  useCreateCompra,
  useUpdateCompra,
  useDeleteCompra,
} from "./hooks/useCompras";

export {
  useProveedoresList,
  useProveedorById,
  useCreateProveedor,
  useUpdateProveedor,
  useDeleteProveedor,
} from "./hooks/useProveedores";

export {
  useCuentasPorPagarList,
  useCuentaPorPagarById,
  useCreateCuentaPorPagar,
  useUpdateCuentaPorPagar,
  useDeleteCuentaPorPagar,
} from "./hooks/useCuentasPorPagar";

export {
  useCxpDocumentosPendientes,
  useCxpSaldo,
  useAplicarPagoTx,
} from "./hooks/useCxpTx";

// --- Types ---
export type {
  ComprasFilter,
  CompraRow,
  ComprasListResponse,
  EmitirCompraPayload,
} from "./hooks/useCompras";

export type {
  CxpDocumentoPendiente,
  CxpFormaPago,
  CxpAplicarPagoPayload,
} from "./hooks/useCxpTx";

// --- Components ---
export { default as ComprasTable } from "./components/ComprasTable";
export { default as CompraForm } from "./components/CompraForm";
export { default as CompraDetail } from "./components/CompraDetail";
export { default as ProveedoresTable } from "./components/ProveedoresTable";
export { default as ProveedorForm } from "./components/ProveedorForm";
export { default as CuentasPorPagarTable } from "./components/CuentasPorPagarTable";
export { default as CuentaPorPagarForm } from "./components/CuentaPorPagarForm";
export { default as CxpMasterPage } from "./components/CxpMasterPage";
export { default as PagoTxForm } from "./components/PagoTxForm";

// --- Pages ---
export { default as ComprasHome } from "./pages/ComprasHome";
