"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

// ─── Query Keys ──────────────────────────────────────────────
const QK_UTILIDADES = "rrhh-utilidades";
const QK_FIDEICOMISO = "rrhh-fideicomiso";
const QK_CAJA_AHORRO = "rrhh-caja-ahorro";
const QK_LOANS = "rrhh-loans";
const QK_OBLIGACIONES = "rrhh-obligaciones";
const QK_FILINGS = "rrhh-filings";
const QK_OCC_HEALTH = "rrhh-occ-health";
const QK_MED_EXAMS = "rrhh-med-exams";
const QK_MED_ORDERS = "rrhh-med-orders";
const QK_TRAINING = "rrhh-training";
const QK_COMMITTEES = "rrhh-committees";

// ─── Common Types ────────────────────────────────────────────

export interface BaseFilter {
  page?: number;
  limit?: number;
  search?: string;
  [key: string]: unknown;
}

// ─── Utilidades (Profit Sharing) ─────────────────────────────

export interface ProfitSharingFilter extends BaseFilter {
  fiscalYear?: number;
  status?: string;
}

export interface GenerateProfitSharingInput {
  fiscalYear: number;
  daysGranted: number;
}

export interface ApproveProfitSharingInput {
  id: number;
}

export function useProfitSharingList(filter?: ProfitSharingFilter) {
  return useQuery({
    queryKey: [QK_UTILIDADES, filter],
    queryFn: () => apiGet("/v1/rrhh/utilidades", filter),
  });
}

export function useGenerateProfitSharing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: GenerateProfitSharingInput) =>
      apiPost("/v1/rrhh/utilidades/generate", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_UTILIDADES] }),
  });
}

export function useProfitSharingSummary(id: number | null) {
  return useQuery({
    queryKey: [QK_UTILIDADES, "summary", id],
    queryFn: () => apiGet(`/v1/rrhh/utilidades/${id}/summary`),
    enabled: !!id,
  });
}

export function useApproveProfitSharing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ApproveProfitSharingInput) =>
      apiPost(`/v1/rrhh/utilidades/${data.id}/approve`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_UTILIDADES] }),
  });
}

// ─── Fideicomiso (Trust) ─────────────────────────────────────

export interface TrustFilter extends BaseFilter {
  year?: number;
  quarter?: number;
  employeeCode?: string;
}

export interface CalculateTrustInput {
  year: number;
  quarter: number;
}

export function useTrustList(filter?: TrustFilter) {
  return useQuery({
    queryKey: [QK_FIDEICOMISO, filter],
    queryFn: () => apiGet("/v1/rrhh/fideicomiso", filter),
  });
}

export function useCalculateTrust() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CalculateTrustInput) =>
      apiPost("/v1/rrhh/fideicomiso/calculate", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_FIDEICOMISO] }),
  });
}

export function useTrustBalance(employeeCode: string | null) {
  return useQuery({
    queryKey: [QK_FIDEICOMISO, "balance", employeeCode],
    queryFn: () => apiGet(`/v1/rrhh/fideicomiso/balance/${employeeCode}`),
    enabled: !!employeeCode,
  });
}

export function useTrustSummary(year: number | null, quarter: number | null) {
  return useQuery({
    queryKey: [QK_FIDEICOMISO, "summary", year, quarter],
    queryFn: () => apiGet("/v1/rrhh/fideicomiso/summary", { year, quarter }),
    enabled: !!year && !!quarter,
  });
}

// ─── Caja de Ahorro (Savings Fund) ──────────────────────────

export interface SavingsFilter extends BaseFilter {
  status?: string;
  employeeCode?: string;
}

export interface EnrollSavingsInput {
  employeeCode: string;
  contributionPct: number;
  employerMatchPct: number;
}

export interface ProcessMonthlyInput {
  year: number;
  month: number;
}

export interface LoanFilter extends BaseFilter {
  status?: string;
  employeeCode?: string;
}

export interface RequestLoanInput {
  employeeCode: string;
  amount: number;
  installments: number;
  reason?: string;
}

export interface ApproveLoanInput {
  loanId: number;
  approved: boolean;
  notes?: string;
}

export interface ProcessLoanPaymentInput {
  loanId: number;
  amount: number;
}

export function useSavingsList(filter?: SavingsFilter) {
  return useQuery({
    queryKey: [QK_CAJA_AHORRO, filter],
    queryFn: () => apiGet("/v1/rrhh/caja-ahorro", filter),
  });
}

export function useEnrollSavings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: EnrollSavingsInput) =>
      apiPost("/v1/rrhh/caja-ahorro/enroll", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CAJA_AHORRO] }),
  });
}

export function useProcessMonthly() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ProcessMonthlyInput) =>
      apiPost("/v1/rrhh/caja-ahorro/process-monthly", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CAJA_AHORRO] }),
  });
}

export function useSavingsBalance(employeeCode: string | null) {
  return useQuery({
    queryKey: [QK_CAJA_AHORRO, "balance", employeeCode],
    queryFn: () => apiGet(`/v1/rrhh/caja-ahorro/balance/${employeeCode}`),
    enabled: !!employeeCode,
  });
}

