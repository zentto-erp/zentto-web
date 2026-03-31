// components/EtiquetasPage.tsx
"use client";

import { useState, useCallback, useRef, useEffect, useMemo } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  Typography,
  InputAdornment,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import PrintIcon from "@mui/icons-material/Print";
import SearchIcon from "@mui/icons-material/Search";
import { useInventarioList } from "../hooks/useInventario";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";
import type { ColumnDef } from "@zentto/datagrid-core";
import { debounce } from "lodash";

interface EtiquetaItem {
  codigo: string;
  descripcion: string;
  precio: number;
  barra: string;
  cantidad: number;
}

const SEARCH_GRID_ID = "module-inventario:etiquetas:search";
const SELECTED_GRID_ID = "module-inventario:etiquetas:selected";

const SEARCH_COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 110, sortable: true },
  { field: "articulo", header: "Articulo", flex: 1, minWidth: 150, sortable: true },
  { field: "precio", header: "Precio", width: 100, type: "number", currency: "VES" },
  {
    field: "actions", header: "", type: "actions", width: 60,
    actions: [
      { icon: "add", label: "Agregar articulo", action: "add", color: "#1976d2" },
    ],
  },
];

const SELECTED_COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 100 },
  { field: "descripcion", header: "Articulo", flex: 1, minWidth: 150 },
  { field: "precio", header: "Precio", width: 100, type: "number", currency: "VES" },
  { field: "cantidad", header: "Cant.", width: 80, type: "number" },
  {
    field: "actions", header: "", type: "actions", width: 60,
    actions: [
      { icon: "delete", label: "Quitar articulo", action: "remove", color: "#dc2626" },
    ],
  },
];

