/**
 * Stories para ZenttoRecordTable.
 *
 * Formato CSF3 (Component Story Format). Compatible con Storybook 7+ cuando
 * el monorepo integre la infraestructura, y usable como showcase manual
 * mientras tanto (los exports nombrados son componentes React renderizables).
 *
 * Variantes:
 *   1. Default           — 20 filas, columnas estándar.
 *   2. Loading           — skeleton de 10 filas.
 *   3. Empty             — estado Polaris con ilustración + CTA.
 *   4. Error             — error con botón de retry.
 *   5. WithSelection     — selección + bulk bar + density toggle + saved views.
 *
 * Issue: CRM-103 (#377).
 */
'use client';

import React, { useState } from 'react';

import {
  ZenttoRecordTable,
  type ColumnSpec,
  type SavedView,
  type BulkAction,
} from './ZenttoRecordTable';
import { ZenttoFilterPanel, type FilterFieldDef } from './ZenttoFilterPanel';
import type { DensityMode } from '../theme';

// ─── Mock data ──────────────────────────────────────────────────────

interface LeadRow extends Record<string, unknown> {
  id: number;
  LeadCode: string;
  ContactName: string;
  CompanyName: string;
  Email: string;
  Phone: string;
  StageName: string;
  EstimatedValue: number;
  Priority: 'URGENT' | 'HIGH' | 'MEDIUM' | 'LOW';
  Status: 'OPEN' | 'WON' | 'LOST';
}

const PRIORITIES: LeadRow['Priority'][] = ['URGENT', 'HIGH', 'MEDIUM', 'LOW'];
const STAGES = ['Prospecto', 'Contactado', 'Calificado', 'Propuesta', 'Negociación'];
const STATUSES: LeadRow['Status'][] = ['OPEN', 'WON', 'LOST'];

function makeMockLeads(count: number): LeadRow[] {
  return Array.from({ length: count }).map((_, i) => ({
    id: i + 1,
    LeadCode: `LEAD-${String(i + 1).padStart(4, '0')}`,
    ContactName: `Contacto ${i + 1}`,
    CompanyName: `Empresa ${((i * 37) % 20) + 1}`,
    Email: `contacto${i + 1}@empresa.com`,
    Phone: `+58 412 ${String(1000000 + i * 137).slice(-7)}`,
    StageName: STAGES[i % STAGES.length],
    EstimatedValue: 1000 + ((i * 913) % 50000),
    Priority: PRIORITIES[i % PRIORITIES.length],
    Status: STATUSES[i % STATUSES.length],
  }));
}

const LEAD_COLUMNS: ColumnSpec[] = [
  { field: 'LeadCode', header: 'Código', width: 110 },
  { field: 'ContactName', header: 'Contacto', flex: 1, minWidth: 160 },
  { field: 'CompanyName', header: 'Empresa', width: 160 },
  { field: 'Email', header: 'Email', width: 200 },
  { field: 'Phone', header: 'Teléfono', width: 140 },
  { field: 'StageName', header: 'Etapa', width: 140 },
  { field: 'EstimatedValue', header: 'Valor Est.', width: 120, type: 'number' },
  { field: 'Priority', header: 'Prioridad', width: 110 },
  { field: 'Status', header: 'Estado', width: 100 },
];

const SAVED_VIEWS: SavedView[] = [
  { id: 'all', label: 'Todos los leads', kind: 'system' },
  { id: 'urgent', label: 'Urgentes (mis leads)', description: 'Priority = URGENT', kind: 'system' },
  { id: 'q2-pipeline', label: 'Pipeline Q2', description: 'Filtrado por etapa activa', kind: 'user' },
];

const BULK_ACTIONS: BulkAction[] = [
  {
    id: 'assign',
    label: 'Asignar',
    variant: 'primary',
    onClick: (ids) => console.log('[bulk] assign', ids),
  },
  {
    id: 'export',
    label: 'Exportar CSV',
    onClick: (ids) => console.log('[bulk] export', ids),
  },
  {
    id: 'delete',
    label: 'Eliminar',
    variant: 'danger',
    onClick: (ids) => console.log('[bulk] delete', ids),
  },
];

