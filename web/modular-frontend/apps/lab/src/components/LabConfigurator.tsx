// LabConfigurator — Configurador generico + CodePreview para cualquier tabla del lab.
// Se le pasan los campos disponibles y genera UI + codigo.
"use client";

import { useState } from "react";
import {
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Box,
  Button,
  Chip,
  Collapse,
  FormControlLabel,
  IconButton,
  MenuItem,
  Snackbar,
  Stack,
  Switch,
  Tab,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  Code as CodeIcon,
  ContentCopy as CopyIcon,
  ExpandMore as ExpandIcon,
  Settings as SettingsIcon,
  VisibilityOff as HideIcon,
} from "@mui/icons-material";
import type { PivotConfig, RowGroupingConfig } from "@zentto/shared-ui";

// ─── Types ──────────────────────────────────────────

export type FieldOption = { value: string; label: string };

export type LabConfig = {
  pivotEnabled: boolean;
  pivotRowField: string;
  pivotColField: string;
  pivotValueField: string;
  pivotAgg: string;
  pivotGrandTotals: boolean;
  pivotRowTotals: boolean;
  groupingEnabled: boolean;
  groupField: string;
  groupSubtotals: boolean;
  groupSort: "asc" | "desc" | "";
  headerFilters: boolean;
  showTotals: boolean;
  clipboard: boolean;
  columnGroups: boolean;
  pinning: boolean;
  pinnedLeft: string[];
  pinnedRight: string[];
};

const AGG_OPTIONS = [
  { value: "sum", label: "Suma" },
  { value: "avg", label: "Promedio" },
  { value: "count", label: "Conteo" },
  { value: "min", label: "Minimo" },
  { value: "max", label: "Maximo" },
];

// ─── Builders ──────────────────────────────────────────

