"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";

const QK = "caja-chica";
const API = "/api/v1/bancos/caja-chica";

export function useCajaChicaBoxes() {
  return useQuery<any>({
    queryKey: [QK, "boxes"],
    queryFn: () => apiGet(API)
  });
}

export function useCreateCajaChicaBox() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { name: string; accountCode?: string; maxAmount: number; responsible?: string }) =>
      apiPost(API, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] })
  });
}

export function useOpenSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { boxId: number; openingAmount: number }) =>
      apiPost(`${API}/${payload.boxId}/abrir`, { openingAmount: payload.openingAmount }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] })
  });
}

export function useCloseSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { boxId: number; notes?: string }) =>
      apiPost(`${API}/${payload.boxId}/cerrar`, { notes: payload.notes }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] })
  });
}

export function useActiveSession(boxId?: number) {
  return useQuery<any>({
    queryKey: [QK, "active-session", boxId],
    enabled: !!boxId,
    queryFn: () => apiGet(`${API}/${boxId}/sesion-activa`)
  });
}

export function useAddExpense() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: {
      boxId: number;
      sessionId: number;
      category: string;
      description: string;
      amount: number;
      beneficiary?: string;
      receiptNumber?: string;
      accountCode?: string;
    }) => apiPost(`${API}/${payload.boxId}/gastos`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] })
  });
}

export function useExpensesList(boxId?: number, sessionId?: number) {
  return useQuery<any>({
    queryKey: [QK, "expenses", boxId, sessionId],
    enabled: !!boxId,
    queryFn: () => {
      const params = sessionId ? `?sessionId=${sessionId}` : "";
      return apiGet(`${API}/${boxId}/gastos${params}`);
    }
  });
}

export function useCajaChicaSummary(boxId?: number) {
  return useQuery<any>({
    queryKey: [QK, "summary", boxId],
    enabled: !!boxId,
    queryFn: () => apiGet(`${API}/${boxId}/resumen`)
  });
}
