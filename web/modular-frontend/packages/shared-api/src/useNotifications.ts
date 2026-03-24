'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost, apiPatch } from './api';

// ─── Types ──────────────────────────────────────────────────

export interface NotificationItem {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  time: string;
  read: boolean;
  route: string | null;
}

export interface NotificationFilters {
  type?: string;
  read?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  pageSize?: number;
}

export interface TaskItem {
  id: string;
  title: string;
  description?: string;
  progress: number;
  color: 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning';
  assignedTo?: string;
  dueDate?: string;
  completed?: boolean;
}

export interface TaskFilters {
  status?: string;
  assignedTo?: string;
  page?: number;
  pageSize?: number;
}

export interface MessageItem {
  id: string;
  sender: string;
  avatar?: string;
  subject: string;
  body?: string;
  time: string;
  unread: boolean;
}

export interface MessageFilters {
  read?: string;
  page?: number;
  pageSize?: number;
}

// ─── Hooks: Notifications ───────────────────────────────────

const QK_NOTIFS = 'notifications-center';
const QK_TASKS = 'tasks-center';
const QK_MSGS = 'messages-center';

export function useNotificationsList(filters: NotificationFilters = {}) {
  return useQuery({
    queryKey: [QK_NOTIFS, filters],
    queryFn: () => apiGet('/v1/sistema/notificaciones', filters as Record<string, unknown>),
  });
}

export function useMarkNotificationsRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (ids: number[]) => apiPost('/v1/sistema/notificaciones/leido', { ids }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_NOTIFS] }),
  });
}

// ─── Hooks: Tasks ───────────────────────────────────────────

export function useTasksList(filters: TaskFilters = {}) {
  return useQuery({
    queryKey: [QK_TASKS, filters],
    queryFn: () => apiGet('/v1/sistema/tareas', filters as Record<string, unknown>),
  });
}

export function useToggleTask() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, progress }: { id: string; progress: number }) =>
      apiPatch(`/v1/sistema/tareas/${id}/progreso`, { progress }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_TASKS] }),
  });
}

// ─── Hooks: Messages ────────────────────────────────────────

export function useMessagesList(filters: MessageFilters = {}) {
  return useQuery({
    queryKey: [QK_MSGS, filters],
    queryFn: () => apiGet('/v1/sistema/mensajes', filters as Record<string, unknown>),
  });
}

export function useMarkMessageRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => apiPatch(`/v1/sistema/mensajes/${id}/leido`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MSGS] }),
  });
}
