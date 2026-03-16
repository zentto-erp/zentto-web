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
  useMovimientoDetalle,
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
export type { ConciliacionFilter } from "./hooks/useConciliacionBancaria";

export {
  useCajaChicaBoxes,
  useCreateCajaChicaBox,
  useOpenSession,
  useCloseSession,
  useActiveSession,
  useAddExpense,
  useExpensesList,
  useCajaChicaSummary,
} from "./hooks/useCajaChica";

// Page components
export { default as BancosPage } from "./components/bancos/BancosPage";
export { default as CuentasBancariasPage } from "./components/bancos/CuentasBancariasPage";
export { default as ConciliacionBancariaPage } from "./components/bancos/ConciliacionBancariaPage";
export { default as ConciliacionWizard } from "./components/ConciliacionWizard";
export { default as MovimientoBancarioWizard } from "./components/MovimientoBancarioWizard";
export { default as VoucherView } from "./components/VoucherView";
export { default as CajaChicaPage } from "./components/CajaChicaPage";

// Home page
export { default as BancosHome } from "./pages/BancosHome";
