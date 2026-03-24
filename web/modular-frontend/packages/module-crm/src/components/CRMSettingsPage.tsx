"use client";

import React, { useState, useEffect } from "react";
import {
  Box,
  Typography,
  Paper,
  Tabs,
  Tab,
  Button,
  Stack,
  TextField,
  MenuItem,
  Switch,
  FormControlLabel,
  FormControl,
  InputLabel,
  Select,
  Alert,
  Chip,
  List,
  ListItem,
  ListItemText,
  Divider,
} from "@mui/material";
import SettingsIcon from "@mui/icons-material/Settings";
import ViewKanbanIcon from "@mui/icons-material/ViewKanban";
import StairsIcon from "@mui/icons-material/Stairs";
import ScoreIcon from "@mui/icons-material/Score";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import {
  ZenttoDataGrid,
  FormDialog,
  type ZenttoColDef,
} from "@zentto/shared-ui";
import {
  usePipelinesList,
  usePipelineStages,
  useCreatePipeline,
  useCreateStage,
} from "../hooks/useCRM";

/* ─── Tab panel helper ──────────────────────────────────────── */

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ pt: 2 }}>{children}</Box> : null;
}

/* ─── Scoring Factors (read-only) ───────────────────────────── */

const SCORING_FACTORS = [
  { name: "Valor estimado alto", description: "Lead con valor estimado superior al promedio", weight: 15 },
  { name: "Tiene email", description: "Contacto con email registrado", weight: 5 },
  { name: "Tiene telefono", description: "Contacto con telefono registrado", weight: 5 },
  { name: "Tiene empresa", description: "Lead asociado a empresa", weight: 5 },
  { name: "Fuente conocida", description: "Fuente de origen identificada (Referido, Web, etc.)", weight: 5 },
  { name: "Prioridad alta", description: "Prioridad HIGH o URGENT", weight: 10 },
  { name: "Actividades recientes", description: "Al menos 1 actividad en los ultimos 7 dias", weight: 10 },
  { name: "Muchas actividades", description: "5+ actividades totales registradas", weight: 10 },
  { name: "Fecha de cierre proxima", description: "Fecha de cierre esperada dentro de 30 dias", weight: 10 },
  { name: "Avance en pipeline", description: "Lead ha avanzado al menos 2 etapas", weight: 10 },
  { name: "Probabilidad de etapa", description: "Etapa actual con probabilidad >= 50%", weight: 5 },
  { name: "Responsable asignado", description: "Lead tiene un vendedor asignado", weight: 5 },
  { name: "Notas agregadas", description: "Lead tiene notas o descripcion", weight: 5 },
];

/* ─── Main Component ────────────────────────────────────────── */

