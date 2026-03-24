/**
 * Zentto Shipping — Service Layer
 * Portal de paquetería para clientes finales.
 */
import { callSp, callSpOut } from "../../db/query.js";
import { signJwt } from "../../auth/jwt.js";
import { getActiveScope } from "../_shared/scope.js";
import { emitBusinessNotification, syncContact, notifyEmail } from "../_shared/notify.js";
import { getCarrierAdapter, getAllAdapters, detectCarrierCandidates } from "./carriers/index.js";
import type { CarrierConfig, QuoteRequest } from "./carriers/carrier.interface.js";
import bcrypt from "bcryptjs";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1 };
}

// ─── Auth ────────────────────────────────────────────────────

interface ShippingCustomerRow {
  ShippingCustomerId: number;
  CompanyId: number;
  Email: string;
  PasswordHash: string;
  DisplayName: string;
  Phone: string | null;
  FiscalId: string | null;
  CompanyName: string | null;
  CountryCode: string | null;
  PreferredLanguage: string;
  IsActive: boolean;
  IsEmailVerified: boolean;
  LastLoginAt: string | null;
}

export async function registerCustomer(data: {
  email: string;
  password: string;
  displayName: string;
  phone?: string;
  fiscalId?: string;
  companyName?: string;
  countryCode?: string;
}) {
  const hash = await bcrypt.hash(data.password, 10);

  const { output } = await callSpOut(
    "usp_Shipping_Customer_Register",
    {
      CompanyId: scope().companyId,
      Email: data.email.toLowerCase().trim(),
      PasswordHash: hash,
      DisplayName: data.displayName,
      Phone: data.phone || null,
      FiscalId: data.fiscalId || null,
      CompanyName: data.companyName || null,
      CountryCode: data.countryCode || null,
    },
    { Resultado: "int", Mensaje: "string" }
  );

  if (output.Resultado !== 1) {
    return { ok: false, error: output.Mensaje || "Error al registrar" };
  }

  // Sync contact + welcome notification
  const email = data.email.toLowerCase().trim();
  syncContact({ email, name: data.displayName, tags: ["shipping"] }).catch(() => {});
  emitBusinessNotification({
    event: "CUSTOMER_REGISTERED",
    to: email,
    subject: "Bienvenido a Zentto Shipping",
    data: { Nombre: data.displayName, Email: email },
  }).catch(() => {});

  return { ok: true };
}

export async function loginCustomer(email: string, password: string) {
  const rows = await callSp<ShippingCustomerRow>(
    "usp_Shipping_Customer_Login",
    { Email: email.toLowerCase().trim() }
  );

  const user = rows[0];
  if (!user) return { ok: false, error: "Credenciales inválidas" };
  if (!user.IsActive) return { ok: false, error: "Cuenta desactivada" };

  const valid = await bcrypt.compare(password, user.PasswordHash);
  if (!valid) return { ok: false, error: "Credenciales inválidas" };

  const token = signJwt({
    userId: user.ShippingCustomerId,
    email: user.Email,
    displayName: user.DisplayName,
    role: "shipping_customer",
    companyAccess: [{ companyId: user.CompanyId, branchIds: [], role: "shipping_customer" }],
  } as any);

  return {
    ok: true,
    token,
    customer: {
      id: user.ShippingCustomerId,
      name: user.DisplayName,
      email: user.Email,
      phone: user.Phone,
      companyName: user.CompanyName,
      countryCode: user.CountryCode,
    },
  };
}

export async function getCustomerProfile(customerId: number) {
  const rows = await callSp<ShippingCustomerRow>("usp_Shipping_Customer_Profile", {
    ShippingCustomerId: customerId,
  });
  return rows[0] || null;
}

// ─── Addresses ───────────────────────────────────────────────

export async function listAddresses(customerId: number) {
  return callSp("usp_Shipping_Address_List", { ShippingCustomerId: customerId });
}

export async function upsertAddress(customerId: number, data: any) {
  const { output } = await callSpOut(
    "usp_Shipping_Address_Upsert",
    {
      ShippingAddressId: data.shippingAddressId || null,
      ShippingCustomerId: customerId,
      Label: data.label || "Principal",
      ContactName: data.contactName,
      Phone: data.phone || null,
      AddressLine1: data.addressLine1,
      AddressLine2: data.addressLine2 || null,
      City: data.city,
      State: data.state || null,
      PostalCode: data.postalCode || null,
      CountryCode: data.countryCode || "VE",
      IsDefault: data.isDefault ? 1 : 0,
    },
    { Resultado: "int", Mensaje: "string" }
  );
  return { ok: output.Resultado === 1, message: output.Mensaje };
}