export function useLoanList(filter?: LoanFilter) {
  return useQuery({
    queryKey: [QK_LOANS, filter],
    queryFn: () => apiGet("/v1/rrhh/caja-ahorro/loans", filter),
  });
}

export function useRequestLoan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: RequestLoanInput) =>
      apiPost("/v1/rrhh/caja-ahorro/loans", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LOANS] }),
  });
}

export function useApproveLoan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ApproveLoanInput) =>
      apiPost(`/v1/rrhh/caja-ahorro/loans/${data.loanId}/approve`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_LOANS] });
      qc.invalidateQueries({ queryKey: [QK_CAJA_AHORRO] });
    },
  });
}

export function useProcessLoanPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ProcessLoanPaymentInput) =>
      apiPost(`/v1/rrhh/caja-ahorro/loans/${data.loanId}/payment`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LOANS] }),
  });
}

// ─── Obligaciones Legales (Legal Obligations) ───────────────

export interface ObligationsFilter extends BaseFilter {
  countryCode?: string;
  frequency?: string;
}

export interface SaveObligationInput {
  code: string;
  name: string;
  countryCode: string;
  employeeRate?: number;
  employerRate?: number;
  frequency?: string;
  description?: string;
}

export interface EnrollObligationInput {
  obligationCode: string;
  employeeId: number;
  startDate: string;
}

export interface FilingsFilter extends BaseFilter {
  period?: string;
  status?: string;
  obligationCode?: string;
}

export interface GenerateFilingInput {
  obligationCode: string;
  periodFrom: string;
  periodTo: string;
}

export interface MarkFiledInput {
  filingId: number;
  referenceNumber?: string;
  filedDate?: string;
}

export function useObligationsList(filter?: ObligationsFilter) {
  return useQuery({
    queryKey: [QK_OBLIGACIONES, filter],
    queryFn: () => apiGet("/v1/rrhh/obligaciones", filter),
  });
}

export function useSaveObligation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: SaveObligationInput) =>
      apiPost("/v1/rrhh/obligaciones", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_OBLIGACIONES] }),
  });
}

export function useObligationsByCountry(code: string | null) {
  return useQuery({
    queryKey: [QK_OBLIGACIONES, "country", code],
    queryFn: () => apiGet(`/v1/rrhh/obligaciones/country/${code}`),
    enabled: !!code,
  });
}

export function useEnrollObligation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: EnrollObligationInput) =>
      apiPost("/v1/rrhh/obligaciones/enroll", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_OBLIGACIONES] }),
  });
}

export function useEmployeeObligations(employeeId: number | null) {
  return useQuery({
    queryKey: [QK_OBLIGACIONES, "employee", employeeId],
    queryFn: () => apiGet(`/v1/rrhh/obligaciones/employee/${employeeId}`),
    enabled: !!employeeId,
  });
}

export function useFilingsList(filter?: FilingsFilter) {
  return useQuery({
    queryKey: [QK_FILINGS, filter],
    queryFn: () => apiGet("/v1/rrhh/obligaciones/filings", filter),
  });
}

export function useGenerateFiling() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: GenerateFilingInput) =>
      apiPost("/v1/rrhh/obligaciones/filings/generate", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_FILINGS] }),
  });
}

export function useFilingSummary(id: number | null) {
  return useQuery({
    queryKey: [QK_FILINGS, "summary", id],
    queryFn: () => apiGet(`/v1/rrhh/obligaciones/filings/${id}`),
    enabled: !!id,
  });
}

export function useMarkFiled() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: MarkFiledInput) =>
      apiPost(`/v1/rrhh/obligaciones/filings/${data.filingId}/mark-filed`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_FILINGS] }),
  });
}

// ─── Salud Ocupacional (Occupational Health) ────────────────

export interface OccHealthFilter extends BaseFilter {
  type?: string;
  status?: string;
  severity?: string;
}

export interface OccHealthInput {
  id?: number;
  employeeCode: string;
  type: string;
  date: string;
  severity: string;
  daysLost?: number;
  description: string;
  status?: string;
  correctiveActions?: string;
}

export function useOccHealthList(filter?: OccHealthFilter) {
  return useQuery({
    queryKey: [QK_OCC_HEALTH, filter],
    queryFn: () => apiGet("/v1/rrhh/salud-ocupacional", filter),
  });
}

export function useCreateOccHealth() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: OccHealthInput) =>
      apiPost("/v1/rrhh/salud-ocupacional", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_OCC_HEALTH] }),
  });
}

