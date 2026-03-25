"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  AppBar,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  IconButton,
  Stack,
  TextField,
  Toolbar,
  Typography,
  Tooltip,
  useMediaQuery,
  useTheme,
  CircularProgress,
} from "@mui/material";
import {  ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import BlockIcon from "@mui/icons-material/Block";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  useBOMList,
  useCreateBOM,
  useActivateBOM,
  useObsoleteBOM,
  type BOMFilter,
} from "../hooks/useManufactura";
import type { ColumnDef } from "@zentto/datagrid-core";

interface BOMLine {
  productId: string;
  productName: string;
  quantity: number;
  unitOfMeasure: string;
  unitCost: number;
}

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

const BOM_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "ACTIVE", label: "Activa" },
      { value: "OBSOLETE", label: "Obsoleta" },
    ],
  },
];

export default function BOMPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<BOMFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});

  // Form state
  const [productId, setProductId] = useState("");
  const [bomCode, setBomCode] = useState("");
  const [bomName, setBomName] = useState("");
  const [outputQuantity, setOutputQuantity] = useState("1");
  const [lines, setLines] = useState<BOMLine[]>([emptyLine()]);
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

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

  const columns: ColumnDef[] = [
    { field: "BOMCode", header: "Codigo BOM", flex: 0.8, minWidth: 120 },
    { field: "BOMName", header: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "ProductName", header: "Producto", flex: 1.2, minWidth: 150 },
    {
      field: "OutputQuantity",
      header: "Cant. Producida",
      width: 130,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "TotalCost",
      header: "Costo Total",
      width: 130,
      currency: true,
      aggregation: "sum",
    },
    {
      field: "Status",
      header: "Estado",
      width: 120,
      statusColors: {
        DRAFT: "default",
        ACTIVE: "success",
        OBSOLETE: "error",
      },
    },
    {
      field: "actions",
      header: "Acciones",
      width: 120,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.BOMId ?? params.row.Id);
        // Bind data to zentto-grid web component
        useEffect(() => {
          const el = gridRef.current;
          if (!el || !registered) return;
          el.columns = columns;
          el.rows = rows;
          el.loading = isLoading;
        }, [rows, isLoading, registered, columns]);

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
    setOutputQuantity("1");
    setLines([emptyLine()]);
  };

  const handleSubmit = () => {
    createBOM.mutate(
      {
        productId: Number(productId),
        bomCode,
        bomName,
        outputQuantity: Number(outputQuantity),
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
      <Box
        sx={{
          display: "flex",
          flexDirection: { xs: "column", sm: "row" },
          justifyContent: "space-between",
          alignItems: { xs: "stretch", sm: "center" },
          gap: 2,
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={600}>
          Lista de Materiales (BOM)
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => { resetForm(); setDialogOpen(true); }}
          fullWidth={isMobile}
        >
          Nueva BOM
        </Button>
      </Box>

      {/* Filters */}
      <ZenttoFilterPanel
        filters={BOM_FILTERS}
        values={filterValues}
        onChange={(vals) => {
          setFilterValues(vals);
          setFilter((f) => ({ ...f, status: vals.estado || undefined }));
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por codigo, nombre..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="manufactura-bom-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-grouping
      ></zentto-grid>

      {/* Dialog: Crear BOM */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "md"}
        fullWidth
      >
        {isMobile ? (
          <AppBar sx={{ position: "relative" }}>
            <Toolbar>
              <IconButton edge="start" color="inherit" onClick={() => setDialogOpen(false)}>
                <CloseIcon />
              </IconButton>
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">
                Nueva Lista de Materiales
              </Typography>
              <Button
                color="inherit"
                onClick={handleSubmit}
                disabled={createBOM.isPending || !bomCode || !bomName || !productId}
              >
                {createBOM.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Nueva Lista de Materiales</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Codigo BOM"
                value={bomCode}
                onChange={(e) => setBomCode(e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre BOM"
                value={bomName}
                onChange={(e) => setBomName(e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Producto Terminado (ID)"
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Cantidad a Producir"
                value={outputQuantity}
                onChange={(e) => setOutputQuantity(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
          </Grid>

          <Typography variant="subtitle2" sx={{ mt: 3, mb: 1, fontWeight: 600 }}>
            Componentes / Materiales
          </Typography>
          {lines.map((line, idx) => (
            <Grid container spacing={1} key={idx} sx={{ mb: 1 }} alignItems="center">
              <Grid item xs={6} sm={2}>
                <TextField
                  label="Producto (ID)"
                  value={line.productId}
                  onChange={(e) => handleLineChange(idx, "productId", e.target.value)}
                  type="number"
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={6} sm={3}>
                <TextField
                  label="Nombre"
                  value={line.productName}
                  onChange={(e) => handleLineChange(idx, "productName", e.target.value)}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Cantidad"
                  type="number"
                  value={line.quantity}
                  onChange={(e) => handleLineChange(idx, "quantity", Number(e.target.value))}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={4} sm={2}>
                <TextField
                  label="Unidad"
                  value={line.unitOfMeasure}
                  onChange={(e) => handleLineChange(idx, "unitOfMeasure", e.target.value)}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={3} sm={2}>
                <TextField
                  label="Costo Unit."
                  type="number"
                  value={line.unitCost}
                  onChange={(e) => handleLineChange(idx, "unitCost", Number(e.target.value))}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={1} sm={1}>
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
              </Grid>
            </Grid>
          ))}
          <Button size="small" onClick={handleAddLine} startIcon={<AddIcon />}>
            Agregar componente
          </Button>
        </DialogContent>
        {!isMobile && (
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
        )}
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
