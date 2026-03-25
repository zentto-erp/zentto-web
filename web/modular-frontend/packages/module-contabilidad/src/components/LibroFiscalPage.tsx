"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, Stack, CircularProgress, Divider,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import AutorenewIcon from "@mui/icons-material/Autorenew";
import { useCountries } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import {
  useGenerarLibroFiscal, useLibroFiscal, useResumenLibroFiscal, type TaxBookFilter,
} from "../hooks/useFiscalTributaria";

const BOOK_TYPES = [
  { value: "PURCHASE", label: "Compras" },
  { value: "SALES", label: "Ventas" },
];

const COLUMNS: ColumnDef[] = [
  { field: "EntryDate", header: "Fecha", width: 110, sortable: true },
  { field: "DocumentNumber", header: "N. Documento", width: 140, sortable: true },
  { field: "DocumentType", header: "Tipo", width: 100, sortable: true, groupable: true },
  { field: "ThirdPartyId", header: "RIF/NIF", width: 120 },
  { field: "ThirdPartyName", header: "Razon social", flex: 1, minWidth: 180, sortable: true },
  { field: "TaxableBase", header: "Base imponible", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "ExemptAmount", header: "Exento", width: 110, type: "number", currency: "VES", aggregation: "sum" },
  { field: "TaxRate", header: "% IVA", width: 80, type: "number" },
  { field: "TaxAmount", header: "Impuesto", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  { field: "WithholdingAmount", header: "Retencion", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  { field: "TotalAmount", header: "Total", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

const RESUMEN_COLUMNS: ColumnDef[] = [
  { field: "TaxRate", header: "Tasa (%)", width: 100, type: "number" },
  { field: "TaxableBase", header: "Base Imponible", width: 160, type: "number", currency: "VES", aggregation: "sum" },
  { field: "TaxAmount", header: "Impuesto", width: 160, type: "number", currency: "VES", aggregation: "sum" },
  { field: "WithholdingAmount", header: "Retenciones", width: 160, type: "number", currency: "VES", aggregation: "sum" },
  { field: "EntryCount", header: "Registros", width: 110, type: "number", aggregation: "sum" },
];

export default function LibroFiscalPage() {
  const gridRef = useRef<any>(null);
  const resumenGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { data: countries = [] } = useCountries();
  const [filter, setFilter] = useState<TaxBookFilter>({ bookType: "PURCHASE", periodCode: "", countryCode: "VE", page: 1, limit: 50 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({ bookType: "PURCHASE", countryCode: "VE" });

  const generarMutation = useGenerarLibroFiscal();
  const { data: libroData, isLoading } = useLibroFiscal(filter.periodCode ? filter : null);
  const { data: resumenData } = useResumenLibroFiscal(filter.bookType, filter.periodCode, filter.countryCode);

  const rows = libroData?.rows ?? [];
  const resumenRows = resumenData?.rows ?? [];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.EntryId }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = resumenGridRef.current;
    if (!el || !registered || resumenRows.length === 0) return;
    el.columns = RESUMEN_COLUMNS;
    el.rows = resumenRows.map((r: any, idx: number) => ({ ...r, id: idx }));
  }, [resumenRows, registered]);

  const handleGenerar = async () => {
    await generarMutation.mutateAsync({ bookType: filter.bookType, periodCode: filter.periodCode, countryCode: filter.countryCode });
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Libro fiscal de compras / ventas" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <ZenttoFilterPanel
          filters={[
            { field: "bookType", label: "Tipo", type: "select", options: BOOK_TYPES.map((t) => ({ value: t.value, label: t.label })) },
            { field: "periodCode", label: "Periodo (YYYY-MM)", type: "text", placeholder: "2026-03", minWidth: 160 },
            { field: "countryCode", label: "Pais", type: "select", options: countries.map((c) => ({ value: c.CountryCode, label: c.CountryName })) },
          ] as FilterFieldDef[]}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({ ...f, bookType: vals.bookType || "PURCHASE", periodCode: vals.periodCode || "", countryCode: vals.countryCode || "VE" }));
          }}
          searchPlaceholder="Buscar en libro fiscal..."
          searchValue={search}
          onSearchChange={setSearch}
          defaultOpen
          hideToggle
        />
        <Stack direction="row" spacing={2} mb={2} alignItems="center">
          <Button variant="contained" onClick={handleGenerar} disabled={!filter.periodCode || generarMutation.isPending}
            startIcon={generarMutation.isPending ? <CircularProgress size={16} /> : <AutorenewIcon />}>Generar libro</Button>
          <Button variant="outlined" startIcon={<FileDownloadIcon />} disabled={rows.length === 0}>Exportar</Button>
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="libro-fiscal"
            height="100%"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
          ></zentto-grid>
        </Paper>

        {resumenRows.length > 0 && (
          <Paper sx={{ mt: 3, p: 2, border: "1px solid #E5E7EB" }}>
            <Typography variant="h6" fontWeight={600} mb={1}>Resumen por tasa impositiva</Typography>
            <Divider sx={{ mb: 2 }} />
            <Box sx={{ height: 200 }}>
              <zentto-grid
                ref={resumenGridRef}
                default-currency="VES"
                height="100%"
                show-totals
                enable-toolbar
                enable-header-menu
                enable-header-filters
                enable-clipboard
                enable-quick-search
                enable-context-menu
                enable-status-bar
                enable-configurator
              ></zentto-grid>
            </Box>
          </Paper>
        )}
      </Box>
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
