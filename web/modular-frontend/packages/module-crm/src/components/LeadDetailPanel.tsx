"use client";

import React, { useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Paper,
  Typography,
  Chip,
  Avatar,
  Button,
  IconButton,
  Divider,
  Stack,
  Skeleton,
  Alert,
  alpha,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from "@mui/material";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import NoteAddIcon from "@mui/icons-material/NoteAdd";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import CloseIcon from "@mui/icons-material/Close";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import RefreshIcon from "@mui/icons-material/Refresh";
import TransformIcon from "@mui/icons-material/Transform";
import { FormDialog, useToast } from "@zentto/shared-ui";
import { useLeadConvert } from "../hooks/useLeadConvert";
import { formatCurrency } from "@zentto/shared-api";
import { LeadScoreBadge } from "./LeadScoreBadge";
import { LeadActivityTimeline } from "./LeadActivityTimeline";
import {
  useLeadDetailFull,
  useLeadHistoryFull,
  useLeadScore,
  useCalculateScore,
} from "../hooks/useCRMScoring";
import {
  useMoveLeadStage,
  useWinLead,
  useLoseLead,
  useCreateActivity,
  usePipelineStages,
  useActivitiesList,
  useCompleteActivity,
} from "../hooks/useCRM";
import { PRIORITY_LABELS } from "../types";

/* ─── Helpers ──────────────────────────────────────────────── */

const statusColor: Record<string, "success" | "error" | "info" | "default"> = {
  OPEN: "info",
  WON: "success",
  LOST: "error",
};

const statusLabel: Record<string, string> = {
  OPEN: "Abierto",
  WON: "Ganado",
  LOST: "Perdido",
  ARCHIVED: "Archivado",
};

const priorityLabel: Record<string, string> = PRIORITY_LABELS;

function formatDate(d: string | null | undefined): string {
  if (!d) return "\u2014";
  try {
    return new Date(d).toLocaleDateString("es", { day: "2-digit", month: "short", year: "numeric" });
  } catch {
    return d;
  }
}

/* ─── Props ────────────────────────────────────────────────── */

interface LeadDetailPanelProps {
  leadId: number;
  onClose?: () => void;
}

/* ─── Component ────────────────────────────────────────────── */

export default function LeadDetailPanel({ leadId, onClose }: LeadDetailPanelProps) {
  const { data: lead, isLoading } = useLeadDetailFull(leadId);
  const { data: historyData } = useLeadHistoryFull(leadId);
  const { data: scoreData } = useLeadScore(leadId);
  const { data: activitiesData } = useActivitiesList({ leadId });
  const { data: stagesData } = usePipelineStages(lead?.PipelineId);

  const calculateScore = useCalculateScore();
  const moveStage = useMoveLeadStage();
  const winLead = useWinLead();
  const loseLead = useLoseLead();
  const createActivity = useCreateActivity();
  const completeActivity = useCompleteActivity();
  const convertLead = useLeadConvert();
  const router = useRouter();
  const { showToast } = useToast();

  const stages = (stagesData as any)?.data ?? (stagesData as any)?.rows ?? stagesData ?? [];
  const activities = (activitiesData as any)?.data ?? (activitiesData as any)?.rows ?? activitiesData ?? [];
  const history = (historyData as any)?.data ?? (historyData as any)?.rows ?? historyData ?? [];

  /* Dialog states */
  const [noteDialogOpen, setNoteDialogOpen] = useState(false);
  const [noteForm, setNoteForm] = useState({ subject: "", description: "" });
  const [moveDialogOpen, setMoveDialogOpen] = useState(false);
  const [moveStageId, setMoveStageId] = useState<number | "">("");
  const [moveNotes, setMoveNotes] = useState("");
  const [loseDialogOpen, setLoseDialogOpen] = useState(false);
  const [loseReason, setLoseReason] = useState("");
  const [convertDialogOpen, setConvertDialogOpen] = useState(false);
  const [convertForm, setConvertForm] = useState({ dealName: "", pipelineId: "" as number | "", stageId: "" as number | "" });

  /* Handlers */
  const handleCreateNote = () => {
    createActivity.mutate(
      { leadId, activityType: "NOTE", subject: noteForm.subject, description: noteForm.description },
      {
        onSuccess: () => {
          setNoteDialogOpen(false);
          setNoteForm({ subject: "", description: "" });
        },
      },
    );
  };

  const handleMoveStage = () => {
    if (!moveStageId) return;
    moveStage.mutate(
      { leadId, newStageId: Number(moveStageId), notes: moveNotes || undefined },
      {
        onSuccess: () => {
          setMoveDialogOpen(false);
          setMoveStageId("");
          setMoveNotes("");
        },
      },
    );
  };

  const handleWin = () => {
    winLead.mutate({ id: leadId });
  };

  const handleLose = () => {
    loseLead.mutate(
      { id: leadId, reason: loseReason },
      {
        onSuccess: () => {
          setLoseDialogOpen(false);
          setLoseReason("");
        },
      },
    );
  };

  const handleRecalculateScore = () => {
    calculateScore.mutate(leadId);
  };

  const openConvertDialog = () => {
    if (!lead) return;
    setConvertForm({
      dealName: lead.ContactName
        ? `Deal — ${lead.ContactName}`
        : `Deal #${lead.LeadId}`,
      pipelineId: lead.PipelineId,
      stageId: lead.StageId,
    });
    setConvertDialogOpen(true);
  };

  const handleConvert = () => {
    convertLead.mutate(
      {
        leadId,
        dealName: convertForm.dealName.trim() || undefined,
        pipelineId: convertForm.pipelineId ? Number(convertForm.pipelineId) : undefined,
        stageId: convertForm.stageId ? Number(convertForm.stageId) : undefined,
      },
      {
        onSuccess: (res: any) => {
          const dealId = res?.id ?? res?.DealId ?? res?.data?.id;
          showToast("Lead convertido a deal", "success");
          setConvertDialogOpen(false);
          if (dealId) router.push(`/deals?deal=${dealId}`);
        },
        onError: (err) => showToast(String((err as Error).message), "error"),
      },
    );
  };

  /* Loading */
  if (isLoading) {
    return (
      <Paper sx={{ p: 3, borderRadius: 2 }}>
        <Stack spacing={2}>
          <Skeleton variant="circular" width={56} height={56} />
          <Skeleton variant="text" width="60%" height={32} />
          <Skeleton variant="rectangular" height={120} />
          <Skeleton variant="rectangular" height={200} />
        </Stack>
      </Paper>
    );
  }

  if (!lead) {
    return <Alert severity="warning">Lead no encontrado</Alert>;
  }

  const initial = (lead.ContactName ?? "?")[0].toUpperCase();
  const score = scoreData?.Score ?? 0;

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
      {/* ─── Header ──────────────────────────────────────────── */}
      <Box
        sx={{
          p: 2.5,
          background: (t) =>
            `linear-gradient(135deg, ${alpha(t.palette.primary.main, 0.08)}, ${alpha(t.palette.primary.main, 0.02)})`,
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <Avatar sx={{ width: 56, height: 56, bgcolor: "primary.main", fontSize: "1.4rem", fontWeight: 700 }}>
            {initial}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <Typography variant="h6" fontWeight={700} noWrap>
                {lead.ContactName}
              </Typography>
              <LeadScoreBadge score={score} size="medium" />
            </Box>
            {lead.CompanyName && (
              <Typography variant="body2" color="text.secondary">
                {lead.CompanyName}
              </Typography>
            )}
            <Box sx={{ display: "flex", gap: 0.5, mt: 0.5, flexWrap: "wrap" }}>
              <Chip
                label={statusLabel[lead.Status] ?? lead.Status}
                size="small"
                color={statusColor[lead.Status] ?? "default"}
              />
              <Chip
                label={lead.StageName}
                size="small"
                sx={{
                  bgcolor: lead.StageColor ? alpha(lead.StageColor, 0.15) : undefined,
                  color: lead.StageColor ?? undefined,
                  fontWeight: 600,
                }}
              />
              <Chip label={priorityLabel[lead.Priority] ?? lead.Priority} size="small" variant="outlined" />
            </Box>
          </Box>
          {onClose && (
            <IconButton onClick={onClose} size="small">
              <CloseIcon />
            </IconButton>
          )}
        </Box>
      </Box>

      <Box sx={{ p: 2.5 }}>
        {/* ─── Contact Info ───────────────────────────────────── */}
        <Stack direction="row" spacing={2} sx={{ mb: 2, flexWrap: "wrap" }}>
          {lead.Email && (
            <Chip
              icon={<EmailIcon />}
              label={lead.Email}
              component="a"
              href={`mailto:${lead.Email}`}
              clickable
              size="small"
              variant="outlined"
            />
          )}
          {lead.Phone && (
            <Chip
              icon={<PhoneIcon />}
              label={lead.Phone}
              component="a"
              href={`tel:${lead.Phone}`}
              clickable
              size="small"
              variant="outlined"
            />
          )}
          {lead.Source && (
            <Chip label={`Origen: ${lead.Source}`} size="small" variant="outlined" />
          )}
        </Stack>

        <Divider sx={{ my: 2 }} />

        {/* ─── Deal Info ─────────────────────────────────────── */}
        <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 2, mb: 2 }}>
          <Box>
            <Typography variant="caption" color="text.secondary">Valor estimado</Typography>
            <Typography variant="h5" fontWeight={700} color="success.main">
              {formatCurrency(lead.EstimatedValue)}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Etapa actual</Typography>
            <Box sx={{ mt: 0.3 }}>
              <Chip
                label={lead.StageName}
                size="small"
                sx={{
                  bgcolor: lead.StageColor ? alpha(lead.StageColor, 0.15) : undefined,
                  color: lead.StageColor ?? undefined,
                  fontWeight: 600,
                }}
              />
            </Box>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Probabilidad</Typography>
            <Typography variant="h6" fontWeight={600}>
              {lead.Probability != null ? `${lead.Probability}%` : "\u2014"}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Dias en etapa</Typography>
            <Typography variant="h6" fontWeight={600}>
              {lead.DaysInStage ?? "\u2014"}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Cierre esperado</Typography>
            <Typography variant="body1" fontWeight={500}>
              {formatDate(lead.ExpectedCloseDate)}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Pipeline</Typography>
            <Typography variant="body1" fontWeight={500}>
              {lead.PipelineName ?? "\u2014"}
            </Typography>
          </Box>
        </Box>

        <Divider sx={{ my: 2 }} />

        {/* ─── Quick Actions ─────────────────────────────────── */}
        {lead.Status === "OPEN" && (
          <>
            <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>
              Acciones rapidas
            </Typography>
            <Stack direction="row" spacing={1} sx={{ mb: 2, flexWrap: "wrap" }}>
              {lead.Phone && (
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<PhoneIcon />}
                  component="a"
                  href={`tel:${lead.Phone}`}
                >
                  Llamar
                </Button>
              )}
              {lead.Email && (
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<EmailIcon />}
                  component="a"
                  href={`mailto:${lead.Email}`}
                >
                  Email
                </Button>
              )}
              <Button
                variant="outlined"
                size="small"
                startIcon={<NoteAddIcon />}
                onClick={() => setNoteDialogOpen(true)}
              >
                Nueva Nota
              </Button>
              <Button
                variant="outlined"
                size="small"
                startIcon={<SwapHorizIcon />}
                onClick={() => setMoveDialogOpen(true)}
              >
                Mover Etapa
              </Button>
              <Button
                variant="contained"
                size="small"
                color="success"
                startIcon={<EmojiEventsIcon />}
                onClick={handleWin}
                disabled={winLead.isPending}
              >
                Ganado
              </Button>
              <Button
                variant="outlined"
                size="small"
                color="error"
                startIcon={<ThumbDownIcon />}
                onClick={() => setLoseDialogOpen(true)}
              >
                Perdido
              </Button>
              <Button
                variant="outlined"
                size="small"
                color="primary"
                startIcon={<TransformIcon />}
                onClick={openConvertDialog}
              >
                Convertir a Deal
              </Button>
            </Stack>
            <Divider sx={{ my: 2 }} />
          </>
        )}

        {/* ─── Activity Timeline ─────────────────────────────── */}
        <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>
          Actividad e Historial
        </Typography>
        <LeadActivityTimeline
          activities={activities}
          history={history}
          onComplete={(id) => completeActivity.mutate(id)}
        />

        <Divider sx={{ my: 2 }} />

        {/* ─── Score Section ─────────────────────────────────── */}
        <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>
          Score
        </Typography>
        <Box sx={{ display: "flex", alignItems: "center", gap: 2, mb: 1 }}>
          <LeadScoreBadge score={score} size="large" />
          <Box sx={{ flex: 1 }}>
            {scoreData?.Factors?.map((f, i) => (
              <Box key={i} sx={{ display: "flex", justifyContent: "space-between", mb: 0.3 }}>
                <Typography variant="caption" color="text.secondary">
                  {f.Description || f.Factor}
                </Typography>
                <Typography variant="caption" fontWeight={600}>
                  {f.Points}/{f.MaxPoints}
                </Typography>
              </Box>
            ))}
            {scoreData?.CalculatedAt && (
              <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block" }}>
                Calculado: {formatDate(scoreData.CalculatedAt)}
              </Typography>
            )}
          </Box>
          <Button
            variant="outlined"
            size="small"
            startIcon={<RefreshIcon />}
            onClick={handleRecalculateScore}
            disabled={calculateScore.isPending}
          >
            Recalcular
          </Button>
        </Box>

        {lead.Notes && (
          <>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 0.5 }}>
              Notas
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ whiteSpace: "pre-wrap" }}>
              {lead.Notes}
            </Typography>
          </>
        )}
      </Box>

      {/* ─── Dialogs ───────────────────────────────────────── */}

      {/* Nueva Nota */}
      <FormDialog
        open={noteDialogOpen}
        onClose={() => setNoteDialogOpen(false)}
        title="Nueva Nota"
        onSave={handleCreateNote}
        loading={createActivity.isPending}
        disableSave={!noteForm.subject.trim()}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Asunto"
            fullWidth
            required
            value={noteForm.subject}
            onChange={(e) => setNoteForm({ ...noteForm, subject: e.target.value })}
          />
          <TextField
            label="Descripcion"
            fullWidth
            multiline
            rows={3}
            value={noteForm.description}
            onChange={(e) => setNoteForm({ ...noteForm, description: e.target.value })}
          />
        </Stack>
      </FormDialog>

      {/* Mover Etapa */}
      <FormDialog
        open={moveDialogOpen}
        onClose={() => setMoveDialogOpen(false)}
        title="Mover a otra etapa"
        onSave={handleMoveStage}
        loading={moveStage.isPending}
        disableSave={!moveStageId}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <FormControl fullWidth>
            <InputLabel>Nueva etapa</InputLabel>
            <Select
              value={moveStageId}
              label="Nueva etapa"
              onChange={(e) => setMoveStageId(Number(e.target.value))}
            >
              {stages
                .filter((s: any) => s.StageId !== lead.StageId)
                .map((s: any) => (
                  <MenuItem key={s.StageId} value={s.StageId}>
                    {s.Name}
                  </MenuItem>
                ))}
            </Select>
          </FormControl>
          <TextField
            label="Notas (opcional)"
            fullWidth
            multiline
            rows={2}
            value={moveNotes}
            onChange={(e) => setMoveNotes(e.target.value)}
          />
        </Stack>
      </FormDialog>

      {/* Marcar Perdido */}
      <FormDialog
        open={loseDialogOpen}
        onClose={() => setLoseDialogOpen(false)}
        title="Marcar como Perdido"
        onSave={handleLose}
        loading={loseLead.isPending}
        disableSave={!loseReason.trim()}
        saveLabel="Marcar Perdido"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Razon de perdida"
            fullWidth
            required
            multiline
            rows={2}
            value={loseReason}
            onChange={(e) => setLoseReason(e.target.value)}
          />
        </Stack>
      </FormDialog>

      {/* Convertir a Deal */}
      <FormDialog
        open={convertDialogOpen}
        onClose={() => setConvertDialogOpen(false)}
        title="Convertir lead a deal"
        onSave={handleConvert}
        loading={convertLead.isPending}
        disableSave={!convertForm.dealName.trim()}
        saveLabel="Convertir"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Alert severity="info" variant="outlined">
            Se creará un Contact + Deal. El lead pasará a estado CONVERTED.
          </Alert>
          <TextField
            label="Nombre del deal"
            fullWidth
            required
            value={convertForm.dealName}
            onChange={(e) => setConvertForm({ ...convertForm, dealName: e.target.value })}
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <FormControl fullWidth>
              <InputLabel>Etapa inicial</InputLabel>
              <Select
                value={convertForm.stageId}
                label="Etapa inicial"
                onChange={(e) =>
                  setConvertForm({ ...convertForm, stageId: Number(e.target.value) })
                }
              >
                {(stages as Array<any>).map((s: any) => (
                  <MenuItem key={s.StageId} value={s.StageId}>
                    {s.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
        </Stack>
      </FormDialog>
    </Paper>
  );
}
