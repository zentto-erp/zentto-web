// NativeGridConfigurator — Panel lateral para configurar <zentto-grid> en tiempo real.
// Permite cambiar props, theme, CSS custom properties, density, y features.
"use client";

import React, { useState } from "react";
import {
  Box,
  Button,
  Chip,
  Divider,
  FormControlLabel,
  IconButton,
  MenuItem,
  Slider,
  Stack,
  Switch,
  Tab,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  Settings as SettingsIcon,
  Palette as PaletteIcon,
  Tune as TuneIcon,
  Code as CodeIcon,
  PivotTableChart as PivotIcon,
  TableRows as GroupIcon,
  ChevronLeft as CollapseIcon,
  ContentCopy as CopyIcon,
} from "@mui/icons-material";

// ─── Config State ──────────────────────────────────────

export interface NativeGridConfig {
  // Features
  showTotals: boolean;
  enableHeaderFilters: boolean;
  enableClipboard: boolean;
  enableFind: boolean;
  enableQuickSearch: boolean;
  enableContextMenu: boolean;
  enableStatusBar: boolean;
  enableGrouping: boolean;
  enableMasterDetail: boolean;
  enableGroupDropZone: boolean;
  enablePivot: boolean;
  pivotRowField: string;
  pivotColField: string;
  pivotValueField: string;
  pivotAggregation: string;
  pivotGrandTotals: boolean;
  enableImport: boolean;
  groupField: string;
  groupSort: string;
  groupSubtotals: boolean;
  // Appearance
  theme: "light" | "dark" | "zentto";
  density: "compact" | "standard" | "comfortable";
  locale: "es" | "en";
  // CSS Custom Properties
  primaryColor: string;
  headerBg: string;
  borderColor: string;
  rowAltBg: string;
  fontFamily: string;
  fontSize: string;
  borderRadius: number;
}

export const DEFAULT_CONFIG: NativeGridConfig = {
  showTotals: true,
  enableHeaderFilters: true,
  enableClipboard: true,
  enableFind: true,
  enableQuickSearch: true,
  enableContextMenu: true,
  enableStatusBar: true,
  enableGrouping: false,
  enableMasterDetail: false,
  enableGroupDropZone: false,
  enablePivot: false,
  pivotRowField: "",
  pivotColField: "",
  pivotValueField: "",
  pivotAggregation: "sum",
  pivotGrandTotals: true,
  enableImport: false,
  groupField: "",
  groupSort: "asc",
  groupSubtotals: true,
  theme: "light",
  density: "comfortable",
  locale: "es",
  primaryColor: "#e67e22",
  headerBg: "#f7f8fa",
  borderColor: "rgba(0,0,0,0.1)",
  rowAltBg: "#fafbfc",
  fontFamily: "Inter, system-ui, sans-serif",
  fontSize: "13.5px",
  borderRadius: 10,
};

// ─── Configurator Component ──────────────────────────────

