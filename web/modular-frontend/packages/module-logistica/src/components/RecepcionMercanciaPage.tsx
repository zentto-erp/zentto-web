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
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DeleteIcon from "@mui/icons-material/Delete";
import { formatCurrency } from "@zentto/shared-api";
import {
  useReceiptsList,
  useCreateReceipt,
  useCompleteReceipt,
  type ReceiptFilter,
} from "../hooks/useLogistica";

interface ReceiptLine {
  productCode: string;
  productName: string;
  orderedQty: number;
  receivedQty: number;
  unitCost: number;
  lotNumber: string;
  expirationDate: string;
}

const statusColors: Record<string, "default" | "warning" | "success" | "error"> = {
  DRAFT: "default",
  PARTIAL: "warning",
  COMPLETE: "success",
  VOIDED: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  PARTIAL: "Parcial",
  COMPLETE: "Completa",
  VOIDED: "Anulada",
};

const emptyLine = (): ReceiptLine => ({
  productCode: "",
  productName: "",
  orderedQty: 0,
  receivedQty: 0,
  unitCost: 0,
  lotNumber: "",
  expirationDate: "",
});

export default function RecepcionMercanciaPage() {
  const [filter, setFilter] = useState<ReceiptFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);

  // Form state
  const [supplierId, setSupplierId] = useState("");
  const [warehouseId, setWarehouseId] = useState("");
  const [purchaseOrderNumber, setPurchaseOrderNumber] = useState("");
  const [lines, setLines] = useState<ReceiptLine[]>([emptyLine()]);

  const { data, isLoading } = useReceiptsList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createReceipt = useCreateReceipt();
  const completeReceipt = useCompleteReceipt();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "ReceiptNumber", headerName: "N. Recepcion", flex: 1, minWidth: 130 },
    { field: "PurchaseDocumentNumber", headerName: "N. Orden Compra", flex: 1, minWidth: 140 },
    { field: "SupplierName", headerName: "Proveedor", flex: 1.5, minWidth: 180 },
    { field: "WarehouseName", headerName: "Almacen", flex: 1, minWidth: 120 },
    {
      field: "ReceiptDate",
      headerName: "Fecha Recepcion",
      flex: 1,
      minWidth: 130,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
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
        return (
          <Stack direction="row" spacing={0.5}>
            <IconButton
              size="small"
              title="Ver detalle"
              onClick={() => {
                setSelectedRow(params.row);
                setDetailOpen(true);
              }}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
            {(status === "DRAFT" || status === "PARTIAL") && (
              <IconButton
                size="small"
                title="Completar"
                color="success"
                onClick={() => {
                  const id = Number(params.row.ReceiptId ?? params.row.Id);
                  if (id) completeReceipt.mutate(id);
                }}
              >
                <CheckCircleIcon fontSize="small" />
              </IconButton>
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

  const handleLineChange = (idx: number, field: keyof ReceiptLine, value: string | number) => {
    setLines((prev) =>
      prev.map((l, i) => (i === idx ? { ...l, [field]: value } : l))
    );
  };

  const resetForm = () => {
    setSupplierId("");
    setWarehouseId("");
    setPurchaseOrderNumber("");
    setLines([emptyLine()]);
  };

  const handleSubmit = () => {
    createReceipt.mutate(
      {
        supplierId: Number(supplierId),
        warehouseId: Number(warehouseId),
        purchaseOrderNumber,
        lines,
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
          Recepcion de Mercancia
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nueva Recepcion
        </Button>
      </Box>

      {/* Filter */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
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
          <MenuItem value="PARTIAL">Parcial</MenuItem>
          <MenuItem value="COMPLETE">Completa</MenuItem>
          <MenuItem value="VOIDED">Anulada</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.ReceiptId ?? row.Id ?? row.ReceiptNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['ReceiptNumber', 'SupplierName']}
        smExtraFields={['Status', 'ReceiptDate']}
      />

      {/* Dialog: Nueva Recepcion */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nueva Recepcion de Mercancia</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Proveedor (ID)"
              value={supplierId}
              onChange={(e) => setSupplierId(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <TextField
              label="Almacen (ID)"
              value={warehouseId}
              onChange={(e) => setWarehouseId(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <TextField
              label="N. Orden de Compra"
              value={purchaseOrderNumber}
              onChange={(e) => setPurchaseOrderNumber(e.target.value)}
              size="small"
              fullWidth
            />

            <Typography variant="subtitle2" sx={{ mt: 2, fontWeight: 600 }}>
              Lineas de Detalle
            </Typography>
            {lines.map((line, idx) => (
              <Stack key={idx} direction="row" spacing={1} alignItems="center">
                <TextField
                  label="Codigo Producto"
                  value={line.productCode}
                  onChange={(e) => handleLineChange(idx, "productCode", e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                />
                <TextField
                  label="Cant. Ordenada"
                  type="number"
                  value={line.orderedQty}
                  onChange={(e) => handleLineChange(idx, "orderedQty", Number(e.target.value))}
                  size="small"
                  sx={{ width: 110 }}
                />
                <TextField
                  label="Cant. Recibida"
                  type="number"
                  value={line.receivedQty}
                  onChange={(e) => handleLineChange(idx, "receivedQty", Number(e.target.value))}
                  size="small"
                  sx={{ width: 110 }}
                />
                <TextField
                  label="Costo Unit."
                  type="number"
                  value={line.unitCost}
                  onChange={(e) => handleLineChange(idx, "unitCost", Number(e.target.value))}
                  size="small"
                  sx={{ width: 110 }}
                />
                <TextField
                  label="Lote"
                  value={line.lotNumber}
                  onChange={(e) => handleLineChange(idx, "lotNumber", e.target.value)}
                  size="small"
                  sx={{ width: 100 }}
                />
                <DatePicker
                  label="Vencimiento"
                  value={line.expirationDate ? dayjs(line.expirationDate) : null}
                  onChange={(v) => handleLineChange(idx, "expirationDate", v ? v.format('YYYY-MM-DD') : '')}
                  slotProps={{ textField: { size: 'small', fullWidth: true } }}
                />
                <IconButton
                  size="small"
                  color="error"
                  onClick={() => handleRemoveLine(idx)}
                  disabled={lines.length === 1}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              </Stack>
            ))}
            <Button size="small" onClick={handleAddLine} startIcon={<AddIcon />}>
              Agregar linea
            </Button>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={createReceipt.isPending || !supplierId || !warehouseId}
          >
            {createReceipt.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Recepcion</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>N. Recepcion:</strong> {String(selectedRow.ReceiptNumber ?? "")}</Typography>
              <Typography><strong>Proveedor:</strong> {String(selectedRow.SupplierName ?? "")}</Typography>
              <Typography><strong>Almacen:</strong> {String(selectedRow.WarehouseName ?? "")}</Typography>
              <Typography><strong>Orden de Compra:</strong> {String(selectedRow.PurchaseDocumentNumber ?? "")}</Typography>
              <Typography><strong>Fecha:</strong> {String(selectedRow.ReceiptDate ?? "").slice(0, 10)}</Typography>
              <Typography>
                <strong>Estado:</strong>{" "}
                <Chip
                  label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                  size="small"
                  color={statusColors[String(selectedRow.Status)] ?? "default"}
                  variant="outlined"
                />
              </Typography>
              <Typography><strong>Notas:</strong> {String(selectedRow.Notes ?? "—")}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
