"use client";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiPost } from "@zentto/shared-api";

const BASE = "/api/v1/crm";

export interface LeadConvertInput {
  leadId: number;
  dealName?: string;
  pipelineId?: number;
  stageId?: number;
  crmCompanyId?: number;
}

/**
 * Convierte un lead en Contact + Deal y marca el lead como CONVERTED.
 * El backend (usp_crm_Lead_Convert) crea el contacto y retorna el DealId creado.
 */
export function useLeadConvert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: LeadConvertInput) => {
      const { leadId, ...body } = d;
      return apiPost(`${BASE}/leads/${leadId}/convert`, body);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["crm-leads"] });
      qc.invalidateQueries({ queryKey: ["crm-deals"] });
      qc.invalidateQueries({ queryKey: ["crm-contacts"] });
    },
  });
}
