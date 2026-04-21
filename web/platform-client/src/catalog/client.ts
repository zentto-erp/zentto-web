/**
 * CatalogClient — cliente tipado para el catalogo comercial publico de Zentto
 * (https://api.zentto.net/v1/catalog/*).
 *
 * Cubre:
 *   - listPlans: lista planes filtrables por vertical, product, includeTrial.
 *   - getPlanBySlug: detalle de un plan por slug.
 *   - listProducts: productos agrupados (core + bundles + addons).
 *   - checkSubdomain: valida que un slug de subdominio este disponible.
 *
 * Todos los endpoints son publicos (no requieren auth). Usado por landings
 * publicas y frontend de signup. Para backoffice (CRUD de planes) ver el
 * cliente futuro `@zentto/platform-client/backoffice-catalog` (pendiente).
 */
import { defaultHttpConfig, httpRequest, type HttpConfig, type HttpConfigInput, type HttpResult } from "../internal/http.js";

export type Vertical =
  | "erp"
  | "medical"
  | "tickets"
  | "hotel"
  | "education"
  | "rental"
  | "none"
  | "pos"
  | "restaurante"
  | "ecommerce"
  | "crm"
  | "contabilidad"
  | "inmobiliario";

export type PlanTier = "core" | "bundle" | "addon" | "enterprise";

export interface CatalogConfig {
  baseUrl?: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
  rateLimit?: HttpConfigInput["rateLimit"];
}

export interface PricingPlanSummary {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: Vertical | string;
  MonthlyPrice: number;
  AnnualPrice: number;
  TransactionFeePercent: number;
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  IsActive: boolean;
  CompanyId: number;
  CreatedAt: string;
}

export interface PricingPlanDetail extends PricingPlanSummary {
  ProductCode: string;
  Description: string;
  BillingCycleDefault: "monthly" | "annual" | "both";
  Tier: PlanTier | null;
  IsAddon: boolean;
  IsTrialOnly: boolean;
  TrialDays: number;
  ModuleCodes: string[];
  Limits: Record<string, unknown>;
  SortOrder: number;
  PaddleProductId: string;
  PaddlePriceIdMonthly: string;
  PaddlePriceIdAnnual: string;
  PaddleSyncStatus: "draft" | "syncing" | "synced" | "error" | "skip";
}

export interface CatalogProduct {
  ProductCode: string;
  VerticalType: Vertical | string;
  IsAddon: boolean;
  Plans: PricingPlanDetail[];
}

export interface SubdomainCheckResult {
  slug: string;
  available: boolean;
  normalized: string;
  reason: string | null;
}

export interface ListPlansParams {
  vertical?: Vertical;
  product?: string;
  includeTrial?: boolean;
}

export interface ListProductsParams {
  vertical?: Vertical;
}

export class CatalogClient {
  private readonly cfg: HttpConfig;

  constructor(opts: CatalogConfig = {}) {
    this.cfg = defaultHttpConfig({
      baseUrl: opts.baseUrl ?? "https://api.zentto.net",
      timeoutMs: opts.timeoutMs,
      retries: opts.retries,
      onError: opts.onError,
      rateLimit: opts.rateLimit,
    });
  }

  /** Lista planes publicos del catalogo canonico. */
  listPlans(params: ListPlansParams = {}): Promise<HttpResult<PricingPlanDetail[]>> {
    return httpRequest<PricingPlanDetail[]>(this.cfg, {
      method: "GET",
      path: "/v1/catalog/plans",
      query: {
        vertical: params.vertical,
        product: params.product,
        includeTrial: params.includeTrial === undefined ? undefined : String(params.includeTrial),
      },
    });
  }

  /** Detalle de un plan por slug. */
  getPlanBySlug(slug: string): Promise<HttpResult<PricingPlanDetail>> {
    return httpRequest<PricingPlanDetail>(this.cfg, {
      method: "GET",
      path: `/v1/catalog/plans/${encodeURIComponent(slug)}`,
    });
  }

  /** Productos del catalogo agrupados (core + bundles + addons). */
  listProducts(params: ListProductsParams = {}): Promise<HttpResult<CatalogProduct[]>> {
    return httpRequest<CatalogProduct[]>(this.cfg, {
      method: "GET",
      path: "/v1/catalog/products",
      query: { vertical: params.vertical },
    });
  }

  /** Valida disponibilidad de un subdominio para signup. */
  checkSubdomain(slug: string): Promise<HttpResult<SubdomainCheckResult>> {
    return httpRequest<SubdomainCheckResult>(this.cfg, {
      method: "GET",
      path: `/v1/catalog/subdomain-check/${encodeURIComponent(slug)}`,
    });
  }
}

/**
 * Factory desde env vars:
 *   ZENTTO_API_URL — default https://api.zentto.net
 */
export function catalogFromEnv(overrides?: Partial<CatalogConfig>): CatalogClient {
  return new CatalogClient({
    baseUrl: process.env.ZENTTO_API_URL,
    ...overrides,
  });
}
