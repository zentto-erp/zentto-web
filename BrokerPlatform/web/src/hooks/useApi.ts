"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";

// ── Search ──
export function useSearch(params: Record<string, string>) {
    const qs = new URLSearchParams(params).toString();
    return useQuery({
        queryKey: ["search", params],
        queryFn: () => api.get(`/v1/search?${qs}`),
    });
}

// ── Property Detail (public) ──
export function usePropertyDetail(id: number | string) {
    return useQuery({
        queryKey: ["property", id],
        queryFn: () => api.get(`/v1/public/properties/${id}`),
        enabled: !!id,
    });
}

// ── Generic CRUD hook ──
export function useCrudList(resource: string, params?: Record<string, string>) {
    const qs = params ? new URLSearchParams(params).toString() : "";
    return useQuery({
        queryKey: [resource, "list", params],
        queryFn: () => api.get(`/v1/${resource}?${qs}`),
    });
}

export function useCrudDetail(resource: string, id: number | string) {
    return useQuery({
        queryKey: [resource, "detail", id],
        queryFn: () => api.get(`/v1/${resource}/${id}`),
        enabled: !!id,
    });
}

export function useCrudCreate(resource: string) {
    const qc = useQueryClient();
    return useMutation({
        mutationFn: (body: Record<string, unknown>) => api.post(`/v1/${resource}`, body),
        onSuccess: () => { qc.invalidateQueries({ queryKey: [resource] }); },
    });
}

export function useCrudUpdate(resource: string) {
    const qc = useQueryClient();
    return useMutation({
        mutationFn: ({ id, ...body }: Record<string, unknown> & { id: number | string }) =>
            api.put(`/v1/${resource}/${id}`, body),
        onSuccess: () => { qc.invalidateQueries({ queryKey: [resource] }); },
    });
}

export function useCrudDelete(resource: string) {
    const qc = useQueryClient();
    return useMutation({
        mutationFn: (id: number | string) => api.delete(`/v1/${resource}/${id}`),
        onSuccess: () => { qc.invalidateQueries({ queryKey: [resource] }); },
    });
}

// ── Auth ──
export function useLogin() {
    return useMutation({
        mutationFn: (data: { email: string; password: string }) => api.post("/v1/auth/login", data),
        onSuccess: (data: any) => {
            if (typeof window !== "undefined" && data.token) {
                localStorage.setItem("broker_token", data.token);
                localStorage.setItem("broker_user", JSON.stringify(data.user));
            }
        },
    });
}

export function useRegister() {
    return useMutation({
        mutationFn: (data: { email: string; password: string; first_name: string; last_name: string }) =>
            api.post("/v1/auth/register", data),
    });
}

// ── Bookings ──
export function useBookingStatusUpdate() {
    const qc = useQueryClient();
    return useMutation({
        mutationFn: ({ id, status, notes }: { id: number; status: string; notes?: string }) =>
            api.patch(`/v1/bookings/${id}/status`, { status, notes }),
        onSuccess: () => { qc.invalidateQueries({ queryKey: ["bookings"] }); },
    });
}

// ── Promotions ──
export function useValidatePromo(code: string) {
    return useQuery({
        queryKey: ["promo", code],
        queryFn: () => api.get(`/v1/promotions/validate/${code}`),
        enabled: code.length >= 3,
    });
}
