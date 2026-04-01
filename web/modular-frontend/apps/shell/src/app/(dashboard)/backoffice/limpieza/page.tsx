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
import RefreshIcon from "@mui/icons-material/Refresh";
import WarningIcon from "@mui/icons-material/Warning";
import DeleteIcon from "@mui/icons-material/Delete";
import { ConfirmDialog } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useGridRegistration } from "@/lib/zentto-grid";
import { useBackoffice, apiFetch, type CleanupRow } from "../context";

export default function LimpiezaPage() {
  const { token } = useBackoffice();
  const gridId = useScopedGridId("cleanup-grid");
  const { ready } = useGridLayoutSync(gridId);
  const { registered } = useGridRegistration(ready);
  const gridRef = useRef<any>(null);
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
      const res = await apiFetch<{ ok: boolean; data: Record<string, unknown>[] }>(
        "/v1/backoffice/cleanup?status=PENDING",
        token
      );
      const mapped: CleanupRow[] = (Array.isArray(res) ? res : res?.data ?? []).map((r, i) => ({
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
  }, [token]);

  useEffect(() => {
    if (registered) load();
  }, [load, registered]);

  const handleScan = async () => {
    setScanLoading(true);
    try {
      await apiFetch("/v1/backoffice/cleanup/scan", token, {
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
        token,
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

  const columns: ColumnDef[] = [
    { field: "CompanyCode", header: "Codigo", width: 110, sortable: true },
    { field: "LegalName", header: "Empresa", flex: 1, minWidth: 160, sortable: true },
    { field: "Reason", header: "Razon", width: 160, sortable: true },
    {
      field: "Status",
      header: "Estado",
      width: 120,
      sortable: true,
      groupable: true,
      statusColors: { PENDING: "warning", NOTIFIED: "info", CONFIRMED: "error", CANCELLED: "default" },
      statusVariant: "filled",
    },
    { field: "FlaggedAtLabel", header: "Marcado", width: 130, sortable: true },
    { field: "DeleteAfterLabel", header: "Eliminar tras", width: 130, sortable: true },
    { field: "DaysUntilDelete", header: "Dias restantes", width: 130, type: "number", sortable: true },
    {
      field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
      actions: [
        { icon: "view", label: "Ver", action: "view", color: "#1976d2" },
      ],
    },
  ];

  const mappedRows = rows.map((r) => ({
    ...r,
    FlaggedAtLabel: r.FlaggedAt ? new Date(r.FlaggedAt).toLocaleDateString("es-VE") : "--",
    DeleteAfterLabel: r.DeleteAfter ? new Date(r.DeleteAfter).toLocaleDateString("es-VE") : "--",
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
        setConfirmAction({ queueId: row.QueueId, action: "cancel", label: `Ver detalles de limpieza: ${row.LegalName}` });
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
        <DeleteIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Cola de Limpieza
        </Typography>
      </Stack>

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
      <ConfirmDialog
        open={!!confirmAction}
        title="Confirmar accion"
        message={confirmAction?.label ?? ""}
        onConfirm={() => {
          if (confirmAction) {
            return handleAction(confirmAction.queueId, confirmAction.action);
          }
        }}
        onClose={() => setConfirmAction(null)}
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
