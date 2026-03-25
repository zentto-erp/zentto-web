// components/CuentasPorPagarTable.tsx
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
import { useCuentasPorPagarList, useDeleteCuentaPorPagar } from "../hooks/useCuentasPorPagar";
import { formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';

const COLUMNS: ColumnDef[] = [
  { field: "nombreProveedor", header: "Proveedor", flex: 1, minWidth: 180, sortable: true },
  { field: "numeroReferencia", header: "Num Ref", width: 130, sortable: true },
  { field: "fechaCreacion", header: "Fecha", width: 130, type: "date", sortable: true },
  { field: "fechaVencimiento", header: "Vencimiento", width: 130, type: "date", sortable: true },
  { field: "montoTotal", header: "Monto", width: 130, type: "number", currency: "VES" },
  { field: "saldo", header: "Saldo", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "diasVencidos", header: "Dias Vencidos", width: 130, type: "number" },
  {
    field: "estado", header: "Estado", width: 130, sortable: true,
    statusColors: {
      Pagada: "success",
      Pendiente: "warning",
      Vencida: "error",
      Parcial: "info",
    },
    statusVariant: "outlined",
  },
];

const CUENTAS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "Pendiente", label: "Pendiente" },
      { value: "Pagada", label: "Pagada" },
      { value: "Vencida", label: "Vencida" },
      { value: "Parcial", label: "Parcial" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
  { field: "proveedor", label: "Proveedor", type: "text", placeholder: "Nombre del proveedor..." },
];

export default function CuentasPorPagarTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCuenta, setSelectedCuenta] = useState<Record<string, unknown> | null>(null);

  const { data: cuentas, isLoading } = useCuentasPorPagarList({
    search,
    estado: filterValues.estado || undefined,
    from: filterValues.from || undefined,
    to: filterValues.to || undefined,
    proveedor: filterValues.proveedor?.trim() || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });

  const { mutate: deleteCuenta, isPending: isDeleting } = useDeleteCuentaPorPagar();

  const handleConfirmDelete = () => {
    if (selectedCuenta) {
      deleteCuenta(String(selectedCuenta.id), {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedCuenta(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
        },
      });
    }
  };

  const rawRows = (cuentas?.data ?? []) as Record<string, unknown>[];
  const total = cuentas?.total ?? 0;

  // Compute diasVencidos on the fly
  const rows: GridRow[] = rawRows.map((r) => {
    const vencimiento = r.fechaVencimiento ? new Date(String(r.fechaVencimiento)) : null;
    const estado = String(r.estado ?? "");
    let diasVencidos = 0;
    if (vencimiento && estado !== "Pagada") {
      const diff = Math.floor((Date.now() - vencimiento.getTime()) / (1000 * 60 * 60 * 24));
      if (diff > 0) diasVencidos = diff;
    }
    return {
      id: r.id ?? r.numeroReferencia ?? Math.random(),
      ...r,
      diasVencidos,
    };
  });

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
        router.push(`/cuentas-por-pagar/${row.id}`);
      } else if (action === "delete") {
        setSelectedCuenta(row);
        setDeleteDialogOpen(true);
      }
    };
    el.addEventListener("action", handler);
    return () => el.removeEventListener("action", handler);
  }, [registered, router]);

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Cuentas por Pagar
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/cuentas-por-pagar/new")}
        >
          Nueva Cuenta
        </Button>
      </Box>

      <ZenttoFilterPanel
        filters={CUENTAS_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por proveedor, numero o referencia..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
      />

      {!registered ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="cuentas-por-pagar"
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

      <DeleteDialog
        open={deleteDialogOpen}
        onClose={() => { setDeleteDialogOpen(false); setSelectedCuenta(null); }}
        onConfirm={handleConfirmDelete}
        itemName={selectedCuenta ? `la cuenta ${selectedCuenta.numeroReferencia ?? ""}` : "esta cuenta por pagar"}
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
