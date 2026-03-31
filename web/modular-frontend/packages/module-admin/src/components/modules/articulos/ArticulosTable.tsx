// components/modules/articulos/ArticulosTable.tsx
// Tabla de articulos con filtros avanzados: selectores, rangos, comodines
"use client";

import { useState, useMemo, useEffect, useRef } from "react";
import { useRouter, usePathname } from "next/navigation";
import {
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Typography,
  Stack,
  Tooltip,
} from "@mui/material";
import {
  ViewColumn as ViewColumnIcon,
} from "@mui/icons-material";
import { useArticulosList, useDeleteArticulo } from "../../../hooks/useArticulos";
import { apiGet, useGridLayoutSync } from "@zentto/shared-api";
import { useQuery } from "@tanstack/react-query";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";


export default function ArticulosTable() {
  const router = useRouter();
  const pathname = usePathname() || '';
  const basePath = pathname.includes('/inventario/') ? '/inventario/articulos' : '/articulos';
  const gridRef = useRef<any>(null);
  const gridId = useScopedGridId('articulos-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);

  // ========== Estado del DataGrid ==========
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 20 });
  const [sortModel, setSortModel] = useState([{ field: "codigo", sort: "asc" as const }]);

  // ========== UI ==========
  const [extendedView, setExtendedView] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedArticulo, setSelectedArticulo] = useState<string | null>(null);

  // ========== Queries ==========
  const sort = sortModel[0];
  const { data: articulosData, isLoading } = useArticulosList({
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
    sortBy: sort?.field,
    sortOrder: sort?.sort,
  });
  const { data: tasaData } = useQuery({
    queryKey: ["config-tasas"],
    queryFn: () => apiGet("/v1/config/tasas") as Promise<{ USD?: number }>,
    staleTime: 10 * 60 * 1000,
  });
  const tasaCambio = tasaData?.USD || 1;
  const { mutate: deleteArticulo, isPending: isDeleting } = useDeleteArticulo();

  // ========== Columnas del DataGrid ==========
  const columns = useMemo<ColumnDef[]>(
    () => {
      const base: ColumnDef[] = [
        { field: "codigo", header: "Codigo", width: 120, sortable: true },
        { field: "descripcion", header: "Articulo", flex: 1, minWidth: 200, sortable: true },
        { field: "categoria", header: "Categoria", width: 110, sortable: true },
        { field: "precioCompra", header: "Costo", width: 110, type: "number", currency: "VES", sortable: true },
        { field: "precioVenta", header: "Precio", width: 110, type: "number", currency: "VES", sortable: true },
        { field: "precioUsd", header: "Precio ($)", width: 100, type: "number", currency: "USD" },
        { field: "stock", header: "Stock", width: 80, type: "number", sortable: true, aggregation: "sum" },
        {
          field: "estado", header: "Estado", width: 100, sortable: true,
          statusColors: { Activo: "success", Inactivo: "error" },
          statusVariant: "outlined",
        },
      ];

      const extended: ColumnDef[] = [
        { field: "referencia", header: "Referencia", width: 120, sortable: true },
        { field: "marca", header: "Marca", width: 110, sortable: true },
        { field: "linea", header: "Linea", width: 100, sortable: true },
        { field: "clase", header: "Clase", width: 100, sortable: true },
        { field: "unidad", header: "Unidad", width: 80, sortable: true },
        { field: "tipo", header: "Tipo", width: 100, sortable: true },
        { field: "minimo", header: "Minimo", width: 80, type: "number", sortable: true },
        { field: "maximo", header: "Maximo", width: 80, type: "number", sortable: true },
        { field: "barra", header: "Cod. Barras", width: 120, sortable: true },
        { field: "nParte", header: "N. Parte", width: 110, sortable: true },
        { field: "ubicacion", header: "Ubicacion", width: 100, sortable: true },
      ];

      const actionsCol: ColumnDef = {
        field: "actions", header: "Acciones", type: "actions" as any, width: 130, pin: "right",
        actions: [
          { icon: "view", label: "Ver detalle", action: "view" },
          { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
          { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
        ],
      } as ColumnDef;

      return extendedView ? [...base, ...extended, actionsCol] : [...base, actionsCol];
    },
    [extendedView]
  );

  // ========== Filas mapeadas ==========
  const rawRows = articulosData?.data ?? [];
  const totalRows = articulosData?.total ?? 0;

  const rows = useMemo(
    () =>
      rawRows.map((item: any) => ({
        ...item,
        id: item.codigo,
        precioUsd: tasaCambio > 1 && (item.precioVenta ?? 0) > 0
          ? Number(((item.precioVenta ?? 0) / tasaCambio).toFixed(2))
          : 0,
      })),
    [rawRows, tasaCambio]
  );

  // ========== Eliminar ==========
  const handleDelete = () => {
    if (!selectedArticulo) return;
    deleteArticulo(selectedArticulo, {
      onSuccess: () => {
        setDeleteDialogOpen(false);
        setSelectedArticulo(null);
      },
    });
  };

  // ========== Bind data to web component ==========
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [columns, rows, isLoading, registered]);

  // ========== Listen for action-click and create-click events ==========
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`${basePath}/${row.codigo}`);
      if (action === "edit") router.push(`${basePath}/${row.codigo}/edit`);
      if (action === "delete") {
        setSelectedArticulo(row.codigo);
        setDeleteDialogOpen(true);
      }
    };
    const createHandler = () => router.push(`${basePath}/new`);

    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, router, basePath]);

  // ========== RENDER ==========
  return (
    <Box sx={{ width: "100%", flex: 1, display: "flex", flexDirection: "column", minHeight: 0, height: "100%" }}>
      {/* ===== BARRA SUPERIOR: Botones ===== */}
      <Stack direction="row" spacing={1} alignItems="center" justifyContent="flex-end" sx={{ mb: 2 }}>
        <Tooltip title="Vista compacta / extendida">
          <Button
            variant={extendedView ? "contained" : "outlined"}
            startIcon={<ViewColumnIcon />}
            onClick={() => setExtendedView(!extendedView)}
            size="small"
          >
            {extendedView ? "Compacta" : "Extendida"}
          </Button>
        </Tooltip>

        <Tooltip title="Registrar entrada o salida de stock">
          <Button
            variant="outlined"
            onClick={() => router.push("/inventario/ajuste")}
            size="small"
          >
            Ajuste de Inventario
          </Button>
        </Tooltip>
      </Stack>

      {/* ===== DATA GRID ===== */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            default-currency="VES"
            export-filename="articulos"
            height="100%"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-create
            create-label="Nuevo Articulo"
          ></zentto-grid>
        )}
      </Box>

      {/* ===== DIALOG ELIMINAR ===== */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirmar eliminacion</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de que desea eliminar el articulo <strong>{selectedArticulo}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={isDeleting}>
            Cancelar
          </Button>
          <Button
            onClick={handleDelete}
            color="error"
            variant="contained"
            disabled={isDeleting}
          >
            {isDeleting ? "Eliminando..." : "Eliminar"}
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
