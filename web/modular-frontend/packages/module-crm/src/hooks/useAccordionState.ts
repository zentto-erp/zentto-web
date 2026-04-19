"use client";

import { useCallback, useEffect, useState } from "react";

/**
 * useAccordionState
 *
 * Persiste el estado expandido/colapsado de un grupo de acordeones
 * en `localStorage` bajo la key provista.
 *
 * Comportamiento:
 * - Si `exclusive` es `true`, expandir un acordeón colapsa al resto
 *   (modo mobile / accordion group).
 * - Si no hay valor guardado, se usa `defaults`.
 * - Si el JSON guardado es inválido, se resetea a `defaults`.
 *
 * Nota: local al módulo `@zentto/crm`. Si otra app lo necesita, se
 * promueve a `@zentto/shared-ui` en un PR dedicado.
 */
export function useAccordionState<K extends string>(
  storageKey: string,
  defaults: Record<K, boolean>,
  options?: { exclusive?: boolean },
): {
  expanded: Record<K, boolean>;
  toggle: (key: K) => void;
  setExpanded: (key: K, value: boolean) => void;
  isExpanded: (key: K) => boolean;
} {
  const exclusive = options?.exclusive ?? false;

  const [expanded, setExpandedState] = useState<Record<K, boolean>>(defaults);

  // Hydrate from localStorage (client only). Evita hydration mismatch
  // inicializando con `defaults` y rehidratando tras mount.
  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      const raw = window.localStorage.getItem(storageKey);
      if (!raw) return;
      const parsed = JSON.parse(raw) as Partial<Record<K, boolean>>;
      if (parsed && typeof parsed === "object") {
        setExpandedState((prev) => ({ ...prev, ...parsed }));
      }
    } catch {
      // Silenciar: corrupción de storage → usamos defaults.
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storageKey]);

  // Persist changes.
  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(expanded));
    } catch {
      // Storage lleno/bloqueado: ignorar.
    }
  }, [storageKey, expanded]);

  const setExpanded = useCallback(
    (key: K, value: boolean) => {
      setExpandedState((prev) => {
        if (exclusive && value) {
          const next = { ...prev } as Record<K, boolean>;
          (Object.keys(next) as K[]).forEach((k) => {
            next[k] = false;
          });
          next[key] = true;
          return next;
        }
        return { ...prev, [key]: value };
      });
    },
    [exclusive],
  );

  const toggle = useCallback(
    (key: K) => {
      setExpandedState((prev) => {
        const current = prev[key];
        if (exclusive && !current) {
          const next = { ...prev } as Record<K, boolean>;
          (Object.keys(next) as K[]).forEach((k) => {
            next[k] = false;
          });
          next[key] = true;
          return next;
        }
        return { ...prev, [key]: !current };
      });
    },
    [exclusive],
  );

  const isExpanded = useCallback((key: K) => !!expanded[key], [expanded]);

  return { expanded, toggle, setExpanded, isExpanded };
}