export function NativeGridConfigurator({
  config,
  onChange,
  groupableFields = [],
  pivotableFields = [],
  open: controlledOpen,
  onToggle,
  children,
}: {
  config: NativeGridConfig;
  onChange: (c: NativeGridConfig) => void;
  groupableFields?: { value: string; label: string }[];
  pivotableFields?: { value: string; label: string; type?: string }[];
  open?: boolean;
  onToggle?: (open: boolean) => void;
  children: React.ReactNode;
}) {
  const [internalOpen, setInternalOpen] = useState(false);
  const open = controlledOpen ?? internalOpen;
  const setOpen = (v: boolean) => { onToggle ? onToggle(v) : setInternalOpen(v); };
  const [tab, setTab] = useState(0);
  const set = (partial: Partial<NativeGridConfig>) => onChange({ ...config, ...partial });

  // Generate CSS custom properties string
  const cssVars: Record<string, string> = {
    "--zg-primary": config.primaryColor,
    "--zg-header-bg": config.headerBg,
    "--zg-border": config.borderColor,
    "--zg-row-stripe": config.rowAltBg,
    "--zg-font-family": config.fontFamily,
    "--zg-font-size": config.fontSize,
  };

  const cssVarsString = Object.entries(cssVars)
    .map(([k, v]) => `${k}: ${v};`)
    .join("\n  ");

  return (
    <Box sx={{ display: "flex", flex: 1, minHeight: 0, gap: 0 }}>
      {/* Grid with CSS vars applied */}
      <Box
        sx={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}
        style={cssVars as any}
      >
        {children}
      </Box>

      {/* Sidebar — controlled by grid settings button */}
      {open && (
        <Box
          sx={{
            width: 280,
            minWidth: 280,
            borderLeft: "1px solid #e0e0e0",
            bgcolor: "#fafafa",
            display: "flex",
            flexDirection: "column",
            overflow: "hidden",
          }}
        >
          {/* Header */}
          <Box sx={{ display: "flex", alignItems: "center", px: 1, py: 0.5, bgcolor: "#f0f0f0", borderBottom: "1px solid #e0e0e0" }}>
            <IconButton size="small" onClick={() => setOpen(false)}>
              <CollapseIcon fontSize="small" />
            </IconButton>
            <Typography variant="caption" fontWeight={600} sx={{ ml: 0.5 }}>
              Configurador
            </Typography>
          </Box>

          {/* Tabs */}
          <Tabs
            value={tab}
            onChange={(_, v) => setTab(v)}
            variant="fullWidth"
            sx={{ minHeight: 36, borderBottom: "1px solid #e0e0e0", "& .MuiTab-root": { minHeight: 36, py: 0.5 } }}
          >
            <Tab icon={<TuneIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} title="Features" />
            <Tab icon={<PivotIcon sx={{ fontSize: 18, color: config.enablePivot ? '#f59e0b' : undefined }} />} sx={{ minWidth: 0 }} title="Pivot" />
            <Tab icon={<GroupIcon sx={{ fontSize: 18, color: config.enableGrouping ? '#f59e0b' : undefined }} />} sx={{ minWidth: 0 }} title="Grupos" />
            <Tab icon={<PaletteIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} title="Apariencia" />
            <Tab icon={<CodeIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} title="Codigo" />
          </Tabs>

          {/* Content — compact selects */}
          <Box sx={{
            flex: 1, overflow: "auto", p: 1.5,
            '& .MuiInputBase-root': { fontSize: 13, height: 34 },
            '& .MuiInputLabel-root': { fontSize: 12 },
            '& .MuiFormHelperText-root': { fontSize: 10, mt: 0.25, lineHeight: 1.2 },
            '& .MuiMenuItem-root': { fontSize: 13, minHeight: 32 },
          }}>
            {tab === 0 && (
              <FeaturesPanel config={config} onChange={set} groupableFields={groupableFields} />
            )}
            {tab === 1 && (
              <PivotPanel config={config} onChange={set} pivotableFields={pivotableFields} />
            )}
            {tab === 2 && (
              <GroupsPanel config={config} onChange={set} groupableFields={groupableFields} />
            )}
            {tab === 3 && (
              <ThemePanel config={config} onChange={set} />
            )}
            {tab === 4 && (
              <CodePanel config={config} cssVars={cssVarsString} />
            )}
          </Box>
        </Box>
      )}
    </Box>
  );
}

// ─── Features Tab ──────────────────────────────────────

