"use client";

import React, { useState, useCallback } from "react";
import {
  Box, Paper, Typography, TextField, Button, IconButton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Stack,
  FormControl, InputLabel, Select, MenuItem, Alert, Tooltip,
  InputAdornment, Switch, FormControlLabel,
} from "@mui/material";
import { DataGrid, type GridColDef, type GridRenderCellParams } from "@mui/x-data-grid";
import SearchIcon from "@mui/icons-material/Search";
import EditIcon from "@mui/icons-material/Edit";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import FilterListIcon from "@mui/icons-material/FilterList";
import GroupWorkIcon from "@mui/icons-material/GroupWork";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import {
  useBatchGrid,
  useBatchBulkUpdate,
  type BatchGridFilter,
} from "../hooks/useNominaBatch";
import PayrollEmployeePanel from "./PayrollEmployeePanel";

interface Props {
  batchId: number;
}

export default function PayrollBatchGrid({ batchId }: Props) {
  const [filter, setFilter] = useState<BatchGridFilter>({ page: 1, limit: 50 });
  const [searchText, setSearchText] = useState("");
  const [selectedEmployee, setSelectedEmployee] = useState<string | null>(null);
  const [bulkOpen, setBulkOpen] = useState(false);
  const [onlyModified, setOnlyModified] = useState(false);
  const [bulkData, setBulkData] = useState({
    conceptCode: "",
    conceptName: "",
    conceptType: "ASIGNACION" as "ASIGNACION" | "DEDUCCION" | "BONO",
    amount: 0,
  });

  const grid = useBatchGrid(batchId, { ...filter, onlyModified });
  const bulkUpdate = useBatchBulkUpdate();

  const gridData = grid.data?.data ?? grid.data ?? { rows: [], total: 0 };
  const rows = Array.isArray(gridData) ? gridData : (gridData.rows ?? []);
  const totalCount = gridData.total ?? rows.length;

  const handleSearch = useCallback(() => {
    setFilter((f) => ({ ...f, search: searchText || undefined, page: 1 }));
  }, [searchText]);

  const handleBulkApply = useCallback(async () => {
    await bulkUpdate.mutateAsync({
      batchId,
      conceptCode: bulkData.conceptCode,
      conceptType: bulkData.conceptType,
      amount: bulkData.amount,
    });
    setBulkOpen(false);
  }, [batchId, bulkData, bulkUpdate]);

  const columns: GridColDef[] = [
    {
      field: "employeeCode",
      headerName: "Cédula",
      width: 110,
      renderCell: (p: GridRenderCellParams) => (
        <Typography variant="body2" sx={{ fontWeight: 600, fontFamily: "monospace" }}>
          {p.value}
        </Typography>
      ),
    },
    {
      field: "employeeName",
      headerName: "Empleado",
      flex: 1,
      minWidth: 200,
      renderCell: (p: GridRenderCellParams) => (
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <Typography variant="body2" sx={{ fontWeight: 500 }}>{p.value}</Typography>
          {p.row.isModified && (
            <Chip label="Editado" size="small" sx={{ bgcolor: brandColors.accent, color: brandColors.dark, fontWeight: 600, fontSize: 10, height: 20 }} />
          )}
          {p.row.hasAlerts && (
            <Tooltip title="Tiene alertas">
              <WarningAmberIcon sx={{ fontSize: 16, color: brandColors.statOrange }} />
            </Tooltip>
          )}
        </Box>
      ),
    },
    { field: "department", headerName: "Depto.", width: 120 },
    {
      field: "sueldoBase",
      headerName: "Sueldo Base",
      width: 130,
      renderCell: (p: GridRenderCellParams) => (
        <Typography variant="body2" sx={{ fontFamily: "monospace" }}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "totalAsignaciones",
      headerName: "Asignaciones",
      width: 130,
      renderCell: (p: GridRenderCellParams) => (
        <Typography variant="body2" sx={{ color: brandColors.success, fontWeight: 600, fontFamily: "monospace" }}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "totalDeducciones",
      headerName: "Deducciones",
      width: 130,
      renderCell: (p: GridRenderCellParams) => (
        <Typography variant="body2" sx={{ color: brandColors.danger, fontWeight: 600, fontFamily: "monospace" }}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "totalNeto",
      headerName: "Neto a Pagar",
      width: 140,
      renderCell: (p: GridRenderCellParams) => (
        <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: "monospace" }}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "lineCount",
      headerName: "Conceptos",
      width: 90,
      align: "center",
      renderCell: (p: GridRenderCellParams) => (
        <Chip label={p.value ?? 0} size="small" variant="outlined" />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 60,
      sortable: false,
      renderCell: (p: GridRenderCellParams) => (
        <Tooltip title="Editar detalle del empleado">
          <IconButton
            size="small"
            onClick={() => setSelectedEmployee(p.row.employeeCode)}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Toolbar */}
      <Paper sx={{ p: 2, mb: 2, borderRadius: 2, display: "flex", alignItems: "center", gap: 2, flexWrap: "wrap" }}>
        <TextField
          size="small"
          placeholder="Buscar por nombre o cédula..."
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSearch()}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon fontSize="small" />
              </InputAdornment>
            ),
          }}
          sx={{ minWidth: 280 }}
        />
        <Button size="small" variant="outlined" onClick={handleSearch} startIcon={<FilterListIcon />}>
          Filtrar
        </Button>

        <FormControlLabel
          control={
            <Switch
              size="small"
              checked={onlyModified}
              onChange={(e) => setOnlyModified(e.target.checked)}
            />
          }
          label={<Typography variant="body2">Solo editados</Typography>}
        />

        <Box sx={{ flexGrow: 1 }} />

        <Button
          size="small"
          variant="outlined"
          color="secondary"
          startIcon={<GroupWorkIcon />}
          onClick={() => setBulkOpen(true)}
        >
          Acción Masiva
        </Button>

        <Chip
          label={`${totalCount} empleados`}
          variant="outlined"
          size="small"
          sx={{ fontWeight: 600 }}
        />
      </Paper>

      {/* Grid */}
      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, borderRadius: 2, overflow: "hidden" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={grid.isLoading}
          pageSizeOptions={[25, 50, 100]}
          paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 50 }}
          onPaginationModelChange={(m) => setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))}
          rowCount={totalCount}
          paginationMode="server"
          disableRowSelectionOnClick
          getRowId={(r) => r.employeeCode || r.employeeId || Math.random()}
          onRowClick={(p) => setSelectedEmployee(p.row.employeeCode)}
          sx={{
            "& .MuiDataGrid-row": {
              cursor: "pointer",
              "&:hover": { bgcolor: "rgba(255,153,0,0.04)" },
            },
          }}
        />
      </Paper>

      {/* Employee Detail Panel */}
      <PayrollEmployeePanel
        batchId={batchId}
        employeeCode={selectedEmployee}
        onClose={() => setSelectedEmployee(null)}
      />

      {/* Bulk Update Dialog */}
      <Dialog open={bulkOpen} onClose={() => setBulkOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Acción Masiva</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Aplicar un concepto a todos los empleados del lote. Útil para bonos, deducciones especiales, etc.
          </Typography>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Código del Concepto"
              fullWidth
              size="small"
              value={bulkData.conceptCode}
              onChange={(e) => setBulkData((d) => ({ ...d, conceptCode: e.target.value }))}
            />
            <TextField
              label="Nombre del Concepto"
              fullWidth
              size="small"
              value={bulkData.conceptName}
              onChange={(e) => setBulkData((d) => ({ ...d, conceptName: e.target.value }))}
            />
            <FormControl fullWidth size="small">
              <InputLabel>Tipo</InputLabel>
              <Select
                value={bulkData.conceptType}
                label="Tipo"
                onChange={(e) => setBulkData((d) => ({ ...d, conceptType: e.target.value as any }))}
              >
                <MenuItem value="ASIGNACION">Asignación</MenuItem>
                <MenuItem value="DEDUCCION">Deducción</MenuItem>
                <MenuItem value="BONO">Bono</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Monto"
              type="number"
              fullWidth
              size="small"
              value={bulkData.amount}
              onChange={(e) => setBulkData((d) => ({ ...d, amount: Number(e.target.value) }))}
            />
          </Stack>
          {bulkUpdate.isError && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {String((bulkUpdate.error as Error)?.message || "Error")}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBulkOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleBulkApply}
            disabled={!bulkData.conceptCode || !bulkData.amount || bulkUpdate.isPending}
          >
            Aplicar a Todos
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
