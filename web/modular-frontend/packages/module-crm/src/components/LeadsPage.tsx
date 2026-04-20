"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams, usePathname } from "next/navigation";
import {
  Box,
  TextField,
  Chip,
  Stack,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from "@mui/material";
import AssignmentIndIcon from "@mui/icons-material/AssignmentInd";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import DownloadIcon from "@mui/icons-material/Download";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import { formatCurrency } from "@zentto/shared-api";
import {
  ModulePageShell,
  RightDetailDrawer,
  useDrawerQueryParam,
  ZenttoRecordTable,
  ZenttoFilterPanel,
  FormDialog,
  ConfirmDialog,
  DeleteDialog,
  useToast,
  type ColumnSpec,
  type BulkAction,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import LeadDetailPanel from "./LeadDetailPanel";
import {
  useLeadsList,
  usePipelinesList,
  usePipelineStages,
  useCreateLead,
  useUpdateLead,
  useDeleteLead,
  useMoveLeadStage,
  useWinLead,
  useLoseLead,
  type Lead,
  type LeadFilter,
} from "../hooks/useCRM";
import {
  PRIORITY_COLORS,
  PRIORITY_LABELS,
  LEAD_STATUS_LABELS,
  type Priority,
} from "../types";

const priorityColor: Record<Priority, "error" | "warning" | "info"> = PRIORITY_COLORS;
const priorityLabel: Record<Priority, string> = PRIORITY_LABELS;

const statusColor: Record<string, "success" | "error" | "info" | "default"> = {
  OPEN: "info",
  WON: "success",
  LOST: "error",
};

const statusLabel: Record<string, string> = LEAD_STATUS_LABELS;

const emptyLead = {
  contactName: "",
  companyName: "",
  email: "",
  phone: "",
  estimatedValue: "",
  priority: "MEDIUM",
  source: "",
  notes: "",
  pipelineId: "" as number | string,
  stageId: "" as number | string,
};

const GRID_ID = "module-crm:leads:list";
const RECORD_TYPE = "lead";

/** Query-string keys persistidos para compartir / recargar. */
const QS_KEYS = {
  search: "q",
  status: "status",
  pipeline: "pipeline",
  stage: "stage",
  priority: "priority",
  source: "source",
  assigned: "assigned",
  createdFrom: "from",
  createdTo: "to",
} as const;

type FilterDraft = Partial<Record<keyof typeof QS_KEYS, string>>;

export default function LeadsPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { showToast } = useToast();

  /* ─── Filter state desde URL ─── */
  const filterFromUrl = useMemo<FilterDraft>(() => {
    const out: FilterDraft = {};
    (Object.keys(QS_KEYS) as Array<keyof typeof QS_KEYS>).forEach((k) => {
      const v = searchParams?.get(QS_KEYS[k]);
      if (v) out[k] = v;
    });
    return out;
  }, [searchParams]);

  const filter: LeadFilter = useMemo(() => ({
    page: 1,
    limit: 25,
    search: filterFromUrl.search || undefined,
    status: filterFromUrl.status || undefined,
    pipelineId: filterFromUrl.pipeline ? Number(filterFromUrl.pipeline) : undefined,
    stageId: filterFromUrl.stage ? Number(filterFromUrl.stage) : undefined,
    priority: (filterFromUrl.priority as Priority) || undefined,
    assignedTo: filterFromUrl.assigned ? Number(filterFromUrl.assigned) : undefined,
  }), [filterFromUrl]);

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

  /* ─── Drawer detalle ─── */
  const leadDrawer = useDrawerQueryParam("lead");
  const drawerLeadId = leadDrawer.id ? Number(leadDrawer.id) : null;

  /* ─── Queries ─── */
  const { data, isLoading, error, refetch } = useLeadsList(filter);
  const { data: pipelinesData } = usePipelinesList();
  const pipelines = (pipelinesData as any)?.data ?? (pipelinesData as any)?.rows ?? pipelinesData ?? [];

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyLead);

  const selectedPipelineId =
    typeof form.pipelineId === "number"
      ? form.pipelineId
      : filterFromUrl.pipeline
        ? Number(filterFromUrl.pipeline)
        : undefined;
  const { data: stagesData } = usePipelineStages(selectedPipelineId);
  const stages = (stagesData as any)?.data ?? (stagesData as any)?.rows ?? stagesData ?? [];

  /* ─── Mutations ─── */
  const createLead = useCreateLead();
  const updateLead = useUpdateLead();
  const deleteLead = useDeleteLead();
  const moveStage = useMoveLeadStage();
  const winLead = useWinLead();
  const loseLead = useLoseLead();

  /* ─── Delete dialog ─── */
  const [deleteTarget, setDeleteTarget] = useState<Lead | null>(null);

  /* ─── Bulk dialogs ─── */
  const [bulkMoveOpen, setBulkMoveOpen] = useState(false);
  const [bulkMoveStageId, setBulkMoveStageId] = useState<number | "">("");
  const [bulkIds, setBulkIds] = useState<Array<string | number>>([]);
  const [bulkLoseOpen, setBulkLoseOpen] = useState(false);
  const [bulkLoseReason, setBulkLoseReason] = useState("");
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  /* ─── Data helpers ─── */
  const rows = (data as any)?.data ?? (data as any)?.rows ?? [];
  const totalCount = (data as any)?.totalCount ?? (data as any)?.TotalCount ?? rows.length;
  const typedRows = rows as Lead[];

  /* ─── Columnas ─── */
  const columns: ColumnSpec[] = useMemo(
    () => [
      { field: "LeadCode", header: "Código", width: 110 },
      { field: "ContactName", header: "Contacto", flex: 1, minWidth: 160 },
      { field: "CompanyName", header: "Empresa", width: 160 },
      { field: "Email", header: "Email", width: 180 },
      { field: "Phone", header: "Teléfono", width: 130 },
      { field: "StageName", header: "Etapa", width: 130 },
      {
        field: "EstimatedValue",
        header: "Valor Est.",
        width: 130,
        renderCell: (value: unknown) => formatCurrency(value as number),
      } as ColumnSpec,
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
            label={statusLabel[value as string] ?? (value as string)}
            size="small"
            color={statusColor[value as string] ?? "default"}
          />
        )) as unknown,
      } as ColumnSpec,
      { field: "Source", header: "Origen", width: 110 },
      { field: "AssignedToName", header: "Asignado a", width: 140 },
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

  /* ─── Filtros (ZenttoFilterPanel) ─── */
  const filterFields: FilterFieldDef[] = useMemo(() => {
    const fields: FilterFieldDef[] = [
      {
        field: "status",
        label: "Estado",
        type: "select",
        options: [
          { value: "OPEN", label: "Abierto" },
          { value: "WON", label: "Ganado" },
          { value: "LOST", label: "Perdido" },
          { value: "ARCHIVED", label: "Archivado" },
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
      {
        field: "source",
        label: "Origen",
        type: "text",
        placeholder: "Origen del lead",
      },
      {
        field: "createdFrom",
        label: "Creado desde",
        type: "date",
      },
      {
        field: "createdTo",
        label: "Creado hasta",
        type: "date",
      },
    ];
    return fields;
  }, [pipelines, stages]);

  const filterValues: Record<string, string> = useMemo(
    () => ({
      status: filterFromUrl.status ?? "",
      pipeline: filterFromUrl.pipeline ?? "",
      stage: filterFromUrl.stage ?? "",
      priority: filterFromUrl.priority ?? "",
      source: filterFromUrl.source ?? "",
      createdFrom: filterFromUrl.createdFrom ?? "",
      createdTo: filterFromUrl.createdTo ?? "",
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
        source: next.source,
        createdFrom: next.createdFrom,
        createdTo: next.createdTo,
      });
    },
    [updateQuery],
  );

  const handleSearchChange = useCallback(
    (v: string) => {
      updateQuery({ search: v });
    },
    [updateQuery],
  );

  /* ─── Dialog crear/editar ─── */
  const handleOpenNew = useCallback(() => {
    setEditId(null);
    setForm({
      ...emptyLead,
      pipelineId: (pipelines as Array<any>)[0]?.PipelineId ?? "",
    });
    setDialogOpen(true);
  }, [pipelines]);

  const handleEdit = useCallback((lead: Lead) => {
    setEditId(lead.LeadId);
    setForm({
      contactName: lead.ContactName,
      companyName: lead.CompanyName ?? "",
      email: lead.Email ?? "",
      phone: lead.Phone ?? "",
      estimatedValue: String(lead.EstimatedValue ?? ""),
      priority: lead.Priority,
      source: lead.Source ?? "",
      notes: lead.Notes ?? "",
      pipelineId: lead.PipelineId,
      stageId: lead.StageId,
    });
    setDialogOpen(true);
  }, []);

  const handleSave = useCallback(() => {
    const payload = {
      ...form,
      estimatedValue: Number(form.estimatedValue) || 0,
      pipelineId: Number(form.pipelineId),
      stageId: Number(form.stageId),
    };

    if (editId) {
      updateLead.mutate(
        { id: editId, ...payload },
        {
          onSuccess: () => {
            setDialogOpen(false);
            showToast("Lead actualizado", "success");
          },
        },
      );
    } else {
      createLead.mutate(payload, {
        onSuccess: () => {
          setDialogOpen(false);
          showToast("Lead creado", "success");
        },
      });
    }
  }, [form, editId, createLead, updateLead, showToast]);

  /* ─── Handlers fila ─── */
  const handleOpenRecord = useCallback(
    (id: string | number) => {
      leadDrawer.openDrawer(id);
    },
    [leadDrawer],
  );

  const handleActionClick = useCallback(
    (row: Lead, action: string) => {
      if (action === "view") leadDrawer.openDrawer(row.LeadId);
      else if (action === "edit") handleEdit(row);
      else if (action === "delete") setDeleteTarget(row);
    },
    [leadDrawer, handleEdit],
  );

  /* ─── Listener action-click del <zentto-grid> interno ─── */
  useEffect(() => {
    const el = document.querySelector<HTMLElement>(`zentto-grid[grid-id="${GRID_ID}"]`);
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action?: string; row?: Lead };
      const action = detail?.action;
      const row = detail?.row;
      if (!action || !row) return;
      handleActionClick(row, action);
    };
    el.addEventListener("action-click", handler as EventListener);
    return () => el.removeEventListener("action-click", handler as EventListener);
  }, [handleActionClick]);

  /* ─── Confirmar delete individual ─── */
  const confirmDelete = useCallback(() => {
    if (!deleteTarget) return;
    deleteLead.mutate(deleteTarget.LeadId, {
      onSuccess: () => {
        showToast("Lead archivado", "success");
        setDeleteTarget(null);
      },
    });
  }, [deleteLead, deleteTarget, showToast]);

  /* ─── Bulk actions ─── */
  const exportCsv = useCallback(
    (ids: Array<string | number>) => {
      const selectedRows = typedRows.filter((r) => ids.includes(r.LeadId));
      if (selectedRows.length === 0) return;
      const headers = [
        "LeadCode",
        "ContactName",
        "CompanyName",
        "Email",
        "Phone",
        "StageName",
        "EstimatedValue",
        "Priority",
        "Status",
        "Source",
        "AssignedToName",
      ];
      const escape = (v: unknown) => {
        const s = v == null ? "" : String(v);
        return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
      };
      const lines = [
        headers.join(","),
        ...selectedRows.map((r) =>
          headers.map((h) => escape((r as any)[h])).join(","),
        ),
      ];
      const csv = lines.join("\n");
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `crm-leads-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      showToast(`${selectedRows.length} leads exportados`, "success");
    },
    [typedRows, showToast],
  );

  const bulkMarkWon = useCallback(
    async (ids: Array<string | number>) => {
      const numeric = ids.map((id) => Number(id));
      // TODO follow-up: crear `usp_crm_lead_bulk_close` para bajar a una llamada.
      await Promise.all(numeric.map((id) => winLead.mutateAsync({ id })));
      showToast(`${numeric.length} leads marcados como ganados`, "success");
    },
    [winLead, showToast],
  );

  const bulkAssign = useCallback(
    (_ids: Array<string | number>) => {
      // TODO follow-up: abrir selector de usuarios y llamar `usp_crm_lead_bulk_assign`.
      showToast(
        "Reasignar masivo pendiente — requiere selector de usuarios (follow-up)",
        "info",
      );
    },
    [showToast],
  );

  const runBulkMove = useCallback(async () => {
    if (!bulkMoveStageId) return;
    const numeric = bulkIds.map((id) => Number(id));
    // TODO follow-up: crear `usp_crm_lead_bulk_move_stage`.
    await Promise.all(
      numeric.map((id) =>
        moveStage.mutateAsync({ leadId: id, newStageId: Number(bulkMoveStageId) }),
      ),
    );
    showToast(`${numeric.length} leads movidos de etapa`, "success");
    setBulkMoveOpen(false);
    setBulkMoveStageId("");
    setBulkIds([]);
  }, [bulkIds, bulkMoveStageId, moveStage, showToast]);

  const runBulkLose = useCallback(async () => {
    if (!bulkLoseReason.trim()) return;
    const numeric = bulkIds.map((id) => Number(id));
    await Promise.all(
      numeric.map((id) => loseLead.mutateAsync({ id, reason: bulkLoseReason })),
    );
    showToast(`${numeric.length} leads marcados perdidos`, "success");
    setBulkLoseOpen(false);
    setBulkLoseReason("");
    setBulkIds([]);
  }, [bulkIds, bulkLoseReason, loseLead, showToast]);

  const runBulkDelete = useCallback(async () => {
    const numeric = bulkIds.map((id) => Number(id));
    await Promise.all(numeric.map((id) => deleteLead.mutateAsync(id)));
    showToast(`${numeric.length} leads archivados`, "success");
    setBulkDeleteOpen(false);
    setBulkIds([]);
  }, [bulkIds, deleteLead, showToast]);

  const bulkActions: BulkAction[] = useMemo(
    () => [
      {
        id: "assign",
        label: "Asignar",
        icon: <AssignmentIndIcon fontSize="small" />,
        onClick: (ids) => bulkAssign(ids),
      },
      {
        id: "move-stage",
        label: "Mover etapa",
        icon: <SwapHorizIcon fontSize="small" />,
        onClick: (ids) => {
          setBulkIds(ids);
          setBulkMoveOpen(true);
        },
      },
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
          setBulkIds(ids);
          setBulkDeleteOpen(true);
        },
      },
    ],
    [bulkAssign, bulkMarkWon, exportCsv],
  );

  /* ─── Render ─── */
  return (
    <ModulePageShell sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <ZenttoRecordTable
          recordType={RECORD_TYPE}
          gridId={GRID_ID}
          rowKey="LeadId"
          rows={typedRows as unknown as Record<string, unknown>[]}
          columns={columns}
          loading={isLoading}
          error={error ? String((error as any)?.message ?? error) : null}
          onRetry={() => refetch()}
          totalCount={totalCount}
          onOpenRecord={handleOpenRecord}
          onCreate={handleOpenNew}
          createLabel="Nuevo Lead"
          bulkActions={bulkActions}
          emptyState={{
            title: "Sin leads todavía",
            description:
              "Crea tu primer lead para empezar a gestionar oportunidades en el pipeline.",
            primaryAction: {
              label: "Crear primer lead",
              onClick: handleOpenNew,
            },
            secondaryAction: {
              label: "Importar CSV",
              onClick: () =>
                showToast(
                  "Importación CSV pendiente (follow-up CRM-110)",
                  "info",
                ),
            },
          }}
          gridAttrs={{
            "export-filename": "crm-leads-list",
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
              searchPlaceholder="Buscar lead (código, contacto, empresa…)"
              searchValue={filterFromUrl.search ?? ""}
              onSearchChange={handleSearchChange}
            />
          }
        />
      </Box>

      {/* ─── Drawer detalle (deep-link ?lead=<id>) ─── */}
      <RightDetailDrawer
        open={leadDrawer.open && drawerLeadId !== null}
        onClose={leadDrawer.closeDrawer}
        title="Detalle del lead"
        subtitle={drawerLeadId ? `#${drawerLeadId}` : undefined}
      >
        {drawerLeadId && (
          <LeadDetailPanel leadId={drawerLeadId} onClose={leadDrawer.closeDrawer} />
        )}
      </RightDetailDrawer>

      {/* ─── FormDialog crear/editar ─── */}
      <FormDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        title={editId ? "Editar lead" : "Nuevo lead"}
        mode={editId ? "edit" : "create"}
        onSave={handleSave}
        loading={createLead.isPending || updateLead.isPending}
        disableSave={!form.contactName.trim()}
        saveLabel={editId ? "Guardar" : "Crear"}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre de contacto"
            fullWidth
            required
            value={form.contactName}
            onChange={(e) => setForm({ ...form, contactName: e.target.value })}
            onKeyDown={(e) => {
              if ((e.metaKey || e.ctrlKey) && e.key === "Enter") handleSave();
            }}
          />
          <TextField
            label="Empresa"
            fullWidth
            value={form.companyName}
            onChange={(e) => setForm({ ...form, companyName: e.target.value })}
          />
          <Stack direction="row" spacing={2}>
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            <FormControl fullWidth>
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
            <FormControl fullWidth>
              <InputLabel>Etapa</InputLabel>
              <Select
                value={form.stageId}
                label="Etapa"
                onChange={(e) => setForm({ ...form, stageId: Number(e.target.value) })}
              >
                {(stages as Array<any>).map((s) => (
                  <MenuItem key={s.StageId} value={s.StageId}>
                    {s.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
          <Stack direction="row" spacing={2}>
            <TextField
              label="Valor estimado"
              fullWidth
              type="number"
              value={form.estimatedValue}
              onChange={(e) => setForm({ ...form, estimatedValue: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Prioridad</InputLabel>
              <Select
                value={form.priority}
                label="Prioridad"
                onChange={(e) => setForm({ ...form, priority: String(e.target.value) })}
              >
                <MenuItem value="URGENT">Urgente</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="LOW">Baja</MenuItem>
              </Select>
            </FormControl>
          </Stack>
          <TextField
            label="Origen"
            fullWidth
            value={form.source}
            onChange={(e) => setForm({ ...form, source: e.target.value })}
          />
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

      {/* ─── Delete individual ─── */}
      <DeleteDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        itemName={
          deleteTarget
            ? `el lead "${deleteTarget.ContactName}" (${deleteTarget.LeadCode})`
            : "este lead"
        }
        loading={deleteLead.isPending}
      />

      {/* ─── Bulk move stage ─── */}
      <FormDialog
        open={bulkMoveOpen}
        onClose={() => {
          setBulkMoveOpen(false);
          setBulkMoveStageId("");
        }}
        title={`Mover ${bulkIds.length} leads a otra etapa`}
        mode="edit"
        onSave={runBulkMove}
        loading={moveStage.isPending}
        disableSave={!bulkMoveStageId}
        saveLabel="Mover"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <FormControl fullWidth>
            <InputLabel>Nueva etapa</InputLabel>
            <Select
              value={bulkMoveStageId}
              label="Nueva etapa"
              onChange={(e) => setBulkMoveStageId(Number(e.target.value))}
            >
              {(stages as Array<any>).map((s) => (
                <MenuItem key={s.StageId} value={s.StageId}>
                  {s.Name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Stack>
      </FormDialog>

      {/* ─── Bulk marcar perdido ─── */}
      <FormDialog
        open={bulkLoseOpen}
        onClose={() => {
          setBulkLoseOpen(false);
          setBulkLoseReason("");
        }}
        title={`Marcar ${bulkIds.length} leads como perdidos`}
        mode="edit"
        onSave={runBulkLose}
        loading={loseLead.isPending}
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

      {/* ─── Bulk delete ─── */}
      <ConfirmDialog
        open={bulkDeleteOpen}
        onClose={() => setBulkDeleteOpen(false)}
        onConfirm={runBulkDelete}
        title="Eliminar leads seleccionados"
        message={`¿Seguro que deseas archivar ${bulkIds.length} lead${bulkIds.length === 1 ? "" : "s"}? Esta acción cambia el estado a ARCHIVED y puede revertirse editando el lead.`}
        confirmLabel="Archivar"
        variant="danger"
        loading={deleteLead.isPending}
      />
    </ModulePageShell>
  );
}
