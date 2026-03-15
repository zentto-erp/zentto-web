"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface FavoriteItem {
  productCode: string;
  productName: string;
  price: number;
  imageUrl: string | null;
  addedAt: number; // timestamp
}

interface FavoritesState {
  items: FavoriteItem[];

  addFavorite: (item: Omit<FavoriteItem, "addedAt">) => void;
  removeFavorite: (productCode: string) => void;
  toggleFavorite: (item: Omit<FavoriteItem, "addedAt">) => void;
  isFavorite: (productCode: string) => boolean;
  clearFavorites: () => void;
}

export const useFavoritesStore = create<FavoritesState>()(
  persist(
    (set, get) => ({
      items: [],

      addFavorite: (item) =>
        set((s) => {
          if (s.items.some((f) => f.productCode === item.productCode)) return s;
          return { items: [...s.items, { ...item, addedAt: Date.now() }] };
        }),

      removeFavorite: (productCode) =>
        set((s) => ({ items: s.items.filter((f) => f.productCode !== productCode) })),

      toggleFavorite: (item) => {
        const exists = get().items.some((f) => f.productCode === item.productCode);
        if (exists) {
          get().removeFavorite(item.productCode);
        } else {
          get().addFavorite(item);
        }
      },

      isFavorite: (productCode) => get().items.some((f) => f.productCode === productCode),

      clearFavorites: () => set({ items: [] }),
    }),
    {
      name: "datqbox-ecommerce-favorites",
      partialize: (state) => ({ items: state.items }),
    }
  )
);
