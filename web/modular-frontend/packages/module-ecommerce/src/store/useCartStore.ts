"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface CartItem {
  productCode: string;
  productName: string;
  quantity: number;
  unitPrice: number;       // Precio en moneda BASE (catálogo)
  taxRate: number;         // decimal (0.16 = 16%)
  imageUrl: string | null;
  subtotal: number;        // Calculado en moneda BASE
  taxAmount: number;       // Calculado en moneda BASE
  total: number;           // Calculado en moneda BASE
}

export interface CustomerInfo {
  name: string;
  email: string;
  phone?: string;
  address?: string;
  fiscalId?: string;
}

export interface DisplayCurrency {
  currencyCode: string;    // ISO 4217
  symbol: string;          // $, Bs, €, etc.
  rateToBase: number;      // Cuántas unidades de esta moneda equivalen a 1 base
  countryCode: string;     // País asociado (para reglas fiscales)
  taxRate: number;         // Tasa fiscal del país (override de items si !=0)
  taxName: string;         // Nombre del impuesto (IVA, IGV, IVU…)
}

const DEFAULT_CURRENCY: DisplayCurrency = {
  currencyCode: "USD",
  symbol: "$",
  rateToBase: 1,
  countryCode: "VE",
  taxRate: 0,
  taxName: "IVA",
};

interface CartState {
  items: CartItem[];
  customerInfo: CustomerInfo | null;
  customerToken: string | null;
  cartOpen: boolean;
  currency: DisplayCurrency;
  /** Token persistente para identificar el carrito server-side (sync multi-device). */
  cartToken: string;

  // Actions
  addItem: (item: Omit<CartItem, "subtotal" | "taxAmount" | "total">) => void;
  removeItem: (productCode: string) => void;
  updateQuantity: (productCode: string, quantity: number) => void;
  clearCart: () => void;
  setCustomerInfo: (info: CustomerInfo | null) => void;
  setCustomerToken: (token: string | null) => void;
  setCartOpen: (open: boolean) => void;
  setCurrency: (currency: DisplayCurrency) => void;
  setCartToken: (token: string) => void;
  hydrateFromServer: (items: CartItem[]) => void;

  // Computed (moneda base — útil para checkout interno y cálculo neto)
  getSubtotal: () => number;
  getTaxTotal: () => number;
  getTotal: () => number;
  getItemCount: () => number;

  // Computed (moneda de display — multiplicado por rateToBase)
  getDisplaySubtotal: () => number;
  getDisplayTaxTotal: () => number;
  getDisplayTotal: () => number;
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
      cartOpen: false,
      currency: DEFAULT_CURRENCY,
      cartToken:
        typeof crypto !== "undefined" && "randomUUID" in crypto
          ? crypto.randomUUID()
          : Math.random().toString(36).slice(2) + Date.now().toString(36),

      addItem: (item) =>
        set((s) => {
          const price = Number(item.unitPrice);
          const taxRate = Number(item.taxRate);
          const existing = s.items.find((c) => c.productCode === item.productCode);
          if (existing) {
            return {
              cartOpen: true,
              items: s.items.map((c) => {
                if (c.productCode !== item.productCode) return c;
                const quantity = c.quantity + item.quantity;
                return { ...c, quantity, ...calcLine(quantity, c.unitPrice, c.taxRate) };
              }),
            };
          }
          const newItem: CartItem = {
            ...item,
            unitPrice: price,
            taxRate,
            ...calcLine(item.quantity, price, taxRate),
          };
          return { cartOpen: true, items: [...s.items, newItem] };
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
      setCartOpen: (open) => set({ cartOpen: open }),
      setCurrency: (currency) => set({ currency }),
      setCartToken: (token) => set({ cartToken: token }),
      hydrateFromServer: (items) => set({ items }),

      // Base
      getSubtotal: () => get().items.reduce((sum, c) => sum + c.subtotal, 0),
      getTaxTotal: () => get().items.reduce((sum, c) => sum + c.taxAmount, 0),
      getTotal: () => get().items.reduce((sum, c) => sum + c.total, 0),
      getItemCount: () => get().items.reduce((sum, c) => sum + c.quantity, 0),

      // Display (rate aplicado)
      getDisplaySubtotal: () => {
        const { rateToBase } = get().currency;
        return Math.round(get().getSubtotal() * rateToBase * 100) / 100;
      },
      getDisplayTaxTotal: () => {
        const { rateToBase } = get().currency;
        return Math.round(get().getTaxTotal() * rateToBase * 100) / 100;
      },
      getDisplayTotal: () => {
        const { rateToBase } = get().currency;
        return Math.round(get().getTotal() * rateToBase * 100) / 100;
      },
    }),
    {
      name: "zentto-ecommerce-cart",
      partialize: (state) => ({
        items: state.items,
        customerInfo: state.customerInfo,
        customerToken: state.customerToken,
        currency: state.currency,
        cartToken: state.cartToken,
      }),
    }
  )
);
