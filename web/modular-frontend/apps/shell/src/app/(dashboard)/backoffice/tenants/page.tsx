"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Stack,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  CircularProgress,
} from "@mui/material";
import RefreshIcon from "@mui/icons-material/Refresh";
import PeopleIcon from "@mui/icons-material/People";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useGridRegistration } from "@/lib/zentto-grid";
import { useBackoffice, apiFetch, type TenantRow, PLAN_OPTIONS } from "../context";

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
      <DialogTitle>Aplicar Plan -- {tenant?.LegalName}</DialogTitle>
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

// ─── Pagina de Tenants ──────────────────────────────────────────────────────

export default function TenantsPage() {
  const { token } = useBackoffice();
  const gridId = useScopedGridId("tenants-grid");
  const { ready } = useGridLayoutSync(gridId);
  const { registered } = useGridRegistration(ready);
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<TenantRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [applyTarget, setApplyTarget] = useState<TenantRow | null>(null);
  const [applyOpen, setApplyOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<{ ok: boolean; data: Record<string, unknown>[]; total: number }>(
        `/v1/backoffice/tenants?page=1&pageSize=100`,
        token
      );
      const mapped: TenantRow[] = (res.data ?? []).map((r, i) => ({
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
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    if (registered) load();
  }, [load, registered]);

  const columns: ColumnDef[] = [
    { field: "CompanyCode", header: "Codigo", width: 110, sortable: true },
    { field: "LegalName", header: "Empresa", flex: 1, minWidth: 180, sortable: true },
    {
      field: "Plan",
      header: "Plan",
      width: 120,
      sortable: true,
      groupable: true,
      statusColors: { FREE: "default", STARTER: "primary", PRO: "primary", ENTERPRISE: "primary" },
      statusVariant: "filled",
    },
    { field: "LicenseType", header: "Tipo Lic.", width: 120, sortable: true },
    {
      field: "LicenseStatus",
      header: "Estado",
      width: 120,
      sortable: true,
      groupable: true,
      statusColors: { ACTIVE: "success", INACTIVE: "default", SUSPENDED: "error", TRIAL: "warning" },
      statusVariant: "filled",
    },
    {
      field: "ExpiresAtLabel",
      header: "Vence",
      width: 130,
      sortable: true,
    },
    { field: "UserCount", header: "Usuarios", width: 100, type: "number", sortable: true },
    {
      field: "LastLoginLabel",
      header: "Ultimo Acceso",
      width: 150,
      sortable: true,
    },
    {
      field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
      actions: [
        { icon: "view", label: "Ver", action: "view", color: "#1976d2" },
      ],
    },
  ];

  const mappedRows = rows.map((r) => ({
    ...r,
    ExpiresAtLabel: r.ExpiresAt ? new Date(r.ExpiresAt).toLocaleDateString("es-VE") : "--",
    LastLoginLabel: r.LastLogin ? new Date(r.LastLogin).toLocaleString("es-VE") : "--",
  }));

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = columns;
    el.rows = mappedRows;
    el.loading = loading;
  }, [mappedRows, loading]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") {
        const t = rows.find((r) => r.CompanyCode === row.CompanyCode);
        if (t) { setApplyTarget(t); setApplyOpen(true); }
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [rows]);

  if (!ready || !registered) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="40vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Stack direction="row" alignItems="center" gap={1} mb={2}>
        <PeopleIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Tenants
        </Typography>
      </Stack>

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
      <zentto-grid
        ref={gridRef}
        grid-id={gridId}
        height="600px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      />
      <ApplyPlanModal
        open={applyOpen}
        tenant={applyTarget}
        masterKey={token}
        onClose={() => setApplyOpen(false)}
        onSuccess={load}
      />
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-grid": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