function FeaturesPanel({
  config, onChange, groupableFields,
}: {
  config: NativeGridConfig;
  onChange: (p: Partial<NativeGridConfig>) => void;
  groupableFields: { value: string; label: string }[];
}) {
  return (
    <Stack spacing={1}>
      <Typography variant="caption" fontWeight={600} color="text.secondary">Features</Typography>
      <FormControlLabel control={<Switch checked={config.showTotals} onChange={(e) => onChange({ showTotals: e.target.checked })} size="small" />} label={<Typography variant="body2">Fila de totales</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableHeaderFilters} onChange={(e) => onChange({ enableHeaderFilters: e.target.checked })} size="small" />} label={<Typography variant="body2">Filtros en headers</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableClipboard} onChange={(e) => onChange({ enableClipboard: e.target.checked })} size="small" />} label={<Typography variant="body2">Clipboard</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableFind} onChange={(e) => onChange({ enableFind: e.target.checked })} size="small" />} label={<Typography variant="body2">Find (Ctrl+F)</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableContextMenu} onChange={(e) => onChange({ enableContextMenu: e.target.checked })} size="small" />} label={<Typography variant="body2">Menu contextual</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableStatusBar} onChange={(e) => onChange({ enableStatusBar: e.target.checked })} size="small" />} label={<Typography variant="body2">Status bar</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableMasterDetail} onChange={(e) => onChange({ enableMasterDetail: e.target.checked })} size="small" />} label={<Typography variant="body2">Master-detail</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableImport} onChange={(e) => onChange({ enableImport: e.target.checked })} size="small" />} label={<Typography variant="body2">Importar (Excel/CSV/JSON)</Typography>} />
      <FormControlLabel control={<Switch checked={config.enableQuickSearch} onChange={(e) => onChange({ enableQuickSearch: e.target.checked })} size="small" />} label={<Typography variant="body2">Busqueda rapida</Typography>} />

      <Divider />
      <Typography variant="caption" fontWeight={600} color="text.secondary">Apariencia</Typography>
      <TextField select label="Tema" value={config.theme} onChange={(e) => onChange({ theme: e.target.value as any })} size="small" fullWidth>
        <MenuItem value="light">Light</MenuItem>
        <MenuItem value="dark">Dark</MenuItem>
        <MenuItem value="zentto">Zentto</MenuItem>
      </TextField>
      <TextField select label="Densidad" value={config.density} onChange={(e) => onChange({ density: e.target.value as any })} size="small" fullWidth>
        <MenuItem value="compact">Compacto</MenuItem>
        <MenuItem value="standard">Normal</MenuItem>
        <MenuItem value="comfortable">Amplio</MenuItem>
      </TextField>
      <TextField select label="Idioma" value={config.locale} onChange={(e) => onChange({ locale: e.target.value as any })} size="small" fullWidth>
        <MenuItem value="es">Español</MenuItem>
        <MenuItem value="en">English</MenuItem>
      </TextField>
    </Stack>
  );
}

// ─── Theme Tab ──────────────────────────────────────

// ─── Pivot Tab ──────────────────────────────────────

function PivotPanel({
  config, onChange, pivotableFields,
}: {
  config: NativeGridConfig;
  onChange: (p: Partial<NativeGridConfig>) => void;
  pivotableFields: { value: string; label: string; type?: string }[];
}) {
  const AGG_LABELS: Record<string, string> = { sum: 'Suma', avg: 'Promedio', count: 'Conteo', min: 'Min', max: 'Max' };
  const textFields = pivotableFields.filter(f => f.type !== 'number');
  const numFields = pivotableFields.filter(f => f.type === 'number');

  return (
    <Stack spacing={1.5}>
      <Typography variant="caption" fontWeight={700} color="text.secondary">Pivot</Typography>

      <FormControlLabel
        control={<Switch checked={config.enablePivot} onChange={(e) => onChange({ enablePivot: e.target.checked })} size="small" />}
        label={<Typography variant="body2" fontWeight={600}>Pivot Mode</Typography>}
      />

      {config.enablePivot && (
        <>
          <TextField select label="Filas (eje Y)" value={config.pivotRowField} onChange={(e) => onChange({ pivotRowField: e.target.value })} size="small" fullWidth
            helperText="Cada valor unico sera una fila">
            {textFields.map((f) => <MenuItem key={f.value} value={f.value}>{f.label}</MenuItem>)}
          </TextField>

          <TextField select label="Columnas (eje X)" value={config.pivotColField} onChange={(e) => onChange({ pivotColField: e.target.value })} size="small" fullWidth
            helperText="Cada valor unico genera una columna">
            {textFields.map((f) => <MenuItem key={f.value} value={f.value}>{f.label}</MenuItem>)}
          </TextField>

          <Divider />
          <Typography variant="caption" fontWeight={600} color="text.secondary">Valores</Typography>

          <Box sx={{ display: 'flex', gap: 1 }}>
            <TextField select label="Campo" value={config.pivotValueField} onChange={(e) => onChange({ pivotValueField: e.target.value })} size="small" sx={{ flex: 1 }}>
              {numFields.map((f) => <MenuItem key={f.value} value={f.value}>{f.label}</MenuItem>)}
            </TextField>
            <TextField select label="Fn" value={config.pivotAggregation} onChange={(e) => onChange({ pivotAggregation: e.target.value })} size="small" sx={{ width: 100 }}>
              <MenuItem value="sum">Suma</MenuItem>
              <MenuItem value="avg">Promedio</MenuItem>
              <MenuItem value="count">Conteo</MenuItem>
              <MenuItem value="min">Min</MenuItem>
              <MenuItem value="max">Max</MenuItem>
            </TextField>
          </Box>

          {config.pivotValueField && (
            <Chip
              icon={<PivotIcon sx={{ fontSize: 14 }} />}
              label={`${AGG_LABELS[config.pivotAggregation] || config.pivotAggregation}(${config.pivotValueField})`}
              color="warning"
              size="small"
              onDelete={() => onChange({ pivotValueField: '' })}
              sx={{ alignSelf: 'flex-start' }}
            />
          )}

          <Divider />
          <FormControlLabel control={<Switch checked={config.pivotGrandTotals} onChange={(e) => onChange({ pivotGrandTotals: e.target.checked })} size="small" />} label={<Typography variant="body2">Gran Total</Typography>} />
          <FormControlLabel control={<Switch checked={true} size="small" disabled />} label={<Typography variant="body2">Total por fila</Typography>} />
        </>
      )}

      {!config.enablePivot && (
        <Typography variant="caption" color="text.secondary">
          Activa Pivot Mode para transformar los datos en una tabla dinamica con filas, columnas y valores agregados.
        </Typography>
      )}
    </Stack>
  );
}

