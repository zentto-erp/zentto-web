'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import type { GridColumnVisibilityModel } from '@mui/x-data-grid';
import type { ZenttoColDef } from './types';
import { getLayout, saveLayout, clearLayout } from './gridLayoutDb';
import type { GridLayoutState } from './gridLayoutDb';

const DEFAULT_DENSITY: GridLayoutState['density'] = 'compact';

const EMPTY_STATE: GridLayoutState = {
  columnVisibility: {},
  columnOrder: [],
  columnWidths: {},
  density: DEFAULT_DENSITY,
};

/**
 * useGridLayout
 *
 * Carga y persiste el layout de una tabla por gridId en IndexedDB.
 * Retorna columnas reordenadas/redimensionadas y callbacks para conectar
 * a los eventos del DataGrid.
 *
 * @param gridId  Identificador único de la tabla. Si es undefined, no persiste.
 * @param columns Columnas originales definidas por el desarrollador.
 */
export function useGridLayout(gridId: string | undefined, columns: ZenttoColDef[]) {
  const [state, setState] = useState<GridLayoutState>(EMPTY_STATE);
  const [loaded, setLoaded] = useState(!gridId); // si no hay gridId, ya está "cargado"
  const saveTimer = useRef<ReturnType<typeof setTimeout>>();

  // ── Carga inicial desde IndexedDB ──────────────────────────────────────────
  useEffect(() => {
    if (!gridId) return;
    let cancelled = false;
    getLayout(gridId).then((saved) => {
      if (!cancelled && saved) setState(saved);
      if (!cancelled) setLoaded(true);
    }).catch(() => {
      if (!cancelled) setLoaded(true);
    });
    return () => { cancelled = true; };
  }, [gridId]);

  // ── Persistencia con debounce ─────────────────────────────────────────────
  const persist = useCallback((newState: GridLayoutState) => {
    if (!gridId) return;
    clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(() => saveLayout(gridId, newState), 400);
  }, [gridId]);

  // ── Columnas reordenadas según el orden guardado ───────────────────────────
  const orderedColumns = useMemo(() => {
    if (!state.columnOrder.length) return columns;
    const orderMap = new Map(state.columnOrder.map((f, i) => [f, i]));
    return [...columns].sort((a, b) => {
      const ai = orderMap.has(a.field) ? orderMap.get(a.field)! : 9999;
      const bi = orderMap.has(b.field) ? orderMap.get(b.field)! : 9999;
      return ai - bi;
    });
  }, [columns, state.columnOrder]);

  // ── Columnas con anchos guardados (elimina flex para respetar el ancho) ────
  const processedColumns = useMemo(() => {
    if (!Object.keys(state.columnWidths).length) return orderedColumns;
    return orderedColumns.map((col) => {
      const w = state.columnWidths[col.field];
      return w ? { ...col, width: w, flex: undefined } : col;
    });
  }, [orderedColumns, state.columnWidths]);

  // ── Handlers para conectar a DataGrid ────────────────────────────────────

  const onColumnVisibilityModelChange = useCallback(
    (model: GridColumnVisibilityModel) => {
      setState((prev) => {
        const next = { ...prev, columnVisibility: model };
        persist(next);
        return next;
      });
    },
    [persist]
  );

  /** Llamar con apiRef.current.getAllColumns().map(c => c.field) tras onColumnOrderChange */
  const onColumnOrderChange = useCallback(
    (orderedFields: string[]) => {
      setState((prev) => {
        const next = { ...prev, columnOrder: orderedFields };
        persist(next);
        return next;
      });
    },
    [persist]
  );

  /** Llamar con { field, width } desde onColumnWidthChange */
  const onColumnWidthChange = useCallback(
    (field: string, width: number) => {
      setState((prev) => {
        const next = {
          ...prev,
          columnWidths: { ...prev.columnWidths, [field]: width },
        };
        persist(next);
        return next;
      });
    },
    [persist]
  );

  const onDensityChange = useCallback(
    (density: GridLayoutState['density']) => {
      setState((prev) => {
        const next = { ...prev, density };
        persist(next);
        return next;
      });
    },
    [persist]
  );

  // ── Reset ──────────────────────────────────────────────────────────────────
  const resetLayout = useCallback(() => {
    setState(EMPTY_STATE);
    if (gridId) clearLayout(gridId);
  }, [gridId]);

  return {
    /** true cuando el layout inicial fue cargado desde IndexedDB */
    loaded,
    /** Columnas con orden y anchos del layout guardado */
    processedColumns,
    /** Model de visibilidad a pasar a columnVisibilityModel */
    columnVisibilityModel: state.columnVisibility,
    /** Densidad guardada */
    density: state.density,
    /** true si hay alguna personalización guardada */
    hasCustomLayout:
      !!gridId &&
      (state.columnOrder.length > 0 ||
        Object.keys(state.columnWidths).length > 0 ||
        Object.keys(state.columnVisibility).length > 0 ||
        state.density !== DEFAULT_DENSITY),
    // handlers
    onColumnVisibilityModelChange,
    onColumnOrderChange,
    onColumnWidthChange,
    onDensityChange,
    resetLayout,
  };
}
