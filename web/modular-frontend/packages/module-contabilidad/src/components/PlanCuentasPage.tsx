"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Stack,
  CircularProgress,
  Alert,
  InputAdornment,
} from "@mui/material";
import { type GridColDef } from "@mui/x-data-grid";
import SearchIcon from "@mui/icons-material/Search";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import { usePlanCuentas } from "../hooks/useContabilidad";

export default function PlanCuentasPage() {
  const [search, setSearch] = useState("");
  const { data, isLoading, error } = usePlanCuentas({ search: search || undefined });

  const rows = data?.data ?? [];

  const columns: GridColDef[] = [
    { field: "codCuenta", headerName: "Código", width: 150 },
    { field: "descripcion", headerName: "Descripción", flex: 1, minWidth: 250 },
    { field: "tipo", headerName: "Tipo", width: 120 },
    { field: "nivel", headerName: "Nivel", width: 80, type: "number" },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          placeholder="Buscar cuenta..."
          size="small"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ minWidth: 300 }}
        />
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar cuentas</Alert>}

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        {isLoading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : (
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            pageSizeOptions={[25, 50, 100]}
            disableRowSelectionOnClick
            getRowId={(r) => r.codCuenta ?? r.cod_cuenta ?? r.COD_CUENTA ?? Math.random()}
            mobileVisibleFields={['codCuenta', 'descripcion']}
            smExtraFields={['tipo']}
          />
        )}
      </Paper>
    </Box>
  );
}
