"use client";

export const MODULE_ID = "flota";
export const MODULE_TITLE = "Flota";

// -- Hooks ────────────────────────────────────────────────────
export {
  useVehiclesList,
  useVehicleDetail,
  useCreateVehicle,
  useUpdateVehicle,
  useFuelLogsList,
  useCreateFuelLog,
  useMaintenanceOrdersList,
  useMaintenanceOrderDetail,
  useCreateMaintenanceOrder,
  useCompleteMaintenanceOrder,
  useCancelMaintenanceOrder,
  useTripsList,
  useCreateTrip,
  useCompleteTrip,
  useFlotaDashboard,
} from "./hooks/useFlota";

export type {
  VehicleFilter,
  VehicleListResponse,
  FuelFilter,
  FuelListResponse,
  MaintenanceFilter,
  MaintenanceListResponse,
  TripFilter,
  TripListResponse,
  FlotaDashboard,
} from "./hooks/useFlota";

// -- Components ───────────────────────────────────────────────
export { default as VehiculosPage } from "./components/VehiculosPage";
export { default as CombustiblePage } from "./components/CombustiblePage";
export { default as MantenimientoPage } from "./components/MantenimientoPage";
export { default as ViajesPage } from "./components/ViajesPage";

// -- Pages ────────────────────────────────────────────────────
export { default as FlotaHome } from "./pages/FlotaHome";
