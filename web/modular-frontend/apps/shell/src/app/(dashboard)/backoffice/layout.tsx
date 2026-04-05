"use client";

import { useState, useCallback, useEffect } from "react";
import {
  Box,
  Typography,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Divider,
  IconButton,
  Tooltip,
  Stack,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Alert,
  useTheme,
} from "@mui/material";
import LockIcon from "@mui/icons-material/Lock";
import DashboardIcon from "@mui/icons-material/Dashboard";
import PeopleIcon from "@mui/icons-material/People";
import MoneyIcon from "@mui/icons-material/AttachMoney";
import StorageIcon from "@mui/icons-material/Storage";
import BackupIcon from "@mui/icons-material/Backup";
import DeleteIcon from "@mui/icons-material/Delete";
import BugIcon from "@mui/icons-material/BugReport";
import LogoutIcon from "@mui/icons-material/Logout";
import MenuOpenIcon from "@mui/icons-material/MenuOpen";
import MenuIcon from "@mui/icons-material/Menu";
import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@zentto/shared-auth";
import dynamic from "next/dynamic";
import { BackofficeProvider, useBackoffice } from "./context";

const TurnstileCaptcha = dynamic(
  () => import("@zentto/shared-auth").then((m) => ({ default: m.TurnstileCaptcha })),
  { ssr: false }
);

// ─── Constantes del sidebar ─────────────────────────────────────────────────

const SIDEBAR_WIDTH = 240;

const MENU_ITEMS = [
  { label: "Dashboard", icon: <DashboardIcon />, path: "/backoffice" },
  { label: "Tenants", icon: <PeopleIcon />, path: "/backoffice/tenants" },
  { label: "Planes y Licencias", icon: <MoneyIcon />, path: "/backoffice/planes" },
  { label: "Recursos", icon: <StorageIcon />, path: "/backoffice/recursos" },
  { label: "Respaldos", icon: <BackupIcon />, path: "/backoffice/respaldos" },
  { label: "Cola de Limpieza", icon: <DeleteIcon />, path: "/backoffice/limpieza" },
  { label: "Soporte", icon: <BugIcon />, path: "/backoffice/soporte" },
];

// ─── Modal de autenticacion 2FA — TOTP (Google Authenticator) ────────────────

type AuthStep = "key" | "totp" | "setup_qr" | "setup_confirm" | "regenerate_qr";

