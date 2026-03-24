/**
 * Zoom Carrier Adapter — Integración con API de Zoom Envíos (Venezuela/LATAM)
 * TODO: Implementar cuando se obtengan credenciales API de Zoom.
 * Por ahora usa el adaptador genérico como base.
 */
import type { CarrierAdapter, QuoteRequest, CreateShipmentRequest, ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig } from "./carrier.interface.js";
import crypto from "crypto";

export class ZoomCarrierAdapter implements CarrierAdapter {
  readonly code = "ZOOM";
  readonly name = "Zoom Envíos";
  readonly supportedCountries = ["VE", "CO", "EC", "PA"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  private get baseUrl(): string {
    return this.config.apiBaseUrl || "https://api.zoom.red";
  }

  private get headers(): Record<string, string> {
    return {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${this.config.apiKey || ""}`,
    };
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    // TODO: Integrar con API real de Zoom
    // POST /api/v1/rates
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);

    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "STANDARD", serviceName: "Zoom Estándar",
        price: Math.max(3.5, totalWeight * 1.2),
        currency: req.currency || "USD", estimatedDays: 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Zoom Express",
        price: Math.max(6, totalWeight * 2.0),
        currency: req.currency || "USD", estimatedDays: 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // TODO: Integrar con API real de Zoom
    // POST /api/v1/shipments
    const trackingNumber = "ZM-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://zoom.red/rastreo/${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    // TODO: GET /api/v1/tracking/{trackingNumber}
    if (!this.config.apiKey) return [];

    try {
      const res = await fetch(`${this.baseUrl}/api/v1/tracking/${trackingNumber}`, {
        headers: this.headers,
        signal: AbortSignal.timeout(10000),
      });
      if (!res.ok) return [];
      const data = await res.json() as any;
      return (data.events || []).map((e: any) => ({
        eventType: e.type || "UPDATE",
        status: e.status || "IN_TRANSIT",
        description: e.description || "",
        location: e.location || null,
        city: e.city || null,
        countryCode: e.countryCode || "VE",
        carrierEventCode: e.code || null,
        eventAt: e.timestamp || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    // TODO: DELETE /api/v1/shipments/{trackingNumber}
    return { ok: true, message: `Zoom envío ${trackingNumber} cancelado` };
  }

  async getLabel(trackingNumber: string) {
    // TODO: GET /api/v1/labels/{trackingNumber}
    return { url: `https://zoom.red/labels/${trackingNumber}.pdf` };
  }
}
