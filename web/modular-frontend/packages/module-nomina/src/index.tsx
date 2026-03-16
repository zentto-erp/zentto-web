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

export {
  useProfitSharingList,
  useGenerateProfitSharing,
  useProfitSharingSummary,
  useApproveProfitSharing,
  useTrustList,
  useCalculateTrust,
  useTrustBalance,
  useTrustSummary,
  useSavingsList,
  useEnrollSavings,
  useProcessMonthly,
  useSavingsBalance,
  useLoanList,
  useRequestLoan,
  useApproveLoan,
  useProcessLoanPayment,
  useObligationsList,
  useSaveObligation,
  useObligationsByCountry,
  useEnrollObligation,
  useEmployeeObligations,
  useFilingsList,
  useGenerateFiling,
  useFilingSummary,
  useMarkFiled,
  useOccHealthList,
  useCreateOccHealth,
  useUpdateOccHealth,
  useOccHealthDetail,
  useMedExamList,
  useSaveMedExam,
  usePendingExams,
  useMedOrderList,
  useCreateMedOrder,
  useApproveMedOrder,
  useTrainingList,
  useSaveTraining,
  useEmployeeCertifications,
  useCommitteeList,
  useSaveCommittee,
  useAddCommitteeMember,
  useRemoveCommitteeMember,
  useRecordMeeting,
  useCommitteeMeetings,
} from "./hooks/useRRHH";

export type {
  BaseFilter,
  ProfitSharingFilter,
  GenerateProfitSharingInput,
  ApproveProfitSharingInput,
  TrustFilter,
  CalculateTrustInput,
  SavingsFilter,
  EnrollSavingsInput,
  ProcessMonthlyInput,
  LoanFilter,
  RequestLoanInput,
  ApproveLoanInput,
  ProcessLoanPaymentInput,
  ObligationsFilter,
  SaveObligationInput,
  EnrollObligationInput,
  FilingsFilter,
  GenerateFilingInput,
  MarkFiledInput,
  OccHealthFilter,
  OccHealthInput,
  MedExamFilter,
  MedExamInput,
  MedOrderFilter,
  MedOrderInput,
  ApproveMedOrderInput,
  TrainingFilter,
  TrainingInput,
  CommitteeFilter,
  CommitteeInput,
  AddCommitteeMemberInput,
  RemoveCommitteeMemberInput,
  RecordMeetingInput,
} from "./hooks/useRRHH";

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

export { default as UtilidadesPage } from "./components/UtilidadesPage";
export { default as FideicomisoPage } from "./components/FideicomisoPage";
export { default as CajaAhorroPage } from "./components/CajaAhorroPage";
export { default as ObligacionesPage } from "./components/ObligacionesPage";
export { default as SaludOcupacionalPage } from "./components/SaludOcupacionalPage";
export { default as ExamenesMedicosPage } from "./components/ExamenesMedicosPage";
export { default as OrdenesMedicasPage } from "./components/OrdenesMedicasPage";
export { default as CapacitacionPage } from "./components/CapacitacionPage";
export { default as ComitesPage } from "./components/ComitesPage";
export { default as DocumentosMainPage } from "./components/DocumentosMainPage";
export { default as DocumentosPage } from "./components/DocumentosPage";
export { default as TemplateEditorPage } from "./components/TemplateEditorPage";
export { default as DocumentViewerModal } from "./components/DocumentViewerModal";

// ─── Document Templates hooks & types ─────────────────────────
export {
  useDocumentTemplatesList,
  useDocumentTemplate,
  useSaveDocumentTemplate,
  useDeleteDocumentTemplate,
  useRenderDocument,
} from "./hooks/useNomina";

export type {
  DocumentTemplate,
  RenderedDocument,
} from "./hooks/useNomina";

// ─── Pages ────────────────────────────────────────────────────
export { default as NominaHome } from "./pages/NominaHome";
