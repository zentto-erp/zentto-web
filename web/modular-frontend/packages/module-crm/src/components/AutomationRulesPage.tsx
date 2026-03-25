"use client";

import React, { useState, useEffect, useRef, useMemo } from "react";
import {
  Box,
  Typography,
  Button,
  Stack,
  Chip,
  Switch,
  TextField,
  MenuItem,
  FormControlLabel,
  Alert,
  CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import SmartToyIcon from "@mui/icons-material/SmartToy";
import { 
  FormDialog,
  DeleteDialog,
  ZenttoFilterPanel,
  type FilterFieldDef } from "@zentto/shared-ui";
import {
  useAutomationRules,
  useUpsertRule,
  useDeleteRule,
  type AutomationRule,
} from "../hooks/useCRMAutomation";
import { usePipelineStages } from "../hooks/useCRM";
import type { ColumnDef } from "@zentto/datagrid-core";

/* ─── Trigger / Action labels & colors ───────────────────────── */

const TRIGGER_LABELS: Record<string, string> = {
  LEAD_STALE: "Lead estancado",
  STAGE_CHANGE: "Cambio de etapa",
  NO_ACTIVITY: "Sin actividad",
  SCORE_BELOW: "Score bajo",
  LEAD_CREATED: "Lead creado",
};

const TRIGGER_COLORS: Record<string, "warning" | "info" | "error" | "success" | "default"> = {
  LEAD_STALE: "warning",
  STAGE_CHANGE: "info",
  NO_ACTIVITY: "error",
  SCORE_BELOW: "error",
  LEAD_CREATED: "success",
};

const ACTION_LABELS: Record<string, string> = {
  NOTIFY: "Notificar",
  ASSIGN: "Asignar",
  MOVE_STAGE: "Mover etapa",
  CREATE_ACTIVITY: "Crear actividad",
  SEND_EMAIL: "Enviar email",
};

const ACTION_COLORS: Record<string, "primary" | "secondary" | "warning" | "info" | "success"> = {
  NOTIFY: "info",
  ASSIGN: "secondary",
  MOVE_STAGE: "warning",
  CREATE_ACTIVITY: "primary",
  SEND_EMAIL: "success",
};

const TRIGGER_OPTIONS = [
  { value: "LEAD_STALE", label: "Lead estancado" },
  { value: "STAGE_CHANGE", label: "Cambio de etapa" },
  { value: "NO_ACTIVITY", label: "Sin actividad" },
  { value: "SCORE_BELOW", label: "Score bajo" },
  { value: "LEAD_CREATED", label: "Lead creado" },
];

const ACTION_OPTIONS = [
  { value: "NOTIFY", label: "Notificar" },
  { value: "ASSIGN", label: "Asignar" },
  { value: "MOVE_STAGE", label: "Mover etapa" },
  { value: "CREATE_ACTIVITY", label: "Crear actividad" },
  { value: "SEND_EMAIL", label: "Enviar email" },
];

const ACTIVITY_TYPE_OPTIONS = [
  { value: "CALL", label: "Llamada" },
  { value: "EMAIL", label: "Email" },
  { value: "MEETING", label: "Reunion" },
  { value: "TASK", label: "Tarea" },
  { value: "NOTE", label: "Nota" },
];

/* ─── Empty form ──────────────────────────────────────────── */

interface RuleForm {
  RuleName: string;
  TriggerEvent: string;
  ConditionJson: Record<string, any>;
  ActionType: string;
  ActionConfig: Record<string, any>;
  IsActive: boolean;
  SortOrder: number;
}

const emptyForm: RuleForm = {
  RuleName: "",
  TriggerEvent: "LEAD_STALE",
  ConditionJson: {},
  ActionType: "NOTIFY",
  ActionConfig: {},
  IsActive: true,
  SortOrder: 0,
};

const AUTOMATION_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "true", label: "Activas" },
      { value: "false", label: "Inactivas" },
    ],
  },
];

/* ─── Main Component ──────────────────────────────────────── */

