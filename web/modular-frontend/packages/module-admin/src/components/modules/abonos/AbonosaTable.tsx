// components/modules/abonos/AbonosaTable.tsx
"use client";

import { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Box, Typography } from "@mui/material";
import { ConfirmDialog } from "@zentto/shared-ui";
import { useAbonosList, useDeleteAbono } from "../../../hooks/useAbonos";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";


export default function AbonosTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const gridId = useScopedGridId('abonos-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAbono, setSelectedAbono] = useState<string | null>(null);

  const { data: abonos, isLoading } = useAbonosList({
    page: page + 1,
    limit: pageSize,
  });

  const { mutate: deleteAbono, isPending: isDeleting } = useDeleteAbono();

  const handleDeleteClick = (numero: string) => {
    setSelectedAbono(numero);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedAbono) {
      deleteAbono(selectedAbono, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedAbono(null);
        },
        onError: (err) => {
          console.error("Error eliminando:", err);
        },
      });
    }
  };

  const columns = useMemo<ColumnDef[]>(
    () => [
      { field: "numeroAbono", header: "Numero Abono", width: 140, sortable: true },
      { field: "nombreCliente", header: "Cliente", flex: 1, minWidth: 180, sortable: true },
      { field: "numeroFactura", header: "Factura", width: 140, sortable: true },
      { field: "fecha", header: "Fecha", width: 120, type: "date", sortable: true },
      { field: "monto", header: "Monto", width: 140, type: "number", currency: "VES", aggregation: "sum" },
      {
        field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
        actions: [
          { icon: "view", label: "Ver", action: "view" },
          { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
        ],
      } as ColumnDef,
    ],
    []
  );

  const rows = useMemo(
    () =>
      (abonos?.data || []).map((a: any, idx: number) => ({
        id: a.numeroAbono || idx,
        ...a,
        fecha: a.fecha ? toDateOnly(a.fecha, timeZone) : "",
      })),
    [abonos?.data, timeZone]
  );

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [columns, rows, isLoading, registered]);

  // Listen for action-click and create-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`/abonos/${row.numeroAbono}`);
      if (action === "delete") handleDeleteClick(row.numeroAbono);
    };
    const createHandler = () => router.push("/abonos/new");

    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, router]);

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
        Abonos
      </Typography>

      {/* zentto-grid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            default-currency="VES"
            export-filename="abonos"
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
            create-label="Nuevo Abono"
          ></zentto-grid>
        )}
      </Box>

      <ConfirmDialog
        open={deleteDialogOpen}
        title="Eliminar Abono"
        message={`Esta seguro de que desea eliminar el abono ${selectedAbono || ""}?`}
        confirmLabel={isDeleting ? "Eliminando..." : "Eliminar"}
        variant="danger"
        onConfirm={handleConfirmDelete}
        onClose={() => {
          setDeleteDialogOpen(false);
          setSelectedAbono(null);
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
