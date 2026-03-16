const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4100";

type FetchOptions = {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
};

export async function apiFetch<T = any>(path: string, opts: FetchOptions = {}): Promise<T> {
    const token = typeof window !== "undefined" ? localStorage.getItem("broker_token") : null;
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

// Convenience methods
export const api = {
    get: <T = any>(path: string) => apiFetch<T>(path),
    post: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "POST", body }),
    put: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "PUT", body }),
    patch: <T = any>(path: string, body: unknown) => apiFetch<T>(path, { method: "PATCH", body }),
    delete: <T = any>(path: string) => apiFetch<T>(path, { method: "DELETE" }),
};
