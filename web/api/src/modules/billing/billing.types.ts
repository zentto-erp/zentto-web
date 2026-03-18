/**
 * billing.types.ts — Tipos para el módulo de facturación SaaS (Paddle)
 */

export interface BillingPlan {
  id: string;
  name: string;
  priceId: string;
  price: number;
  currency: string;
  interval: "month";
  features: string[];
}

export interface CheckoutRequest {
  priceId: string;
  customerEmail: string;
}

export interface SubscriptionRecord {
  SubscriptionId: string;
  CompanyId: number;
  PaddleCustomerId: string;
  PaddleSubscriptionId: string;
  PriceId: string;
  PlanName: string;
  Status: string;
  CurrentPeriodStart: string;
  CurrentPeriodEnd: string;
  CancelledAt: string | null;
}

export interface WebhookEvent {
  event_type: string;
  event_id: string;
  occurred_at: string;
  data: Record<string, unknown>;
}

export type SubscriptionStatus =
  | "active"
  | "canceled"
  | "past_due"
  | "paused"
  | "trialing";

export const PLANS: BillingPlan[] = [
  {
    id: "basico",
    name: "Zentto Básico",
    priceId: "pri_01kky59xnge4kenjp2hav35rx0",
    price: 29,
    currency: "USD",
    interval: "month",
    features: [
      "1 empresa",
      "2 sucursales",
      "5 usuarios",
      "Facturación",
      "Inventario",
      "Cuentas por Cobrar / Cuentas por Pagar",
      "Reportes básicos",
    ],
  },
  {
    id: "profesional",
    name: "Zentto Profesional",
    priceId: "pri_01kky5a0mwzk38j23hkcgmxn47",
    price: 79,
    currency: "USD",
    interval: "month",
    features: [
      "3 empresas",
      "10 sucursales",
      "25 usuarios",
      "Todo lo de Básico",
      "Contabilidad",
      "Nómina",
      "Multi-moneda",
      "Reportes avanzados",
      "API access",
      "Soporte prioritario",
    ],
  },
];
