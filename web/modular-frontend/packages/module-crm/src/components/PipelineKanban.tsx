"use client";

import React, { useState, useMemo, useCallback } from "react";
import {
  DndContext,
  DragOverlay,
  closestCorners,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
  type DragOverEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  verticalListSortingStrategy,
  useSortable,
} from "@dnd-kit/sortable";
import { useDroppable } from "@dnd-kit/core";
import { CSS } from "@dnd-kit/utilities";
import {
  Box,
  Paper,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  IconButton,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Skeleton,
  Alert,
  Stack,
  Tooltip,
  Badge,
  Avatar,
  alpha,
  LinearProgress,
  useTheme,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import FilterListIcon from "@mui/icons-material/FilterList";
import BusinessIcon from "@mui/icons-material/Business";
import PersonIcon from "@mui/icons-material/Person";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import DragIndicatorIcon from "@mui/icons-material/DragIndicator";
import { formatCurrency } from "@zentto/shared-api";
import { FormDialog, DeleteDialog } from "@zentto/shared-ui";
import {
  usePipelinesList,
  usePipelineStages,
  useLeadsList,
  useCreateLead,
  useMoveLeadStage,
  useWinLead,
  useLoseLead,
  type Lead,
  type PipelineStage,
  type LeadFilter,
} from "../hooks/useCRM";

// ─── Priority config ────────────────────────────────────────────────────────

const PRIORITY: Record<string, { color: "error" | "warning" | "info" | "default"; label: string; order: number }> = {
  URGENT: { color: "error", label: "Urgente", order: 0 },
  HIGH: { color: "error", label: "Alta", order: 1 },
  MEDIUM: { color: "warning", label: "Media", order: 2 },
  LOW: { color: "info", label: "Baja", order: 3 },
};

const SOURCE_ICONS: Record<string, string> = {
  WEB: "🌐",
  REFERRAL: "🤝",
  COLD_CALL: "📞",
  EVENT: "🎪",
  SOCIAL: "📱",
};

// ─── Draggable Lead Card ────────────────────────────────────────────────────

interface LeadCardProps {
  lead: Lead;
  onWin: (lead: Lead) => void;
  onLose: (lead: Lead) => void;
  isDragging?: boolean;
}

function SortableLeadCard({ lead, onWin, onLose }: LeadCardProps) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: `lead-${lead.LeadId}`,
    data: { type: "lead", lead },
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
  };

  return (
    <div ref={setNodeRef} style={style} {...attributes}>
      <LeadCardContent lead={lead} onWin={onWin} onLose={onLose} dragListeners={listeners} />
    </div>
  );
}

