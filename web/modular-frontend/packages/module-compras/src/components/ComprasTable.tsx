"use client";

import { useMemo, useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  CircularProgress,
  Typography,
} from "@mui/material";
import { Add } from "@mui/icons-material";
import {
  ConfirmDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useComprasList } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, formatDate } from "@zentto/shared-api";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';

const COLUMNS: ColumnDef[] = [
  { field: "documentNumber", header: "Numero", width: 130, sortable: true },
  { field: "supplierName", header: "Proveedor", flex: 1, minWidth: 180, sortable: true },
  { field: "issueDate", header: "Fecha", width: 130, type: "date", sortable: true },
  {
    field: "documentType", header: "Tipo", width: 120, sortable: true,
    statusColors: { CONTADO: "success", CREDITO: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "status", header: "Estado", width: 130, sortable: true,
    statusColors: {
      DRAFT: "default",
      EMITIDA: "info",
      ANULADA: "error",
      RECIBIDA: "success",
      PARCIAL: "warning",
    },
    statusVariant: "outlined",
  },
  { field: "totalAmount", header: "Total", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

const COMPRAS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "EMITIDA", label: "Emitida" },
      { value: "RECIBIDA", label: "Recibida" },
      { value: "PARCIAL", label: "Parcial" },
      { value: "ANULADA", label: "Anulada" },
    ],
  },
  {
    field: "tipo",
    label: "Tipo",
    type: "select",
    options: [
      { value: "CONTADO", label: "Contado" },
      { value: "CREDITO", label: "Credito" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
  { field: "proveedor", label: "Proveedor", type: "text", placeholder: "Nombre del proveedor..." },
];

export default function ComprasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  function firstDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth(), 1), timeZone);
  }

  function lastDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth() + 1, 0), timeZone);
  }

  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({
    from: firstDayOfCurrentMonth(),
    to: lastDayOfCurrentMonth(),
  });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 50 });

  // Anular dialog
  const [anularOpen, setAnularOpen] = useState(false);
  const [anularRow, setAnularRow] = useState<Record<string, unknown> | null>(null);

  const filter = useMemo(
    () => ({
      search: search.trim() || undefined,
      fechaDesde: filterValues.from || undefined,
      fechaHasta: filterValues.to || undefined,
      estado: filterValues.estado || undefined,
      tipo: filterValues.tipo || undefined,
      proveedor: filterValues.proveedor?.trim() || undefined,
      page: paginationModel.page + 1,
      limit: paginationModel.pageSize,
    }),
    [search, filterValues, paginationModel]
  );

  const { data, isLoading } = useComprasList(filter);

  const rows: GridRow[] = ((data?.rows ?? []) as Record<string, unknown>[]).map((r) => ({
    id: r.documentNumber ?? r.id ?? Math.random(),
    ...r,
    supplierName: r.supplierName || r.supplierCode || "",
  }));
  const total = data?.total ?? 0;

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
      { icon: SVG_DELETE, label: "Anular", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

  // Listen for action events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") {
        router.push(`/compras/${encodeURIComponent(String(row.documentNumber))}`);
      } else if (action === "edit") {
        router.push(`/compras/${encodeURIComponent(String(row.documentNumber))}/edit`);
      } else if (action === "delete") {
        setAnularRow(row);
        setAnularOpen(true);
      }
    };
    el.addEventListener("action", handler);
    return () => el.removeEventListener("action", handler);
  }, [registered, router]);

  const handleAnularConfirm = () => {
    // TODO: integrar mutacion de anulacion cuando el endpoint exista
    setAnularOpen(false);
    setAnularRow(null);
  };

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Compras
        </Typography>
        <Button variant="contained" startIcon={<Add />} onClick={() => router.push("/compras/new")}>
          Nueva Compra
        </Button>
      </Box>

      <ZenttoFilterPanel
        filters={COMPRAS_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por numero, proveedor, rif..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        defaultOpen
      />

      {!registered ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="compras-list"
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

      <ConfirmDialog
        open={anularOpen}
        onClose={() => { setAnularOpen(false); setAnularRow(null); }}
        onConfirm={handleAnularConfirm}
        title="Anular Compra"
        message={`Estas seguro de que deseas anular la compra ${anularRow?.documentNumber ?? ""}? Esta accion no se puede deshacer.`}
        confirmLabel="Anular"
        variant="danger"
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
