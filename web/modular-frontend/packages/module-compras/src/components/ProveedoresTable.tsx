// components/ProveedoresTable.tsx
"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  CircularProgress,
} from "@mui/material";
import { DeleteDialog } from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useComprasGridRegistration } from "./zenttoGridPersistence";
import { useProveedoresList, useDeleteProveedor } from "../hooks/useProveedores";
import { Proveedor, ProveedorFilter } from "@zentto/shared-api/types";


const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 120, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 180, sortable: true, groupable: true },
  { field: "rif", header: "RIF", width: 140, sortable: true },
  { field: "email", header: "Email", flex: 1, minWidth: 160, sortable: true },
  { field: "telefono", header: "Telefono", width: 130, sortable: true },
  { field: "saldo", header: "Saldo", width: 130, type: "number", currency: "VES", aggregation: "sum", sortable: true },
  {
    field: "estado",
    header: "Estado",
    width: 120,
    sortable: true,
    groupable: true,
    statusColors: {
      Activo: "success",
      ACTIVE: "success",
      Inactivo: "error",
      INACTIVE: "error",
    },
    statusVariant: "outlined",
  },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 130,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  },
];

const GRID_ID = "module-compras:proveedores:list";

export default function ProveedoresTable() {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useComprasGridRegistration(gridLayoutReady);
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 50 });
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedProveedor, setSelectedProveedor] = useState<Proveedor | null>(null);

  const { data, isLoading } = useProveedoresList({
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  } as ProveedorFilter);
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();
  const rows: GridRow[] = ((data?.items ?? []) as unknown as Record<string, unknown>[]).map((r) => ({
    id: r.codigo ?? r.id ?? Math.random(),
    ...r,
  }));

  const handleDeleteConfirm = () => {
    if (selectedProveedor) {
      deleteProveedor(selectedProveedor.codigo, {
        onSuccess: () => {
          setDeleteOpen(false);
          setSelectedProveedor(null);
        },
      });
    }
  };

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") {
        router.push(`/proveedores/${row.codigo}`);
      } else if (action === "edit") {
        router.push(`/proveedores/${row.codigo}/edit`);
      } else if (action === "delete") {
        setSelectedProveedor(row as unknown as Proveedor);
        setDeleteOpen(true);
      }
    };
    const createHandler = () => router.push("/proveedores/new");
    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, router]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {!gridLayoutReady || !registered ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid
            ref={gridRef}
            grid-id={GRID_ID}
            default-currency="VES"
            export-filename="proveedores"
            height="calc(100vh - 200px)"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-grouping
            enable-pivot
            enable-create
            create-label="Nuevo Proveedor"
          />
        </Box>
      )}

      <DeleteDialog
        open={deleteOpen}
        onClose={() => {
          setDeleteOpen(false);
          setSelectedProveedor(null);
        }}
        onConfirm={handleDeleteConfirm}
        itemName={selectedProveedor ? `el proveedor ${selectedProveedor.nombre}` : "este proveedor"}
        loading={isDeleting}
      />
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-grid": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}
