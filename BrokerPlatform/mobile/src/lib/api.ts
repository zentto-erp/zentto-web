import { Platform } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";

// React Native (Android Emulator) usa 10.0.2.2 para acceder a localhost.
// iOS usa localhost normal.
const LOCAL_IP = Platform.OS === "android" ? "10.0.2.2" : "localhost";
const API_URL = `http://${LOCAL_IP}:4100`;

type FetchOptions = {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
};

export async function apiFetch<T = any>(path: string, opts: FetchOptions = {}): Promise<T> {
    const token = await AsyncStorage.getItem("broker_token");
    const headers: Record<string, string> = {
        "Content-Type": "application/json",
        ...opts.headers,
    };
    if (token) headers["Authorization"] = `Bearer ${token}`;

    const res = await fetch(`${API_URL}${path}`, {
        method: opts.method || "GET",
        headers,
        body: opts.body ? JSON.stringify(opts.body) : undefined,
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({ error: res.statusText }));
        throw new Error(err.error || err.message || `API error ${res.status}`);
    }

    return res.json();
}

export const api = {
    get: <T = any>(path: string) => apiFetch<T>(path),
    post: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "POST", body }),
    put: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "PUT", body }),
    patch: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "PATCH", body }),
    delete: <T = any>(path: string) => apiFetch<T>(path, { method: "DELETE" }),
};
