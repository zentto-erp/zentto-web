// components/KardexPage.tsx
"use client";

import { useState, useRef, useEffect } from "react";
import {
  Box, TextField, Typography, Stack, Chip, Paper,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import InputAdornment from "@mui/material/InputAdornment";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useKardex } from "../hooks/useConteoAlbaranes";
import { formatCurrency } from "@zentto/shared-api";

const MOVTYPE_COLORS: Record<string, string> = {
  PURCHASE_IN:    "success",
  SALE_OUT:       "error",
  TRANSFER_IN:    "info",
  TRANSFER_OUT:   "warning",
  ADJUSTMENT_IN:  "success",
  ADJUSTMENT_OUT: "error",
  ENTRADA:        "success",
  SALIDA:         "error",
  TRASLADO:       "info",
  AJUSTE:         "default",
};

const GRID_ID = "module-inventario:kardex:list";

const COLUMNS: ColumnDef[] = [
  { field: "FechaMovimiento",      header: "Fecha",          width: 120 },
  { field: "TipoMovimiento",       header: "Tipo",           width: 140,
    statusColors: MOVTYPE_COLORS, statusVariant: "outlined" },
  { field: "Cantidad",             header: "Cantidad",       width: 100, type: "number" },
  { field: "CostoUnitario",        header: "Costo Unit.",    width: 130, type: "number", currency: "VES" },
  { field: "SaldoAcumulado",       header: "Saldo",          width: 110, type: "number" },
  { field: "Referencia",           header: "Referencia",     width: 130 },
  { field: "TipoDocumentoOrigen",  header: "Documento",      width: 130 },
  { field: "Notas",                header: "Notas",          flex: 1, minWidth: 150 },
];

export default function KardexPage() {
  const gridRef = useRef<any>(null);
  const [search, setSearch]     = useState("");
  const [codigo, setCodigo]     = useState("");
  const [fechaDesde, setDesde]  = useState("");
  const [fechaHasta, setHasta]  = useState("");

  const { data, isLoading } = useKardex(codigo, {
    fechaDesde: fechaDesde || undefined,
    fechaHasta: fechaHasta || undefined,
    page: 1,
    limit: 500,
  });

  const rows = (data?.rows ?? []).map((r, i) => ({
    ...r,
    id: i,
    FechaMovimiento: r.FechaMovimiento?.slice(0, 10) ?? "",
  }));

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading]);

  function handleSearch() {
    setCodigo(search.trim());
  }

  return (
    <Box sx={{ p: 2 }}>
      <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} mb={2} alignItems="flex-end">
        <TextField
          size="small"
          label="Código de artículo"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSearch()}
          InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon /></InputAdornment> }}
          sx={{ minWidth: 200 }}
        />
        <TextField size="small" label="Desde" type="date" value={fechaDesde} onChange={(e) => setDesde(e.target.value)} InputLabelProps={{ shrink: true }} />
        <TextField size="small" label="Hasta" type="date" value={fechaHasta} onChange={(e) => setHasta(e.target.value)} InputLabelProps={{ shrink: true }} />
      </Stack>

      {codigo && (
        <Paper variant="outlined" sx={{ p: 1.5, mb: 2, display: "flex", gap: 2, alignItems: "center", flexWrap: "wrap" }}>
          <Typography variant="body2"><strong>Artículo:</strong> {codigo}</Typography>
          {data && (
            <>
              <Chip size="small" label={`${data.total} movimientos`} />
              <Chip size="small" color="primary" label={`Saldo actual: ${rows[rows.length - 1]?.SaldoAcumulado ?? "—"}`} />
            </>
          )}
        </Paper>
      )}

      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="520px"
        enable-toolbar
        enable-header-filters
        enable-status-bar
        enable-quick-search
        export-filename="kardex"
      />
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
