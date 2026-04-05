"use client";

import React, { useState } from "react";
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  Link,
  CircularProgress,
} from "@mui/material";
import { setUser } from "../../lib/auth";

const API_BASE = process.env.NEXT_PUBLIC_SITES_API || "http://localhost:4500";

export default function LoginPage() {
  const [usuario, setUsuario] = useState("");
  const [clave, setClave] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState<"login" | "forgot">("login");
  const [forgotSent, setForgotSent] = useState(false);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: "POST",
        credentials: "include",  // Recibe cookie HttpOnly
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: usuario.toUpperCase(), password: clave }),
      });
      const data = await res.json();

      if (!res.ok || data.error) {
        setError(data.message || data.error || "Credenciales incorrectas");
        return;
      }

      // Token esta en cookie HttpOnly — NO en JavaScript
      // Solo guardamos el perfil del usuario (no sensible)
      setUser(data.data?.user || { usuario });

      // Redirect to dashboard
      window.location.href = "/";
    } catch (err: any) {
      setError(err.message || "Error de conexion");
    } finally {
      setLoading(false);
    }
  }

  async function handleForgotPassword(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch(`${API_BASE}/auth/forgot-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();

      if (!res.ok && !data.ok) {
        setError(data.message || "Error al enviar email");
        return;
      }

      setForgotSent(true);
    } catch (err: any) {
      setError(err.message || "Error de conexion");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        bgcolor: "#f1f5f9",
        p: 2,
      }}
    >
      <Card
        elevation={0}
        sx={{
          width: "100%",
          maxWidth: 420,
          borderRadius: 3,
          border: "1px solid #e2e8f0",
        }}
      >
        <CardContent sx={{ p: 4 }}>
          {/* Logo */}
          <Box sx={{ display: "flex", justifyContent: "center", mb: 3 }}>
            <Box
              sx={{
                width: 52,
                height: 52,
                borderRadius: 3,
                background: "linear-gradient(135deg, #6366f1, #8b5cf6)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontWeight: 800,
                fontSize: 24,
              }}
            >
              Z
            </Box>
          </Box>

          <Typography
            variant="h5"
            sx={{
              textAlign: "center",
              fontWeight: 700,
              color: "#1e293b",
              mb: 0.5,
            }}
          >
            {mode === "login" ? "Zentto Panel" : "Recuperar contrasena"}
          </Typography>
          <Typography
            variant="body2"
            sx={{ textAlign: "center", color: "#64748b", mb: 3 }}
          >
            {mode === "login"
              ? "Inicia sesion para gestionar tus sitios"
              : "Te enviaremos un email con instrucciones"}
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>
              {error}
            </Alert>
          )}

          {mode === "forgot" && forgotSent ? (
            <Box sx={{ textAlign: "center" }}>
              <Alert severity="success" sx={{ mb: 2, borderRadius: 2 }}>
                Se ha enviado un email con instrucciones para restablecer tu contrasena.
              </Alert>
              <Link
                component="button"
                variant="body2"
                onClick={() => {
                  setMode("login");
                  setForgotSent(false);
                  setError("");
                }}
                sx={{ color: "#6366f1", cursor: "pointer" }}
              >
                Volver al inicio de sesion
              </Link>
            </Box>
          ) : (
            <Box
              component="form"
              onSubmit={mode === "login" ? handleLogin : handleForgotPassword}
            >
              <TextField
                fullWidth
                label="Usuario"
                type="text"
                value={usuario}
                onChange={(e) => setUsuario(e.target.value)}
                required
                autoComplete="username"
                placeholder="ej: admin.demo"
                sx={{ mb: 2 }}
                size="small"
              />

              {mode === "login" && (
                <TextField
                  fullWidth
                  label="Contrasena"
                  type="password"
                  value={clave}
                  onChange={(e) => setClave(e.target.value)}
                  required
                  autoComplete="current-password"
                  sx={{ mb: 3 }}
                  size="small"
                />
              )}

              <Button
                type="submit"
                variant="contained"
                fullWidth
                disabled={loading}
                sx={{
                  py: 1.2,
                  textTransform: "none",
                  fontWeight: 600,
                  borderRadius: 2,
                  bgcolor: "#6366f1",
                  "&:hover": { bgcolor: "#4f46e5" },
                  mb: 2,
                }}
              >
                {loading ? (
                  <CircularProgress size={22} sx={{ color: "#fff" }} />
                ) : mode === "login" ? (
                  "Iniciar sesion"
                ) : (
                  "Enviar instrucciones"
                )}
              </Button>

              {mode === "login" ? (
                <Box
                  sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                  }}
                >
                  <Link
                    component="button"
                    type="button"
                    variant="body2"
                    onClick={() => {
                      setMode("forgot");
                      setError("");
                    }}
                    sx={{ color: "#6366f1", cursor: "pointer", fontSize: 13 }}
                  >
                    Olvidaste tu contrasena?
                  </Link>
                  <Link
                    href="/register"
                    variant="body2"
                    sx={{ color: "#6366f1", fontSize: 13 }}
                  >
                    Registrarse
                  </Link>
                </Box>
              ) : (
                <Box sx={{ textAlign: "center" }}>
                  <Link
                    component="button"
                    type="button"
                    variant="body2"
                    onClick={() => {
                      setMode("login");
                      setError("");
                    }}
                    sx={{ color: "#6366f1", cursor: "pointer", fontSize: 13 }}
                  >
                    Volver al inicio de sesion
                  </Link>
                </Box>
              )}
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
