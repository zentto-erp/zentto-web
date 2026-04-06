"use client";

import { RefObject, useEffect, useState } from "react";

export function buildContabilidadGridId(page: string, scope = "main"): string {
  return `contabilidad:${page}:${scope}`;
}

export function useContabilidadGridRegistration(layoutReady: boolean) {
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    if (!layoutReady) return;

    let cancelled = false;

    // Safety timeout: if dynamic import hangs, unblock the page after 2s
    const safetyTimer = setTimeout(() => {
      if (!cancelled) setRegistered(true);
    }, 2000);

    import("@zentto/datagrid").then(() => {
      if (!cancelled) {
        clearTimeout(safetyTimer);
        setRegistered(true);
      }
    }).catch(() => {
      // If the dynamic import fails (e.g. chunk error, network), still mark as
      // registered so the page renders instead of showing an infinite spinner.
      if (!cancelled) {
        clearTimeout(safetyTimer);
        setRegistered(true);
      }
    });

    return () => {
      cancelled = true;
      clearTimeout(safetyTimer);
    };
  }, [layoutReady]);

  return {
    gridReady: layoutReady && registered,
    registered,
  };
}

export function useContabilidadGridId(
  gridRef: RefObject<HTMLElement | null>,
  gridId: string,
) {
  useEffect(() => {
    gridRef.current?.setAttribute("grid-id", gridId);
  }, [gridId, gridRef]);
}
