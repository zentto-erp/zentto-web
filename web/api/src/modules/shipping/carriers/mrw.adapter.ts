/**
 * MRW Carrier Adapter — Integración con API de MRW (España/LATAM)
 * TODO: Implementar cuando se obtengan credenciales API de MRW.
 */
import type { CarrierAdapter, QuoteRequest, CreateShipmentRequest, ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig } from "./carrier.interface.js";
import crypto from "crypto";

export class MrwCarrierAdapter implements CarrierAdapter {
  readonly code = "MRW";
  readonly name = "MRW";
  readonly supportedCountries = ["ES", "PT", "VE", "CO", "MX"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  private get baseUrl(): string {
    return this.config.apiBaseUrl || "https://api.mrw.es";
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    // TODO: Integrar con API real de MRW
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);
    const isIntl = req.originCountryCode !== req.destCountryCode;

    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "STANDARD", serviceName: "MRW Económico",
        price: isIntl ? Math.max(15, totalWeight * 5) : Math.max(4, totalWeight * 1.5),
        currency: req.currency || "EUR", estimatedDays: isIntl ? 7 : 2, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "MRW Urgente",
        price: isIntl ? Math.max(25, totalWeight * 8) : Math.max(7, totalWeight * 2.5),
        currency: req.currency || "EUR", estimatedDays: isIntl ? 3 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // TODO: Integrar con API real de MRW — SOAP/REST endpoint
    const trackingNumber = "MRW-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp?enviession=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    // TODO: Integrar con API real de MRW tracking
    if (!this.config.apiKey) return [];

    try {
      const res = await fetch(`${this.baseUrl}/v1/tracking/${trackingNumber}`, {
        headers: { "Authorization": `Bearer ${this.config.apiKey}` },
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
        countryCode: e.countryCode || "ES",
        carrierEventCode: e.code || null,
        eventAt: e.timestamp || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `MRW envío ${trackingNumber} cancelado` };
  }

  async getLabel(trackingNumber: string) {
    return { url: `${this.baseUrl}/v1/labels/${trackingNumber}` };
  }
}
