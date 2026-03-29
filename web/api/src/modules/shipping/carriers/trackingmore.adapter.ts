/**
 * TrackingMore Aggregator Adapter — Fallback para carriers sin API pública
 * Cubre: SEUR ES, GLS Spain, FedEx, UPS, Servientrega CO, Liberty Express VE,
 *        Estafeta MX, Redpack MX, Paquetexpress MX, y 1,570+ carriers más.
 *
 * API: POST https://api.trackingmore.com/v4/trackings/realtime
 * Header: Tracking-Api-Key: {API_KEY}
 *
 * Para obtener clave: https://www.trackingmore.com/api
 * - Plan gratuito: 14 días trial
 * - Plan básico: $11/mes → 200 trackings
 *
 * El carrier code de TrackingMore se detecta automáticamente o se puede
 * especificar en extraConfig.trackingmoreCode.
 *
 * Configurar en .env: CARRIER_TRACKINGMORE_API_KEY=xxxx
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const TM_API = "https://api.trackingmore.com/v4/trackings/realtime";

// Mapeo de estados TrackingMore → Zentto
const TM_STATUS_MAP: Record<string, string> = {
  delivered: "DELIVERED",
  out_for_delivery: "OUT_FOR_DELIVERY",
  in_transit: "IN_TRANSIT",
  pickup: "PICKED_UP",
  undelivered: "EXCEPTION",
  exception: "EXCEPTION",
  expired: "EXCEPTION",
  pending: "DRAFT",
  notfound: "DRAFT",
};

export class TrackingMoreAdapter implements CarrierAdapter {
  readonly code = "TRACKINGMORE";
  readonly name = "TrackingMore (Aggregator)";
  readonly supportedCountries = ["*"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  private get apiKey(): string {
    return this.config.apiKey ||
      process.env.CARRIER_TRACKINGMORE_API_KEY ||
      "";
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    // TrackingMore es solo tracking — no cotiza
    return [];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = "TM-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return { trackingNumber, labelUrl: null, labelBase64: null, carrierTrackingUrl: null };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    if (!this.apiKey) return [];

    // Carrier slug de TrackingMore (ej: "seur", "gls-spain", "fedex")
    const carrierCode = this.config.extraConfig?.trackingmoreCode ||
                        this.config.extraConfig?.tmCode ||
                        undefined;

    const body: Record<string, any> = { tracking_number: trackingNumber };
    if (carrierCode) body.carrier_code = carrierCode;

    try {
      const res = await fetch(TM_API, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Tracking-Api-Key": this.apiKey,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(15_000),
      });

      if (!res.ok) return [];

      const data = await res.json() as any;

      if (data.code !== 200 || !data.data) return [];

      const trackingData = data.data;
      const rawEvents: any[] = trackingData.origin_info?.trackinfo || trackingData.destination_info?.trackinfo || [];

      if (rawEvents.length === 0) return [];

      return rawEvents.map((e: any) => ({
        eventType: "UPDATE",
        status: TM_STATUS_MAP[trackingData.status] || "IN_TRANSIT",
        description: e.tracking_detail || "",
        location: e.location || null,
        city: e.location || null,
        countryCode: trackingData.origin_country || null,
        carrierEventCode: null,
        eventAt: e.Date || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `TrackingMore ${trackingNumber}: contactar carrier directamente` };
  }

  async getLabel(_trackingNumber: string) {
    return {};
  }
}