function LeadCardContent({
  lead,
  onWin,
  onLose,
  dragListeners,
  overlay,
}: LeadCardProps & { dragListeners?: any; overlay?: boolean }) {
  const theme = useTheme();
  const priority = PRIORITY[lead.Priority] ?? PRIORITY.MEDIUM;
  const sourceIcon = SOURCE_ICONS[lead.Source] ?? "📋";

  return (
    <Card
      sx={{
        mb: 1,
        borderRadius: 2,
        borderLeft: `3px solid ${(theme.palette as any)[priority.color]?.main ?? theme.palette.grey[400]}`,
        boxShadow: overlay ? "0 8px 24px rgba(0,0,0,0.2)" : "0 1px 3px rgba(0,0,0,0.08)",
        "&:hover": { boxShadow: "0 3px 12px rgba(0,0,0,0.12)" },
        transition: "box-shadow 0.2s, transform 0.15s",
        transform: overlay ? "rotate(2deg) scale(1.02)" : "none",
        cursor: "grab",
        bgcolor: "background.paper",
      }}
    >
      <CardContent sx={{ p: 1.5, pb: "10px !important" }}>
        {/* Drag handle + Lead Code + Priority */}
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 0.75 }}>
          <Box {...dragListeners} sx={{ cursor: "grab", color: "text.disabled", display: "flex" }}>
            <DragIndicatorIcon sx={{ fontSize: 16 }} />
          </Box>
          <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 700, fontFamily: "monospace", fontSize: "0.7rem" }}>
            {lead.LeadCode}
          </Typography>
          <Box sx={{ flex: 1 }} />
          <Chip
            label={priority.label}
            size="small"
            color={priority.color}
            sx={{ height: 18, fontSize: "0.65rem", fontWeight: 700 }}
          />
        </Box>

        {/* Contact name */}
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.75, mb: 0.5 }}>
          <Avatar sx={{ width: 24, height: 24, fontSize: "0.7rem", bgcolor: "primary.main" }}>
            {lead.ContactName?.charAt(0)?.toUpperCase() ?? "?"}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="body2" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: "0.8125rem" }} noWrap>
              {lead.ContactName}
            </Typography>
            {lead.CompanyName && (
              <Typography variant="caption" color="text.secondary" sx={{ fontSize: "0.7rem", lineHeight: 1.1 }} noWrap>
                {lead.CompanyName}
              </Typography>
            )}
          </Box>
        </Box>

        {/* Value + Source */}
        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mt: 0.75 }}>
          {lead.EstimatedValue > 0 ? (
            <Typography variant="body2" sx={{ fontWeight: 800, color: "success.main", fontSize: "0.85rem" }}>
              {formatCurrency(lead.EstimatedValue)}
            </Typography>
          ) : (
            <Typography variant="caption" color="text.disabled">Sin valor</Typography>
          )}
          <Box sx={{ display: "flex", gap: 0.5, alignItems: "center" }}>
            {lead.Source && (
              <Tooltip title={lead.Source}>
                <Typography sx={{ fontSize: "0.85rem", lineHeight: 1 }}>{sourceIcon}</Typography>
              </Tooltip>
            )}
          </Box>
        </Box>

        {/* Quick actions */}
        <Box sx={{ display: "flex", justifyContent: "flex-end", gap: 0.25, mt: 0.75, pt: 0.5, borderTop: "1px solid", borderColor: "divider" }}>
          <Tooltip title="Ganado">
            <IconButton size="small" color="success" onClick={(e) => { e.stopPropagation(); onWin(lead); }}
              sx={{ width: 26, height: 26 }}>
              <EmojiEventsIcon sx={{ fontSize: 15 }} />
            </IconButton>
          </Tooltip>
          <Tooltip title="Perdido">
            <IconButton size="small" color="error" onClick={(e) => { e.stopPropagation(); onLose(lead); }}
              sx={{ width: 26, height: 26 }}>
              <ThumbDownIcon sx={{ fontSize: 15 }} />
            </IconButton>
          </Tooltip>
        </Box>
      </CardContent>
    </Card>
  );
}

// ─── Droppable Stage Column ─────────────────────────────────────────────────

interface StageColumnProps {
  stage: PipelineStage;
  leads: Lead[];
  totalValue: number;
  onWin: (lead: Lead) => void;
  onLose: (lead: Lead) => void;
}

function StageColumn({ stage, leads, totalValue, onWin, onLose }: StageColumnProps) {
  const theme = useTheme();
  const { setNodeRef, isOver } = useDroppable({
    id: `stage-${stage.StageId}`,
    data: { type: "stage", stage },
  });

  const sortableIds = leads.map((l) => `lead-${l.LeadId}`);

  return (
    <Paper
      ref={setNodeRef}
      sx={{
        minWidth: 290,
        maxWidth: 330,
        width: 290,
        flexShrink: 0,
        borderRadius: 3,
        borderTop: `4px solid ${stage.Color || theme.palette.primary.main}`,
        bgcolor: isOver
          ? alpha(stage.Color || theme.palette.primary.main, 0.06)
          : stage.IsClosed
          ? alpha(theme.palette.grey[500], 0.04)
          : "background.paper",
        display: "flex",
        flexDirection: "column",
        transition: "background-color 0.2s",
        overflow: "hidden",
      }}
    >
      {/* Column Header */}
      <Box sx={{ p: 1.75, borderBottom: "1px solid", borderColor: "divider" }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 800, fontSize: "0.85rem" }}>
            {stage.Name}
          </Typography>
          <Badge
            badgeContent={leads.length}
            color="primary"
            sx={{ "& .MuiBadge-badge": { fontSize: "0.7rem", height: 18, minWidth: 18 } }}
          />
        </Box>
        <Box sx={{ display: "flex", gap: 1, mt: 0.5, alignItems: "center" }}>
          {totalValue > 0 && (
            <Typography variant="caption" color="success.main" fontWeight={700} sx={{ fontSize: "0.75rem" }}>
              {formatCurrency(totalValue)}
            </Typography>
          )}
          {stage.Probability > 0 && (
            <Chip
              label={`${stage.Probability}%`}
              size="small"
              variant="outlined"
              sx={{ height: 18, fontSize: "0.6rem", fontWeight: 700 }}
            />
          )}
        </Box>
        {/* Mini progress bar showing probability */}
        {stage.Probability > 0 && (
          <LinearProgress
            variant="determinate"
            value={stage.Probability}
            sx={{ mt: 1, height: 3, borderRadius: 2, bgcolor: "grey.200" }}
          />
        )}
      </Box>

      {/* Cards area */}
      <Box
        sx={{
          p: 1,
          flex: 1,
          overflowY: "auto",
          minHeight: 100,
          maxHeight: "calc(100vh - 320px)",
          "&::-webkit-scrollbar": { width: 4 },
          "&::-webkit-scrollbar-thumb": { bgcolor: "grey.300", borderRadius: 2 },
        }}
      >
        <SortableContext items={sortableIds} strategy={verticalListSortingStrategy}>
          {leads.length === 0 ? (
            <Box
              sx={{
                p: 3,
                textAlign: "center",
                border: "2px dashed",
                borderColor: isOver ? "primary.main" : "grey.200",
                borderRadius: 2,
                transition: "border-color 0.2s",
              }}
            >
              <Typography variant="caption" color={isOver ? "primary.main" : "text.disabled"}>
                {isOver ? "Soltar aqui" : "Arrastra leads aqui"}
              </Typography>
            </Box>
          ) : (
            leads.map((lead) => (
              <SortableLeadCard key={lead.LeadId} lead={lead} onWin={onWin} onLose={onLose} />
            ))
          )}
        </SortableContext>
      </Box>
    </Paper>
  );
}

