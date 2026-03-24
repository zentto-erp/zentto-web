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
 *
 * FIX: La version anterior tenia un bug donde:
 *   1. El estado se inicializaba como EMPTY_STATE
 *   2. El useEffect cargaba desde IndexedDB (async)
 *   3. Pero ANTES de que el useEffect terminara, el componente
 *      renderizaba con EMPTY_STATE y el DataGrid tomaba esos valores
 *   4. Cuando el useEffect terminaba y seteaba el estado real,
 *      el DataGrid ya habia sobreescrito la visibilidad con valores vacios
 *
 * Solucion: Usar un flag `loaded` que bloquea el render del DataGrid
 * hasta que el layout se haya cargado desde IndexedDB. El componente
 * padre puede usar `layout.loaded` para mostrar un skeleton o esperar.
 */
export function useGridLayout(gridId: string | undefined, columns: ZenttoColDef[]) {
  const [state, setState] = useState<GridLayoutState>(EMPTY_STATE);
  const [loaded, setLoaded] = useState(!gridId); // sin gridId = ya cargado
  const saveTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const mountedRef = useRef(true);

  // Track mounted state to avoid setState after unmount
  useEffect(() => {
    mountedRef.current = true;
    return () => { mountedRef.current = false; };
  }, []);

  // ── Load from IndexedDB ───────────────────────────────────────────────────
  useEffect(() => {
    if (!gridId) {
      setLoaded(true);
      return;
    }

    let cancelled = false;

    // Reset loaded state when gridId changes (e.g., navigating between pages)
    setLoaded(false);

    getLayout(gridId)
      .then((saved) => {
        if (cancelled || !mountedRef.current) return;
        if (saved) {
          setState(saved);
        } else {
          setState(EMPTY_STATE);
        }
        setLoaded(true);
      })
      .catch(() => {
        if (cancelled || !mountedRef.current) return;
        setState(EMPTY_STATE);
        setLoaded(true);
      });

    return () => {
      cancelled = true;
    };
  }, [gridId]);

  // ── Persist with debounce ─────────────────────────────────────────────────
  const persist = useCallback(
    (newState: GridLayoutState) => {
      if (!gridId) return;
      clearTimeout(saveTimer.current);
      saveTimer.current = setTimeout(() => {
        if (mountedRef.current) {
          saveLayout(gridId, newState);
        }
      }, 400);
    },
    [gridId]
  );

  // ── Columns reordered by saved order ──────────────────────────────────────
  const orderedColumns = useMemo(() => {
    if (!state.columnOrder.length) return columns;
    const orderMap = new Map(state.columnOrder.map((f, i) => [f, i]));
    return [...columns].sort((a, b) => {
      const ai = orderMap.has(a.field) ? orderMap.get(a.field)! : 9999;
      const bi = orderMap.has(b.field) ? orderMap.get(b.field)! : 9999;
      return ai - bi;
    });
  }, [columns, state.columnOrder]);

  // ── Columns with saved widths ─────────────────────────────────────────────
  const processedColumns = useMemo(() => {
    if (!Object.keys(state.columnWidths).length) return orderedColumns;
    return orderedColumns.map((col) => {
      const w = state.columnWidths[col.field];
      return w ? { ...col, width: w, flex: undefined } : col;
    });
  }, [orderedColumns, state.columnWidths]);

  // ── Handlers ──────────────────────────────────────────────────────────────

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

  // ── Reset ─────────────────────────────────────────────────────────────────
  const resetLayout = useCallback(() => {
    setState(EMPTY_STATE);
    if (gridId) clearLayout(gridId);
  }, [gridId]);

  return {
    /** true when the initial layout has been loaded from IndexedDB */
    loaded,
    /** Columns with saved order and widths */
    processedColumns,
    /** Visibility model to pass to columnVisibilityModel */
    columnVisibilityModel: state.columnVisibility,
    /** Saved density */
    density: state.density,
    /** true if there's any saved customization */
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