// ─── Carriers ────────────────────────────────────────────────

export async function listCarriers() {
  return callSp("usp_Shipping_CarrierConfig_List", { CompanyId: scope().companyId });
}

async function getCarrierConfigs(): Promise<CarrierConfig[]> {
  const rows = await callSp<any>("usp_Shipping_CarrierConfig_List", { CompanyId: scope().companyId });
  return rows.map((r: any) => ({
    carrierConfigId: r.CarrierConfigId,
    carrierCode: r.CarrierCode,
    carrierName: r.CarrierName,
    carrierType: r.CarrierType,
    apiBaseUrl: r.ApiBaseUrl,
    apiKey: r.ApiKey,
    apiSecret: r.ApiSecret,
    accountNumber: r.AccountNumber,
    extraConfig: r.ExtraConfig ? (typeof r.ExtraConfig === "string" ? JSON.parse(r.ExtraConfig) : r.ExtraConfig) : undefined,
  }));
}

// ─── Quotes ──────────────────────────────────────────────────

export async function getQuotes(quoteReq: QuoteRequest) {
  const configs = await getCarrierConfigs();
  if (configs.length === 0) {
    // Fallback: usar adaptador genérico
    const generic = getCarrierAdapter({ carrierConfigId: 0, carrierCode: "GENERIC", carrierName: "Manual", carrierType: "MANUAL" });
    return generic.quote(quoteReq);
  }

  const adapters = getAllAdapters(configs);
  const allRates = await Promise.allSettled(adapters.map((a) => a.quote(quoteReq)));

  return allRates
    .filter((r): r is PromiseFulfilledResult<any[]> => r.status === "fulfilled")
    .flatMap((r) => r.value)
    .sort((a, b) => a.price - b.price);
}

// ─── Shipments ───────────────────────────────────────────────

export async function createShipment(customerId: number, data: any) {
  const { output } = await callSpOut(
    "usp_Shipping_Shipment_Create",
    {
      CompanyId: scope().companyId,
      ShippingCustomerId: customerId,
      CarrierCode: data.carrierCode || null,
      ServiceType: data.serviceType || "STANDARD",
      OriginContactName: data.origin.contactName,
      OriginPhone: data.origin.phone || null,
      OriginAddress: data.origin.address,
      OriginCity: data.origin.city,
      OriginState: data.origin.state || null,
      OriginPostalCode: data.origin.postalCode || null,
      OriginCountryCode: data.origin.countryCode || "VE",
      DestContactName: data.destination.contactName,
      DestPhone: data.destination.phone || null,
      DestAddress: data.destination.address,
      DestCity: data.destination.city,
      DestState: data.destination.state || null,
      DestPostalCode: data.destination.postalCode || null,
      DestCountryCode: data.destination.countryCode || "VE",
      DeclaredValue: data.declaredValue || null,
      Currency: data.currency || "USD",
      Description: data.description || null,
      Notes: data.notes || null,
      Reference: data.reference || null,
      PackagesJson: data.packages ? JSON.stringify(data.packages) : null,
    },
    { Resultado: "int", Mensaje: "string" }
  );

  const shipmentId = output.Resultado as number;
  const shipmentNumber = output.Mensaje as string;

  if (!shipmentId || shipmentId <= 0) {
    return { ok: false, error: output.Mensaje || "Error al crear envío" };
  }

  // Si se seleccionó un carrier, intentar generar guía
  if (data.carrierCode) {
    try {
      const configs = await getCarrierConfigs();
      const config = configs.find((c) => c.carrierCode === data.carrierCode);
      if (config) {
        const adapter = getCarrierAdapter(config);
        const label = await adapter.createShipment({
          ...data.origin,
          originContactName: data.origin.contactName,
          originAddress: data.origin.address,
          originCity: data.origin.city,
          originCountryCode: data.origin.countryCode || "VE",
          destContactName: data.destination.contactName,
          destAddress: data.destination.address,
          destCity: data.destination.city,
          destCountryCode: data.destination.countryCode || "VE",
          packages: data.packages || [],
        });

        // Update shipment with tracking info
        if (label.trackingNumber) {
          await callSpOut(
            "usp_Shipping_Shipment_UpdateStatus",
            {
              ShipmentId: shipmentId,
              NewStatus: "LABEL_READY",
              EventDescription: `Guía generada: ${label.trackingNumber}`,
              Source: "CARRIER",
            },
            { Resultado: "int", Mensaje: "string" }
          );
        }
      }
    } catch (err) {
      console.error("[shipping] Error generating label:", err);
    }
  }

  // Notify customer
  const profile = await getCustomerProfile(customerId);
  if (profile?.Email) {
    notifyShipmentEvent(profile.Email, profile.DisplayName || "", "CREATED", shipmentNumber, {
      ShipmentNumber: shipmentNumber,
      Destino: `${data.destination.city}, ${data.destination.countryCode || "VE"}`,
    });
  }

  return { ok: true, shipmentId, shipmentNumber };
}

