/**
 * DatqBox Payment Gateway — Configuration Service
 *
 * CRUD for payment methods, providers, company configs, accepted methods.
 */

import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";
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
  let where = "1=1";
  const params: Record<string, unknown> = {};
  if (countryCode) {
    where += " AND (CountryCode = @cc OR CountryCode IS NULL)";
    params.cc = countryCode;
  }
  return query<PaymentMethod>(`
    SELECT Id, Code, Name, Category, CountryCode, IconName,
           RequiresGateway, IsActive, SortOrder
    FROM pay.PaymentMethods
    WHERE ${where} AND IsActive = 1
    ORDER BY SortOrder, Name
  `, params);
}

export async function upsertPaymentMethod(data: Partial<PaymentMethod> & { code: string; name: string }) {
  const pool = await getPool();
  await pool.request()
    .input("code", sql.VarChar(30), data.code)
    .input("name", sql.NVarChar(100), data.name)
    .input("category", sql.VarChar(30), data.category || "OTHER")
    .input("countryCode", sql.Char(2), data.countryCode || null)
    .input("iconName", sql.VarChar(50), data.iconName || null)
    .input("requiresGateway", sql.Bit, data.requiresGateway ? 1 : 0)
    .input("isActive", sql.Bit, data.isActive !== false ? 1 : 0)
    .input("sortOrder", sql.Int, data.sortOrder || 0)
    .query(`
      MERGE pay.PaymentMethods AS t
      USING (SELECT @code AS Code, @countryCode AS CC) AS s
      ON t.Code = s.Code AND ISNULL(t.CountryCode,'__') = ISNULL(s.CC,'__')
      WHEN MATCHED THEN
        UPDATE SET Name = @name, Category = @category, IconName = @iconName,
                   RequiresGateway = @requiresGateway, IsActive = @isActive, SortOrder = @sortOrder
      WHEN NOT MATCHED THEN
        INSERT (Code, Name, Category, CountryCode, IconName, RequiresGateway, IsActive, SortOrder)
        VALUES (@code, @name, @category, @countryCode, @iconName, @requiresGateway, @isActive, @sortOrder);
    `);
}

// ══════════════════════════════════════════════════════════════
// Payment Providers
// ══════════════════════════════════════════════════════════════

export async function listProviders(countryCode?: string) {
  let where = "IsActive = 1";
  const params: Record<string, unknown> = {};
  if (countryCode) {
    where += " AND (CountryCode = @cc OR CountryCode IS NULL)";
    params.cc = countryCode;
  }
  return query<PaymentProvider>(`
    SELECT Id, Code, Name, CountryCode, ProviderType, BaseUrlSandbox, BaseUrlProd,
           AuthType, DocsUrl, LogoUrl, IsActive
    FROM pay.PaymentProviders
    WHERE ${where}
    ORDER BY Name
  `, params);
}

export async function getProviderByCode(code: string) {
  const rows = await query<PaymentProvider>(
    "SELECT * FROM pay.PaymentProviders WHERE Code = @code",
    { code }
  );
  return rows[0] || null;
}

export async function getProviderCapabilities(providerCode: string) {
  return query<any>(`
    SELECT c.*, p.Code AS ProviderCode
    FROM pay.ProviderCapabilities c
    JOIN pay.PaymentProviders p ON p.Id = c.ProviderId
    WHERE p.Code = @code AND c.IsActive = 1
    ORDER BY c.Capability, c.PaymentMethod
  `, { code: providerCode });
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
  return getAllPlugins().map(p => ({
    providerCode: p.providerCode,
    fields: p.getConfigFields(),
  }));
}

// ══════════════════════════════════════════════════════════════
// Company Payment Config
// ══════════════════════════════════════════════════════════════

export async function listCompanyConfigs(empresaId: number, sucursalId?: number) {
  let where = "c.EmpresaId = @eid";
  const params: Record<string, unknown> = { eid: empresaId };
  if (sucursalId != null) {
    where += " AND c.SucursalId = @sid";
    params.sid = sucursalId;
  }
  return query<any>(`
    SELECT c.*, p.Code AS ProviderCode, p.Name AS ProviderName
    FROM pay.CompanyPaymentConfig c
    JOIN pay.PaymentProviders p ON p.Id = c.ProviderId
    WHERE ${where}
    ORDER BY p.Name
  `, params);
}

