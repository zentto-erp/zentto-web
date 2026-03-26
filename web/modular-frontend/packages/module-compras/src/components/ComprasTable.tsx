"use client";

import { useMemo, useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  CircularProgress,
} from "@mui/material";
import { ConfirmDialog } from "@zentto/shared-ui";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useComprasList, useDeleteCompra } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { apiGet, toDateOnly } from "@zentto/shared-api";
import { useToast } from "@zentto/shared-ui";

// Icon names resolved by zentto-grid's built-in icon system (v0.3.1+)

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
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 130,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Anular", action: "delete", color: "#dc2626" },
    ],
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
    const actionHandler = (e: CustomEvent) => {
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
    const createHandler = () => router.push("/compras/new");
    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
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
            enable-create
            create-label="Nueva Compra"
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
