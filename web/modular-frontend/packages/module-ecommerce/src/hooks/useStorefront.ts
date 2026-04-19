"use client";

import { useQuery } from "@tanstack/react-query";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data as T;
}

export interface StorefrontCountry {
  countryCode: string;
  countryName: string;
  currencyCode: string;
  currencySymbol: string;
  phonePrefix: string;
  flagEmoji: string;
}

export interface StorefrontCurrency {
  currencyCode: string;
  currencyName: string;
  symbol: string;
  rateToBase: number;
  isBase: boolean;
  rateDate: string;
}

export interface CountryConfig extends StorefrontCountry {
  referenceCurrency: string;
  defaultExchangeRate: number;
  pricesIncludeTax: boolean;
  specialTaxRate: number;
  specialTaxEnabled: boolean;
  taxAuthorityCode: string;
  fiscalIdName: string;
  timeZoneIana: string;
  defaultTaxCode: string | null;
  defaultTaxName: string | null;
  defaultTaxRate: number;
}

export function useStorefrontCountries() {
  return useQuery<StorefrontCountry[]>({
    queryKey: ["storefront", "countries"],
    queryFn: () => get("/store/storefront/countries"),
    staleTime: 60 * 60 * 1000,
  });
}

export function useStorefrontCurrencies() {
  return useQuery<StorefrontCurrency[]>({
    queryKey: ["storefront", "currencies"],
    queryFn: () => get("/store/storefront/currencies"),
    staleTime: 10 * 60 * 1000,
  });
}

export function useCountryConfig(code?: string) {
  return useQuery<CountryConfig>({
    queryKey: ["storefront", "country", code],
    enabled: !!code,
    queryFn: () => get(`/store/storefront/country/${encodeURIComponent(code!)}`),
    staleTime: 30 * 60 * 1000,
  });
}

export function useResolveCountry() {
  return useQuery<CountryConfig & { source: "ip" | "default" }>({
    queryKey: ["storefront", "resolve"],
    queryFn: () => get("/store/storefront/resolve"),
    staleTime: 30 * 60 * 1000,
  });
}
