"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useShippingStore } from "../store/useShippingStore";
import { shipGet, shipPostAuth, shipPost } from "./useShippingAuth";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

function useToken() {
  return useShippingStore((s) => s.customerToken);
}

// ─── Dashboard ──────────────────────────────────────────────

export function useShippingDashboard() {
  const token = useToken();
  return useQuery({
    queryKey: ["shipping-dashboard"],
    enabled: !!token,
    queryFn: () => shipGet("/shipping/my/dashboard", token!),
  });
}

// ─── Addresses ──────────────────────────────────────────────

export function useShippingAddresses() {
  const token = useToken();
  return useQuery({
    queryKey: ["shipping-addresses"],
    enabled: !!token,
    queryFn: () => shipGet("/shipping/my/addresses", token!),
  });
}

export function useUpsertAddress() {
  const token = useToken();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => shipPostAuth("/shipping/my/addresses", data, token!),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["shipping-addresses"] }),
  });
}

// ─── Carriers ───────────────────────────────────────────────

export function useShippingCarriers() {
  const token = useToken();
  return useQuery({
    queryKey: ["shipping-carriers"],
    enabled: !!token,
    queryFn: () => shipGet("/shipping/my/carriers", token!),
  });
}

// ─── Quotes ─────────────────────────────────────────────────

export function useShippingQuote() {
  const token = useToken();
  return useMutation({
    mutationFn: (data: any) => shipPostAuth("/shipping/my/quotes", data, token!),
  });
}

// ─── Shipments ──────────────────────────────────────────────

export interface ShipmentFilter {
  status?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export function useShipmentsList(filter: ShipmentFilter) {
  const token = useToken();
  const params = new URLSearchParams();
  if (filter.status) params.set("status", filter.status);
  if (filter.search) params.set("search", filter.search);
  if (filter.page) params.set("page", String(filter.page));
  if (filter.limit) params.set("limit", String(filter.limit));

  return useQuery({
    queryKey: ["shipping-shipments", filter],
    enabled: !!token,
    queryFn: () => shipGet(`/shipping/my/shipments?${params}`, token!),
  });
}

export function useShipmentDetail(id: number | null) {
  const token = useToken();
  return useQuery({
    queryKey: ["shipping-shipment", id],
    enabled: !!token && !!id,
    queryFn: () => shipGet(`/shipping/my/shipments/${id}`, token!),
  });
}

export function useCreateShipment() {
  const token = useToken();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => shipPostAuth("/shipping/my/shipments", data, token!),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["shipping-shipments"] });
      qc.invalidateQueries({ queryKey: ["shipping-dashboard"] });
    },
  });
}

// ─── Customs ────────────────────────────────────────────────

export function useUpsertCustoms() {
  const token = useToken();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ shipmentId, data }: { shipmentId: number; data: any }) =>
      shipPostAuth(`/shipping/my/shipments/${shipmentId}/customs`, data, token!),
    onSuccess: (_d, vars) => qc.invalidateQueries({ queryKey: ["shipping-shipment", vars.shipmentId] }),
  });
}

// ─── Public Tracking ────────────────────────────────────────

export function usePublicTracking(trackingNumber: string | null, captchaToken?: string | null) {
  return useQuery({
    queryKey: ["shipping-track", trackingNumber],
    enabled: !!trackingNumber,
    queryFn: async () => {
      const headers: Record<string, string> = {};
      if (captchaToken) headers["x-captcha-token"] = captchaToken;
      const res = await fetch(`${API_BASE}/shipping/track/${encodeURIComponent(trackingNumber!)}`, { headers });
      const data = await res.json().catch(() => ({}));
      if (res.status === 403) throw new Error("Verificación anti-bot requerida");
      if (!res.ok) throw new Error(data?.error || "No encontrado");
      return data;
    },
  });
}
