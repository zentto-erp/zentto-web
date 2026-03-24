"use client";

import { useState } from "react";
import {
  Box, Typography, Button, Stack, TextField, MenuItem, Dialog,
  DialogTitle, DialogContent, DialogActions, Alert,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import { useCountries, useLookup } from "@zentto/shared-api";
import { useConceptosList, useConceptoUpsert, type ConceptoFilter } from "../hooks/useFiscalTributaria";

const columns: ZenttoColDef[] = [
  { field: "ConceptCode", headerName: "Codigo", width: 140 },
  { field: "Description", headerName: "Descripcion", flex: 1, minWidth: 200 },
  { field: "SupplierType", headerName: "Tipo Persona", width: 130 },
  { field: "ActivityCode", headerName: "Actividad", width: 130 },
  { field: "RetentionType", headerName: "Tipo Ret.", width: 100 },
  { field: "Rate", headerName: "%", width: 80, type: "number", valueFormatter: (v: number) => `${v}%` },
  { field: "SubtrahendUT", headerName: "Sustraendo UT", width: 120, type: "number" },
  { field: "MinBaseUT", headerName: "Min Base UT", width: 110, type: "number" },
  { field: "SeniatCode", headerName: "Cod SENIAT", width: 100 },
  { field: "CountryCode", headerName: "Pais", width: 60 },
];

export default function ConceptosRetencionPage() {
  const { data: countries = [] } = useCountries();
  const { data: retTypes = [] } = useLookup('RETENTION_TYPE');
  const { data: supplierTypes = [] } = useLookup('SUPPLIER_TYPE');
  const [filter, setFilter] = useState<ConceptoFilter>({ page: 1, limit: 50 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<Record<string, any>>({
    conceptCode: "", description: "", supplierType: "AMBOS", activityCode: "",
    retentionType: "ISLR", rate: 0, subtrahendUT: 0, minBaseUT: 0,
    seniatCode: "", countryCode: "VE",
  });

  const { data, isLoading } = useConceptosList(filter);
  const upsert = useConceptoUpsert();
  const rows = data?.rows ?? [];

  const handleSave = async () => {
    try {
      await upsert.mutateAsync(form as any);
      setDialogOpen(false);
    } catch { /* toast handled by mutation */ }
  };

  const handleEdit = (row: any) => {
    setForm({
      conceptCode: row.ConceptCode, description: row.Description,
      supplierType: row.SupplierType, activityCode: row.ActivityCode ?? "",
      retentionType: row.RetentionType, rate: row.Rate,
      subtrahendUT: row.SubtrahendUT, minBaseUT: row.MinBaseUT,
      seniatCode: row.SeniatCode ?? "", countryCode: row.CountryCode,
    });
    setDialogOpen(true);
  };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
        <Typography variant="h6">Conceptos de Retencion</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => {
          setForm({ conceptCode: "", description: "", supplierType: "AMBOS", activityCode: "",
            retentionType: "ISLR", rate: 0, subtrahendUT: 0, minBaseUT: 0, seniatCode: "", countryCode: "VE" });
          setDialogOpen(true);
        }}>Nuevo Concepto</Button>
      </Stack>

      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField select label="Pais" value={filter.countryCode ?? ""} sx={{ minWidth: 140 }}
          onChange={(e) => setFilter({ ...filter, countryCode: e.target.value || undefined })}>
          <MenuItem value="">Todos</MenuItem>
          {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
        </TextField>
        <TextField select label="Tipo" value={filter.retentionType ?? ""} sx={{ minWidth: 130 }}
          onChange={(e) => setFilter({ ...filter, retentionType: e.target.value || undefined })}>
          <MenuItem value="">Todos</MenuItem>
          {retTypes.map((t) => <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>)}
        </TextField>
        <TextField label="Buscar" value={filter.search ?? ""}
          onChange={(e) => setFilter({ ...filter, search: e.target.value || undefined })} />
      </Stack>

      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={isLoading}
        getRowId={(r) => r.ConceptId ?? r.ConceptCode}
        autoHeight
        onRowClick={(p) => handleEdit(p.row)}
        sx={{ "& .MuiDataGrid-row": { cursor: "pointer" } }}
        initialState={{ pagination: { paginationModel: { pageSize: 25 } } }}
        pageSizeOptions={[25, 50]}
        mobileVisibleFields={['Description', 'RetentionType']}
        smExtraFields={['Rate', 'CountryCode']}
        enableGrouping
        enableClipboard
      />

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{form.conceptCode ? "Editar Concepto" : "Nuevo Concepto"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
              <TextField label="Codigo" fullWidth value={form.conceptCode}
                onChange={(e) => setForm({ ...form, conceptCode: e.target.value })}
                disabled={!!form.conceptCode && rows.some((r: any) => r.ConceptCode === form.conceptCode)} />
              <TextField select label="Pais" value={form.countryCode} sx={{ minWidth: 120 }}
                onChange={(e) => setForm({ ...form, countryCode: e.target.value })}>
                {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
              </TextField>
            </Stack>
            <TextField label="Descripcion" fullWidth value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })} />
            <Stack direction="row" spacing={2}>
              <TextField select label="Tipo Persona" fullWidth value={form.supplierType}
                onChange={(e) => setForm({ ...form, supplierType: e.target.value })}>
                {supplierTypes.map((t) => <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>)}
              </TextField>
              <TextField label="Actividad" fullWidth value={form.activityCode}
                onChange={(e) => setForm({ ...form, activityCode: e.target.value })} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField select label="Tipo Retencion" fullWidth value={form.retentionType}
                onChange={(e) => setForm({ ...form, retentionType: e.target.value })}>
                {retTypes.map((t) => <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>)}
              </TextField>
              <TextField label="% Retencion" type="number" fullWidth value={form.rate}
                onChange={(e) => setForm({ ...form, rate: Number(e.target.value) })} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="Sustraendo (UT)" type="number" fullWidth value={form.subtrahendUT}
                onChange={(e) => setForm({ ...form, subtrahendUT: Number(e.target.value) })} />
              <TextField label="Base Minima (UT)" type="number" fullWidth value={form.minBaseUT}
                onChange={(e) => setForm({ ...form, minBaseUT: Number(e.target.value) })} />
              <TextField label="Cod SENIAT" fullWidth value={form.seniatCode}
                onChange={(e) => setForm({ ...form, seniatCode: e.target.value })} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={upsert.isPending || !form.conceptCode || !form.description}>
            {upsert.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