export async function upsertCompanyConfig(data: CompanyPaymentConfigInput) {
  // Resolve provider ID
  const provider = await getProviderByCode(data.providerCode);
  if (!provider) throw new Error(`Provider not found: ${data.providerCode}`);

  const pool = await getPool();
  await pool.request()
    .input("eid", sql.Int, data.empresaId)
    .input("sid", sql.Int, data.sucursalId)
    .input("cc", sql.Char(2), data.countryCode)
    .input("pid", sql.Int, provider.id)
    .input("env", sql.VarChar(10), data.environment || "sandbox")
    .input("clientId", sql.VarChar(500), data.clientId || null)
    .input("clientSecret", sql.VarChar(500), data.clientSecret || null)
    .input("merchantId", sql.VarChar(100), data.merchantId || null)
    .input("terminalId", sql.VarChar(100), data.terminalId || null)
    .input("integratorId", sql.VarChar(50), data.integratorId || null)
    .input("certPath", sql.VarChar(500), data.certificatePath || null)
    .input("extra", sql.NVarChar(sql.MAX), data.extraConfig ? JSON.stringify(data.extraConfig) : null)
    .input("autoCap", sql.Bit, data.autoCapture !== false ? 1 : 0)
    .input("allowRef", sql.Bit, data.allowRefunds !== false ? 1 : 0)
    .input("maxRef", sql.Int, data.maxRefundDays ?? 30)
    .query(`
      MERGE pay.CompanyPaymentConfig AS t
      USING (SELECT @eid AS E, @sid AS S, @pid AS P) AS s
      ON t.EmpresaId = s.E AND t.SucursalId = s.S AND t.ProviderId = s.P
      WHEN MATCHED THEN
        UPDATE SET CountryCode = @cc, Environment = @env,
                   ClientId = COALESCE(@clientId, t.ClientId),
                   ClientSecret = COALESCE(@clientSecret, t.ClientSecret),
                   MerchantId = COALESCE(@merchantId, t.MerchantId),
                   TerminalId = COALESCE(@terminalId, t.TerminalId),
                   IntegratorId = COALESCE(@integratorId, t.IntegratorId),
                   CertificatePath = COALESCE(@certPath, t.CertificatePath),
                   ExtraConfig = COALESCE(@extra, t.ExtraConfig),
                   AutoCapture = @autoCap, AllowRefunds = @allowRef,
                   MaxRefundDays = @maxRef, IsActive = 1, UpdatedAt = GETDATE()
      WHEN NOT MATCHED THEN
        INSERT (EmpresaId, SucursalId, CountryCode, ProviderId, Environment,
                ClientId, ClientSecret, MerchantId, TerminalId, IntegratorId,
                CertificatePath, ExtraConfig, AutoCapture, AllowRefunds, MaxRefundDays)
        VALUES (@eid, @sid, @cc, @pid, @env,
                @clientId, @clientSecret, @merchantId, @terminalId, @integratorId,
                @certPath, @extra, @autoCap, @allowRef, @maxRef);
    `);
}

export async function deleteCompanyConfig(id: number) {
  const pool = await getPool();
  await pool.request()
    .input("id", sql.Int, id)
    .query("UPDATE pay.CompanyPaymentConfig SET IsActive = 0 WHERE Id = @id");
}

// ══════════════════════════════════════════════════════════════
// Accepted Payment Methods per Company
// ══════════════════════════════════════════════════════════════