function AuthModal({ onAuth }: { onAuth: (token: string) => void }) {
  const [step, setStep] = useState<AuthStep>("key");
  const [masterKey, setMasterKey] = useState("");
  const [totpCode, setTotpCode] = useState("");
  const [setupSecret, setSetupSecret] = useState("");
  const [setupQr, setSetupQr] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [captchaToken, setCaptchaToken] = useState("");

  const base = process.env.NEXT_PUBLIC_API_URL ?? "/api";

  const handleMasterKey = async () => {
    if (!masterKey.trim()) { setError("Ingresa la Master Key"); return; }
    setLoading(true); setError("");
    try {
      const statusRes = await fetch(`${base}/v1/backoffice/auth/status`);
      const status = await statusRes.json();

      if (!status.setupDone) {
        const setupRes = await fetch(`${base}/v1/backoffice/auth/setup`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ masterKey: masterKey.trim(), captchaToken }),
        });
        const setup = await setupRes.json();
        if (!setupRes.ok) {
          setError(setupRes.status === 401 ? "Master Key incorrecta." : setup.error ?? "Error.");
          return;
        }
        setSetupSecret(setup.secret);
        setSetupQr(setup.qrDataUrl);
        setStep("setup_qr");
      } else {
        setStep("totp");
      }
    } catch {
      setError("Error de conexion con la API.");
    } finally {
      setLoading(false);
    }
  };

  const handleSetupConfirm = async () => {
    if (totpCode.length !== 6) { setError("El codigo debe tener 6 digitos"); return; }
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/setup/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), code: totpCode, secret: setupSecret }),
      });
      if (!res.ok) {
        setError("Codigo incorrecto. Verifica que la app este sincronizada.");
        return;
      }
      setStep("setup_confirm");
      await handleLogin();
    } catch {
      setError("Error de conexion.");
    } finally {
      setLoading(false);
    }
  };

  const handleRegenerate = async () => {
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/setup/regenerate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), captchaToken }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(res.status === 401 ? "Master Key incorrecta." : data.error ?? "Error.");
        return;
      }
      setSetupSecret(data.secret);
      setSetupQr(data.qrDataUrl);
      setTotpCode("");
      setStep("regenerate_qr");
    } catch {
      setError("Error de conexion.");
    } finally {
      setLoading(false);
    }
  };

  const handleRegenerateConfirm = async () => {
    if (totpCode.length !== 6) { setError("El codigo debe tener 6 digitos"); return; }
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/setup/regenerate/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), code: totpCode, secret: setupSecret }),
      });
      if (!res.ok) {
        setError("Codigo incorrecto. Verifica que escaneaste el nuevo QR.");
        return;
      }
      await handleLogin();
    } catch {
      setError("Error de conexion.");
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async () => {
    const code = totpCode;
    if (code.length !== 6) { setError("El codigo debe tener 6 digitos"); return; }
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), totpCode: code, captchaToken }),
      });
      const data = await res.json();
      if (!res.ok) {
        if (res.status === 429) setError("Demasiados intentos. Espera 15 minutos.");
        else if (res.status === 428) { setStep("setup_qr"); return; }
        else setError("Codigo incorrecto o expirado. Los codigos rotan cada 30s.");
        return;
      }
      onAuth(data.token);
    } catch {
      setError("Error de conexion.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open maxWidth="xs" fullWidth disableEscapeKeyDown>
      <DialogTitle>
        <Stack direction="row" alignItems="center" gap={1}>
          <LockIcon color="warning" />
          Backoffice{" "}
          {step === "key" && "-- Acceso"}
          {step === "totp" && "-- Verificacion 2FA"}
          {(step === "setup_qr" || step === "setup_confirm") && "-- Configurar 2FA"}
          {step === "regenerate_qr" && "-- Regenerar 2FA"}
        </Stack>
      </DialogTitle>

      <DialogContent>
        {step === "key" && (
          <>
            <Typography variant="body2" color="text.secondary" mb={2}>
              Seccion exclusiva para administradores del sistema Zentto.
            </Typography>
            <TextField
              label="Master Key"
              type="password"
              fullWidth
              value={masterKey}
              onChange={(e) => { setMasterKey(e.target.value); setError(""); }}
              onKeyDown={(e) => e.key === "Enter" && handleMasterKey()}
              error={!!error}
              helperText={error}
              autoFocus
              disabled={loading}
              sx={{ mb: 2 }}
            />
            <TurnstileCaptcha onTokenChange={setCaptchaToken} />
          </>
        )}

        {step === "setup_qr" && (
          <>
            <Alert severity="info" sx={{ mb: 2 }}>
              Primera configuracion de 2FA. Escanea el QR con Google Authenticator.
            </Alert>
            {setupQr && (
              <Box textAlign="center" mb={2}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={setupQr} alt="QR TOTP" width={200} height={200} style={{ borderRadius: 8 }} />
              </Box>
            )}
            <Typography variant="caption" color="text.secondary" display="block" mb={1}>
              Si no puedes escanear, ingresa este codigo manualmente en la app:
            </Typography>
            <Typography
              variant="body2"
              fontFamily="monospace"
              sx={{ bgcolor: "action.hover", p: 1, borderRadius: 1, wordBreak: "break-all", mb: 2 }}
            >
              {setupSecret}
            </Typography>
            <TextField
              label="Codigo de confirmacion (6 digitos)"
              type="text"
              fullWidth
              value={totpCode}
              onChange={(e) => { setTotpCode(e.target.value.replace(/\D/g, "").slice(0, 6)); setError(""); }}
              onKeyDown={(e) => e.key === "Enter" && handleSetupConfirm()}
              error={!!error}
              helperText={error || "Ingresa el codigo que muestra tu app para confirmar"}
              autoFocus
              disabled={loading}
              inputProps={{ maxLength: 6, style: { letterSpacing: "0.5em", fontSize: "1.4rem", textAlign: "center" } }}
            />
          </>
        )}

        {step === "totp" && (
          <>
            <Typography variant="body2" color="text.secondary" mb={2}>
              Abre <strong>Google Authenticator</strong> (o Authy / Bitwarden) e ingresa el
              codigo de 6 digitos de <strong>Zentto Backoffice</strong>.
            </Typography>
            <TextField
              label="Codigo TOTP"
              type="text"
              fullWidth
              value={totpCode}
              onChange={(e) => { setTotpCode(e.target.value.replace(/\D/g, "").slice(0, 6)); setError(""); }}
              onKeyDown={(e) => e.key === "Enter" && totpCode.length === 6 && handleLogin()}
              error={!!error}
              helperText={error || "El codigo rota cada 30 segundos"}
              autoFocus
              disabled={loading}
              inputProps={{ maxLength: 6, style: { letterSpacing: "0.5em", fontSize: "1.4rem", textAlign: "center" } }}
            />
            <Stack direction="row" justifyContent="space-between" mt={1}>
              <Button size="small" onClick={() => { setStep("key"); setTotpCode(""); setError(""); }}>
                Volver
              </Button>
              <Button size="small" color="warning" onClick={handleRegenerate} disabled={loading}>
                Perdi mi autenticador
              </Button>
            </Stack>
          </>
        )}

        {step === "regenerate_qr" && (
          <>
            <Alert severity="warning" sx={{ mb: 2 }}>
              Escanea este <strong>nuevo QR</strong> con Google Authenticator. El codigo anterior dejara de funcionar.
            </Alert>
            {setupQr && (
              <Box textAlign="center" mb={2}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={setupQr} alt="QR TOTP" width={200} height={200} style={{ borderRadius: 8 }} />
              </Box>
            )}
            <Typography variant="caption" color="text.secondary" display="block" mb={1}>
              Codigo manual:
            </Typography>
            <Typography
              variant="body2"
              fontFamily="monospace"
              sx={{ bgcolor: "action.hover", p: 1, borderRadius: 1, wordBreak: "break-all", mb: 2 }}
            >
              {setupSecret}
            </Typography>
            <TextField
              label="Codigo de confirmacion (6 digitos)"
              type="text"
              fullWidth
              value={totpCode}
              onChange={(e) => { setTotpCode(e.target.value.replace(/\D/g, "").slice(0, 6)); setError(""); }}
              onKeyDown={(e) => e.key === "Enter" && handleRegenerateConfirm()}
              error={!!error}
              helperText={error || "Ingresa el codigo del nuevo QR para confirmar"}
              autoFocus
              disabled={loading}
              inputProps={{ maxLength: 6, style: { letterSpacing: "0.5em", fontSize: "1.4rem", textAlign: "center" } }}
            />
          </>
        )}
      </DialogContent>

      <DialogActions>
        <Button
          variant="contained"
          disabled={loading}
          onClick={() => {
            if (step === "key") handleMasterKey();
            else if (step === "setup_qr") handleSetupConfirm();
            else if (step === "regenerate_qr") handleRegenerateConfirm();
            else if (step === "totp") handleLogin();
          }}
        >
          {loading ? "Verificando..." : step === "key" ? "Continuar" : (step === "setup_qr" || step === "regenerate_qr") ? "Confirmar" : "Ingresar"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

function BackofficeSidebar() {
  const router = useRouter();
  const pathname = usePathname();
  const theme = useTheme();
  const { clear } = useBackoffice();
  const isDark = theme.palette.mode === "dark";

  const isActive = (path: string) => {
    if (path === "/backoffice") return pathname === "/backoffice";
    return pathname.startsWith(path);
  };

  const sidebarBg = isDark ? "#1a1a2e" : "#1b2a4a";
  const activeColor = "#3b82f6";
  const hoverBg = isDark ? "rgba(255,255,255,0.06)" : "rgba(255,255,255,0.08)";

  return (
    <Box
      sx={{
        width: SIDEBAR_WIDTH,
        minWidth: SIDEBAR_WIDTH,
        minHeight: "100%",
        bgcolor: sidebarBg,
        color: "#fff",
        display: "flex",
        flexDirection: "column",
        borderRight: `1px solid ${isDark ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.1)"}`,
        borderRadius: "8px 0 0 8px",
      }}
    >
      {/* Header */}
      <Box sx={{ px: 2.5, py: 2.5, borderBottom: "1px solid rgba(255,255,255,0.1)" }}>
        <Stack direction="row" alignItems="center" gap={1.5}>
          <StorageIcon sx={{ color: activeColor, fontSize: 28 }} />
          <Box>
            <Typography variant="subtitle1" fontWeight={700} sx={{ lineHeight: 1.2 }}>
              ZENTTO
            </Typography>
            <Typography variant="caption" sx={{ color: "rgba(255,255,255,0.5)", letterSpacing: 1 }}>
              BACKOFFICE
            </Typography>
          </Box>
        </Stack>
      </Box>

      {/* Navigation */}
      <List sx={{ flex: 1, py: 1.5, px: 1 }}>
        {MENU_ITEMS.map((item) => {
          const active = isActive(item.path);
          return (
            <ListItem key={item.path} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton
                onClick={() => router.push(item.path)}
                sx={{
                  borderRadius: 1.5,
                  py: 1,
                  px: 2,
                  bgcolor: active ? `${activeColor}22` : "transparent",
                  borderLeft: active ? `3px solid ${activeColor}` : "3px solid transparent",
                  "&:hover": { bgcolor: active ? `${activeColor}33` : hoverBg },
                  transition: "all 0.15s ease",
                }}
              >
                <ListItemIcon
                  sx={{
                    color: active ? activeColor : "rgba(255,255,255,0.6)",
                    minWidth: 36,
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.label}
                  primaryTypographyProps={{
                    fontSize: "0.875rem",
                    fontWeight: active ? 600 : 400,
                    color: active ? "#fff" : "rgba(255,255,255,0.75)",
                  }}
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>

      {/* Footer */}
      <Divider sx={{ borderColor: "rgba(255,255,255,0.1)" }} />
      <Box sx={{ p: 1.5 }}>
        <ListItemButton
          onClick={clear}
          sx={{
            borderRadius: 1.5,
            py: 1,
            px: 2,
            "&:hover": { bgcolor: "rgba(255,100,100,0.15)" },
          }}
        >
          <ListItemIcon sx={{ color: "#ef5350", minWidth: 36 }}>
            <LogoutIcon />
          </ListItemIcon>
          <ListItemText
            primary="Cerrar sesion"
            primaryTypographyProps={{
              fontSize: "0.875rem",
              color: "rgba(255,255,255,0.7)",
            }}
          />
        </ListItemButton>
      </Box>
    </Box>
  );
}

// ─── Layout interior (protegido) ─────────────────────────────────────────────

function BackofficeInner({ children }: { children: React.ReactNode }) {
  const { isSet, save } = useBackoffice();
  const { isAdmin, isAuthenticated } = useAuth();

  if (!isSet) {
    return <AuthModal onAuth={save} />;
  }

  if (isAuthenticated && !isAdmin) {
    return (
      <Box
        display="flex"
        flexDirection="column"
        alignItems="center"
        justifyContent="center"
        minHeight="60vh"
        gap={2}
      >
        <LockIcon sx={{ fontSize: 64 }} color="error" />
        <Typography variant="h5" color="error">
          Acceso denegado
        </Typography>
        <Typography color="text.secondary">
          Esta seccion requiere el rol SYSADMIN.
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", minHeight: "calc(100vh - 64px)", mx: -3, mt: -3 }}>
      <BackofficeSidebar />
      <Box
        component="main"
        sx={{
          flex: 1,
          p: { xs: 2, md: 3 },
          overflow: "auto",
        }}
      >
        {children}
      </Box>
    </Box>
  );
}

// ─── Layout exportado ────────────────────────────────────────────────────────

export default function BackofficeLayout({ children }: { children: React.ReactNode }) {
  return (
    <BackofficeProvider>
      <BackofficeInner>{children}</BackofficeInner>
    </BackofficeProvider>
  );
}
