"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Tab,
  Tabs,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from "@mui/material";
import { type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import PublishIcon from "@mui/icons-material/Publish";
import CheckIcon from "@mui/icons-material/Check";
import IconButton from "@mui/material/IconButton";
import { formatCurrency, useCountries } from "@zentto/shared-api";
import {
  useObligationsList,
  useSaveObligation,
  useFilingsList,
  useGenerateFiling,
  useMarkFiled,
  type ObligationsFilter,
  type FilingsFilter,
  type SaveObligationInput,
  type GenerateFilingInput,
} from "../hooks/useRRHH";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

export default function ObligacionesPage() {
  const { data: countries = [] } = useCountries();
  const [tab, setTab] = useState(0);
  const [oblFilter, setOblFilter] = useState<ObligationsFilter>({ page: 1, limit: 25 });
  const [filFilter, setFilFilter] = useState<FilingsFilter>({ page: 1, limit: 25 });
  const [oblDialogOpen, setOblDialogOpen] = useState(false);
  const [filDialogOpen, setFilDialogOpen] = useState(false);
  const [oblForm, setOblForm] = useState<SaveObligationInput>({
    code: "", name: "", countryCode: "", employeeRate: 0, employerRate: 0, frequency: "MENSUAL",
  });
  const [filForm, setFilForm] = useState<GenerateFilingInput>({
    obligationCode: "", periodFrom: "", periodTo: "",
  });

  const { data: oblData, isLoading: oblLoading } = useObligationsList(oblFilter);
  const { data: filData, isLoading: filLoading } = useFilingsList(filFilter);
  const saveOblMutation = useSaveObligation();
  const generateFilMutation = useGenerateFiling();
  const markFiledMutation = useMarkFiled();

  const oblRows = oblData?.data ?? oblData?.rows ?? [];
  const filRows = filData?.data ?? filData?.rows ?? [];

  const oblColumns: GridColDef[] = [
    { field: "countryCode", headerName: "País", width: 80 },
    { field: "code", headerName: "Código", width: 120 },
    { field: "name", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "employeeRate", headerName: "% Empleado", width: 120, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "employerRate", headerName: "% Patronal", width: 120, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "frequency", headerName: "Frecuencia", width: 120 },
    { field: "entity", headerName: "Entidad", width: 150 },
  ];

  const filColumns: GridColDef[] = [
    { field: "period", headerName: "Período", width: 150 },
    { field: "obligationName", headerName: "Obligación", flex: 1, minWidth: 200 },
    { field: "employeeAmount", headerName: "Monto Empleado", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0) },
    { field: "employerAmount", headerName: "Monto Patronal", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0) },
    { field: "totalAmount", headerName: "Total", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
    {
      field: "status",
      headerName: "Estado",
      width: 130,
      renderCell: (p) => (
        <Chip
          label={
            p.value === "PRESENTADA" ? "Presentada" :
            p.value === "GENERADA" ? "Generada" : "Pendiente"
          }
          size="small"
          color={
            p.value === "PRESENTADA" ? "success" :
            p.value === "GENERADA" ? "info" : "warning"
          }
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          {p.row.status === "PENDIENTE" && (
            <IconButton
              size="small"
              color="primary"
              title="Generar"
              onClick={() => {
                setFilForm({ obligationCode: p.row.obligationCode, periodFrom: "", periodTo: "" });
                setFilDialogOpen(true);
              }}
            >
              <PublishIcon fontSize="small" />
            </IconButton>
          )}
          {p.row.status !== "PRESENTADA" && (
            <IconButton
              size="small"
              color="success"
              title="Marcar Presentada"
              onClick={() => markFiledMutation.mutate({ filingId: p.row.id })}
            >
              <CheckIcon fontSize="small" />
            </IconButton>
          )}
        </Stack>
      ),
    },
  ];

  const handleSaveObligation = async () => {
    await saveOblMutation.mutateAsync(oblForm);
    setOblDialogOpen(false);
    setOblForm({ code: "", name: "", countryCode: "", employeeRate: 0, employerRate: 0, frequency: "MENSUAL" });
  };

  const handleGenerateFiling = async () => {
    await generateFilMutation.mutateAsync(filForm);
    setFilDialogOpen(false);
    setFilForm({ obligationCode: "", periodFrom: "", periodTo: "" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Obligaciones Legales</Typography>
        <Stack direction="row" spacing={1}>
          {tab === 0 && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOblDialogOpen(true)}>
              Nueva Obligación
            </Button>
          )}
          {tab === 1 && (
            <Button variant="contained" startIcon={<PublishIcon />} onClick={() => setFilDialogOpen(true)}>
              Generar Declaración
            </Button>
          )}
        </Stack>
      </Stack>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
        <Tab label="Obligaciones" />
        <Tab label="Declaraciones" />
      </Tabs>

      {/* Tab: Obligaciones (Catálogo) */}
      <TabPanel value={tab} index={0}>
        <Stack direction="row" spacing={2} mb={2}>
          <TextField
            label="Buscar"
            size="small"
            value={oblFilter.search || ""}
            onChange={(e) => setOblFilter((f) => ({ ...f, search: e.target.value }))}
          />
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>País</InputLabel>
            <Select
              value={oblFilter.countryCode || ""}
              label="País"
              onChange={(e) => setOblFilter((f) => ({ ...f, countryCode: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              {countries.map(c => (
                <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Frecuencia</InputLabel>
            <Select
              value={oblFilter.frequency || ""}
              label="Frecuencia"
              onChange={(e) => setOblFilter((f) => ({ ...f, frequency: e.target.value || undefined }))}
            >
              <MenuItem value="">Todas</MenuItem>
              <MenuItem value="MENSUAL">Mensual</MenuItem>
              <MenuItem value="TRIMESTRAL">Trimestral</MenuItem>
              <MenuItem value="ANUAL">Anual</MenuItem>
            </Select>
          </FormControl>
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={oblRows}
            columns={oblColumns}
            loading={oblLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.id ?? r.code}
            mobileVisibleFields={['code', 'name']}
            smExtraFields={['frequency', 'countryCode']}
          />
        </Paper>
      </TabPanel>

      {/* Tab: Declaraciones (Filings) */}
      <TabPanel value={tab} index={1}>
        <Stack direction="row" spacing={2} mb={2}>
          <TextField
            label="Buscar"
            size="small"
            value={filFilter.search || ""}
            onChange={(e) => setFilFilter((f) => ({ ...f, search: e.target.value }))}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filFilter.status || ""}
              label="Estado"
              onChange={(e) => setFilFilter((f) => ({ ...f, status: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="PENDIENTE">Pendiente</MenuItem>
              <MenuItem value="GENERADA">Generada</MenuItem>
              <MenuItem value="PRESENTADA">Presentada</MenuItem>
            </Select>
          </FormControl>
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={filRows}
            columns={filColumns}
            loading={filLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.id ?? `${r.obligationCode}-${r.period}`}
            mobileVisibleFields={['period', 'obligationName']}
            smExtraFields={['totalAmount', 'status']}
          />
        </Paper>
      </TabPanel>

      {/* New Obligation Dialog */}
      <Dialog open={oblDialogOpen} onClose={() => setOblDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Obligación Legal</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Código"
              fullWidth
              value={oblForm.code}
              onChange={(e) => setOblForm((f) => ({ ...f, code: e.target.value }))}
            />
            <TextField
              label="Nombre"
              fullWidth
              value={oblForm.name}
              onChange={(e) => setOblForm((f) => ({ ...f, name: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>País</InputLabel>
              <Select
                value={oblForm.countryCode}
                label="País"
                onChange={(e) => setOblForm((f) => ({ ...f, countryCode: e.target.value }))}
              >
                {countries.map(c => (
                  <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="% Empleado"
              type="number"
              fullWidth
              value={oblForm.employeeRate || ""}
              onChange={(e) => setOblForm((f) => ({ ...f, employeeRate: Number(e.target.value) }))}
            />
            <TextField
              label="% Patronal"
              type="number"
              fullWidth
              value={oblForm.employerRate || ""}
              onChange={(e) => setOblForm((f) => ({ ...f, employerRate: Number(e.target.value) }))}
            />
            <FormControl fullWidth>
              <InputLabel>Frecuencia</InputLabel>
              <Select
                value={oblForm.frequency || "MENSUAL"}
                label="Frecuencia"
                onChange={(e) => setOblForm((f) => ({ ...f, frequency: e.target.value }))}
              >
                <MenuItem value="MENSUAL">Mensual</MenuItem>
                <MenuItem value="TRIMESTRAL">Trimestral</MenuItem>
                <MenuItem value="ANUAL">Anual</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Descripción"
              fullWidth
              multiline
              rows={2}
              value={oblForm.description || ""}
              onChange={(e) => setOblForm((f) => ({ ...f, description: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOblDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSaveObligation} disabled={saveOblMutation.isPending}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Generate Filing Dialog */}
      <Dialog open={filDialogOpen} onClose={() => setFilDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Generar Declaración</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Código Obligación"
              fullWidth
              value={filForm.obligationCode}
              onChange={(e) => setFilForm((f) => ({ ...f, obligationCode: e.target.value }))}
            />
            <DatePicker
              label="Período Desde"
              value={filForm.periodFrom ? dayjs(filForm.periodFrom) : null}
              onChange={(v) => setFilForm((f) => ({ ...f, periodFrom: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <DatePicker
              label="Período Hasta"
              value={filForm.periodTo ? dayjs(filForm.periodTo) : null}
              onChange={(v) => setFilForm((f) => ({ ...f, periodTo: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFilDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleGenerateFiling} disabled={generateFilMutation.isPending}>
            Generar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
