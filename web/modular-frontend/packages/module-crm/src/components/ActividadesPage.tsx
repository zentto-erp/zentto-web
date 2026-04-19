"use client";

import React, { useCallback, useMemo, useState } from "react";
import {
  Box,
  Checkbox,
  MenuItem,
  Stack,
  TextField,
} from "@mui/material";
import dayjs from "dayjs";
import {
  ContextActionHeader,
  DatePicker,
  FormDialog,
  RightDetailDrawer,
  useDrawerQueryParam,
  ZenttoFilterPanel,
  ZenttoRecordTable,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { ActivityTypeChip } from "./shared/ActivityTypeChip";
import ActivityDetailPanel from "./ActivityDetailPanel";
import {
  useActivitiesList,
  useCompleteActivity,
  useCreateActivity,
  useDeleteActivity,
  useLeadsList,
  type Activity,
  type ActivityFilter,
} from "../hooks/useCRM";
import {
  ACTIVITY_STATUS_LABELS,
  ACTIVITY_TYPE_LABELS,
  ACTIVITY_TYPE_VALUES,
  type ActivityType,
} from "../types";

const GRID_ID = "module-crm:actividades:list";

const emptyForm = {
  leadId: "" as number | string,
  activityType: "CALL" as ActivityType,
  subject: "",
  description: "",
  dueDate: "",
};

// Helpers que leen filtros desde la URL query — fuente de verdad es la URL.
function readUrlParam(search: URLSearchParams, key: string): string {
  return search.get(key) ?? "";
}

export default function ActividadesPage() {
  /* ─── URL query como fuente de verdad para filtros ────────── */
  const urlSearch =
    typeof window !== "undefined" ? new URLSearchParams(window.location.search) : new URLSearchParams();

  const [filterValues, setFilterValues] = useState<Record<string, string>>(() => ({
    type: readUrlParam(urlSearch, "type"),
    status: readUrlParam(urlSearch, "status"),
    assignedTo: readUrlParam(urlSearch, "assignedTo"),
    leadId: readUrlParam(urlSearch, "leadId"),
    dueFrom: readUrlParam(urlSearch, "dueFrom"),
    dueTo: readUrlParam(urlSearch, "dueTo"),
    createdFrom: readUrlParam(urlSearch, "createdFrom"),
    createdTo: readUrlParam(urlSearch, "createdTo"),
  }));
  const [searchValue, setSearchValue] = useState<string>(() => readUrlParam(urlSearch, "q"));

  /* ─── Sincroniza filtros ↔ URL (sin recargar) ──────────────── */
  const syncUrl = useCallback((next: Record<string, string>, q: string) => {
    if (typeof window === "undefined") return;
    const params = new URLSearchParams(window.location.search);
    for (const [k, v] of Object.entries(next)) {
      if (v) params.set(k, v);
      else params.delete(k);
    }
    if (q) params.set("q", q);
    else params.delete("q");
    const qs = params.toString();
    const url = qs ? `${window.location.pathname}?${qs}` : window.location.pathname;
    window.history.replaceState(null, "", url);
  }, []);

  const handleFiltersChange = useCallback(
    (next: Record<string, string>) => {
      setFilterValues(next);
      syncUrl(next, searchValue);
    },
    [syncUrl, searchValue],
  );

  const handleSearchChange = useCallback(
    (q: string) => {
      setSearchValue(q);
      syncUrl(filterValues, q);
    },
    [syncUrl, filterValues],
  );

  /* ─── Drawer ?activity=<id> ────────────────────────────────── */
  const activityDrawer = useDrawerQueryParam("activity");
  const drawerActivityId = activityDrawer.id ? Number(activityDrawer.id) : null;

  /* ─── Data ─────────────────────────────────────────────────── */
  const apiFilter: ActivityFilter = useMemo(() => {
    const f: ActivityFilter = { page: 1, limit: 25 };
    if (filterValues.type) f.type = filterValues.type;
    if (filterValues.leadId) f.leadId = Number(filterValues.leadId);
    if (filterValues.status === "completed") f.isCompleted = true;
    if (filterValues.status === "pending") f.isCompleted = false;
    return f;
  }, [filterValues]);

  const { data, isLoading, error, refetch } = useActivitiesList(apiFilter);
  const { data: leadsData } = useLeadsList({ limit: 500 });
  const createActivity = useCreateActivity();
  const completeActivity = useCompleteActivity();
  const deleteActivity = useDeleteActivity();

  const rowsRaw: Activity[] =
    ((data as any)?.data ?? (data as any)?.rows ?? []) as Activity[];
  const totalCount = (data as any)?.totalCount ?? (data as any)?.TotalCount ?? rowsRaw.length;

  // Filtros de cliente — search q + rangos de fecha + assignedTo/owner.
  const rows: Activity[] = useMemo(() => {
    const q = searchValue.trim().toLowerCase();
    return rowsRaw.filter((a) => {
      if (q) {
        const hay =
          (a.Subject ?? "").toLowerCase().includes(q) ||
          (a.Description ?? "").toLowerCase().includes(q) ||
          (a.LeadCode ?? "").toLowerCase().includes(q) ||
          (a.AssignedToName ?? "").toLowerCase().includes(q);
        if (!hay) return false;
      }
      if (filterValues.assignedTo) {
        const aid = String(a.AssignedTo ?? "");
        if (aid !== filterValues.assignedTo) return false;
      }
      if (filterValues.dueFrom && a.DueDate && a.DueDate < filterValues.dueFrom) return false;
      if (filterValues.dueTo && a.DueDate && a.DueDate > filterValues.dueTo) return false;
      if (filterValues.createdFrom && a.CreatedAt && a.CreatedAt.slice(0, 10) < filterValues.createdFrom) return false;
      if (filterValues.createdTo && a.CreatedAt && a.CreatedAt.slice(0, 10) > filterValues.createdTo) return false;
      return true;
    });
  }, [rowsRaw, searchValue, filterValues]);

  // Rows para el grid — inyectamos `id` (rowKey por defecto) para selección.
  const gridRows = useMemo(
    () => rows.map((r) => ({ ...r, id: r.ActivityId } as unknown as Record<string, unknown>)),
    [rows],
  );

  /* ─── Leads para filtro select ─────────────────────────────── */
  const leads: Array<{ LeadId: number; LeadCode: string; ContactName: string }> = useMemo(() => {
    const raw = ((leadsData as any)?.data ?? (leadsData as any)?.rows ?? leadsData ?? []) as any[];
    return raw.map((l) => ({ LeadId: l.LeadId, LeadCode: l.LeadCode, ContactName: l.ContactName }));
  }, [leadsData]);

  /* ─── Owners únicos para filtro Owner ──────────────────────── */
  const owners = useMemo(() => {
    const map = new Map<string, string>();
    rowsRaw.forEach((a) => {
      if (a.AssignedTo) {
        map.set(String(a.AssignedTo), a.AssignedToName ?? String(a.AssignedTo));
      }
    });
    return Array.from(map.entries()).map(([value, label]) => ({ value, label }));
  }, [rowsRaw]);

  /* ─── Columnas ─────────────────────────────────────────────── */
  const columns: ColumnDef[] = useMemo(
    () => [
      {
        field: "ActivityType",
        header: "Tipo",
        width: 140,
        renderCell: ((value: unknown) => (
          <ActivityTypeChip type={value as string} />
        )) as unknown as ColumnDef["renderCell"],
      },
      {
        field: "Subject",
        header: "Asunto",
        flex: 1,
        minWidth: 200,
      },
      {
        field: "LeadCode",
        header: "Lead",
        width: 120,
      },
      {
        field: "AssignedToName",
        header: "Owner",
        width: 150,
      },
      {
        field: "IsCompleted",
        header: "Estado",
        width: 120,
        renderCell: ((value: unknown, row: GridRow) => (
          <Checkbox
            checked={!!value}
            onChange={() => {
              if (!value) completeActivity.mutate(row.ActivityId as number);
            }}
            disabled={!!value}
            size="small"
          />
        )) as unknown as ColumnDef["renderCell"],
      },
      {
        field: "DueDate",
        header: "Fecha límite",
        width: 140,
      },
      {
        field: "CreatedAt",
        header: "Creada",
        width: 150,
      },
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
      },
    ],
    [completeActivity],
  );

  /* ─── Filtros FilterPanel ──────────────────────────────────── */
  const filterFields: FilterFieldDef[] = useMemo(
    () => [
      {
        field: "type",
        label: "Tipo",
        type: "select",
        options: ACTIVITY_TYPE_VALUES.map((v) => ({ value: v, label: ACTIVITY_TYPE_LABELS[v] })),
      },
      {
        field: "status",
        label: "Estado",
        type: "select",
        options: [
          { value: "pending", label: ACTIVITY_STATUS_LABELS.pending },
          { value: "completed", label: ACTIVITY_STATUS_LABELS.completed },
        ],
      },
      {
        field: "assignedTo",
        label: "Owner",
        type: "select",
        options: owners,
      },
      {
        field: "leadId",
        label: "Lead",
        type: "select",
        options: leads.map((l) => ({
          value: String(l.LeadId),
          label: `${l.LeadCode} — ${l.ContactName}`,
        })),
        minWidth: 220,
      },
      { field: "dueFrom", label: "Vence desde", type: "date" },
      { field: "dueTo", label: "Vence hasta", type: "date" },
      { field: "createdFrom", label: "Creada desde", type: "date" },
      { field: "createdTo", label: "Creada hasta", type: "date" },
    ],
    [owners, leads],
  );

  /* ─── Dialog Crear ─────────────────────────────────────────── */
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState(emptyForm);

  const openCreate = () => {
    setForm(emptyForm);
    setCreateOpen(true);
  };

  const handleCreate = () => {
    createActivity.mutate(
      { ...form, leadId: form.leadId ? Number(form.leadId) : undefined },
      {
        onSuccess: () => {
          setCreateOpen(false);
          setForm(emptyForm);
        },
      },
    );
  };

  /* ─── Delete confirm ───────────────────────────────────────── */
  const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);

  const handleDeleteConfirmed = () => {
    if (confirmDeleteId == null) return;
    deleteActivity.mutate(confirmDeleteId, {
      onSuccess: () => setConfirmDeleteId(null),
    });
  };

  /* ─── Bulk actions ─────────────────────────────────────────── */
  const [selection, setSelection] = useState<Array<string | number>>([]);

  const bulkActions = useMemo(
    () => [
      {
        id: "complete",
        label: "Marcar completada",
        variant: "primary" as const,
        onClick: async (ids: Array<string | number>) => {
          await Promise.all(ids.map((id) => completeActivity.mutateAsync(Number(id))));
          setSelection([]);
        },
      },
      {
        id: "reassign",
        label: "Reasignar",
        onClick: (_ids: Array<string | number>) => {
          // TODO futuro: abrir dialog de reasignación con selector de usuario.
          // Por ahora es un placeholder porque no hay selector de usuarios.
          window.alert("Reasignar: selector de usuarios pendiente de diseño (CRM-107).");
        },
      },
      {
        id: "delete",
        label: "Eliminar",
        variant: "danger" as const,
        onClick: async (ids: Array<string | number>) => {
          if (!window.confirm(`¿Eliminar ${ids.length} actividades?`)) return;
          await Promise.all(ids.map((id) => deleteActivity.mutateAsync(Number(id))));
          setSelection([]);
        },
      },
    ],
    [completeActivity, deleteActivity],
  );

  /* ─── Action handlers ──────────────────────────────────────── */
  const handleAction = useCallback(
    (action: string, row: Activity) => {
      if (action === "view") {
        activityDrawer.openDrawer(row.ActivityId);
      } else if (action === "edit") {
        // Edit usa el drawer que embebe ActivityDetailPanel con su propio edit dialog.
        activityDrawer.openDrawer(row.ActivityId);
      } else if (action === "delete") {
        setConfirmDeleteId(row.ActivityId);
      }
    },
    [activityDrawer],
  );

  const handleRowOpen = useCallback(
    (id: string | number) => {
      activityDrawer.openDrawer(id);
    },
    [activityDrawer],
  );

  /* ─── Wire <zentto-grid> action-click (custom event del grid) ─ */
  // ZenttoRecordTable no expone aún action-click; lo escuchamos en el wrapper
  // montado ya que el grid está embebido dentro. Se hace vía delegación:
  // usamos un efecto global sobre el grid-id.
  React.useEffect(() => {
    if (typeof document === "undefined") return;
    const el = document.querySelector(`zentto-grid[grid-id="${GRID_ID}"]`);
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action?: string; row?: Activity };
      if (!detail?.action || !detail.row) return;
      handleAction(detail.action, detail.row);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [handleAction, gridRows.length]);

  /* ─── Render ───────────────────────────────────────────────── */
  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Actividades" />

      <ZenttoRecordTable<Record<string, unknown>>
        recordType="activity"
        gridId={GRID_ID}
        rows={gridRows}
        columns={columns as any}
        loading={isLoading}
        error={error ? String((error as any)?.message ?? error) : null}
        onRetry={() => refetch()}
        rowKey="id"
        totalCount={totalCount}
        onOpenRecord={handleRowOpen}
        bulkActions={bulkActions}
        selection={selection}
        onSelectionChange={(ids) => setSelection(ids)}
        createLabel="Nueva Actividad"
        onCreate={openCreate}
        emptyState={{
          title: "Sin actividades",
          description: "Registra llamadas, reuniones, notas o tareas para dar seguimiento a tus leads.",
          primaryAction: { label: "Crear primer actividad", onClick: openCreate },
        }}
        filterPanel={
          <ZenttoFilterPanel
            filters={filterFields}
            values={filterValues}
            onChange={handleFiltersChange}
            searchPlaceholder="Buscar por asunto, descripción, lead u owner…"
            searchValue={searchValue}
            onSearchChange={handleSearchChange}
          />
        }
      />

      {/* Drawer de detalle */}
      <RightDetailDrawer
        open={activityDrawer.open && drawerActivityId !== null}
        onClose={activityDrawer.closeDrawer}
        title="Detalle de actividad"
        subtitle={drawerActivityId ? `#${drawerActivityId}` : undefined}
      >
        {drawerActivityId !== null && (
          <ActivityDetailPanel
            activityId={drawerActivityId}
            onClose={activityDrawer.closeDrawer}
            initialActivity={rowsRaw.find((r) => r.ActivityId === drawerActivityId) ?? null}
          />
        )}
      </RightDetailDrawer>

      {/* Dialog Crear Actividad */}
      <FormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Nueva Actividad"
        onSave={handleCreate}
        loading={createActivity.isPending}
        disableSave={!form.subject.trim()}
        saveLabel="Crear"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            select
            label="Tipo de actividad"
            fullWidth
            value={form.activityType}
            onChange={(e) => setForm({ ...form, activityType: e.target.value as ActivityType })}
          >
            {ACTIVITY_TYPE_VALUES.map((v) => (
              <MenuItem key={v} value={v}>
                {ACTIVITY_TYPE_LABELS[v]}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            label="Asunto"
            fullWidth
            required
            value={form.subject}
            onChange={(e) => setForm({ ...form, subject: e.target.value })}
          />
          <TextField
            label="Descripción"
            fullWidth
            multiline
            rows={3}
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <DatePicker
            label="Fecha límite"
            value={form.dueDate ? dayjs(form.dueDate) : null}
            onChange={(v) => setForm({ ...form, dueDate: v ? v.format("YYYY-MM-DD") : "" })}
            slotProps={{ textField: { size: "small", fullWidth: true } }}
          />
          <TextField
            select
            label="Lead (opcional)"
            fullWidth
            value={form.leadId === "" ? "" : String(form.leadId)}
            onChange={(e) =>
              setForm({ ...form, leadId: e.target.value ? Number(e.target.value) : "" })
            }
            helperText="Dejar vacío si no está asociado a un lead"
          >
            <MenuItem value="">
              <em>— Sin lead asociado —</em>
            </MenuItem>
            {leads.map((l) => (
              <MenuItem key={l.LeadId} value={String(l.LeadId)}>
                {l.LeadCode} — {l.ContactName}
              </MenuItem>
            ))}
          </TextField>
        </Stack>
      </FormDialog>

      {/* Confirm delete (single row) */}
      <FormDialog
        open={confirmDeleteId !== null}
        onClose={() => setConfirmDeleteId(null)}
        title="Eliminar actividad"
        mode="edit"
        saveLabel="Eliminar"
        onSave={handleDeleteConfirmed}
        loading={deleteActivity.isPending}
      >
        <Box>¿Seguro que deseas eliminar esta actividad? Esta acción no se puede deshacer.</Box>
      </FormDialog>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-grid": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}
