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
  TextField,
  Typography,
  Tooltip,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";

import { ZenttoDataGrid, type ZenttoColDef, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DeleteIcon from "@mui/icons-material/Delete";

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
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

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

  const columns: ZenttoColDef[] = [
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
          <Box sx={{ display: "flex", gap: 0.5 }}>
            <Tooltip title="Ver detalle">
              <IconButton
                size="small"
                onClick={() => {
                  setSelectedRow(params.row);
                  setDetailOpen(true);
                }}
              >
                <VisibilityIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            {(status === "DRAFT" || status === "PARTIAL") && (
              <Tooltip title="Completar recepcion">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => {
                    const id = Number(params.row.ReceiptId ?? params.row.Id);
                    if (id) completeReceipt.mutate(id);
                  }}
                >
                  <CheckCircleIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
          </Box>
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
      <Box sx={{
        display: "flex",
        flexDirection: { xs: "column", sm: "row" },
        justifyContent: "space-between",
        alignItems: { xs: "stretch", sm: "center" },
        gap: 2,
        mb: 3,
      }}>
        <Typography variant="h5" fontWeight={600}>
          Recepcion de Mercancia
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setDialogOpen(true)}
          fullWidth={isMobile}
          sx={{ maxWidth: { sm: "fit-content" } }}
        >
          Nueva Recepcion
        </Button>
      </Box>

      {/* Filter */}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={6} md={3}>
          <TextField
            select
            label="Estado"
            value={filter.status ?? ""}
            onChange={handleStatusFilter}
            fullWidth
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="DRAFT">Borrador</MenuItem>
            <MenuItem value="PARTIAL">Parcial</MenuItem>
            <MenuItem value="COMPLETE">Completa</MenuItem>
            <MenuItem value="VOIDED">Anulada</MenuItem>
          </TextField>
        </Grid>
      </Grid>

      {/* DataGrid */}
      <ZenttoDataGrid
        gridId="logistica-recepcion-mercancia-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.ReceiptId ?? row.Id ?? row.ReceiptNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        enableHeaderFilters
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        enableClipboard
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['ReceiptNumber', 'SupplierName']}
        smExtraFields={['Status', 'ReceiptDate']}
      />

      {/* Dialog: Nueva Recepcion */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "md"}
        fullWidth
      >
        <DialogTitle>Nueva Recepcion de Mercancia</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="Proveedor (ID)"
                value={supplierId}
                onChange={(e) => setSupplierId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="Almacen (ID)"
                value={warehouseId}
                onChange={(e) => setWarehouseId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="N. Orden de Compra"
                value={purchaseOrderNumber}
                onChange={(e) => setPurchaseOrderNumber(e.target.value)}
                fullWidth
              />
            </Grid>
          </Grid>

          <Typography variant="subtitle2" sx={{ mt: 3, mb: 1, fontWeight: 600 }}>
            Lineas de Detalle
          </Typography>
          {lines.map((line, idx) => (
            <Grid container spacing={1} key={idx} sx={{ mb: 1 }} alignItems="center">
              <Grid item xs={12} sm={3}>
                <TextField
                  label="Codigo Producto"
                  value={line.productCode}
                  onChange={(e) => handleLineChange(idx, "productCode", e.target.value)}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={1.5}>
                <TextField
                  label="Cant. Ord."
                  type="number"
                  value={line.orderedQty}
                  onChange={(e) => handleLineChange(idx, "orderedQty", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={1.5}>
                <TextField
                  label="Cant. Rec."
                  type="number"
                  value={line.receivedQty}
                  onChange={(e) => handleLineChange(idx, "receivedQty", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={1.5}>
                <TextField
                  label="Costo Unit."
                  type="number"
                  value={line.unitCost}
                  onChange={(e) => handleLineChange(idx, "unitCost", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={6} sm={1.5}>
                <TextField
                  label="Lote"
                  value={line.lotNumber}
                  onChange={(e) => handleLineChange(idx, "lotNumber", e.target.value)}
                  fullWidth
                />
              </Grid>
              <Grid item xs={6} sm={2}>
                <DatePicker
                  label="Vencimiento"
                  value={line.expirationDate ? dayjs(line.expirationDate) : null}
                  onChange={(v) => handleLineChange(idx, "expirationDate", v ? v.format('YYYY-MM-DD') : '')}
                  slotProps={{ textField: { size: 'small', fullWidth: true } }}
                />
              </Grid>
              <Grid item xs={12} sm={1} sx={{ display: "flex", justifyContent: { xs: "flex-end", sm: "center" } }}>
                <Tooltip title="Eliminar linea">
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
              </Grid>
            </Grid>
          ))}
          <Button size="small" onClick={handleAddLine} startIcon={<AddIcon />}>
            Agregar linea
          </Button>
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
      <Dialog
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "sm"}
        fullWidth
      >
        <DialogTitle>Detalle de Recepcion</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Box sx={{ mt: 1, display: "flex", flexDirection: "column", gap: 1 }}>
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
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
