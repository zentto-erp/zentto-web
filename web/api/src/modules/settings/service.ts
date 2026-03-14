import { callSp, callSpOut, sql } from "../../db/query.js";

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
  const rows = await callSp<{ Module: string; SettingKey: string; SettingValue: string; ValueType: string }>(
    "usp_Cfg_AppSetting_List",
    { CompanyId: companyId }
  );

  const grouped: Record<string, Record<string, any>> = {};
  for (const row of rows) {
    const mod = row.Module;
    if (!grouped[mod]) grouped[mod] = {};
    grouped[mod][row.SettingKey] = parseValue(row.SettingValue, row.ValueType);
  }
  return grouped;
}

/**
 * Get settings for a specific module.
 */
export async function getModuleSettings(companyId: number, moduleName: string): Promise<Record<string, any>> {
  const rows = await callSp<{ SettingKey: string; SettingValue: string; ValueType: string }>(
    "usp_Cfg_AppSetting_ListByModule",
    { CompanyId: companyId, Module: moduleName }
  );

  const settings: Record<string, any> = {};
  for (const row of rows) {
    settings[row.SettingKey] = parseValue(row.SettingValue, row.ValueType);
  }
  return settings;
}

/**
 * Get settings with full metadata (for admin panel).
 */
export async function getModuleSettingsWithMeta(companyId: number, moduleName: string): Promise<AppSetting[]> {
  const rows = await callSp<{
    SettingId: number; CompanyId: number; Module: string; SettingKey: string;
    SettingValue: string; ValueType: string; Description: string | null;
    IsReadOnly: boolean; UpdatedAt: string;
  }>(
    "usp_Cfg_AppSetting_ListWithMeta",
    { CompanyId: companyId, Module: moduleName }
  );

  return rows.map((r) => ({
    settingId: r.SettingId,
    companyId: r.CompanyId,
    module: r.Module,
    settingKey: r.SettingKey,
    settingValue: r.SettingValue,
    valueType: r.ValueType as AppSetting["valueType"],
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
  let saved = 0;

  // Fetch existing keys for type info via SP
  const existing = await callSp<{ SettingKey: string; ValueType: string; IsReadOnly: boolean }>(
    "usp_Cfg_AppSetting_ListWithMeta",
    { CompanyId: companyId, Module: moduleName }
  );

  const typeMap = new Map<string, { valueType: string; isReadOnly: boolean }>();
  for (const r of existing) {
    typeMap.set(r.SettingKey, { valueType: r.ValueType, isReadOnly: r.IsReadOnly });
  }

  for (const [key, value] of Object.entries(settings)) {
    const meta = typeMap.get(key);

    // Skip read-only settings
    if (meta?.isReadOnly) continue;

    const vt = meta?.valueType || inferValueType(value);
    const serialized = serializeValue(value, vt);

    await callSpOut(
      "usp_Cfg_AppSetting_Upsert",
      {
        CompanyId: companyId,
        Module: moduleName,
        SettingKey: key,
        SettingValue: serialized,
        ValueType: vt,
        UserId: userId ?? null,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );
    saved++;
  }

  return { saved };
}

/** List distinct module names that have settings */
export async function listSettingModules(companyId: number): Promise<string[]> {
  const rows = await callSp<{ Module: string }>(
    "usp_Cfg_AppSetting_ListModules",
    { CompanyId: companyId }
  );
  return rows.map((r) => r.Module);
}

function inferValueType(val: any): string {
  if (typeof val === "boolean") return "boolean";
  if (typeof val === "number") return "number";
  if (typeof val === "object") return "json";
  return "string";
}
