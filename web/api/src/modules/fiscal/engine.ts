import { CountryCode, IFiscalPlugin } from "./types.js";
import { EspanaVerifactuPlugin } from "./plugins/espana-verifactu.plugin.js";
import { VenezuelaFiscalPlugin } from "./plugins/venezuela.plugin.js";

const pluginRegistry: Record<CountryCode, IFiscalPlugin> = {
  VE: new VenezuelaFiscalPlugin(),
  ES: new EspanaVerifactuPlugin()
};

export function getFiscalPlugin(countryCode: CountryCode): IFiscalPlugin {
  return pluginRegistry[countryCode];
}

export function listFiscalPlugins() {
  return Object.values(pluginRegistry).map((plugin) => ({
    countryCode: plugin.countryCode,
    taxRates: plugin.getTaxRates().length,
    invoiceTypes: plugin.getInvoiceTypes().length
  }));
}