export default function AutomationRulesPage() {
  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data: rulesRaw, isLoading } = useAutomationRules();
  const upsertMutation = useUpsertRule();
  const deleteMutation = useDeleteRule();

  const allRules: AutomationRule[] = useMemo(() => {
    if (!rulesRaw) return [];
    return Array.isArray(rulesRaw) ? rulesRaw : (rulesRaw as any)?.data ?? [];
  }, [rulesRaw]);

  const rules = useMemo(() => {
    let filtered = allRules;
    if (filterValues.estado === "true") filtered = filtered.filter((r) => r.IsActive);
    if (filterValues.estado === "false") filtered = filtered.filter((r) => !r.IsActive);
    if (searchText) {
      const q = searchText.toLowerCase();
      filtered = filtered.filter((r) => r.RuleName.toLowerCase().includes(q));
    }
    return filtered;
  }, [allRules, filterValues, searchText]);

  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [searchText, setSearchText] = useState("");

  // Dialog state
  const [formOpen, setFormOpen] = useState(false);
  const [editRule, setEditRule] = useState<AutomationRule | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<AutomationRule | null>(null);
  const [form, setForm] = useState<RuleForm>(emptyForm);
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  // Stages for condition/action selects
  const { data: stagesRaw } = usePipelineStages(undefined);
  const stages = useMemo(() => {
    if (!stagesRaw) return [];
    return Array.isArray(stagesRaw) ? stagesRaw : (stagesRaw as any)?.data ?? [];
  }, [stagesRaw]);

  // Reset form when dialog opens
  useEffect(() => {
    if (formOpen) {
      if (editRule) {
        setForm({
          RuleName: editRule.RuleName,
          TriggerEvent: editRule.TriggerEvent,
          ConditionJson: editRule.ConditionJson ?? {},
          ActionType: editRule.ActionType,
          ActionConfig: editRule.ActionConfig ?? {},
          IsActive: editRule.IsActive,
          SortOrder: editRule.SortOrder,
        });
      } else {
        setForm(emptyForm);
      }
    }
  }, [formOpen, editRule]);

  // Open create dialog
  const handleCreate = () => {
    setEditRule(null);
    setFormOpen(true);
  };

  // Open edit dialog
  const handleRowClick = (row: AutomationRule) => {
    setEditRule(row);
    setFormOpen(true);
  };

  // Save
  const handleSave = async () => {
    await upsertMutation.mutateAsync({
      ...(editRule ? { RuleId: editRule.RuleId } : {}),
      RuleName: form.RuleName,
      TriggerEvent: form.TriggerEvent,
      ConditionJson: form.ConditionJson,
      ActionType: form.ActionType,
      ActionConfig: form.ActionConfig,
      IsActive: form.IsActive,
      SortOrder: form.SortOrder,
    });
    setFormOpen(false);
  };

  // Delete
  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    await deleteMutation.mutateAsync(deleteTarget.RuleId);
    setDeleteOpen(false);
    setDeleteTarget(null);
  };

  // Field updater
  const setField = <K extends keyof RuleForm>(key: K, value: RuleForm[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const setCondition = (key: string, value: any) =>
    setForm((prev) => ({
      ...prev,
      ConditionJson: { ...prev.ConditionJson, [key]: value },
    }));

  const setAction = (key: string, value: any) =>
    setForm((prev) => ({
      ...prev,
      ActionConfig: { ...prev.ActionConfig, [key]: value },
    }));

  /* ─── Columns ─────────────────────────────────────────────── */

  const columns: ColumnDef[] = [
    { field: "RuleName", header: "Nombre", flex: 1.5, minWidth: 200 },
    {
      field: "TriggerEvent",
      header: "Trigger",
      width: 160,
      renderCell: (params: any) => (
        <Chip
          label={TRIGGER_LABELS[params.value] ?? params.value}
          color={TRIGGER_COLORS[params.value] ?? "default"}
          size="small"
          variant="outlined"
        />
      ),
    },
    {
      field: "ActionType",
      header: "Accion",
      width: 160,
      renderCell: (params: any) => (
        <Chip
          label={ACTION_LABELS[params.value] ?? params.value}
          color={ACTION_COLORS[params.value] ?? "primary"}
          size="small"
        />
      ),
    },
    {
      field: "IsActive",
      header: "Activa",
      width: 100,
      renderCell: (params: any) => (
        <Switch
          checked={!!params.value}
          size="small"
          disabled
          color="success"
        />
      ),
    },
    {
      field: "SortOrder",
      header: "Orden",
      width: 80,
      type: "number",
    },
    {
      field: "actions",
      header: "",
      width: 80,
      sortable: false,
      filterable: false,
      renderCell: (params: any) => (
        <Button
          size="small"
          color="error"
          onClick={(e) => {
            e.stopPropagation();
            setDeleteTarget(params.row);
            setDeleteOpen(true);
          }}
        >
          Eliminar
        </Button>
      ),
    },
  ];

  /* ─── Condition Fields (dynamic) ──────────────────────────── */

  const renderConditionFields = () => {
    switch (form.TriggerEvent) {
      case "LEAD_STALE":
        // Bind data to zentto-grid web component
        useEffect(() => {
          const el = gridRef.current;
          if (!el || !registered) return;
          el.columns = columns;
          el.rows = rows;
          el.loading = isLoading;
        }, [rows, isLoading, registered, columns]);

        return (
          <TextField
            label="Dias sin actividad"
            type="number"
            fullWidth
            value={form.ConditionJson.days ?? ""}
            onChange={(e) => setCondition("days", Number(e.target.value))}
          />
        );
      case "SCORE_BELOW":
        return (
          <TextField
            label="Score minimo"
            type="number"
            fullWidth
            value={form.ConditionJson.minScore ?? ""}
            onChange={(e) => setCondition("minScore", Number(e.target.value))}
          />
        );
      case "STAGE_CHANGE":
        return (
          <TextField
            label="Etapa destino"
            select
            fullWidth
            value={form.ConditionJson.stageId ?? ""}
            onChange={(e) => setCondition("stageId", Number(e.target.value))}
          >
            {stages.map((s: any) => (
              <MenuItem key={s.StageId} value={s.StageId}>
                {s.Name}
              </MenuItem>
            ))}
          </TextField>
        );
      case "NO_ACTIVITY":
        return (
          <TextField
            label="Dias sin actividad"
            type="number"
            fullWidth
            value={form.ConditionJson.days ?? ""}
            onChange={(e) => setCondition("days", Number(e.target.value))}
          />
        );
      case "LEAD_CREATED":
        return null;
      default:
        return null;
    }
  };

  /* ─── Action Config Fields (dynamic) ──────────────────────── */

  const renderActionFields = () => {
    switch (form.ActionType) {
      case "NOTIFY":
        return (
          <Stack spacing={2}>
            <TextField
              label="Mensaje"
              fullWidth
              multiline
              rows={2}
              value={form.ActionConfig.message ?? ""}
              onChange={(e) => setAction("message", e.target.value)}
            />
            <TextField
              label="ID usuario a notificar"
              type="number"
              fullWidth
              value={form.ActionConfig.userId ?? ""}
              onChange={(e) => setAction("userId", Number(e.target.value))}
            />
          </Stack>
        );
      case "SEND_EMAIL":
        return (
          <Stack spacing={2}>
            <TextField
              label="Template"
              fullWidth
              value={form.ActionConfig.template ?? ""}
              onChange={(e) => setAction("template", e.target.value)}
            />
            <TextField
              label="Email destino"
              fullWidth
              type="email"
              value={form.ActionConfig.email ?? ""}
              onChange={(e) => setAction("email", e.target.value)}
            />
          </Stack>
        );
      case "MOVE_STAGE":
        return (
          <TextField
            label="Etapa destino"
            select
            fullWidth
            value={form.ActionConfig.stageId ?? ""}
            onChange={(e) => setAction("stageId", Number(e.target.value))}
          >
            {stages.map((s: any) => (
              <MenuItem key={s.StageId} value={s.StageId}>
                {s.Name}
              </MenuItem>
            ))}
          </TextField>
        );
      case "CREATE_ACTIVITY":
        return (
          <Stack spacing={2}>
            <TextField
              label="Tipo de actividad"
              select
              fullWidth
              value={form.ActionConfig.activityType ?? ""}
              onChange={(e) => setAction("activityType", e.target.value)}
            >
              {ACTIVITY_TYPE_OPTIONS.map((o) => (
                <MenuItem key={o.value} value={o.value}>
                  {o.label}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              label="Asunto"
              fullWidth
              value={form.ActionConfig.subject ?? ""}
              onChange={(e) => setAction("subject", e.target.value)}
            />
          </Stack>
        );
      case "ASSIGN":
        return (
          <TextField
            label="ID usuario a asignar"
            type="number"
            fullWidth
            value={form.ActionConfig.userId ?? ""}
            onChange={(e) => setAction("userId", Number(e.target.value))}
          />
        );
      default:
        return null;
    }
  };

  /* ─── Render ──────────────────────────────────────────────── */

  return (
    <Box>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <SmartToyIcon sx={{ fontSize: 28, color: "primary.main" }} />
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            Automatizaciones
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleCreate}
          sx={{ borderRadius: 2 }}
        >
          Nueva Regla
        </Button>
      </Box>

      <ZenttoFilterPanel
        filters={AUTOMATION_FILTERS}
        values={filterValues}
        onChange={setFilterValues}
        searchPlaceholder="Buscar reglas..."
        searchValue={searchText}
        onSearchChange={setSearchText}
      />

      <zentto-grid
        ref={gridRef}
        export-filename="crm-automation-rules-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-grouping
      ></zentto-grid>

      {/* ─── Form Dialog ──────────────────────────────────────── */}
      <FormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSave={handleSave}
        title={editRule ? "Editar Regla" : "Nueva Regla de Automatizacion"}
        mode={editRule ? "edit" : "create"}
        maxWidth="sm"
        loading={upsertMutation.isPending}
        disableSave={!form.RuleName.trim()}
      >
        <Stack spacing={2.5}>
          <TextField
            label="Nombre de la regla"
            fullWidth
            required
            value={form.RuleName}
            onChange={(e) => setField("RuleName", e.target.value)}
          />

          <TextField
            label="Trigger"
            select
            fullWidth
            value={form.TriggerEvent}
            onChange={(e) => {
              setField("TriggerEvent", e.target.value);
              setField("ConditionJson", {});
            }}
          >
            {TRIGGER_OPTIONS.map((o) => (
              <MenuItem key={o.value} value={o.value}>
                {o.label}
              </MenuItem>
            ))}
          </TextField>

          {/* Dynamic condition fields */}
          {renderConditionFields()}

          <TextField
            label="Tipo de accion"
            select
            fullWidth
            value={form.ActionType}
            onChange={(e) => {
              setField("ActionType", e.target.value);
              setField("ActionConfig", {});
            }}
          >
            {ACTION_OPTIONS.map((o) => (
              <MenuItem key={o.value} value={o.value}>
                {o.label}
              </MenuItem>
            ))}
          </TextField>

          {/* Dynamic action config fields */}
          {renderActionFields()}

          <TextField
            label="Orden"
            type="number"
            fullWidth
            value={form.SortOrder}
            onChange={(e) => setField("SortOrder", Number(e.target.value))}
          />

          <FormControlLabel
            control={
              <Switch
                checked={form.IsActive}
                onChange={(e) => setField("IsActive", e.target.checked)}
                color="success"
              />
            }
            label="Regla activa"
          />
        </Stack>
      </FormDialog>

      {/* ─── Delete Dialog ─────────────────────────────────────── */}
      <DeleteDialog
        open={deleteOpen}
        onClose={() => {
          setDeleteOpen(false);
          setDeleteTarget(null);
        }}
        onConfirm={handleDeleteConfirm}
        itemName={`la regla "${deleteTarget?.RuleName ?? ""}"`}
        loading={deleteMutation.isPending}
      />
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
