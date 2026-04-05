"use client";

import React, { useState } from "react";

const SITES_API = process.env.NEXT_PUBLIC_SITES_API || "https://sitesdev.zentto.net";

export default function LoginPage() {
  const [usuario, setUsuario] = useState("");
  const [clave, setClave] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    if (!usuario.trim() || !clave.trim()) {
      setError("Ingresa usuario y contrasena");
      return;
    }
    setError("");
    setLoading(true);

    try {
      const res = await fetch(`${SITES_API}/auth/login`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: usuario.trim().toUpperCase(), password: clave }),
      });

      const text = await res.text();
      let data: any;
      try { data = JSON.parse(text); } catch { data = { error: text }; }

      if (!res.ok || data.error) {
        setError(data.message || data.error || "Credenciales incorrectas");
        setLoading(false);
        return;
      }

      if (data.user || data.data?.user) {
        sessionStorage.setItem("zentto-panel-user", JSON.stringify(data.user || data.data.user));
      }

      window.location.href = "/";
    } catch (err: any) {
      setError("Error de conexion. Intenta de nuevo.");
      setLoading(false);
    }
  }

  return (
    <div style={{
      minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center",
      background: "linear-gradient(135deg, #f8fafc 0%, #eef2ff 100%)",
      fontFamily: "Inter, system-ui, -apple-system, sans-serif", padding: 20,
    }}>
      <div style={{
        width: "100%", maxWidth: 380, background: "#fff", borderRadius: 20,
        padding: "40px 32px", boxShadow: "0 8px 32px rgba(99,102,241,0.12)",
      }}>
        <div style={{ textAlign: "center", marginBottom: 28 }}>
          <div style={{
            width: 60, height: 60, borderRadius: 16,
            background: "linear-gradient(135deg, #6366f1, #8b5cf6)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
            color: "#fff", fontSize: 30, fontWeight: 800, marginBottom: 16,
          }}>Z</div>
          <h1 style={{ fontSize: 22, fontWeight: 700, margin: "0 0 6px", color: "#1e293b" }}>Zentto Panel</h1>
          <p style={{ color: "#94a3b8", fontSize: 14, margin: 0 }}>Gestiona tus sitios web</p>
        </div>

        {error && (
          <div style={{
            background: "#fef2f2", color: "#dc2626", padding: "10px 14px",
            borderRadius: 10, fontSize: 13, marginBottom: 16, lineHeight: 1.4,
          }}>{error}</div>
        )}

        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: 14 }}>
            <label style={{ display: "block", fontSize: 13, color: "#475569", marginBottom: 6, fontWeight: 500 }}>Usuario</label>
            <input
              type="text"
              value={usuario}
              onChange={(e) => setUsuario(e.target.value)}
              placeholder="ej: admin.demo"
              required
              autoComplete="username"
              autoFocus
              style={{
                width: "100%", padding: "11px 14px", border: "2px solid #e2e8f0",
                borderRadius: 10, fontSize: 15, outline: "none", boxSizing: "border-box",
              }}
            />
          </div>
          <div style={{ marginBottom: 22 }}>
            <label style={{ display: "block", fontSize: 13, color: "#475569", marginBottom: 6, fontWeight: 500 }}>Contrasena</label>
            <input
              type="password"
              value={clave}
              onChange={(e) => setClave(e.target.value)}
              required
              autoComplete="current-password"
              style={{
                width: "100%", padding: "11px 14px", border: "2px solid #e2e8f0",
                borderRadius: 10, fontSize: 15, outline: "none", boxSizing: "border-box",
              }}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            style={{
              width: "100%", padding: "13px", border: "none", borderRadius: 12,
              fontSize: 15, fontWeight: 600, cursor: loading ? "wait" : "pointer",
              background: loading ? "#a5b4fc" : "linear-gradient(135deg, #6366f1, #8b5cf6)",
              color: "#fff", boxShadow: "0 4px 12px rgba(99,102,241,0.3)",
            }}
          >{loading ? "Verificando..." : "Iniciar sesion"}</button>
        </form>

        <p style={{ textAlign: "center", marginTop: 20, fontSize: 12, color: "#94a3b8" }}>
          Zentto Sites &copy; 2026
        </p>
      </div>
    </div>
  );
}
