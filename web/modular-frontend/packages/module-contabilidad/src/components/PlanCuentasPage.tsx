"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Stack,
  CircularProgress,
  Alert,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { usePlanCuentas } from "../hooks/useContabilidad";

const PLAN_CUENTAS_FILTERS: FilterFieldDef[] = [
  { field: "tipo", label: "Tipo", type: "select", options: [
    { value: "A", label: "Acreedor" },
    { value: "D", label: "Deudor" },
  ]},
  { field: "nivel", label: "Nivel", type: "select", options: [
    { value: "1", label: "Nivel 1" },
    { value: "2", label: "Nivel 2" },
    { value: "3", label: "Nivel 3" },
  ]},
];

export default function PlanCuentasPage() {
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const { data, isLoading, error } = usePlanCuentas({ search: search || undefined });

  const rows = data?.data ?? [];

  const columns: ZenttoColDef[] = [
    { field: "codCuenta", headerName: "Código", width: 150 },
    { field: "descripcion", headerName: "Descripción", flex: 1, minWidth: 250 },
    { field: "tipo", headerName: "Tipo", width: 120 },
    { field: "nivel", headerName: "Nivel", width: 80, type: "number" },
  ];

  // Client-side filter by tipo/nivel since the API may not support it
  const filteredRows = React.useMemo(() => {
    let result = rows;
    if (filterValues.tipo) {
      result = result.filter((r: any) => r.tipo === filterValues.tipo);
    }
    if (filterValues.nivel) {
      result = result.filter((r: any) => String(r.nivel) === filterValues.nivel);
    }
    return result;
  }, [rows, filterValues]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ZenttoFilterPanel
        filters={PLAN_CUENTAS_FILTERS}
        values={filterValues}
        onChange={setFilterValues}
        searchPlaceholder="Buscar cuenta..."
        searchValue={search}
        onSearchChange={setSearch}
      />

      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar cuentas</Alert>}

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        {isLoading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : (
          <ZenttoDataGrid
            gridId="contabilidad-plan-cuentas-list"
            rows={filteredRows}
            columns={columns}
            pageSizeOptions={[25, 50, 100]}
            disableRowSelectionOnClick
            getRowId={(r) => r.codCuenta ?? r.cod_cuenta ?? r.COD_CUENTA ?? Math.random()}
            mobileVisibleFields={['codCuenta', 'descripcion']}
            smExtraFields={['tipo']}
            enableGrouping
            enableClipboard
            enableHeaderFilters
          />
        )}
      </Paper>
    </Box>
  );
}
