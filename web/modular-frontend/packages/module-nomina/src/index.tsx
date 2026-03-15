"use client";

// ─── Hooks ────────────────────────────────────────────────────
export {
  useConceptosList,
  useSaveConcepto,
  useNominasList,
  useNominaDetalle,
  useProcesarNominaEmpleado,
  useProcesarNominaCompleta,
  useCerrarNomina,
  useVacacionesList,
  useVacacionDetalle,
  useProcesarVacaciones,
  useLiquidacionesList,
  useLiquidacionDetalle,
  useCalcularLiquidacion,
  useConstantesList,
  useSaveConstante,
} from "./hooks/useNomina";

export {
  useEmpleadosList,
  useEmpleadoDetalle,
  useCreateEmpleado,
  useUpdateEmpleado,
  useDeleteEmpleado,
} from "./hooks/useEmpleados";

export type {
  EmpleadoFilter,
  EmpleadoInput,
} from "./hooks/useEmpleados";

export {
  useVacacionSolicitudesList,
  useVacacionSolicitudDetalle,
  useDiasDisponibles,
  useCrearSolicitudVacaciones,
  useAprobarSolicitud,
  useRechazarSolicitud,
  useCancelarSolicitud,
  useProcesarPagoVacaciones,
} from "./hooks/useVacacionesSolicitudes";

export {
  useBatchList,
  useGenerateDraft,
  useBatchSummary,
  useBatchGrid,
  useBatchEmployeeLines,
  useSaveDraftLine,
  useBatchAddLine,
  useBatchRemoveLine,
  useApproveDraft,
  useProcessBatch,
  useBatchBulkUpdate,
} from "./hooks/useNominaBatch";

export type {
  SolicitudVacacionesInput,
  SolicitudFilter,
  DiasDisponibles,
} from "./hooks/useVacacionesSolicitudes";

export type {
  BatchDraftInput,
  BatchFilter,
  BatchGridFilter,
  SaveDraftLineInput,
  BatchAddLineInput,
  BatchBulkUpdateInput,
  BatchSummary,
  BatchGridRow,
  EmployeeLine,
} from "./hooks/useNominaBatch";

// ─── Types ────────────────────────────────────────────────────
export type {
  ConceptoFilter,
  ConceptoInput,
  NominaFilter,
  ProcesarEmpleadoInput,
  ProcesarNominaInput,
  VacacionesInput,
  LiquidacionInput,
  ConstanteInput,
} from "./hooks/useNomina";

// ─── Components ───────────────────────────────────────────────
export { default as NominasPage } from "./components/NominasPage";
export { default as ConceptosPage } from "./components/ConceptosPage";
export { default as EmpleadosPage } from "./components/EmpleadosPage";
export { default as VacacionesPage } from "./components/VacacionesPage";
export { default as VacacionesCalendarPage } from "./components/VacacionesCalendarPage";
export { default as VacacionesSolicitudesPage } from "./components/VacacionesSolicitudesPage";
export { default as LiquidacionesPage } from "./components/LiquidacionesPage";
export { default as ConstantesPage } from "./components/ConstantesPage";
export { default as NominaWizard } from "./components/NominaWizard";
export { default as NominaBatchWizard } from "./components/NominaBatchWizard";
export { default as PayrollBatchGrid } from "./components/PayrollBatchGrid";
export { default as PayrollPreview } from "./components/PayrollPreview";
export { default as PayrollEmployeePanel } from "./components/PayrollEmployeePanel";
export { default as LiquidacionesWizard } from "./components/LiquidacionesWizard";
export { default as VacacionesWizard } from "./components/VacacionesWizard";

// ─── Pages ────────────────────────────────────────────────────
export { default as NominaHome } from "./pages/NominaHome";
