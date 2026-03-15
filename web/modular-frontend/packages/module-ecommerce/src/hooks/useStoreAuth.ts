"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { useCartStore } from "../store/useCartStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function storePost(path: string, body: unknown) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function storeGetAuth(path: string, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

export function useCustomerRegister() {
  return useMutation({
    mutationFn: (payload: {
      email: string;
      name: string;
      password: string;
      phone?: string;
      address?: string;
      fiscalId?: string;
    }) => storePost("/store/auth/register", payload),
  });
}

export function useCustomerLogin() {
  const setToken = useCartStore((s) => s.setCustomerToken);
  const setInfo = useCartStore((s) => s.setCustomerInfo);

  return useMutation({
    mutationFn: (payload: { email: string; password: string }) =>
      storePost("/store/auth/login", payload),
    onSuccess: (data: any) => {
      if (data.token) setToken(data.token);
      if (data.customer) {
        setInfo({
          name: data.customer.name,
          email: data.customer.email,
          phone: data.customer.phone,
          address: data.customer.address,
          fiscalId: data.customer.fiscalId,
        });
      }
    },
  });
}

export function useCustomerProfile() {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<any>({
    queryKey: ["store-customer", "profile"],
    enabled: !!token,
    queryFn: () => storeGetAuth("/store/my/profile", token!),
  });
}

export function useCustomerLogout() {
  const setToken = useCartStore((s) => s.setCustomerToken);
  const setInfo = useCartStore((s) => s.setCustomerInfo);
  return () => {
    setToken(null);
    setInfo(null);
  };
}
