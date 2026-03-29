"use client";

export const MODULE_ID = "shipping";
export const MODULE_TITLE = "Zentto Shipping";

// Store
export { useShippingStore } from "./store/useShippingStore";
export type { ShippingCustomerInfo } from "./store/useShippingStore";

// Hooks - Auth
export { useShippingRegister, useShippingLogin, useShippingProfile, useShippingLogout } from "./hooks/useShippingAuth";

// Hooks - Shipping
export {
  useShippingDashboard,
  useShippingAddresses,
  useUpsertAddress,
  useShippingCarriers,
  useShippingQuote,
  useShipmentsList,
  useShipmentDetail,
  useCreateShipment,
  useUpsertCustoms,
  usePublicTracking,
} from "./hooks/useShipping";
export type { ShipmentFilter } from "./hooks/useShipping";

// Pages
export { default as ShippingLayout } from "./pages/ShippingLayout";
export { default as ShippingHome } from "./pages/ShippingHome";

// Components
export { default as ShippingDashboard } from "./components/ShippingDashboard";
export { default as ShipmentsList } from "./components/ShipmentsList";
export { default as CreateShipment } from "./components/CreateShipment";
export { default as ShipmentDetail } from "./components/ShipmentDetail";
export { default as PublicTracking } from "./components/PublicTracking";