export function buildPivotConfig(cfg: LabConfig, fields: FieldOption[]): PivotConfig | undefined {
  if (!cfg.pivotEnabled) return undefined;
  return {
    rowField: cfg.pivotRowField,
    columnField: cfg.pivotColField,
    valueField: cfg.pivotValueField,
    aggregation: cfg.pivotAgg as any,
    rowFieldHeader: fields.find((f) => f.value === cfg.pivotRowField)?.label || cfg.pivotRowField,
    showGrandTotals: cfg.pivotGrandTotals,
    showRowTotals: cfg.pivotRowTotals,
    valueFormatter: (v) => new Intl.NumberFormat("es-VE", { minimumFractionDigits: 2 }).format(v),
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

// ─── Code Generator ──────────────────────────────────────

function generateCode(cfg: LabConfig, fields: FieldOption[], numericFields: FieldOption[], mode: "full" | "props"): string {
  const props: string[] = [];

  if (cfg.clipboard) props.push("enableClipboard");
  if (cfg.headerFilters) props.push("enableHeaderFilters");
  if (cfg.showTotals) {
    props.push("showTotals");
    props.push('totalsLabel="Totales"');
  }

  if (cfg.groupingEnabled) {
    props.push("enableGrouping");
    props.push(`rowGroupingConfig={{
  field: "${cfg.groupField}",
  showSubtotals: ${cfg.groupSubtotals},
  sortGroups: ${cfg.groupSort ? `"${cfg.groupSort}"` : "null"},
}}`);
  }

  if (cfg.pivotEnabled) {
    props.push("enablePivot");
    props.push(`pivotConfig={{
  rowField: "${cfg.pivotRowField}",
  columnField: "${cfg.pivotColField}",
  valueField: "${cfg.pivotValueField}",
  aggregation: "${cfg.pivotAgg}",
  rowFieldHeader: "${fields.find((f) => f.value === cfg.pivotRowField)?.label || cfg.pivotRowField}",
  showGrandTotals: ${cfg.pivotGrandTotals},
  showRowTotals: ${cfg.pivotRowTotals},
}}`);
  }

  if (cfg.pinning) props.push('pinnedColumns={{ left: ["id"], right: ["actions"] }}');
  if (cfg.columnGroups) props.push("columnGroups={[...]}");

  if (mode === "props") return props.join("\n");

  return `import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";

// Tus columnas aqui...
const columns: ZenttoColDef[] = [ /* ... */ ];

<ZenttoDataGrid
  gridId="mi-tabla"
  columns={columns}
  rows={rows}
  loading={isLoading}
  ${props.join("\n  ")}
  exportFilename="mi-tabla"
  pageSizeOptions={[10, 25, 50, 100]}
/>`;
}

// ─── Component ──────────────────────────────────────────

export function LabConfigurator({
  config,
  onChange,
  fields,
  numericFields,
}: {
  config: LabConfig;
  onChange: (c: LabConfig) => void;
  fields: FieldOption[];
  numericFields: FieldOption[];
}) {
  const set = (partial: Partial<LabConfig>) => onChange({ ...config, ...partial });
  const [copied, setCopied] = useState(false);
  const [showCode, setShowCode] = useState(false);
  const [codeTab, setCodeTab] = useState(0);

  const code = generateCode(config, fields, numericFields, codeTab === 0 ? "full" : "props");

  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <Box sx={{ mb: 1.5 }}>
      <Accordion defaultExpanded={false} variant="outlined" sx={{ "&:before": { display: "none" } }}>
        <AccordionSummary expandIcon={<ExpandIcon />}>
          <Stack direction="row" spacing={1} alignItems="center">
            <SettingsIcon fontSize="small" color="primary" />
            <Typography variant="subtitle2">Configurar ZenttoDataGrid</Typography>
            <Chip label="LAB" size="small" color="warning" />
          </Stack>
        </AccordionSummary>
        <AccordionDetails>
          <Stack spacing={3}>
            {/* ─── PIVOT ──────────────────── */}
            <Box>
              <FormControlLabel
                control={<Switch checked={config.pivotEnabled} onChange={(e) => set({ pivotEnabled: e.target.checked })} />}
                label={<Typography variant="subtitle2" fontWeight={600}>Tabla Pivot</Typography>}
              />
              {config.pivotEnabled && (
                <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap sx={{ mt: 1 }}>
                  <TextField select label="Filas (eje Y)" value={config.pivotRowField} onChange={(e) => set({ pivotRowField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                    {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                  </TextField>
                  <TextField select label="Columnas (eje X)" value={config.pivotColField} onChange={(e) => set({ pivotColField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                    {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                  </TextField>
                  <TextField select label="Valor" value={config.pivotValueField} onChange={(e) => set({ pivotValueField: e.target.value })} size="small" sx={{ minWidth: 130 }}>
                    {numericFields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                  </TextField>
                  <TextField select label="Agregacion" value={config.pivotAgg} onChange={(e) => set({ pivotAgg: e.target.value })} size="small" sx={{ minWidth: 120 }}>
                    {AGG_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                  </TextField>
                  <FormControlLabel control={<Switch checked={config.pivotGrandTotals} onChange={(e) => set({ pivotGrandTotals: e.target.checked })} size="small" />} label="Gran Total" />
                  <FormControlLabel control={<Switch checked={config.pivotRowTotals} onChange={(e) => set({ pivotRowTotals: e.target.checked })} size="small" />} label="Total x fila" />
                </Stack>
              )}
            </Box>

            {/* ─── GROUPING ──────────────────── */}
            <Box>
              <FormControlLabel
                control={<Switch checked={config.groupingEnabled} onChange={(e) => set({ groupingEnabled: e.target.checked })} />}
                label={<Typography variant="subtitle2" fontWeight={600}>Agrupar filas</Typography>}
              />
              {config.groupingEnabled && (
                <Stack direction="row" spacing={1.5} sx={{ mt: 1 }}>
                  <TextField select label="Agrupar por" value={config.groupField} onChange={(e) => set({ groupField: e.target.value })} size="small" sx={{ minWidth: 140 }}>
                    {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
                  </TextField>
                  <TextField select label="Ordenar" value={config.groupSort} onChange={(e) => set({ groupSort: e.target.value as any })} size="small" sx={{ minWidth: 120 }}>
                    <MenuItem value="">Sin orden</MenuItem>
                    <MenuItem value="asc">A-Z</MenuItem>
                    <MenuItem value="desc">Z-A</MenuItem>
                  </TextField>
                  <FormControlLabel control={<Switch checked={config.groupSubtotals} onChange={(e) => set({ groupSubtotals: e.target.checked })} size="small" />} label="Subtotales" />
                </Stack>
              )}
            </Box>

            {/* ─── FEATURES ──────────────────── */}
            <Box>
              <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 1 }}>Funciones</Typography>
              <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap>
                <FormControlLabel control={<Switch checked={config.headerFilters} onChange={(e) => set({ headerFilters: e.target.checked })} size="small" />} label="Filtros en headers" />
                <FormControlLabel control={<Switch checked={config.showTotals} onChange={(e) => set({ showTotals: e.target.checked })} size="small" />} label="Fila de totales" />
                <FormControlLabel control={<Switch checked={config.clipboard} onChange={(e) => set({ clipboard: e.target.checked })} size="small" />} label="Clipboard" />
                <FormControlLabel control={<Switch checked={config.columnGroups} onChange={(e) => set({ columnGroups: e.target.checked })} size="small" />} label="Grupos columnas" />
                <FormControlLabel control={<Switch checked={config.pinning} onChange={(e) => set({ pinning: e.target.checked })} size="small" />} label="Columnas fijas" />
              </Stack>
            </Box>
          </Stack>
        </AccordionDetails>
      </Accordion>

      {/* ─── SHOW CODE — estilo MUI docs ──────────────────── */}
      <Stack
        direction="row"
        justifyContent="flex-end"
        spacing={1}
        sx={{ p: 0.5, bgcolor: "#f5f5f5", borderRadius: showCode ? 0 : "0 0 8px 8px", border: "1px solid #e0e0e0", borderTop: 0 }}
      >
        <Button size="small" startIcon={showCode ? <HideIcon /> : <CodeIcon />} onClick={() => setShowCode(!showCode)} sx={{ textTransform: "none" }}>
          {showCode ? "Hide code" : "Show code"}
        </Button>
        {showCode && (
          <Tooltip title="Copiar">
            <IconButton size="small" onClick={handleCopy}><CopyIcon fontSize="small" /></IconButton>
          </Tooltip>
        )}
      </Stack>

      <Collapse in={showCode}>
        <Box sx={{ border: "1px solid #e0e0e0", borderTop: 0, borderRadius: "0 0 8px 8px", overflow: "hidden" }}>
          <Tabs value={codeTab} onChange={(_, v) => setCodeTab(v)} sx={{ px: 1, bgcolor: "#1e1e1e", minHeight: 36 }}>
            <Tab label="Completo" sx={{ color: "#aaa", "&.Mui-selected": { color: "#fff" }, textTransform: "none", minHeight: 36, py: 0 }} />
            <Tab label="Solo props" sx={{ color: "#aaa", "&.Mui-selected": { color: "#fff" }, textTransform: "none", minHeight: 36, py: 0 }} />
          </Tabs>
          <Box
            component="pre"
            sx={{
              m: 0, p: 2, bgcolor: "#1e1e1e", color: "#d4d4d4",
              fontSize: "0.8rem", fontFamily: "Consolas, Monaco, monospace",
              overflow: "auto", maxHeight: 350,
            }}
          >
            {code}
          </Box>
        </Box>
      </Collapse>

      <Snackbar open={copied} message="Copiado al portapapeles" autoHideDuration={2000} onClose={() => setCopied(false)} />
    </Box>
  );
}