export async function listShipments(customerId: number, filters: { status?: string; search?: string; page?: number; limit?: number }) {
  const params: any = {
    ShippingCustomerId: customerId,
    Status: filters.status || null,
    Search: filters.search || null,
    Page: filters.page || 1,
    Limit: filters.limit || 20,
  };

  const { rows, output } = await callSpOut(
    "usp_Shipping_Shipment_List",
    params,
    { TotalCount: "int" }
  );

  return { rows, totalCount: output.TotalCount ?? (rows[0] as any)?.TotalCount ?? 0 };
}

export async function getShipment(shipmentId: number, customerId?: number) {
  const shipment = await callSp("usp_Shipping_Shipment_Get", {
    ShipmentId: shipmentId,
    ShippingCustomerId: customerId || null,
  });

  // For PG we need separate calls for related data
  const events = await callSp("usp_Shipping_Shipment_Events", { ShipmentId: shipmentId }).catch(() => []);
  const packages = await callSp("usp_Shipping_Shipment_Packages", { ShipmentId: shipmentId }).catch(() => []);

  return {
    shipment: shipment[0] || null,
    events,
    packages,
  };
}

export async function updateShipmentStatus(
  shipmentId: number,
  status: string,
  description: string,
  extra?: { location?: string; city?: string; countryCode?: string; carrierEventCode?: string; source?: string }
) {
  const { output } = await callSpOut(
    "usp_Shipping_Shipment_UpdateStatus",
    {
      ShipmentId: shipmentId,
      NewStatus: status,
      EventDescription: description,
      Location: extra?.location || null,
      City: extra?.city || null,
      CountryCode: extra?.countryCode || null,
      CarrierEventCode: extra?.carrierEventCode || null,
      Source: extra?.source || "SYSTEM",
    },
    { Resultado: "int", Mensaje: "string" }
  );

  // Get shipment to notify customer
  if (output.Resultado === 1) {
    try {
      const shipment = (await callSp("usp_Shipping_Shipment_Get", { ShipmentId: shipmentId }))[0] as any;
      if (shipment?.ShippingCustomerId) {
        const profile = await getCustomerProfile(shipment.ShippingCustomerId);
        if (profile?.Email) {
          notifyShipmentEvent(profile.Email, profile.DisplayName || "", status, shipment.ShipmentNumber, {
            Estado: statusLabels[status] || status,
            Descripcion: description,
          });
        }
      }
    } catch {}
  }

  return { ok: output.Resultado === 1, message: output.Mensaje };
}

// ─── Public Tracking ─────────────────────────────────────────

interface ShipmentTrackRow {
  ShipmentId: number;
  CarrierCode: string | null;
  TrackingNumber: string | null;
  Status: string;
  ShipmentNumber: string;
}

