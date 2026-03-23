"use client";

import { useState } from "react";
import {
  Box, Typography, Button, Stack, TextField, MenuItem, Dialog,
  DialogTitle, DialogContent, DialogActions,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import { useCountries } from "@zentto/shared-api";
import { useTaxUnitList, useTaxUnitUpsert } from "../hooks/useFiscalTributaria";

const columns: GridColDef[] = [
  { field: "CountryCode", headerName: "Pais", width: 80 },
  { field: "TaxYear", headerName: "Ano", width: 80 },
  { field: "UnitValue", headerName: "Valor UT", width: 120, type: "number" },
  { field: "Currency", headerName: "Moneda", width: 80 },
  { field: "EffectiveDate", headerName: "Vigente desde", width: 130, valueFormatter: (v: string) => v?.slice(0, 10) },
];

export default function UnidadTributariaPage() {
  const { data: countries = [] } = useCountries();
  const [filterCountry, setFilterCountry] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({ countryCode: "VE", taxYear: new Date().getFullYear(), unitValue: 0, currency: "VES", effectiveDate: "" });

  const { data, isLoading } = useTaxUnitList(filterCountry || undefined);
  const upsert = useTaxUnitUpsert();
  const rows = data?.rows ?? [];

  const handleSave = async () => {
    try {
      await upsert.mutateAsync(form);
      setDialogOpen(false);
    } catch { /* handled */ }
  };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
        <Typography variant="h6">Unidad Tributaria</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => {
          setForm({ countryCode: "VE", taxYear: new Date().getFullYear(), unitValue: 0, currency: "VES", effectiveDate: `${new Date().getFullYear()}-01-01` });
          setDialogOpen(true);
        }}>Nuevo Valor</Button>
      </Stack>

      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField select label="Pais" size="small" value={filterCountry} sx={{ minWidth: 150 }}
          onChange={(e) => setFilterCountry(e.target.value)}>
          <MenuItem value="">Todos</MenuItem>
          {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
        </TextField>
      </Stack>

      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={isLoading}
        getRowId={(r) => r.TaxUnitId ?? `${r.CountryCode}-${r.TaxYear}`}
        autoHeight
        onRowClick={(p) => {
          setForm({
            countryCode: p.row.CountryCode, taxYear: p.row.TaxYear,
            unitValue: p.row.UnitValue, currency: p.row.Currency,
            effectiveDate: p.row.EffectiveDate?.slice(0, 10) ?? "",
          });
          setDialogOpen(true);
        }}
        sx={{ "& .MuiDataGrid-row": { cursor: "pointer" } }}
        initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
        pageSizeOptions={[10, 25]}
        mobileVisibleFields={['CountryCode', 'UnitValue']}
        smExtraFields={['TaxYear', 'EffectiveDate']}
      />

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Valor Unidad Tributaria</DialogTitle>
        <DialogContent>
          <FormGrid spacing={2} sx={{ mt: 1 }}>
            <FormField xs={12} sm={6}>
              <TextField select label="Pais" size="small" fullWidth value={form.countryCode}
                onChange={(e) => {
                  const country = countries.find((c) => c.CountryCode === e.target.value);
                  setForm({ ...form, countryCode: e.target.value, currency: country?.CurrencyCode ?? "VES" });
                }}>
                {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
              </TextField>
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Ano" type="number" size="small" fullWidth value={form.taxYear}
                onChange={(e) => setForm({ ...form, taxYear: Number(e.target.value) })} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Valor UT" type="number" size="small" fullWidth value={form.unitValue}
                onChange={(e) => setForm({ ...form, unitValue: Number(e.target.value) })} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Moneda" size="small" fullWidth value={form.currency} disabled />
            </FormField>
            <FormField xs={12}>
              <DatePicker
                label="Vigente desde"
                value={form.effectiveDate ? dayjs(form.effectiveDate) : null}
                onChange={(v) => setForm({ ...form, effectiveDate: v ? v.format('YYYY-MM-DD') : '' })}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={upsert.isPending || !form.unitValue}>
            {upsert.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
