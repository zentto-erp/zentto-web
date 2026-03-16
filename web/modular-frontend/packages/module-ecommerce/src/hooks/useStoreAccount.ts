"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useCartStore } from "../store/useCartStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function authGet(path: string, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function authPost(path: string, body: unknown, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function authPut(path: string, body: unknown, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function authDelete(path: string, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

// ─── Tipos ───────────────────────────────────────────

export interface CustomerAddress {
  AddressId: number;
  Label: string;
  RecipientName: string;
  Phone: string | null;
  AddressLine: string;
  City: string | null;
  State: string | null;
  ZipCode: string | null;
  Country: string;
  Instructions: string | null;
  IsDefault: boolean;
}

export interface CustomerPaymentMethod {
  PaymentMethodId: number;
  MethodType: string;
  Label: string;
  BankName: string | null;
  AccountPhone: string | null;
  AccountNumber: string | null;
  AccountEmail: string | null;
  HolderName: string | null;
  HolderFiscalId: string | null;
  CardType: string | null;
  CardLast4: string | null;
  CardExpiry: string | null;
  IsDefault: boolean;
}

export interface AddressFormData {
  label: string;
  recipientName: string;
  phone?: string;
  addressLine: string;
  city?: string;
  state?: string;
  zipCode?: string;
  country?: string;
  instructions?: string;
  isDefault?: boolean;
}

export interface PaymentMethodFormData {
  methodType: string;
  label: string;
  bankName?: string;
  accountPhone?: string;
  accountNumber?: string;
  accountEmail?: string;
  holderName?: string;
  holderFiscalId?: string;
  cardType?: string;
  cardLast4?: string;
  cardExpiry?: string;
  isDefault?: boolean;
}

// ─── Direcciones ─────────────────────────────────────

export function useMyAddresses() {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<CustomerAddress[]>({
    queryKey: ["store-customer", "addresses"],
    enabled: !!token,
    queryFn: () => authGet("/store/my/addresses", token!),
  });
}

export function useCreateAddress() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: AddressFormData) => authPost("/store/my/addresses", data, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "addresses"] }); },
  });
}

export function useUpdateAddress() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: AddressFormData }) =>
      authPut(`/store/my/addresses/${id}`, data, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "addresses"] }); },
  });
}

export function useDeleteAddress() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => authDelete(`/store/my/addresses/${id}`, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "addresses"] }); },
  });
}

// ─── Métodos de pago ─────────────────────────────────

export function useMyPaymentMethods() {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<CustomerPaymentMethod[]>({
    queryKey: ["store-customer", "payment-methods"],
    enabled: !!token,
    queryFn: () => authGet("/store/my/payment-methods", token!),
  });
}

export function useCreatePaymentMethod() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: PaymentMethodFormData) =>
      authPost("/store/my/payment-methods", data, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "payment-methods"] }); },
  });
}

export function useUpdatePaymentMethod() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: PaymentMethodFormData }) =>
      authPut(`/store/my/payment-methods/${id}`, data, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "payment-methods"] }); },
  });
}

export function useDeletePaymentMethod() {
  const token = useCartStore((s) => s.customerToken);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => authDelete(`/store/my/payment-methods/${id}`, token!),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["store-customer", "payment-methods"] }); },
  });
}
