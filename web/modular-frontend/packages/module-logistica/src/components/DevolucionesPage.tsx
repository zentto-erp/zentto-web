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
import DeleteIcon from "@mui/icons-material/Delete";
import {
  useReturnsList,
  useCreateReturn,
  type ReturnFilter,
} from "../hooks/useLogistica";
import type { ColumnDef } from "@zentto/datagrid-core";

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

const DEVOLUCIONES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "PENDING", label: "Pendiente" },
      { value: "APPROVED", label: "Aprobada" },
      { value: "COMPLETE", label: "Completa" },
      { value: "REJECTED", label: "Rechazada" },
      { value: "VOIDED", label: "Anulada" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

export default function DevolucionesPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<ReturnFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);

  // Form state
  const [supplierId, setSupplierId] = useState("");
  const [returnReason, setReturnReason] = useState("");
  const [lines, setLines] = useState<ReturnLine[]>([emptyLine()]);
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

const { data, isLoading } = useReturnsList({
    ...filter,
    search: search || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createReturn = useCreateReturn();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "ReturnNumber", header: "N. Devolucion", flex: 1, minWidth: 130 },
    { field: "SupplierName", header: "Proveedor", flex: 1.5, minWidth: 180 },
    {
      field: "ReturnDate",
      header: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    { field: "Reason", header: "Motivo", flex: 1.5, minWidth: 180 },
    {
      field: "Status",
      header: "Estado",
      width: 120,
      renderCell: (params) => {
        const status = String(params.value ?? "DRAFT");
        // Bind data to zentto-grid web component
        useEffect(() => {
          const el = gridRef.current;
          if (!el || !registered) return;
          el.columns = columns;
          el.rows = rows;
          el.loading = isLoading;
        }, [rows, isLoading, registered, columns]);

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
      header: "Acciones",
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
      <Box sx={{
        display: "flex",
        flexDirection: { xs: "column", sm: "row" },
        justifyContent: "space-between",
        alignItems: { xs: "stretch", sm: "center" },
        gap: 2,
        mb: 3,
      }}>
        <Typography variant="h5" fontWeight={600}>
          Devoluciones
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setDialogOpen(true)}
          fullWidth={isMobile}
          sx={{ maxWidth: { sm: "fit-content" } }}
        >
          Nueva Devolucion
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={DEVOLUCIONES_FILTERS}
        values={filterValues}
        onChange={handleFilterChange}
        searchPlaceholder="Buscar devoluciones..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="logistica-devoluciones-list"
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

      {/* Dialog: Nueva Devolucion */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "md"}
        fullWidth
      >
        <DialogTitle>Nueva Devolucion</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Proveedor (ID)"
                value={supplierId}
                onChange={(e) => setSupplierId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                label="Motivo General"
                value={returnReason}
                onChange={(e) => setReturnReason(e.target.value)}
                fullWidth
                multiline
                rows={2}
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
                  label="Cantidad"
                  type="number"
                  value={line.quantity}
                  onChange={(e) => handleLineChange(idx, "quantity", Number(e.target.value))}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Lote"
                  value={line.lotNumber}
                  onChange={(e) => handleLineChange(idx, "lotNumber", e.target.value)}
                  fullWidth
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Serial"
                  value={line.serialNumber}
                  onChange={(e) => handleLineChange(idx, "serialNumber", e.target.value)}
                  fullWidth
                />
              </Grid>
              <Grid item xs={12} sm={2.5}>
                <TextField
                  label="Motivo"
                  value={line.reason}
                  onChange={(e) => handleLineChange(idx, "reason", e.target.value)}
                  fullWidth
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
            disabled={createReturn.isPending || !supplierId}
          >
            {createReturn.isPending ? "Guardando..." : "Guardar"}
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
        <DialogTitle>Detalle de Devolucion</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Box sx={{ mt: 1, display: "flex", flexDirection: "column", gap: 1 }}>
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
