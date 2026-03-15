"use client";

// ─── Hooks ────────────────────────────────────────────────────
export {
  useAsientosList,
  useAsientoDetalle,
  useCreateAsiento,
  useAnularAsiento,
  useCrearAjuste,
  useGenerarDepreciacion,
  useLibroMayor,
  useMayorAnalitico,
  useBalanceComprobacion,
  useEstadoResultados,
  useBalanceGeneral,
  useLibroDiario,
  useDashboardResumen,
  usePlanCuentas,
  useCuentaDetalle,
  useSeedPlanCuentas,
  useCreateCuenta,
  useUpdateCuenta,
  useDeleteCuenta,
} from "./hooks/useContabilidad";

// ─── Types ────────────────────────────────────────────────────
export type {
  AsientoFilter,
  AsientoDetalle,
  CreateAsientoInput,
  CreateAjusteInput,
  CuentaContable,
  CuentaInput,
} from "./hooks/useContabilidad";

// ─── Components ───────────────────────────────────────────────
export { default as AsientosListPage } from "./components/AsientosListPage";
export { default as NuevoAsientoPage } from "./components/NuevoAsientoPage";
export { default as PlanCuentasPage } from "./components/PlanCuentasPage";
export { default as PlanCuentasPageMejorado } from "./components/PlanCuentasPageMejorado";
export { default as ReportesContablesPage } from "./components/ReportesContablesPage";
export { default as EditableDataGrid } from "./components/EditableDataGrid";

// ─── Pages ────────────────────────────────────────────────────
export { default as ContabilidadHome } from "./pages/ContabilidadHome";