export default function EtiquetasPage() {
  const searchGridRef = useRef<any>(null);
  const selectedGridRef = useRef<any>(null);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<EtiquetaItem[]>([]);

  const { data: inventario, isLoading } = useInventarioList({ search, limit: 50 });
  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const { ready: searchReady } = useGridLayoutSync(SEARCH_GRID_ID);
  const { ready: selectedReady } = useGridLayoutSync(SELECTED_GRID_ID);
  const layoutReady = searchReady && selectedReady;
  const { registered } = useInventarioGridRegistration(layoutReady);

  const debouncedSearch = useCallback(
    debounce((value: string) => setSearch(value), 500),
    []
  );

  const searchGridRows = useMemo(() => rows.map((item, i) => ({
    id: i,
    codigo: String(item.CODIGO ?? ""),
    articulo: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
    precio: Number(item.PRECIO_VENTA ?? 0),
    _alreadyAdded: selected.some((s) => s.codigo === String(item.CODIGO ?? "")),
  })), [rows, selected]);

  const selectedGridRows = useMemo(() => selected.map((s, i) => ({
    id: i,
    codigo: s.codigo,
    descripcion: s.descripcion,
    precio: s.precio,
    cantidad: s.cantidad,
  })), [selected]);

  // Search grid
  useEffect(() => {
    const el = searchGridRef.current;
    if (!el || !registered) return;
    el.columns = SEARCH_COLUMNS;
    el.rows = searchGridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [searchGridRows, isLoading, registered]);

  useEffect(() => {
    const el = searchGridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "add" && row) {
        const codigo = String(row.codigo ?? "");
        if (selected.some((s) => s.codigo === codigo)) return;
        const item = rows.find((r) => String(r.CODIGO ?? "") === codigo);
        if (!item) return;
        setSelected((prev) => [
          ...prev,
          {
            codigo,
            descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
            precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
            barra: String(item.Barra ?? item.CODIGO ?? ""),
            cantidad: 1,
          },
        ]);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows, selected]);

  // Selected grid
  useEffect(() => {
    const el = selectedGridRef.current;
    if (!el || !registered) return;
    el.columns = SELECTED_COLUMNS;
    el.rows = selectedGridRows;
    el.loading = false;
    el.getRowId = (r: any) => r.id;
  }, [selectedGridRows, registered]);

  useEffect(() => {
    const el = selectedGridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "remove" && row) {
        setSelected((prev) => prev.filter((s) => s.codigo !== row.codigo));
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, selectedGridRows]);

  const handlePrint = () => {
    setTimeout(() => {
      window.print();
    }, 300);
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Screen content (hidden when printing) */}
      <Box className="no-print">
        <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, display: "flex", alignItems: "center", gap: 1 }}>
          <LocalOfferIcon /> Generador de Etiquetas
        </Typography>

        <Grid container spacing={3}>
          {/* Left: Search & add items */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Buscar Articulos</Typography>
              <TextField
                placeholder="Buscar por codigo o nombre..."
                onChange={(e) => debouncedSearch(e.target.value)}
                fullWidth
                sx={{ mb: 2 }}
                InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
              />

              {isLoading && <CircularProgress size={24} />}

              {!isLoading && search && rows.length > 0 && (
                <zentto-grid
                  ref={searchGridRef}
                  grid-id={SEARCH_GRID_ID}
                  height="300px"
                  enable-header-filters
                  enable-quick-search
                  enable-toolbar
                  enable-header-menu
                  enable-clipboard
                  enable-context-menu
                  enable-status-bar
                  enable-configurator
                />
              )}
            </Paper>
          </Grid>

          {/* Right: Selected items */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Paper sx={{ p: 2 }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
                <Typography variant="subtitle1" fontWeight={600}>
                  Etiquetas a Imprimir ({selected.reduce((acc, s) => acc + s.cantidad, 0)})
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<PrintIcon />}
                  onClick={handlePrint}
                  disabled={selected.length === 0}
                  size="small"
                >
                  Imprimir
                </Button>
              </Box>

              {selected.length === 0 ? (
                <Typography variant="body2" color="text.secondary" sx={{ py: 3, textAlign: "center" }}>
                  Agregue articulos desde la busqueda para generar etiquetas
                </Typography>
              ) : (
                <zentto-grid
                  ref={selectedGridRef}
                  grid-id={SELECTED_GRID_ID}
                  height="300px"
                  enable-status-bar
                  enable-quick-search
                  enable-header-filters
                  enable-configurator
                  enable-toolbar
                  enable-header-menu
                  enable-clipboard
                  enable-context-menu
                />
              )}
            </Paper>
          </Grid>
        </Grid>
      </Box>

      {/* Print layout */}
      <Box
        className="print-only"
        sx={{
          display: "none",
          "@media print": {
            display: "flex",
            flexWrap: "wrap",
            gap: "8px",
            padding: "4mm",
          },
        }}
      >
        {selected.flatMap((item) =>
          Array.from({ length: item.cantidad }, (_, i) => (
            <Box
              key={`${item.codigo}-${i}`}
              sx={{
                "@media print": {
                  width: "60mm",
                  height: "30mm",
                  border: "1px solid #000",
                  borderRadius: "4px",
                  padding: "3mm",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                  pageBreakInside: "avoid",
                  fontSize: "9pt",
                },
              }}
            >
              <Box sx={{ "@media print": { fontWeight: "bold", fontSize: "8pt", lineHeight: 1.2, overflow: "hidden", maxHeight: "10mm" } }}>
                {item.descripcion}
              </Box>
              <Box sx={{ "@media print": { display: "flex", justifyContent: "space-between", alignItems: "flex-end" } }}>
                <Box sx={{ "@media print": { fontSize: "7pt", color: "#666" } }}>
                  {item.codigo}
                  {item.barra && item.barra !== item.codigo && (
                    <Box component="span" sx={{ "@media print": { display: "block" } }}>
                      {item.barra}
                    </Box>
                  )}
                </Box>
                <Box sx={{ "@media print": { fontWeight: "bold", fontSize: "12pt" } }}>
                  {formatCurrency(item.precio)}
                </Box>
              </Box>
            </Box>
          ))
        )}
      </Box>

      {/* Print styles */}
      <style jsx global>{`
        @media print {
          .no-print { display: none !important; }
          .print-only { display: flex !important; }
          @page { margin: 5mm; }
        }
      `}</style>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
