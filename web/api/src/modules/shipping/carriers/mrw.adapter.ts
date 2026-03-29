/**
 * MRW Venezuela Carrier Adapter
 * API: POST https://mrwve.com/api/tracking  { nro_tracking: "..." }
 * Respuesta: JSON con objeto tracking{} cuando el sistema está operativo.
 * Si el sistema está en mantenimiento devuelve { codigo: "03", error: "..." }
 */
import type {
  CarrierAdapter, QuoteRequest, CreateShipmentRequest,
  ShippingRate, ShipmentLabel, TrackingEvent, CarrierConfig,
} from "./carrier.interface.js";
import crypto from "crypto";

const MRW_TRACKING_URL = "https://mrwve.com/api/tracking";
const MRW_PUBLIC_TRACK = "https://www.mrwve.com/rastreo/"; // fallback link

// Mapeo de estatus MRW → estado interno Zentto
function mapMrwStatus(estatus: string): string {
  const s = (estatus || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (s.includes("entregado")) return "DELIVERED";
  if (s.includes("entrada") || s.includes("generado")) return "PICKED_UP";
  if (s.includes("disponible")) return "IN_TRANSIT";
  if (s.includes("salida")) return "IN_TRANSIT";
  if (s.includes("transito") || s.includes("transito")) return "IN_TRANSIT";
  if (s.includes("pedido") || s.includes("por entregar") || s.includes("asignaci")) return "OUT_FOR_DELIVERY";
  if (s.includes("monitoreo") || s.includes("operaciones")) return "IN_TRANSIT";
  if (s.includes("devuelto") || s.includes("retorno")) return "RETURNED";
  if (s.includes("excepcion") || s.includes("incidencia")) return "EXCEPTION";
  return "IN_TRANSIT";
}

function parseMrwDate(e: Record<string, any>): string {
  const raw = e.fecha_scan || e.fecha || e.fecha_hora || e.fecha_hora_string;
  if (!raw) return new Date().toISOString();
  // Intentar parsear fecha dd/mm/yyyy HH:MM o ISO
  const ddmm = /^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2}))?/;
  const m = ddmm.exec(String(raw));
  if (m) {
    const [, dd, mo, yy, hh = "00", mm = "00"] = m;
    return new Date(`${yy}-${mo}-${dd}T${hh}:${mm}:00Z`).toISOString();
  }
  const d = new Date(raw);
  return isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

export class MrwCarrierAdapter implements CarrierAdapter {
  readonly code = "MRW";
  readonly name = "MRW Venezuela";
  readonly supportedCountries = ["VE"];

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
        price: isIntl ? Math.max(15, totalWeight * 5) : Math.max(4, totalWeight * 1.5),
        currency: "USD", estimatedDays: isIntl ? 7 : 3, estimatedDelivery: null,
      },
      {
        carrierCode: this.code, carrierName: this.name,
        serviceType: "EXPRESS", serviceName: "MRW Urgente",
        price: isIntl ? Math.max(25, totalWeight * 8) : Math.max(7, totalWeight * 2.5),
        currency: "USD", estimatedDays: isIntl ? 3 : 1, estimatedDelivery: null,
      },
    ];
  }

  async createShipment(_req: CreateShipmentRequest): Promise<ShipmentLabel> {
    // TODO: API real cuando MRW habilite endpoint de creación
    const trackingNumber = "MRW-" + crypto.randomBytes(6).toString("hex").toUpperCase();
    return {
      trackingNumber,
      labelUrl: null,
      labelBase64: null,
      carrierTrackingUrl: `${MRW_PUBLIC_TRACK}${trackingNumber}`,
    };
  }

  async track(trackingNumber: string): Promise<TrackingEvent[]> {
    try {
      const res = await fetch(MRW_TRACKING_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Referer": "https://www.mrwve.com/",
          "Origin": "https://www.mrwve.com",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        },
        body: JSON.stringify({ nro_tracking: trackingNumber }),
        signal: AbortSignal.timeout(12_000),
      });

      if (!res.ok) return [];

      const data = await res.json() as any;

      // Sistema en mantenimiento u error
      if (data.codigo) return [];

      const rawEvents = data.tracking ? Object.values(data.tracking) : [];
      if (rawEvents.length === 0) return [];

      return (rawEvents as Record<string, any>[]).map((e) => ({
        eventType: "UPDATE",
        status: mapMrwStatus(e.estatus),
        description: [e.estatus, e.observacion || e.mensaje || e.descripcion].filter(Boolean).join(" — "),
        location: e.agencia || null,
        city: e.estado || null,
        countryCode: "VE",
        carrierEventCode: e.estatus || null,
        eventAt: parseMrwDate(e),
      }));
    } catch {
      return [];
    }
  }

  async cancel(trackingNumber: string) {
    return { ok: true, message: `MRW ${trackingNumber}: solicitar cancelación vía WhatsApp MRW` };
  }

  async getLabel(trackingNumber: string) {
    return { url: `${MRW_PUBLIC_TRACK}${trackingNumber}` };
  }
}
