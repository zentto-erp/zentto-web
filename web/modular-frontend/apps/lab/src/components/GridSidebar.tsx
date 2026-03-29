// GridSidebar — Panel lateral estilo AG Grid integrado al DataGrid.
// Tabs: Columnas, Pivot, Grupos, Codigo
"use client";

import React, { useState } from "react";
import {
  Box,
  Button,
  Checkbox,
  Chip,
  Divider,
  FormControlLabel,
  IconButton,
  MenuItem,
  Dialog,
  DialogContent,
  DialogTitle,
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
  ViewColumn as ColumnsIcon,
  PivotTableChart as PivotIcon,
  TableRows as GroupIcon,
  Code as CodeIcon,
  ContentCopy as CopyIcon,
  Fullscreen as FullscreenIcon,
  Close as CloseIcon,
  ChevronRight as OpenIcon,
  ChevronLeft as CollapseIcon,
  DragIndicator as DragIcon,
} from "@mui/icons-material";
import dynamic from "next/dynamic";
import type { LabConfig, FieldOption } from "./LabConfigurator";

// Monaco lazy-load (solo se carga cuando se abre el modal)
const MonacoEditor = dynamic(() => import("@monaco-editor/react"), { ssr: false });

// ─── Types ──────────────────────────────────────────

type SidebarTab = "columns" | "pivot" | "groups" | "code";

const AGG_OPTIONS = [
  { value: "sum", label: "Suma" },
  { value: "avg", label: "Promedio" },
  { value: "count", label: "Conteo" },
  { value: "min", label: "Min" },
  { value: "max", label: "Max" },
];

// ─── Code Generator ──────────────────────────────────

