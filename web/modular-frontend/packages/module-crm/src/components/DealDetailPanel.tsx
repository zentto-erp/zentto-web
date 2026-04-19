"use client";

import React, { useState } from "react";
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardActionArea,
  CardContent,
  Chip,
  Divider,
  FormControl,
  IconButton,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Skeleton,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
  alpha,
} from "@mui/material";
import BusinessIcon from "@mui/icons-material/Business";
import CloseIcon from "@mui/icons-material/Close";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import EditIcon from "@mui/icons-material/Edit";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import PersonIcon from "@mui/icons-material/Person";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import {
  DeleteDialog,
  FormDialog,
  useDrawerQueryParam,
  useToast,
} from "@zentto/shared-ui";
import { formatCurrency } from "@zentto/shared-api";
import {
  useCloseLostDeal,
  useCloseWonDeal,
  useDeal,
  useDealTimeline,
  useDeleteDeal,
  useMoveDealStage,
  type Deal,
} from "../hooks/useDeals";
import { usePipelineStages } from "../hooks/useCRM";
import { PRIORITY_LABELS, type Priority } from "../types";

interface DealDetailPanelProps {
  dealId: number;
  onClose?: () => void;
  onEdit?: () => void;
}

function formatDate(d: string | null | undefined): string {
  if (!d) return "—";
  try {
    return new Date(d).toLocaleDateString("es", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return d;
  }
}

function formatDateTime(d: string | null | undefined): string {
  if (!d) return "—";
  try {
    return new Date(d).toLocaleString("es", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return d;
  }
}

const statusColor: Record<string, "success" | "error" | "info" | "default"> = {
  OPEN: "info",
  WON: "success",
  LOST: "error",
  ABANDONED: "default",
};

const statusLabel: Record<string, string> = {
  OPEN: "Abierto",
  WON: "Ganado",
  LOST: "Perdido",
  ABANDONED: "Abandonado",
};

export default function DealDetailPanel({
  dealId,
  onClose,
  onEdit,
}: DealDetailPanelProps) {
  const { data, isLoading } = useDeal(dealId);
  const deal = ((data as any)?.data ?? (data as any) ?? null) as Deal | null;
  const { showToast } = useToast();
  const [tab, setTab] = useState("overview");

  const contactDrawer = useDrawerQueryParam("contact");
  const companyDrawer = useDrawerQueryParam("company");

  const { data: stagesData } = usePipelineStages(deal?.PipelineId);
  const stages = (stagesData as any)?.data ?? (stagesData as any)?.rows ?? stagesData ?? [];

  const { data: timelineData } = useDealTimeline(dealId);
  const timelineEvents =
    (timelineData as any)?.data ?? (timelineData as any)?.rows ?? timelineData ?? [];

  const moveStage = useMoveDealStage();
  const closeWon = useCloseWonDeal();
  const closeLost = useCloseLostDeal();
  const deleteDeal = useDeleteDeal();

  const [moveDialogOpen, setMoveDialogOpen] = useState(false);
  const [moveStageId, setMoveStageId] = useState<number | "">("");
  const [moveNotes, setMoveNotes] = useState("");
  const [loseDialogOpen, setLoseDialogOpen] = useState(false);
  const [loseReason, setLoseReason] = useState("");
  const [deleteOpen, setDeleteOpen] = useState(false);

  const handleMoveStage = () => {
    if (!moveStageId || !deal) return;
    moveStage.mutate(
      { dealId: deal.DealId, newStageId: Number(moveStageId), notes: moveNotes || undefined },
      {
        onSuccess: () => {
          showToast("Deal movido de etapa", "success");
          setMoveDialogOpen(false);
          setMoveStageId("");
          setMoveNotes("");
        },
      },
    );
  };

  const handleWin = () => {
    if (!deal) return;
    closeWon.mutate(
      { id: deal.DealId },
      { onSuccess: () => showToast("Deal marcado como ganado", "success") },
    );
  };

  const handleLose = () => {
    if (!deal) return;
    closeLost.mutate(
      { id: deal.DealId, reason: loseReason },
      {
        onSuccess: () => {
          showToast("Deal marcado como perdido", "success");
          setLoseDialogOpen(false);
          setLoseReason("");
        },
      },
    );
  };

  const handleDelete = () => {
    if (!deal) return;
    deleteDeal.mutate(deal.DealId, {
      onSuccess: () => {
        showToast("Deal eliminado", "success");
        setDeleteOpen(false);
        onClose?.();
      },
    });
  };

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

  if (!deal) return <Alert severity="warning">Deal no encontrado</Alert>;

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
      <Box
        sx={{
          p: 2.5,
          background: (t) =>
            `linear-gradient(135deg, ${alpha(t.palette.primary.main, 0.08)}, ${alpha(
              t.palette.primary.main,
              0.02,
            )})`,
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <Avatar sx={{ width: 56, height: 56, bgcolor: "primary.main" }}>
            <EmojiEventsIcon />
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="h6" fontWeight={700} noWrap>
              {deal.Name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {deal.DealCode}
            </Typography>
            <Stack direction="row" spacing={0.5} sx={{ mt: 0.5, flexWrap: "wrap" }}>
              <Chip
                label={statusLabel[deal.Status] ?? deal.Status}
                size="small"
                color={statusColor[deal.Status] ?? "default"}
              />
              <Chip
                label={deal.StageName ?? "—"}
                size="small"
                sx={{
                  bgcolor: deal.StageColor ? alpha(deal.StageColor, 0.15) : undefined,
                  color: deal.StageColor ?? undefined,
                  fontWeight: 600,
                }}
              />
              <Chip
                label={PRIORITY_LABELS[deal.Priority as Priority] ?? deal.Priority}
                size="small"
                variant="outlined"
              />
            </Stack>
          </Box>
          <Stack direction="row" spacing={0.5}>
            {onEdit && (
              <IconButton size="small" onClick={onEdit} aria-label="editar">
                <EditIcon />
              </IconButton>
            )}
            <IconButton
              size="small"
              onClick={() => setDeleteOpen(true)}
              aria-label="eliminar"
              color="error"
            >
              <DeleteOutlineIcon />
            </IconButton>
            {onClose && (
              <IconButton size="small" onClick={onClose} aria-label="cerrar">
                <CloseIcon />
              </IconButton>
            )}
          </Stack>
        </Box>
      </Box>

      <Tabs
        value={tab}
        onChange={(_, v) => setTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{ borderBottom: "1px solid", borderColor: "divider", px: 2 }}
      >
        <Tab value="overview" label="Overview" />
        <Tab value="related" label="Contacto / Empresa" />
        <Tab value="timeline" label="Timeline" />
        <Tab value="notes" label="Notas" />
      </Tabs>

      <Box sx={{ p: 2.5 }}>
        {tab === "overview" && (
          <Stack spacing={2}>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
                gap: 2,
              }}
            >
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Valor
                </Typography>
                <Typography variant="h5" fontWeight={700} color="success.main">
                  {formatCurrency(deal.Value)} {deal.Currency && deal.Currency !== "USD" ? deal.Currency : ""}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Probabilidad
                </Typography>
                <Typography variant="h6" fontWeight={600}>
                  {deal.Probability != null ? `${deal.Probability}%` : "—"}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Cierre esperado
                </Typography>
                <Typography variant="body1" fontWeight={500}>
                  {formatDate(deal.ExpectedClose)}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Pipeline
                </Typography>
                <Typography variant="body1" fontWeight={500}>
                  {deal.PipelineName ?? "—"}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Owner
                </Typography>
                <Typography variant="body1" fontWeight={500}>
                  {deal.OwnerAgentName ?? "—"}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Origen
                </Typography>
                <Typography variant="body1" fontWeight={500}>
                  {deal.Source ?? "—"}
                </Typography>
              </Box>
            </Box>

            {deal.Tags && (
              <Box>
                <Typography variant="caption" color="text.secondary" sx={{ display: "block", mb: 0.5 }}>
                  Tags
                </Typography>
                <Stack direction="row" spacing={0.5} flexWrap="wrap">
                  {deal.Tags.split(",")
                    .map((t) => t.trim())
                    .filter(Boolean)
                    .map((t) => (
                      <Chip key={t} label={t} size="small" variant="outlined" />
                    ))}
                </Stack>
              </Box>
            )}

            <Divider />

            {deal.Status === "OPEN" && (
              <>
                <Typography variant="subtitle2" fontWeight={600}>
                  Acciones
                </Typography>
                <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<SwapHorizIcon />}
                    onClick={() => setMoveDialogOpen(true)}
                  >
                    Mover etapa
                  </Button>
                  <Button
                    variant="contained"
                    size="small"
                    color="success"
                    startIcon={<EmojiEventsIcon />}
                    onClick={handleWin}
                    disabled={closeWon.isPending}
                  >
                    Close Won
                  </Button>
                  <Button
                    variant="outlined"
                    size="small"
                    color="error"
                    startIcon={<ThumbDownIcon />}
                    onClick={() => setLoseDialogOpen(true)}
                  >
                    Close Lost
                  </Button>
                </Stack>
              </>
            )}

            {deal.ClosedAt && (
              <Alert
                severity={deal.Status === "WON" ? "success" : "error"}
                variant="outlined"
              >
                Cerrado el {formatDate(deal.ClosedAt)}
                {deal.LostReason ? ` — Razón: ${deal.LostReason}` : ""}
              </Alert>
            )}
          </Stack>
        )}

        {tab === "related" && (
          <Stack spacing={1.5}>
            {deal.ContactId && deal.ContactName ? (
              <Card variant="outlined" sx={{ borderRadius: 2 }}>
                <CardActionArea onClick={() => contactDrawer.openDrawer(deal.ContactId!)}>
                  <CardContent
                    sx={{ py: 1.5, display: "flex", alignItems: "center", gap: 1.5 }}
                  >
                    <Avatar sx={{ width: 32, height: 32, bgcolor: "primary.light" }}>
                      <PersonIcon fontSize="small" />
                    </Avatar>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="body2" fontWeight={600} noWrap>
                        {deal.ContactName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Contacto principal
                      </Typography>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            ) : (
              <Alert severity="info" variant="outlined">
                Sin contacto asociado.
              </Alert>
            )}
            {deal.CrmCompanyId && deal.CompanyName ? (
              <Card variant="outlined" sx={{ borderRadius: 2 }}>
                <CardActionArea
                  onClick={() => companyDrawer.openDrawer(deal.CrmCompanyId!)}
                >
                  <CardContent
                    sx={{ py: 1.5, display: "flex", alignItems: "center", gap: 1.5 }}
                  >
                    <Avatar sx={{ width: 32, height: 32, bgcolor: "primary.light" }}>
                      <BusinessIcon fontSize="small" />
                    </Avatar>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="body2" fontWeight={600} noWrap>
                        {deal.CompanyName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Empresa asociada
                      </Typography>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            ) : (
              <Alert severity="info" variant="outlined">
                Sin empresa asociada.
              </Alert>
            )}
          </Stack>
        )}

        {tab === "timeline" && (
          <Stack spacing={1.5}>
            {(!timelineEvents || timelineEvents.length === 0) && (
              <Alert severity="info" variant="outlined">
                Sin eventos registrados en la línea de tiempo.
              </Alert>
            )}
            {(timelineEvents as Array<any>).map((ev, idx) => (
              <Box
                key={idx}
                sx={{
                  borderLeft: "3px solid",
                  borderColor: "primary.main",
                  pl: 2,
                  py: 0.5,
                }}
              >
                <Typography variant="caption" color="text.secondary">
                  {formatDateTime(ev.EventDate)}
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {ev.Title ?? ev.EventType}
                </Typography>
                {ev.Description && (
                  <Typography variant="body2" color="text.secondary">
                    {ev.Description}
                  </Typography>
                )}
                {ev.Actor && (
                  <Typography variant="caption" color="text.secondary">
                    por {ev.Actor}
                  </Typography>
                )}
              </Box>
            ))}
          </Stack>
        )}

        {tab === "notes" && (
          <Box>
            {deal.Notes ? (
              <Typography variant="body2" sx={{ whiteSpace: "pre-wrap" }}>
                {deal.Notes}
              </Typography>
            ) : (
              <Alert severity="info" variant="outlined">
                Sin notas registradas en este deal.
              </Alert>
            )}
          </Box>
        )}
      </Box>

      {/* Dialogs */}
      <FormDialog
        open={moveDialogOpen}
        onClose={() => setMoveDialogOpen(false)}
        title="Mover a otra etapa"
        mode="edit"
        onSave={handleMoveStage}
        loading={moveStage.isPending}
        disableSave={!moveStageId}
        saveLabel="Mover"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <FormControl fullWidth>
            <InputLabel>Nueva etapa</InputLabel>
            <Select
              value={moveStageId}
              label="Nueva etapa"
              onChange={(e) => setMoveStageId(Number(e.target.value))}
            >
              {(stages as Array<any>)
                .filter((s: any) => s.StageId !== deal.StageId)
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

      <FormDialog
        open={loseDialogOpen}
        onClose={() => setLoseDialogOpen(false)}
        title="Marcar deal como perdido"
        mode="edit"
        onSave={handleLose}
        loading={closeLost.isPending}
        disableSave={!loseReason.trim()}
        saveLabel="Close Lost"
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Razón de pérdida"
            fullWidth
            required
            multiline
            rows={2}
            value={loseReason}
            onChange={(e) => setLoseReason(e.target.value)}
          />
        </Stack>
      </FormDialog>

      <DeleteDialog
        open={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
        itemName={`el deal "${deal.Name}" (${deal.DealCode})`}
        loading={deleteDeal.isPending}
      />
    </Paper>
  );
}
