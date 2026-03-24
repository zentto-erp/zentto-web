/**
 * Liberty Express Carrier Adapter — Integración con Liberty Express (Venezuela/Caribbean)
 * TODO: Implementar cuando se obtengan credenciales API de Liberty.
 */
import type { CarrierAdapter, QuoteRequest, CreateShipmentRequest, ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig } from "./carrier.interface.js";
import crypto from "crypto";

export class LibertyCarrierAdapter implements CarrierAdapter {
  readonly code = "LIBERTY";
  readonly name = "Liberty Express";
  readonly supportedCountries = ["VE", "CO", "PA", "DO", "CL", "US"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  private get baseUrl(): string {
    return this.config.apiBaseUrl || "https://api.libertyexpress.com";
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    // TODO: Integrar con API real de Liberty Express
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);
    const isIntl = req.originCountryCode !== req.destCountryCode;

    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "STANDARD", serviceName: "Liberty Estándar",
        price: isIntl ? Math.max(12, totalWeight * 4.5) : Math.max(3, totalWeight * 1.0),
        currency: req.currency || "USD", estimatedDays: isIntl ? 5 : 2, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Liberty Express",
        price: isIntl ? Math.max(20, totalWeight * 7) : Math.max(5, totalWeight * 1.8),
        currency: req.currency || "USD", estimatedDays: isIntl ? 2 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // TODO: Integrar con API real de Liberty
    const trackingNumber = "LBT-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.libertyexpress.com/Rastreo?guia=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    if (!this.config.apiKey) return [];

    try {
      const res = await fetch(`${this.baseUrl}/api/tracking/${trackingNumber}`, {
        headers: { "X-Api-Key": this.config.apiKey },
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
    return { ok: true, message: `Liberty envío ${trackingNumber} cancelado` };
  }

  async getLabel(trackingNumber: string) {
    return { url: `${this.baseUrl}/api/labels/${trackingNumber}` };
  }
}
