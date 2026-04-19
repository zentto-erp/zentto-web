/**
 * Tipos compartidos del módulo CRM.
 *
 * Referencia: docs/wiki/design-audits/2026-04-19-crm.md §4.3 (tokens)
 * y criterio de aceptación "Enum Priority consolidado a URGENT/HIGH/MEDIUM/LOW".
 */

/** Prioridad canónica para Lead / Activity. No usar strings libres. */
export type Priority = 'URGENT' | 'HIGH' | 'MEDIUM' | 'LOW';

/** Listado ordenado (urgente primero) — útil para selects y orden de columnas. */
export const PRIORITY_VALUES: readonly Priority[] = [
  'URGENT',
  'HIGH',
  'MEDIUM',
  'LOW',
] as const;

/** Etiquetas en español para mostrar en UI. */
export const PRIORITY_LABELS: Record<Priority, string> = {
  URGENT: 'Urgente',
  HIGH: 'Alta',
  MEDIUM: 'Media',
  LOW: 'Baja',
};

/**
 * Color MUI por prioridad — alineado con `token.color.priority` de
 * `@zentto/shared-ui`. Consumir con `priorityColor[value] ?? 'default'`.
 */
export const PRIORITY_COLORS: Record<Priority, 'error' | 'warning' | 'info'> = {
  URGENT: 'error',
  HIGH: 'error',
  MEDIUM: 'warning',
  LOW: 'info',
};

/** Type-guard para validar strings que vengan del backend. */
export function isPriority(value: unknown): value is Priority {
  return (
    typeof value === 'string' &&
    (PRIORITY_VALUES as readonly string[]).includes(value)
  );
}

/** Normaliza cualquier valor a un Priority válido (default: MEDIUM). */
export function toPriority(value: unknown): Priority {
  return isPriority(value) ? value : 'MEDIUM';
}

/** Estado del ciclo de vida de un Lead. */
export type LeadStatus = 'OPEN' | 'WON' | 'LOST' | 'ARCHIVED';

export const LEAD_STATUS_LABELS: Record<LeadStatus, string> = {
  OPEN: 'Abierto',
  WON: 'Ganado',
  LOST: 'Perdido',
  ARCHIVED: 'Archivado',
};

/** Tipo canónico de actividad — alineado con backend y ActivityTimeline. */
export type ActivityType = 'CALL' | 'EMAIL' | 'MEETING' | 'NOTE' | 'TASK';

export const ACTIVITY_TYPE_VALUES: readonly ActivityType[] = [
  'CALL',
  'EMAIL',
  'MEETING',
  'NOTE',
  'TASK',
] as const;

export const ACTIVITY_TYPE_LABELS: Record<ActivityType, string> = {
  CALL: 'Llamada',
  EMAIL: 'Correo',
  MEETING: 'Reunión',
  NOTE: 'Nota',
  TASK: 'Tarea',
};

/** Color MUI por tipo de actividad — consistente con ActivityTimeline. */
export const ACTIVITY_TYPE_COLORS: Record<
  ActivityType,
  'primary' | 'secondary' | 'success' | 'warning' | 'info'
> = {
  CALL: 'primary',
  EMAIL: 'info',
  MEETING: 'success',
  NOTE: 'warning',
  TASK: 'secondary',
};

export function isActivityType(value: unknown): value is ActivityType {
  return (
    typeof value === 'string' &&
    (ACTIVITY_TYPE_VALUES as readonly string[]).includes(value)
  );
}

/** Estado derivado de una actividad — completada vs pendiente. */
export type ActivityStatus = 'pending' | 'completed';

export const ACTIVITY_STATUS_LABELS: Record<ActivityStatus, string> = {
  pending: 'Pendiente',
  completed: 'Completada',
};
