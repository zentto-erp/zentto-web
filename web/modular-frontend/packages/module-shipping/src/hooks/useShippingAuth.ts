"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { useShippingStore } from "../store/useShippingStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function shipPost(path: string, body: unknown) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function shipGet(path: string, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function shipPostAuth(path: string, body: unknown, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

export function useShippingRegister() {
  return useMutation({
    mutationFn: (payload: {
      email: string;
      password: string;
      displayName: string;
      phone?: string;
      companyName?: string;
      countryCode?: string;
    }) => shipPost("/shipping/auth/register", payload),
  });
}

export function useShippingLogin() {
  const setToken = useShippingStore((s) => s.setCustomerToken);
  const setInfo = useShippingStore((s) => s.setCustomerInfo);

  return useMutation({
    mutationFn: (payload: { email: string; password: string }) =>
      shipPost("/shipping/auth/login", payload),
    onSuccess: (data: any) => {
      if (data.token) setToken(data.token);
      if (data.customer) setInfo(data.customer);
    },
  });
}

export function useShippingProfile() {
  const token = useShippingStore((s) => s.customerToken);
  return useQuery<any>({
    queryKey: ["shipping-profile"],
    enabled: !!token,
    queryFn: () => shipGet("/shipping/my/profile", token!),
  });
}

export function useShippingLogout() {
  const logout = useShippingStore((s) => s.logout);
  return logout;
}

// Re-export helpers for use in other hooks
export { shipGet, shipPost, shipPostAuth };
