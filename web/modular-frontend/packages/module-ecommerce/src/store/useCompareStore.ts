"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

interface CompareState {
  codes: string[];
  toggle: (code: string) => boolean; // devuelve true si quedó agregado
  clear: () => void;
  contains: (code: string) => boolean;
}

const MAX_COMPARE = 4;

export const useCompareStore = create<CompareState>()(
  persist(
    (set, get) => ({
      codes: [],
      toggle: (code) => {
        const current = get().codes;
        if (current.includes(code)) {
          set({ codes: current.filter((c) => c !== code) });
          return false;
        }
        if (current.length >= MAX_COMPARE) {
          // Reemplaza el más antiguo (FIFO)
          set({ codes: [...current.slice(1), code] });
          return true;
        }
        set({ codes: [...current, code] });
        return true;
      },
      clear: () => set({ codes: [] }),
      contains: (code) => get().codes.includes(code),
    }),
    { name: "zentto-ecommerce-compare" }
  )
);
