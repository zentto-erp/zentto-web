/**
 * DatqBox Payment Gateway — Plugin Registry
 *
 * Central registry that maps provider codes to their plugin implementations.
 * New providers are added here.
 */

import type { IPaymentPlugin } from "./types.js";
import { MercantilPlugin } from "./plugins/mercantil.plugin.js";
import { RedsysPlugin } from "./plugins/redsys.plugin.js";
import { BinancePayPlugin } from "./plugins/binance-pay.plugin.js";
import { ManualPlugin } from "./plugins/manual.plugin.js";

const plugins = new Map<string, IPaymentPlugin>();

function register(plugin: IPaymentPlugin) {
  plugins.set(plugin.providerCode, plugin);
}

// ── Register all known plugins ──────────────────────────────────

register(new MercantilPlugin());
register(new RedsysPlugin());
register(new BinancePayPlugin());
register(new ManualPlugin());

// Spanish banks — all route through Redsys, same plugin with different providerCode label
// The RedsysPlugin is generic; we alias it for each Spanish bank so config lookup works
const redsysAliases = ["CAIXABANK", "BBVA_ES", "SANTANDER_ES", "SABADELL", "BANKINTER"];
for (const alias of redsysAliases) {
  const aliased = new RedsysPlugin();
  (aliased as any).providerCode = alias;       // override code for registry lookup
  register(aliased);
}

// VE banks without public API — mapped to ManualPlugin until APIs are available
const manualVeBanks = ["BDV", "BANCA_AMIGA", "BANESCO", "PROVINCIAL"];
for (const code of manualVeBanks) {
  const manual = new ManualPlugin();
  (manual as any).providerCode = code;
  register(manual);
}

// ── Public API ──────────────────────────────────────────────────

export function getPlugin(providerCode: string): IPaymentPlugin | undefined {
  return plugins.get(providerCode);
}

export function getAllPlugins(): IPaymentPlugin[] {
  return Array.from(plugins.values());
}

export function getPluginCodes(): string[] {
  return Array.from(plugins.keys());
}
