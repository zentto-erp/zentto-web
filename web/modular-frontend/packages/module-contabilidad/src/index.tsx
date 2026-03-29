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
  // Conciliación bancaria: usar hooks de @zentto/module-bancos
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

export type {
  Periodo,
  PeriodoChecklistItem,
  CentroCosto,
  CentroCostoInput,
  Presupuesto,
  PresupuestoDetalle,
  PresupuestoLinea,
  CreatePresupuestoInput,
  // BankStatement, BankStatementLine, BankReconSummary: usar @zentto/module-bancos
  RecurrenteTemplate,
  RecurrenteLinea,
  CreateRecurrenteInput,
  VarianzaRow,
  CashFlowSection,
  AgingBucket,
  FinancialRatio,
  TaxSummaryRow,
  DrillDownRow,
} from "./hooks/useContabilidadAdvanced";

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

// ─── Hooks Activos Fijos ─────────────────────────────────────
export {
  useCategoriasList, useCategoriaDetalle, useUpsertCategoria,
  useActivosFijosList, useActivoFijoDetalle,
  useCreateActivoFijo, useUpdateActivoFijo, useDisposeActivoFijo,
  useCalcularDepreciacion, usePreviewDepreciacion, useDepreciacionHistorial,
  useAddMejora, useRevaluarActivo,
  useReporteLibroActivos, useReporteCuadroDepreciacion, useReporteActivosPorCategoria,
} from "./hooks/useActivosFijos";

export type {
  FixedAssetCategory, FixedAsset, DepreciationRecord,
  AssetFilter, CreateAssetInput, DisposeAssetInput, ImprovementInput, RevalueInput,
} from "./hooks/useActivosFijos";

// ─── Hooks Fiscal Tributaria ─────────────────────────────────
export {
  useGenerarLibroFiscal, useLibroFiscal, useResumenLibroFiscal, useExportarLibro,
  useCalcularDeclaracion, useDeclaracionesList, useDeclaracionDetalle,
  usePresentarDeclaracion, useEnmendarDeclaracion, useExportarDeclaracion,
  useGenerarRetencion, useRetencionesList, useRetencionDetalle,
  useConceptosList, useConceptoUpsert, useTaxUnitList, useTaxUnitUpsert, useCalcularRetencion,
} from "./hooks/useFiscalTributaria";

export type {
  TaxBookEntry, TaxBookSummary, TaxDeclaration, WithholdingVoucher, WithholdingConcept, TaxUnit,
  TaxBookFilter, DeclarationFilter, WithholdingFilter, ConceptoFilter,
} from "./hooks/useFiscalTributaria";

// ─── Componentes Activos Fijos y Fiscal ─────────────────────
export { default as ActivosFijosListPage } from "./components/ActivosFijosListPage";
export { default as CategoriasActivosPage } from "./components/CategoriasActivosPage";
export { default as DepreciacionWizard } from "./components/DepreciacionWizard";
export { default as LibroFiscalPage } from "./components/LibroFiscalPage";
export { default as DeclaracionesPage } from "./components/DeclaracionesPage";
export { default as RetencionesPage } from "./components/RetencionesPage";

// ─── Pages ────────────────────────────────────────────────────
export { default as ContabilidadHome } from "./pages/ContabilidadHome";
