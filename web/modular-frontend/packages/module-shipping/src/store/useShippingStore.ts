"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface ShippingCustomerInfo {
  id: number;
  name: string;
  email: string;
  phone?: string;
  companyName?: string;
  countryCode?: string;
}

interface ShippingStore {
  customerToken: string | null;
  customerInfo: ShippingCustomerInfo | null;
  setCustomerToken: (token: string | null) => void;
  setCustomerInfo: (info: ShippingCustomerInfo | null) => void;
  logout: () => void;
}

export const useShippingStore = create<ShippingStore>()(
  persist(
    (set) => ({
      customerToken: null,
      customerInfo: null,
      setCustomerToken: (token) => set({ customerToken: token }),
      setCustomerInfo: (info) => set({ customerInfo: info }),
      logout: () => set({ customerToken: null, customerInfo: null }),
    }),
    { name: "zentto-shipping-auth" }
  )
);
