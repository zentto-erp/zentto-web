"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
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
  Alert,
} from "@mui/material";
import VisibilityIcon from "@mui/icons-material/Visibility";
import DeleteIcon from "@mui/icons-material/Delete";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import {
  useActivosFijosList,
  useCategoriasList,
  useCreateActivoFijo,
  useDisposeActivoFijo,
  type AssetFilter,
  type CreateAssetInput,
} from "../hooks/useActivosFijos";

const STATUS_OPTIONS = [
  { value: "", label: "Todos" },
  { value: "ACTIVE", label: "Activo" },
  { value: "DISPOSED", label: "Dado de baja" },
  { value: "FULLY_DEPRECIATED", label: "Totalmente depreciado" },
];

const DEPRECIATION_METHODS = [
  { value: "STRAIGHT_LINE", label: "Línea recta" },
  { value: "DOUBLE_DECLINING", label: "Doble declinación" },
  { value: "UNITS_PRODUCED", label: "Unidades producidas" },
  { value: "NONE", label: "Sin depreciación" },
];

const statusColor = (s: string) => {
  switch (s) {
    case "ACTIVE": return "success";
    case "DISPOSED": return "error";
    case "FULLY_DEPRECIATED": return "warning";
    default: return "default";
  }
};

const emptyForm: CreateAssetInput = {
  assetCode: "",
  description: "",
  categoryId: 0,
  acquisitionDate: "",
  acquisitionCost: 0,
  residualValue: 0,
  usefulLifeMonths: 0,
  depreciationMethod: "STRAIGHT_LINE",
  assetAccountCode: "",
  deprecAccountCode: "",
  expenseAccountCode: "",
  costCenterCode: "",
  location: "",
  serialNumber: "",
};

