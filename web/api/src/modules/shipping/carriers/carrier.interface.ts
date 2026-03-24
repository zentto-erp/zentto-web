/**
 * Zentto Shipping — Carrier Interface
 * Strategy pattern: cada carrier implementa esta interfaz.
 */

export interface ShippingRate {
  carrierCode: string;
  carrierName: string;
  serviceType: string;
  serviceName: string;
  price: number;
  currency: string;
  estimatedDays: number | null;
  estimatedDelivery: string | null;
}

export interface ShipmentLabel {
  trackingNumber: string;
  labelUrl: string | null;
  labelBase64: string | null;
  carrierTrackingUrl: string | null;
}

export interface TrackingEvent {
  eventType: string;
  status: string;
  description: string;
  location: string | null;
  city: string | null;
  countryCode: string | null;
  carrierEventCode: string | null;
  eventAt: string;
}

export interface QuoteRequest {
  originCity: string;
  originState?: string;
  originPostalCode?: string;
  originCountryCode: string;
  destCity: string;
  destState?: string;
  destPostalCode?: string;
  destCountryCode: string;
  packages: Array<{
    weight: number;
    weightUnit: string;
    length?: number;
    width?: number;
    height?: number;
    dimensionUnit: string;
    declaredValue?: number;
  }>;
  serviceType?: string;
  declaredValue?: number;
  currency?: string;
}

export interface CreateShipmentRequest extends QuoteRequest {
  originContactName: string;
  originPhone?: string;
  originAddress: string;
  destContactName: string;
  destPhone?: string;
  destAddress: string;
  description?: string;
  reference?: string;
}

export interface CarrierAdapter {
  readonly code: string;
  readonly name: string;
  readonly supportedCountries: string[];

  /** Obtener cotizaciones de envío */
  quote(req: QuoteRequest): Promise<ShippingRate[]>;

  /** Crear envío y obtener guía + tracking */
  createShipment(req: CreateShipmentRequest): Promise<ShipmentLabel>;

  /** Rastrear envío por tracking number */
  track(trackingNumber: string): Promise<TrackingEvent[]>;

  /** Cancelar envío */
  cancel(trackingNumber: string): Promise<{ ok: boolean; message: string }>;

  /** Obtener etiqueta (PDF/imagen) */
  getLabel(trackingNumber: string): Promise<{ url?: string; base64?: string }>;
}

export interface CarrierConfig {
  carrierConfigId: number;
  carrierCode: string;
  carrierName: string;
  carrierType: string;
  apiBaseUrl?: string;
  apiKey?: string;
  apiSecret?: string;
  accountNumber?: string;
  extraConfig?: Record<string, any>;
}
