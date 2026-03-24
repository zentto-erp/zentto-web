/**
 * Zoom Venezuela Carrier Adapter
 * Tracking: GET https://zoom.red/tracking-de-envios-personas/?nro-guia=XXX&tipo-consulta=1
 * La página es WordPress con plugin mmg-zoom-api. Devuelve HTML con el resultado.
 * El Turnstile (Cloudflare) solo se valida si el parámetro está presente en la request.
 * Desde Node.js server-side no hay desafío de browser, por lo que la llamada
 * sin token puede funcionar dependiendo de la config del plugin WP.
 *
 * Fallback: si Zoom bloquea la request, retornar carrierTrackingUrl para
 * que el usuario rastree directamente en zoom.red
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const ZOOM_TRACK_PAGE = "https://zoom.red/tracking-de-envios-personas/";

// Mapeo de estatus Zoom → estado interno
function mapZoomStatus(raw: string): string {
  const s = (raw || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (s.includes("entregado") || s.includes("entregada")) return "DELIVERED";
  if (s.includes("en camino") || s.includes("salida") || s.includes("proceso")) return "OUT_FOR_DELIVERY";
  if (s.includes("recibido") || s.includes("ingres") || s.includes("generado")) return "PICKED_UP";
  if (s.includes("transito") || s.includes("traslado") || s.includes("oficina")) return "IN_TRANSIT";
  if (s.includes("devuelto") || s.includes("retorno")) return "RETURNED";
  if (s.includes("excepcion") || s.includes("incidencia")) return "EXCEPTION";
  return "IN_TRANSIT";
}

/**
 * Parsea eventos de tracking desde el HTML de zoom.red.
 * El plugin mmg-zoom-api genera bloques con:
 *   .zappi-trk-container / .zapi-container → contenedor raíz
 *   .zapi-evento-item o tabla de eventos
 * Usa regex resiliente para extraer fecha, estatus, agencia/ubicación.
 */
function parseZoomHtml(html: string): TrackingEvent[] {
  const events: TrackingEvent[] = [];

  // Verificar si hay un bloque de error (Turnstile bloqueó o guía inválida)
  if (
    html.includes("err-mensaje") ||
    html.includes("No se pudo validar la identidad") ||
    html.includes("no es válido o no existe")
  ) {
    return [];
  }

  // Detectar si la guía fue encontrada
  if (!html.includes("zappi-trk") && !html.includes("zapi-")) {
    return [];
  }

  // Intentar extraer eventos de tabla HTML o divs de timeline
  // Patrón típico del plugin: <td>FECHA</td><td>ESTATUS</td><td>AGENCIA</td>
  const tableRowRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  const cellRegex = /<td[^>]*>([\s\S]*?)<\/td>/gi;
  let rowMatch: RegExpExecArray | null;

  while ((rowMatch = tableRowRegex.exec(html)) !== null) {
    const rowHtml = rowMatch[1];
    const cells: string[] = [];
    let cellMatch: RegExpExecArray | null;
    const localCellRegex = /<td[^>]*>([\s\S]*?)<\/td>/gi;
    while ((cellMatch = localCellRegex.exec(rowHtml)) !== null) {
      cells.push(stripHtml(cellMatch[1]).trim());
    }
    if (cells.length >= 2 && looksLikeDate(cells[0])) {
      const [rawDate, rawStatus, rawAgencia, rawEstado] = cells;
      events.push({
        eventType: "UPDATE",
        status: mapZoomStatus(rawStatus || ""),
        description: rawStatus || "",
        location: rawAgencia || null,
        city: rawEstado || null,
        countryCode: "VE",
        carrierEventCode: rawStatus || null,
        eventAt: parseZoomDate(rawDate),
      });
    }
  }

  if (events.length > 0) return events;

  // Patrón alternativo: divs con clases del plugin
  // <div class="zapi-fecha">16/10/2025 15:26 HS</div>
  // <div class="zapi-estatus">ENTREGADO</div>
  // <div class="zapi-agencia">ANACO</div>
  const blockRegex = /class="[^"]*zapi-evento[^"]*"[^>]*>([\s\S]*?)(?=class="[^"]*zapi-evento|<\/div>\s*<\/div>)/gi;
  let blockMatch: RegExpExecArray | null;
  while ((blockMatch = blockRegex.exec(html)) !== null) {
    const block = blockMatch[1];
    const fecha = extractField(block, ["zapi-fecha", "fecha_scan", "date"]);
    const estatus = extractField(block, ["zapi-estatus", "estatus", "status"]);
    const agencia = extractField(block, ["zapi-agencia", "agencia", "location"]);
    const estado = extractField(block, ["zapi-estado", "estado", "city"]);
    if (estatus) {
      events.push({
        eventType: "UPDATE",
        status: mapZoomStatus(estatus),
        description: estatus,
        location: agencia || null,
        city: estado || null,
        countryCode: "VE",
        carrierEventCode: estatus,
        eventAt: parseZoomDate(fecha || ""),
      });
    }
  }

  return events;
}

function extractField(html: string, classNames: string[]): string {
  for (const cls of classNames) {
    const re = new RegExp(`class="[^"]*${cls}[^"]*"[^>]*>([\s\S]*?)<\/`, "i");
    const m = re.exec(html);
    if (m) return stripHtml(m[1]).trim();
  }
  return "";
}

function stripHtml(s: string): string {
  return s.replace(/<[^>]+>/g, " ").replace(/&amp;/g, "&").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
}

function looksLikeDate(s: string): boolean {
  return /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/.test(s);
}

function parseZoomDate(raw: string): string {
  if (!raw) return new Date().toISOString();
  // "16/10/2025 15:26 HS" o "16/10/2025"
  const m = /(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2}))?/.exec(raw);
  if (m) {
    const [, dd, mo, yy, hh = "00", mm = "00"] = m;
    return new Date(`${yy}-${mo}-${dd}T${hh}:${mm}:00Z`).toISOString();
  }
  const d = new Date(raw);
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

export class ZoomCarrierAdapter implements CarrierAdapter {
  readonly code = "ZOOM";
  readonly name = "Zoom Envíos";
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
        serviceType: "STANDARD", serviceName: "Zoom Estándar",
        price: Math.max(3.5, totalWeight * 1.2),
        currency: "USD", estimatedDays: 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "Zoom Express",
        price: Math.max(6, totalWeight * 2.0),
        currency: "USD", estimatedDays: 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // TODO: API real cuando Zoom habilite endpoint de creación
    const trackingNumber = "ZM-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `${ZOOM_TRACK_PAGE}?nro-guia=${trackingNumber}&tipo-consulta=1`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    const url = `${ZOOM_TRACK_PAGE}?nro-guia=${encodeURIComponent(trackingNumber)}&tipo-consulta=1`;
    try {
      // Llamada server-side: sin navegador no hay desafío Turnstile de Cloudflare.
      // El plugin WP mmg-zoom-api valida el token SOLO si está presente en $_GET.
      // Desde Node.js no se envía el parámetro → el plugin puede omitir la validación.
      const res = await fetch(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language": "es-VE,es;q=0.9",
          "Cache-Control": "no-cache",
          "Referer": "https://zoom.red/",
        },
        redirect: "follow",
        signal: AbortSignal.timeout(15_000),
      });

      if (!res.ok) return [];

      const html = await res.text();
      return parseZoomHtml(html);
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `Zoom ${trackingNumber}: contactar soporte en zoom.red` };
  }

  async getLabel(trackingNumber: string) {
    return {
      url: `${ZOOM_TRACK_PAGE}?nro-guia=${trackingNumber}&tipo-consulta=1`,
    };
  }
}
