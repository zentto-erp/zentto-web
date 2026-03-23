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
import DeleteIcon from "@mui/icons-material/Delete";
import {
  useReturnsList,
  useCreateReturn,
  type ReturnFilter,
} from "../hooks/useLogistica";

interface ReturnLine {
  productCode: string;
  quantity: number;
  lotNumber: string;
  serialNumber: string;
  reason: string;
}

const statusColors: Record<string, "default" | "warning" | "success" | "error" | "info"> = {
  DRAFT: "default",
  PENDING: "warning",
  APPROVED: "info",
  COMPLETE: "success",
  REJECTED: "error",
  VOIDED: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  PENDING: "Pendiente",
  APPROVED: "Aprobada",
  COMPLETE: "Completa",
  REJECTED: "Rechazada",
  VOIDED: "Anulada",
};

const emptyLine = (): ReturnLine => ({
  productCode: "",
  quantity: 0,
  lotNumber: "",
  serialNumber: "",
  reason: "",
});

export default function DevolucionesPage() {
  const [filter, setFilter] = useState<ReturnFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);

  // Form state
  const [supplierId, setSupplierId] = useState("");
  const [returnReason, setReturnReason] = useState("");
  const [lines, setLines] = useState<ReturnLine[]>([emptyLine()]);

  const { data, isLoading } = useReturnsList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createReturn = useCreateReturn();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "ReturnNumber", headerName: "N. Devolucion", flex: 1, minWidth: 130 },
    { field: "SupplierName", headerName: "Proveedor", flex: 1.5, minWidth: 180 },
    {
      field: "ReturnDate",
      headerName: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    { field: "Reason", headerName: "Motivo", flex: 1.5, minWidth: 180 },
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
      width: 80,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
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
      ),
    },
  ];

  const handleStatusFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, status: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const handleAddLine = () => setLines((prev) => [...prev, emptyLine()]);

  const handleRemoveLine = (idx: number) =>
    setLines((prev) => prev.filter((_, i) => i !== idx));

  const handleLineChange = (idx: number, field: keyof ReturnLine, value: string | number) => {
    setLines((prev) =>
      prev.map((l, i) => (i === idx ? { ...l, [field]: value } : l))
    );
  };

  const resetForm = () => {
    setSupplierId("");
    setReturnReason("");
    setLines([emptyLine()]);
  };

  const handleSubmit = () => {
    createReturn.mutate(
      {
        supplierId: Number(supplierId),
        reason: returnReason,
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
          Devoluciones
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nueva Devolucion
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
          <MenuItem value="PENDING">Pendiente</MenuItem>
          <MenuItem value="APPROVED">Aprobada</MenuItem>
          <MenuItem value="COMPLETE">Completa</MenuItem>
          <MenuItem value="REJECTED">Rechazada</MenuItem>
          <MenuItem value="VOIDED">Anulada</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.ReturnId ?? row.Id ?? row.ReturnNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['ReturnNumber', 'SupplierName']}
        smExtraFields={['Status', 'ReturnDate']}
      />

      {/* Dialog: Nueva Devolucion */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nueva Devolucion</DialogTitle>
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
              label="Motivo General"
              value={returnReason}
              onChange={(e) => setReturnReason(e.target.value)}
              size="small"
              fullWidth
              multiline
              rows={2}
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
                  label="Cantidad"
                  type="number"
                  value={line.quantity}
                  onChange={(e) => handleLineChange(idx, "quantity", Number(e.target.value))}
                  size="small"
                  sx={{ width: 100 }}
                />
                <TextField
                  label="Lote"
                  value={line.lotNumber}
                  onChange={(e) => handleLineChange(idx, "lotNumber", e.target.value)}
                  size="small"
                  sx={{ width: 100 }}
                />
                <TextField
                  label="Serial"
                  value={line.serialNumber}
                  onChange={(e) => handleLineChange(idx, "serialNumber", e.target.value)}
                  size="small"
                  sx={{ width: 120 }}
                />
                <TextField
                  label="Motivo"
                  value={line.reason}
                  onChange={(e) => handleLineChange(idx, "reason", e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
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
            disabled={createReturn.isPending || !supplierId}
          >
            {createReturn.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Devolucion</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>N. Devolucion:</strong> {String(selectedRow.ReturnNumber ?? "")}</Typography>
              <Typography><strong>Proveedor:</strong> {String(selectedRow.SupplierName ?? "")}</Typography>
              <Typography><strong>Fecha:</strong> {String(selectedRow.ReturnDate ?? "").slice(0, 10)}</Typography>
              <Typography><strong>Motivo:</strong> {String(selectedRow.Reason ?? "—")}</Typography>
              <Typography>
                <strong>Estado:</strong>{" "}
                <Chip
                  label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                  size="small"
                  color={statusColors[String(selectedRow.Status)] ?? "default"}
                  variant="outlined"
                />
              </Typography>
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
