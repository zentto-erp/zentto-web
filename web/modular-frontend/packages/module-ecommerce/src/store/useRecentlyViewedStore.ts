"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface RecentlyViewedItem {
  productCode: string;
  productName: string;
  price: number;
  imageUrl: string | null;
  category?: string;
  viewedAt: number;
}

interface RecentlyViewedState {
  items: RecentlyViewedItem[];
  addView: (item: Omit<RecentlyViewedItem, "viewedAt">) => void;
  clearHistory: () => void;
  getCategories: () => string[];
}

const MAX_ITEMS = 30;

export const useRecentlyViewedStore = create<RecentlyViewedState>()(
  persist(
    (set, get) => ({
      items: [],

      addView: (item) =>
        set((s) => {
          const filtered = s.items.filter((i) => i.productCode !== item.productCode);
          const updated = [{ ...item, viewedAt: Date.now() }, ...filtered];
          return { items: updated.slice(0, MAX_ITEMS) };
        }),

      clearHistory: () => set({ items: [] }),

      getCategories: () => {
        const cats = get()
          .items.map((i) => i.category)
          .filter((c): c is string => !!c);
        return Array.from(new Set(cats));
      },
    }),
    {
      name: "datqbox-ecommerce-recently-viewed",
      partialize: (state) => ({ items: state.items }),
    }
  )
);
