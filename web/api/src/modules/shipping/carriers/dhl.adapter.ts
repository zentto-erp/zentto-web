/**
 * DHL Express Global Adapter
 * API oficial con demo-key gratuita (250 llamadas/día):
 * GET https://api-eu.dhl.com/track/shipments?trackingNumber={TRACKING}
 * Header: DHL-API-Key: demo-key  (o clave real desde env/BD)
 *
 * Para producción: registrarse en developer.dhl.com → API key gratuita 250/día.
 * La clave se almacena en CarrierConfig.apiKey o env CARRIER_DHL_API_KEY.
 *
 * Cobertura: Global (VE, ES, CO, MX, US, + 220 países)
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const DHL_TRACK_API = "https://api-eu.dhl.com/track/shipments";

function mapDhlStatus(code: string, desc: string): string {
  const c = (code || "").toUpperCase();
  const d = (desc || "").toLowerCase();
  if (c === "DELIVERED" || d.includes("entregado") || d.includes("delivered")) return "DELIVERED";
  if (c === "OUT-FOR-DELIVERY" || d.includes("reparto") || d.includes("out for delivery")) return "OUT_FOR_DELIVERY";
  if (c === "IN-CUSTOMS" || d.includes("aduana") || d.includes("customs")) return "IN_CUSTOMS";
  if (c === "TRANSIT" || d.includes("transito") || d.includes("in transit")) return "IN_TRANSIT";
  if (c === "PICKUP" || d.includes("recogido") || d.includes("picked up")) return "PICKED_UP";
  if (c === "RETURNED" || d.includes("devuelto")) return "RETURNED";
  if (c === "EXCEPTION" || d.includes("excepcion") || d.includes("exception")) return "EXCEPTION";
  return "IN_TRANSIT";
}

export class DhlAdapter implements CarrierAdapter {
  readonly code = "DHL";
  readonly name = "DHL Express";
  readonly supportedCountries = ["*"]; // global

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  private get apiKey(): string {
    return this.config.apiKey ||
      process.env.CARRIER_DHL_API_KEY ||
      "demo-key"; // demo-key = 250 llamadas/día gratis
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);
    const isIntl = req.originCountryCode !== req.destCountryCode;
    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "DHL Express Worldwide",
        price: isIntl ? Math.max(25, totalWeight * 8) : Math.max(12, totalWeight * 4),
        currency: "USD", estimatedDays: isIntl ? 3 : 1, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "ECONOMY", serviceName: "DHL Economy Select",
        price: isIntl ? Math.max(15, totalWeight * 5) : Math.max(8, totalWeight * 3),
        currency: "USD", estimatedDays: isIntl ? 7 : 3, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // DHL requiere cuenta comercial para crear guías — usar API oficial con credenciales
    const trackingNumber = crypto.randomBytes(10).toString("hex").toUpperCase().slice(0, 10);
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.dhl.com/es-es/home/tracking/tracking-express.html?submit=1&tracking-id=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    try {
      const url = `${DHL_TRACK_API}?trackingNumber=${encodeURIComponent(trackingNumber)}`;
      const res = await fetch(url, {
        headers: {
          "DHL-API-Key": this.apiKey,
          "Accept": "application/json",
          "User-Agent": "Mozilla/5.0 Zentto/1.0",
        },
        signal: AbortSignal.timeout(12_000),
      });

      if (!res.ok) return [];

      const data = await res.json() as any;
      const shipments: any[] = data.shipments || [];
      if (shipments.length === 0) return [];

      const shipment = shipments[0];
      const rawEvents: any[] = shipment.events || [];

      return rawEvents.map((e: any) => ({
        eventType: "UPDATE",
        status: mapDhlStatus(e.typeCode || "", e.description || ""),
        description: e.description || e.typeCode || "",
        location: e.location?.address?.addressLocality || null,
        city: e.location?.address?.addressLocality || null,
        countryCode: e.location?.address?.countryCode || null,
        carrierEventCode: e.typeCode || null,
        eventAt: e.timestamp || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `DHL ${trackingNumber}: contactar DHL Express para cancelación` };
  }

  async getLabel(trackingNumber: string) {
    return {
      url: `https://www.dhl.com/es-es/home/tracking/tracking-express.html?submit=1&tracking-id=${trackingNumber}`,
    };
  }
}