// ─── Groups Tab ──────────────────────────────────────

function GroupsPanel({
  config, onChange, groupableFields,
}: {
  config: NativeGridConfig;
  onChange: (p: Partial<NativeGridConfig>) => void;
  groupableFields: { value: string; label: string }[];
}) {
  return (
    <Stack spacing={1.5}>
      <Typography variant="caption" fontWeight={700} color="text.secondary">Grupos</Typography>

      <FormControlLabel
        control={<Switch checked={config.enableGrouping} onChange={(e) => onChange({ enableGrouping: e.target.checked })} size="small" />}
        label={<Typography variant="body2" fontWeight={600}>Row Groups</Typography>}
      />

      {config.enableGrouping && (
        <>
          <Typography variant="caption" color="text.secondary">Agrupar filas por campo</Typography>

          <TextField select label="Agrupar por" value={config.groupField} onChange={(e) => onChange({ groupField: e.target.value })} size="small" fullWidth>
            {groupableFields.map((f) => <MenuItem key={f.value} value={f.value}>{f.label}</MenuItem>)}
          </TextField>

          {config.groupField && (
            <Chip
              icon={<GroupIcon sx={{ fontSize: 14 }} />}
              label={groupableFields.find(f => f.value === config.groupField)?.label || config.groupField}
              color="warning"
              size="small"
              onDelete={() => onChange({ groupField: '', enableGrouping: false })}
              sx={{ alignSelf: 'flex-start' }}
            />
          )}

          <TextField select label="Ordenar" value={config.groupSort} onChange={(e) => onChange({ groupSort: e.target.value })} size="small" fullWidth>
            <MenuItem value="asc">A → Z</MenuItem>
            <MenuItem value="desc">Z → A</MenuItem>
          </TextField>

          <FormControlLabel control={<Switch checked={config.groupSubtotals} onChange={(e) => onChange({ groupSubtotals: e.target.checked })} size="small" />} label={<Typography variant="body2">Subtotales</Typography>} />

          <Divider />
          <FormControlLabel control={<Switch checked={config.enableGroupDropZone} onChange={(e) => onChange({ enableGroupDropZone: e.target.checked })} size="small" />} label={<Typography variant="body2">Drop zone (drag headers)</Typography>} />
        </>
      )}

      {!config.enableGrouping && (
        <Typography variant="caption" color="text.secondary">
          Activa Row Groups para agrupar filas por un campo y ver subtotales.
        </Typography>
      )}
    </Stack>
  );
}

// ─── Theme Tab ──────────────────────────────────────

