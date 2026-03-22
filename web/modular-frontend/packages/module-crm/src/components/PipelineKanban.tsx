"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  IconButton,
  Menu,
  MenuItem,
  TextField,
  FormControl,
  InputLabel,
  Select,
  Skeleton,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  Tooltip,
  Badge,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import FilterListIcon from "@mui/icons-material/FilterList";
import BusinessIcon from "@mui/icons-material/Business";
import PersonIcon from "@mui/icons-material/Person";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
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

const priorityColor: Record<string, "error" | "warning" | "info" | "default"> = {
  HIGH: "error",
  MEDIUM: "warning",
  LOW: "info",
  NONE: "default",
};

const priorityLabel: Record<string, string> = {
  HIGH: "Alta",
  MEDIUM: "Media",
  LOW: "Baja",
  NONE: "Sin prioridad",
};

export default function PipelineKanban() {
  const [selectedPipelineId, setSelectedPipelineId] = useState<number | undefined>();
  const [filterPriority, setFilterPriority] = useState<string>("");
  const [filterStatus, setFilterStatus] = useState<string>("");
  const [showFilters, setShowFilters] = useState(false);
  const [newLeadOpen, setNewLeadOpen] = useState(false);
  const [moveAnchor, setMoveAnchor] = useState<{ el: HTMLElement; lead: Lead } | null>(null);
  const [loseDialog, setLoseDialog] = useState<Lead | null>(null);
  const [loseReason, setLoseReason] = useState("");

  // ─── Form state para nuevo lead ───────────────────────────
  const [newLead, setNewLead] = useState({
    contactName: "",
    companyName: "",
    email: "",
    phone: "",
    estimatedValue: "",
    priority: "MEDIUM",
    source: "",
    notes: "",
  });

  // ─── Queries ──────────────────────────────────────────────
  const { data: pipelinesData, isLoading: loadingPipelines } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];

  const activePipelineId = selectedPipelineId ?? (pipelines.length > 0 ? pipelines[0]?.PipelineId : undefined);

  const { data: stagesData, isLoading: loadingStages } = usePipelineStages(activePipelineId);
  const stages: PipelineStage[] = stagesData?.data ?? stagesData?.rows ?? stagesData ?? [];

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

  // ─── Leads agrupados por stage ────────────────────────────
  const leadsByStage = useMemo(() => {
    const map: Record<number, Lead[]> = {};
    for (const s of stages) map[s.StageId] = [];
    for (const l of leads) {
      if (!map[l.StageId]) map[l.StageId] = [];
      map[l.StageId].push(l);
    }
    return map;
  }, [leads, stages]);

  // ─── Handlers ─────────────────────────────────────────────
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
          setNewLead({ contactName: "", companyName: "", email: "", phone: "", estimatedValue: "", priority: "MEDIUM", source: "", notes: "" });
        },
      }
    );
  };

  const handleMove = (stageId: number) => {
    if (!moveAnchor) return;
    moveStage.mutate({ leadId: moveAnchor.lead.LeadId, stageId });
    setMoveAnchor(null);
  };

  const handleWin = (lead: Lead) => winLead.mutate(lead.LeadId);

  const handleLose = () => {
    if (!loseDialog) return;
    loseLead.mutate({ id: loseDialog.LeadId, reason: loseReason });
    setLoseDialog(null);
    setLoseReason("");
  };

  const isLoading = loadingPipelines || loadingStages || loadingLeads;

  return (
    <Box>
      {/* ─── Header ──────────────────────────────────────────── */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 700, color: "text.primary" }}>
          Pipeline CRM
        </Typography>
        <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
          {pipelines.length > 1 && (
            <FormControl size="small" sx={{ minWidth: 180 }}>
              <InputLabel>Pipeline</InputLabel>
              <Select
                value={activePipelineId ?? ""}
                label="Pipeline"
                onChange={(e) => setSelectedPipelineId(Number(e.target.value))}
              >
                {pipelines.map((p: any) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>{p.Name}</MenuItem>
                ))}
              </Select>
            </FormControl>
          )}
          <IconButton onClick={() => setShowFilters(!showFilters)} color={showFilters ? "primary" : "default"}>
            <FilterListIcon />
          </IconButton>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setNewLeadOpen(true)}>
            Nuevo Lead
          </Button>
        </Box>
      </Box>

      {/* ─── Filtros ─────────────────────────────────────────── */}
      {showFilters && (
        <Paper sx={{ p: 2, mb: 2, borderRadius: 2 }}>
          <Stack direction="row" spacing={2}>
            <FormControl size="small" sx={{ minWidth: 140 }}>
              <InputLabel>Prioridad</InputLabel>
              <Select value={filterPriority} label="Prioridad" onChange={(e) => setFilterPriority(e.target.value)}>
                <MenuItem value="">Todas</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="LOW">Baja</MenuItem>
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 140 }}>
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

      {/* ─── Kanban Board ────────────────────────────────────── */}
      {isLoading ? (
        <Box sx={{ display: "flex", gap: 2, overflow: "hidden" }}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} variant="rectangular" width={280} height={400} sx={{ borderRadius: 2, flexShrink: 0 }} />
          ))}
        </Box>
      ) : stages.length === 0 ? (
        <Alert severity="info">
          No hay etapas configuradas para este pipeline. Configure las etapas desde la administración de CRM.
        </Alert>
      ) : (
        <Box
          sx={{
            display: "flex",
            gap: 2,
            overflowX: "auto",
            pb: 2,
            minHeight: 400,
            "&::-webkit-scrollbar": { height: 8 },
            "&::-webkit-scrollbar-thumb": { bgcolor: "grey.300", borderRadius: 4 },
          }}
        >
          {stages
            .sort((a, b) => a.SortOrder - b.SortOrder)
            .map((stage) => {
              const stageLeads = leadsByStage[stage.StageId] ?? [];
              const stageTotal = stageLeads.reduce((sum, l) => sum + (l.EstimatedValue ?? 0), 0);

              return (
                <Paper
                  key={stage.StageId}
                  sx={{
                    minWidth: 280,
                    maxWidth: 320,
                    flexShrink: 0,
                    borderRadius: 2,
                    borderTop: `4px solid ${stage.Color || brandColors.statBlue}`,
                    bgcolor: stage.IsClosed ? "grey.50" : "background.paper",
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  {/* Column Header */}
                  <Box sx={{ p: 2, borderBottom: "1px solid", borderColor: "divider" }}>
                    <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                        {stage.Name}
                      </Typography>
                      <Badge badgeContent={stageLeads.length} color="primary" />
                    </Box>
                    {stageTotal > 0 && (
                      <Typography variant="caption" color="text.secondary">
                        {formatCurrency(stageTotal)}
                      </Typography>
                    )}
                    {stage.Probability > 0 && (
                      <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                        ({stage.Probability}%)
                      </Typography>
                    )}
                  </Box>

                  {/* Cards */}
                  <Box sx={{ p: 1, flex: 1, overflowY: "auto", maxHeight: 600 }}>
                    {stageLeads.length === 0 ? (
                      <Box sx={{ p: 2, textAlign: "center" }}>
                        <Typography variant="caption" color="text.disabled">
                          Sin leads
                        </Typography>
                      </Box>
                    ) : (
                      stageLeads.map((lead) => (
                        <Card
                          key={lead.LeadId}
                          sx={{
                            mb: 1,
                            borderRadius: 1.5,
                            boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
                            "&:hover": { boxShadow: "0 2px 8px rgba(0,0,0,0.15)" },
                            transition: "box-shadow 0.2s",
                          }}
                        >
                          <CardContent sx={{ p: 1.5, pb: "12px !important" }}>
                            {/* Lead Code + Priority */}
                            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 0.5 }}>
                              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
                                {lead.LeadCode}
                              </Typography>
                              <Chip
                                label={priorityLabel[lead.Priority] ?? lead.Priority}
                                size="small"
                                color={priorityColor[lead.Priority] ?? "default"}
                                sx={{ height: 20, fontSize: "0.7rem" }}
                              />
                            </Box>

                            {/* Contact */}
                            <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 0.5 }}>
                              <PersonIcon sx={{ fontSize: 14, color: "text.secondary" }} />
                              <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.2 }}>
                                {lead.ContactName}
                              </Typography>
                            </Box>

                            {/* Company */}
                            {lead.CompanyName && (
                              <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 0.5 }}>
                                <BusinessIcon sx={{ fontSize: 14, color: "text.secondary" }} />
                                <Typography variant="caption" color="text.secondary">
                                  {lead.CompanyName}
                                </Typography>
                              </Box>
                            )}

                            {/* Value */}
                            {lead.EstimatedValue > 0 && (
                              <Typography variant="body2" sx={{ fontWeight: 700, color: brandColors.success, mb: 0.5 }}>
                                {formatCurrency(lead.EstimatedValue)}
                              </Typography>
                            )}

                            {/* Source chip */}
                            {lead.Source && (
                              <Chip
                                label={lead.Source}
                                size="small"
                                variant="outlined"
                                sx={{ height: 18, fontSize: "0.65rem", mr: 0.5 }}
                              />
                            )}

                            {/* Actions */}
                            <Box sx={{ display: "flex", justifyContent: "flex-end", gap: 0.5, mt: 1 }}>
                              <Tooltip title="Mover a otra etapa">
                                <IconButton
                                  size="small"
                                  onClick={(e) => setMoveAnchor({ el: e.currentTarget, lead })}
                                >
                                  <ArrowForwardIcon sx={{ fontSize: 16 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Marcar como ganado">
                                <IconButton size="small" color="success" onClick={() => handleWin(lead)}>
                                  <EmojiEventsIcon sx={{ fontSize: 16 }} />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="Marcar como perdido">
                                <IconButton size="small" color="error" onClick={() => setLoseDialog(lead)}>
                                  <ThumbDownIcon sx={{ fontSize: 16 }} />
                                </IconButton>
                              </Tooltip>
                            </Box>
                          </CardContent>
                        </Card>
                      ))
                    )}
                  </Box>
                </Paper>
              );
            })}
        </Box>
      )}

      {/* ─── Move Menu ───────────────────────────────────────── */}
      <Menu
        anchorEl={moveAnchor?.el}
        open={!!moveAnchor}
        onClose={() => setMoveAnchor(null)}
      >
        {stages
          .filter((s) => s.StageId !== moveAnchor?.lead.StageId)
          .sort((a, b) => a.SortOrder - b.SortOrder)
          .map((s) => (
            <MenuItem key={s.StageId} onClick={() => handleMove(s.StageId)}>
              <Box sx={{ width: 12, height: 12, borderRadius: "50%", bgcolor: s.Color || brandColors.statBlue, mr: 1 }} />
              {s.Name}
            </MenuItem>
          ))}
      </Menu>

      {/* ─── Lose Dialog ─────────────────────────────────────── */}
      <Dialog open={!!loseDialog} onClose={() => setLoseDialog(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Marcar lead como perdido</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Lead: <strong>{loseDialog?.LeadCode}</strong> - {loseDialog?.ContactName}
          </Typography>
          <TextField
            label="Motivo de la pérdida"
            fullWidth
            multiline
            rows={3}
            value={loseReason}
            onChange={(e) => setLoseReason(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoseDialog(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleLose} disabled={!loseReason.trim()}>
            Confirmar pérdida
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── New Lead Dialog ─────────────────────────────────── */}
      <Dialog open={newLeadOpen} onClose={() => setNewLeadOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Lead</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
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
                label="Teléfono"
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
                <Select
                  value={newLead.priority}
                  label="Prioridad"
                  onChange={(e) => setNewLead({ ...newLead, priority: e.target.value })}
                >
                  <MenuItem value="HIGH">Alta</MenuItem>
                  <MenuItem value="MEDIUM">Media</MenuItem>
                  <MenuItem value="LOW">Baja</MenuItem>
                </Select>
              </FormControl>
            </Stack>
            <TextField
              label="Origen"
              fullWidth
              placeholder="Web, referido, llamada..."
              value={newLead.source}
              onChange={(e) => setNewLead({ ...newLead, source: e.target.value })}
            />
            <TextField
              label="Notas"
              fullWidth
              multiline
              rows={2}
              value={newLead.notes}
              onChange={(e) => setNewLead({ ...newLead, notes: e.target.value })}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewLeadOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreateLead}
            disabled={!newLead.contactName.trim() || createLead.isPending}
          >
            {createLead.isPending ? "Creando..." : "Crear Lead"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
