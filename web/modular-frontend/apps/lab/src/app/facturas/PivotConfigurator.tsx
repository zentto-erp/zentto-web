// PivotConfigurator — Panel inline para que el usuario configure
// pivot, grouping y funciones avanzadas sin tocar codigo.
"use client";

import { useState } from "react";
import {
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Box,
  Button,
  Chip,
  FormControlLabel,
  MenuItem,
  Snackbar,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import {
  ContentCopy as CopyIcon,
  ExpandMore as ExpandIcon,
  Settings as SettingsIcon,
} from "@mui/icons-material";
import type { PivotConfig, RowGroupingConfig } from "@zentto/shared-ui";

// ─── Campos disponibles para facturas ─────────────────────
const FIELD_OPTIONS = [
  { value: "nombreCliente", label: "Cliente" },
  { value: "estado", label: "Estado" },
  { value: "tipoDoc", label: "Tipo Doc" },
  { value: "fecha", label: "Fecha" },
  { value: "numeroFactura", label: "Numero" },
  { value: "totalFactura", label: "Total" },
];

const NUMERIC_FIELDS = [
  { value: "totalFactura", label: "Total Factura" },
];

const AGG_OPTIONS = [
  { value: "sum", label: "Suma" },
  { value: "avg", label: "Promedio" },
  { value: "count", label: "Conteo" },
  { value: "min", label: "Minimo" },
  { value: "max", label: "Maximo" },
];

export type LabConfig = {
  // Pivot
  pivotEnabled: boolean;
  pivotRowField: string;
  pivotColField: string;
  pivotValueField: string;
  pivotAgg: string;
  pivotGrandTotals: boolean;
  pivotRowTotals: boolean;
  // Grouping
  groupingEnabled: boolean;
  groupField: string;
  groupSubtotals: boolean;
  groupSort: "asc" | "desc" | "";
  // Features
  headerFilters: boolean;
  showTotals: boolean;
  clipboard: boolean;
  columnGroups: boolean;
  pinning: boolean;
};

export const DEFAULT_CONFIG: LabConfig = {
  pivotEnabled: true,
  pivotRowField: "nombreCliente",
  pivotColField: "estado",
  pivotValueField: "totalFactura",
  pivotAgg: "sum",
  pivotGrandTotals: true,
  pivotRowTotals: true,
  groupingEnabled: true,
  groupField: "estado",
  groupSubtotals: true,
  groupSort: "asc",
  headerFilters: true,
  showTotals: true,
  clipboard: true,
  columnGroups: true,
  pinning: true,
};

export function buildPivotConfig(cfg: LabConfig): PivotConfig | undefined {
  if (!cfg.pivotEnabled) return undefined;
  return {
    rowField: cfg.pivotRowField,
    columnField: cfg.pivotColField,
    valueField: cfg.pivotValueField,
    aggregation: cfg.pivotAgg as any,
    rowFieldHeader: FIELD_OPTIONS.find((f) => f.value === cfg.pivotRowField)?.label || cfg.pivotRowField,
    showGrandTotals: cfg.pivotGrandTotals,
    showRowTotals: cfg.pivotRowTotals,
    valueFormatter: (v) =>
      new Intl.NumberFormat("es-VE", { minimumFractionDigits: 2 }).format(v),
  };
}

export function buildGroupingConfig(cfg: LabConfig): RowGroupingConfig | undefined {
  if (!cfg.groupingEnabled || !cfg.groupField) return undefined;
  return {
    field: cfg.groupField,
    showSubtotals: cfg.groupSubtotals,
    sortGroups: cfg.groupSort ? (cfg.groupSort as "asc" | "desc") : null,
  };
}

function generateSnippet(cfg: LabConfig): string {
  const lines: string[] = [];
  if (cfg.clipboard) lines.push("enableClipboard");
  if (cfg.headerFilters) lines.push("enableHeaderFilters");
  if (cfg.showTotals) lines.push('showTotals\ntotalsLabel="Totales"');
  if (cfg.groupingEnabled) {
    lines.push("enableGrouping");
    lines.push(`rowGroupingConfig={{
  field: "${cfg.groupField}",
  showSubtotals: ${cfg.groupSubtotals},
  sortGroups: ${cfg.groupSort ? `"${cfg.groupSort}"` : "null"},
}}`);
  }
  if (cfg.pivotEnabled) {
    lines.push("enablePivot");
    lines.push(`pivotConfig={{
  rowField: "${cfg.pivotRowField}",
  columnField: "${cfg.pivotColField}",
  valueField: "${cfg.pivotValueField}",
  aggregation: "${cfg.pivotAgg}",
  rowFieldHeader: "${FIELD_OPTIONS.find((f) => f.value === cfg.pivotRowField)?.label || cfg.pivotRowField}",
  showGrandTotals: ${cfg.pivotGrandTotals},
  showRowTotals: ${cfg.pivotRowTotals},
}}`);
  }
  if (cfg.pinning) lines.push('pinnedColumns={{ left: ["codigo"], right: ["actions"] }}');
  return `<ZenttoDataGrid\n  ${lines.join("\n  ")}\n/>`;
}

export function PivotConfigurator({
  config,
  onChange,
}: {
  config: LabConfig;
  onChange: (c: LabConfig) => void;
}) {
  const set = (partial: Partial<LabConfig>) => onChange({ ...config, ...partial });
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const snippet = generateSnippet(config);
    navigator.clipboard.writeText(snippet).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <Accordion
      defaultExpanded={false}
      sx={{ mb: 1.5, "&:before": { display: "none" } }}
      variant="outlined"
    >
      <AccordionSummary expandIcon={<ExpandIcon />}>
        <Stack direction="row" spacing={1} alignItems="center">
          <SettingsIcon fontSize="small" color="primary" />
          <Typography variant="subtitle2">Configurar ZenttoDataGrid</Typography>
          <Chip label="LAB" size="small" color="warning" />
        </Stack>
      </AccordionSummary>
      <AccordionDetails>
        <Stack spacing={3}>
          {/* ─── PIVOT ──────────────────────── */}
          <Box>
            <FormControlLabel
              control={<Switch checked={config.pivotEnabled} onChange={(e) => set({ pivotEnabled: e.target.checked })} />}
              label={<Typography variant="subtitle2" fontWeight={600}>Tabla Pivot</Typography>}
            />
            {config.pivotEnabled && (
              <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap sx={{ mt: 1 }}>
                <TextField select label="Filas (eje Y)" value={config.pivotRowField} onChange={(e) => set({ pivotRowField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                  {FIELD_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                </TextField>
                <TextField select label="Columnas (eje X)" value={config.pivotColField} onChange={(e) => set({ pivotColField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                  {FIELD_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                </TextField>
                <TextField select label="Valor" value={config.pivotValueField} onChange={(e) => set({ pivotValueField: e.target.value })} size="small" sx={{ minWidth: 130 }}>
                  {NUMERIC_FIELDS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                </TextField>
                <TextField select label="Agregacion" value={config.pivotAgg} onChange={(e) => set({ pivotAgg: e.target.value })} size="small" sx={{ minWidth: 120 }}>
                  {AGG_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                </TextField>
                <FormControlLabel control={<Switch checked={config.pivotGrandTotals} onChange={(e) => set({ pivotGrandTotals: e.target.checked })} size="small" />} label="Gran Total" />
                <FormControlLabel control={<Switch checked={config.pivotRowTotals} onChange={(e) => set({ pivotRowTotals: e.target.checked })} size="small" />} label="Total por fila" />
              </Stack>
            )}
          </Box>

          {/* ─── GROUPING ──────────────────────── */}
          <Box>
            <FormControlLabel
              control={<Switch checked={config.groupingEnabled} onChange={(e) => set({ groupingEnabled: e.target.checked })} />}
              label={<Typography variant="subtitle2" fontWeight={600}>Agrupar filas</Typography>}
            />
            {config.groupingEnabled && (
              <Stack direction="row" spacing={1.5} sx={{ mt: 1 }}>
                <TextField select label="Agrupar por" value={config.groupField} onChange={(e) => set({ groupField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                  {FIELD_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                </TextField>
                <TextField select label="Ordenar grupos" value={config.groupSort} onChange={(e) => set({ groupSort: e.target.value as any })} size="small" sx={{ minWidth: 120 }}>
                  <MenuItem value="">Sin orden</MenuItem>
                  <MenuItem value="asc">A → Z</MenuItem>
                  <MenuItem value="desc">Z → A</MenuItem>
                </TextField>
                <FormControlLabel control={<Switch checked={config.groupSubtotals} onChange={(e) => set({ groupSubtotals: e.target.checked })} size="small" />} label="Subtotales" />
              </Stack>
            )}
          </Box>

          {/* ─── FEATURES ──────────────────────── */}
          <Box>
            <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>Funciones</Typography>
            <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap>
              <FormControlLabel control={<Switch checked={config.headerFilters} onChange={(e) => set({ headerFilters: e.target.checked })} size="small" />} label="Filtros en headers" />
              <FormControlLabel control={<Switch checked={config.showTotals} onChange={(e) => set({ showTotals: e.target.checked })} size="small" />} label="Fila de totales" />
              <FormControlLabel control={<Switch checked={config.clipboard} onChange={(e) => set({ clipboard: e.target.checked })} size="small" />} label="Clipboard (Ctrl+C)" />
              <FormControlLabel control={<Switch checked={config.columnGroups} onChange={(e) => set({ columnGroups: e.target.checked })} size="small" />} label="Grupos de columnas" />
              <FormControlLabel control={<Switch checked={config.pinning} onChange={(e) => set({ pinning: e.target.checked })} size="small" />} label="Columnas fijas" />
            </Stack>
          </Box>
          {/* ─── CODIGO GENERADO ──────────────────────── */}
          <Box>
            <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
              <Typography variant="subtitle2" fontWeight={600}>Codigo JSX generado</Typography>
              <Button size="small" startIcon={<CopyIcon />} onClick={handleCopy} variant="outlined">
                Copiar
              </Button>
            </Stack>
            <Box
              component="pre"
              sx={{
                p: 1.5,
                bgcolor: "#1e1e1e",
                color: "#d4d4d4",
                borderRadius: 1,
                fontSize: "0.8rem",
                overflow: "auto",
                maxHeight: 250,
                fontFamily: "Consolas, Monaco, monospace",
              }}
            >
              {generateSnippet(config)}
            </Box>
          </Box>
        </Stack>
        <Snackbar open={copied} message="Configuracion copiada al portapapeles" autoHideDuration={2000} />
      </AccordionDetails>
    </Accordion>
  );
}
