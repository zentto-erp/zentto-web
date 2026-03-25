"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  TextField,
  Typography,
  Tooltip,
  useMediaQuery,
  useTheme,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid";

import {  ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DeleteIcon from "@mui/icons-material/Delete";

import {
  useDeliveryNotesList,
  useCreateDeliveryNote,
  useDispatchDeliveryNote,
  useDeliverDeliveryNote,
  type DeliveryFilter,
} from "../hooks/useLogistica";
import type { ColumnDef } from "@zentto/datagrid-core";

function AlbaranDetailPanel({ row }: { row: Record<string, unknown> }) {
  const statusColors: Record<string, 'default' | 'info' | 'warning' | 'primary' | 'success' | 'error'> = {
    DRAFT: 'default', PICKING: 'info', PACKED: 'primary',
    DISPATCHED: 'warning', IN_TRANSIT: 'warning', DELIVERED: 'success', VOIDED: 'error',
  };

  const fields = [
    { label: 'N Doc. Venta', value: row.SalesDocumentNumber },
    { label: 'Transportista', value: row.CarrierName },
    { label: 'Entregado a', value: row.DeliveredToName },
    { label: 'Fecha', value: row.DeliveryDate ? String(row.DeliveryDate).slice(0, 10) : null },
  ].filter(f => f.value != null && f.value !== '');

  // Bind data to zentto-grid web component

  useEffect(() => {

    const el = gridRef.current;

    if (!el || !registered) return;

    el.columns = columns;

    el.rows = rows;

    el.loading = isLoading;

  }, [rows, isLoading, registered, columns]);


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

const statusColors: Record<string, "default" | "warning" | "success" | "error" | "info" | "primary"> = {
  DRAFT: "default",
  CONFIRMED: "info",
  PICKING: "warning",
  PACKED: "warning",
  DISPATCHED: "info",
  IN_TRANSIT: "warning",
  DELIVERED: "success",
  VOIDED: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  CONFIRMED: "Confirmado",
  PICKING: "En Picking",
  PACKED: "Empacado",
  DISPATCHED: "Despachado",
  IN_TRANSIT: "En Transito",
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

const ALBARANES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "CONFIRMED", label: "Confirmado" },
      { value: "PICKING", label: "En Picking" },
      { value: "PACKED", label: "Empacado" },
      { value: "DISPATCHED", label: "Despachado" },
      { value: "IN_TRANSIT", label: "En Transito" },
      { value: "DELIVERED", label: "Entregado" },
      { value: "VOIDED", label: "Anulado" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

export default function AlbaranesPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<DeliveryFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
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
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  const handleFilterChange = (vals: Record<string, string>) => {
    setFilterValues(vals);
    setFilter((f) => ({
      ...f,
      status: vals.estado || undefined,
      fechaDesde: vals.from || undefined,
      fechaHasta: vals.to || undefined,
    }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useDeliveryNotesList({
    ...filter,
    search: search || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createDelivery = useCreateDeliveryNote();
  const dispatchDelivery = useDispatchDeliveryNote();
  const deliverDelivery = useDeliverDeliveryNote();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "DeliveryNumber", header: "N. Albaran", flex: 1, minWidth: 130 },
    { field: "SalesDocumentNumber", header: "N. Doc. Venta", flex: 1, minWidth: 130 },
    { field: "CustomerName", header: "Cliente", flex: 1.5, minWidth: 180 },
    {
      field: "DeliveryDate",
      header: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "Status",
      header: "Estado",
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
    { field: "CarrierName", header: "Transportista", flex: 1, minWidth: 140 },
    {
      field: "actions",
      header: "Acciones",
      width: 140,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.DeliveryId ?? params.row.Id);
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
            {status === "PACKED" && (
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
            {(status === "DISPATCHED" || status === "IN_TRANSIT") && (
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
          </Box>
        );
      },
    },
  ];

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
      <Box sx={{
        display: "flex",
        flexDirection: { xs: "column", sm: "row" },
        justifyContent: "space-between",
        alignItems: { xs: "stretch", sm: "center" },
        gap: 2,
        mb: 3,
      }}>
        <Typography variant="h5" fontWeight={600}>
          Albaranes / Notas de Entrega
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setDialogOpen(true)}
          fullWidth={isMobile}
          sx={{ maxWidth: { sm: "fit-content" } }}
        >
          Nuevo Albaran
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={ALBARANES_FILTERS}
        values={filterValues}
        onChange={handleFilterChange}
        searchPlaceholder="Buscar albaranes..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="logistica-albaranes-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>

      {/* Dialog: Nuevo Albaran */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "md"}
        fullWidth
      >
        <DialogTitle>Nuevo Albaran</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="Cliente (ID)"
                value={customerId}
                onChange={(e) => setCustomerId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="N. Documento de Venta"
                value={salesDocumentNumber}
                onChange={(e) => setSalesDocumentNumber(e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <TextField
                label="Transportista (ID)"
                value={carrierId}
                onChange={(e) => setCarrierId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
          </Grid>

          <Typography variant="subtitle2" sx={{ mt: 3, mb: 1, fontWeight: 600 }}>
            Lineas de Detalle
          </Typography>
          {lines.map((line, idx) => (
            <Grid container spacing={1} key={idx} sx={{ mb: 1 }} alignItems="center">
              <Grid item xs={12} sm={4}>
                <TextField
                  label="Codigo Producto"
                  value={line.productCode}
                  onChange={(e) => handleLineChange(idx, "productCode", e.target.value)}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Cant. Ordenada"
                  type="number"
                  value={line.orderedQty}
                  onChange={(e) => handleLineChange(idx, "orderedQty", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Cant. Picked"
                  type="number"
                  value={line.pickedQty}
                  onChange={(e) => handleLineChange(idx, "pickedQty", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Cant. Packed"
                  type="number"
                  value={line.packedQty}
                  onChange={(e) => handleLineChange(idx, "packedQty", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={12} sm={2} sx={{ display: "flex", justifyContent: { xs: "flex-end", sm: "center" } }}>
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
            disabled={createDelivery.isPending || !customerId}
          >
            {createDelivery.isPending ? "Guardando..." : "Guardar"}
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
        <DialogTitle>Detalle de Albaran</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Box sx={{ mt: 1, display: "flex", flexDirection: "column", gap: 1 }}>
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
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Entregar */}
      <Dialog
        open={deliverDialogOpen}
        onClose={() => setDeliverDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "xs"}
        fullWidth
      >
        <DialogTitle>Confirmar Entrega</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 1, display: "flex", flexDirection: "column", gap: 2 }}>
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
          </Box>
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
