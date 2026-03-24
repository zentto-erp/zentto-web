/**
 * Generic Carrier Adapter — Para carriers manuales sin API.
 * Genera tracking numbers internos y permite actualización manual de estados.
 */
import type { CarrierAdapter, QuoteRequest, CreateShipmentRequest, ShippingRate, ShipmentLabel, TrackingEvent } from "./carrier.interface.js";
import crypto from "crypto";

export class GenericCarrierAdapter implements CarrierAdapter {
  readonly code = "GENERIC";
  readonly name = "Carrier Manual";
  readonly supportedCountries = ["*"];

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    // Carrier manual no cotiza — precio se ingresa manualmente
    return [{
      carrierCode: this.code,
      carrierName: this.name,
      serviceType: req.serviceType || "STANDARD",
      serviceName: "Envío manual",
      price: 0,
      currency: req.currency || "USD",
      estimatedDays: null,
      estimatedDelivery: null,
    }];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = "ZT-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: null,
    };
  }

  async track(_trackingNumber: string): Promise<TrackingEvent[]> {
    // Manual — tracking se maneja internamente via ShipmentEvent
    return [];
  }

  async cancel(_trackingNumber: string) {
    return { ok: true, message: "Envío cancelado (manual)" };
  }

  async getLabel(_trackingNumber: string) {
    return {};
  }
}
