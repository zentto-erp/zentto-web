"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  Autocomplete,
  Box,
  Chip,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import DownloadIcon from "@mui/icons-material/Download";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import {
  ContextActionHeader,
  DeleteDialog,
  FormDialog,
  RightDetailDrawer,
  useDrawerQueryParam,
  useToast,
  ZenttoFilterPanel,
  ZenttoRecordTable,
  type BulkAction,
  type ColumnSpec,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import { formatCurrency } from "@zentto/shared-api";
import DealDetailPanel from "./DealDetailPanel";
import {
  useCloseLostDeal,
  useCloseWonDeal,
  useDealsList,
  useDeleteDeal,
  useUpsertDeal,
  type Deal,
  type DealFilter,
  type DealStatus,
} from "../hooks/useDeals";
import { usePipelinesList, usePipelineStages } from "../hooks/useCRM";
import { useCompaniesList, type Company } from "../hooks/useCompanies";
import { useContactsList, type Contact } from "../hooks/useContacts";
import { PRIORITY_COLORS, PRIORITY_LABELS, type Priority } from "../types";

const GRID_ID = "module-crm:deals:list";
const RECORD_TYPE = "deal";

const QS_KEYS = {
  search: "q",
  status: "status",
  pipeline: "pipeline",
  stage: "stage",
  priority: "priority",
} as const;

const priorityColor: Record<Priority, "error" | "warning" | "info"> = PRIORITY_COLORS;
const priorityLabel: Record<Priority, string> = PRIORITY_LABELS;

const statusColor: Record<DealStatus, "success" | "error" | "info" | "default"> = {
  OPEN: "info",
  WON: "success",
  LOST: "error",
  ABANDONED: "default",
};
const statusLabel: Record<DealStatus, string> = {
  OPEN: "Abierto",
  WON: "Ganado",
  LOST: "Perdido",
  ABANDONED: "Abandonado",
};

const emptyDeal = {
  name: "",
  pipelineId: "" as number | "",
  stageId: "" as number | "",
  contactId: "" as number | "",
  crmCompanyId: "" as number | "",
  value: "",
  currency: "USD",
  probability: "",
  expectedClose: "",
  priority: "MEDIUM" as Priority,
  source: "",
  notes: "",
  tags: "",
};

type FilterDraft = Partial<Record<keyof typeof QS_KEYS, string>>;

export default function DealsPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { showToast } = useToast();

  const filterFromUrl = useMemo<FilterDraft>(() => {
    const out: FilterDraft = {};
    (Object.keys(QS_KEYS) as Array<keyof typeof QS_KEYS>).forEach((k) => {
      const v = searchParams?.get(QS_KEYS[k]);
      if (v) out[k] = v;
    });
    return out;
  }, [searchParams]);

  const filter: DealFilter = useMemo(
    () => ({
      page: 1,
      limit: 50,
      search: filterFromUrl.search || undefined,
      status: (filterFromUrl.status as DealStatus) || undefined,
      pipelineId: filterFromUrl.pipeline ? Number(filterFromUrl.pipeline) : undefined,
      stageId: filterFromUrl.stage ? Number(filterFromUrl.stage) : undefined,
    }),
    [filterFromUrl],
  );

  const updateQuery = useCallback(
    (patch: FilterDraft) => {
      const params = new URLSearchParams(searchParams?.toString() ?? "");
      (Object.keys(patch) as Array<keyof typeof QS_KEYS>).forEach((k) => {
        const qsKey = QS_KEYS[k];
        const v = patch[k];
        if (v == null || v === "") params.delete(qsKey);
        else params.set(qsKey, v);
      });
      const qs = params.toString();
      router.push(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [pathname, router, searchParams],
  );

  const dealDrawer = useDrawerQueryParam("deal");
  const drawerDealId = dealDrawer.id ? Number(dealDrawer.id) : null;

  const { data, isLoading, error, refetch } = useDealsList(filter);
  const { data: pipelinesData } = usePipelinesList();
  const pipelines = (pipelinesData as any)?.data ?? (pipelinesData as any)?.rows ?? pipelinesData ?? [];

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyDeal);

  const selectedPipelineId =
    typeof form.pipelineId === "number"
      ? form.pipelineId
      : filterFromUrl.pipeline
        ? Number(filterFromUrl.pipeline)
        : undefined;
  const { data: stagesData } = usePipelineStages(selectedPipelineId);
  const stages = (stagesData as any)?.data ?? (stagesData as any)?.rows ?? stagesData ?? [];

  const { data: companiesData } = useCompaniesList({ active: true, limit: 500 });
  const companies: Company[] =
    (companiesData as any)?.data ?? (companiesData as any)?.rows ?? companiesData ?? [];

  const { data: contactsData } = useContactsList({ active: true, limit: 500 });
  const contacts: Contact[] =
    (contactsData as any)?.data ?? (contactsData as any)?.rows ?? contactsData ?? [];

  const upsertDeal = useUpsertDeal();
  const deleteDeal = useDeleteDeal();
  const closeWon = useCloseWonDeal();
  const closeLost = useCloseLostDeal();

  const rows = (data as any)?.data ?? (data as any)?.rows ?? [];
  const totalCount = (data as any)?.totalCount ?? (data as any)?.TotalCount ?? rows.length;
  const typedRows = rows as Deal[];

  const [deleteTarget, setDeleteTarget] = useState<Deal | null>(null);
  const [bulkDeleteIds, setBulkDeleteIds] = useState<Array<string | number>>([]);
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);
  const [bulkLoseOpen, setBulkLoseOpen] = useState(false);
  const [bulkLoseReason, setBulkLoseReason] = useState("");
  const [bulkIds, setBulkIds] = useState<Array<string | number>>([]);

  const columns: ColumnSpec[] = useMemo(
    () => [
      {
        field: "DealCode",
        header: "Código",
        width: 110,
        // El backend aún no emite DealCode; derivamos `DEAL-NNN` del DealId
        // para paridad visual con Leads (LEAD-NNN). Cuando se agregue la
        // columna al schema (migración goose), este fallback sigue siendo
        // compatible — si DealCode viene del API, se usa tal cual.
        renderCell: ((value: unknown, row: unknown) => {
          if (typeof value === "string" && value.length > 0) return value;
          const id = (row as { DealId?: number | string })?.DealId;
          if (id == null) return "—";
          return `DEAL-${String(id).padStart(3, "0")}`;
        }) as unknown,
      } as ColumnSpec,
      { field: "Name", header: "Nombre", flex: 1, minWidth: 180 },
      { field: "ContactName", header: "Contacto", width: 160 },
      { field: "CompanyName", header: "Empresa", width: 160 },
      { field: "StageName", header: "Etapa", width: 140 },
      {
        field: "Value",
        header: "Valor",
        width: 130,
        renderCell: ((v: unknown) => formatCurrency(v as number)) as unknown,
      } as ColumnSpec,
      {
        field: "Probability",
        header: "Prob.",
        width: 90,
        renderCell: ((v: unknown) => (v != null ? `${v}%` : "—")) as unknown,
      } as ColumnSpec,
      { field: "ExpectedClose", header: "Cierre esperado", width: 150 },
      {
        field: "Priority",
        header: "Prioridad",
        width: 110,
        renderCell: ((value: unknown) => (
          <Chip
            label={priorityLabel[value as Priority] ?? (value as string)}
            size="small"
            color={priorityColor[value as Priority] ?? "default"}
          />
        )) as unknown,
      } as ColumnSpec,
      {
        field: "Status",
        header: "Estado",
        width: 110,
        renderCell: ((value: unknown) => (
          <Chip
            label={statusLabel[value as DealStatus] ?? (value as string)}
            size="small"
            color={statusColor[value as DealStatus] ?? "default"}
          />
        )) as unknown,
      } as ColumnSpec,
      { field: "OwnerAgentName", header: "Owner", width: 140 },
      {
        field: "actions",
        header: "Acciones",
        type: "actions",
        width: 130,
        pin: "right",
        actions: [
          { icon: "view", label: "Ver", action: "view", color: "#6b7280" },
          { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
          { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
        ],
      } as ColumnSpec,
    ],
    [],
  );

  const filterFields: FilterFieldDef[] = useMemo(
    () => [
      {
        field: "status",
        label: "Estado",
        type: "select",
        options: [
          { value: "OPEN", label: "Abierto" },
          { value: "WON", label: "Ganado" },
          { value: "LOST", label: "Perdido" },
          { value: "ABANDONED", label: "Abandonado" },
        ],
      },
      {
        field: "pipeline",
        label: "Pipeline",
        type: "select",
        options: (pipelines as Array<any>).map((p) => ({
          value: String(p.PipelineId),
          label: p.Name,
        })),
      },
      {
        field: "stage",
        label: "Etapa",
        type: "select",
        options: (stages as Array<any>).map((s) => ({
          value: String(s.StageId),
          label: s.Name,
        })),
      },
      {
        field: "priority",
        label: "Prioridad",
        type: "select",
        options: [
          { value: "URGENT", label: "Urgente" },
          { value: "HIGH", label: "Alta" },
          { value: "MEDIUM", label: "Media" },
          { value: "LOW", label: "Baja" },
        ],
      },
    ],
    [pipelines, stages],
  );

  const filterValues: Record<string, string> = useMemo(
    () => ({
      status: filterFromUrl.status ?? "",
      pipeline: filterFromUrl.pipeline ?? "",
      stage: filterFromUrl.stage ?? "",
      priority: filterFromUrl.priority ?? "",
    }),
    [filterFromUrl],
  );

  const handleFilterChange = useCallback(
    (next: Record<string, string>) => {
      updateQuery({
        status: next.status,
        pipeline: next.pipeline,
        stage: next.stage,
        priority: next.priority,
      });
    },
    [updateQuery],
  );

  const handleSearchChange = useCallback(
    (v: string) => updateQuery({ search: v }),
    [updateQuery],
  );

  const handleOpenNew = useCallback(() => {
    setEditId(null);
    setForm({
      ...emptyDeal,
      pipelineId: (pipelines as Array<any>)[0]?.PipelineId ?? "",
    });
    setDialogOpen(true);
  }, [pipelines]);

  const handleEdit = useCallback((d: Deal) => {
    setEditId(d.DealId);
    setForm({
      name: d.Name ?? "",
      pipelineId: d.PipelineId,
      stageId: d.StageId,
      contactId: d.ContactId ?? "",
      crmCompanyId: d.CrmCompanyId ?? "",
      value: String(d.Value ?? ""),
      currency: d.Currency ?? "USD",
      probability: d.Probability != null ? String(d.Probability) : "",
      expectedClose: d.ExpectedClose ? String(d.ExpectedClose).slice(0, 10) : "",
      priority: d.Priority ?? "MEDIUM",
      source: d.Source ?? "",
      notes: d.Notes ?? "",
      tags: d.Tags ?? "",
    });
    setDialogOpen(true);
  }, []);

  const handleSave = useCallback(() => {
    const payload: Record<string, unknown> = {
      id: editId ?? undefined,
      name: form.name.trim(),
      pipelineId: form.pipelineId ? Number(form.pipelineId) : undefined,
      stageId: form.stageId ? Number(form.stageId) : undefined,
      contactId: form.contactId ? Number(form.contactId) : undefined,
      crmCompanyId: form.crmCompanyId ? Number(form.crmCompanyId) : undefined,
      value: form.value ? Number(form.value) : undefined,
      currency: form.currency || undefined,
      probability: form.probability !== "" ? Number(form.probability) : undefined,
      expectedClose: form.expectedClose || undefined,
      priority: form.priority,
      source: form.source || undefined,
      notes: form.notes || undefined,
      tags: form.tags || undefined,
    };
    upsertDeal.mutate(payload as any, {
      onSuccess: () => {
        setDialogOpen(false);
        showToast(editId ? "Deal actualizado" : "Deal creado", "success");
      },
    });
  }, [editId, form, upsertDeal, showToast]);

  const handleOpenRecord = useCallback(
    (id: string | number) => dealDrawer.openDrawer(id),
    [dealDrawer],
  );

  const handleActionClick = useCallback(
    (row: Deal, action: string) => {
      if (action === "view") dealDrawer.openDrawer(row.DealId);
      else if (action === "edit") handleEdit(row);
      else if (action === "delete") setDeleteTarget(row);
    },
    [dealDrawer, handleEdit],
  );

  useEffect(() => {
    const el = document.querySelector<HTMLElement>(`zentto-grid[grid-id="${GRID_ID}"]`);
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action?: string; row?: Deal };
      if (!detail?.action || !detail?.row) return;
      handleActionClick(detail.row, detail.action);
    };
    el.addEventListener("action-click", handler as EventListener);
    return () => el.removeEventListener("action-click", handler as EventListener);
  }, [handleActionClick]);

  const confirmDelete = useCallback(() => {
    if (!deleteTarget) return;
    deleteDeal.mutate(deleteTarget.DealId, {
      onSuccess: () => {
        showToast("Deal eliminado", "success");
        setDeleteTarget(null);
      },
    });
  }, [deleteDeal, deleteTarget, showToast]);

  const runBulkDelete = useCallback(async () => {
    const numeric = bulkDeleteIds.map((id) => Number(id));
    await Promise.all(numeric.map((id) => deleteDeal.mutateAsync(id)));
    showToast(`${numeric.length} deals eliminados`, "success");
    setBulkDeleteOpen(false);
    setBulkDeleteIds([]);
  }, [bulkDeleteIds, deleteDeal, showToast]);

  const bulkMarkWon = useCallback(
    async (ids: Array<string | number>) => {
      const numeric = ids.map((id) => Number(id));
      await Promise.all(numeric.map((id) => closeWon.mutateAsync({ id })));
      showToast(`${numeric.length} deals ganados`, "success");
    },
    [closeWon, showToast],
  );

  const runBulkLose = useCallback(async () => {
    const numeric = bulkIds.map((id) => Number(id));
    await Promise.all(
      numeric.map((id) => closeLost.mutateAsync({ id, reason: bulkLoseReason })),
    );
    showToast(`${numeric.length} deals perdidos`, "success");
    setBulkLoseOpen(false);
    setBulkLoseReason("");
    setBulkIds([]);
  }, [bulkIds, bulkLoseReason, closeLost, showToast]);

  const exportCsv = useCallback(
    (ids: Array<string | number>) => {
      const selected = typedRows.filter((r) => ids.includes(r.DealId));
      if (!selected.length) return;
      const headers = [
        "DealCode",
        "Name",
        "ContactName",
        "CompanyName",
        "StageName",
        "Value",
        "Currency",
        "Probability",
        "Status",
        "Priority",
        "OwnerAgentName",
      ];
      const escape = (v: unknown) => {
        const s = v == null ? "" : String(v);
        return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
      };
      const lines = [
        headers.join(","),
        ...selected.map((r) => headers.map((h) => escape((r as any)[h])).join(",")),
      ];
      const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `crm-deals-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      showToast(`${selected.length} deals exportados`, "success");
    },
    [typedRows, showToast],
  );

  const bulkActions: BulkAction[] = useMemo(
    () => [
      {
        id: "mark-won",
        label: "Ganado",
        icon: <EmojiEventsIcon fontSize="small" />,
        variant: "primary",
        onClick: (ids) => bulkMarkWon(ids),
      },
      {
        id: "mark-lost",
        label: "Perdido",
        icon: <ThumbDownIcon fontSize="small" />,
        onClick: (ids) => {
          setBulkIds(ids);
          setBulkLoseOpen(true);
        },
      },
      {
        id: "export-csv",
        label: "Exportar CSV",
        icon: <DownloadIcon fontSize="small" />,
        onClick: (ids) => exportCsv(ids),
      },
      {
        id: "delete",
        label: "Eliminar",
        icon: <DeleteOutlineIcon fontSize="small" />,
        variant: "danger",
        onClick: (ids) => {
          setBulkDeleteIds(ids);
          setBulkDeleteOpen(true);
        },
      },
    ],
    [bulkMarkWon, exportCsv],
  );

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Deals" />

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <ZenttoRecordTable
          recordType={RECORD_TYPE}
          gridId={GRID_ID}
          rowKey="DealId"
          rows={typedRows as unknown as Record<string, unknown>[]}
          columns={columns}
          loading={isLoading}
          error={error ? String((error as any)?.message ?? error) : null}
          onRetry={() => refetch()}
          totalCount={totalCount}
          onOpenRecord={handleOpenRecord}
          onCreate={handleOpenNew}
          createLabel="Nuevo deal"
          bulkActions={bulkActions}
          emptyState={{
            title: "Sin deals todavía",
            description:
              "Registra oportunidades comerciales para gestionarlas en tu pipeline de ventas.",
            primaryAction: {
              label: "Crear primer deal",
              onClick: handleOpenNew,
            },
            secondaryAction: {
              label: "Ver pipeline",
              onClick: () => router.push("/pipeline"),
            },
          }}
          gridAttrs={{
            "export-filename": "crm-deals-list",
            "enable-header-menu": true,
            "enable-header-filters": true,
            "enable-clipboard": true,
            "enable-context-menu": true,
            "enable-configurator": true,
            "enable-grouping": true,
            "enable-pivot": true,
          }}
          filterPanel={
            <ZenttoFilterPanel
              filters={filterFields}
              values={filterValues}
              onChange={handleFilterChange}
              searchPlaceholder="Buscar deal (código, nombre, contacto…)"
              searchValue={filterFromUrl.search ?? ""}
              onSearchChange={handleSearchChange}
            />
          }
        />
      </Box>

      <RightDetailDrawer
        open={dealDrawer.open && drawerDealId !== null}
        onClose={dealDrawer.closeDrawer}
        title="Detalle del deal"
        subtitle={drawerDealId ? `#${drawerDealId}` : undefined}
        width={{ desktop: 560 }}
      >
        {drawerDealId && (
          <DealDetailPanel
            dealId={drawerDealId}
            onClose={dealDrawer.closeDrawer}
            onEdit={() => {
              const row = typedRows.find((r) => r.DealId === drawerDealId);
              if (row) handleEdit(row);
            }}
          />
        )}
      </RightDetailDrawer>

      <FormDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        title={editId ? "Editar deal" : "Nuevo deal"}
        mode={editId ? "edit" : "create"}
        onSave={handleSave}
        loading={upsertDeal.isPending}
        disableSave={!form.name.trim() || !form.pipelineId || !form.stageId}
        saveLabel={editId ? "Guardar" : "Crear"}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre del deal"
            fullWidth
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <FormControl fullWidth required>
              <InputLabel>Pipeline</InputLabel>
              <Select
                value={form.pipelineId}
                label="Pipeline"
                onChange={(e) =>
                  setForm({ ...form, pipelineId: Number(e.target.value), stageId: "" })
                }
              >
                {(pipelines as Array<any>).map((p) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>
                    {p.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl fullWidth required>
              <InputLabel>Etapa</InputLabel>
              <Select
                value={form.stageId}
                label="Etapa"
                onChange={(e) => setForm({ ...form, stageId: Number(e.target.value) })}
                disabled={!form.pipelineId && !editId}
              >
                {(stages as Array<any>).map((s) => (
                  <MenuItem key={s.StageId} value={s.StageId}>
                    {s.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <Autocomplete
              sx={{ flex: 1 }}
              options={contacts}
              getOptionLabel={(c) =>
                `${c.FirstName ?? ""} ${c.LastName ?? ""}`.trim() || `#${c.ContactId}`
              }
              value={
                contacts.find((c) => c.ContactId === Number(form.contactId)) ?? null
              }
              onChange={(_, v) =>
                setForm({ ...form, contactId: v?.ContactId ?? "" })
              }
              renderInput={(params) => <TextField {...params} label="Contacto" />}
            />
            <Autocomplete
              sx={{ flex: 1 }}
              options={companies}
              getOptionLabel={(c) => c.Name ?? `#${c.CrmCompanyId}`}
              value={
                companies.find((c) => c.CrmCompanyId === Number(form.crmCompanyId)) ??
                null
              }
              onChange={(_, v) =>
                setForm({ ...form, crmCompanyId: v?.CrmCompanyId ?? "" })
              }
              renderInput={(params) => <TextField {...params} label="Empresa" />}
            />
          </Stack>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Valor"
              type="number"
              fullWidth
              value={form.value}
              onChange={(e) => setForm({ ...form, value: e.target.value })}
            />
            <TextField
              label="Moneda"
              fullWidth
              inputProps={{ maxLength: 3 }}
              value={form.currency}
              onChange={(e) => setForm({ ...form, currency: e.target.value.toUpperCase() })}
            />
            <TextField
              label="Probabilidad (%)"
              type="number"
              fullWidth
              value={form.probability}
              onChange={(e) => setForm({ ...form, probability: e.target.value })}
            />
          </Stack>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Cierre esperado"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={form.expectedClose}
              onChange={(e) => setForm({ ...form, expectedClose: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Prioridad</InputLabel>
              <Select
                value={form.priority}
                label="Prioridad"
                onChange={(e) =>
                  setForm({ ...form, priority: e.target.value as Priority })
                }
              >
                <MenuItem value="URGENT">Urgente</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="LOW">Baja</MenuItem>
              </Select>
            </FormControl>
          </Stack>

          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Origen"
              fullWidth
              value={form.source}
              onChange={(e) => setForm({ ...form, source: e.target.value })}
            />
            <TextField
              label="Tags (coma separado)"
              fullWidth
              value={form.tags}
              onChange={(e) => setForm({ ...form, tags: e.target.value })}
            />
          </Stack>
          <TextField
            label="Notas"
            fullWidth
            multiline
            rows={2}
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
          />
        </Stack>
      </FormDialog>

      <DeleteDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        itemName={
          deleteTarget ? `el deal "${deleteTarget.Name}" (${deleteTarget.DealCode})` : "este deal"
        }
        loading={deleteDeal.isPending}
      />

      <DeleteDialog
        open={bulkDeleteOpen}
        onClose={() => setBulkDeleteOpen(false)}
        onConfirm={runBulkDelete}
        itemName={`${bulkDeleteIds.length} deal${bulkDeleteIds.length === 1 ? "" : "s"}`}
        loading={deleteDeal.isPending}
      />

      <FormDialog
        open={bulkLoseOpen}
        onClose={() => {
          setBulkLoseOpen(false);
          setBulkLoseReason("");
        }}
        title={`Marcar ${bulkIds.length} deals como perdidos`}
        mode="edit"
        onSave={runBulkLose}
        loading={closeLost.isPending}
        disableSave={!bulkLoseReason.trim()}
        saveLabel="Marcar perdidos"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Razón de pérdida"
            fullWidth
            required
            multiline
            rows={2}
            value={bulkLoseReason}
            onChange={(e) => setBulkLoseReason(e.target.value)}
          />
        </Stack>
      </FormDialog>
    </Box>
  );
}