const FILTER_FIELDS: FilterFieldDef[] = [
  {
    field: 'priority',
    label: 'Prioridad',
    type: 'select',
    options: PRIORITIES.map((p) => ({ value: p, label: p })),
  },
  {
    field: 'status',
    label: 'Estado',
    type: 'toggle',
    options: STATUSES.map((s) => ({ value: s, label: s })),
  },
];

// ─── CSF3 meta ──────────────────────────────────────────────────────

const meta = {
  title: 'Shared UI / ZenttoRecordTable',
  component: ZenttoRecordTable,
  parameters: {
    layout: 'fullscreen',
    docs: {
      description: {
        component:
          'Wrapper sobre `<zentto-grid>`. Provee saved views, bulk actions, density toggle, empty state Polaris y estados loading/error. Ver `CRM-103 (#377)`.',
      },
    },
  },
};

export default meta;

// ─── Stories ────────────────────────────────────────────────────────

/** 1. Default — 20 filas + filtros básicos. */
export const Default = () => {
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState<Record<string, string>>({});
  return (
    <div style={{ height: '80vh', display: 'flex' }}>
      <ZenttoRecordTable<LeadRow>
        recordType="lead"
        rows={makeMockLeads(20)}
        columns={LEAD_COLUMNS}
        totalCount={142}
        onOpenRecord={(id) => console.log('[open]', id)}
        filterPanel={
          <ZenttoFilterPanel
            filters={FILTER_FIELDS}
            values={filters}
            onChange={setFilters}
            searchPlaceholder="Buscar lead…"
            searchValue={search}
            onSearchChange={setSearch}
          />
        }
      />
    </div>
  );
};

/** 2. Loading — skeleton de 10 filas. */
export const Loading = () => (
  <div style={{ height: '80vh', display: 'flex' }}>
    <ZenttoRecordTable<LeadRow>
      recordType="lead"
      rows={[]}
      columns={LEAD_COLUMNS}
      loading
    />
  </div>
);

/** 3. Empty — Polaris style con CTA. */
export const Empty = () => (
  <div style={{ height: '80vh', display: 'flex' }}>
    <ZenttoRecordTable<LeadRow>
      recordType="lead"
      rows={[]}
      columns={LEAD_COLUMNS}
      emptyState={{
        title: 'Aún no tienes leads',
        description:
          'Crea tu primer lead o importa desde un CSV para empezar a hacer seguimiento de oportunidades.',
        primaryAction: {
          label: 'Crear lead',
          onClick: () => console.log('[cta] create'),
        },
        secondaryAction: {
          label: 'Importar CSV',
          onClick: () => console.log('[cta] import'),
        },
      }}
    />
  </div>
);

/** 4. Error — con retry. */
export const ErrorVariant = () => (
  <div style={{ height: '80vh', display: 'flex' }}>
    <ZenttoRecordTable<LeadRow>
      recordType="lead"
      rows={[]}
      columns={LEAD_COLUMNS}
      error="No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo."
      onRetry={() => console.log('[retry]')}
    />
  </div>
);

/** 5. WithSelection — bulk bar + density toggle + saved views. */
export const WithSelection = () => {
  const [selection, setSelection] = useState<Array<string | number>>([1, 3, 7]);
  const [density, setDensity] = useState<DensityMode>('default');
  const [viewId, setViewId] = useState<string | number | null>('urgent');

  return (
    <div style={{ height: '80vh', display: 'flex' }}>
      <ZenttoRecordTable<LeadRow>
        recordType="lead"
        rows={makeMockLeads(15)}
        columns={LEAD_COLUMNS}
        savedViews={SAVED_VIEWS}
        currentViewId={viewId}
        onSavedViewChange={setViewId}
        onSaveCurrentView={() => console.log('[save view]')}
        onManageViews={() => console.log('[manage views]')}
        selection={selection}
        onSelectionChange={setSelection}
        bulkActions={BULK_ACTIONS}
        density={density}
        onDensityChange={setDensity}
        totalCount={15}
      />
    </div>
  );
};
