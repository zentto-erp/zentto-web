"use client";

import { useMemo, useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  CircularProgress,
  Typography,
} from "@mui/material";
import { Add } from "@mui/icons-material";
import { ConfirmDialog } from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useComprasList, useDeleteCompra } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { apiGet, toDateOnly } from "@zentto/shared-api";
import { useToast } from "@zentto/shared-ui";

// ─── SVG icons for action buttons ───────────────────────────────────────────
const SVG_VIEW =
  '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT =
  '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE =
  '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';

// ─── Master columns (encabezado de compra) ──────────────────────────────────
const COLUMNS: ColumnDef[] = [
  { field: "documentNumber", header: "Numero", width: 130, sortable: true, groupable: true },
  { field: "supplierName", header: "Proveedor", flex: 1, minWidth: 180, sortable: true, groupable: true },
  { field: "issueDate", header: "Fecha", width: 130, type: "date", sortable: true },
  {
    field: "documentType",
    header: "Tipo",
    width: 120,
    sortable: true,
    groupable: true,
    statusColors: { CONTADO: "success", CREDITO: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "status",
    header: "Estado",
    width: 130,
    sortable: true,
    groupable: true,
    statusColors: {
      DRAFT: "default",
      EMITIDA: "info",
      ANULADA: "error",
      RECIBIDA: "success",
      PARCIAL: "warning",
    },
    statusVariant: "outlined",
  },
  {
    field: "totalAmount",
    header: "Total",
    width: 140,
    type: "number",
    currency: "VES",
    aggregation: "sum",
    sortable: true,
  },
];

// ─── Detail columns (lineas de compra) ──────────────────────────────────────
const DETAIL_COLUMNS: ColumnDef[] = [
  { field: "ProductCode", header: "Codigo", width: 120, sortable: true },
  { field: "Description", header: "Descripcion", flex: 1, minWidth: 200, sortable: true },
  { field: "Quantity", header: "Cant.", width: 90, type: "number", aggregation: "sum" },
  { field: "UnitPrice", header: "P. Unit.", width: 120, type: "number", currency: "VES" },
  { field: "TaxRate", header: "IVA %", width: 80, type: "number" },
  { field: "DiscountAmount", header: "Desc.", width: 100, type: "number", currency: "VES" },
  { field: "TotalAmount", header: "Total", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

// ─── Component ──────────────────────────────────────────────────────────────
export default function ComprasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const { showToast } = useToast();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const deleteMutation = useDeleteCompra();

  // Detail cache: documentNumber → detail rows
  const detailCache = useRef<Record<string, GridRow[]>>({});

  function firstDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth(), 1), timeZone);
  }
  function lastDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth() + 1, 0), timeZone);
  }

  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 50 });

  const filter = useMemo(
    () => ({
      fechaDesde: firstDayOfCurrentMonth(),
      fechaHasta: lastDayOfCurrentMonth(),
      page: paginationModel.page + 1,
      limit: paginationModel.pageSize,
    }),
    [paginationModel]
  );

  const { data, isLoading } = useComprasList(filter);

  const rows: GridRow[] = useMemo(
    () =>
      ((data?.rows ?? []) as Record<string, unknown>[]).map((r) => ({
        id: r.documentNumber ?? r.id ?? Math.random(),
        ...r,
        supplierName: r.supplierName || r.supplierCode || "",
        _details: [] as GridRow[],
      })),
    [data?.rows]
  );

  // Anular dialog
  const [anularOpen, setAnularOpen] = useState(false);
  const [anularRow, setAnularRow] = useState<Record<string, unknown> | null>(null);

  // Register web component
  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // Fetch detail lines for a given document
  const fetchDetail = useCallback(
    async (docNumber: string) => {
      if (detailCache.current[docNumber]) return detailCache.current[docNumber];
      try {
        const raw = (await apiGet(
          `/v1/documentos-compra/COMPRA/${encodeURIComponent(docNumber)}/detalle`
        )) as Record<string, unknown>[];
        const mapped: GridRow[] = (raw || []).map((d, idx) => ({
          id: `${docNumber}_${idx}`,
          ProductCode: d.ProductCode ?? d.CODIGO ?? "",
          Description: d.Description ?? d.DESCRIPCION ?? "",
          Quantity: Number(d.Quantity ?? d.CANTIDAD ?? 0),
          UnitPrice: Number(d.UnitPrice ?? d.PRECIO_COSTO ?? 0),
          TaxRate: Number(d.TaxRate ?? d.Alicuota ?? d.ALICUOTA ?? 0),
          DiscountAmount: Number(d.DiscountAmount ?? d.DESCUENTO ?? 0),
          TotalAmount: Number(d.TotalAmount ?? d.SUBTOTAL ?? 0),
        }));
        detailCache.current[docNumber] = mapped;
        return mapped;
      } catch {
        return [];
      }
    },
    []
  );

  // Bind data to grid
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;

    // Action buttons (CRUD)
    el.actionButtons = [
      { icon: SVG_VIEW, label: "Ver", action: "view" },
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#e67e22" },
      { icon: SVG_DELETE, label: "Anular", action: "delete", color: "#dc2626" },
    ];

    // Master-detail
    el.detailColumns = DETAIL_COLUMNS;
    el.detailRowsAccessor = (row: GridRow) => {
      const docNum = String(row.documentNumber ?? "");
      const cached = detailCache.current[docNum];
      if (cached) return cached;
      // Trigger async fetch — grid will re-render when data arrives
      fetchDetail(docNum).then((details) => {
        if (details.length > 0) {
          // Update the row in the grid to trigger re-render
          const currentRows = el.rows as GridRow[];
          el.rows = currentRows.map((r: GridRow) =>
            String(r.documentNumber) === docNum ? { ...r, _details: details } : r
          );
        }
      });
      return [];
    };
  }, [rows, isLoading, registered, fetchDetail]);

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
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, router]);

  const handleAnularConfirm = async () => {
    if (!anularRow?.documentNumber) return;
    try {
      await deleteMutation.mutateAsync(String(anularRow.documentNumber));
      showToast("Compra anulada correctamente", "success");
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error al anular compra", "error");
    } finally {
      setAnularOpen(false);
      setAnularRow(null);
    }
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Compras
        </Typography>
        <Button variant="contained" startIcon={<Add />} onClick={() => router.push("/compras/new")}>
          Nueva Compra
        </Button>
      </Box>

      {!registered ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="compras-list"
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
            enable-master-detail
            enable-grouping
            enable-pivot
          />
        </Box>
      )}

      <ConfirmDialog
        open={anularOpen}
        onClose={() => {
          setAnularOpen(false);
          setAnularRow(null);
        }}
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
      "zentto-grid": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}
