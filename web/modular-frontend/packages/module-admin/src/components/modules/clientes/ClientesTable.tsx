// components/modules/clientes/ClientesTable.tsx
"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Typography } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import {
  DeleteDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import { useCrudGeneric } from "../../../hooks/useCrudGeneric";
import { Cliente } from "@zentto/shared-api/types";
import type { ColumnDef } from "@zentto/datagrid-core";


const CLIENTE_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "Activo", label: "Activo" },
      { value: "Inactivo", label: "Inactivo" },
      { value: "Suspendido", label: "Suspendido" },
    ],
  },
];

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 100, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "rif", header: "RIF", width: 130, sortable: true },
  { field: "email", header: "Email", width: 200 },
  { field: "telefono", header: "Telefono", width: 140 },
  { field: "saldo", header: "Saldo", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "estado",
    header: "Estado",
    width: 110,
    statusColors: { Activo: "success", Inactivo: "error", Suspendido: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 130, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

export default function ClientesTable() {
  const router = useRouter();
  const crud = useCrudGeneric<Cliente>("clientes");
  const { data, isLoading } = crud.list();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Cliente | null>(null);

  const { mutate: deleteCliente, isPending: isDeleting } = crud.delete("");

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // Filtrado local
  const filteredData = useMemo(() => {
    const items = data?.items || data?.data || [];
    let filtered = items;
    if (search) {
      const term = search.toLowerCase();
      filtered = filtered.filter(
        (client: Cliente) =>
          client.nombre.toLowerCase().includes(term) ||
          client.rif.includes(search)
      );
    }
    if (filterValues.estado) {
      filtered = filtered.filter(
        (client: Cliente) => client.estado === filterValues.estado
      );
    }
    return filtered;
  }, [data, search, filterValues]);

  const rows = useMemo(
    () =>
      filteredData.map((client: Cliente, idx: number) => ({
        id: client.codigo || idx,
        ...client,
      })),
    [filteredData]
  );

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  // Listen for action-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`/clientes/${row.codigo}`);
      if (action === "edit") router.push(`/clientes/${row.codigo}/edit`);
      if (action === "delete") {
        const client = filteredData.find((c: Cliente) => c.codigo === row.codigo);
        if (client) {
          setSelectedClient(client);
          setDeleteOpen(true);
        }
      }
    };

    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, router, filteredData]);

  const handleDeleteConfirm = () => {
    if (selectedClient) {
      deleteCliente(selectedClient.codigo, {
        onSuccess: () => {
          setDeleteOpen(false);
          setSelectedClient(null);
        },
      });
    }
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Gestion de Clientes
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/clientes/new")}>
          Nuevo Cliente
        </Button>
      </Box>

      {/* Filtros */}
      <ZenttoFilterPanel
        filters={CLIENTE_FILTERS}
        values={filterValues}
        onChange={setFilterValues}
        searchPlaceholder="Buscar por nombre o RIF..."
        searchValue={search}
        onSearchChange={setSearch}
      />

      {/* zentto-grid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="clientes"
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
          ></zentto-grid>
        )}
      </Box>

      <DeleteDialog
        open={deleteOpen}
        itemName={selectedClient?.nombre || ""}
        onConfirm={handleDeleteConfirm}
        onClose={() => {
          setDeleteOpen(false);
          setSelectedClient(null);
        }}
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
