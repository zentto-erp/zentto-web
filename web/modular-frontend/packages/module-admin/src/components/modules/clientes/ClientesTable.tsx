// components/modules/clientes/ClientesTable.tsx
"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Box, Typography } from "@mui/material";
import { DeleteDialog } from "@zentto/shared-ui";
import { useCrudGeneric } from "../../../hooks/useCrudGeneric";
import { Cliente } from "@zentto/shared-api/types";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";


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
  const gridId = useScopedGridId('clientes-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Cliente | null>(null);

  const { mutate: deleteCliente, isPending: isDeleting } = crud.delete("");

  const allItems = data?.items || data?.data || [];
  const rows = useMemo(
    () =>
      allItems.map((client: Cliente, idx: number) => ({
        id: client.codigo || idx,
        ...client,
      })),
    [allItems]
  );

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  // Listen for action-click and create-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`/clientes/${row.codigo}`);
      if (action === "edit") router.push(`/clientes/${row.codigo}/edit`);
      if (action === "delete") {
        const client = allItems.find((c: Cliente) => c.codigo === row.codigo);
        if (client) {
          setSelectedClient(client);
          setDeleteOpen(true);
        }
      }
    };
    const createHandler = () => router.push("/clientes/new");

    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, router, allItems]);

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
      <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
        Gestion de Clientes
      </Typography>

      {/* zentto-grid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
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
            enable-create
            create-label="Nuevo Cliente"
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
