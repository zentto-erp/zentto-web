'use client';

import React, { useCallback, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, IconButton, InputLabel, LinearProgress, MenuItem, Paper,
  Select, Slider, Stack, Tab, Tabs, TextField, Tooltip, Typography,
  useMediaQuery, useTheme,
} from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';
import FormatListBulletedIcon from '@mui/icons-material/FormatListBulleted';
import MailOutlineIcon from '@mui/icons-material/MailOutline';
import DoneAllIcon from '@mui/icons-material/DoneAll';
import CheckIcon from '@mui/icons-material/Check';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import { ZenttoDataGrid } from '@zentto/shared-ui';
import type { ZenttoColDef } from '@zentto/shared-ui';
import {
  useNotificationsList, useMarkNotificationsRead,
  useTasksList, useToggleTask,
  useMessagesList, useMarkMessageRead,
} from '@zentto/shared-api';
import type {
  NotificationItem, NotificationFilters,
  TaskItem, TaskFilters,
  MessageItem, MessageFilters,
} from '@zentto/shared-api';

// ─── Tab mapping ──────────────────────────────────────────────

const TAB_MAP: Record<string, number> = {
  notificaciones: 0,
  tareas: 1,
  mensajes: 2,
};
const TAB_NAMES = ['notificaciones', 'tareas', 'mensajes'] as const;

// ─── Main Page ────────────────────────────────────────────────

export default function NotificacionesPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const tabParam = searchParams.get('tab') ?? 'notificaciones';
  const [activeTab, setActiveTab] = useState(TAB_MAP[tabParam] ?? 0);

  const handleTabChange = (_: React.SyntheticEvent, newVal: number) => {
    setActiveTab(newVal);
    const name = TAB_NAMES[newVal];
    router.replace(`/notificaciones${name === 'notificaciones' ? '' : `?tab=${name}`}`, { scroll: false });
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 } }}>
      <Typography variant="h5" fontWeight="bold" sx={{ mb: 2 }}>
        Centro de Notificaciones
      </Typography>

      <Paper sx={{ mb: 2 }}>
        <Tabs
          value={activeTab}
          onChange={handleTabChange}
          variant={isMobile ? 'scrollable' : 'standard'}
          scrollButtons={isMobile ? 'auto' : false}
          allowScrollButtonsMobile
        >
          <Tab icon={<NotificationsIcon />} iconPosition="start" label="Notificaciones" />
          <Tab icon={<FormatListBulletedIcon />} iconPosition="start" label="Tareas" />
          <Tab icon={<MailOutlineIcon />} iconPosition="start" label="Mensajes" />
        </Tabs>
      </Paper>

      {activeTab === 0 && <NotificationsTab isMobile={isMobile} />}
      {activeTab === 1 && <TasksTab isMobile={isMobile} />}
      {activeTab === 2 && <MessagesTab isMobile={isMobile} />}
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════
// TAB: Notificaciones
// ═══════════════════════════════════════════════════════════════

