/**
 * DatqBox Payment Gateway — Configuration Service
 *
 * CRUD for payment methods, providers, company configs, accepted methods.
 * All database access via stored procedures (no inline SQL).
 */

import { callSp } from "../../db/query.js";
import { getPlugin, getAllPlugins } from "./registry.js";
import type {
  PaymentMethod,
  PaymentProvider,
  CompanyPaymentConfig,
  AcceptedPaymentMethod,
  CardReaderDevice,
  CompanyPaymentConfigInput,
} from "./types.js";

// ══════════════════════════════════════════════════════════════
// Payment Methods
// ══════════════════════════════════════════════════════════════

export async function listPaymentMethods(countryCode?: string) {
  return callSp<PaymentMethod>("usp_Pay_Method_List", {
    CountryCode: countryCode ?? null,
  });
}

export async function upsertPaymentMethod(
  data: Partial<PaymentMethod> & { code: string; name: string }
) {
  await callSp("usp_Pay_Method_Upsert", {
    MethodCode: data.code,
    MethodName: data.name,
    CountryCode: data.countryCode ?? null,
    MethodType: data.category || "OTHER",
    IsActive: data.isActive !== false,
  });
}

// ══════════════════════════════════════════════════════════════
// Payment Providers
// ══════════════════════════════════════════════════════════════

export async function listProviders(_countryCode?: string) {
  return callSp<PaymentProvider>("usp_Pay_Provider_List");
}

export async function getProviderByCode(code: string) {
  const rows = await callSp<PaymentProvider>("usp_Pay_Provider_Get", {
    ProviderCode: code,
  });
  return rows[0] || null;
}

export async function getProviderCapabilities(providerCode: string) {
  return callSp<any>("usp_Pay_Provider_GetCapabilities", {
    ProviderCode: providerCode,
  });
}

/**
 * Returns the config field definitions for a provider plugin,
 * so the frontend can render the right form.
 */
export function getProviderConfigFields(providerCode: string) {
  const plugin = getPlugin(providerCode);
  if (!plugin) return [];
  return plugin.getConfigFields();
}

export function listAvailablePlugins() {
  return getAllPlugins().map((p) => ({
    providerCode: p.providerCode,
    fields: p.getConfigFields(),
  }));
}

// ══════════════════════════════════════════════════════════════
// Company Payment Config
// ══════════════════════════════════════════════════════════════

export async function listCompanyConfigs(
  empresaId: number,
  sucursalId?: number
) {
  return callSp<CompanyPaymentConfig & { ProviderCode: string; ProviderName: string }>(
    "usp_Pay_CompanyConfig_ListByCompany",
    {
      CompanyId: empresaId,
      BranchId: sucursalId ?? null,
    }
  );
}

export async function upsertCompanyConfig(data: CompanyPaymentConfigInput) {
  await callSp("usp_Pay_CompanyConfig_UpsertFull", {
    CompanyId: data.empresaId,
    BranchId: data.sucursalId,
    CountryCode: data.countryCode,
    ProviderCode: data.providerCode,
    Environment: data.environment || "sandbox",
    ClientId: data.clientId ?? null,
    ClientSecret: data.clientSecret ?? null,
    MerchantId: data.merchantId ?? null,
    TerminalId: data.terminalId ?? null,
    IntegratorId: data.integratorId ?? null,
    CertificatePath: data.certificatePath ?? null,
    ExtraConfig: data.extraConfig ? JSON.stringify(data.extraConfig) : null,
    AutoCapture: data.autoCapture !== false,
    AllowRefunds: data.allowRefunds !== false,
    MaxRefundDays: data.maxRefundDays ?? 30,
  });
}

export async function deleteCompanyConfig(id: number) {
  await callSp("usp_Pay_CompanyConfig_DeactivateById", { Id: id });
}

// ══════════════════════════════════════════════════════════════
// Accepted Payment Methods per Company
// ══════════════════════════════════════════════════════════════

export async function listAcceptedMethods(
  empresaId: number,
  sucursalId: number,
  channel?: "POS" | "WEB" | "RESTAURANT"
) {
  return callSp<AcceptedPaymentMethod>("usp_Pay_AcceptedMethod_List", {
    CompanyId: empresaId,
    SucursalId: sucursalId,
    AppliesToPOS: channel === "POS" ? true : null,
    AppliesToWeb: channel === "WEB" ? true : null,
    AppliesToRestaurant: channel === "RESTAURANT" ? true : null,
  });
}

export async function upsertAcceptedMethod(data: {
  empresaId: number;
  sucursalId: number;
  paymentMethodId: number;
  providerId?: number;
  appliesToPOS?: boolean;
  appliesToWeb?: boolean;
  appliesToRestaurant?: boolean;
  minAmount?: number;
  maxAmount?: number;
  commissionPct?: number;
  commissionFixed?: number;
  sortOrder?: number;
}) {
  await callSp("usp_Pay_AcceptedMethod_Upsert", {
    CompanyId: data.empresaId,
    BranchId: data.sucursalId,
    PaymentMethodId: data.paymentMethodId,
    ProviderId: data.providerId ?? null,
    AppliesToPOS: data.appliesToPOS !== false,
    AppliesToWeb: data.appliesToWeb !== false,
    AppliesToRestaurant: data.appliesToRestaurant !== false,
    MinAmount: data.minAmount ?? null,
    MaxAmount: data.maxAmount ?? null,
    CommissionPct: data.commissionPct ?? null,
    CommissionFixed: data.commissionFixed ?? null,
    SortOrder: data.sortOrder ?? 0,
  });
}

export async function removeAcceptedMethod(id: number) {
  await callSp("usp_Pay_AcceptedMethod_Deactivate", { Id: id });
}

// ══════════════════════════════════════════════════════════════
// Card Reader Devices
// ══════════════════════════════════════════════════════════════

export async function listCardReaders(
  empresaId: number,
  sucursalId?: number
) {
  return callSp<CardReaderDevice>("usp_Pay_CardReader_ListByCompany", {
    CompanyId: empresaId,
    BranchId: sucursalId ?? null,
  });
}

export async function upsertCardReader(
  data: Omit<CardReaderDevice, "id" | "isActive" | "lastSeenAt"> & {
    id?: number;
  }
) {
  await callSp("usp_Pay_CardReader_Upsert", {
    DeviceId: data.id ?? null,
    CompanyId: data.empresaId,
    BranchId: data.sucursalId,
    StationId: data.stationId,
    DeviceName: data.deviceName,
    DeviceType: data.deviceType,
    ConnectionType: data.connectionType,
    ConnectionConfig: data.connectionConfig
      ? JSON.stringify(data.connectionConfig)
      : null,
    ProviderId: data.providerId ?? null,
  });
}
