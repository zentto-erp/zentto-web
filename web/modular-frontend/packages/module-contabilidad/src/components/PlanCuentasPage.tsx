"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, CircularProgress, Alert,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { usePlanCuentas } from "../hooks/useContabilidad";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";

const PLAN_CUENTAS_FILTERS: FilterFieldDef[] = [
  { field: "tipo", label: "Tipo", type: "select", options: [
    { value: "A", label: "Acreedor" }, { value: "D", label: "Deudor" },
  ]},
  { field: "nivel", label: "Nivel", type: "select", options: [
    { value: "1", label: "Nivel 1" }, { value: "2", label: "Nivel 2" }, { value: "3", label: "Nivel 3" },
  ]},
];

const COLUMNS: ColumnDef[] = [
  { field: "codCuenta", header: "Codigo", width: 150, sortable: true },
  { field: "descripcion", header: "Descripcion", flex: 1, minWidth: 250, sortable: true },
  { field: "tipo", header: "Tipo", width: 120, sortable: true, groupable: true },
  { field: "nivel", header: "Nivel", width: 80, type: "number", sortable: true },
];

const GRID_IDS = {
  gridRef: buildContabilidadGridId("plan-cuentas", "main"),
} as const;

export default function PlanCuentasPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const { data, isLoading, error } = usePlanCuentas({ search: search || undefined });

  const rows = data?.data ?? [];

  const filteredRows = React.useMemo(() => {
    let result = rows;
    if (filterValues.tipo) result = result.filter((r: any) => r.tipo === filterValues.tipo);
    if (filterValues.nivel) result = result.filter((r: any) => String(r.nivel) === filterValues.nivel);
    return result;
  }, [rows, filterValues]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = filteredRows.map((r: any) => ({ ...r, id: r.codCuenta ?? r.cod_cuenta ?? r.COD_CUENTA ?? Math.random() }));
    el.loading = isLoading;
    // No actionButtons needed — read-only plan de cuentas view (use PlanCuentasPageMejorado for editing)
  }, [filteredRows, isLoading, registered]);

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ZenttoFilterPanel filters={PLAN_CUENTAS_FILTERS} values={filterValues} onChange={setFilterValues}
        searchPlaceholder="Buscar cuenta..." searchValue={search} onSearchChange={setSearch} />

      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar cuentas</Alert>}

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <zentto-grid
          ref={gridRef}
          export-filename="plan-cuentas"
          height="100%"
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
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
