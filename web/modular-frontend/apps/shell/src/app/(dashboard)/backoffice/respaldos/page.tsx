"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  Alert,
  LinearProgress,
  Stack,
  CircularProgress,
} from "@mui/material";
import RefreshIcon from "@mui/icons-material/Refresh";
import BackupIcon from "@mui/icons-material/Backup";
import { ConfirmDialog } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useGridRegistration } from "@/lib/zentto-grid";
import { useBackoffice, apiFetch, type BackupRow } from "../context";

export default function RespaldosPage() {
  const { token } = useBackoffice();
  const gridId = useScopedGridId("respaldos-grid");
  const { ready } = useGridLayoutSync(gridId);
  const { registered } = useGridRegistration(ready);
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<BackupRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [backupTarget, setBackupTarget] = useState<BackupRow | null>(null);
  const [backupConfirmOpen, setBackupConfirmOpen] = useState(false);
  const [backupLoading, setBackupLoading] = useState(false);
  const [runningIds, setRunningIds] = useState<Set<number>>(new Set());
  const [progressMap, setProgressMap] = useState<Map<number, { phase: string; percent: number; detail: string; elapsedSeconds: number }>>(new Map());
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const [tenantsRes, backupsRes] = await Promise.all([
        apiFetch<{ ok: boolean; data: Record<string, unknown>[] }>(
          "/v1/backoffice/tenants?page=1&pageSize=100", token
        ),
        apiFetch<{ ok: boolean; data: Record<string, unknown>[] }>(
          "/v1/backoffice/backups", token
        ).catch(() => ({ ok: true, data: [] as Record<string, unknown>[] })),
      ]);
      const backupMap = new Map<number, Record<string, unknown>>();
      for (const b of backupsRes.data ?? []) {
        backupMap.set(Number(b.CompanyId), b);
      }
      const mapped: BackupRow[] = (tenantsRes.data ?? []).map((r, i) => {
        const bk = backupMap.get(Number(r.CompanyId));
        return {
          id: i,
          CompanyId: r.CompanyId as number,
          CompanyCode: r.CompanyCode as string,
          LegalName: r.LegalName as string,
          LastBackupAt: (bk?.LastBackupAt as string) ?? (bk?.CompletedAt as string) ?? (bk?.StartedAt as string) ?? null,
          BackupSizeMB: bk?.LastBackupSizeMB != null ? Number(bk.LastBackupSizeMB) : bk?.SizeBytes != null ? Number(bk.SizeBytes) / (1024 * 1024) : null,
          BackupStatus: (bk?.LastBackupStatus as string) ?? (bk?.Status as string) ?? "UNKNOWN",
        };
      });
      setRows(mapped);

      // Detectar backups en progreso
      const running = new Set<number>();
      const newProgress = new Map(progressMap);
      await Promise.all(mapped.map(async (r) => {
        try {
          const p = await apiFetch<{ ok: boolean; running: boolean; phase?: string; percent?: number; detail?: string; elapsedSeconds?: number }>(
            `/v1/backoffice/tenants/${r.CompanyId}/backup/progress`, token
          );
          if (p.running) {
            running.add(r.CompanyId);
            newProgress.set(r.CompanyId, { phase: p.phase ?? "", percent: p.percent ?? 0, detail: p.detail ?? "", elapsedSeconds: p.elapsedSeconds ?? 0 });
          } else {
            newProgress.delete(r.CompanyId);
          }
        } catch { /* ignore */ }
      }));
      setRunningIds(running);
      setProgressMap(newProgress);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    if (registered) load();
  }, [load, registered]);

  // Poll progreso cada 3s mientras haya backups en progreso
  const pollProgress = useCallback(async () => {
    if (runningIds.size === 0) return;
    const newMap = new Map(progressMap);
    let anyRunning = false;
    for (const cid of runningIds) {
      try {
        const res = await apiFetch<{ ok: boolean; running: boolean; phase?: string; percent?: number; detail?: string; elapsedSeconds?: number }>(
          `/v1/backoffice/tenants/${cid}/backup/progress`, token
        );
        if (res.running) {
          anyRunning = true;
          newMap.set(cid, { phase: res.phase ?? "", percent: res.percent ?? 0, detail: res.detail ?? "", elapsedSeconds: res.elapsedSeconds ?? 0 });
        } else {
          newMap.delete(cid);
        }
      } catch { /* ignore */ }
    }
    setProgressMap(newMap);
    if (!anyRunning) { setRunningIds(new Set()); load(); }
  }, [runningIds, token, progressMap, load]);

  useEffect(() => {
    if (runningIds.size > 0) {
      pollRef.current = setInterval(pollProgress, 3000);
    } else if (pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [runningIds.size, pollProgress]);

  const handleBackup = async () => {
    if (!backupTarget) return;
    setBackupLoading(true);
    try {
      await apiFetch(
        `/v1/backoffice/tenants/${backupTarget.CompanyId}/backup`,
        token,
        { method: "POST" }
      );
      setBackupConfirmOpen(false);
      setRows(prev => prev.map(r =>
        r.CompanyId === backupTarget.CompanyId ? { ...r, BackupStatus: "RUNNING" } : r
      ));
      setRunningIds(prev => new Set([...prev, backupTarget.CompanyId]));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
      setBackupConfirmOpen(false);
    } finally {
      setBackupLoading(false);
    }
  };

  const columns: ColumnDef[] = [
    { field: "CompanyCode", header: "Codigo", width: 110, sortable: true },
    { field: "LegalName", header: "Empresa", flex: 1, minWidth: 180, sortable: true },
    { field: "LastBackupAtLabel", header: "Ultimo Respaldo", width: 170, sortable: true },
    { field: "BackupSizeMBLabel", header: "Tamano (MB)", width: 130, sortable: true },
    {
      field: "BackupStatus",
      header: "Estado",
      width: 130,
      sortable: true,
      groupable: true,
      statusColors: { OK: "success", FAILED: "error", RUNNING: "info", UNKNOWN: "default" },
      statusVariant: "filled",
    },
    {
      field: "actions", header: "Acciones", type: "actions", width: 120, pin: "right",
      actions: [
        { icon: "backup", label: "Crear respaldo", action: "backup", color: "#ed6c02" },
        { icon: "view", label: "Ver historial", action: "view", color: "#1976d2" },
      ],
    },
  ];

  const mappedRows = rows.map((r) => ({
    ...r,
    LastBackupAtLabel: r.LastBackupAt ? new Date(r.LastBackupAt).toLocaleString("es-VE") : "Sin respaldo",
    BackupSizeMBLabel: r.BackupSizeMB != null ? `${r.BackupSizeMB.toFixed(1)} MB` : "--",
  }));

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = columns;
    el.rows = mappedRows;
    el.loading = loading;
  }, [mappedRows, loading]);

  // Historial dialog
  const [historyTarget, setHistoryTarget] = useState<BackupRow | null>(null);
  const [historyRows, setHistoryRows] = useState<Record<string, unknown>[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  const loadHistory = useCallback(async (companyId: number) => {
    setHistoryLoading(true);
    try {
      const res = await apiFetch<{ ok: boolean; data: Record<string, unknown>[] }>(
        `/v1/backoffice/tenants/${companyId}/backups`, token
      );
      setHistoryRows(res.data ?? []);
    } catch { setHistoryRows([]); }
    finally { setHistoryLoading(false); }
  }, [token]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      const target = rows.find((r) => r.CompanyCode === row.CompanyCode);
      if (!target) return;
      if (action === "backup") {
        if (runningIds.has(target.CompanyId)) return;
        setBackupTarget(target);
        setBackupConfirmOpen(true);
      } else if (action === "view") {
        setHistoryTarget(target);
        loadHistory(target.CompanyId);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [rows, runningIds, loadHistory]);

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
        <BackupIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Respaldos
        </Typography>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>
      )}
      {runningIds.size > 0 && Array.from(runningIds).map(cid => {
        const p = progressMap.get(cid);
        const row = rows.find(r => r.CompanyId === cid);
        return (
          <Alert key={cid} severity="info" sx={{ mb: 2 }}>
            <Typography variant="subtitle2" fontWeight={600}>
              Respaldo: {row?.LegalName ?? `Tenant #${cid}`}
            </Typography>
            <Typography variant="body2" sx={{ mt: 0.5 }}>
              {p?.detail || "Iniciando..."}
              {p?.elapsedSeconds ? ` (${p.elapsedSeconds}s)` : ""}
            </Typography>
            <LinearProgress
              variant={p?.percent ? "determinate" : "indeterminate"}
              value={p?.percent ?? 0}
              sx={{ mt: 1, height: 8, borderRadius: 4 }}
            />
            {p?.percent != null && (
              <Typography variant="caption" color="text.secondary">{p.percent}%</Typography>
            )}
          </Alert>
        );
      })}
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
      <ConfirmDialog
        open={backupConfirmOpen}
        title="Crear respaldo"
        message={`Crear un respaldo manual para ${backupTarget?.LegalName}? El proceso puede tardar algunos minutos.`}
        onConfirm={handleBackup}
        onClose={() => setBackupConfirmOpen(false)}
        confirmLabel={backupLoading ? "Creando..." : "Crear respaldo"}
      />
      {/* Dialog historial de backups */}
      <Dialog open={!!historyTarget} onClose={() => setHistoryTarget(null)} maxWidth="md" fullWidth>
        <DialogTitle>
          Historial de respaldos -- {historyTarget?.LegalName}
        </DialogTitle>
        <DialogContent>
          {historyLoading ? (
            <Box py={2}>
              <LinearProgress />
            </Box>
          ) : historyRows.length === 0 ? (
            <Typography color="text.secondary" py={2}>No hay respaldos registrados.</Typography>
          ) : (
            <Box sx={{ maxHeight: 400, overflow: "auto" }}>
              {historyRows.map((h, i) => (
                <Box key={i} sx={{ py: 1, px: 2, borderBottom: "1px solid #eee", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <Box>
                    <Typography variant="body2" fontWeight={600}>
                      {h.Status === "OK" ? "Completado" : h.Status === "FAILED" ? "Fallido" : h.Status === "RUNNING" ? "En progreso..." : String(h.Status)}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {h.CompletedAt ? new Date(h.CompletedAt as string).toLocaleString("es-VE") : h.StartedAt ? new Date(h.StartedAt as string).toLocaleString("es-VE") : "--"}
                      {h.SizeBytes ? ` -- ${(Number(h.SizeBytes) / (1024 * 1024)).toFixed(1)} MB` : ""}
                      {h.RequestedBy ? ` -- por ${h.RequestedBy}` : ""}
                    </Typography>
                  </Box>
                  <Chip
                    label={String(h.Status)}
                    size="small"
                    color={h.Status === "OK" ? "success" : h.Status === "FAILED" ? "error" : h.Status === "RUNNING" ? "info" : "default"}
                  />
                </Box>
              ))}
            </Box>
          )}
        </DialogContent>
      </Dialog>
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
