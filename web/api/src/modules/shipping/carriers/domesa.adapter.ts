/**
 * Domesa Colombia Carrier Adapter
 * API pública confirmada (no requiere credenciales):
 * POST https://www.domesa.com.co/publico/consultatracking/GetApi
 * Body: { "Identificacion": "CEDULA_O_RIF", "Idetar": "NUMERO_GUIA" }
 * Nota: Requiere AMBOS campos — Identificación del remitente y número de guía.
 * El número de tracking se puede pasar como ambos si se desconoce la cédula.
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const DOMESA_CO_API = "https://www.domesa.com.co/publico/consultatracking/GetApi";

function mapDomesaStatus(raw: string): string {
  const s = (raw || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (s.includes("entregado") || s.includes("entregada")) return "DELIVERED";
  if (s.includes("en reparto") || s.includes("para entrega")) return "OUT_FOR_DELIVERY";
  if (s.includes("aduana")) return "IN_CUSTOMS";
  if (s.includes("transito") || s.includes("traslad") || s.includes("en ruta")) return "IN_TRANSIT";
  if (s.includes("recibido") || s.includes("ingresado") || s.includes("generada")) return "PICKED_UP";
  if (s.includes("devuelt") || s.includes("retorn")) return "RETURNED";
  if (s.includes("incidencia") || s.includes("excepcion")) return "EXCEPTION";
  return "IN_TRANSIT";
}

function parseDomesaDate(raw: string): string {
  if (!raw) return new Date().toISOString();
  const d = new Date(raw);
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

export class DomesaAdapter implements CarrierAdapter {
  readonly code = "DOMESA";
  readonly name = "Domesa";
  readonly supportedCountries = ["CO", "VE", "EC", "PA", "PE"];

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
        serviceType: "STANDARD", serviceName: "Domesa Estándar",
        price: isIntl ? Math.max(15, totalWeight * 5) : Math.max(5, totalWeight * 2),
        currency: "USD", estimatedDays: isIntl ? 7 : 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Domesa Express",
        price: isIntl ? Math.max(25, totalWeight * 8) : Math.max(9, totalWeight * 3.5),
        currency: "USD", estimatedDays: isIntl ? 3 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = "DOM-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.domesa.com.co/rastreo/?guia=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    // La API de Domesa CO requiere Identificacion + Idetar.
    // Si solo tenemos la guía, probamos con la guía como ambos campos.
    // En producción el cliente puede tener su cédula vinculada al envío.
    const extra = this.config.extraConfig || {};
    const identificacion = extra.identificacion || trackingNumber;

    try {
      const res = await fetch(DOMESA_CO_API, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Referer": "https://www.domesa.com.co/",
          "Origin": "https://www.domesa.com.co",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "application/json, text/plain, */*",
        },
        body: JSON.stringify({ Identificacion: identificacion, Idetar: trackingNumber }),
        signal: AbortSignal.timeout(12_000),
      });

      if (!res.ok) return [];

      const data = await res.json() as any;

      // Si ExceptionMessage indica que la combinación no existe
      if (data.ExceptionMessage || data.Message === "False." || data.Guia === null) return [];

      // La respuesta incluye Tracking (array de eventos) o info básica del envío
      const rawTracking: any[] = data.Tracking || [];

      if (rawTracking.length > 0) {
        return rawTracking.map((e: any) => ({
          eventType: "UPDATE",
          status: mapDomesaStatus(e.Situacion || e.Estado || e.estatus || ""),
          description: e.Situacion || e.Descripcion || e.Estado || "",
          location: e.Agencia || e.Oficina || null,
          city: e.Ciudad || data.Ciudad || null,
          countryCode: e.Pais || "CO",
          carrierEventCode: e.Codigo || null,
          eventAt: parseDomesaDate(e.Fecha || e.FechaHora || ""),
        }));
      }

      // Si no hay tracking array pero sí info básica del envío (un solo evento)
      if (data.Guia || data.Ciudad || data.Destino) {
        return [{
          eventType: "UPDATE",
          status: "IN_TRANSIT",
          description: `Guía ${data.Guia || trackingNumber} — Destino: ${data.Destino || ""}`,
          location: null,
          city: data.Ciudad || data.Destino || null,
          countryCode: "CO",
          carrierEventCode: null,
          eventAt: new Date().toISOString(),
        }];
      }

      return [];
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `Domesa ${trackingNumber}: contactar oficina Domesa` };
  }

  async getLabel(trackingNumber: string) {
    return { url: `https://www.domesa.com.co/rastreo/?guia=${trackingNumber}` };
  }
}