function generateCode(cfg: LabConfig, fields: FieldOption[]): string {
  // ── Build props section ──
  const p: string[] = [];

  p.push(`      gridId="productos-table"`);
  p.push(`      columns={columns}`);
  p.push(`      rows={productos}`);
  p.push(`      pageSizeOptions={[10, 25, 50, 100]}`);
  p.push(`      exportFilename="productos"`);
  p.push(`      defaultCurrency="VES"`);

  if (cfg.clipboard) p.push(`      enableClipboard`);
  if (cfg.headerFilters) p.push(`      enableHeaderFilters`);
  if (cfg.showTotals) {
    p.push(`      showTotals`);
    p.push(`      totalsLabel="Totales"`);
  }
  if (cfg.pinning) {
    p.push(`      pinnedColumns={{ left: ["codigo"], right: ["estado"] }}`);
  }
  if (cfg.columnGroups) {
    p.push(`      columnGroups={[
        { groupId: "producto", headerName: "Producto", children: ["codigo", "nombre", "categoria"] },
        { groupId: "financiero", headerName: "Financiero", children: ["precio", "stock"] },
      ]}`);
  }
  if (cfg.groupingEnabled) {
    p.push(`      enableGrouping`);
    p.push(`      rowGroupingConfig={{
        field: "${cfg.groupField}",
        showSubtotals: ${cfg.groupSubtotals},
        sortGroups: ${cfg.groupSort ? `"${cfg.groupSort}"` : "null"},
      }}`);
  }
  if (cfg.pivotEnabled) {
    const rowLabel = fields.find((f) => f.value === cfg.pivotRowField)?.label || cfg.pivotRowField;
    p.push(`      enablePivot`);
    p.push(`      pivotConfig={{
        rowField: "${cfg.pivotRowField}",
        columnField: "${cfg.pivotColField}",
        valueField: "${cfg.pivotValueField}",
        aggregation: "${cfg.pivotAgg}",
        rowFieldHeader: "${rowLabel}",
        showGrandTotals: ${cfg.pivotGrandTotals},
        showRowTotals: ${cfg.pivotRowTotals},
      }}`);
  }

  return `/**
 * Ejemplo funcional de <zentto-grid> (web component nativo)
 * Copiar este archivo, instalar dependencias y funciona.
 *
 * npm install @zentto/datagrid @zentto/datagrid-core
 */
"use client";

import React, { useRef, useEffect, useState } from "react";
import { Box, Typography } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";

// ─── Tipos ─────────────────────────────────────────────────
interface Producto {
  id: number;
  codigo: string;
  nombre: string;
  categoria: string;
  precio: number;
  stock: number;
  estado: "Activo" | "Inactivo";
}

// ─── Columnas ──────────────────────────────────────────────
const columns: ColumnDef[] = [
  {
    field: "codigo",
    header: "Codigo",
    width: 120,
    sortable: true,
  },
  {
    field: "nombre",
    header: "Nombre",
    flex: 1,
    minWidth: 200,
    sortable: true,
  },
  {
    field: "categoria",
    header: "Categoria",
    width: 130,
    sortable: true,
  },
  {
    field: "precio",
    header: "Precio",
    width: 120,
    type: "number",
    currency: true,        // formatea como moneda automaticamente
    aggregation: "sum",    // suma en la fila de totales
  },
  {
    field: "stock",
    header: "Stock",
    width: 100,
    type: "number",
    aggregation: "sum",
  },
  {
    field: "estado",
    header: "Estado",
    width: 110,
    statusColors: {        // chip coloreado automatico
      Activo: "success",
      Inactivo: "error",
    },
    statusVariant: "outlined",
  },
];

// ─── Datos de ejemplo ──────────────────────────────────────
const productos: Producto[] = [
  { id: 1,  codigo: "ELEC-001", nombre: "Audifonos Bluetooth Pro",         categoria: "Electro",  precio: 89.99,  stock: 150, estado: "Activo" },
  { id: 2,  codigo: "ELEC-002", nombre: "Cargador Inalambrico 15W",       categoria: "Electro",  precio: 29.99,  stock: 300, estado: "Activo" },
  { id: 3,  codigo: "ELEC-003", nombre: "Teclado Mecanico RGB",           categoria: "Electro",  precio: 69.99,  stock: 90,  estado: "Activo" },
  { id: 4,  codigo: "DEP-001",  nombre: "Set Bandas Elasticas (5 pcs)",   categoria: "Deporte",  precio: 14.99,  stock: 301, estado: "Activo" },
  { id: 5,  codigo: "DEP-002",  nombre: "Botella Termica 1L Acero",       categoria: "Deporte",  precio: 19.99,  stock: 251, estado: "Activo" },
  { id: 6,  codigo: "DEP-003",  nombre: "Mat de Yoga Antideslizante",     categoria: "Deporte",  precio: 22.99,  stock: 160, estado: "Activo" },
  { id: 7,  codigo: "HOG-001",  nombre: "Lampara LED Escritorio",         categoria: "Hogar",    precio: 34.99,  stock: 75,  estado: "Activo" },
  { id: 8,  codigo: "HOG-002",  nombre: "Organizador Cajones Bambu",      categoria: "Hogar",    precio: 24.99,  stock: 0,   estado: "Inactivo" },
  { id: 9,  codigo: "HOG-003",  nombre: "Bascula Digital Cocina",         categoria: "Hogar",    precio: 15.99,  stock: 200, estado: "Activo" },
  { id: 10, codigo: "ELEC-004", nombre: "Power Bank 20000mAh USB-C",      categoria: "Electro",  precio: 39.99,  stock: 180, estado: "Activo" },
];

// ─── Componente ────────────────────────────────────────────
export default function ProductosTable() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = productos;
  }, [registered]);

  return (
    <Box sx={{ height: 600, p: 2 }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 2 }}>
        Productos
      </Typography>

      <zentto-grid
        ref={gridRef}
        export-filename="productos"
        height="500px"
        enable-toolbar
        enable-header-filters
        enable-clipboard
      />
    </Box>
  );
}`;
}

// ─── Sidebar Tab Icons ──────────────────────────────

