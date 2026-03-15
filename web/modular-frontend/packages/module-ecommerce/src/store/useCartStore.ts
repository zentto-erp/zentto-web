"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface CartItem {
  productCode: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  taxRate: number; // decimal (0.16 = 16%)
  imageUrl: string | null;
  subtotal: number;
  taxAmount: number;
  total: number;
}

export interface CustomerInfo {
  name: string;
  email: string;
  phone?: string;
  address?: string;
  fiscalId?: string;
}

interface CartState {
  items: CartItem[];
  customerInfo: CustomerInfo | null;
  customerToken: string | null;

  // Actions
  addItem: (item: Omit<CartItem, "subtotal" | "taxAmount" | "total">) => void;
  removeItem: (productCode: string) => void;
  updateQuantity: (productCode: string, quantity: number) => void;
  clearCart: () => void;
  setCustomerInfo: (info: CustomerInfo | null) => void;
  setCustomerToken: (token: string | null) => void;

  // Computed
  getSubtotal: () => number;
  getTaxTotal: () => number;
  getTotal: () => number;
  getItemCount: () => number;
}

function calcLine(qty: number, price: number, taxRate: number) {
  const subtotal = Math.round(qty * price * 100) / 100;
  const taxAmount = Math.round(subtotal * taxRate * 100) / 100;
  const total = Math.round((subtotal + taxAmount) * 100) / 100;
  return { subtotal, taxAmount, total };
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      customerInfo: null,
      customerToken: null,

      addItem: (item) =>
        set((s) => {
          const existing = s.items.find((c) => c.productCode === item.productCode);
          if (existing) {
            return {
              items: s.items.map((c) => {
                if (c.productCode !== item.productCode) return c;
                const quantity = c.quantity + item.quantity;
                return { ...c, quantity, ...calcLine(quantity, c.unitPrice, c.taxRate) };
              }),
            };
          }
          const newItem: CartItem = {
            ...item,
            ...calcLine(item.quantity, item.unitPrice, item.taxRate),
          };
          return { items: [...s.items, newItem] };
        }),

      removeItem: (productCode) =>
        set((s) => ({ items: s.items.filter((c) => c.productCode !== productCode) })),

      updateQuantity: (productCode, quantity) =>
        set((s) => ({
          items:
            quantity <= 0
              ? s.items.filter((c) => c.productCode !== productCode)
              : s.items.map((c) => {
                  if (c.productCode !== productCode) return c;
                  return { ...c, quantity, ...calcLine(quantity, c.unitPrice, c.taxRate) };
                }),
        })),

      clearCart: () => set({ items: [] }),

      setCustomerInfo: (info) => set({ customerInfo: info }),
      setCustomerToken: (token) => set({ customerToken: token }),

      // Computed
      getSubtotal: () => get().items.reduce((sum, c) => sum + c.subtotal, 0),
      getTaxTotal: () => get().items.reduce((sum, c) => sum + c.taxAmount, 0),
      getTotal: () => get().items.reduce((sum, c) => sum + c.total, 0),
      getItemCount: () => get().items.reduce((sum, c) => sum + c.quantity, 0),
    }),
    {
      name: "datqbox-ecommerce-cart",
      partialize: (state) => ({
        items: state.items,
        customerInfo: state.customerInfo,
        customerToken: state.customerToken,
      }),
    }
  )
);
