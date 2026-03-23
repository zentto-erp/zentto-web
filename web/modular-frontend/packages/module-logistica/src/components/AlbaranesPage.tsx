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
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DeleteIcon from "@mui/icons-material/Delete";
import { formatCurrency } from "@zentto/shared-api";
import {
  useDeliveryNotesList,
  useCreateDeliveryNote,
  useDispatchDeliveryNote,
  useDeliverDeliveryNote,
  type DeliveryFilter,
} from "../hooks/useLogistica";

function AlbaranDetailPanel({ row }: { row: Record<string, unknown> }) {
  const statusColors: Record<string, 'default' | 'info' | 'warning' | 'primary' | 'success' | 'error'> = {
    DRAFT: 'default', CONFIRMED: 'info', PICKING: 'warning',
    PACKED: 'primary', DISPATCHED: 'info', DELIVERED: 'success', VOIDED: 'error',
  };

  const fields = [
    { label: 'Nº Doc. Venta', value: row.SalesDocumentNumber },
    { label: 'Transportista', value: row.CarrierName },
    { label: 'Entregado a', value: row.DeliveredToName },
    { label: 'Fecha', value: row.DeliveryDate ? String(row.DeliveryDate).slice(0, 10) : null },
  ].filter(f => f.value != null && f.value !== '');

  return (
    <Box sx={{ px: 3, py: 2, display: 'flex', flexWrap: 'wrap', gap: 3, alignItems: 'center' }}>
      {fields.map(f => (
        <Box key={f.label} sx={{ minWidth: 140 }}>
          <Typography variant="caption" color="text.secondary"
            sx={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block' }}>
            {f.label}
          </Typography>
          <Typography variant="body2" fontWeight={500} sx={{ mt: 0.25 }}>
            {String(f.value)}
          </Typography>
        </Box>
      ))}
      <Box>
        <Typography variant="caption" color="text.secondary"
          sx={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block' }}>
          Estado
        </Typography>
        <Chip
          size="small"
          label={String(row.Status ?? '')}
          color={statusColors[String(row.Status ?? '')] ?? 'default'}
          sx={{ mt: 0.25, fontWeight: 600 }}
        />
      </Box>
    </Box>
  );
}

interface DeliveryLine {
  productCode: string;
  productName: string;
  orderedQty: number;
  pickedQty: number;
  packedQty: number;
}

const statusColors: Record<string, "default" | "warning" | "success" | "error" | "info" | "primary" | "secondary"> = {
  DRAFT: "default",
  CONFIRMED: "info",
  PICKING: "warning",
  PACKED: "secondary",
  DISPATCHED: "primary",
  DELIVERED: "success",
  VOIDED: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  CONFIRMED: "Confirmado",
  PICKING: "En Picking",
  PACKED: "Empacado",
  DISPATCHED: "Despachado",
  DELIVERED: "Entregado",
  VOIDED: "Anulado",
};

const emptyLine = (): DeliveryLine => ({
  productCode: "",
  productName: "",
  orderedQty: 0,
  pickedQty: 0,
  packedQty: 0,
});

export default function AlbaranesPage() {
  const [filter, setFilter] = useState<DeliveryFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [deliverDialogOpen, setDeliverDialogOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);
  const [deliveredToName, setDeliveredToName] = useState("");

  // Form state
  const [customerId, setCustomerId] = useState("");
  const [salesDocumentNumber, setSalesDocumentNumber] = useState("");
  const [carrierId, setCarrierId] = useState("");
  const [lines, setLines] = useState<DeliveryLine[]>([emptyLine()]);

  const { data, isLoading } = useDeliveryNotesList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createDelivery = useCreateDeliveryNote();
  const dispatchDelivery = useDispatchDeliveryNote();
  const deliverDelivery = useDeliverDeliveryNote();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "DeliveryNumber", headerName: "N. Albaran", flex: 1, minWidth: 130 },
    { field: "SalesDocumentNumber", headerName: "N. Doc. Venta", flex: 1, minWidth: 130 },
    { field: "CustomerName", headerName: "Cliente", flex: 1.5, minWidth: 180 },
    {
      field: "DeliveryDate",
      headerName: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
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
    { field: "CarrierName", headerName: "Transportista", flex: 1, minWidth: 140 },
    {
      field: "actions",
      headerName: "Acciones",
      width: 140,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.DeliveryId ?? params.row.Id);
        return (
          <Stack direction="row" spacing={0.5}>
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
            {(status === "CONFIRMED" || status === "PACKED") && (
              <Tooltip title="Despachar">
                <IconButton
                  size="small"
                  color="primary"
                  onClick={() => {
                    if (id) dispatchDelivery.mutate(id);
                  }}
                >
                  <LocalShippingIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            {status === "DISPATCHED" && (
              <Tooltip title="Entregar">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => {
                    setSelectedRow(params.row);
                    setDeliveredToName("");
                    setDeliverDialogOpen(true);
                  }}
                >
                  <CheckCircleIcon fontSize="small" />
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

  const handleLineChange = (idx: number, field: keyof DeliveryLine, value: string | number) => {
    setLines((prev) =>
      prev.map((l, i) => (i === idx ? { ...l, [field]: value } : l))
    );
  };

  const resetForm = () => {
    setCustomerId("");
    setSalesDocumentNumber("");
    setCarrierId("");
    setLines([emptyLine()]);
  };

  const handleSubmit = () => {
    createDelivery.mutate(
      {
        customerId: Number(customerId),
        salesDocumentNumber,
        carrierId: carrierId ? Number(carrierId) : null,
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

  const handleDeliver = () => {
    const id = Number(selectedRow?.DeliveryId ?? selectedRow?.Id);
    if (id) {
      deliverDelivery.mutate(
        { id, deliveredToName },
        {
          onSuccess: () => {
            setDeliverDialogOpen(false);
            setSelectedRow(null);
          },
        }
      );
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Albaranes / Notas de Entrega
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nuevo Albaran
        </Button>
      </Box>

      {/* Filter */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          select
          label="Estado"
          value={filter.status ?? ""}
          onChange={handleStatusFilter}
         
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">Todos</MenuItem>
          <MenuItem value="DRAFT">Borrador</MenuItem>
          <MenuItem value="CONFIRMED">Confirmado</MenuItem>
          <MenuItem value="PICKING">En Picking</MenuItem>
          <MenuItem value="PACKED">Empacado</MenuItem>
          <MenuItem value="DISPATCHED">Despachado</MenuItem>
          <MenuItem value="DELIVERED">Entregado</MenuItem>
          <MenuItem value="VOIDED">Anulado</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.DeliveryId ?? row.Id ?? row.DeliveryNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['DeliveryNumber', 'CustomerName']}
        smExtraFields={['Status', 'DeliveryDate']}
        getDetailContent={(row: any) => <AlbaranDetailPanel row={row} />}
        detailPanelHeight={100}
      />

      {/* Dialog: Nuevo Albaran */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nuevo Albaran</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Cliente (ID)"
              value={customerId}
              onChange={(e) => setCustomerId(e.target.value)}
              type="number"
              fullWidth
            />
            <TextField
              label="N. Documento de Venta"
              value={salesDocumentNumber}
              onChange={(e) => setSalesDocumentNumber(e.target.value)}
              fullWidth
            />
            <TextField
              label="Transportista (ID)"
              value={carrierId}
              onChange={(e) => setCarrierId(e.target.value)}
              type="number"
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
                  sx={{ flex: 1 }}
                />
                <TextField
                  label="Cant. Ordenada"
                  type="number"
                  value={line.orderedQty}
                  onChange={(e) => handleLineChange(idx, "orderedQty", Number(e.target.value))}
                  sx={{ width: 110 }}
                />
                <TextField
                  label="Cant. Picked"
                  type="number"
                  value={line.pickedQty}
                  onChange={(e) => handleLineChange(idx, "pickedQty", Number(e.target.value))}
                  sx={{ width: 110 }}
                />
                <TextField
                  label="Cant. Packed"
                  type="number"
                  value={line.packedQty}
                  onChange={(e) => handleLineChange(idx, "packedQty", Number(e.target.value))}
                  sx={{ width: 110 }}
                />
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
            disabled={createDelivery.isPending || !customerId}
          >
            {createDelivery.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Albaran</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>N. Albaran:</strong> {String(selectedRow.DeliveryNumber ?? "")}</Typography>
              <Typography><strong>Doc. Venta:</strong> {String(selectedRow.SalesDocumentNumber ?? "")}</Typography>
              <Typography><strong>Cliente:</strong> {String(selectedRow.CustomerName ?? "")}</Typography>
              <Typography><strong>Transportista:</strong> {String(selectedRow.CarrierName ?? "—")}</Typography>
              <Typography><strong>Fecha:</strong> {String(selectedRow.DeliveryDate ?? "").slice(0, 10)}</Typography>
              <Typography>
                <strong>Estado:</strong>{" "}
                <Chip
                  label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                  size="small"
                  color={statusColors[String(selectedRow.Status)] ?? "default"}
                  variant="outlined"
                />
              </Typography>
              <Typography><strong>Entregado a:</strong> {String(selectedRow.DeliveredToName ?? "—")}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Entregar */}
      <Dialog open={deliverDialogOpen} onClose={() => setDeliverDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Confirmar Entrega</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Albaran: {String(selectedRow?.DeliveryNumber ?? "")}
            </Typography>
            <TextField
              label="Recibido por"
              value={deliveredToName}
              onChange={(e) => setDeliveredToName(e.target.value)}
              fullWidth
              placeholder="Nombre de quien recibe"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeliverDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            color="success"
            onClick={handleDeliver}
            disabled={deliverDelivery.isPending || !deliveredToName.trim()}
          >
            {deliverDelivery.isPending ? "Procesando..." : "Confirmar Entrega"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