const TAB_ICONS: Record<SidebarTab, React.ReactElement> = {
  columns: <ColumnsIcon fontSize="small" />,
  pivot: <PivotIcon fontSize="small" />,
  groups: <GroupIcon fontSize="small" />,
  code: <CodeIcon fontSize="small" />,
};

const TAB_LABELS: Record<SidebarTab, string> = {
  columns: "Columnas",
  pivot: "Pivot",
  groups: "Grupos",
  code: "Codigo",
};

// ─── Main Component ──────────────────────────────────

export function GridSidebar({
  config,
  onChange,
  fields,
  numericFields,
  children,
}: {
  config: LabConfig;
  onChange: (c: LabConfig) => void;
  fields: FieldOption[];
  numericFields: FieldOption[];
  children: React.ReactNode; // The grid
}) {
  const [open, setOpen] = useState(true);
  const [activeTab, setActiveTab] = useState<SidebarTab>("pivot");
  const [copied, setCopied] = useState(false);
  const set = (partial: Partial<LabConfig>) => onChange({ ...config, ...partial });

  const handleCopy = () => {
    navigator.clipboard.writeText(generateCode(config, fields)).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <Box sx={{ display: "flex", flex: 1, minHeight: 0, border: "1px solid #e0e0e0", borderRadius: 1, overflow: "hidden" }}>
      {/* Grid area */}
      <Box sx={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}>
        {children}
      </Box>

      {/* Collapsed tab strip (always visible) */}
      <Box
        sx={{
          display: "flex",
          flexDirection: "column",
          bgcolor: "#f8f8f8",
          borderLeft: "1px solid #e0e0e0",
          width: open ? 0 : 32,
          overflow: "hidden",
          transition: "width 0.2s",
        }}
      >
        {!open && (
          <Tooltip title="Abrir panel" placement="left">
            <IconButton size="small" onClick={() => setOpen(true)} sx={{ mt: 1 }}>
              <OpenIcon fontSize="small" sx={{ transform: "rotate(180deg)" }} />
            </IconButton>
          </Tooltip>
        )}
      </Box>

      {/* Sidebar panel */}
      <Box
        sx={{
          width: open ? 280 : 0,
          minWidth: open ? 280 : 0,
          transition: "width 0.2s, min-width 0.2s",
          overflow: "hidden",
          borderLeft: open ? "1px solid #e0e0e0" : "none",
          display: "flex",
          flexDirection: "column",
          bgcolor: "#fafafa",
        }}
      >
        {open && (
          <>
            {/* Header */}
            <Box sx={{ display: "flex", alignItems: "center", px: 1, py: 0.5, bgcolor: "#f0f0f0", borderBottom: "1px solid #e0e0e0" }}>
              <IconButton size="small" onClick={() => setOpen(false)}>
                <CollapseIcon fontSize="small" />
              </IconButton>
              <Typography variant="caption" fontWeight={600} sx={{ ml: 0.5 }}>
                {TAB_LABELS[activeTab]}
              </Typography>
            </Box>

            {/* Tab strip */}
            <Tabs
              value={activeTab}
              onChange={(_, v) => setActiveTab(v)}
              variant="fullWidth"
              sx={{
                minHeight: 36,
                borderBottom: "1px solid #e0e0e0",
                "& .MuiTab-root": { minHeight: 36, py: 0.5, minWidth: 0 },
              }}
            >
              {(["columns", "pivot", "groups", "code"] as SidebarTab[]).map((tab) => (
                <Tab key={tab} value={tab} icon={TAB_ICONS[tab]} sx={{ minWidth: 0, px: 1 }} />
              ))}
            </Tabs>

            {/* Tab content */}
            <Box sx={{ flex: 1, overflow: "auto", p: 1.5 }}>
              {activeTab === "columns" && (
                <ColumnsPanel config={config} onChange={set} fields={fields} />
              )}
              {activeTab === "pivot" && (
                <PivotPanel config={config} onChange={set} fields={fields} numericFields={numericFields} />
              )}
              {activeTab === "groups" && (
                <GroupsPanel config={config} onChange={set} fields={fields} />
              )}
              {activeTab === "code" && (
                <CodePanel config={config} fields={fields} onCopy={handleCopy} />
              )}
            </Box>
          </>
        )}
      </Box>

      <Snackbar open={copied} message="Copiado" autoHideDuration={1500} onClose={() => setCopied(false)} />
    </Box>
  );
}

