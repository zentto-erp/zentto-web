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

// ─── Hooks Avanzados ─────────────────────────────────────────
export {
  usePeriodosList, useEnsureYear, useClosePeriod, useReopenPeriod,
  useGenerateClosingEntries, usePeriodoChecklist,
  useCentrosCostoList, useCentroCostoGet, useCreateCentroCosto, useUpdateCentroCosto, useDeleteCentroCosto,
  usePresupuestosList, usePresupuestoGet, useCreatePresupuesto, useUpdatePresupuesto, useDeletePresupuesto, usePresupuestoVarianza,
  useBankStatementsList, useBankStatementLines, useImportBankStatement, useMatchBankLine, useUnmatchBankLine, useAutoMatch, useBankReconSummary,
  useRecurrentesList, useRecurrenteGet, useCreateRecurrente, useUpdateRecurrente, useDeleteRecurrente, useExecuteRecurrente, useDueRecurrentes,
  useReverseEntry,
  useCashFlowReport, useBalanceCompMultiPeriod, usePnLMultiPeriod, useAgingCxC, useAgingCxP, useFinancialRatios, useTaxSummary, useDrillDown,
  usePnLByCostCenter,
} from "./hooks/useContabilidadAdvanced";

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

// ─── Componentes Avanzados ───────────────────────────────────
export { default as PlanCuentasTree } from "./components/PlanCuentasTree";
export { default as ContabilidadDashboardPro } from "./pages/ContabilidadDashboardPro";
export { default as CierreContableWizard } from "./components/CierreContableWizard";
export { default as ConciliacionBancariaPage } from "./components/ConciliacionBancariaPage";
export { default as CentrosCostoPage } from "./components/CentrosCostoPage";
export { default as PresupuestosPage } from "./components/PresupuestosPage";
export { default as AsientosRecurrentesPage } from "./components/AsientosRecurrentesPage";
export { default as ReportesAvanzadosPage } from "./components/ReportesAvanzadosPage";

// ─── Pages ────────────────────────────────────────────────────
export { default as ContabilidadHome } from "./pages/ContabilidadHome";
