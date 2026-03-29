"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Chip,
  CircularProgress,
} from "@mui/material";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { formatDateTime, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useFiscalRecords, type FiscalRecordFilter } from "../hooks/useAuditoria";
import type { ColumnDef } from "@zentto/datagrid-core";
import { buildAuditoriaGridId, useAuditoriaGridRegistration } from "./zenttoGridPersistence";


const FISCAL_FILTERS: FilterFieldDef[] = [
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
];

const GRID_ID = buildAuditoriaGridId("fiscal-records", "list");

export default function FiscalRecordsPage() {
  const { timeZone } = useTimezone();
  const [filter, setFilter] = useState<FiscalRecordFilter>({ page: 1, limit: 25 });
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useAuditoriaGridRegistration(layoutReady);

const { data, isLoading } = useFiscalRecords(filter);

  const rows = data?.data ?? [];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "FiscalRecordId", header: "ID", width: 70 },
    {
      field: "CreatedAt",
      header: "Fecha",
      width: 160,
      renderCell: (value: unknown) => (value ? formatDateTime(value as string, { timeZone }) : "-"),
    },
    { field: "InvoiceNumber", header: "N° Factura", width: 140 },
    { field: "InvoiceType", header: "Tipo", width: 100 },
    { field: "CountryCode", header: "País", width: 70 },
    {
      field: "RecordHash",
      header: "Hash",
      width: 180,
      renderCell: ((value: unknown) => (
        <span style={{ fontFamily: "monospace", fontSize: "0.75rem" }}>
          {value ? String(value).substring(0, 20) + "..." : "-"}
        </span>
      )) as unknown as ColumnDef["renderCell"],
    },
    {
      field: "SentToAuthority",
      header: "Enviado",
      width: 100,
      renderCell: ((value: unknown) => (
        <Chip
          label={value ? "Sí" : "No"}
          size="small"
          color={value ? "success" : "default"}
          variant="outlined"
        />
      )) as unknown as ColumnDef["renderCell"],
    },
    {
      field: "AuthorityStatus",
      header: "Estado",
      width: 120,
      renderCell: ((value: unknown) => (
        <Chip
          label={(value as string) ?? "N/A"}
          size="small"
          color={value === "ACCEPTED" ? "success" : value === "REJECTED" ? "error" : "default"}
          variant="outlined"
        />
      )) as unknown as ColumnDef["renderCell"],
    },
    {
      field: "actions",
      header: "Acciones",
      type: "actions",
      width: 80,
      pin: "right",
      actions: [
        { icon: "view", label: "Ver detalle", action: "view", color: "#6b7280" },
      ],
    },
  ];

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") { /* TODO: ver detalle registro fiscal */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Registros Fiscales" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <ZenttoFilterPanel
          filters={FISCAL_FILTERS}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              fechaDesde: vals.fechaDesde || undefined,
              fechaHasta: vals.fechaHasta || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar registros fiscales..."
          searchValue=""
          onSearchChange={() => {}}
        />

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
        grid-id={GRID_ID}
        ref={gridRef}
        export-filename="auditoria-fiscal-records-list"
        height="calc(100vh - 280px)"
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