export async function trackPublic(trackingNumber: string) {
  // 1. Buscar en nuestra BD
  const [shipment] = await callSp<ShipmentTrackRow>("usp_Shipping_Track", { TrackingNumber: trackingNumber });
  const storedEvents = await callSp("usp_Shipping_Track_Events", { TrackingNumber: trackingNumber }).catch(() => []);

  // 2. Si el envío tiene un carrier conocido (ZOOM, MRW, LIBERTY), consultar su API
  if (shipment?.CarrierCode && shipment.CarrierCode !== "MANUAL") {
    try {
      const configs = await getCarrierConfigs();
      const cfg = configs.find((c) => c.carrierCode === shipment.CarrierCode);
      if (cfg) {
        const adapter = getCarrierAdapter(cfg);
        const trackNum = shipment.TrackingNumber || trackingNumber;
        const carrierEvents = await adapter.track(trackNum);
        if (carrierEvents.length > 0) {
          // Persistir eventos nuevos del carrier en nuestra BD
          for (const e of carrierEvents) {
            await updateShipmentStatus(shipment.ShipmentId, e.status, e.description, {
              location: e.location ?? undefined,
              city: e.city ?? undefined,
              countryCode: e.countryCode ?? undefined,
              carrierEventCode: e.carrierEventCode ?? undefined,
              source: "CARRIER_POLL",
            }).catch(() => {});
          }
          // Devolver los eventos frescos del carrier
          const refreshed = await callSp("usp_Shipping_Track_Events", { TrackingNumber: trackingNumber }).catch(() => storedEvents);
          return { shipment, events: refreshed };
        }
      }
    } catch { /* si el carrier falla, usar eventos locales */ }
  }

  // 3. Si NO está en nuestra BD, intentar rastrear directamente en los carriers conocidos
  if (!shipment) {
    const carrierEvents = await tryCarrierDirectTracking(trackingNumber);
    if (carrierEvents.length > 0) {
      // Devolvemos resultado "externo" sin shipment record
      return {
        shipment: { ShipmentNumber: trackingNumber, TrackingNumber: trackingNumber, Status: carrierEvents[0].status, external: true },
        events: carrierEvents.map((e) => ({
          Description: e.description,
          EventAt: e.eventAt,
          City: e.city,
          Location: e.location,
          CarrierEventCode: e.carrierEventCode,
        })),
      };
    }
    return { shipment: null, events: [] };
  }

  return { shipment, events: storedEvents };
}

/** Intenta rastrear en todos los carriers cuando el número no está en nuestra BD */
async function tryCarrierDirectTracking(trackingNumber: string) {
  try {
    const configs = await getCarrierConfigs();
    const candidates = detectCarrierCandidates(trackingNumber, configs);
    for (const cfg of candidates) {
      const adapter = getCarrierAdapter(cfg);
      const events = await adapter.track(trackingNumber);
      if (events.length > 0) return events;
    }
  } catch { /* silencioso */ }
  return [];
}

// ─── Customs ─────────────────────────────────────────────────

export async function upsertCustoms(shipmentId: number, data: any) {
  const { output } = await callSpOut(
    "usp_Shipping_Customs_Upsert",
    {
      ShipmentId: shipmentId,
      ContentType: data.contentType || "MERCHANDISE",
      TotalDeclaredValue: data.totalDeclaredValue,
      Currency: data.currency || "USD",
      ExporterName: data.exporterName || null,
      ExporterFiscalId: data.exporterFiscalId || null,
      ImporterName: data.importerName || null,
      ImporterFiscalId: data.importerFiscalId || null,
      OriginCountryCode: data.originCountryCode,
      DestCountryCode: data.destCountryCode,
      HsCode: data.hsCode || null,
      ItemDescription: data.itemDescription,
      Quantity: data.quantity || 1,
      WeightKg: data.weightKg || null,
      Notes: data.notes || null,
    },
    { Resultado: "int", Mensaje: "string" }
  );
  return { ok: output.Resultado === 1, message: output.Mensaje };
}

// ─── Dashboard ───────────────────────────────────────────────

export async function getDashboard(customerId: number) {
  const rows = await callSp("usp_Shipping_Dashboard", { ShippingCustomerId: customerId });
  return rows[0] || null;
}

// ─── Notification Helper ─────────────────────────────────────

const statusLabels: Record<string, string> = {
  CREATED: "Creado",
  DRAFT: "Borrador",
  QUOTED: "Cotizado",
  LABEL_READY: "Guía lista",
  PICKED_UP: "Recogido",
  IN_TRANSIT: "En tránsito",
  IN_CUSTOMS: "En aduana",
  CUSTOMS_HELD: "Retenido en aduana",
  CUSTOMS_CLEARED: "Liberado de aduana",
  OUT_FOR_DELIVERY: "En camino a entrega",
  DELIVERED: "Entregado",
  RETURNED: "Devuelto",
  EXCEPTION: "Incidencia",
  CANCELLED: "Cancelado",
};

function notifyShipmentEvent(
  email: string,
  customerName: string,
  eventType: string,
  shipmentNumber: string,
  data: Record<string, string>
) {
  const label = statusLabels[eventType] || eventType;
  const subject = `Envío ${shipmentNumber} — ${label}`;

  emitBusinessNotification({
    event: "DELIVERY_DISPATCHED" as any,
    to: email,
    subject,
    data: {
      Envío: shipmentNumber,
      Estado: label,
      Cliente: customerName,
      ...data,
    },
    channels: ["email"],
  }).catch(() => {});
}
