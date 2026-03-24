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
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import PublishIcon from "@mui/icons-material/Publish";
import CheckIcon from "@mui/icons-material/Check";
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

const OBL_FILTERS: FilterFieldDef[] = [
  {
    field: "frequency", label: "Frecuencia", type: "select",
    options: [
      { value: "MENSUAL", label: "Mensual" },
      { value: "TRIMESTRAL", label: "Trimestral" },
      { value: "ANUAL", label: "Anual" },
    ],
  },
];

const FILING_FILTERS: FilterFieldDef[] = [
  {
    field: "status", label: "Estado", type: "select",
    options: [
      { value: "PENDIENTE", label: "Pendiente" },
      { value: "GENERADA", label: "Generada" },
      { value: "PRESENTADA", label: "Presentada" },
    ],
  },
];

export default function ObligacionesPage() {
  const { data: countries = [] } = useCountries();
  const [oblSearch, setOblSearch] = useState("");
  const [oblFilterValues, setOblFilterValues] = useState<Record<string, string>>({});
  const [filSearch, setFilSearch] = useState("");
  const [filFilterValues, setFilFilterValues] = useState<Record<string, string>>({});
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

  const oblColumns: ZenttoColDef[] = [
    { field: "CountryCode", headerName: "País", width: 80 },
    { field: "Code", headerName: "Código", width: 120 },
    { field: "Name", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "EmployeeRate", headerName: "% Empleado", width: 120, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "EmployerRate", headerName: "% Patronal", width: 120, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "FilingFrequency", headerName: "Frecuencia", width: 120 },
    { field: "InstitutionName", headerName: "Entidad", width: 150 },
  ];

  const filColumns: ZenttoColDef[] = [
    { field: "period", headerName: "Período", width: 150 },
    { field: "obligationName", headerName: "Obligación", flex: 1, minWidth: 200 },
    { field: "employeeAmount", headerName: "Monto Empleado", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
    { field: "employerAmount", headerName: "Monto Patronal", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
    { field: "totalAmount", headerName: "Total", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
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
            <Tooltip title="Generar declaracion">
              <IconButton
                size="small"
                color="primary"
                onClick={() => {
                  setFilForm({ obligationCode: p.row.obligationCode, periodFrom: "", periodTo: "" });
                  setFilDialogOpen(true);
                }}
              >
                <PublishIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          {p.row.status !== "PRESENTADA" && (
            <Tooltip title="Marcar como presentada">
              <IconButton
                size="small"
                color="success"
                onClick={() => markFiledMutation.mutate({ filingId: p.row.id })}
              >
                <CheckIcon fontSize="small" />
              </IconButton>
            </Tooltip>
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
        <ZenttoFilterPanel
          filters={OBL_FILTERS}
          values={oblFilterValues}
          onChange={(v) => {
            setOblFilterValues(v);
            setOblFilter((f) => ({ ...f, frequency: v.frequency || undefined }));
          }}
          searchPlaceholder="Buscar obligaciones..."
          searchValue={oblSearch}
          onSearchChange={(v) => {
            setOblSearch(v);
            setOblFilter((f) => ({ ...f, search: v || undefined }));
          }}
        />

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            gridId="nomina-obligaciones-list"
            rows={oblRows}
            columns={oblColumns}
            loading={oblLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.LegalObligationId ?? r.Code}
            enableGrouping
            enableClipboard
            enableHeaderFilters
            mobileVisibleFields={['Code', 'Name']}
            smExtraFields={['FilingFrequency', 'CountryCode']}
          />
        </Paper>
      </TabPanel>

      {/* Tab: Declaraciones (Filings) */}
      <TabPanel value={tab} index={1}>
        <ZenttoFilterPanel
          filters={FILING_FILTERS}
          values={filFilterValues}
          onChange={(v) => {
            setFilFilterValues(v);
            setFilFilter((f) => ({ ...f, status: v.status || undefined }));
          }}
          searchPlaceholder="Buscar declaraciones..."
          searchValue={filSearch}
          onSearchChange={(v) => {
            setFilSearch(v);
            setFilFilter((f) => ({ ...f, search: v || undefined }));
          }}
        />

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            gridId="nomina-obligaciones-filing"
            rows={filRows}
            columns={filColumns}
            loading={filLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.id ?? `${r.obligationCode}-${r.period}`}
            showTotals
            totalsLabel="Total"
            enableGrouping
            enableClipboard
            enableHeaderFilters
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
