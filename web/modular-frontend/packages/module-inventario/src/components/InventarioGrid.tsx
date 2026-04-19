"use client";

import { useEffect, useRef } from "react";
import { Box, Button, Stack, Typography } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";

interface InventarioGridProps {
  columns: ColumnDef[];
  rows: Record<string, unknown>[];
  loading?: boolean;
  totalRows?: number;
  page?: number;
  pageSize?: number;
  onPageChange?: (page: number) => void;
  onAction?: (action: string, row: any) => void;
  height?: number;
}

export function InventarioGrid({
  columns,
  rows,
  loading = false,
  totalRows = 0,
  page = 1,
  pageSize = 50,
  onPageChange,
  onAction,
  height = 520,
}: InventarioGridProps) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current as any;
    if (!el) return;
    el.columns = columns;
  }, [columns]);

  useEffect(() => {
    const el = ref.current as any;
    if (!el) return;
    el.rows = loading ? [] : rows;
  }, [rows, loading]);

  useEffect(() => {
    const el = ref.current as any;
    if (!el) return;
    el.loading = loading;
  }, [loading]);

  useEffect(() => {
    const el = ref.current;
    if (!el || !onAction) return;
    const handler = (e: Event) => {
      const { action, row } = (e as CustomEvent<{ action: string; row: any }>).detail ?? {};
      if (action && row) onAction(action, row);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [onAction]);

  const hasPrev = page > 1;
  const hasNext = page * pageSize < totalRows;

  return (
    <Box>
      {/* @ts-expect-error — web component registrado globalmente */}
      <zentto-grid
        ref={ref as React.Ref<HTMLElement>}
        height={`${height}px`}
        enable-toolbar
        enable-quick-search
        enable-status-bar
      />
      {onPageChange && (
        <Stack direction="row" spacing={1} alignItems="center" justifyContent="flex-end" sx={{ mt: 1 }}>
          <Button size="small" disabled={!hasPrev} onClick={() => onPageChange(page - 1)}>
            Anterior
          </Button>
          <Typography variant="caption" color="text.secondary">
            Página {page} · {totalRows} registros
          </Typography>
          <Button size="small" disabled={!hasNext} onClick={() => onPageChange(page + 1)}>
            Siguiente
          </Button>
        </Stack>
      )}
    </Box>
  );
}
