// components/modules/abonos/AbonosaTable.tsx
"use client";

import { useState, useMemo, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Typography } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import { ConfirmDialog, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { useAbonosList, useDeleteAbono } from "../../../hooks/useAbonos";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";
import type { ColumnDef } from "@zentto/datagrid-core";


const ABONO_FILTERS: FilterFieldDef[] = [
  { field: "cliente", label: "Cliente", type: "text", placeholder: "Nombre del cliente..." },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

export default function AbonosTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAbono, setSelectedAbono] = useState<string | null>(null);

  // Filtros
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  const handleFilterChange = (vals: Record<string, string>) => {
    setFilterValues(vals);
    setPage(0);
  };

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setPage(0);
  };

  const { data: abonos, isLoading } = useAbonosList({
    search: search || undefined,
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

  // Listen for action-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`/abonos/${row.numeroAbono}`);
      if (action === "delete") handleDeleteClick(row.numeroAbono);
    };

    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, router]);

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Abonos
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/abonos/new")}>
          Nuevo Abono
        </Button>
      </Box>

      {/* Filtros */}
      <ZenttoFilterPanel
        filters={ABONO_FILTERS}
        values={filterValues}
        onChange={handleFilterChange}
        searchPlaceholder="Buscar por numero, cliente o factura..."
        searchValue={search}
        onSearchChange={handleSearchChange}
      />

      {/* zentto-grid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
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
