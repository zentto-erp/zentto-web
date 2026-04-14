"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Box, Typography, Stack, Alert, Button, Chip, Tabs, Tab, Paper, CircularProgress,
} from "@mui/material";
import MoneyIcon from "@mui/icons-material/AttachMoney";
import AddIcon from "@mui/icons-material/Add";
import SyncIcon from "@mui/icons-material/Sync";
import CloudSyncIcon from "@mui/icons-material/CloudSync";
import RefreshIcon from "@mui/icons-material/Refresh";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useGridRegistration } from "@/lib/zentto-grid";
import { useBackoffice, apiFetch } from "../context";
import { PlanFormModal } from "./PlanFormModal";
import type { PlanAdmin, PendingSyncRow } from "./types";

type TabKey = "catalog" | "paddle";

export default function PlanesPage() {
  const { token, isSet } = useBackoffice();
  const [tab, setTab] = useState<TabKey>("catalog");

  // Dos grids (uno por tab). Cada tab tiene su gridId + registration + layout sync.
  const catalogGridId = useScopedGridId("planes-catalog");
  const pendingGridId = useScopedGridId("planes-paddle");
  const { ready: catalogLayoutReady } = useGridLayoutSync(catalogGridId);
  const { ready: pendingLayoutReady } = useGridLayoutSync(pendingGridId);
  const { registered: catalogRegistered } = useGridRegistration(catalogLayoutReady);
  const { registered: pendingRegistered } = useGridRegistration(pendingLayoutReady);

  const catalogGridRef = useRef<any>(null);
  const pendingGridRef = useRef<any>(null);

  const [plans, setPlans] = useState<PlanAdmin[]>([]);
  const [pending, setPending] = useState<PendingSyncRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<PlanAdmin | null>(null);
  const [syncingId, setSyncingId] = useState<number | null>(null);
  const [bulkSyncing, setBulkSyncing] = useState(false);

  const reloadCatalog = useCallback(async () => {
    if (!isSet) return;
    setLoading(true); setError("");
    try {
      const res = await apiFetch<{ ok: boolean; plans: PlanAdmin[] }>(
        "/v1/backoffice/catalog/plans", token
      );
      setPlans(res.plans ?? []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally { setLoading(false); }
  }, [token, isSet]);

  const reloadPending = useCallback(async () => {
    if (!isSet) return;
    setLoading(true); setError("");
    try {
      const res = await apiFetch<{ ok: boolean; pending: PendingSyncRow[] }>(
        "/v1/backoffice/catalog/paddle/pending", token
      );
      setPending(res.pending ?? []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally { setLoading(false); }
  }, [token, isSet]);

  useEffect(() => {
    if (tab === "catalog" && catalogRegistered) void reloadCatalog();
    if (tab === "paddle"  && pendingRegistered) void reloadPending();
  }, [tab, catalogRegistered, pendingRegistered, reloadCatalog, reloadPending]);

  const handleEdit = (row: PlanAdmin) => { setEditing(row); setModalOpen(true); };
  const handleCreate = () => { setEditing(null); setModalOpen(true); };
  const handleSaved = () => { void reloadCatalog(); setInfo("Plan guardado"); };

  const handleToggle = async (row: PlanAdmin) => {
    setError("");
    try {
      await apiFetch(`/v1/backoffice/catalog/plans/${row.PricingPlanId}/toggle`, token, {
        method: "PATCH",
        body: JSON.stringify({ isActive: !row.IsActive }),
      });
      await reloadCatalog();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  const handleSyncOne = async (planId: number) => {
    setSyncingId(planId); setError("");
    try {
      const res = await apiFetch<{ ok: boolean; mensaje: string }>(
        `/v1/backoffice/catalog/paddle/sync/${planId}`, token, { method: "POST" }
      );
      if (res.ok) setInfo(`Plan sincronizado: ${res.mensaje}`);
      else setError(`Sync falló: ${res.mensaje}`);
      await Promise.all([reloadPending(), reloadCatalog()]);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally { setSyncingId(null); }
  };

  const handleSyncAll = async () => {
    setBulkSyncing(true); setError("");
    try {
      const res = await apiFetch<{ ok: boolean; total: number; synced: number; failed: number; errors: string[] }>(
        "/v1/backoffice/catalog/paddle/sync-all", token, { method: "POST" }
      );
      setInfo(`Sincronización: ${res.synced}/${res.total} OK, ${res.failed} fallaron${res.failed > 0 ? ` — ${res.errors.slice(0, 3).join("; ")}` : ""}`);
      await Promise.all([reloadPending(), reloadCatalog()]);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally { setBulkSyncing(false); }
  };

  // ── Columnas y datos para grid "catalog" ───────────────────────────────────
  const catalogColumns: ColumnDef[] = [
    { field: "Slug", header: "Slug", width: 200, sortable: true },
    { field: "Name", header: "Nombre", width: 180, sortable: true },
    {
      field: "ProductCode", header: "Producto", width: 110, sortable: true, groupable: true,
      statusColors: { "erp-core": "primary", medical: "info", hotel: "info", tickets: "info", education: "info", rental: "info" },
      statusVariant: "outlined",
    },
    { field: "VerticalType", header: "Vertical", width: 100, sortable: true },
    { field: "PriceLabel", header: "Precio", width: 150, sortable: true },
    { field: "MaxUsers", header: "Users", width: 80, type: "number", sortable: true },
    {
      field: "FlagsLabel", header: "Flags", width: 130,
    },
    {
      field: "PaddleSyncStatus", header: "Paddle", width: 120, sortable: true, groupable: true,
      statusColors: { draft: "warning", syncing: "info", synced: "success", error: "error", skip: "default" },
      statusVariant: "filled",
    },
    {
      field: "actions", header: "Acciones", type: "actions", width: 130, pin: "right",
      actions: [
        { icon: "edit",   label: "Editar",       action: "edit",   color: "#1976d2" },
        { icon: "toggle", label: "Activar/Off",  action: "toggle", color: "#757575" },
        { icon: "sync",   label: "Sync Paddle",  action: "sync",   color: "#7B1FA2" },
      ],
    },
  ];

  const mappedPlans = plans.map((p, i) => ({
    ...p, id: i,
    PriceLabel: p.IsTrialOnly ? `${p.TrialDays}d gratis` : `$${Number(p.MonthlyPrice).toFixed(2)}/mes`,
    FlagsLabel: [
      p.IsTrialOnly ? "Trial" : null,
      p.IsAddon ? "Add-on" : null,
      !p.IsActive ? "Inactivo" : null,
    ].filter(Boolean).join(" · "),
  }));

  useEffect(() => {
    const el = catalogGridRef.current;
    if (!el || tab !== "catalog") return;
    el.columns = catalogColumns;
    el.rows = mappedPlans;
    el.loading = loading;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, mappedPlans, loading]);

  useEffect(() => {
    const el = catalogGridRef.current;
    if (!el) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      const plan = plans.find((p) => p.PricingPlanId === row.PricingPlanId);
      if (!plan) return;
      if (action === "edit")   handleEdit(plan);
      if (action === "toggle") void handleToggle(plan);
      if (action === "sync" && !plan.IsTrialOnly) void handleSyncOne(plan.PricingPlanId);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [plans]);

  // ── Columnas y datos para grid "paddle pending" ────────────────────────────
  const pendingColumns: ColumnDef[] = [
    { field: "Slug", header: "Slug", width: 200, sortable: true },
    { field: "Name", header: "Nombre", width: 180, sortable: true },
    { field: "ProductCode", header: "Producto", width: 120, sortable: true },
    { field: "MonthlyPriceLabel", header: "Mensual", width: 110, sortable: true, type: "number" },
    { field: "AnnualPriceLabel", header: "Anual", width: 110, sortable: true, type: "number" },
    { field: "PaddleProductId", header: "Product ID", width: 220 },
    {
      field: "PaddleSyncStatus", header: "Estado", width: 110, sortable: true, groupable: true,
      statusColors: { draft: "warning", syncing: "info", synced: "success", error: "error" },
      statusVariant: "filled",
    },
    {
      field: "actions", header: "", type: "actions", width: 80, pin: "right",
      actions: [{ icon: "sync", label: "Sync", action: "sync", color: "#7B1FA2" }],
    },
  ];

  const mappedPending = pending.map((p, i) => ({
    ...p, id: i,
    MonthlyPriceLabel: `$${Number(p.MonthlyPrice).toFixed(2)}`,
    AnnualPriceLabel: `$${Number(p.AnnualPrice).toFixed(2)}`,
    PaddleProductId: p.PaddleProductId || "—",
  }));

  useEffect(() => {
    const el = pendingGridRef.current;
    if (!el || tab !== "paddle") return;
    el.columns = pendingColumns;
    el.rows = mappedPending;
    el.loading = loading;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, mappedPending, loading]);

  useEffect(() => {
    const el = pendingGridRef.current;
    if (!el) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "sync") void handleSyncOne(row.PricingPlanId);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!isSet) {
    return <Alert severity="warning">Debes autenticarte en el backoffice antes de gestionar planes.</Alert>;
  }

  return (
    <Box>
      <Stack direction={{ xs: "column", sm: "row" }} alignItems={{ sm: "center" }} justifyContent="space-between" gap={2} mb={2}>
        <Stack direction="row" alignItems="center" gap={1}>
          <MoneyIcon color="primary" />
          <Typography variant="h5" fontWeight={700}>Catálogo de planes</Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          <Button startIcon={<RefreshIcon />} onClick={() => tab === "catalog" ? reloadCatalog() : reloadPending()} disabled={loading}>
            Refrescar
          </Button>
          {tab === "catalog" && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreate}>
              Nuevo plan
            </Button>
          )}
          {tab === "paddle" && pending.length > 0 && (
            <Button variant="contained" color="secondary" startIcon={<CloudSyncIcon />} disabled={bulkSyncing} onClick={handleSyncAll}>
              {bulkSyncing ? "Sincronizando..." : `Sync todo (${pending.length})`}
            </Button>
          )}
          {syncingId !== null && <CircularProgress size={20} sx={{ ml: 1, alignSelf: "center" }} />}
        </Stack>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError("")}>{error}</Alert>}
      {info && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setInfo("")}>{info}</Alert>}

      <Paper sx={{ mb: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} indicatorColor="primary">
          <Tab value="catalog" label={`Catálogo (${plans.length})`} />
          <Tab value="paddle" label={`Paddle sync (${pending.length})`} />
        </Tabs>
      </Paper>

      {tab === "catalog" && (
        !catalogLayoutReady || !catalogRegistered ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress /></Box>
        ) : (
          <zentto-grid
            ref={catalogGridRef}
            grid-id={catalogGridId}
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
        )
      )}

      {tab === "paddle" && (
        !pendingLayoutReady || !pendingRegistered ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress /></Box>
        ) : pending.length === 0 && !loading ? (
          <Alert severity="success">Todos los planes están sincronizados con Paddle.</Alert>
        ) : (
          <zentto-grid
            ref={pendingGridRef}
            grid-id={pendingGridId}
            height="500px"
            enable-toolbar
            enable-header-menu
            enable-quick-search
            enable-status-bar
          />
        )
      )}

      <PlanFormModal
        open={modalOpen}
        initial={editing}
        masterKey={token}
        onClose={() => setModalOpen(false)}
        onSaved={handleSaved}
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
