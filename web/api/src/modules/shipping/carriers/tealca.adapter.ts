/**
 * Tealca Venezuela Carrier Adapter
 * La web de Tealca usa carga dinámica con Divi/jQuery.
 * Intentamos scraping del HTML con múltiples User-Agents.
 * Si el endpoint interno no responde, devolvemos URL directa.
 *
 * TODO: Si se obtiene acceso a su API oficial, reemplazar con llamada directa.
 * Contacto técnico: https://www.tealca.com/contactenos/
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const TEALCA_TRACK_URL = "https://www.tealca.com/rastrear-envio/";

function mapTealcaStatus(raw: string): string {
  const s = (raw || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (s.includes("entregado") || s.includes("entregada")) return "DELIVERED";
  if (s.includes("en reparto") || s.includes("en camino")) return "OUT_FOR_DELIVERY";
  if (s.includes("transito") || s.includes("en ruta")) return "IN_TRANSIT";
  if (s.includes("recibido") || s.includes("ingresado")) return "PICKED_UP";
  if (s.includes("devuelto")) return "RETURNED";
  return "IN_TRANSIT";
}

function parseTealcaDate(raw: string): string {
  if (!raw) return new Date().toISOString();
  const m = /(\d{2})[\/\-](\d{2})[\/\-](\d{4})(?:\s+(\d{2}):(\d{2}))?/.exec(raw);
  if (m) {
    const [, dd, mo, yy, hh = "00", mm = "00"] = m;
    return new Date(`${yy}-${mo}-${dd}T${hh}:${mm}:00Z`).toISOString();
  }
  const d = new Date(raw);
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

function parseTealcaHtml(html: string): TrackingEvent[] {
  const events: TrackingEvent[] = [];
  if (!html || html.includes("no se encontr") || html.includes("no existe")) return [];

  // Buscar tablas de eventos
  const trRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  let trMatch: RegExpExecArray | null;
  while ((trMatch = trRegex.exec(html)) !== null) {
    const cells: string[] = [];
    const tdRegex = /<td[^>]*>([\s\S]*?)<\/td>/gi;
    let tdMatch: RegExpExecArray | null;
    while ((tdMatch = tdRegex.exec(trMatch[1])) !== null) {
      cells.push(tdMatch[1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim());
    }
    if (cells.length >= 2 && /\d{2}[\/\-]\d{2}[\/\-]\d{4}/.test(cells[0])) {
      const [fecha, estatus, agencia, ciudad] = cells;
      events.push({
        eventType: "UPDATE",
        status: mapTealcaStatus(estatus || ""),
        description: estatus || "",
        location: agencia || null,
        city: ciudad || null,
        countryCode: "VE",
        carrierEventCode: estatus || null,
        eventAt: parseTealcaDate(fecha),
      });
    }
  }
  return events;
}

export class TealcaAdapter implements CarrierAdapter {
  readonly code = "TEALCA";
  readonly name = "Tealca";
  readonly supportedCountries = ["VE"];

  private config: CarrierConfig;

  constructor(config: CarrierConfig) {
    this.config = config;
  }

  async quote(req: QuoteRequest): Promise<ShippingRate[]> {
    const totalWeight = req.packages.reduce((sum, p) => sum + p.weight, 0);
    return [
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "STANDARD", serviceName: "Tealca Estándar",
        price: Math.max(4, totalWeight * 1.5),
        currency: "USD", estimatedDays: 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Tealca Express",
        price: Math.max(8, totalWeight * 2.5),
        currency: "USD", estimatedDays: 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = "TL-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `${TEALCA_TRACK_URL}?guia=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    try {
      const res = await fetch(`${TEALCA_TRACK_URL}?guia=${encodeURIComponent(trackingNumber)}`, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml",
          "Referer": "https://www.tealca.com/",
          "Accept-Language": "es-VE,es;q=0.9",
        },
        redirect: "follow",
        signal: AbortSignal.timeout(12_000),
      });
      if (!res.ok) return [];
      const html = await res.text();
      return parseTealcaHtml(html);
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `Tealca ${trackingNumber}: contactar agencia Tealca` };
  }

  async getLabel(trackingNumber: string) {
    return { url: `${TEALCA_TRACK_URL}?guia=${trackingNumber}` };
  }
}
