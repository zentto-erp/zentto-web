"use client";

export const MODULE_ID = "bancos";
export const MODULE_TITLE = "Bancos";

// Hooks
export {
  useBancosList,
  useCreateBanco,
  useUpdateBanco,
  useDeleteBanco,
  useCuentasBancarias,
  useMovimientosCuenta,
  useGenerarMovimientoBancario,
} from "./hooks/useBancosAuxiliares";

export {
  useConciliaciones,
  useCuentasBank,
  useConciliacionDetalle,
  useCrearConciliacion,
  useImportarExtracto,
  useConciliarMovimiento,
  useGenerarAjuste,
  useCerrarConciliacion,
} from "./hooks/useConciliacionBancaria";

// Page components
export { default as BancosPage } from "./components/bancos/BancosPage";
export { default as CuentasBancariasPage } from "./components/bancos/CuentasBancariasPage";
export { default as ConciliacionBancariaPage } from "./components/bancos/ConciliacionBancariaPage";
export { default as ConciliacionWizard } from "./components/ConciliacionWizard";

// Home page
export { default as BancosHome } from "./pages/BancosHome";