function NotificationsTab({ isMobile }: { isMobile: boolean }) {
  const router = useRouter();
  const [filters, setFilters] = useState<NotificationFilters>({});
  const { data, isLoading, refetch } = useNotificationsList(filters);
  const markRead = useMarkNotificationsRead();

  const rows: NotificationItem[] = data?.data ?? [];

  const handleMarkAllRead = async () => {
    const unreadIds = rows.filter(r => !r.read).map(r => Number(r.id));
    if (unreadIds.length > 0) {
      await markRead.mutateAsync(unreadIds);
      refetch();
    }
  };

  const handleMarkOneRead = async (id: string) => {
    await markRead.mutateAsync([Number(id)]);
    refetch();
  };

  const handleRowClick = (row: NotificationItem) => {
    if (!row.read) handleMarkOneRead(row.id);
    if (row.route) router.push(row.route);
  };

  const typeColors: Record<string, 'info' | 'success' | 'warning' | 'error'> = {
    info: 'info',
    success: 'success',
    warning: 'warning',
    error: 'error',
  };

  const columns: ZenttoColDef[] = useMemo(() => [
    {
      field: 'type',
      headerName: 'Tipo',
      width: 110,
      statusColors: { info: 'info', success: 'success', warning: 'warning', error: 'error' },
      statusVariant: 'filled',
    },
    { field: 'title', headerName: 'Titulo', flex: 1, minWidth: 180 },
    { field: 'message', headerName: 'Mensaje', flex: 2, minWidth: 200, mobileHide: true },
    { field: 'time', headerName: 'Fecha', width: 160, mobileHide: true },
    {
      field: 'read',
      headerName: 'Estado',
      width: 120,
      renderCell: (params) => (
        <Chip
          size="small"
          label={params.value ? 'Leida' : 'No leida'}
          color={params.value ? 'default' : 'primary'}
          variant={params.value ? 'outlined' : 'filled'}
        />
      ),
    },
    {
      field: 'route',
      headerName: 'Ruta',
      width: 80,
      mobileHide: true,
      tabletHide: true,
      renderCell: (params) =>
        params.value ? (
          <Tooltip title="Ir a destino">
            <OpenInNewIcon fontSize="small" color="action" />
          </Tooltip>
        ) : null,
    },
    {
      field: 'actions',
      headerName: '',
      width: 60,
      sortable: false,
      filterable: false,
      renderCell: (params) =>
        !params.row.read ? (
          <Tooltip title="Marcar como leida">
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                handleMarkOneRead(params.row.id);
              }}
            >
              <CheckIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        ) : null,
    },
  ], []);

  const unreadCount = rows.filter(r => !r.read).length;

  return (
    <Stack spacing={2}>
      {/* Filters */}
      <Paper sx={{ p: 2 }}>
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          alignItems={{ sm: 'center' }}
          flexWrap="wrap"
        >
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Tipo</InputLabel>
            <Select
              value={filters.type ?? ''}
              label="Tipo"
              onChange={(e) => setFilters(f => ({ ...f, type: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="info">Info</MenuItem>
              <MenuItem value="success">Exito</MenuItem>
              <MenuItem value="warning">Advertencia</MenuItem>
              <MenuItem value="error">Error</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filters.read ?? ''}
              label="Estado"
              onChange={(e) => setFilters(f => ({ ...f, read: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="false">No leidos</MenuItem>
              <MenuItem value="true">Leidos</MenuItem>
            </Select>
          </FormControl>
          <TextField
            type="date"
            label="Desde"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={filters.dateFrom ?? ''}
            onChange={(e) => setFilters(f => ({ ...f, dateFrom: e.target.value || undefined }))}
            sx={{ minWidth: 150 }}
          />
          <TextField
            type="date"
            label="Hasta"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={filters.dateTo ?? ''}
            onChange={(e) => setFilters(f => ({ ...f, dateTo: e.target.value || undefined }))}
            sx={{ minWidth: 150 }}
          />
          <Box sx={{ flex: 1 }} />
          {unreadCount > 0 && (
            <Button
              variant="outlined"
              size="small"
              startIcon={<DoneAllIcon />}
              onClick={handleMarkAllRead}
              disabled={markRead.isPending}
            >
              Marcar todas como leidas ({unreadCount})
            </Button>
          )}
        </Stack>
      </Paper>

      {/* Grid */}
      <Paper sx={{ height: 600 }}>
        <ZenttoDataGrid
          gridId="notification-center-notifs"
          rows={rows}
          columns={columns}
          loading={isLoading}
          getRowId={(row) => row.id}
          onRowClick={(params) => handleRowClick(params.row as NotificationItem)}
          mobileVisibleFields={['type', 'title', 'read']}
          smExtraFields={['message', 'time']}
          density="compact"
          toolbarTitle="Notificaciones"
          showExportCsv
          exportFilename="notificaciones"
          getRowClassName={(params) =>
            params.row.read ? '' : 'zentto-row-unread'
          }
          sx={{
            '& .zentto-row-unread': {
              bgcolor: 'action.hover',
              fontWeight: 500,
            },
          }}
        />
      </Paper>
    </Stack>
  );
}

// ═══════════════════════════════════════════════════════════════
// TAB: Tareas
// ═══════════════════════════════════════════════════════════════

function TasksTab({ isMobile }: { isMobile: boolean }) {
  const [filters, setFilters] = useState<TaskFilters>({});
  const { data, isLoading, refetch } = useTasksList(filters);
  const toggleTask = useToggleTask();
  const [editDialog, setEditDialog] = useState<TaskItem | null>(null);
  const [sliderVal, setSliderVal] = useState(0);

  const rows: TaskItem[] = data?.data ?? [];

  const handleToggleComplete = async (task: TaskItem) => {
    const newProgress = task.progress === 100 ? 0 : 100;
    await toggleTask.mutateAsync({ id: task.id, progress: newProgress });
    refetch();
  };

  const handleOpenProgress = (task: TaskItem) => {
    setSliderVal(task.progress);
    setEditDialog(task);
  };

  const handleSaveProgress = async () => {
    if (!editDialog) return;
    await toggleTask.mutateAsync({ id: editDialog.id, progress: sliderVal });
    setEditDialog(null);
    refetch();
  };

  const columns: ZenttoColDef[] = useMemo(() => [
    { field: 'title', headerName: 'Titulo', flex: 1, minWidth: 180 },
    { field: 'description', headerName: 'Descripcion', flex: 1.5, minWidth: 200, mobileHide: true },
    {
      field: 'progress',
      headerName: 'Progreso',
      width: 180,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', width: '100%', gap: 1 }}>
          <LinearProgress
            variant="determinate"
            value={params.value as number}
            color={(params.row.color as any) ?? 'primary'}
            sx={{ flex: 1, borderRadius: 1, height: 8 }}
          />
          <Typography variant="caption" sx={{ minWidth: 35, textAlign: 'right' }}>
            {params.value}%
          </Typography>
        </Box>
      ),
    },
    {
      field: 'color',
      headerName: 'Color',
      width: 100,
      mobileHide: true,
      tabletHide: true,
      renderCell: (params) => (
        <Chip size="small" label={params.value as string} color={(params.value as any) ?? 'default'} />
      ),
    },
    { field: 'assignedTo', headerName: 'Asignado a', width: 140, mobileHide: true },
    { field: 'dueDate', headerName: 'Vencimiento', width: 130, mobileHide: true },
    {
      field: 'completed',
      headerName: 'Estado',
      width: 120,
      renderCell: (params) => {
        const done = params.row.progress === 100;
        return (
          <Chip
            size="small"
            label={done ? 'Completada' : 'Pendiente'}
            color={done ? 'success' : 'warning'}
            variant={done ? 'filled' : 'outlined'}
          />
        );
      },
    },
    {
      field: 'actions',
      headerName: '',
      width: 120,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Cambiar progreso">
            <Button
              size="small"
              variant="text"
              sx={{ minWidth: 0, textTransform: 'none', fontSize: '0.75rem' }}
              onClick={(e) => {
                e.stopPropagation();
                handleOpenProgress(params.row as TaskItem);
              }}
            >
              Editar
            </Button>
          </Tooltip>
          <Tooltip title={params.row.progress === 100 ? 'Reabrir' : 'Completar'}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                handleToggleComplete(params.row as TaskItem);
              }}
            >
              <CheckIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ], []);

  return (
    <Stack spacing={2}>
      {/* Filters */}
      <Paper sx={{ p: 2 }}>
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          alignItems={{ sm: 'center' }}
        >
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filters.status ?? ''}
              label="Estado"
              onChange={(e) => setFilters(f => ({ ...f, status: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="pending">Pendiente</MenuItem>
              <MenuItem value="completed">Completada</MenuItem>
            </Select>
          </FormControl>
          <TextField
            label="Asignado a"
            size="small"
            value={filters.assignedTo ?? ''}
            onChange={(e) => setFilters(f => ({ ...f, assignedTo: e.target.value || undefined }))}
            sx={{ minWidth: 180 }}
          />
        </Stack>
      </Paper>

      {/* Grid */}
      <Paper sx={{ height: 600 }}>
        <ZenttoDataGrid
          gridId="notification-center-tasks"
          rows={rows}
          columns={columns}
          loading={isLoading}
          getRowId={(row) => row.id}
          mobileVisibleFields={['title', 'progress', 'completed']}
          smExtraFields={['assignedTo', 'dueDate']}
          density="compact"
          toolbarTitle="Tareas"
          showExportCsv
          exportFilename="tareas"
        />
      </Paper>

      {/* Progress Dialog */}
      <Dialog
        open={!!editDialog}
        onClose={() => setEditDialog(null)}
        fullScreen={isMobile}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Cambiar progreso</DialogTitle>
        <DialogContent>
          <Typography variant="subtitle2" sx={{ mb: 2 }}>
            {editDialog?.title}
          </Typography>
          <Box sx={{ px: 2 }}>
            <Slider
              value={sliderVal}
              onChange={(_, v) => setSliderVal(v as number)}
              step={5}
              marks
              min={0}
              max={100}
              valueLabelDisplay="on"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialog(null)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSaveProgress}
            disabled={toggleTask.isPending}
          >
            Guardar
          </Button>
        </DialogActions>
      </Dialog>
    </Stack>
  );
}

// ═══════════════════════════════════════════════════════════════
// TAB: Mensajes
// ═══════════════════════════════════════════════════════════════

function MessagesTab({ isMobile }: { isMobile: boolean }) {
  const [filters, setFilters] = useState<MessageFilters>({});
  const { data, isLoading, refetch } = useMessagesList(filters);
  const markRead = useMarkMessageRead();
  const [selectedMsg, setSelectedMsg] = useState<MessageItem | null>(null);

  const rows: MessageItem[] = data?.data ?? [];

  const handleMarkRead = async (id: string) => {
    await markRead.mutateAsync(id);
    refetch();
  };

  const handleRowClick = (msg: MessageItem) => {
    if (msg.unread) handleMarkRead(msg.id);
    setSelectedMsg(msg);
  };

  const columns: ZenttoColDef[] = useMemo(() => [
    { field: 'sender', headerName: 'Remitente', width: 180 },
    { field: 'subject', headerName: 'Asunto', flex: 1, minWidth: 220 },
    { field: 'time', headerName: 'Fecha', width: 160, mobileHide: true },
    {
      field: 'unread',
      headerName: 'Estado',
      width: 120,
      renderCell: (params) => (
        <Chip
          size="small"
          label={params.value ? 'No leido' : 'Leido'}
          color={params.value ? 'primary' : 'default'}
          variant={params.value ? 'filled' : 'outlined'}
        />
      ),
    },
    {
      field: 'actions',
      headerName: '',
      width: 60,
      sortable: false,
      filterable: false,
      renderCell: (params) =>
        params.row.unread ? (
          <Tooltip title="Marcar como leido">
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                handleMarkRead(params.row.id);
              }}
            >
              <CheckIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        ) : null,
    },
  ], []);

  return (
    <Stack spacing={2}>
      {/* Filters */}
      <Paper sx={{ p: 2 }}>
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          alignItems={{ sm: 'center' }}
        >
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filters.read ?? ''}
              label="Estado"
              onChange={(e) => setFilters(f => ({ ...f, read: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="false">No leidos</MenuItem>
              <MenuItem value="true">Leidos</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {/* Grid */}
      <Paper sx={{ height: 600 }}>
        <ZenttoDataGrid
          gridId="notification-center-msgs"
          rows={rows}
          columns={columns}
          loading={isLoading}
          getRowId={(row) => row.id}
          onRowClick={(params) => handleRowClick(params.row as MessageItem)}
          mobileVisibleFields={['sender', 'subject', 'unread']}
          smExtraFields={['time']}
          density="compact"
          toolbarTitle="Mensajes"
          showExportCsv
          exportFilename="mensajes"
          getRowClassName={(params) =>
            params.row.unread ? 'zentto-row-unread' : ''
          }
          sx={{
            '& .zentto-row-unread': {
              bgcolor: 'action.hover',
              fontWeight: 500,
            },
          }}
        />
      </Paper>

      {/* Message Detail Dialog */}
      <Dialog
        open={!!selectedMsg}
        onClose={() => setSelectedMsg(null)}
        fullScreen={isMobile}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Stack spacing={0.5}>
            <Typography variant="subtitle1" fontWeight="bold">
              {selectedMsg?.subject}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              De: {selectedMsg?.sender} &middot; {selectedMsg?.time}
            </Typography>
          </Stack>
        </DialogTitle>
        <DialogContent dividers>
          <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
            {selectedMsg?.body ?? selectedMsg?.subject}
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedMsg(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Stack>
  );
}