// ─── Main Pipeline Kanban ───────────────────────────────────────────────────

export default function PipelineKanban() {
  const [selectedPipelineId, setSelectedPipelineId] = useState<number | undefined>();
  const [filterPriority, setFilterPriority] = useState<string>("");
  const [filterStatus, setFilterStatus] = useState<string>("");
  const [showFilters, setShowFilters] = useState(false);
  const [newLeadOpen, setNewLeadOpen] = useState(false);
  const [loseDialog, setLoseDialog] = useState<Lead | null>(null);
  const [loseReason, setLoseReason] = useState("");
  const [activeDragLead, setActiveDragLead] = useState<Lead | null>(null);

  // Form state for new lead
  const [newLead, setNewLead] = useState({
    contactName: "",
    companyName: "",
    email: "",
    phone: "",
    estimatedValue: "",
    priority: "MEDIUM",
    source: "WEB",
    notes: "",
  });

  // ─── Queries ──────────────────────────────────────────────
  const { data: pipelinesData, isLoading: loadingPipelines } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];

  const activePipelineId = selectedPipelineId ?? (pipelines.length > 0 ? pipelines[0]?.PipelineId : undefined);

  const { data: stagesData, isLoading: loadingStages } = usePipelineStages(activePipelineId);
  const stages: PipelineStage[] = (stagesData?.data ?? stagesData?.rows ?? stagesData ?? [])
    .sort((a: PipelineStage, b: PipelineStage) => a.SortOrder - b.SortOrder);

  const filter: LeadFilter = {
    pipelineId: activePipelineId,
    ...(filterPriority ? { priority: filterPriority } : {}),
    ...(filterStatus ? { status: filterStatus } : {}),
    limit: 500,
  };
  const { data: leadsData, isLoading: loadingLeads } = useLeadsList(activePipelineId ? filter : undefined);
  const leads: Lead[] = leadsData?.data ?? leadsData?.rows ?? leadsData ?? [];

  // ─── Mutations ────────────────────────────────────────────
  const createLead = useCreateLead();
  const moveStage = useMoveLeadStage();
  const winLead = useWinLead();
  const loseLead = useLoseLead();

  // ─── Leads grouped by stage ───────────────────────────────
  const leadsByStage = useMemo(() => {
    const map: Record<number, Lead[]> = {};
    for (const s of stages) map[s.StageId] = [];
    for (const l of leads) {
      if (!map[l.StageId]) map[l.StageId] = [];
      map[l.StageId].push(l);
    }
    return map;
  }, [leads, stages]);

  // ─── DnD sensors ──────────────────────────────────────────
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor)
  );

  // ─── DnD handlers ─────────────────────────────────────────
  const handleDragStart = useCallback((event: DragStartEvent) => {
    const { active } = event;
    const lead = active.data.current?.lead as Lead | undefined;
    if (lead) setActiveDragLead(lead);
  }, []);

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      setActiveDragLead(null);
      const { active, over } = event;
      if (!over) return;

      const activeLead = active.data.current?.lead as Lead | undefined;
      if (!activeLead) return;

      // Determine target stage
      let targetStageId: number | null = null;

      if (over.data.current?.type === "stage") {
        targetStageId = over.data.current.stage.StageId;
      } else if (over.data.current?.type === "lead") {
        // Dropped on another lead card — use that lead's stage
        targetStageId = over.data.current.lead.StageId;
      }

      // If the stage actually changed, call the API
      if (targetStageId && targetStageId !== activeLead.StageId) {
        moveStage.mutate({
          leadId: activeLead.LeadId,
          newStageId: targetStageId,
        });
      }
    },
    [moveStage]
  );

  // ─── CRUD handlers ────────────────────────────────────────
  const handleCreateLead = () => {
    if (!activePipelineId || !stages.length) return;
    createLead.mutate(
      {
        pipelineId: activePipelineId,
        stageId: stages[0]?.StageId,
        ...newLead,
        estimatedValue: Number(newLead.estimatedValue) || 0,
      },
      {
        onSuccess: () => {
          setNewLeadOpen(false);
          setNewLead({ contactName: "", companyName: "", email: "", phone: "", estimatedValue: "", priority: "MEDIUM", source: "WEB", notes: "" });
        },
      }
    );
  };

  const handleWin = (lead: Lead) => winLead.mutate({ id: lead.LeadId });
  const handleLose = () => {
    if (!loseDialog) return;
    loseLead.mutate({ id: loseDialog.LeadId, reason: loseReason });
    setLoseDialog(null);
    setLoseReason("");
  };

  const isLoading = loadingPipelines || loadingStages || loadingLeads;

  // ─── Summary stats ────────────────────────────────────────
  const totalLeads = leads.filter((l) => l.Status === "OPEN").length;
  const totalValue = leads.filter((l) => l.Status === "OPEN").reduce((s, l) => s + (l.EstimatedValue ?? 0), 0);

  return (
    <Box>
      {/* ─── Header ──────────────────────────────────────────── */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2, flexWrap: "wrap", gap: 1.5 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            Pipeline
          </Typography>
          {!isLoading && (
            <Typography variant="caption" color="text.secondary">
              {totalLeads} leads abiertos &middot; {formatCurrency(totalValue)} en pipeline
            </Typography>
          )}
        </Box>
        <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
          {pipelines.length > 1 && (
            <FormControl size="small" sx={{ minWidth: 160 }}>
              <InputLabel>Pipeline</InputLabel>
              <Select value={activePipelineId ?? ""} label="Pipeline" onChange={(e) => setSelectedPipelineId(Number(e.target.value))}>
                {pipelines.map((p: any) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>{p.Name}</MenuItem>
                ))}
              </Select>
            </FormControl>
          )}
          <Tooltip title={showFilters ? "Ocultar filtros" : "Filtros"}>
            <IconButton onClick={() => setShowFilters(!showFilters)} color={showFilters ? "primary" : "default"} size="small">
              <FilterListIcon />
            </IconButton>
          </Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewLeadOpen(true)} size="small">
            Nuevo Lead
          </Button>
        </Box>
      </Box>

      {/* ─── Filters ─────────────────────────────────────────── */}
      {showFilters && (
        <Paper sx={{ p: 2, mb: 2, borderRadius: 2 }}>
          <Stack direction="row" spacing={2} flexWrap="wrap">
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Prioridad</InputLabel>
              <Select value={filterPriority} label="Prioridad" onChange={(e) => setFilterPriority(e.target.value)}>
                <MenuItem value="">Todas</MenuItem>
                <MenuItem value="URGENT">Urgente</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="LOW">Baja</MenuItem>
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Estado</InputLabel>
              <Select value={filterStatus} label="Estado" onChange={(e) => setFilterStatus(e.target.value)}>
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="OPEN">Abierto</MenuItem>
                <MenuItem value="WON">Ganado</MenuItem>
                <MenuItem value="LOST">Perdido</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </Paper>
      )}

      {/* ─── Kanban Board with DnD ───────────────────────────── */}
      {isLoading ? (
        <Box sx={{ display: "flex", gap: 2, overflow: "hidden" }}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} variant="rectangular" width={290} height={450} sx={{ borderRadius: 3, flexShrink: 0 }} />
          ))}
        </Box>
      ) : stages.length === 0 ? (
        <Alert severity="info" sx={{ borderRadius: 2 }}>
          No hay etapas configuradas para este pipeline. Configure las etapas desde la administracion de CRM.
        </Alert>
      ) : (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCorners}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          <Box
            sx={{
              display: "flex",
              gap: 2,
              overflowX: "auto",
              pb: 2,
              minHeight: 450,
              "&::-webkit-scrollbar": { height: 6 },
              "&::-webkit-scrollbar-thumb": { bgcolor: "grey.300", borderRadius: 3 },
            }}
          >
            {stages.map((stage) => {
              const stageLeads = leadsByStage[stage.StageId] ?? [];
              const stageTotal = stageLeads.reduce((sum, l) => sum + (l.EstimatedValue ?? 0), 0);
              return (
                <StageColumn
                  key={stage.StageId}
                  stage={stage}
                  leads={stageLeads}
                  totalValue={stageTotal}
                  onWin={handleWin}
                  onLose={(l) => setLoseDialog(l)}
                />
              );
            })}
          </Box>

          {/* Drag overlay — shows a floating card while dragging */}
          <DragOverlay>
            {activeDragLead ? (
              <Box sx={{ width: 280 }}>
                <LeadCardContent
                  lead={activeDragLead}
                  onWin={() => {}}
                  onLose={() => {}}
                  overlay
                />
              </Box>
            ) : null}
          </DragOverlay>
        </DndContext>
      )}

      {/* ─── Lose Dialog ─────────────────────────────────────── */}
      <FormDialog
        open={!!loseDialog}
        onClose={() => { setLoseDialog(null); setLoseReason(""); }}
        onSave={handleLose}
        title="Marcar lead como perdido"
        subtitle={loseDialog ? `${loseDialog.LeadCode} - ${loseDialog.ContactName}` : ""}
        mode="edit"
        saveLabel="Confirmar perdida"
        disableSave={!loseReason.trim()}
        loading={loseLead.isPending}
      >
        <TextField
          label="Motivo de la perdida"
          fullWidth
          multiline
          rows={3}
          value={loseReason}
          onChange={(e) => setLoseReason(e.target.value)}
          placeholder="Precio, competencia, timing, no responde..."
        />
      </FormDialog>

      {/* ─── New Lead Dialog ─────────────────────────────────── */}
      <FormDialog
        open={newLeadOpen}
        onClose={() => setNewLeadOpen(false)}
        onSave={handleCreateLead}
        title="Nuevo Lead"
        subtitle="Agregar prospecto al pipeline"
        mode="create"
        saveLabel="Crear Lead"
        disableSave={!newLead.contactName.trim()}
        loading={createLead.isPending}
      >
        <Stack spacing={2}>
          <TextField
            label="Nombre de contacto"
            fullWidth
            required
            value={newLead.contactName}
            onChange={(e) => setNewLead({ ...newLead, contactName: e.target.value })}
          />
          <TextField
            label="Empresa"
            fullWidth
            value={newLead.companyName}
            onChange={(e) => setNewLead({ ...newLead, companyName: e.target.value })}
          />
          <Stack direction="row" spacing={2}>
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={newLead.email}
              onChange={(e) => setNewLead({ ...newLead, email: e.target.value })}
            />
            <TextField
              label="Telefono"
              fullWidth
              value={newLead.phone}
              onChange={(e) => setNewLead({ ...newLead, phone: e.target.value })}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            <TextField
              label="Valor estimado"
              fullWidth
              type="number"
              value={newLead.estimatedValue}
              onChange={(e) => setNewLead({ ...newLead, estimatedValue: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Prioridad</InputLabel>
              <Select value={newLead.priority} label="Prioridad" onChange={(e) => setNewLead({ ...newLead, priority: e.target.value })}>
                <MenuItem value="URGENT">Urgente</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="LOW">Baja</MenuItem>
              </Select>
            </FormControl>
          </Stack>
          <FormControl fullWidth>
            <InputLabel>Origen</InputLabel>
            <Select value={newLead.source} label="Origen" onChange={(e) => setNewLead({ ...newLead, source: e.target.value })}>
              <MenuItem value="WEB">Web</MenuItem>
              <MenuItem value="REFERRAL">Referido</MenuItem>
              <MenuItem value="COLD_CALL">Llamada en frio</MenuItem>
              <MenuItem value="EVENT">Evento</MenuItem>
              <MenuItem value="SOCIAL">Redes sociales</MenuItem>
              <MenuItem value="OTHER">Otro</MenuItem>
            </Select>
          </FormControl>
          <TextField
            label="Notas"
            fullWidth
            multiline
            rows={2}
            value={newLead.notes}
            onChange={(e) => setNewLead({ ...newLead, notes: e.target.value })}
          />
        </Stack>
      </FormDialog>
    </Box>
  );
}