export default function CRMSettingsPage() {
  const [tab, setTab] = useState(0);
  const [selectedPipeline, setSelectedPipeline] = useState<number | undefined>();
  const [pipelineDialogOpen, setPipelineDialogOpen] = useState(false);
  const [stageDialogOpen, setStageDialogOpen] = useState(false);
  const [editingPipeline, setEditingPipeline] = useState<any>(null);
  const [editingStage, setEditingStage] = useState<any>(null);

  // Pipeline form state
  const [pipelineName, setPipelineName] = useState("");
  const [pipelineDesc, setPipelineDesc] = useState("");
  const [pipelineIsDefault, setPipelineIsDefault] = useState(false);

  // Stage form state
  const [stageName, setStageName] = useState("");
  const [stageOrder, setStageOrder] = useState(0);
  const [stageColor, setStageColor] = useState("#1976d2");
  const [stageProbability, setStageProbability] = useState(0);
  const [stageDays, setStageDays] = useState(7);
  const [stageIsClosed, setStageIsClosed] = useState(false);
  const [stageIsWon, setStageIsWon] = useState(false);

  // Data
  const { data: pipelinesRaw, isLoading: pipelinesLoading } = usePipelinesList();
  const pipelines: any[] = (pipelinesRaw as any)?.data ?? (pipelinesRaw as any)?.rows ?? pipelinesRaw ?? [];

  const { data: stagesRaw, isLoading: stagesLoading } = usePipelineStages(selectedPipeline);
  const stages: any[] = (stagesRaw as any)?.data ?? (stagesRaw as any)?.rows ?? stagesRaw ?? [];

  const createPipeline = useCreatePipeline();
  const createStage = useCreateStage();

  // Auto-select first pipeline
  useEffect(() => {
    if (!selectedPipeline && pipelines.length > 0) {
      setSelectedPipeline(pipelines[0].PipelineId);
    }
  }, [pipelines, selectedPipeline]);

  /* ── Pipeline dialog handlers ────────────────────────────── */

  function openNewPipeline() {
    setEditingPipeline(null);
    setPipelineName("");
    setPipelineDesc("");
    setPipelineIsDefault(false);
    setPipelineDialogOpen(true);
  }

  function openEditPipeline(p: any) {
    setEditingPipeline(p);
    setPipelineName(p.Name || "");
    setPipelineDesc(p.Description || "");
    setPipelineIsDefault(!!p.IsDefault);
    setPipelineDialogOpen(true);
  }

  async function savePipeline() {
    await createPipeline.mutateAsync({
      pipelineId: editingPipeline?.PipelineId ?? null,
      name: pipelineName,
      description: pipelineDesc,
      isDefault: pipelineIsDefault,
    });
    setPipelineDialogOpen(false);
  }

  /* ── Stage dialog handlers ───────────────────────────────── */

  function openNewStage() {
    setEditingStage(null);
    setStageName("");
    setStageOrder(stages.length + 1);
    setStageColor("#1976d2");
    setStageProbability(0);
    setStageDays(7);
    setStageIsClosed(false);
    setStageIsWon(false);
    setStageDialogOpen(true);
  }

  function openEditStage(s: any) {
    setEditingStage(s);
    setStageName(s.Name || "");
    setStageOrder(s.SortOrder ?? 0);
    setStageColor(s.Color || "#1976d2");
    setStageProbability(s.Probability ?? 0);
    setStageDays(s.ExpectedDays ?? 7);
    setStageIsClosed(!!s.IsClosed);
    setStageIsWon(!!s.IsWon);
    setStageDialogOpen(true);
  }

  async function saveStage() {
    if (!selectedPipeline) return;
    await createStage.mutateAsync({
      pipelineId: selectedPipeline,
      stageId: editingStage?.StageId ?? null,
      name: stageName,
      sortOrder: stageOrder,
      color: stageColor,
      probability: stageProbability,
      expectedDays: stageDays,
      isClosed: stageIsClosed,
      isWon: stageIsWon,
    });
    setStageDialogOpen(false);
  }

  /* ── Stage columns ───────────────────────────────────────── */

  const stageColumns: ZenttoColDef[] = [
    { field: "SortOrder", headerName: "Orden", width: 80 },
    { field: "Name", headerName: "Nombre", flex: 1 },
    {
      field: "Color",
      headerName: "Color",
      width: 100,
      renderCell: (params: any) => (
        <Box
          sx={{
            width: 28,
            height: 28,
            borderRadius: 1,
            bgcolor: params.value || "#ccc",
            border: "1px solid rgba(0,0,0,0.2)",
          }}
        />
      ),
    },
    {
      field: "Probability",
      headerName: "Probabilidad %",
      width: 130,
      renderCell: (params: any) => `${params.value ?? 0}%`,
    },
    {
      field: "IsClosed",
      headerName: "Cerrada",
      width: 90,
      renderCell: (params: any) => (
        <Chip
          size="small"
          label={params.value ? "Si" : "No"}
          color={params.value ? "warning" : "default"}
        />
      ),
    },
    {
      field: "IsWon",
      headerName: "Ganada",
      width: 90,
      renderCell: (params: any) => (
        <Chip
          size="small"
          label={params.value ? "Si" : "No"}
          color={params.value ? "success" : "default"}
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 80,
      sortable: false,
      renderCell: (params: any) => (
        <Button size="small" onClick={() => openEditStage(params.row)}>
          <EditIcon fontSize="small" />
        </Button>
      ),
    },
  ];

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
        Configuracion CRM
      </Typography>

      <Paper sx={{ borderRadius: 2 }}>
        <Tabs
          value={tab}
          onChange={(_, v) => setTab(v)}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab icon={<ViewKanbanIcon />} iconPosition="start" label="Pipelines" />
          <Tab icon={<StairsIcon />} iconPosition="start" label="Etapas" />
          <Tab icon={<ScoreIcon />} iconPosition="start" label="Scoring" />
        </Tabs>

        <Box sx={{ p: 2 }}>
          {/* ═══ Tab: Pipelines ══════════════════════════════════ */}
          <TabPanel value={tab} index={0}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
              <Typography variant="h6">Pipelines</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={openNewPipeline}
              >
                Nuevo Pipeline
              </Button>
            </Stack>

            {pipelinesLoading ? (
              <Typography color="text.secondary">Cargando...</Typography>
            ) : pipelines.length === 0 ? (
              <Alert severity="info">No hay pipelines configurados</Alert>
            ) : (
              <Stack spacing={1}>
                {pipelines.map((p: any) => (
                  <Paper
                    key={p.PipelineId}
                    variant="outlined"
                    sx={{
                      p: 2,
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                      cursor: "pointer",
                      bgcolor: selectedPipeline === p.PipelineId ? "action.selected" : "transparent",
                      "&:hover": { bgcolor: "action.hover" },
                    }}
                    onClick={() => setSelectedPipeline(p.PipelineId)}
                  >
                    <Box>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <Typography fontWeight={600}>{p.Name}</Typography>
                        {p.IsDefault && (
                          <Chip size="small" label="Default" color="primary" variant="outlined" />
                        )}
                        <Chip
                          size="small"
                          label={p.IsActive ? "Activo" : "Inactivo"}
                          color={p.IsActive ? "success" : "default"}
                        />
                      </Stack>
                      {p.Description && (
                        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                          {p.Description}
                        </Typography>
                      )}
                    </Box>
                    <Button
                      size="small"
                      startIcon={<EditIcon />}
                      onClick={(e) => {
                        e.stopPropagation();
                        openEditPipeline(p);
                      }}
                    >
                      Editar
                    </Button>
                  </Paper>
                ))}
              </Stack>
            )}
          </TabPanel>

          {/* ═══ Tab: Etapas ═════════════════════════════════════ */}
          <TabPanel value={tab} index={1}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
              <Stack direction="row" spacing={2} alignItems="center">
                <Typography variant="h6">Etapas</Typography>
                <FormControl sx={{ minWidth: 180 }}>
                  <InputLabel>Pipeline</InputLabel>
                  <Select
                    value={selectedPipeline ?? ""}
                    label="Pipeline"
                    size="small"
                    onChange={(e) =>
                      setSelectedPipeline(e.target.value ? Number(e.target.value) : undefined)
                    }
                  >
                    {pipelines.map((p: any) => (
                      <MenuItem key={p.PipelineId} value={p.PipelineId}>
                        {p.Name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Stack>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={openNewStage}
                disabled={!selectedPipeline}
              >
                Nueva Etapa
              </Button>
            </Stack>

            {!selectedPipeline ? (
              <Alert severity="info">Selecciona un pipeline para ver sus etapas</Alert>
            ) : stagesLoading ? (
              <Typography color="text.secondary">Cargando...</Typography>
            ) : (
              <ZenttoDataGrid
                rows={stages}
                columns={stageColumns}
                getRowId={(row: any) => row.StageId}
                autoHeight
                hideFooter={stages.length <= 10}
              />
            )}
          </TabPanel>

          {/* ═══ Tab: Scoring ════════════════════════════════════ */}
          <TabPanel value={tab} index={2}>
            <Typography variant="h6" sx={{ mb: 1 }}>
              Factores de scoring
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              El score se calcula automaticamente sumando los pesos de cada factor que
              aplique al lead. El rango es 0-100.
            </Typography>

            <Paper variant="outlined" sx={{ borderRadius: 2 }}>
              <List disablePadding>
                {SCORING_FACTORS.map((f, idx) => (
                  <React.Fragment key={f.name}>
                    {idx > 0 && <Divider />}
                    <ListItem
                      secondaryAction={
                        <Chip
                          label={`+${f.weight} pts`}
                          color="primary"
                          size="small"
                          variant="outlined"
                          sx={{ fontWeight: 700 }}
                        />
                      }
                    >
                      <ListItemText
                        primary={f.name}
                        secondary={f.description}
                        primaryTypographyProps={{ fontWeight: 600 }}
                      />
                    </ListItem>
                  </React.Fragment>
                ))}
              </List>
            </Paper>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Total maximo: {SCORING_FACTORS.reduce((sum, f) => sum + f.weight, 0)} puntos
            </Typography>
          </TabPanel>
        </Box>
      </Paper>

      {/* ═══ Pipeline Dialog ══════════════════════════════════════ */}
      <FormDialog
        open={pipelineDialogOpen}
        onClose={() => setPipelineDialogOpen(false)}
        onSave={savePipeline}
        title={editingPipeline ? "Editar Pipeline" : "Nuevo Pipeline"}
        loading={createPipeline.isPending}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            value={pipelineName}
            onChange={(e) => setPipelineName(e.target.value)}
            required
            fullWidth
          />
          <TextField
            label="Descripcion"
            value={pipelineDesc}
            onChange={(e) => setPipelineDesc(e.target.value)}
            multiline
            rows={2}
            fullWidth
          />
          <FormControlLabel
            control={
              <Switch
                checked={pipelineIsDefault}
                onChange={(e) => setPipelineIsDefault(e.target.checked)}
              />
            }
            label="Pipeline por defecto"
          />
        </Stack>
      </FormDialog>

      {/* ═══ Stage Dialog ═════════════════════════════════════════ */}
      <FormDialog
        open={stageDialogOpen}
        onClose={() => setStageDialogOpen(false)}
        onSave={saveStage}
        title={editingStage ? "Editar Etapa" : "Nueva Etapa"}
        loading={createStage.isPending}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            value={stageName}
            onChange={(e) => setStageName(e.target.value)}
            required
            fullWidth
          />
          <TextField
            label="Orden"
            type="number"
            value={stageOrder}
            onChange={(e) => setStageOrder(Number(e.target.value))}
            fullWidth
          />
          <TextField
            label="Color"
            type="color"
            value={stageColor}
            onChange={(e) => setStageColor(e.target.value)}
            fullWidth
            InputProps={{ sx: { height: 48 } }}
          />
          <TextField
            label="Probabilidad (%)"
            type="number"
            value={stageProbability}
            onChange={(e) => setStageProbability(Number(e.target.value))}
            inputProps={{ min: 0, max: 100 }}
            fullWidth
          />
          <TextField
            label="Dias esperados"
            type="number"
            value={stageDays}
            onChange={(e) => setStageDays(Number(e.target.value))}
            inputProps={{ min: 1 }}
            fullWidth
          />
          <FormControlLabel
            control={
              <Switch
                checked={stageIsClosed}
                onChange={(e) => setStageIsClosed(e.target.checked)}
              />
            }
            label="Etapa cerrada"
          />
          {stageIsClosed && (
            <FormControlLabel
              control={
                <Switch
                  checked={stageIsWon}
                  onChange={(e) => setStageIsWon(e.target.checked)}
                />
              }
              label="Etapa ganada (si no, es perdida)"
            />
          )}
        </Stack>
      </FormDialog>
    </Box>
  );
}
