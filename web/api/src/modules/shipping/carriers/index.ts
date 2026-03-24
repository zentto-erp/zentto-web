/**
 * Carrier Registry — Factory para obtener el adapter correcto según carrierCode.
 */
import type { CarrierAdapter, CarrierConfig } from "./carrier.interface.js";
import { GenericCarrierAdapter } from "./generic.adapter.js";
import { ZoomCarrierAdapter } from "./zoom.adapter.js";
import { MrwCarrierAdapter } from "./mrw.adapter.js";
import { LibertyCarrierAdapter } from "./liberty.adapter.js";

const adapterCache = new Map<string, CarrierAdapter>();

export function getCarrierAdapter(config: CarrierConfig): CarrierAdapter {
  const cacheKey = `${config.carrierCode}_${config.carrierConfigId}`;
  const cached = adapterCache.get(cacheKey);
  if (cached) return cached;

  let adapter: CarrierAdapter;

  switch (config.carrierCode.toUpperCase()) {
    case "ZOOM":
      adapter = new ZoomCarrierAdapter(config);
      break;
    case "MRW":
      adapter = new MrwCarrierAdapter(config);
      break;
    case "LIBERTY":
      adapter = new LibertyCarrierAdapter(config);
      break;
    default:
      adapter = new GenericCarrierAdapter();
      break;
  }

  adapterCache.set(cacheKey, adapter);
  return adapter;
}

export function getAllAdapters(configs: CarrierConfig[]): CarrierAdapter[] {
  return configs.map(getCarrierAdapter);
}

export { type CarrierAdapter, type CarrierConfig } from "./carrier.interface.js";