// ─── Columns Tab ──────────────────────────────────────

function ColumnsPanel({
  config, onChange, fields,
}: {
  config: LabConfig;
  onChange: (p: Partial<LabConfig>) => void;
  fields: FieldOption[];
}) {
  // Parse pinned columns from config
  const pinnedLeft = (config as any).pinnedLeft as string[] || [];
  const pinnedRight = (config as any).pinnedRight as string[] || [];

  const togglePin = (field: string, side: "left" | "right") => {
    const current = side === "left" ? [...pinnedLeft] : [...pinnedRight];
    const other = side === "left" ? [...pinnedRight] : [...pinnedLeft];
    const idx = current.indexOf(field);
    if (idx >= 0) {
      current.splice(idx, 1);
    } else {
      // Remove from other side first
      const oi = other.indexOf(field);
      if (oi >= 0) other.splice(oi, 1);
      current.push(field);
    }
    if (side === "left") {
      onChange({ pinnedLeft: current, pinnedRight: other } as any);
    } else {
      onChange({ pinnedRight: current, pinnedLeft: other } as any);
    }
  };

  return (
    <Stack spacing={1.5}>
      <Typography variant="caption" fontWeight={600} color="text.secondary">Funciones</Typography>
      <FormControlLabel
        control={<Switch checked={config.headerFilters} onChange={(e) => onChange({ headerFilters: e.target.checked })} size="small" />}
        label={<Typography variant="body2">Filtros en headers</Typography>}
      />
      <FormControlLabel
        control={<Switch checked={config.showTotals} onChange={(e) => onChange({ showTotals: e.target.checked })} size="small" />}
        label={<Typography variant="body2">Fila de totales</Typography>}
      />
      <FormControlLabel
        control={<Switch checked={config.clipboard} onChange={(e) => onChange({ clipboard: e.target.checked })} size="small" />}
        label={<Typography variant="body2">Clipboard (Ctrl+C)</Typography>}
      />
      <FormControlLabel
        control={<Switch checked={config.columnGroups} onChange={(e) => onChange({ columnGroups: e.target.checked })} size="small" />}
        label={<Typography variant="body2">Grupos de columnas</Typography>}
      />

      <Divider />
      <Typography variant="caption" fontWeight={600} color="text.secondary">
        Fijar columnas (Pin)
      </Typography>
      <Typography variant="caption" color="text.secondary">
        Haz clic en los iconos para fijar a izquierda o derecha
      </Typography>

      {fields.map((f) => {
        const isLeft = pinnedLeft.includes(f.value);
        const isRight = pinnedRight.includes(f.value);
        return (
          <Box key={f.value} sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
            <Tooltip title="Fijar izquierda">
              <IconButton
                size="small"
                onClick={() => togglePin(f.value, "left")}
                color={isLeft ? "primary" : "default"}
                sx={{ fontSize: "0.7rem" }}
              >
                {isLeft ? "◀" : "◁"}
              </IconButton>
            </Tooltip>
            <Typography variant="body2" sx={{ flex: 1, fontSize: "0.8rem" }}>
              {f.label}
            </Typography>
            <Tooltip title="Fijar derecha">
              <IconButton
                size="small"
                onClick={() => togglePin(f.value, "right")}
                color={isRight ? "primary" : "default"}
                sx={{ fontSize: "0.7rem" }}
              >
                {isRight ? "▶" : "▷"}
              </IconButton>
            </Tooltip>
          </Box>
        );
      })}
    </Stack>
  );
}

