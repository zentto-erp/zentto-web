"use client";

import React, { useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Divider,
  Paper,
  Skeleton,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { FormDialog } from "@zentto/shared-ui";
import { ActivityTypeChip } from "./shared/ActivityTypeChip";
import {
  ACTIVITY_STATUS_LABELS,
  isActivityType,
  type ActivityType,
} from "../types";
import {
  useActivitiesList,
  useCompleteActivity,
  useDeleteActivity,
  useUpdateActivity,
  type Activity,
} from "../hooks/useCRM";

export interface ActivityDetailPanelProps {
  activityId: number;
  onClose?: () => void;
  /**
   * Row opcional precargado desde la lista — evita re-fetch. Si no se pasa,
   * el panel busca en la lista ya cargada por el filtro vacío.
   */
  initialActivity?: Activity | null;
}

function formatDate(d: string | null | undefined): string {
  if (!d) return "\u2014";
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

/**
 * Panel de detalle de una actividad CRM. Se monta dentro de
 * `<RightDetailDrawer>` y expone acciones rápidas: marcar completada, editar,
 * eliminar.
 *
 * Actualmente no existe un endpoint GET /actividades/:id — el panel resuelve
 * el registro desde la lista en caché (React Query). Cuando se añada el
 * endpoint, reemplazar el lookup por `useActivityDetail(id)`.
 */
export default function ActivityDetailPanel({
  activityId,
  onClose,
  initialActivity,
}: ActivityDetailPanelProps) {
  // Busca el activity en la lista ya cargada. Si no está, dispara una nueva query.
  const { data, isLoading } = useActivitiesList();
  const rows: Activity[] = useMemo(
    () => ((data as any)?.data ?? (data as any)?.rows ?? data ?? []) as Activity[],
    [data],
  );
  const activity = useMemo(
    () => initialActivity ?? rows.find((a) => a.ActivityId === activityId) ?? null,
    [initialActivity, rows, activityId],
  );

  const completeActivity = useCompleteActivity();
  const updateActivity = useUpdateActivity();
  const deleteActivity = useDeleteActivity();

  const [editOpen, setEditOpen] = useState(false);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false);
  const [editForm, setEditForm] = useState({
    subject: "",
    description: "",
    dueDate: "",
    activityType: "CALL" as ActivityType,
  });

  const openEdit = () => {
    if (!activity) return;
    setEditForm({
      subject: activity.Subject ?? "",
      description: activity.Description ?? "",
      dueDate: activity.DueDate ? activity.DueDate.slice(0, 10) : "",
      activityType: isActivityType(activity.ActivityType)
        ? activity.ActivityType
        : "TASK",
    });
    setEditOpen(true);
  };

  const handleSaveEdit = () => {
    if (!activity) return;
    updateActivity.mutate(
      {
        id: activity.ActivityId,
        subject: editForm.subject,
        description: editForm.description,
        dueDate: editForm.dueDate || undefined,
        activityType: editForm.activityType,
      },
      { onSuccess: () => setEditOpen(false) },
    );
  };

  const handleComplete = () => {
    if (!activity) return;
    completeActivity.mutate(activity.ActivityId);
  };

  const handleDelete = () => {
    if (!activity) return;
    deleteActivity.mutate(activity.ActivityId, {
      onSuccess: () => {
        setConfirmDeleteOpen(false);
        onClose?.();
      },
    });
  };

  if (isLoading && !activity) {
    return (
      <Paper sx={{ p: 2.5, borderRadius: 2 }}>
        <Stack spacing={2}>
          <Skeleton variant="text" width="60%" height={28} />
          <Skeleton variant="rectangular" height={80} />
          <Skeleton variant="rectangular" height={40} />
        </Stack>
      </Paper>
    );
  }

  if (!activity) {
    return <Alert severity="warning">Actividad no encontrada</Alert>;
  }

  const statusKey = activity.IsCompleted ? "completed" : "pending";

  return (
    <Paper sx={{ p: 2.5, borderRadius: 2 }}>
      {/* Header */}
      <Stack direction="row" spacing={1} sx={{ mb: 1.5, alignItems: "center", flexWrap: "wrap" }}>
        <ActivityTypeChip type={activity.ActivityType} size="small" />
        <Chip
          label={ACTIVITY_STATUS_LABELS[statusKey]}
          size="small"
          color={activity.IsCompleted ? "success" : "default"}
          variant={activity.IsCompleted ? "filled" : "outlined"}
        />
      </Stack>

      <Typography variant="h6" fontWeight={700} sx={{ mb: 0.5 }}>
        {activity.Subject || "(Sin asunto)"}
      </Typography>
      {activity.LeadCode && (
        <Typography variant="caption" color="text.secondary">
          Lead: {activity.LeadCode}
        </Typography>
      )}

      {activity.Description && (
        <Box sx={{ mt: 1.5 }}>
          <Typography variant="body2" color="text.secondary" sx={{ whiteSpace: "pre-wrap" }}>
            {activity.Description}
          </Typography>
        </Box>
      )}

      <Divider sx={{ my: 2 }} />

      {/* Metadata */}
      <Stack spacing={1}>
        <Stack direction="row" spacing={1}>
          <Typography variant="caption" color="text.secondary" sx={{ minWidth: 110 }}>
            Fecha límite
          </Typography>
          <Typography variant="body2">{formatDate(activity.DueDate)}</Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          <Typography variant="caption" color="text.secondary" sx={{ minWidth: 110 }}>
            Asignado a
          </Typography>
          <Typography variant="body2">{activity.AssignedToName ?? "\u2014"}</Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          <Typography variant="caption" color="text.secondary" sx={{ minWidth: 110 }}>
            Creado
          </Typography>
          <Typography variant="body2">{formatDate(activity.CreatedAt)}</Typography>
        </Stack>
        {activity.CompletedAt && (
          <Stack direction="row" spacing={1}>
            <Typography variant="caption" color="text.secondary" sx={{ minWidth: 110 }}>
              Completada
            </Typography>
            <Typography variant="body2">{formatDate(activity.CompletedAt)}</Typography>
          </Stack>
        )}
      </Stack>

      <Divider sx={{ my: 2 }} />

      {/* Actions */}
      <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap" }}>
        {!activity.IsCompleted && (
          <Button
            variant="contained"
            size="small"
            color="success"
            startIcon={<CheckCircleIcon />}
            onClick={handleComplete}
            disabled={completeActivity.isPending}
          >
            Marcar completada
          </Button>
        )}
        <Button
          variant="outlined"
          size="small"
          startIcon={<EditIcon />}
          onClick={openEdit}
        >
          Editar
        </Button>
        <Button
          variant="outlined"
          size="small"
          color="error"
          startIcon={<DeleteIcon />}
          onClick={() => setConfirmDeleteOpen(true)}
        >
          Eliminar
        </Button>
      </Stack>

      {/* Edit dialog */}
      <FormDialog
        open={editOpen}
        onClose={() => setEditOpen(false)}
        title="Editar actividad"
        mode="edit"
        onSave={handleSaveEdit}
        loading={updateActivity.isPending}
        disableSave={!editForm.subject.trim()}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            select
            label="Tipo"
            fullWidth
            SelectProps={{ native: true }}
            value={editForm.activityType}
            onChange={(e) =>
              setEditForm({ ...editForm, activityType: e.target.value as ActivityType })
            }
          >
            <option value="CALL">Llamada</option>
            <option value="EMAIL">Correo</option>
            <option value="MEETING">Reunión</option>
            <option value="NOTE">Nota</option>
            <option value="TASK">Tarea</option>
          </TextField>
          <TextField
            label="Asunto"
            fullWidth
            required
            value={editForm.subject}
            onChange={(e) => setEditForm({ ...editForm, subject: e.target.value })}
          />
          <TextField
            label="Descripción"
            fullWidth
            multiline
            rows={3}
            value={editForm.description}
            onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
          />
          <TextField
            label="Fecha límite"
            type="date"
            fullWidth
            InputLabelProps={{ shrink: true }}
            value={editForm.dueDate}
            onChange={(e) => setEditForm({ ...editForm, dueDate: e.target.value })}
          />
        </Stack>
      </FormDialog>

      {/* Delete confirm */}
      <FormDialog
        open={confirmDeleteOpen}
        onClose={() => setConfirmDeleteOpen(false)}
        title="Eliminar actividad"
        mode="edit"
        saveLabel="Eliminar"
        onSave={handleDelete}
        loading={deleteActivity.isPending}
      >
        <Typography variant="body2">
          ¿Seguro que deseas eliminar la actividad "{activity.Subject}"? Esta acción no se puede deshacer.
        </Typography>
      </FormDialog>
    </Paper>
  );
}