export async function listAcceptedMethods(
  empresaId: number,
  sucursalId: number,
  channel?: "POS" | "WEB" | "RESTAURANT"
) {
  let channelFilter = "";
  if (channel === "POS") channelFilter = "AND a.AppliesToPOS = 1";
  else if (channel === "WEB") channelFilter = "AND a.AppliesToWeb = 1";
  else if (channel === "RESTAURANT") channelFilter = "AND a.AppliesToRestaurant = 1";

  return query<AcceptedPaymentMethod>(`
    SELECT a.*,
           m.Code AS methodCode, m.Name AS methodName, m.Category AS methodCategory, m.IconName,
           p.Code AS providerCode, p.Name AS providerName
    FROM pay.AcceptedPaymentMethods a
    JOIN pay.PaymentMethods m ON m.Id = a.PaymentMethodId
    LEFT JOIN pay.PaymentProviders p ON p.Id = a.ProviderId
    WHERE a.EmpresaId = @eid AND a.SucursalId = @sid AND a.IsActive = 1 ${channelFilter}
    ORDER BY a.SortOrder, m.Name
  `, { eid: empresaId, sid: sucursalId });
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
  const pool = await getPool();
  await pool.request()
    .input("eid", sql.Int, data.empresaId)
    .input("sid", sql.Int, data.sucursalId)
    .input("pmid", sql.Int, data.paymentMethodId)
    .input("pid", sql.Int, data.providerId || null)
    .input("pos", sql.Bit, data.appliesToPOS !== false ? 1 : 0)
    .input("web", sql.Bit, data.appliesToWeb !== false ? 1 : 0)
    .input("rest", sql.Bit, data.appliesToRestaurant !== false ? 1 : 0)
    .input("minAmt", sql.Decimal(18, 2), data.minAmount || null)
    .input("maxAmt", sql.Decimal(18, 2), data.maxAmount || null)
    .input("commPct", sql.Decimal(5, 4), data.commissionPct || null)
    .input("commFix", sql.Decimal(18, 2), data.commissionFixed || null)
    .input("sort", sql.Int, data.sortOrder || 0)
    .query(`
      MERGE pay.AcceptedPaymentMethods AS t
      USING (SELECT @eid AS E, @sid AS S, @pmid AS M, @pid AS P) AS s
      ON t.EmpresaId = s.E AND t.SucursalId = s.S AND t.PaymentMethodId = s.M AND ISNULL(t.ProviderId,0) = ISNULL(s.P,0)
      WHEN MATCHED THEN
        UPDATE SET AppliesToPOS = @pos, AppliesToWeb = @web, AppliesToRestaurant = @rest,
                   MinAmount = @minAmt, MaxAmount = @maxAmt,
                   CommissionPct = @commPct, CommissionFixed = @commFix,
                   SortOrder = @sort, IsActive = 1
      WHEN NOT MATCHED THEN
        INSERT (EmpresaId, SucursalId, PaymentMethodId, ProviderId,
                AppliesToPOS, AppliesToWeb, AppliesToRestaurant,
                MinAmount, MaxAmount, CommissionPct, CommissionFixed, SortOrder)
        VALUES (@eid, @sid, @pmid, @pid, @pos, @web, @rest,
                @minAmt, @maxAmt, @commPct, @commFix, @sort);
    `);
}

export async function removeAcceptedMethod(id: number) {
  const pool = await getPool();
  await pool.request()
    .input("id", sql.Int, id)
    .query("UPDATE pay.AcceptedPaymentMethods SET IsActive = 0 WHERE Id = @id");
}

// ══════════════════════════════════════════════════════════════
// Card Reader Devices
// ══════════════════════════════════════════════════════════════

export async function listCardReaders(empresaId: number, sucursalId?: number) {
  let where = "EmpresaId = @eid";
  const params: Record<string, unknown> = { eid: empresaId };
  if (sucursalId != null) {
    where += " AND SucursalId = @sid";
    params.sid = sucursalId;
  }
  return query<CardReaderDevice>(`
    SELECT * FROM pay.CardReaderDevices
    WHERE ${where} AND IsActive = 1
    ORDER BY StationId, DeviceName
  `, params);
}

export async function upsertCardReader(data: Omit<CardReaderDevice, "id" | "isActive" | "lastSeenAt"> & { id?: number }) {
  const pool = await getPool();
  if (data.id) {
    await pool.request()
      .input("id", sql.Int, data.id)
      .input("name", sql.NVarChar(100), data.deviceName)
      .input("type", sql.VarChar(30), data.deviceType)
      .input("connType", sql.VarChar(30), data.connectionType)
      .input("connCfg", sql.NVarChar(500), data.connectionConfig ? JSON.stringify(data.connectionConfig) : null)
      .input("pid", sql.Int, data.providerId || null)
      .input("station", sql.VarChar(50), data.stationId)
      .query(`
        UPDATE pay.CardReaderDevices
        SET DeviceName = @name, DeviceType = @type, ConnectionType = @connType,
            ConnectionConfig = @connCfg, ProviderId = @pid, StationId = @station
        WHERE Id = @id
      `);
  } else {
    await pool.request()
      .input("eid", sql.Int, data.empresaId)
      .input("sid", sql.Int, data.sucursalId)
      .input("station", sql.VarChar(50), data.stationId)
      .input("name", sql.NVarChar(100), data.deviceName)
      .input("type", sql.VarChar(30), data.deviceType)
      .input("connType", sql.VarChar(30), data.connectionType)
      .input("connCfg", sql.NVarChar(500), data.connectionConfig ? JSON.stringify(data.connectionConfig) : null)
      .input("pid", sql.Int, data.providerId || null)
      .query(`
        INSERT INTO pay.CardReaderDevices (EmpresaId, SucursalId, StationId, DeviceName, DeviceType, ConnectionType, ConnectionConfig, ProviderId)
        VALUES (@eid, @sid, @station, @name, @type, @connType, @connCfg, @pid)
      `);
  }
}