function ThemePanel({ config, onChange }: { config: NativeGridConfig; onChange: (p: Partial<NativeGridConfig>) => void }) {
  return (
    <Stack spacing={1.5}>
      <Typography variant="caption" fontWeight={600} color="text.secondary">CSS Custom Properties</Typography>
      <Typography variant="caption" color="text.secondary">
        Cambia estos valores para personalizar el grid. Se aplican via CSS variables.
      </Typography>

      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        <input type="color" value={config.primaryColor} onChange={(e) => onChange({ primaryColor: e.target.value })} style={{ width: 28, height: 28, border: "none", cursor: "pointer" }} />
        <Typography variant="body2" sx={{ flex: 1 }}>Primary</Typography>
        <Typography variant="caption" color="text.secondary">{config.primaryColor}</Typography>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        <input type="color" value={config.headerBg} onChange={(e) => onChange({ headerBg: e.target.value })} style={{ width: 28, height: 28, border: "none", cursor: "pointer" }} />
        <Typography variant="body2" sx={{ flex: 1 }}>Header BG</Typography>
        <Typography variant="caption" color="text.secondary">{config.headerBg}</Typography>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        <input type="color" value={config.borderColor} onChange={(e) => onChange({ borderColor: e.target.value })} style={{ width: 28, height: 28, border: "none", cursor: "pointer" }} />
        <Typography variant="body2" sx={{ flex: 1 }}>Borders</Typography>
        <Typography variant="caption" color="text.secondary">{config.borderColor}</Typography>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        <input type="color" value={config.rowAltBg} onChange={(e) => onChange({ rowAltBg: e.target.value })} style={{ width: 28, height: 28, border: "none", cursor: "pointer" }} />
        <Typography variant="body2" sx={{ flex: 1 }}>Row alternada</Typography>
        <Typography variant="caption" color="text.secondary">{config.rowAltBg}</Typography>
      </Box>

      <Divider />
      <Typography variant="caption" fontWeight={600} color="text.secondary">Tipografia</Typography>

      <TextField label="Font family" value={config.fontFamily} onChange={(e) => onChange({ fontFamily: e.target.value })} size="small" fullWidth />
      <TextField label="Font size" value={config.fontSize} onChange={(e) => onChange({ fontSize: e.target.value })} size="small" fullWidth />

      <Typography variant="caption" fontWeight={600} color="text.secondary">Border radius</Typography>
      <Slider
        value={config.borderRadius}
        onChange={(_, v) => onChange({ borderRadius: v as number })}
        min={0} max={20} step={1}
        valueLabelDisplay="auto"
        size="small"
      />
    </Stack>
  );
}

// ─── Code Tab ──────────────────────────────────────

