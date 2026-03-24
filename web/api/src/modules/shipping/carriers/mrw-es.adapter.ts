/**
 * MRW España Carrier Adapter
 * Tracking: POST https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp
 * Body: application/x-www-form-urlencoded  envio=TRACKINGNUM&btnBuscar=Buscar
 * Respuesta: HTML server-side (ASP clásico) — se parsea con regex.
 * Sin CAPTCHA ni autenticación. Solo requiere Referer + User-Agent.
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const MRW_ES_TRACK_URL = "https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp";

function mapMrwEsStatus(raw: string): string {
  const s = (raw || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (s.includes("entregado") || s.includes("entregada")) return "DELIVERED";
  if (s.includes("reparto") || s.includes("repartidor")) return "OUT_FOR_DELIVERY";
  if (s.includes("aduana") || s.includes("detenido")) return "IN_CUSTOMS";
  if (s.includes("transito") || s.includes("transporte") || s.includes("clasificado")) return "IN_TRANSIT";
  if (s.includes("recogida") || s.includes("recogido") || s.includes("entrada")) return "PICKED_UP";
  if (s.includes("devuelto") || s.includes("retorno")) return "RETURNED";
  if (s.includes("incidencia") || s.includes("problema")) return "EXCEPTION";
  return "IN_TRANSIT";
}

function parseMrwEsDate(raw: string): string {
  if (!raw) return new Date().toISOString();
  // "16/03/2025 10:30" o "16-03-2025"
  const m = /(\d{2})[\/\-](\d{2})[\/\-](\d{4})(?:\s+(\d{2}):(\d{2}))?/.exec(raw);
  if (m) {
    const [, dd, mo, yy, hh = "00", mm = "00"] = m;
    return new Date(`${yy}-${mo}-${dd}T${hh}:${mm}:00Z`).toISOString();
  }
  const d = new Date(raw);
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

/**
 * Parsea la tabla de eventos de tracking del HTML de MRW España.
 * La página ASP genera una tabla con columnas: Fecha | Hora | Situación | Agencia | Comentarios
 */
function parseMrwEsHtml(html: string): TrackingEvent[] {
  const events: TrackingEvent[] = [];

  // Si la página dice "no encontrado" o "no existe"
  if (
    html.includes("no existe") ||
    html.includes("No se ha encontrado") ||
    html.includes("envio no encontrado")
  ) return [];

  // Buscar filas de tabla: <tr> con al menos 4 <td>
  const trRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  let trMatch: RegExpExecArray | null;

  while ((trMatch = trRegex.exec(html)) !== null) {
    const rowHtml = trMatch[1];
    // Extraer celdas
    const cells: string[] = [];
    const tdRegex = /<td[^>]*>([\s\S]*?)<\/td>/gi;
    let tdMatch: RegExpExecArray | null;
    while ((tdMatch = tdRegex.exec(rowHtml)) !== null) {
      cells.push(stripHtml(tdMatch[1]).trim());
    }

    // MRW ES: [fecha, hora, situacion, agencia, comentarios] — al menos 3 cols con fecha
    if (cells.length >= 3 && /\d{2}[\/\-]\d{2}[\/\-]\d{4}/.test(cells[0])) {
      const [fecha, hora, situacion, agencia, comentarios] = cells;
      const fechaHora = hora ? `${fecha} ${hora}` : fecha;
      events.push({
        eventType: "UPDATE",
        status: mapMrwEsStatus(situacion || ""),
        description: [situacion, comentarios].filter(Boolean).join(" — "),
        location: agencia || null,
        city: extractCity(agencia || ""),
        countryCode: "ES",
        carrierEventCode: situacion || null,
        eventAt: parseMrwEsDate(fechaHora),
      });
    }
  }

  return events;
}

function extractCity(agency: string): string | null {
  // Agencia suele contener ciudad: "MRW MADRID CENTRO" → "MADRID"
  if (!agency) return null;
  const parts = agency.split(/\s+/);
  // Quitar "MRW" del inicio y tomar el resto como ciudad
  const filtered = parts.filter((p) => p !== "MRW" && p.length > 2);
  return filtered.length > 0 ? filtered[0] : null;
}

function stripHtml(s: string): string {
  return s.replace(/<[^>]+>/g, " ").replace(/&amp;/g, "&").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
}

export class MrwEsAdapter implements CarrierAdapter {
  readonly code = "MRW_ES";
  readonly name = "MRW España";
  readonly supportedCountries = ["ES", "PT", "AD"];

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
        serviceType: "STANDARD", serviceName: "MRW Económico",
        price: isIntl ? Math.max(12, totalWeight * 4) : Math.max(4, totalWeight * 1.5),
        currency: "EUR", estimatedDays: isIntl ? 5 : 2, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "MRW Urgente 10",
        price: isIntl ? Math.max(20, totalWeight * 7) : Math.max(7, totalWeight * 2.5),
        currency: "EUR", estimatedDays: isIntl ? 3 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    const trackingNumber = crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp?envio=${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    try {
      const body = new URLSearchParams({ envio: trackingNumber, btnBuscar: "Buscar" });
      const res = await fetch(MRW_ES_TRACK_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Referer": "https://www.mrw.es/seguimiento_envios/",
          "Origin": "https://www.mrw.es",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
          "Accept-Language": "es-ES,es;q=0.9",
        },
        body: body.toString(),
        redirect: "follow",
        signal: AbortSignal.timeout(12_000),
      });

      if (!res.ok) return [];
      const html = await res.text();
      return parseMrwEsHtml(html);
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `MRW ES ${trackingNumber}: contactar agencia MRW España` };
  }

  async getLabel(trackingNumber: string) {
    return {
      url: `https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp?envio=${trackingNumber}`,
    };
  }
}
