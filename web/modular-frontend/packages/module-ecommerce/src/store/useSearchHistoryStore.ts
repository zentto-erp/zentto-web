"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

interface SearchHistoryState {
  terms: Array<{ term: string; timestamp: number }>;
  addTerm: (term: string) => void;
  removeTerm: (term: string) => void;
  clearHistory: () => void;
}

const MAX_TERMS = 10;

export const useSearchHistoryStore = create<SearchHistoryState>()(
  persist(
    (set) => ({
      terms: [],

      addTerm: (term) =>
        set((s) => {
          const normalized = term.trim().toLowerCase();
          if (!normalized) return s;
          const filtered = s.terms.filter((t) => t.term.toLowerCase() !== normalized);
          return { terms: [{ term: term.trim(), timestamp: Date.now() }, ...filtered].slice(0, MAX_TERMS) };
        }),

      removeTerm: (term) =>
        set((s) => ({
          terms: s.terms.filter((t) => t.term.toLowerCase() !== term.toLowerCase()),
        })),

      clearHistory: () => set({ terms: [] }),
    }),
    {
      name: "zentto-ecommerce-search-history",
      partialize: (state) => ({ terms: state.terms }),
    }
  )
);
