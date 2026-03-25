'use client';

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, IconButton, InputLabel, LinearProgress, MenuItem, Paper,
  Select, Slider, Stack, Tab, Tabs, TextField, Tooltip, Typography,
  useMediaQuery, useTheme, CircularProgress,
} from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';
import FormatListBulletedIcon from '@mui/icons-material/FormatListBulleted';
import MailOutlineIcon from '@mui/icons-material/MailOutline';
import DoneAllIcon from '@mui/icons-material/DoneAll';
import CheckIcon from '@mui/icons-material/Check';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import type { ColumnDef } from '@zentto/datagrid-core';
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
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  const tabParam = searchParams.get('tab') ?? 'notificaciones';
  const [activeTab, setActiveTab] = useState(TAB_MAP[tabParam] ?? 0);

  const handleTabChange = (_: React.SyntheticEvent, newVal: number) => {
    setActiveTab(newVal);
    const name = TAB_NAMES[newVal];
    router.replace(`/notificaciones${name === 'notificaciones' ? '' : `?tab=${name}`}`, { scroll: false });
  };

  if (!registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

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
  const gridRef = useRef<any>(null);
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

  const columns = useMemo<ColumnDef[]>(() => [
    {
      field: 'type',
      header: 'Tipo',
      width: 110,
      sortable: true,
      groupable: true,
      statusColors: { info: 'info', success: 'success', warning: 'warning', error: 'error' },
      statusVariant: 'filled',
    },
    { field: 'title', header: 'Titulo', flex: 1, minWidth: 180, sortable: true },
    { field: 'message', header: 'Mensaje', flex: 2, minWidth: 200, sortable: true },
    { field: 'time', header: 'Fecha', width: 160, sortable: true },
    {
      field: 'estadoLabel',
      header: 'Estado',
      width: 120,
      sortable: true,
      statusColors: { 'No leida': 'primary', 'Leida': 'default' },
      statusVariant: 'outlined',
    },
  ], []);

  const mappedRows = useMemo(() =>
    rows.map((r) => ({
      id: r.id,
      type: r.type,
      title: r.title,
      message: r.message,
      time: r.time,
      estadoLabel: r.read ? 'Leida' : 'No leida',
    })),
    [rows]
  );

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = columns;
    el.rows = mappedRows;
    el.loading = isLoading;
  }, [mappedRows, isLoading, columns]);

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
        <zentto-grid
          ref={gridRef}
          height="100%"
          export-filename="notificaciones"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
        />
      </Paper>
    </Stack>
  );
}

// ═══════════════════════════════════════════════════════════════
// TAB: Tareas
// ═══════════════════════════════════════════════════════════════

function TasksTab({ isMobile }: { isMobile: boolean }) {
  const gridRef = useRef<any>(null);
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

  const handleSaveProgress = async () => {
    if (!editDialog) return;
    await toggleTask.mutateAsync({ id: editDialog.id, progress: sliderVal });
    setEditDialog(null);
    refetch();
  };

  const columns = useMemo<ColumnDef[]>(() => [
    { field: 'title', header: 'Titulo', flex: 1, minWidth: 180, sortable: true },
    { field: 'description', header: 'Descripcion', flex: 1.5, minWidth: 200, sortable: true },
    { field: 'progress', header: 'Progreso', width: 100, type: 'number', sortable: true },
    { field: 'assignedTo', header: 'Asignado a', width: 140, sortable: true },
    { field: 'dueDate', header: 'Vencimiento', width: 130, sortable: true },
    {
      field: 'estadoLabel',
      header: 'Estado',
      width: 120,
      sortable: true,
      groupable: true,
      statusColors: { Completada: 'success', Pendiente: 'warning' },
      statusVariant: 'filled',
    },
  ], []);

  const mappedRows = useMemo(() =>
    rows.map((r) => ({
      id: r.id,
      title: r.title,
      description: r.description,
      progress: r.progress,
      assignedTo: r.assignedTo,
      dueDate: r.dueDate,
      estadoLabel: r.progress === 100 ? 'Completada' : 'Pendiente',
    })),
    [rows]
  );

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = columns;
    el.rows = mappedRows;
    el.loading = isLoading;
  }, [mappedRows, isLoading, columns]);

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
        <zentto-grid
          ref={gridRef}
          height="100%"
          export-filename="tareas"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
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
  const gridRef = useRef<any>(null);
  const [filters, setFilters] = useState<MessageFilters>({});
  const { data, isLoading, refetch } = useMessagesList(filters);
  const markRead = useMarkMessageRead();
  const [selectedMsg, setSelectedMsg] = useState<MessageItem | null>(null);

  const rows: MessageItem[] = data?.data ?? [];

  const handleMarkRead = async (id: string) => {
    await markRead.mutateAsync(id);
    refetch();
  };

  const columns = useMemo<ColumnDef[]>(() => [
    { field: 'sender', header: 'Remitente', width: 180, sortable: true },
    { field: 'subject', header: 'Asunto', flex: 1, minWidth: 220, sortable: true },
    { field: 'time', header: 'Fecha', width: 160, sortable: true },
    {
      field: 'estadoLabel',
      header: 'Estado',
      width: 120,
      sortable: true,
      statusColors: { 'No leido': 'primary', 'Leido': 'default' },
      statusVariant: 'outlined',
    },
  ], []);

  const mappedRows = useMemo(() =>
    rows.map((r) => ({
      id: r.id,
      sender: r.sender,
      subject: r.subject,
      time: r.time,
      estadoLabel: r.unread ? 'No leido' : 'Leido',
    })),
    [rows]
  );

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = columns;
    el.rows = mappedRows;
    el.loading = isLoading;
  }, [mappedRows, isLoading, columns]);

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
        <zentto-grid
          ref={gridRef}
          height="100%"
          export-filename="mensajes"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
