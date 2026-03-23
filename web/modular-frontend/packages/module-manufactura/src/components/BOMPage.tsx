"use client";

import React, { useState } from "react";
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  Stack,
  TextField,
  Typography,
  Tooltip,
} from "@mui/material";
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import BlockIcon from "@mui/icons-material/Block";
import DeleteIcon from "@mui/icons-material/Delete";
import { formatCurrency } from "@zentto/shared-api";
import {
  useBOMList,
  useCreateBOM,
  useActivateBOM,
  useObsoleteBOM,
  type BOMFilter,
} from "../hooks/useManufactura";

interface BOMLine {
  productId: string;
  productName: string;
  quantity: number;
  unitOfMeasure: string;
  unitCost: number;
}

const statusColors: Record<string, "default" | "success" | "error" | "warning"> = {
  DRAFT: "default",
  ACTIVE: "success",
  OBSOLETE: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  ACTIVE: "Activa",
  OBSOLETE: "Obsoleta",
};

const emptyLine = (): BOMLine => ({
  productId: "",
  productName: "",
  quantity: 0,
  unitOfMeasure: "",
  unitCost: 0,
});

export default function BOMPage() {
  const [filter, setFilter] = useState<BOMFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [search, setSearch] = useState("");

  // Form state
  const [productId, setProductId] = useState("");
  const [bomCode, setBomCode] = useState("");
  const [bomName, setBomName] = useState("");
  const [expectedQuantity, setExpectedQuantity] = useState("1");
  const [lines, setLines] = useState<BOMLine[]>([emptyLine()]);

  const { data, isLoading } = useBOMList({
    ...filter,
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createBOM = useCreateBOM();
  const activateBOM = useActivateBOM();
  const obsoleteBOM = useObsoleteBOM();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "BOMCode", headerName: "Codigo BOM", flex: 0.8, minWidth: 120 },
    { field: "BOMName", headerName: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "ProductName", headerName: "Producto", flex: 1.2, minWidth: 150 },
    {
      field: "ExpectedQuantity",
      headerName: "Cant. Esperada",
      width: 130,
      type: "number",
    },
    {
      field: "TotalCost",
      headerName: "Costo Total",
      width: 130,
      renderCell: (params) => formatCurrency(Number(params.value ?? 0)),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      renderCell: (params) => {
        const status = String(params.value ?? "DRAFT");
        return (
          <Chip
            label={statusLabels[status] ?? status}
            size="small"
            color={statusColors[status] ?? "default"}
            variant="outlined"
          />
        );
      },
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 120,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.BOMId ?? params.row.Id);
        return (
          <Stack direction="row" spacing={0.5}>
            {status === "DRAFT" && (
              <Tooltip title="Activar BOM">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => id && activateBOM.mutate(id)}
                >
                  <CheckCircleIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            {(status === "DRAFT" || status === "ACTIVE") && (
              <Tooltip title="Marcar obsoleta">
                <IconButton
                  size="small"
                  color="error"
                  onClick={() => id && obsoleteBOM.mutate(id)}
                >
                  <BlockIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
          </Stack>
        );
      },
    },
  ];

  const handleStatusFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, status: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const handleAddLine = () => setLines((prev) => [...prev, emptyLine()]);

  const handleRemoveLine = (idx: number) =>
    setLines((prev) => prev.filter((_, i) => i !== idx));

  const handleLineChange = (idx: number, field: keyof BOMLine, value: string | number) => {
    setLines((prev) =>
      prev.map((l, i) => (i === idx ? { ...l, [field]: value } : l))
    );
  };

  const resetForm = () => {
    setProductId("");
    setBomCode("");
    setBomName("");
    setExpectedQuantity("1");
    setLines([emptyLine()]);
  };

  const handleSubmit = () => {
    createBOM.mutate(
      {
        productId: Number(productId),
        bomCode,
        bomName,
        expectedQuantity: Number(expectedQuantity),
        lines: lines.map((l) => ({
          productId: Number(l.productId),
          quantity: l.quantity,
          unitOfMeasure: l.unitOfMeasure,
          unitCost: l.unitCost,
        })),
      },
      {
        onSuccess: () => {
          setDialogOpen(false);
          resetForm();
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Lista de Materiales (BOM)
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { resetForm(); setDialogOpen(true); }}>
          Nueva BOM
        </Button>
      </Box>

      {/* Filters */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          placeholder="Buscar por codigo, nombre..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPaginationModel((p) => ({ ...p, page: 0 }));
          }}
          size="small"
          sx={{ flex: 1 }}
        />
        <TextField
          select
          label="Estado"
          value={filter.status ?? ""}
          onChange={handleStatusFilter}
          size="small"
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">Todos</MenuItem>
          <MenuItem value="DRAFT">Borrador</MenuItem>
          <MenuItem value="ACTIVE">Activa</MenuItem>
          <MenuItem value="OBSOLETE">Obsoleta</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.BOMId ?? row.Id ?? row.BOMCode ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['BOMName', 'Status']}
        smExtraFields={['ProductName', 'TotalCost']}
      />

      {/* Dialog: Crear BOM */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nueva Lista de Materiales</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Codigo BOM"
              value={bomCode}
              onChange={(e) => setBomCode(e.target.value)}
              size="small"
              fullWidth
            />
            <TextField
              label="Nombre BOM"
              value={bomName}
              onChange={(e) => setBomName(e.target.value)}
              size="small"
              fullWidth
            />
            <TextField
              label="Producto Terminado (ID)"
              value={productId}
              onChange={(e) => setProductId(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <TextField
              label="Cantidad Esperada"
              value={expectedQuantity}
              onChange={(e) => setExpectedQuantity(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />

            <Typography variant="subtitle2" sx={{ mt: 2, fontWeight: 600 }}>
              Componentes / Materiales
            </Typography>
            {lines.map((line, idx) => (
              <Stack key={idx} direction="row" spacing={1} alignItems="center">
                <TextField
                  label="Producto (ID)"
                  value={line.productId}
                  onChange={(e) => handleLineChange(idx, "productId", e.target.value)}
                  size="small"
                  type="number"
                  sx={{ width: 120 }}
                />
                <TextField
                  label="Nombre"
                  value={line.productName}
                  onChange={(e) => handleLineChange(idx, "productName", e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                />
                <TextField
                  label="Cantidad"
                  type="number"
                  value={line.quantity}
                  onChange={(e) => handleLineChange(idx, "quantity", Number(e.target.value))}
                  size="small"
                  sx={{ width: 100 }}
                />
                <TextField
                  label="Unidad"
                  value={line.unitOfMeasure}
                  onChange={(e) => handleLineChange(idx, "unitOfMeasure", e.target.value)}
                  size="small"
                  sx={{ width: 100 }}
                />
                <TextField
                  label="Costo Unit."
                  type="number"
                  value={line.unitCost}
                  onChange={(e) => handleLineChange(idx, "unitCost", Number(e.target.value))}
                  size="small"
                  sx={{ width: 110 }}
                />
                <Tooltip title="Eliminar componente">
                  <span>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleRemoveLine(idx)}
                      disabled={lines.length === 1}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </span>
                </Tooltip>
              </Stack>
            ))}
            <Button size="small" onClick={handleAddLine} startIcon={<AddIcon />}>
              Agregar componente
            </Button>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={createBOM.isPending || !bomCode || !bomName || !productId}
          >
            {createBOM.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
