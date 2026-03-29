"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

const BASE = "/api/v1/flota";
const QK_VEHICLES = "fleet-vehicles";
const QK_FUEL = "fleet-fuel";
const QK_MAINTENANCE = "fleet-maintenance";
const QK_TRIPS = "fleet-trips";
const QK_DASHBOARD = "fleet-dashboard";
const QK_ALERTS = "fleet-alerts";
const QK_REPORT_FUEL = "fleet-report-fuel";

// ── Types ────────────────────────────────────────────────────

export interface VehicleFilter {
  status?: string;
  vehicleType?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface VehicleListResponse {
  rows: Record<string, unknown>[];
  total: number;
}

export interface FuelFilter {
  vehicleId?: number;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface FuelListResponse {
  rows: Record<string, unknown>[];
  total: number;
}

export interface MaintenanceFilter {
  vehicleId?: number;
  status?: string;
  page?: number;
  limit?: number;
}

export interface MaintenanceListResponse {
  rows: Record<string, unknown>[];
  total: number;
}

export interface TripFilter {
  vehicleId?: number;
  status?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface TripListResponse {
  rows: Record<string, unknown>[];
  total: number;
}

export interface FlotaDashboard {
  VehiculosActivos: number;
  KmTotalMes: number;
  CostoCombustibleMes: number;
  MantenimientosPendientes: number;
}

// ── Vehiculos ───────────────────────────────────────────────

export function useVehiclesList(filter?: VehicleFilter) {
  return useQuery<VehicleListResponse>({
    queryKey: [QK_VEHICLES, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.vehicleType) params.append("vehicleType", filter.vehicleType);
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/vehiculos?${params.toString()}`);
    },
  });
}

export function useVehicleDetail(id?: number) {
  return useQuery({
    queryKey: [QK_VEHICLES, "detail", id],
    queryFn: () => apiGet(`${BASE}/vehiculos/${id}`),
    enabled: !!id,
  });
}

export function useCreateVehicle() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/vehiculos`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_VEHICLES] }),
  });
}

export function useUpdateVehicle() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/vehiculos`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_VEHICLES] }),
  });
}

// ── Combustible ─────────────────────────────────────────────

export function useFuelLogsList(filter?: FuelFilter) {
  return useQuery<FuelListResponse>({
    queryKey: [QK_FUEL, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.vehicleId) params.append("vehicleId", filter.vehicleId.toString());
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/combustible?${params.toString()}`);
    },
  });
}

export function useCreateFuelLog() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/combustible`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_FUEL] }),
  });
}

// ── Mantenimiento ───────────────────────────────────────────

export function useMaintenanceOrdersList(filter?: MaintenanceFilter) {
  return useQuery<MaintenanceListResponse>({
    queryKey: [QK_MAINTENANCE, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.vehicleId) params.append("vehicleId", filter.vehicleId.toString());
      if (filter?.status) params.append("status", filter.status);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/mantenimientos?${params.toString()}`);
    },
  });
}

export function useMaintenanceOrderDetail(id?: number) {
  return useQuery({
    queryKey: [QK_MAINTENANCE, "detail", id],
    queryFn: () => apiGet(`${BASE}/mantenimientos/${id}`),
    enabled: !!id,
  });
}

export function useCreateMaintenanceOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/mantenimientos`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MAINTENANCE] }),
  });
}

export function useCompleteMaintenanceOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; actualCost: number; completedDate: string }) =>
      apiPost(`${BASE}/mantenimientos/${d.id}/completar`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MAINTENANCE] }),
  });
}

export function useCancelMaintenanceOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/mantenimientos/${id}/cancelar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_MAINTENANCE] }),
  });
}

// ── Viajes ──────────────────────────────────────────────────

export function useTripsList(filter?: TripFilter) {
  return useQuery<TripListResponse>({
    queryKey: [QK_TRIPS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.vehicleId) params.append("vehicleId", filter.vehicleId.toString());
      if (filter?.status) params.append("status", filter.status);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/viajes?${params.toString()}`);
    },
  });
}