// ─── Pivot Tab ──────────────────────────────────────

function PivotPanel({
  config, onChange, fields, numericFields,
}: {
  config: LabConfig;
  onChange: (p: Partial<LabConfig>) => void;
  fields: FieldOption[];
  numericFields: FieldOption[];
}) {
  return (
    <Stack spacing={1.5}>
      <FormControlLabel
        control={<Switch checked={config.pivotEnabled} onChange={(e) => onChange({ pivotEnabled: e.target.checked })} />}
        label={<Typography variant="subtitle2" fontWeight={600}>Pivot Mode</Typography>}
      />

      {config.pivotEnabled && (
        <>
          <TextField select label="Filas (eje Y)" value={config.pivotRowField} onChange={(e) => onChange({ pivotRowField: e.target.value })} size="small" fullWidth>
            {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
          </TextField>

          <TextField select label="Columnas (eje X)" value={config.pivotColField} onChange={(e) => onChange({ pivotColField: e.target.value })} size="small" fullWidth>
            {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
          </TextField>

          <Divider />
          <Typography variant="caption" color="text.secondary" fontWeight={600}>
            Valores
          </Typography>

          <Box sx={{ display: "flex", gap: 1 }}>
            <TextField select label="Campo" value={config.pivotValueField} onChange={(e) => onChange({ pivotValueField: e.target.value })} size="small" sx={{ flex: 1 }}>
              {numericFields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
            <TextField select label="Fn" value={config.pivotAgg} onChange={(e) => onChange({ pivotAgg: e.target.value })} size="small" sx={{ width: 90 }}>
              {AGG_OPTIONS.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
          </Box>

          {/* Value chips (like AG Grid) */}
          <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>
            <Chip
              icon={<DragIcon sx={{ fontSize: 14 }} />}
              label={`${AGG_OPTIONS.find((a) => a.value === config.pivotAgg)?.label || "sum"}(${numericFields.find((f) => f.value === config.pivotValueField)?.label || config.pivotValueField})`}
              size="small"
              color="primary"
              variant="outlined"
              onDelete={() => onChange({ pivotEnabled: false })}
            />
          </Box>

          <Divider />
          <FormControlLabel
            control={<Switch checked={config.pivotGrandTotals} onChange={(e) => onChange({ pivotGrandTotals: e.target.checked })} size="small" />}
            label={<Typography variant="body2">Gran Total</Typography>}
          />
          <FormControlLabel
            control={<Switch checked={config.pivotRowTotals} onChange={(e) => onChange({ pivotRowTotals: e.target.checked })} size="small" />}
            label={<Typography variant="body2">Total por fila</Typography>}
          />
        </>
      )}
    </Stack>
  );
}

// ─── Groups Tab ──────────────────────────────────────

function GroupsPanel({
  config, onChange, fields,
}: {
  config: LabConfig;
  onChange: (p: Partial<LabConfig>) => void;
  fields: FieldOption[];
}) {
  return (
    <Stack spacing={1.5}>
      <FormControlLabel
        control={<Switch checked={config.groupingEnabled} onChange={(e) => onChange({ groupingEnabled: e.target.checked })} />}
        label={<Typography variant="subtitle2" fontWeight={600}>Row Groups</Typography>}
      />

      {config.groupingEnabled && (
        <>
          <Typography variant="caption" color="text.secondary">
            Agrupar filas por campo
          </Typography>

          <TextField select label="Agrupar por" value={config.groupField} onChange={(e) => onChange({ groupField: e.target.value })} size="small" fullWidth>
            {fields.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
          </TextField>

          {/* Active group chip */}
          <Box sx={{ p: 1, border: "1px dashed #ccc", borderRadius: 1, minHeight: 40, display: "flex", alignItems: "center", gap: 0.5 }}>
            <DragIcon sx={{ fontSize: 14, color: "text.secondary" }} />
            <Chip
              label={fields.find((f) => f.value === config.groupField)?.label || config.groupField}
              size="small"
              color="info"
              onDelete={() => onChange({ groupingEnabled: false })}
            />
          </Box>

          <TextField select label="Ordenar" value={config.groupSort} onChange={(e) => onChange({ groupSort: e.target.value as any })} size="small" fullWidth>
            <MenuItem value="">Sin orden</MenuItem>
            <MenuItem value="asc">A → Z</MenuItem>
            <MenuItem value="desc">Z → A</MenuItem>
          </TextField>

          <FormControlLabel
            control={<Switch checked={config.groupSubtotals} onChange={(e) => onChange({ groupSubtotals: e.target.checked })} size="small" />}
            label={<Typography variant="body2">Subtotales</Typography>}
          />
        </>
      )}
    </Stack>
  );
}

// ─── Code Tab ──────────────────────────────────────

function CodePanel({
  config, fields, onCopy,
}: {
  config: LabConfig;
  fields: FieldOption[];
  onCopy: () => void;
}) {
  const code = generateCode(config, fields);
  const [monacoOpen, setMonacoOpen] = useState(false);
  const [copied2, setCopied2] = useState(false);

  const handleCopyInModal = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied2(true);
      setTimeout(() => setCopied2(false), 2000);
    });
  };

  return (
    <>
      <Stack spacing={1}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Typography variant="caption" fontWeight={600}>JSX generado</Typography>
          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Copiar codigo">
              <IconButton size="small" onClick={onCopy}><CopyIcon fontSize="small" /></IconButton>
            </Tooltip>
            <Tooltip title="Abrir en editor">
              <IconButton size="small" onClick={() => setMonacoOpen(true)} color="primary">
                <FullscreenIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Stack>
        </Box>
        <Box
          component="pre"
          sx={{
            m: 0, p: 1.5, bgcolor: "#1e1e1e", color: "#d4d4d4",
            fontSize: "0.7rem", fontFamily: "Consolas, Monaco, monospace",
            overflow: "auto", maxHeight: 300, borderRadius: 1,
            whiteSpace: "pre-wrap", wordBreak: "break-word",
          }}
        >
          {code}
        </Box>
      </Stack>

      {/* ─── Modal con Monaco Editor ─── */}
      <Dialog
        open={monacoOpen}
        onClose={() => setMonacoOpen(false)}
        maxWidth={false}
        fullWidth
        PaperProps={{ sx: { width: "90vw", height: "85vh", maxWidth: "none" } }}
      >
        <DialogTitle sx={{ display: "flex", alignItems: "center", py: 1, bgcolor: "#1e1e1e", color: "#fff" }}>
          <CodeIcon sx={{ mr: 1 }} />
          <Box component="span" sx={{ flex: 1, fontWeight: 600, fontSize: "0.95rem" }}>
            ProductosTable.tsx
          </Box>
          <Chip label="TypeScript React" size="small" sx={{ mr: 1, color: "#fff", borderColor: "#555" }} variant="outlined" />
          <Button
            size="small"
            startIcon={<CopyIcon />}
            onClick={handleCopyInModal}
            sx={{ color: "#fff", mr: 1, textTransform: "none" }}
          >
            {copied2 ? "Copiado!" : "Copiar"}
          </Button>
          <IconButton size="small" onClick={() => setMonacoOpen(false)} sx={{ color: "#fff" }}>
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent sx={{ p: 0, bgcolor: "#1e1e1e", overflow: "hidden" }}>
          <MonacoEditor
            height="100%"
            language="typescript"
            theme="vs-dark"
            value={code}
            options={{
              readOnly: true,
              minimap: { enabled: true },
              fontSize: 14,
              lineNumbers: "on",
              scrollBeyondLastLine: false,
              wordWrap: "on",
              padding: { top: 12 },
              renderWhitespace: "none",
              smoothScrolling: true,
              cursorBlinking: "smooth",
              folding: true,
              bracketPairColorization: { enabled: true },
            }}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}
