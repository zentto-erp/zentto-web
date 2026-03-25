// CodePreview — Panel "Show code" estilo MUI docs.
// Muestra el codigo completo del componente con la configuracion actual.
"use client";

import { useState } from "react";
import {
  Box,
  Button,
  Collapse,
  IconButton,
  Snackbar,
  Stack,
  Tab,
  Tabs,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  Code as CodeIcon,
  ContentCopy as CopyIcon,
  OpenInNew as OpenIcon,
  VisibilityOff as HideIcon,
} from "@mui/icons-material";
import type { LabConfig } from "./PivotConfigurator";

// ─── Generador de codigo completo ──────────────────────────

function generateFullCode(cfg: LabConfig): string {
  const imports = [
    `import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";`,
  ];

  // Build columns
  const cols = `const columns: ZenttoColDef[] = [
  { field: "numeroFactura", headerName: "Numero", width: 150, sortable: true },
  { field: "nombreCliente", headerName: "Cliente", flex: 1, minWidth: 180 },
  {
    field: "fecha", headerName: "Fecha", width: 120,
    valueFormatter: (value) => value ? new Date(value).toLocaleDateString("es-VE") : "",
  },
  {
    field: "tipoDoc", headerName: "Tipo", width: 110,
    statusColors: { FACT: "primary", PRESUP: "info", PEDIDO: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "totalFactura", headerName: "Total", width: 140,
    type: "number", currency: true, aggregation: "sum",
  },
  {
    field: "estado", headerName: "Estado", width: 120,
    statusColors: { Pagada: "success", Emitida: "info", Anulada: "error" },
    statusVariant: "outlined",
  },
];`;

  // Build props
  const props: string[] = [
    `gridId="mi-tabla"`,
    `columns={columns}`,
    `rows={rows}`,
    `loading={isLoading}`,
  ];

  if (cfg.clipboard) props.push(`enableClipboard`);
  if (cfg.headerFilters) props.push(`enableHeaderFilters`);
  if (cfg.showTotals) {
    props.push(`showTotals`);
    props.push(`totalsLabel="Totales"`);
  }
  props.push(`defaultCurrency="VES"`);

  if (cfg.groupingEnabled) {
    props.push(`enableGrouping`);
    props.push(`rowGroupingConfig={{
    field: "${cfg.groupField}",
    showSubtotals: ${cfg.groupSubtotals},
    sortGroups: ${cfg.groupSort ? `"${cfg.groupSort}"` : "null"},
  }}`);
  }

  if (cfg.pivotEnabled) {
    props.push(`enablePivot`);
    props.push(`pivotConfig={{
    rowField: "${cfg.pivotRowField}",
    columnField: "${cfg.pivotColField}",
    valueField: "${cfg.pivotValueField}",
    aggregation: "${cfg.pivotAgg}",
    showGrandTotals: ${cfg.pivotGrandTotals},
    showRowTotals: ${cfg.pivotRowTotals},
  }}`);
  }

  if (cfg.pinning) {
    props.push(`pinnedColumns={{ left: ["numeroFactura"], right: ["actions"] }}`);
  }

  if (cfg.columnGroups) {
    props.push(`columnGroups={[
    { groupId: "doc", headerName: "Documento", children: ["numeroFactura", "tipoDoc", "estado"] },
    { groupId: "comercial", headerName: "Comercial", children: ["nombreCliente", "totalFactura"] },
  ]}`);
  }

  props.push(`exportFilename="facturas"`);
  props.push(`pageSizeOptions={[10, 25, 50, 100]}`);

  return `${imports.join("\n")}

${cols}

// En tu componente:
<ZenttoDataGrid
  ${props.join("\n  ")}
/>`;
}

function generatePropsOnly(cfg: LabConfig): string {
  const lines: string[] = [];
  if (cfg.clipboard) lines.push("enableClipboard");
  if (cfg.headerFilters) lines.push("enableHeaderFilters");
  if (cfg.showTotals) lines.push("showTotals");
  if (cfg.groupingEnabled) {
    lines.push(`enableGrouping`);
    lines.push(`rowGroupingConfig={{ field: "${cfg.groupField}", showSubtotals: ${cfg.groupSubtotals} }}`);
  }
  if (cfg.pivotEnabled) {
    lines.push(`enablePivot`);
    lines.push(`pivotConfig={{ rowField: "${cfg.pivotRowField}", columnField: "${cfg.pivotColField}", valueField: "${cfg.pivotValueField}", aggregation: "${cfg.pivotAgg}" }}`);
  }
  if (cfg.pinning) lines.push(`pinnedColumns={{ left: ["id"], right: ["actions"] }}`);
  if (cfg.columnGroups) lines.push(`columnGroups={[...]}`);
  return lines.join("\n");
}

// ─── Componente ──────────────────────────────────────────

export function CodePreview({ config }: { config: LabConfig }) {
  const [show, setShow] = useState(false);
  const [tab, setTab] = useState(0);
  const [copied, setCopied] = useState(false);

  const code = tab === 0 ? generateFullCode(config) : generatePropsOnly(config);

  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true);
    });
  };

  return (
    <Box sx={{ mt: 0 }}>
      {/* Toggle bar — estilo MUI docs */}
      <Stack
        direction="row"
        justifyContent="flex-end"
        spacing={1}
        sx={{
          p: 0.5,
          bgcolor: "#f5f5f5",
          borderRadius: show ? "0" : "0 0 8px 8px",
          borderTop: "1px solid #e0e0e0",
        }}
      >
        <Button
          size="small"
          startIcon={show ? <HideIcon /> : <CodeIcon />}
          onClick={() => setShow(!show)}
          sx={{ textTransform: "none", fontWeight: 500 }}
        >
          {show ? "Hide code" : "Show code"}
        </Button>
        {show && (
          <>
            <Tooltip title="Copiar codigo">
              <IconButton size="small" onClick={handleCopy}>
                <CopyIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </>
        )}
      </Stack>

      {/* Code panel */}
      <Collapse in={show}>
        <Box sx={{ borderTop: "1px solid #e0e0e0" }}>
          <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ px: 1, bgcolor: "#1e1e1e" }}>
            <Tab label="Completo" sx={{ color: "#aaa", "&.Mui-selected": { color: "#fff" }, textTransform: "none", minHeight: 36 }} />
            <Tab label="Solo props" sx={{ color: "#aaa", "&.Mui-selected": { color: "#fff" }, textTransform: "none", minHeight: 36 }} />
          </Tabs>
          <Box
            component="pre"
            sx={{
              m: 0,
              p: 2,
              bgcolor: "#1e1e1e",
              color: "#d4d4d4",
              fontSize: "0.8rem",
              fontFamily: "Consolas, Monaco, 'Courier New', monospace",
              overflow: "auto",
              maxHeight: 400,
              borderRadius: "0 0 8px 8px",
              // Syntax highlighting via CSS (basic)
              "& .kw": { color: "#569cd6" },
              "& .str": { color: "#ce9178" },
              "& .num": { color: "#b5cea8" },
              "& .cmt": { color: "#6a9955" },
            }}
          >
            {code}
          </Box>
        </Box>
      </Collapse>

      <Snackbar
        open={copied}
        message="Codigo copiado al portapapeles"
        autoHideDuration={2000}
        onClose={() => setCopied(false)}
      />
    </Box>
  );
}
