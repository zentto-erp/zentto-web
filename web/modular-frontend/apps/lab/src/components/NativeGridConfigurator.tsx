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
  enableContextMenu: boolean;
  enableStatusBar: boolean;
  enableGrouping: boolean;
  enableMasterDetail: boolean;
  groupField: string;
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
  enableContextMenu: true,
  enableStatusBar: true,
  enableGrouping: false,
  enableMasterDetail: false,
  groupField: "",
  theme: "light",
  density: "comfortable",
  locale: "es",
  primaryColor: "#f59e0b",
  headerBg: "#f8f9fa",
  borderColor: "#e0e0e0",
  rowAltBg: "#fafafa",
  fontFamily: "Inter, system-ui, sans-serif",
  fontSize: "0.875rem",
  borderRadius: 8,
};

// ─── Configurator Component ──────────────────────────────

export function NativeGridConfigurator({
  config,
  onChange,
  groupableFields = [],
  children,
}: {
  config: NativeGridConfig;
  onChange: (c: NativeGridConfig) => void;
  groupableFields?: { value: string; label: string }[];
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(true);
  const [tab, setTab] = useState(0);
  const set = (partial: Partial<NativeGridConfig>) => onChange({ ...config, ...partial });

  // Generate CSS custom properties string
  const cssVars: Record<string, string> = {
    "--zg-primary": config.primaryColor,
    "--zg-header-bg": config.headerBg,
    "--zg-border-color": config.borderColor,
    "--zg-row-alt-bg": config.rowAltBg,
    "--zg-font-family": config.fontFamily,
    "--zg-font-size": config.fontSize,
  };

  const cssVarsString = Object.entries(cssVars)
    .map(([k, v]) => `${k}: ${v};`)
    .join("\n  ");

  // Generate usage code
  const codeSnippet = `<zentto-grid
  ${config.showTotals ? "show-totals" : ""}
  ${config.enableHeaderFilters ? "enable-header-filters" : ""}
  ${config.enableClipboard ? "enable-clipboard" : ""}
  ${config.enableFind ? "enable-find" : ""}
  ${config.enableContextMenu ? "enable-context-menu" : ""}
  ${config.enableStatusBar ? "enable-status-bar" : ""}
  ${config.enableGrouping ? `enable-grouping\n  group-field="${config.groupField}"` : ""}
  ${config.enableMasterDetail ? "enable-master-detail" : ""}
  theme="${config.theme}"
  density="${config.density}"
  locale="${config.locale}"
  style="${Object.entries(cssVars).map(([k, v]) => `${k}:${v}`).join(";")}"
></zentto-grid>`.replace(/\n\s*\n/g, "\n").trim();

  return (
    <Box sx={{ display: "flex", flex: 1, minHeight: 0, gap: 0 }}>
      {/* Grid with CSS vars applied */}
      <Box
        sx={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}
        style={cssVars as any}
      >
        {children}
      </Box>

      {/* Sidebar */}
      {!open && (
        <Tooltip title="Abrir configurador">
          <IconButton
            onClick={() => setOpen(true)}
            sx={{ position: "fixed", right: 8, top: 100, bgcolor: "#f0f0f0", zIndex: 10 }}
          >
            <SettingsIcon />
          </IconButton>
        </Tooltip>
      )}

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
            <Tab icon={<TuneIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} />
            <Tab icon={<PaletteIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} />
            <Tab icon={<CodeIcon sx={{ fontSize: 18 }} />} sx={{ minWidth: 0 }} />
          </Tabs>

          {/* Content */}
          <Box sx={{ flex: 1, overflow: "auto", p: 1.5 }}>
            {tab === 0 && (
              <FeaturesPanel config={config} onChange={set} groupableFields={groupableFields} />
            )}
            {tab === 1 && (
              <ThemePanel config={config} onChange={set} />
            )}
            {tab === 2 && (
              <CodePanel code={codeSnippet} cssVars={cssVarsString} />
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

      <Divider />
      <Typography variant="caption" fontWeight={600} color="text.secondary">Agrupacion</Typography>
      <FormControlLabel control={<Switch checked={config.enableGrouping} onChange={(e) => onChange({ enableGrouping: e.target.checked })} size="small" />} label={<Typography variant="body2">Row grouping</Typography>} />
      {config.enableGrouping && groupableFields.length > 0 && (
        <TextField select label="Agrupar por" value={config.groupField} onChange={(e) => onChange({ groupField: e.target.value })} size="small" fullWidth>
          {groupableFields.map((f) => <MenuItem key={f.value} value={f.value}>{f.label}</MenuItem>)}
        </TextField>
      )}

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

function CodePanel({ code, cssVars }: { code: string; cssVars: string }) {
  const [copied, setCopied] = useState(false);

  const fullCode = `<!-- HTML -->
${code}

<!-- CSS Custom Properties -->
<style>
  zentto-grid {
  ${cssVars}
  }
</style>`;

  return (
    <Stack spacing={1}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <Typography variant="caption" fontWeight={600}>Codigo generado</Typography>
        <Tooltip title="Copiar">
          <IconButton size="small" onClick={() => {
            navigator.clipboard.writeText(fullCode);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
          }}>
            <CopyIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>
      {copied && <Chip label="Copiado!" color="success" size="small" />}
      <Box
        component="pre"
        sx={{
          m: 0, p: 1, bgcolor: "#1e1e1e", color: "#d4d4d4",
          fontSize: "0.7rem", fontFamily: "Consolas, Monaco, monospace",
          overflow: "auto", maxHeight: 400, borderRadius: 1,
          whiteSpace: "pre-wrap", wordBreak: "break-word",
        }}
      >
        {fullCode}
      </Box>
    </Stack>
  );
}