export function useUpdateOccHealth() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: OccHealthInput) =>
      apiPut(`/v1/rrhh/salud-ocupacional/${data.id}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_OCC_HEALTH] }),
  });
}

export function useOccHealthDetail(id: number | null) {
  return useQuery({
    queryKey: [QK_OCC_HEALTH, "detail", id],
    queryFn: () => apiGet(`/v1/rrhh/salud-ocupacional/${id}`),
    enabled: !!id,
  });
}

// ─── Examenes Medicos (Medical Exams) ───────────────────────

export interface MedExamFilter extends BaseFilter {
  type?: string;
  employeeCode?: string;
  overdue?: boolean;
}

export interface MedExamInput {
  id?: number;
  employeeCode: string;
  type: string;
  examDate: string;
  nextDueDate?: string;
  result?: string;
  provider?: string;
  notes?: string;
}

export function useMedExamList(filter?: MedExamFilter) {
  return useQuery({
    queryKey: [QK_MED_EXAMS, filter],
    queryFn: () => apiGet("/v1/rrhh/examenes-medicos", filter),
  });
}

export function useSaveMedExam() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: MedExamInput) =>
      apiPost("/v1/rrhh/examenes-medicos", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MED_EXAMS] }),
  });
}

export function useDeleteMedExam() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/rrhh/examenes-medicos/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MED_EXAMS] }),
  });
}

export function usePendingExams() {
  return useQuery({
    queryKey: [QK_MED_EXAMS, "pending"],
    queryFn: () => apiGet("/v1/rrhh/examenes-medicos/pending"),
  });
}

// ─── Ordenes Medicas (Medical Orders) ───────────────────────

export interface MedOrderFilter extends BaseFilter {
  type?: string;
  status?: string;
  employeeCode?: string;
}

export interface MedOrderInput {
  employeeCode: string;
  type: string;
  date: string;
  diagnosis?: string;
  cost?: number;
  description?: string;
}

export interface ApproveMedOrderInput {
  orderId: number;
  approved: boolean;
  notes?: string;
}

export function useMedOrderList(filter?: MedOrderFilter) {
  return useQuery({
    queryKey: [QK_MED_ORDERS, filter],
    queryFn: () => apiGet("/v1/rrhh/ordenes-medicas", filter),
  });
}

export function useCreateMedOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: MedOrderInput) =>
      apiPost("/v1/rrhh/ordenes-medicas", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MED_ORDERS] }),
  });
}

export function useApproveMedOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ApproveMedOrderInput) =>
      apiPost(`/v1/rrhh/ordenes-medicas/${data.orderId}/approve`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MED_ORDERS] }),
  });
}

// ─── Capacitacion (Training) ────────────────────────────────

export interface TrainingFilter extends BaseFilter {
  type?: string;
  employeeCode?: string;
  regulatory?: boolean;
}

export interface TrainingInput {
  id?: number;
  employeeCode: string;
  title: string;
  type: string;
  provider?: string;
  hours?: number;
  result?: string;
  regulatory?: boolean;
  startDate: string;
  endDate?: string;
  certificateUrl?: string;
}

export function useTrainingList(filter?: TrainingFilter) {
  return useQuery({
    queryKey: [QK_TRAINING, filter],
    queryFn: () => apiGet("/v1/rrhh/capacitacion", filter),
  });
}

export function useSaveTraining() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: TrainingInput) =>
      apiPost("/v1/rrhh/capacitacion", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_TRAINING] }),
  });
}

export function useDeleteTraining() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/rrhh/capacitacion/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_TRAINING] }),
  });
}

export function useEmployeeCertifications(code: string | null) {
  return useQuery({
    queryKey: [QK_TRAINING, "certifications", code],
    queryFn: () => apiGet(`/v1/rrhh/capacitacion/certifications/${code}`),
    enabled: !!code,
  });
}

// ─── Comites (Committees) ───────────────────────────────────

export interface CommitteeFilter extends BaseFilter {
  type?: string;
  active?: boolean;
}

export interface CommitteeInput {
  id?: number;
  name: string;
  type: string;
  description?: string;
  startDate: string;
  endDate?: string;
}

export interface AddCommitteeMemberInput {
  committeeId: number;
  employeeCode: string;
  role: string;
}

export interface RemoveCommitteeMemberInput {
  committeeId: number;
  memberId: number;
}

export interface RecordMeetingInput {
  committeeId: number;
  date: string;
  summary: string;
  attendees?: string[];
  agreements?: string;
}

export function useCommitteeList(filter?: CommitteeFilter) {
  return useQuery({
    queryKey: [QK_COMMITTEES, filter],
    queryFn: () => apiGet("/v1/rrhh/comites", filter),
  });
}

export function useSaveCommittee() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CommitteeInput) =>
      apiPost("/v1/rrhh/comites", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_COMMITTEES] }),
  });
}

export function useAddCommitteeMember() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: AddCommitteeMemberInput) =>
      apiPost(`/v1/rrhh/comites/${data.committeeId}/members`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_COMMITTEES] }),
  });
}

export function useRemoveCommitteeMember() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: RemoveCommitteeMemberInput) =>
      apiDelete(`/v1/rrhh/comites/${data.committeeId}/members/${data.memberId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_COMMITTEES] }),
  });
}

export function useRecordMeeting() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: RecordMeetingInput) =>
      apiPost(`/v1/rrhh/comites/${data.committeeId}/meetings`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_COMMITTEES] }),
  });
}

export function useCommitteeMeetings(committeeId: number | null) {
  return useQuery({
    queryKey: [QK_COMMITTEES, "meetings", committeeId],
    queryFn: () => apiGet(`/v1/rrhh/comites/${committeeId}/meetings`),
    enabled: !!committeeId,
  });
}
