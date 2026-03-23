"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  MenuItem,
  Select,
  InputLabel,
  FormControl,
  Tooltip,
  CircularProgress,
  Autocomplete,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import EditIcon from "@mui/icons-material/Edit";
import AddIcon from "@mui/icons-material/Add";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useCategoriasList,
  useUpsertCategoria,
  type FixedAssetCategory,
} from "../hooks/useActivosFijos";
import { usePlanCuentas } from "../hooks/useContabilidad";

const DEPRECIATION_METHODS = [
  { value: "STRAIGHT_LINE", label: "Línea recta" },
  { value: "DOUBLE_DECLINING", label: "Doble declinación" },
  { value: "UNITS_PRODUCED", label: "Unidades producidas" },
  { value: "NONE", label: "Sin depreciación" },
];

const methodLabel = (m: string) =>
  DEPRECIATION_METHODS.find((d) => d.value === m)?.label ?? m;

interface CategoryForm {
  categoryCode: string;
  categoryName: string;
  defaultUsefulLifeMonths: number;
  defaultDepreciationMethod: string;
  defaultResidualPercent: number;
  defaultAssetAccountCode: string;
  defaultDeprecAccountCode: string;
  defaultExpenseAccountCode: string;
  countryCode: string;
}

const emptyForm: CategoryForm = {
  categoryCode: "",
  categoryName: "",
  defaultUsefulLifeMonths: 60,
  defaultDepreciationMethod: "STRAIGHT_LINE",
  defaultResidualPercent: 0,
  defaultAssetAccountCode: "",
  defaultDeprecAccountCode: "",
  defaultExpenseAccountCode: "",
  countryCode: "",
};

function formatLifespan(months: number): string {
  const years = Math.floor(months / 12);
  const rem = months % 12;
  const parts: string[] = [];
  if (years > 0) parts.push(`${years} año${years > 1 ? "s" : ""}`);
  if (rem > 0) parts.push(`${rem} mes${rem > 1 ? "es" : ""}`);
  return parts.join(" ") || "0 meses";
}

export default function CategoriasActivosPage() {
  const [openDialog, setOpenDialog] = useState(false);
  const [form, setForm] = useState<CategoryForm>({ ...emptyForm });
  const [isEditing, setIsEditing] = useState(false);

  const { data, isLoading } = useCategoriasList();
  const upsertMutation = useUpsertCategoria();
  const { data: cuentasData } = usePlanCuentas();
  const cuentas = (cuentasData?.data ?? cuentasData?.rows ?? []).map((c: any) => ({
    code: c.codCuenta ?? c.Cod_Cuenta ?? c.AccountCode ?? "",
    name: c.descripcion ?? c.Desc_Cta ?? c.AccountName ?? "",
  }));

  const rows = data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "CategoryCode", headerName: "Codigo", width: 120 },
    { field: "CategoryName", headerName: "Nombre", flex: 1, minWidth: 200 },
    {
      field: "DefaultUsefulLifeMonths",
      headerName: "Vida útil",
      width: 150,
      renderCell: (p) => formatLifespan(p.value),
    },
    {
      field: "DefaultDepreciationMethod",
      headerName: "Método dep.",
      width: 170,
      renderCell: (p) => <Chip label={methodLabel(p.value)} size="small" variant="outlined" />,
    },
    {
      field: "DefaultResidualPercent",
      headerName: "% Residual",
      width: 110,
      renderCell: (p) => `${p.value ?? 0}%`,
    },
    { field: "CountryCode", headerName: "Pais", width: 80 },
    {
      field: "acciones",
      headerName: "",
      width: 70,
      sortable: false,
      renderCell: (p) => (
        <Tooltip title="Editar">
          <IconButton size="small" onClick={() => handleEdit(p.row)}>
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ];

  const handleEdit = (row: FixedAssetCategory) => {
    setForm({
      categoryCode: row.CategoryCode,
      categoryName: row.CategoryName,
      defaultUsefulLifeMonths: row.DefaultUsefulLifeMonths,
      defaultDepreciationMethod: row.DefaultDepreciationMethod,
      defaultResidualPercent: row.DefaultResidualPercent ?? 0,
      defaultAssetAccountCode: row.DefaultAssetAccountCode ?? "",
      defaultDeprecAccountCode: row.DefaultDeprecAccountCode ?? "",
      defaultExpenseAccountCode: row.DefaultExpenseAccountCode ?? "",
      countryCode: row.CountryCode ?? "",
    });
    setIsEditing(true);
    setOpenDialog(true);
  };

  const handleNew = () => {
    setForm({ ...emptyForm });
    setIsEditing(false);
    setOpenDialog(true);
  };

  const handleSave = async () => {
    await upsertMutation.mutateAsync(form);
    setOpenDialog(false);
    setForm({ ...emptyForm });
  };

  const setField = <K extends keyof CategoryForm>(key: K, val: CategoryForm[K]) =>
    setForm((f) => ({ ...f, [key]: val }));

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Categorias de Activos Fijos"
        primaryAction={{
          label: "Nueva categoría",
          onClick: handleNew,
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(row) => row.CategoryId}
            sx={{ border: "none" }}
            mobileVisibleFields={['CategoryName', 'DefaultDepreciationMethod']}
            smExtraFields={['DefaultUsefulLifeMonths', 'CountryCode']}
          />
        </Paper>
      </Box>

      {/* Dialog Crear/Editar Categoria */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{isEditing ? "Editar categoría" : "Nueva categoría"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Codigo"
                fullWidth
               
                value={form.categoryCode}
                onChange={(e) => setField("categoryCode", e.target.value)}
                disabled={isEditing}
              />
              <TextField
                label="Nombre"
                fullWidth
               
                value={form.categoryName}
                onChange={(e) => setField("categoryName", e.target.value)}
              />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Vida útil (meses)"
                type="number"
                fullWidth
               
                value={form.defaultUsefulLifeMonths}
                onChange={(e) => setField("defaultUsefulLifeMonths", Number(e.target.value))}
              />
              <FormControl fullWidth>
                <InputLabel>Método depreciación</InputLabel>
                <Select
                  label="Método depreciación"
                  value={form.defaultDepreciationMethod}
                  onChange={(e) => setField("defaultDepreciationMethod", e.target.value)}
                >
                  {DEPRECIATION_METHODS.map((m) => (
                    <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField
                label="% Residual"
                type="number"
                fullWidth
               
                value={form.defaultResidualPercent}
                onChange={(e) => setField("defaultResidualPercent", Number(e.target.value))}
              />
              <TextField
                label="Pais"
                fullWidth
               
                value={form.countryCode}
                onChange={(e) => setField("countryCode", e.target.value)}
                placeholder="VE, ES, CO..."
              />
            </Stack>
            <Stack direction="row" spacing={2}>
              <Autocomplete
                options={cuentas}
                getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultAssetAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultAssetAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta activo" />}
                fullWidth
                isOptionEqualToValue={(opt, val) => opt.code === val.code}
              />
              <Autocomplete
                options={cuentas}
                getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultDeprecAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultDeprecAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta dep. acum." />}
                fullWidth
                isOptionEqualToValue={(opt, val) => opt.code === val.code}
              />
              <Autocomplete
                options={cuentas}
                getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultExpenseAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultExpenseAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta gasto" />}
                fullWidth
                isOptionEqualToValue={(opt, val) => opt.code === val.code}
              />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={upsertMutation.isPending || !form.categoryCode || !form.categoryName}
            startIcon={upsertMutation.isPending ? <CircularProgress size={16} /> : <AddIcon />}
          >
            {isEditing ? "Guardar" : "Crear"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
