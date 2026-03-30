"use client";

import { RefObject, useEffect, useState } from "react";

export function buildCRMGridId(page: string, scope = "main"): string {
  return `crm:${page}:${scope}`;
}

export function useCRMGridRegistration(layoutReady: boolean) {
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    if (!layoutReady) return;

    let cancelled = false;

    import("@zentto/datagrid").then(() => {
      if (!cancelled) {
        setRegistered(true);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [layoutReady]);

  return {
    gridReady: layoutReady && registered,
    registered,
  };
}

export function useCRMGridId(
  gridRef: RefObject<HTMLElement | null>,
  gridId: string,
) {
  useEffect(() => {
    gridRef.current?.setAttribute("grid-id", gridId);
  }, [gridId, gridRef]);
}
