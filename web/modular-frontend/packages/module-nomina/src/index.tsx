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
} from "./hooks/useEmpleados";

export type {
  EmpleadoFilter,
} from "./hooks/useEmpleados";

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
export { default as VacacionesPage } from "./components/VacacionesPage";
export { default as LiquidacionesPage } from "./components/LiquidacionesPage";
export { default as ConstantesPage } from "./components/ConstantesPage";
export { default as NominaWizard } from "./components/NominaWizard";

// ─── Pages ────────────────────────────────────────────────────
export { default as NominaHome } from "./pages/NominaHome";
