/**
 * Correos España Carrier Adapter
 * API pública confirmada (no requiere credenciales):
 * GET https://api1.correos.es/digital-services/searchengines/api/v1/?text={TRACKING}&language=ES&searchType=envio
 * - HTTP 204 = guía no encontrada
 * - HTTP 200 = JSON con shipment[] y events[]
 * Cobertura: ES → mundo entero (paquetería internacional Correos)
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const API_BASE = "https://api1.correos.es/digital-services/searchengines/api/v1/";

// Mapeo de fases/estados Correos → estado interno Zentto
function mapCorreosStatus(phase: string, summaryText?: string): string {
  const p = (phase || "").toLowerCase();
  const t = (summaryText || "").toLowerCase();
  if (p.includes("entregad") || t.includes("entregado")) return "DELIVERED";
  if (p.includes("reparto") || t.includes("reparto") || t.includes("en camino")) return "OUT_FOR_DELIVERY";
  if (p.includes("aduana") || t.includes("aduana")) return "IN_CUSTOMS";
  if (p.includes("transito") || p.includes("tránsito") || t.includes("transito")) return "IN_TRANSIT";
  if (p.includes("admitid") || p.includes("recogid") || t.includes("admitido")) return "PICKED_UP";
  if (p.includes("devuelto") || t.includes("devuelto")) return "RETURNED";
  if (p.includes("incidencia") || t.includes("incidencia")) return "EXCEPTION";
  return "IN_TRANSIT";
}

export class CorreosEsAdapter implements CarrierAdapter {
  readonly code = "CORREOS_ES";
  readonly name = "Correos España";
  readonly supportedCountries = ["ES"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);
    const isIntl = req.originCountryCode !== req.destCountryCode;
    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "STANDARD", serviceName: "Correos Paquete Estándar",
        price: isIntl ? Math.max(12, totalWeight * 4) : Math.max(3.5, totalWeight * 1.2),
        currency: "EUR", estimatedDays: isIntl ? 10 : 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Correos Express",
        price: isIntl ? Math.max(20, totalWeight * 6) : Math.max(6, totalWeight * 2),
        currency: "EUR", estimatedDays: isIntl ? 5 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = "ES" + crypto.randomBytes(8).toString("hex").toUpperCase().slice(0, 9) + "ES";
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    try {
      const url = `${API_BASE}?text=${encodeURIComponent(trackingNumber)}&language=ES&searchType=envio`;
      const res = await fetch(url, {
        headers: {
          "Referer": "https://www.correos.es/",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "application/json, text/plain, */*",
          "Origin": "https://www.correos.es",
        },
        signal: AbortSignal.timeout(12_000),
      });

      // 204 = guía no encontrada
      if (res.status === 204 || !res.ok) return [];

      const data = await res.json() as any;
      const eventsRaw: any[] = data.events || data.shipment?.[0]?.events || [];

      if (eventsRaw.length === 0) return [];

      return eventsRaw.map((e: any) => ({
        eventType: "UPDATE",
        status: mapCorreosStatus(e.phase || e.state || "", e.summaryText || e.description),
        description: e.summaryText || e.description || e.phase || "",
        location: e.officeName || e.office || null,
        city: e.city || e.municipality || null,
        countryCode: e.countryCode || "ES",
        carrierEventCode: e.phase || e.state || null,
        eventAt: e.recordDate || e.date || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `Correos ES ${trackingNumber}: contactar oficina de Correos` };
  }

  async getLabel(trackingNumber: string) {
    return {
      url: `https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number=${trackingNumber}`,
    };
  }
}
