"use client";

import * as React from "react";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import AddIcon from "@mui/icons-material/Add";
import type { ColumnDef } from "@zentto/datagrid-core";

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
  }, [initialRows, columns, loading, registered, getRowId]);

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
