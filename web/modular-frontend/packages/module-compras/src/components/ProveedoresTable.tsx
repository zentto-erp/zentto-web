// components/ProveedoresTable.tsx
"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  CircularProgress,
  Typography,
} from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import {
  DeleteDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useProveedoresList, useDeleteProveedor } from "../hooks/useProveedores";
import { Proveedor, ProveedorFilter } from "@zentto/shared-api/types";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 120, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 180, sortable: true },
  { field: "rif", header: "RIF", width: 140, sortable: true },
  { field: "email", header: "Email", flex: 1, minWidth: 160, sortable: true },
  { field: "telefono", header: "Telefono", width: 130, sortable: true },
  { field: "saldo", header: "Saldo", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "estado", header: "Estado", width: 120, sortable: true,
    statusColors: {
      Activo: "success",
      ACTIVE: "success",
      Inactivo: "error",
      INACTIVE: "error",
    },
    statusVariant: "outlined",
  },
];

const PROVEEDORES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "Activo", label: "Activo" },
      { value: "Inactivo", label: "Inactivo" },
    ],
  },
];

export default function ProveedoresTable() {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedProveedor, setSelectedProveedor] = useState<Proveedor | null>(null);

  // Queries
  const { data, isLoading } = useProveedoresList({
    search,
    estado: filterValues.estado || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  } as ProveedorFilter);
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();

  const rows: GridRow[] = ((data?.items ?? []) as unknown as Record<string, unknown>[]).map((r) => ({
    id: r.codigo ?? r.id ?? Math.random(),
    ...r,
  }));
  const total = data?.total ?? 0;

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

  // Register web component
  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // Bind data to grid
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.actionButtons = [
      { icon: SVG_VIEW, label: "Ver", action: "view" },
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#e67e22" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

  // Listen for action events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
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
    el.addEventListener("action", handler);
    return () => el.removeEventListener("action", handler);
  }, [registered, router]);

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Gestion de Proveedores
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/proveedores/new")}
        >
          Nuevo Proveedor
        </Button>
      </Box>

      {/* Filters */}
      <ZenttoFilterPanel
        filters={PROVEEDORES_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por nombre o RIF..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
      />

      {/* DataGrid */}
      {!registered ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="proveedores"
          height="calc(100vh - 280px)"
          show-totals
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
        ></zentto-grid>
      )}

      {/* Delete Dialog */}
      <DeleteDialog
        open={deleteOpen}
        onClose={() => { setDeleteOpen(false); setSelectedProveedor(null); }}
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
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
