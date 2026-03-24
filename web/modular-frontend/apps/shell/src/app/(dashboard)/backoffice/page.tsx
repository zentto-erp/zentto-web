"use client";

import { useState, useEffect, useCallback } from "react";
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Card,
  CardContent,
  Chip,
  Button,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  LinearProgress,
  Alert,
  Tooltip,
  Stack,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Lock as LockIcon,
  Refresh as RefreshIcon,
  Storage as StorageIcon,
  People as PeopleIcon,
  AttachMoney as MoneyIcon,
  Delete as DeleteIcon,
  Backup as BackupIcon,
  Cancel as CancelIcon,
  Notifications as NotifyIcon,
  Warning as WarningIcon,
  CheckCircle as CheckIcon,
  Visibility as ViewIcon,
  PlayArrow as ApplyIcon,
} from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  ConfirmDialog,
} from "@zentto/shared-ui";
import { useAuth } from "@zentto/shared-auth";
import type { GridPaginationModel } from "@mui/x-data-grid";

// ─── Tipos ───────────────────────────────────────────────────────────────────

interface DashboardData {
  TotalTenants: number;
  MRR: number;
  TotalDbMB: number;
  CleanupPending: number;
}

interface TenantRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  Plan: string;
  LicenseType: string;
  LicenseStatus: string;
  ExpiresAt: string | null;
  UserCount: number;
  LastLogin: string | null;
}

interface ResourceRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  DbSizeMB: number;
  LastLoginAt: string | null;
  Status: string;
}

interface CleanupRow {
  id: number;
  QueueId: number;
  CompanyCode: string;
  LegalName: string;
  Reason: string;
  Status: string;
  FlaggedAt: string;
  DeleteAfter: string;
  DaysUntilDelete: number;
}

interface BackupRow {
  id: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  LastBackupAt: string | null;
  BackupSizeMB: number | null;
  BackupStatus: string;
}

// ─── Constantes ──────────────────────────────────────────────────────────────

const SESSION_KEY = "bo_session_token"; // session token JWT (no la master key)

const PLAN_OPTIONS = ["FREE", "STARTER", "PRO", "ENTERPRISE"];

const STATUS_COLORS: Record<
  string,
  "default" | "success" | "warning" | "error" | "info"
> = {
  ACTIVE: "success",
  INACTIVE: "default",
  SUSPENDED: "error",
  TRIAL: "warning",
  PENDING: "warning",
  NOTIFIED: "info",
  CONFIRMED: "error",
  CANCELLED: "default",
  OK: "success",
  FAILED: "error",
  RUNNING: "info",
};

// ─── Hook para Session Token (JWT emitido tras 2FA) ──────────────────────────

function useSessionToken() {
  const [token, setToken] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return sessionStorage.getItem(SESSION_KEY) ?? "";
    }
    return "";
  });

  const save = useCallback((t: string) => {
    sessionStorage.setItem(SESSION_KEY, t);
    setToken(t);
  }, []);

  const clear = useCallback(() => {
    sessionStorage.removeItem(SESSION_KEY);
    setToken("");
  }, []);

  return { token, save, clear, isSet: !!token };
}

// ─── Fetcher con Session Token ────────────────────────────────────────────────

