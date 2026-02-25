"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPut } from "@/lib/api";

export type CountryCode = "VE" | "ES";

export type FiscalCountrySummary = {
  code: CountryCode;
  name: string;
  currency: string;
  authority: string;
  requiresFiscalPrinter: boolean;
  supportsVerifactu: boolean;
};

export type FiscalTaxRate = {
  code: string;
  name: string;
  rate: number;
  countryCode: CountryCode;
  appliesToPOS: boolean;
  appliesToRestaurant: boolean;
  isDefault: boolean;
  surchargeRate?: number;
};

export type FiscalInvoiceType = {
  code: string;
  name: string;
  countryCode: CountryCode;
  isRectificative: boolean;
  maxAmount?: number | null;
  requiresRecipientNIF: boolean;
};

export type FiscalRegulatorySource = {
  id: string;
  title: string;
  authority: string;
  type: string;
  url: string;
  publishedDate?: string;
  notes?: string;
};

export type FiscalMilestone = {
  key: string;
  date: string;
  description: string;
  sourceUrl: string;
};

export type FiscalCountryKnowledge = {
  country: {
    code: CountryCode;
    name: string;
    currency: string;
    taxAuthority: string;
    fiscalIdName: string;
  };
  taxes: FiscalTaxRate[];
  invoiceTypes: FiscalInvoiceType[];
  milestones: FiscalMilestone[];
  sources: FiscalRegulatorySource[];
  verifactu?: {
    enabled: boolean;
    modes: Array<"auto" | "manual">;
    productionEndpoint: string;
    testingEndpoint: string;
    qrBaseUrlProduction: string;
    qrBaseUrlTesting: string;
  };
};

export type FiscalConfig = {
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
  currency: string;
  taxRegime: string;
  defaultTaxCode: string;
  defaultTaxRate: number;
  fiscalPrinterEnabled: boolean;
  printerBrand?: string;
  printerPort?: string;
  verifactuEnabled: boolean;
  verifactuMode: "auto" | "manual";
  certificatePath?: string;
  certificatePassword?: string;
  aeatEndpoint?: string;
  senderNIF?: string;
  senderRIF?: string;
  softwareId?: string;
  softwareName?: string;
  softwareVersion?: string;
  posEnabled: boolean;
  restaurantEnabled: boolean;
};

const QUERY_KEY = "fiscal-config";
const API_BASE = "/api/v1/fiscal";

export function useFiscalCountries(enabled = true) {
  return useQuery<FiscalCountrySummary[]>({
    queryKey: [QUERY_KEY, "countries"],
    queryFn: async () => {
      const resp = await apiGet(`${API_BASE}/countries`);
      return (resp?.data ?? []) as FiscalCountrySummary[];
    },
    enabled
  });
}

export function useFiscalCountryKnowledge(countryCode: CountryCode, enabled = true) {
  return useQuery<FiscalCountryKnowledge>({
    queryKey: [QUERY_KEY, "country", countryCode],
    queryFn: async () => {
      const resp = await apiGet(`${API_BASE}/countries/${countryCode}`);
      return resp?.data as FiscalCountryKnowledge;
    },
    enabled: !!countryCode && enabled
  });
}

export function useFiscalConfig(params: {
  empresaId: number;
  sucursalId?: number;
  countryCode: CountryCode;
}, enabled = true) {
  return useQuery<FiscalConfig>({
    queryKey: [QUERY_KEY, "current", params],
    queryFn: async () => {
      const query = new URLSearchParams({
        empresaId: String(params.empresaId),
        sucursalId: String(params.sucursalId ?? 0),
        countryCode: params.countryCode
      });
      const resp = await apiGet(`${API_BASE}/config?${query.toString()}`);
      return resp?.data as FiscalConfig;
    },
    enabled: !!params.empresaId && !!params.countryCode && enabled
  });
}

export function useSaveFiscalConfig() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: FiscalConfig) => {
      const resp = await apiPut(`${API_BASE}/config`, payload);
      return resp?.data as FiscalConfig;
    },
    onSuccess: (saved: FiscalConfig) => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, "current"] });
      queryClient.setQueryData(
        [
          QUERY_KEY,
          "current",
          { empresaId: saved.empresaId, sucursalId: saved.sucursalId, countryCode: saved.countryCode }
        ],
        saved
      );
    }
  });
}