export function useCreateTrip() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/viajes`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_TRIPS] }),
  });
}

export function useCompleteTrip() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; endMileage: number; arrivalDate: string; fuelUsed?: number }) =>
      apiPost(`${BASE}/viajes/${d.id}/completar`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_TRIPS] }),
  });
}

// ── Alertas ─────────────────────────────────────────────────

export interface FleetAlertItem {
  AlertType: string;
  ItemId: number;
  VehicleId: number;
  LicensePlate: string;
  Brand: string;
  Model: string;
  DocumentType?: string;
  DocumentNumber?: string;
  MaintenanceTypeName?: string;
  OrderNumber?: string;
  ExpiryDate?: string;
  ScheduledDate?: string;
  DaysOverdue?: number;
  DaysUntilExpiry?: number;
}

export interface FleetAlertsResponse {
  expired: FleetAlertItem[];
  expiringSoon: FleetAlertItem[];
  maintenanceOverdue: FleetAlertItem[];
  summary: {
    expiredDocsCount: number;
    expiringSoonDocsCount: number;
    overdueMaintenanceCount: number;
  };
}

export function useFleetAlerts() {
  return useQuery<FleetAlertsResponse>({
    queryKey: [QK_ALERTS],
    queryFn: () => apiGet(`${BASE}/alertas`),
  });
}

// ── Reportes ────────────────────────────────────────────────

export interface FuelMonthlyRow {
  VehicleId: number;
  LicensePlate: string;
  Brand: string;
  Model: string;
  TotalLiters: number;
  TotalCost: number;
  AvgCostPerLiter: number;
}

export interface FuelMonthlyResponse {
  rows: FuelMonthlyRow[];
  year: number;
  month: number;
}

export function useFuelMonthlyReport(year: number, month: number) {
  return useQuery<FuelMonthlyResponse>({
    queryKey: [QK_REPORT_FUEL, year, month],
    queryFn: () => apiGet(`${BASE}/reportes/combustible-mensual?year=${year}&month=${month}`),
    enabled: year > 0 && month > 0,
  });
}

// ── Dashboard ───────────────────────────────────────────────

export function useFlotaDashboard() {
  return useQuery<FlotaDashboard>({
    queryKey: [QK_DASHBOARD],
    queryFn: () => apiGet(`${BASE}/dashboard`),
  });
}

// ── Analytics ──────────────────────────────────────────────

export interface FuelCostByVehicleRow {
  VehicleId: number;
  LicensePlate: string;
  BrandModel: string;
  TotalCost: number;
}

export interface KmByMonthRow {
  Month: string;
  MonthLabel: string;
  TotalKm: number;
}

export interface NextMaintenanceRow {
  MaintenanceOrderId: number;
  OrderNumber: string;
  LicensePlate: string;
  BrandModel: string;
  MaintenanceType: string;
  ScheduledDate: string;
  EstimatedCost: number;
  Status: string;
}

export interface FlotaTrends {
  FuelCostThisMonth: number;
  FuelCostLastMonth: number;
  KmThisMonth: number;
  KmLastMonth: number;
  TripsThisMonth: number;
  TripsLastMonth: number;
}

const QK_ANALYTICS = "fleet-analytics";

export function useFuelCostByVehicle() {
  return useQuery<FuelCostByVehicleRow[]>({
    queryKey: [QK_ANALYTICS, "fuel-by-vehicle"],
    queryFn: () => apiGet(`${BASE}/analytics/fuel-by-vehicle`),
  });
}

export function useKmByMonth() {
  return useQuery<KmByMonthRow[]>({
    queryKey: [QK_ANALYTICS, "km-by-month"],
    queryFn: () => apiGet(`${BASE}/analytics/km-by-month`),
  });
}

export function useNextMaintenance() {
  return useQuery<NextMaintenanceRow[]>({
    queryKey: [QK_ANALYTICS, "next-maintenance"],
    queryFn: () => apiGet(`${BASE}/analytics/next-maintenance`),
  });
}

export function useFlotaTrends() {
  return useQuery<FlotaTrends>({
    queryKey: [QK_ANALYTICS, "trends"],
    queryFn: () => apiGet(`${BASE}/analytics/trends`),
  });
}