async function apiFetch<T>(
  path: string,
  sessionToken: string,
  options: RequestInit = {}
): Promise<T> {
  const base = process.env.NEXT_PUBLIC_API_URL ?? "/api";
  const res = await fetch(`${base}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-Backoffice-Token": sessionToken,
      ...(options.headers ?? {}),
    },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`${res.status}: ${text || res.statusText}`);
  }
  return res.json() as Promise<T>;
}

// ─── Modal de autenticacion 2FA — TOTP (Google Authenticator) ────────────────

type AuthStep = "key" | "totp" | "setup_qr" | "setup_confirm";

function AuthModal({ onAuth }: { onAuth: (token: string) => void }) {
  const [step, setStep] = useState<AuthStep>("key");
  const [masterKey, setMasterKey] = useState("");
  const [totpCode, setTotpCode] = useState("");
  const [setupSecret, setSetupSecret] = useState("");
  const [setupQr, setSetupQr] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const base = process.env.NEXT_PUBLIC_API_URL ?? "/api";

  // Paso 1 → verificar Master Key, luego ver si hay TOTP configurado
  const handleMasterKey = async () => {
    if (!masterKey.trim()) { setError("Ingresa la Master Key"); return; }
    setLoading(true); setError("");
    try {
      // Verificar status del TOTP
      const statusRes = await fetch(`${base}/v1/backoffice/auth/status`);
      const status = await statusRes.json();

      if (!status.setupDone) {
        // Primera vez → iniciar setup TOTP
        const setupRes = await fetch(`${base}/v1/backoffice/auth/setup`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ masterKey: masterKey.trim() }),
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
        // TOTP ya configurado → pedir código
        setStep("totp");
      }
    } catch {
      setError("Error de conexion con la API.");
    } finally {
      setLoading(false);
    }
  };

  // Paso 2a (setup) → confirmar primer código TOTP
  const handleSetupConfirm = async () => {
    if (totpCode.length !== 6) { setError("El codigo debe tener 6 digitos"); return; }
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/setup/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), code: totpCode, secret: setupSecret }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError("Codigo incorrecto. Verifica que la app este sincronizada.");
        return;
      }
      // Setup confirmado → mostrar instrucción de guardar en env y continuar
      setStep("setup_confirm");
      // Intentar login inmediatamente tras el setup
      await handleLogin(data.secret);
    } catch {
      setError("Error de conexion.");
    } finally {
      setLoading(false);
    }
  };

  // Paso 2b (login normal) → verificar código TOTP
  const handleLogin = async (secretOverride?: string) => {
    const code = secretOverride ? totpCode : totpCode;
    if (code.length !== 6) { setError("El codigo debe tener 6 digitos"); return; }
    setLoading(true); setError("");
    try {
      const res = await fetch(`${base}/v1/backoffice/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ masterKey: masterKey.trim(), totpCode: code }),
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
          {step === "key" && "— Acceso"}
          {step === "totp" && "— Verificacion 2FA"}
          {(step === "setup_qr" || step === "setup_confirm") && "— Configurar 2FA"}
        </Stack>
      </DialogTitle>

      <DialogContent>
        {/* ── Paso 1: Master Key ── */}
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
            />
          </>
        )}

        {/* ── Paso 2a: Setup QR ── */}
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

        {/* ── Paso 2b: Login TOTP ── */}
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
            <Button size="small" sx={{ mt: 1 }} onClick={() => { setStep("key"); setTotpCode(""); setError(""); }}>
              Volver
            </Button>
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
            else if (step === "totp") handleLogin();
          }}
        >
          {loading ? "Verificando..." : step === "key" ? "Continuar" : step === "setup_qr" ? "Activar 2FA" : "Ingresar"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Dashboard Cards ──────────────────────────────────────────────────────────

function DashboardCards({
  data,
  loading,
}: {
  data: DashboardData | null;
  loading: boolean;
}) {
  const cards = [
    {
      label: "Total Tenants",
      value: data?.TotalTenants ?? "—",
      icon: <PeopleIcon fontSize="large" color="primary" />,
    },
    {
      label: "MRR Estimado",
      value: data ? `$${Number(data.MRR).toLocaleString("es-VE")}` : "—",
      icon: <MoneyIcon fontSize="large" color="success" />,
    },
    {
      label: "BD Total (MB)",
      value: data ? `${Number(data.TotalDbMB).toFixed(1)} MB` : "—",
      icon: <StorageIcon fontSize="large" color="info" />,
    },
    {
      label: "Cola Pendiente",
      value: data?.CleanupPending ?? "—",
      icon: <WarningIcon fontSize="large" color="warning" />,
    },
  ];

  return (
    <Grid container spacing={2} mb={3}>
      {cards.map((c) => (
        <Grid key={c.label} size={{ xs: 12, sm: 6, md: 3 }}>
          <Card variant="outlined">
            <CardContent>
              <Stack
                direction="row"
                justifyContent="space-between"
                alignItems="center"
              >
                <Box>
                  <Typography variant="caption" color="text.secondary">
                    {c.label}
                  </Typography>
                  {loading ? (
                    <LinearProgress sx={{ mt: 1, width: 80 }} />
                  ) : (
                    <Typography variant="h5" fontWeight={700}>
                      {c.value}
                    </Typography>
                  )}
                </Box>
                {c.icon}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}

// ─── Modal: Aplicar Plan ──────────────────────────────────────────────────────

function ApplyPlanModal({
  open,
  tenant,
  masterKey,
  onClose,
  onSuccess,
}: {
  open: boolean;
  tenant: TenantRow | null;
  masterKey: string;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [plan, setPlan] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (open && tenant) setPlan(tenant.Plan ?? "");
  }, [open, tenant]);

  const handleApply = async () => {
    if (!plan) return;
    setLoading(true);
    setError("");
    try {
      await apiFetch(
        `/v1/backoffice/tenants/${tenant!.CompanyId}/apply-plan`,
        masterKey,
        { method: "POST", body: JSON.stringify({ plan }) }
      );
      onSuccess();
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>Aplicar Plan — {tenant?.LegalName}</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}
        <FormControl fullWidth sx={{ mt: 1 }}>
          <InputLabel>Plan</InputLabel>
          <Select
            value={plan}
            label="Plan"
            onChange={(e) => setPlan(e.target.value)}
          >
            {PLAN_OPTIONS.map((p) => (
              <MenuItem key={p} value={p}>
                {p}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={loading}>
          Cancelar
        </Button>
        <Button
          variant="contained"
          onClick={handleApply}
          disabled={loading || !plan}
        >
          Aplicar
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Tab: Tenants ─────────────────────────────────────────────────────────────

function TenantsTab({ masterKey }: { masterKey: string }) {
  const [rows, setRows] = useState<TenantRow[]>([]);
  const [rowCount, setRowCount] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [pagination, setPagination] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 20,
  });
  const [applyTarget, setApplyTarget] = useState<TenantRow | null>(null);
  const [applyOpen, setApplyOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<{ rows: Record<string, unknown>[]; totalCount: number }>(
        `/v1/backoffice/tenants?page=${pagination.page + 1}&pageSize=${pagination.pageSize}`,
        masterKey
      );
      const mapped: TenantRow[] = (res.rows ?? []).map((r, i) => ({
        id: i,
        CompanyId: r.CompanyId as number,
        CompanyCode: r.CompanyCode as string,
        LegalName: r.LegalName as string,
        Plan: r.Plan as string,
        LicenseType: r.LicenseType as string,
        LicenseStatus: r.LicenseStatus as string,
        ExpiresAt: (r.ExpiresAt as string) ?? null,
        UserCount: r.UserCount as number,
        LastLogin: (r.LastLogin as string) ?? null,
      }));
      setRows(mapped);
      setRowCount(res.totalCount ?? mapped.length);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [masterKey, pagination]);

  useEffect(() => {
    load();
  }, [load]);

  const columns: ZenttoColDef[] = [
    { field: "CompanyCode", headerName: "Codigo", width: 110 },
    { field: "LegalName", headerName: "Empresa", flex: 1, minWidth: 180 },
    {
      field: "Plan",
      headerName: "Plan",
      width: 120,
      renderCell: ({ value }) => (
        <Chip
          label={value as string}
          size="small"
          color={value === "FREE" ? "default" : "primary"}
        />
      ),
    },
    { field: "LicenseType", headerName: "Tipo Lic.", width: 120 },
    {
      field: "LicenseStatus",
      headerName: "Estado",
      width: 120,
      renderCell: ({ value }) => (
        <Chip
          label={value as string}
          size="small"
          color={STATUS_COLORS[value as string] ?? "default"}
        />
      ),
    },
    {
      field: "ExpiresAt",
      headerName: "Vence",
      width: 130,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleDateString("es-VE") : "—",
    },
    { field: "UserCount", headerName: "Usuarios", width: 100, type: "number" },
    {
      field: "LastLogin",
      headerName: "Ultimo Acceso",
      width: 150,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleString("es-VE") : "—",
    },
    {
      field: "__actions",
      headerName: "Acciones",
      width: 130,
      sortable: false,
      renderCell: ({ row }) => (
        <Stack direction="row" gap={0.5}>
          <Tooltip title="Ver detalle">
            <IconButton size="small" color="info">
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Aplicar plan">
            <IconButton
              size="small"
              color="primary"
              onClick={() => {
                setApplyTarget(row as TenantRow);
                setApplyOpen(true);
              }}
            >
              <ApplyIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      <Stack direction="row" justifyContent="flex-end" mb={1}>
        <Button startIcon={<RefreshIcon />} onClick={load} disabled={loading}>
          Actualizar
        </Button>
      </Stack>
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={loading}
        paginationModel={pagination}
        onPaginationModelChange={setPagination}
        rowCount={rowCount}
        paginationMode="server"
        autoHeight
      />
      <ApplyPlanModal
        open={applyOpen}
        tenant={applyTarget}
        masterKey={masterKey}
        onClose={() => setApplyOpen(false)}
        onSuccess={load}
      />
    </Box>
  );
}

// ─── Tab: Recursos ────────────────────────────────────────────────────────────

const MAX_DB_MB = 10240; // 10 GB referencia visual

function RecursosTab({ masterKey }: { masterKey: string }) {
  const [rows, setRows] = useState<ResourceRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<Record<string, unknown>[]>(
        "/v1/backoffice/resources",
        masterKey
      );
      const mapped: ResourceRow[] = (res ?? []).map((r, i) => ({
        id: i,
        CompanyId: r.CompanyId as number,
        CompanyCode: r.CompanyCode as string,
        LegalName: r.LegalName as string,
        DbSizeMB: Number(r.DbSizeMB ?? 0),
        LastLoginAt: (r.LastLoginAt as string) ?? null,
        Status: r.Status as string,
      }));
      setRows(mapped);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [masterKey]);

  useEffect(() => {
    load();
  }, [load]);

  const columns: ZenttoColDef[] = [
    { field: "CompanyCode", headerName: "Codigo", width: 110 },
    { field: "LegalName", headerName: "Empresa", flex: 1, minWidth: 180 },
    {
      field: "DbSizeMB",
      headerName: "BD (MB)",
      width: 210,
      type: "number",
      renderCell: ({ value }) => {
        const mb = value as number;
        const pct = Math.min(100, (mb / MAX_DB_MB) * 100);
        const color: "error" | "warning" | "primary" =
          pct > 80 ? "error" : pct > 50 ? "warning" : "primary";
        return (
          <Box width="100%">
            <Typography variant="caption">{mb.toFixed(1)} MB</Typography>
            <LinearProgress
              variant="determinate"
              value={pct}
              color={color}
              sx={{ mt: 0.5, height: 6, borderRadius: 1 }}
            />
          </Box>
        );
      },
    },
    {
      field: "LastLoginAt",
      headerName: "Ultimo Acceso",
      width: 160,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleString("es-VE") : "—",
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      renderCell: ({ value }) => (
        <Chip
          label={value as string}
          size="small"
          color={STATUS_COLORS[value as string] ?? "default"}
        />
      ),
    },
  ];

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      <Stack direction="row" justifyContent="flex-end" mb={1}>
        <Button startIcon={<RefreshIcon />} onClick={load} disabled={loading}>
          Actualizar
        </Button>
      </Stack>
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={loading}
        autoHeight
      />
    </Box>
  );
}

// ─── Tab: Cola de limpieza ────────────────────────────────────────────────────

function CleanupTab({ masterKey }: { masterKey: string }) {
  const [rows, setRows] = useState<CleanupRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [scanLoading, setScanLoading] = useState(false);
  const [error, setError] = useState("");
  const [confirmAction, setConfirmAction] = useState<{
    queueId: number;
    action: string;
    label: string;
  } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<Record<string, unknown>[]>(
        "/v1/backoffice/cleanup?status=PENDING",
        masterKey
      );
      const mapped: CleanupRow[] = (res ?? []).map((r, i) => ({
        id: i,
        QueueId: r.QueueId as number,
        CompanyCode: r.CompanyCode as string,
        LegalName: r.LegalName as string,
        Reason: r.Reason as string,
        Status: r.Status as string,
        FlaggedAt: r.FlaggedAt as string,
        DeleteAfter: r.DeleteAfter as string,
        DaysUntilDelete: r.DaysUntilDelete as number,
      }));
      setRows(mapped);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [masterKey]);

  useEffect(() => {
    load();
  }, [load]);

  const handleScan = async () => {
    setScanLoading(true);
    try {
      await apiFetch("/v1/backoffice/cleanup/scan", masterKey, {
        method: "POST",
      });
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setScanLoading(false);
    }
  };

  const handleAction = async (queueId: number, action: string) => {
    try {
      await apiFetch(
        `/v1/backoffice/cleanup/${queueId}/action`,
        masterKey,
        {
          method: "POST",
          body: JSON.stringify({ action }),
        }
      );
      setConfirmAction(null);
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
      setConfirmAction(null);
    }
  };

  const columns: ZenttoColDef[] = [
    { field: "CompanyCode", headerName: "Codigo", width: 110 },
    { field: "LegalName", headerName: "Empresa", flex: 1, minWidth: 160 },
    { field: "Reason", headerName: "Razon", width: 160 },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      renderCell: ({ value }) => (
        <Chip
          label={value as string}
          size="small"
          color={STATUS_COLORS[value as string] ?? "default"}
        />
      ),
    },
    {
      field: "FlaggedAt",
      headerName: "Marcado",
      width: 130,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleDateString("es-VE") : "—",
    },
    {
      field: "DeleteAfter",
      headerName: "Eliminar tras",
      width: 130,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleDateString("es-VE") : "—",
    },
    {
      field: "DaysUntilDelete",
      headerName: "Dias restantes",
      width: 130,
      type: "number",
      renderCell: ({ value }) => (
        <Typography
          variant="body2"
          color={(value as number) <= 3 ? "error" : "text.primary"}
          fontWeight={(value as number) <= 3 ? 700 : 400}
        >
          {value as number} dia(s)
        </Typography>
      ),
    },
    {
      field: "__actions",
      headerName: "Acciones",
      width: 200,
      sortable: false,
      renderCell: ({ row }) => {
        const r = row as CleanupRow;
        return (
          <Stack direction="row" gap={0.5}>
            <Tooltip title="Cancelar">
              <IconButton
                size="small"
                color="success"
                onClick={() =>
                  setConfirmAction({
                    queueId: r.QueueId,
                    action: "CANCEL",
                    label: "Cancelar la eliminacion de este tenant?",
                  })
                }
              >
                <CancelIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title="Notificar">
              <IconButton
                size="small"
                color="info"
                onClick={() =>
                  setConfirmAction({
                    queueId: r.QueueId,
                    action: "NOTIFY",
                    label: "Enviar notificacion de eliminacion al tenant?",
                  })
                }
              >
                <NotifyIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title="Confirmar eliminacion">
              <IconButton
                size="small"
                color="error"
                onClick={() =>
                  setConfirmAction({
                    queueId: r.QueueId,
                    action: "CONFIRM_DELETE",
                    label:
                      "Confirmar eliminacion permanente? Esta accion no puede deshacerse.",
                  })
                }
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Stack>
        );
      },
    },
  ];

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      <Stack direction="row" gap={1} justifyContent="flex-end" mb={1}>
        <Button startIcon={<RefreshIcon />} onClick={load} disabled={loading}>
          Actualizar
        </Button>
        <Button
          variant="outlined"
          color="warning"
          startIcon={<WarningIcon />}
          onClick={handleScan}
          disabled={scanLoading}
        >
          {scanLoading ? "Escaneando..." : "Escanear ahora"}
        </Button>
      </Stack>
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={loading}
        autoHeight
      />
      <ConfirmDialog
        open={!!confirmAction}
        title="Confirmar accion"
        message={confirmAction?.label ?? ""}
        onConfirm={() =>
          confirmAction &&
          handleAction(confirmAction.queueId, confirmAction.action)
        }
        onCancel={() => setConfirmAction(null)}
      />
    </Box>
  );
}

// ─── Tab: Respaldos ───────────────────────────────────────────────────────────

function RespaldosTab({ masterKey }: { masterKey: string }) {
  const [rows, setRows] = useState<BackupRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [backupTarget, setBackupTarget] = useState<BackupRow | null>(null);
  const [backupConfirmOpen, setBackupConfirmOpen] = useState(false);
  const [backupLoading, setBackupLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<{ rows: Record<string, unknown>[] }>(
        "/v1/backoffice/tenants?page=1&pageSize=200",
        masterKey
      );
      const mapped: BackupRow[] = (res.rows ?? []).map((r, i) => ({
        id: i,
        CompanyId: r.CompanyId as number,
        CompanyCode: r.CompanyCode as string,
        LegalName: r.LegalName as string,
        LastBackupAt: (r.LastBackupAt as string) ?? null,
        BackupSizeMB: r.BackupSizeMB != null ? Number(r.BackupSizeMB) : null,
        BackupStatus: (r.BackupStatus as string) ?? "UNKNOWN",
      }));
      setRows(mapped);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [masterKey]);

  useEffect(() => {
    load();
  }, [load]);

  const handleBackup = async () => {
    if (!backupTarget) return;
    setBackupLoading(true);
    try {
      await apiFetch(
        `/v1/backoffice/tenants/${backupTarget.CompanyId}/backup`,
        masterKey,
        { method: "POST" }
      );
      setBackupConfirmOpen(false);
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
      setBackupConfirmOpen(false);
    } finally {
      setBackupLoading(false);
    }
  };

  const columns: ZenttoColDef[] = [
    { field: "CompanyCode", headerName: "Codigo", width: 110 },
    { field: "LegalName", headerName: "Empresa", flex: 1, minWidth: 180 },
    {
      field: "LastBackupAt",
      headerName: "Ultimo Respaldo",
      width: 170,
      valueFormatter: ({ value }) =>
        value ? new Date(value as string).toLocaleString("es-VE") : "Sin respaldo",
    },
    {
      field: "BackupSizeMB",
      headerName: "Tamano (MB)",
      width: 130,
      type: "number",
      valueFormatter: ({ value }) =>
        value != null ? `${Number(value).toFixed(1)} MB` : "—",
    },
    {
      field: "BackupStatus",
      headerName: "Estado",
      width: 130,
      renderCell: ({ value }) => (
        <Chip
          label={value as string}
          size="small"
          color={STATUS_COLORS[value as string] ?? "default"}
          icon={
            value === "OK" ? (
              <CheckIcon fontSize="small" />
            ) : value === "FAILED" ? (
              <WarningIcon fontSize="small" />
            ) : undefined
          }
        />
      ),
    },
    {
      field: "__actions",
      headerName: "Acciones",
      width: 130,
      sortable: false,
      renderCell: ({ row }) => (
        <Tooltip title="Crear respaldo">
          <IconButton
            size="small"
            color="primary"
            onClick={() => {
              setBackupTarget(row as BackupRow);
              setBackupConfirmOpen(true);
            }}
          >
            <BackupIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ];

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      <Stack direction="row" justifyContent="flex-end" mb={1}>
        <Button startIcon={<RefreshIcon />} onClick={load} disabled={loading}>
          Actualizar
        </Button>
      </Stack>
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={loading}
        autoHeight
      />
      <ConfirmDialog
        open={backupConfirmOpen}
        title="Crear respaldo"
        message={`Crear un respaldo manual para ${backupTarget?.LegalName}? El proceso puede tardar algunos minutos.`}
        onConfirm={handleBackup}
        onCancel={() => setBackupConfirmOpen(false)}
        confirmLabel={backupLoading ? "Creando..." : "Crear respaldo"}
      />
    </Box>
  );
}

// ─── Pagina principal ─────────────────────────────────────────────────────────

export default function BackofficePage() {
  const { user } = useAuth();
  const { token, save, clear, isSet } = useSessionToken();
  const [tab, setTab] = useState(0);
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [dashLoading, setDashLoading] = useState(false);

  const isSysAdmin =
    (user as Record<string, unknown> | null)?.role === "SYSADMIN" ||
    ((user as Record<string, unknown> | null)?.roles as string[] | undefined)?.includes(
      "SYSADMIN"
    );

  const loadDashboard = useCallback(async () => {
    if (!isSet) return;
    setDashLoading(true);
    try {
      const res = await apiFetch<DashboardData>(
        "/v1/backoffice/dashboard",
        token
      );
      setDashboard(res);
    } catch (e: unknown) {
      // Si el token expiró, limpiar sesión y volver al login
      if (e instanceof Error && e.message.startsWith("401")) {
        clear();
      }
    } finally {
      setDashLoading(false);
    }
  }, [isSet, token, clear]);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  if (!isSet) {
    return <AuthModal onAuth={save} />;
  }

  if (user && !isSysAdmin) {
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
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      <Stack direction="row" alignItems="center" gap={1} mb={2}>
        <StorageIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Backoffice
        </Typography>
        <Chip label="SYSADMIN" size="small" color="warning" sx={{ ml: 1 }} />
        <Box flex={1} />
        <Tooltip title="Refrescar dashboard">
          <IconButton onClick={loadDashboard} disabled={dashLoading}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
        <Tooltip title="Cerrar sesion backoffice">
          <IconButton onClick={clear} color="warning">
            <LockIcon />
          </IconButton>
        </Tooltip>
      </Stack>

      <DashboardCards data={dashboard} loading={dashLoading} />

      <Box sx={{ borderBottom: 1, borderColor: "divider", mb: 2 }}>
        <Tabs value={tab} onChange={(_, v: number) => setTab(v)}>
          <Tab label="Tenants" />
          <Tab label="Recursos" />
          <Tab label="Cola de limpieza" />
          <Tab label="Respaldos" />
        </Tabs>
      </Box>

      {tab === 0 && <TenantsTab masterKey={token} />}
      {tab === 1 && <RecursosTab masterKey={token} />}
      {tab === 2 && <CleanupTab masterKey={token} />}
      {tab === 3 && <RespaldosTab masterKey={token} />}
    </Box>
  );
}
