/**
 * Carrier Registry — Factory + detección automática por formato de tracking
 *
 * Carriers implementados:
 *
 * Venezuela (VE):
 *   ZOOM      — GET HTML scraping zoom.red (sin credenciales)
 *   MRW       — POST JSON mrwve.com/api/tracking (sin credenciales)
 *   TEALCA    — GET HTML scraping tealca.com (sin credenciales, best-effort)
 *   LIBERTY   — iQPack stub (pendiente API)
 *
 * España (ES):
 *   CORREOS_ES — GET JSON api1.correos.es (sin credenciales, API pública)
 *   MRW_ES     — POST HTML scraping mrw.es (sin credenciales)
 *
 * Colombia (CO):
 *   DOMESA     — POST JSON domesa.com.co (sin credenciales)
 *
 * Global:
 *   DHL        — GET API api-eu.dhl.com (demo-key gratis 250/día)
 *   TRACKINGMORE — POST aggregator (SEUR, GLS, FedEx, UPS, Servientrega, etc.)
 *
 * Manual/interno:
 *   GENERIC    — Sin API, tracking manual via ShipmentEvent
 */
import type { CarrierAdapter, CarrierConfig } from "./carrier.interface.js";
import { GenericCarrierAdapter }     from "./generic.adapter.js";
import { ZoomCarrierAdapter }        from "./zoom.adapter.js";
import { MrwCarrierAdapter }         from "./mrw.adapter.js";
import { LibertyCarrierAdapter }     from "./liberty.adapter.js";
import { TealcaAdapter }             from "./tealca.adapter.js";
import { CorreosEsAdapter }          from "./correos-es.adapter.js";
import { MrwEsAdapter }              from "./mrw-es.adapter.js";
import { DomesaAdapter }             from "./domesa.adapter.js";
import { DhlAdapter }                from "./dhl.adapter.js";
import { TrackingMoreAdapter }       from "./trackingmore.adapter.js";

const adapterCache = new Map<string, CarrierAdapter>();

export function getCarrierAdapter(config: CarrierConfig): CarrierAdapter {
  const cacheKey = `${config.carrierCode}_${config.carrierConfigId}`;
  const cached = adapterCache.get(cacheKey);
  if (cached) return cached;

  let adapter: CarrierAdapter;

  switch (config.carrierCode.toUpperCase()) {
    // ── Venezuela ────────────────────────────────────────────
    case "ZOOM":           adapter = new ZoomCarrierAdapter(config);    break;
    case "MRW":            adapter = new MrwCarrierAdapter(config);     break;
    case "TEALCA":         adapter = new TealcaAdapter(config);         break;
    case "LIBERTY":        adapter = new LibertyCarrierAdapter(config); break;

    // ── España ───────────────────────────────────────────────
    case "CORREOS_ES":     adapter = new CorreosEsAdapter(config);      break;
    case "MRW_ES":         adapter = new MrwEsAdapter(config);          break;

    // ── Colombia ─────────────────────────────────────────────
    case "DOMESA":         adapter = new DomesaAdapter(config);         break;

    // ── Global ───────────────────────────────────────────────
    case "DHL":            adapter = new DhlAdapter(config);            break;
    case "TRACKINGMORE":   adapter = new TrackingMoreAdapter(config);   break;

    default:               adapter = new GenericCarrierAdapter();        break;
  }

  adapterCache.set(cacheKey, adapter);
  return adapter;
}

export function getAllAdapters(configs: CarrierConfig[]): CarrierAdapter[] {
  return configs.map(getCarrierAdapter);
}

/**
 * Detecta candidatos de carrier por formato del número de tracking.
 * Usado en tryCarrierDirectTracking() cuando el envío no está en nuestra BD.
 */
export function detectCarrierCandidates(
  trackingNumber: string,
  configs: CarrierConfig[]
): CarrierConfig[] {
  const t = trackingNumber.toUpperCase().trim();

  // ── España ────────────────────────────────────────────────────────
  // Correos ES: EA/RR/CP + 9 dígitos + ES  (ej: EA123456789ES)
  if (/^[A-Z]{2}\d{9}[A-Z]{2}$/.test(t)) {
    return configs.filter((c) => c.carrierCode === "CORREOS_ES");
  }

  // ── Venezuela ─────────────────────────────────────────────────────
  // Número puro de dígitos (8-12 dígitos) → Zoom o MRW Venezuela
  if (/^\d{8,12}$/.test(t)) {
    const ve = configs.filter((c) => ["ZOOM", "MRW", "TEALCA"].includes(c.carrierCode));
    return ve.length > 0 ? ve : configs;
  }

  // ── Prefijos conocidos ─────────────────────────────────────────────
  if (t.startsWith("MRW-") || t.startsWith("MRW")) {
    return configs.filter((c) => ["MRW", "MRW_ES"].includes(c.carrierCode));
  }
  if (t.startsWith("ZM-") || t.startsWith("ZOO")) {
    return configs.filter((c) => c.carrierCode === "ZOOM");
  }
  if (t.startsWith("TL-")) {
    return configs.filter((c) => c.carrierCode === "TEALCA");
  }
  if (t.startsWith("DOM-")) {
    return configs.filter((c) => c.carrierCode === "DOMESA");
  }
  if (t.startsWith("LIB-")) {
    return configs.filter((c) => c.carrierCode === "LIBERTY");
  }

  // ── DHL: 10 dígitos o JD + dígitos ────────────────────────────────
  if (/^JD\d{18}$/.test(t) || /^\d{10}$/.test(t)) {
    return configs.filter((c) => c.carrierCode === "DHL");
  }

  // ── Colombia: guías Domesa ─────────────────────────────────────────
  if (t.startsWith("DOM") || /^\d{12,15}$/.test(t)) {
    const co = configs.filter((c) => c.carrierCode === "DOMESA");
    if (co.length > 0) return co;
  }

  // ── Fallback: TrackingMore para todo lo demás ──────────────────────
  const tm = configs.filter((c) => c.carrierCode === "TRACKINGMORE");
  if (tm.length > 0) return tm;

  return configs;
}

export { type CarrierAdapter, type CarrierConfig } from "./carrier.interface.js";