export default function ActivosFijosListPage() {
  const router = useRouter();
  const [filter, setFilter] = useState<AssetFilter>({ page: 1, limit: 25 });
  const [openCreate, setOpenCreate] = useState(false);
  const [form, setForm] = useState<CreateAssetInput>({ ...emptyForm });
  const [disposeId, setDisposeId] = useState<number | null>(null);
  const [disposeReason, setDisposeReason] = useState("");

  const { data, isLoading } = useActivosFijosList(filter);
  const { data: categoriasData } = useCategoriasList();
  const createMutation = useCreateActivoFijo();
  const disposeMutation = useDisposeActivoFijo();

  const rows = data?.rows ?? [];
  const categorias: any[] = categoriasData?.rows ?? [];

  const columns: ZenttoColDef[] = [
    { field: "AssetCode", headerName: "Código", width: 110 },
    { field: "Description", headerName: "Descripción", flex: 1, minWidth: 200 },
    {
      field: "CategoryName",
      headerName: "Categoría",
      width: 150,
      renderCell: (p) => <Chip label={p.value} size="small" variant="outlined" />,
    },
    { field: "AcquisitionDate", headerName: "Fecha adq.", width: 120 },
    {
      field: "AcquisitionCost",
      headerName: "Costo adq.",
      width: 140,
      type: "number",
      aggregation: "sum",
      currency: "VES",
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "BookValue",
      headerName: "Valor en Libros",
      width: 140,
      type: "number",
      aggregation: "sum",
      currency: "VES",
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 150,
      statusColors: { ACTIVE: "success", DISPOSED: "error", FULLY_DEPRECIATED: "warning" },
      renderCell: (p) => (
        <Chip label={p.value} size="small" color={statusColor(p.value) as any} />
      ),
    },
    {
      field: "acciones",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ver detalle">
            <IconButton
              size="small"
              onClick={() => router.push(`/contabilidad/activos-fijos/${p.row.AssetId}`)}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {p.row.Status === "ACTIVE" && (
            <Tooltip title="Dar de baja">
              <IconButton
                size="small"
                color="error"
                onClick={() => setDisposeId(p.row.AssetId)}
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
        </Stack>
      ),
    },
  ];

  const handleCreate = async () => {
    await createMutation.mutateAsync(form);
    setOpenCreate(false);
    setForm({ ...emptyForm });
  };

  const handleDispose = async () => {
    if (!disposeId) return;
    await disposeMutation.mutateAsync({
      id: disposeId,
      disposalDate: new Date().toISOString().slice(0, 10),
      disposalReason: disposeReason,
    });
    setDisposeId(null);
    setDisposeReason("");
  };

  const setField = <K extends keyof CreateAssetInput>(key: K, val: CreateAssetInput[K]) =>
    setForm((f) => ({ ...f, [key]: val }));

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Activos fijos"
        primaryAction={{
          label: "Nuevo activo",
          onClick: () => setOpenCreate(true),
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filtros */}
        <FormGrid spacing={2} sx={{ mb: 2 }}>
          <FormField xs={12} sm={4}>
            <TextField
              label="Buscar"
             
              fullWidth
              value={filter.search || ""}
              onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value, page: 1 }))}
            />
          </FormField>
          <FormField xs={12} sm={4}>
            <FormControl fullWidth>
              <InputLabel>Categoría</InputLabel>
              <Select
                label="Categoría"
                value={filter.categoryCode || ""}
                onChange={(e) => setFilter((f) => ({ ...f, categoryCode: e.target.value || undefined, page: 1 }))}
              >
                <MenuItem value="">Todas</MenuItem>
                {categorias.map((c) => (
                  <MenuItem key={c.CategoryCode} value={c.CategoryCode}>
                    {c.CategoryName}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </FormField>
          <FormField xs={12} sm={4}>
            <FormControl fullWidth>
              <InputLabel>Estado</InputLabel>
              <Select
                label="Estado"
                value={filter.status || ""}
                onChange={(e) => setFilter((f) => ({ ...f, status: e.target.value || undefined, page: 1 }))}
              >
                {STATUS_OPTIONS.map((o) => (
                  <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </FormField>
        </FormGrid>

        {/* DataGrid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[25, 50]}
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            rowCount={data?.total ?? 0}
            paginationMode="server"
            disableRowSelectionOnClick
            getRowId={(row) => row.AssetId}
            sx={{ border: "none" }}
            mobileVisibleFields={['Description', 'Status']}
            smExtraFields={['AcquisitionCost', 'CategoryName']}
            showTotals
            enableGrouping
            enablePivot
            enableClipboard
          />
        </Paper>
      </Box>

      {/* Dialog Crear Activo */}
      <Dialog open={openCreate} onClose={() => setOpenCreate(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nuevo activo fijo</DialogTitle>
        <DialogContent>
          <FormGrid spacing={2} sx={{ mt: 1 }}>
            <FormField xs={12} sm={6}>
              <TextField
                label="Código"
                fullWidth
               
                value={form.assetCode}
                onChange={(e) => setField("assetCode", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField
                label="Número de Serie"
                fullWidth
               
                value={form.serialNumber || ""}
                onChange={(e) => setField("serialNumber", e.target.value)}
              />
            </FormField>
            <FormField xs={12}>
              <TextField
                label="Descripción"
                fullWidth
               
                value={form.description}
                onChange={(e) => setField("description", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Categoría</InputLabel>
                <Select
                  label="Categoría"
                  value={form.categoryId || ""}
                  onChange={(e) => setField("categoryId", Number(e.target.value))}
                >
                  {categorias.map((c) => (
                    <MenuItem key={c.CategoryId} value={c.CategoryId}>
                      {c.CategoryName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} sm={6}>
              <DatePicker
                label="Fecha adquisición"
                value={form.acquisitionDate ? dayjs(form.acquisitionDate) : null}
                onChange={(v) => setField("acquisitionDate", v ? v.format('YYYY-MM-DD') : '')}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Costo adquisición"
                type="number"
                fullWidth
               
                value={form.acquisitionCost}
                onChange={(e) => setField("acquisitionCost", Number(e.target.value))}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Valor residual"
                type="number"
                fullWidth
               
                value={form.residualValue || 0}
                onChange={(e) => setField("residualValue", Number(e.target.value))}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Vida Útil (meses)"
                type="number"
                fullWidth
               
                value={form.usefulLifeMonths}
                onChange={(e) => setField("usefulLifeMonths", Number(e.target.value))}
              />
            </FormField>
            <FormField xs={12}>
              <FormControl fullWidth>
                <InputLabel>Método de Depreciación</InputLabel>
                <Select
                  label="Método de Depreciación"
                  value={form.depreciationMethod || "STRAIGHT_LINE"}
                  onChange={(e) => setField("depreciationMethod", e.target.value)}
                >
                  {DEPRECIATION_METHODS.map((m) => (
                    <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Cuenta activo"
                fullWidth
               
                value={form.assetAccountCode}
                onChange={(e) => setField("assetAccountCode", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Cuenta dep. acum."
                fullWidth
               
                value={form.deprecAccountCode}
                onChange={(e) => setField("deprecAccountCode", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField
                label="Cuenta gasto"
                fullWidth
               
                value={form.expenseAccountCode}
                onChange={(e) => setField("expenseAccountCode", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField
                label="Centro de Costo"
                fullWidth
               
                value={form.costCenterCode || ""}
                onChange={(e) => setField("costCenterCode", e.target.value)}
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField
                label="Ubicación"
                fullWidth
               
                value={form.location || ""}
                onChange={(e) => setField("location", e.target.value)}
              />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCreate(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={createMutation.isPending || !form.assetCode || !form.description}
            startIcon={createMutation.isPending ? <CircularProgress size={16} /> : <AddIcon />}
          >
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog Dar de Baja */}
      <Dialog open={disposeId != null} onClose={() => setDisposeId(null)}>
        <DialogTitle>Dar de baja activo</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            Esta acción registrará la baja del activo y no se puede deshacer.
          </Alert>
          <TextField
            label="Motivo de la baja"
            fullWidth
            multiline
            rows={3}
            value={disposeReason}
            onChange={(e) => setDisposeReason(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDisposeId(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDispose}
            disabled={!disposeReason || disposeMutation.isPending}
          >
            Dar de Baja
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
