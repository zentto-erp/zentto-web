import { getPool, sql } from "../../db/mssql.js";

export interface AppSetting {
  settingId: number;
  companyId: number;
  module: string;
  settingKey: string;
  settingValue: string;
  valueType: "string" | "number" | "boolean" | "json";
  description: string | null;
  isReadOnly: boolean;
  updatedAt: string;
}

/** Parse raw DB value into its typed form */
function parseValue(raw: string, type: string): any {
  switch (type) {
    case "number":
      return Number(raw);
    case "boolean":
      return raw === "true" || raw === "1";
    case "json":
      try {
        return JSON.parse(raw);
      } catch {
        return raw;
      }
    default:
      return raw;
  }
}

/** Convert typed value back to string for storage */
function serializeValue(val: any, type: string): string {
  if (type === "json") return JSON.stringify(val);
  if (type === "boolean") return val ? "true" : "false";
  return String(val ?? "");
}

/**
 * Get ALL settings for a company, grouped by module.
 * Returns: { general: { pais: 'VE', ... }, contabilidad: { ... }, ... }
 */
export async function getAllSettings(companyId: number): Promise<Record<string, Record<string, any>>> {
  const pool = await getPool();
  const result = await pool
    .request()
    .input("companyId", sql.Int, companyId)
    .query(`SELECT Module, SettingKey, SettingValue, ValueType
            FROM cfg.AppSetting
            WHERE CompanyId = @companyId
            ORDER BY Module, SettingKey`);

  const grouped: Record<string, Record<string, any>> = {};
  for (const row of result.recordset) {
    const mod = row.Module as string;
    if (!grouped[mod]) grouped[mod] = {};
    grouped[mod][row.SettingKey] = parseValue(row.SettingValue, row.ValueType);
  }
  return grouped;
}

/**
 * Get settings for a specific module.
 */
export async function getModuleSettings(companyId: number, moduleName: string): Promise<Record<string, any>> {
  const pool = await getPool();
  const result = await pool
    .request()
    .input("companyId", sql.Int, companyId)
    .input("module", sql.NVarChar(60), moduleName)
    .query(`SELECT SettingKey, SettingValue, ValueType, Description, IsReadOnly
            FROM cfg.AppSetting
            WHERE CompanyId = @companyId AND Module = @module
            ORDER BY SettingKey`);

  const settings: Record<string, any> = {};
  for (const row of result.recordset) {
    settings[row.SettingKey] = parseValue(row.SettingValue, row.ValueType);
  }
  return settings;
}

/**
 * Get settings with full metadata (for admin panel).
 */
export async function getModuleSettingsWithMeta(companyId: number, moduleName: string): Promise<AppSetting[]> {
  const pool = await getPool();
  const result = await pool
    .request()
    .input("companyId", sql.Int, companyId)
    .input("module", sql.NVarChar(60), moduleName)
    .query(`SELECT SettingId, CompanyId, Module, SettingKey, SettingValue, ValueType,
                   Description, IsReadOnly, UpdatedAt
            FROM cfg.AppSetting
            WHERE CompanyId = @companyId AND Module = @module
            ORDER BY SettingKey`);

  return result.recordset.map((r: any) => ({
    settingId: r.SettingId,
    companyId: r.CompanyId,
    module: r.Module,
    settingKey: r.SettingKey,
    settingValue: r.SettingValue,
    valueType: r.ValueType,
    description: r.Description,
    isReadOnly: r.IsReadOnly,
    updatedAt: r.UpdatedAt,
  }));
}

/**
 * Bulk-save settings for a module. UPSERT approach.
 * Receives a flat object: { key1: value1, key2: value2, ... }
 */
export async function saveModuleSettings(
  companyId: number,
  moduleName: string,
  settings: Record<string, any>,
  userId?: number
): Promise<{ saved: number }> {
  const pool = await getPool();
  let saved = 0;

  // Fetch existing keys for type info
  const existing = await pool
    .request()
    .input("companyId", sql.Int, companyId)
    .input("module", sql.NVarChar(60), moduleName)
    .query(`SELECT SettingKey, ValueType, IsReadOnly FROM cfg.AppSetting
            WHERE CompanyId = @companyId AND Module = @module`);

  const typeMap = new Map<string, { valueType: string; isReadOnly: boolean }>();
  for (const r of existing.recordset) {
    typeMap.set(r.SettingKey, { valueType: r.ValueType, isReadOnly: r.IsReadOnly });
  }

  for (const [key, value] of Object.entries(settings)) {
    const meta = typeMap.get(key);

    // Skip read-only settings
    if (meta?.isReadOnly) continue;

    const vt = meta?.valueType || inferValueType(value);
    const serialized = serializeValue(value, vt);

    await pool
      .request()
      .input("companyId", sql.Int, companyId)
      .input("module", sql.NVarChar(60), moduleName)
      .input("key", sql.NVarChar(120), key)
      .input("value", sql.NVarChar(sql.MAX), serialized)
      .input("valueType", sql.NVarChar(20), vt)
      .input("userId", sql.Int, userId ?? null)
      .query(`
        IF EXISTS (SELECT 1 FROM cfg.AppSetting WHERE CompanyId = @companyId AND Module = @module AND SettingKey = @key)
          UPDATE cfg.AppSetting
          SET SettingValue = @value, ValueType = @valueType, UpdatedAt = SYSUTCDATETIME(), UpdatedByUserId = @userId
          WHERE CompanyId = @companyId AND Module = @module AND SettingKey = @key
        ELSE
          INSERT INTO cfg.AppSetting (CompanyId, Module, SettingKey, SettingValue, ValueType, UpdatedByUserId)
          VALUES (@companyId, @module, @key, @value, @valueType, @userId)
      `);
    saved++;
  }

  return { saved };
}

/** List distinct module names that have settings */
export async function listSettingModules(companyId: number): Promise<string[]> {
  const pool = await getPool();
  const result = await pool
    .request()
    .input("companyId", sql.Int, companyId)
    .query(`SELECT DISTINCT Module FROM cfg.AppSetting WHERE CompanyId = @companyId ORDER BY Module`);
  return result.recordset.map((r: any) => r.Module);
}

function inferValueType(val: any): string {
  if (typeof val === "boolean") return "boolean";
  if (typeof val === "number") return "number";
  if (typeof val === "object") return "json";
  return "string";
}
