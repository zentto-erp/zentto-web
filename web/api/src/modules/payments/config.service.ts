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

// Los SPs devuelven PascalCase; el frontend espera camelCase.
// Estos mappers convierten las filas antes de enviarlas al cliente.
function mapPaymentMethod(r: any): PaymentMethod {
  return {
    id:              r.Id              ?? r.id,
    code:            r.Code            ?? r.code,
    name:            r.Name            ?? r.name,
    category:        r.Category        ?? r.category,
    countryCode:     r.CountryCode     ?? r.countryCode     ?? null,
    iconName:        r.IconName        ?? r.iconName        ?? null,
    requiresGateway: r.RequiresGateway ?? r.requiresGateway ?? false,
    isActive:        r.IsActive        ?? r.isActive        ?? true,
    sortOrder:       r.SortOrder       ?? r.sortOrder       ?? 0,
  };
}

function mapPaymentProvider(r: any): PaymentProvider {
  return {
    id:             r.Id             ?? r.id,
    code:           r.Code           ?? r.code,
    name:           r.Name           ?? r.name,
    countryCode:    r.CountryCode    ?? r.countryCode    ?? null,
    providerType:   r.ProviderType   ?? r.providerType,
    baseUrlSandbox: r.BaseUrlSandbox ?? r.baseUrlSandbox ?? null,
    baseUrlProd:    r.BaseUrlProd    ?? r.baseUrlProd    ?? null,
    authType:       r.AuthType       ?? r.authType       ?? null,
    docsUrl:        r.DocsUrl        ?? r.docsUrl        ?? null,
    logoUrl:        r.LogoUrl        ?? r.logoUrl        ?? null,
    isActive:       r.IsActive       ?? r.isActive       ?? true,
  };
}

function mapCompanyConfig(r: any): CompanyPaymentConfig & { providerCode: string; providerName: string; providerType: string } {
  return {
    id:              r.Id              ?? r.id,
    empresaId:       r.EmpresaId       ?? r.empresaId,
    sucursalId:      r.SucursalId      ?? r.sucursalId,
    countryCode:     r.CountryCode     ?? r.countryCode,
    providerId:      r.ProviderId      ?? r.providerId,
    providerCode:    r.ProviderCode    ?? r.providerCode    ?? '',
    providerName:    r.ProviderName    ?? r.providerName    ?? '',
    providerType:    r.ProviderType    ?? r.providerType    ?? '',
    environment:     r.Environment     ?? r.environment,
    clientId:        r.ClientId        ?? r.clientId        ?? null,
    clientSecret:    r.ClientSecret    ?? r.clientSecret    ?? null,
    merchantId:      r.MerchantId      ?? r.merchantId      ?? null,
    terminalId:      r.TerminalId      ?? r.terminalId      ?? null,
    integratorId:    r.IntegratorId    ?? r.integratorId    ?? null,
    certificatePath: r.CertificatePath ?? r.certificatePath ?? null,
    extraConfig:     r.ExtraConfig     ?? r.extraConfig     ?? null,
    autoCapture:     r.AutoCapture     ?? r.autoCapture     ?? false,
    allowRefunds:    r.AllowRefunds    ?? r.allowRefunds    ?? false,
    maxRefundDays:   r.MaxRefundDays   ?? r.maxRefundDays   ?? 30,
    isActive:        r.IsActive        ?? r.isActive        ?? true,
  };
}

function mapAcceptedMethod(r: any): AcceptedPaymentMethod {
  return {
    id:                  r.Id                  ?? r.id,
    empresaId:           r.EmpresaId           ?? r.empresaId,
    sucursalId:          r.SucursalId          ?? r.sucursalId,
    paymentMethodId:     r.PaymentMethodId     ?? r.paymentMethodId,
    providerId:          r.ProviderId          ?? r.providerId          ?? null,
    methodCode:          r.MethodCode          ?? r.methodCode,
    methodName:          r.MethodName          ?? r.methodName,
    methodCategory:      r.MethodCategory      ?? r.methodCategory,
    iconName:            r.IconName            ?? r.iconName            ?? null,
    providerCode:        r.ProviderCode        ?? r.providerCode        ?? null,
    providerName:        r.ProviderName        ?? r.providerName        ?? null,
    appliesToPOS:        r.AppliesToPOS        ?? r.appliesToPOS        ?? false,
    appliesToWeb:        r.AppliesToWeb        ?? r.appliesToWeb        ?? false,
    appliesToRestaurant: r.AppliesToRestaurant ?? r.appliesToRestaurant ?? false,
    minAmount:           r.MinAmount           ?? r.minAmount           ?? null,
    maxAmount:           r.MaxAmount           ?? r.maxAmount           ?? null,
    commissionPct:       r.CommissionPct       ?? r.commissionPct       ?? null,
    commissionFixed:     r.CommissionFixed     ?? r.commissionFixed     ?? null,
    sortOrder:           r.SortOrder           ?? r.sortOrder           ?? 0,
    isActive:            r.IsActive            ?? r.isActive            ?? true,
  };
}

// ══════════════════════════════════════════════════════════════
// Payment Methods
// ══════════════════════════════════════════════════════════════

export async function listPaymentMethods(countryCode?: string) {
  const rows = await callSp<any>("usp_Pay_Method_List", {
    CountryCode: countryCode ?? null,
  });
  return rows.map(mapPaymentMethod);
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
  const rows = await callSp<any>("usp_Pay_Provider_List");
  return rows.map(mapPaymentProvider);
}

export async function getProviderByCode(code: string) {
  const rows = await callSp<any>("usp_Pay_Provider_Get", {
    ProviderCode: code,
  });
  return rows[0] ? mapPaymentProvider(rows[0]) : null;
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
  const rows = await callSp<any>("usp_Pay_CompanyConfig_ListByCompany", {
    CompanyId: empresaId,
    BranchId: sucursalId ?? null,
  });
  return rows.map(mapCompanyConfig);
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
  const rows = await callSp<any>("usp_Pay_AcceptedMethod_List", {
    CompanyId: empresaId,
    SucursalId: sucursalId,
    AppliesToPOS: channel === "POS" ? true : null,
    AppliesToWeb: channel === "WEB" ? true : null,
    AppliesToRestaurant: channel === "RESTAURANT" ? true : null,
  });
  return rows.map(mapAcceptedMethod);
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
