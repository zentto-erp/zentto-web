"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  Alert,
  Stack,
  CircularProgress,
} from "@mui/material";
import {
  Refresh as RefreshIcon,
  Storage as StorageIcon,
} from "@mui/icons-material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useGridRegistration } from "@/lib/zentto-grid";
import { useBackoffice, apiFetch, type ResourceRow } from "../context";

export default function RecursosPage() {
  const { token } = useBackoffice();
  const gridId = useScopedGridId("recursos-grid");
  const { ready } = useGridLayoutSync(gridId);
  const { registered } = useGridRegistration(ready);
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<ResourceRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiFetch<{ ok: boolean; data: Record<string, unknown>[] }>(
        "/v1/backoffice/resources",
        token
      );
      const mapped: ResourceRow[] = (Array.isArray(res) ? res : res?.data ?? []).map((r, i) => ({
        id: i,
        CompanyId: r.CompanyId as number,
        CompanyCode: r.CompanyCode as string,
        LegalName: r.LegalName as string,
        DbSizeMB: r.DbSizeMB != null && r.DbSizeMB !== "" ? Number(r.DbSizeMB) || 0 : 0,
        LastLoginAt: r.LastLoginAt && r.LastLoginAt !== "null" ? String(r.LastLoginAt) : null,
        Status: r.Status as string,
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
    { field: "DbSizeMBLabel", header: "BD (MB)", width: 140, type: "number", sortable: true },
    { field: "LastLoginAtLabel", header: "Ultimo Acceso", width: 160, sortable: true },
    {
      field: "Status",
      header: "Estado",
      width: 120,
      sortable: true,
      groupable: true,
      statusColors: { ACTIVE: "success", INACTIVE: "default", SUSPENDED: "error" },
      statusVariant: "filled",
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
    DbSizeMBLabel: `${r.DbSizeMB.toFixed(1)} MB`,
    LastLoginAtLabel: r.LastLoginAt ? new Date(r.LastLoginAt).toLocaleString("es-VE") : "--",
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
        console.log("Ver recurso:", row);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, []);

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
        <StorageIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Recursos
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
