import { useQuery, useMutation } from "@tanstack/react-query";
import { api } from "../lib/api";
import AsyncStorage from "@react-native-async-storage/async-storage";

export function useSearch(params: Record<string, string>) {
    const qs = new URLSearchParams(params).toString();
    return useQuery({
        queryKey: ["search", params],
        queryFn: () => api.get(`/v1/search?${qs}`),
    });
}

export function usePropertyDetail(id: number | string) {
    return useQuery({
        queryKey: ["property", id],
        queryFn: () => api.get(`/v1/public/properties/${id}`),
        enabled: !!id,
    });
}

export function useLogin() {
    return useMutation({
        mutationFn: (data: { email: string; password: string }) => api.post("/v1/auth/login", data),
        onSuccess: async (data: any) => {
            if (data.token) {
                await AsyncStorage.setItem("broker_token", data.token);
                await AsyncStorage.setItem("broker_user", JSON.stringify(data.user));
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