function CodePanel({ config, cssVars }: { config: NativeGridConfig; cssVars: string }) {
  const [copied, setCopied] = useState(false);
  const [fw, setFw] = useState<'react' | 'html' | 'vue'>('react');

  const boolProps = [
    config.showTotals && 'showTotals',
    config.enableHeaderFilters && 'enableHeaderFilters',
    config.enableClipboard && 'enableClipboard',
    config.enableFind && 'enableFind',
    config.enableQuickSearch && 'enableQuickSearch',
    config.enableContextMenu && 'enableContextMenu',
    config.enableStatusBar && 'enableStatusBar',
    (config as any).enableRowSelection && 'enableRowSelection',
    config.enableGrouping && 'enableGrouping',
    config.enableMasterDetail && 'enableMasterDetail',
    config.enableImport && 'enableImport',
    config.enableGroupDropZone && 'enableGroupDropZone',
    config.enablePivot && 'enablePivot',
  ].filter(Boolean);

  const reactCode = `/**
 * ZenttoDataGrid — React (Web Component)
 * npm install @zentto/datagrid @zentto/datagrid-core
 */
"use client";
import { useEffect, useRef } from "react";
import type { ColumnDef } from "@zentto/datagrid-core";

// 1. Registrar el web component (una vez)
if (typeof window !== "undefined") {
  import("@zentto/datagrid");
}

const columns: ColumnDef[] = [
  { field: "name", header: "Nombre", sortable: true },
  { field: "total", header: "Total", type: "number", currency: "USD", aggregation: "sum" },
  { field: "status", header: "Estado", statusColors: { Active: "success", Inactive: "error" } },
];

const rows = [
  { id: 1, name: "Item A", total: 100, status: "Active" },
  { id: 2, name: "Item B", total: 250, status: "Inactive" },
];

export default function MyGrid() {
  const ref = useRef<any>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.columns = columns;
    el.rows = rows;
    el.theme = "${config.theme}";
    el.density = "${config.density}";
    el.locale = "${config.locale}";${config.enableGrouping ? `\n    el.groupField = "${config.groupField}";` : ''}${config.enablePivot && config.pivotRowField ? `\n    el.pivotConfig = { rowField: "${config.pivotRowField}", columnField: "${config.pivotColField}", valueField: "${config.pivotValueField}", aggregation: "${config.pivotAggregation}", showGrandTotals: ${config.pivotGrandTotals} };` : ''}
  }, []);

  return (
    <zentto-grid
      ref={ref}
      ${boolProps.map(p => `${p?.replace(/([A-Z])/g, '-$1').toLowerCase()}`).join('\n      ')}
      default-currency="USD"
      height="500px"
      style={{ ${Object.entries({ '--zg-primary': config.primaryColor, '--zg-font-family': config.fontFamily }).map(([k, v]) => `'${k}': '${v}'`).join(', ')} }}
    />
  );
}`;

  const htmlCode = `<!--
  ZenttoDataGrid — HTML puro (Web Component)
  npm install @zentto/datagrid
-->
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>ZenttoDataGrid</title>
  <style>
    zentto-grid {
      ${cssVars}
    }
  </style>
</head>
<body>
  <zentto-grid
    ${boolProps.map(p => `${p?.replace(/([A-Z])/g, '-$1').toLowerCase()}`).join('\n    ')}
    theme="${config.theme}"
    density="${config.density}"
    locale="${config.locale}"
    default-currency="USD"
    height="500px"
  ></zentto-grid>

  <script type="module">
    import '@zentto/datagrid';

    const grid = document.querySelector('zentto-grid');
    grid.columns = [
      { field: 'name', header: 'Nombre', sortable: true },
      { field: 'total', header: 'Total', type: 'number', currency: 'USD' },
    ];
    grid.rows = [
      { id: 1, name: 'Item A', total: 100 },
      { id: 2, name: 'Item B', total: 250 },
    ];
  </script>
</body>
</html>`;

  const vueCode = `<!--
  ZenttoDataGrid — Vue 3 (Web Component)
  npm install @zentto/datagrid @zentto/datagrid-core
-->
<script setup lang="ts">
import { ref, onMounted } from 'vue';
// import('@zentto/datagrid') — se registra dinamicamente en useEffect
import type { ColumnDef } from '@zentto/datagrid-core';

const gridRef = ref<any>(null);

const columns: ColumnDef[] = [
  { field: 'name', header: 'Nombre', sortable: true },
  { field: 'total', header: 'Total', type: 'number', currency: 'USD', aggregation: 'sum' },
];

const rows = [
  { id: 1, name: 'Item A', total: 100 },
  { id: 2, name: 'Item B', total: 250 },
];

onMounted(() => {
  const el = gridRef.value;
  if (!el) return;
  el.columns = columns;
  el.rows = rows;
  el.theme = '${config.theme}';
  el.density = '${config.density}';
  el.locale = '${config.locale}';
});
</script>

<template>
  <zentto-grid
    ref="gridRef"
    ${boolProps.map(p => `${p?.replace(/([A-Z])/g, '-$1').toLowerCase()}`).join('\n    ')}
    default-currency="USD"
    height="500px"
    :style="{ ${Object.entries({ '--zg-primary': config.primaryColor }).map(([k, v]) => `'${k}': '${v}'`).join(', ')} }"
  />
</template>`;

  const codes = { react: reactCode, html: htmlCode, vue: vueCode };
  const labels = { react: 'React / Next.js', html: 'HTML puro', vue: 'Vue 3' };
  const activeCode = codes[fw];

  return (
    <Stack spacing={1}>
      <Box sx={{ display: "flex", gap: 0.5 }}>
        {(['react', 'html', 'vue'] as const).map(f => (
          <Chip key={f} label={labels[f]} size="small" variant={fw === f ? 'filled' : 'outlined'} color={fw === f ? 'warning' : 'default'}
            onClick={() => setFw(f)} sx={{ cursor: 'pointer', fontSize: 11 }} />
        ))}
      </Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <Typography variant="caption" fontWeight={600}>{labels[fw]}</Typography>
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          {copied && <Chip label="Copiado!" color="success" size="small" sx={{ height: 22 }} />}
          <Tooltip title="Copiar">
            <IconButton size="small" onClick={() => {
              navigator.clipboard.writeText(activeCode);
              setCopied(true);
              setTimeout(() => setCopied(false), 2000);
            }}>
              <CopyIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
      <Box
        component="pre"
        sx={{
          m: 0, p: 1.5, bgcolor: "#1e1e1e", color: "#d4d4d4",
          fontSize: 11, fontFamily: "'Cascadia Code', 'Fira Code', Consolas, monospace",
          overflow: "auto", maxHeight: 500, borderRadius: 1.5,
          whiteSpace: "pre-wrap", wordBreak: "break-word",
          lineHeight: 1.5, letterSpacing: '0.01em',
        }}
      >
        {activeCode}
      </Box>
    </Stack>
  );
}
