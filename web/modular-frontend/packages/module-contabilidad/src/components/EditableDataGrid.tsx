"use client";

import * as React from "react";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import AddIcon from "@mui/icons-material/Add";
import type { ColumnDef } from "@zentto/datagrid-core";

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

// ---- Tipos ----
export interface EditableDataGridProps<T extends { id?: string | number }> {
  rows: T[];
  columns: ColumnDef[];
  onSave: (row: T) => Promise<void> | void;
  onDelete: (id: string | number) => Promise<void> | void;
  onCancel?: (id: string | number) => void;
  loading?: boolean;
  height?: number | string;
  flexFill?: boolean;
  title?: string;
  addButtonText?: string;
  hideAddButton?: boolean;
  getRowId?: (row: T) => string | number;
  onRowClick?: (row: T) => void;
  extraActions?: (row: T) => React.ReactElement[];
  defaultNewRow?: Partial<T>;
}

// ---- Componente Principal ----
export default function EditableDataGrid<T extends { id?: string | number }>({
  rows: initialRows,
  columns,
  onSave,
  onDelete,
  onCancel,
  loading = false,
  height,
  title,
  addButtonText,
  hideAddButton = false,
  getRowId,
  onRowClick,
  extraActions,
  defaultNewRow,
}: EditableDataGridProps<T>) {
  const gridRef = React.useRef<any>(null);
  const [registered, setRegistered] = React.useState(false);

  React.useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  React.useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = initialRows.map((r: any) => ({
      ...r,
      id: getRowId ? getRowId(r) : r.id,
    }));
    el.loading = loading;
    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#d32f2f" },
    ];
  }, [initialRows, columns, loading, registered, getRowId]);

  React.useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      const original = initialRows.find((r: any) => (getRowId ? getRowId(r) : r.id) === row.id) as T | undefined;
      if (action === "edit" && original && onRowClick) {
        onRowClick(original);
      } else if (action === "delete" && row.id != null) {
        onDelete(row.id);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, initialRows, getRowId, onRowClick, onDelete]);

  if (!registered) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box
      sx={{
        ...(height ? { height } : { flex: 1, minHeight: 0 }),
        width: "100%",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {!hideAddButton && (
        <Box sx={{ p: 1, display: "flex", alignItems: "center", gap: 1 }}>
          {title && <Box sx={{ flex: 1 }}><strong>{title}</strong></Box>}
          <Button variant="outlined" size="small" startIcon={<AddIcon />}
            onClick={() => {
              // Trigger add row - business logic stays in parent
              console.log("Add row requested");
            }}>
            {addButtonText || "Nuevo"}
          </Button>
        </Box>
      )}
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          height="100%"
          enable-editing
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
        ></zentto-grid>
      </Box>
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
