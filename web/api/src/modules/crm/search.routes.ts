/**
 * CRM Cross-entity Search — GET /v1/crm/search
 *
 * Endpoint orquestador que unifica la búsqueda a través de contactos,
 * empresas, deals (y, en el futuro, leads) en una sola llamada para
 * alimentar el CommandPalette del rediseño CRM (issue #439).
 *
 * Reusa los SPs existentes:
 *   - usp_crm_Contact_Search
 *   - usp_crm_Company_Search
 *   - usp_crm_Deal_Search
 *
 * Leads: hoy NO existe `usp_crm_Lead_Search`. Si un cliente solicita
 * explícitamente `entities=lead`, se devuelve un warning y esa entidad
 * queda vacía (TODO: crear SP dedicado para búsqueda de leads).
 *
 * Tenant guard: los servicios subyacentes resuelven `CompanyId` vía
 * `getActiveScope()`, por lo que el controller no requiere lógica extra.
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as companySvc from "./companyService.js";
import * as contactSvc from "./contactService.js";
import * as dealSvc    from "./dealService.js";

export const crmSearchRouter = Router();

// ── Tipos del contrato ────────────────────────────────────────────────────────

type EntityKind = "lead" | "contact" | "company" | "deal";

interface SearchResult {
  type: EntityKind;
  id: number | string;
  title: string;
  subtitle?: string;
  meta?: Record<string, unknown>;
}

interface SearchResponse {
  results: SearchResult[];
  total: number;
  byEntity: Partial<Record<EntityKind, number>>;
  warnings?: string[];
}

// ── Validación de query params ────────────────────────────────────────────────

const ALLOWED_ENTITIES: EntityKind[] = ["lead", "contact", "company", "deal"];
const DEFAULT_ENTITIES: EntityKind[] = ["contact", "company", "deal"];

const searchQuerySchema = z.object({
  q: z.string().trim().min(2, "q debe tener al menos 2 caracteres").max(200),
  entities: z
    .string()
    .optional()
    .transform((val) => {
      if (!val || !val.trim()) return DEFAULT_ENTITIES;
      const parts = val
        .split(",")
        .map((s) => s.trim().toLowerCase())
        .filter(Boolean)
        .filter((e): e is EntityKind => (ALLOWED_ENTITIES as string[]).includes(e));
      return parts.length > 0 ? Array.from(new Set(parts)) : DEFAULT_ENTITIES;
    }),
  limit: z
    .string()
    .optional()
    .transform((val) => {
      if (!val) return 10;
      const n = Number(val);
      if (!Number.isFinite(n) || n <= 0) return 10;
      return Math.min(Math.max(1, Math.floor(n)), 50);
    }),
});

// ── Normalizadores por entidad ────────────────────────────────────────────────

function normalizeContact(row: any): SearchResult {
  const first = row.FirstName ?? row.firstName ?? "";
  const last  = row.LastName  ?? row.lastName  ?? "";
  const full  = `${first} ${last}`.trim() || row.Email || row.email || "(sin nombre)";
  const email = row.Email ?? row.email ?? null;
  const phone = row.Phone ?? row.phone ?? null;
  const companyName = row.CompanyName ?? row.companyName ?? null;
  return {
    type: "contact",
    id: Number(row.ContactId ?? row.contactId),
    title: full,
    subtitle: email || phone || companyName || undefined,
    meta: {
      email,
      phone,
      companyName,
    },
  };
}

function normalizeCompany(row: any): SearchResult {
  const name = row.Name ?? row.name ?? "(sin nombre)";
  const taxId    = row.TaxId    ?? row.taxId    ?? null;
  const industry = row.Industry ?? row.industry ?? null;
  return {
    type: "company",
    id: Number(row.CrmCompanyId ?? row.crmCompanyId),
    title: String(name),
    subtitle: taxId || industry || undefined,
    meta: {
      taxId,
      industry,
    },
  };
}

function normalizeDeal(row: any): SearchResult {
  const name     = row.Name     ?? row.name     ?? "(sin nombre)";
  const value    = row.Value    ?? row.value    ?? null;
  const currency = row.Currency ?? row.currency ?? null;
  const status   = row.Status   ?? row.status   ?? null;
  const subtitle = value != null
    ? `${currency ?? ""} ${Number(value).toLocaleString()}`.trim()
    : status ?? undefined;
  return {
    type: "deal",
    id: Number(row.DealId ?? row.dealId),
    title: String(name),
    subtitle,
    meta: {
      value: value != null ? Number(value) : null,
      currency,
      status,
    },
  };
}

// ── Controller ────────────────────────────────────────────────────────────────

crmSearchRouter.get("/", async (req: Request, res: Response) => {
  // Validación
  const parsed = searchQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return res.status(400).json({
      error: issue?.message ?? "invalid_query",
      details: parsed.error.issues,
    });
  }
  const { q, entities, limit } = parsed.data;

  const warnings: string[] = [];
  const tasks: Array<Promise<SearchResult[]>> = [];
  const runOrder: EntityKind[] = [];

  if (entities.includes("contact")) {
    runOrder.push("contact");
    tasks.push(
      contactSvc.searchContacts(q, limit).then((rows: any) =>
        Array.isArray(rows) ? rows.map(normalizeContact) : [],
      ),
    );
  }
  if (entities.includes("company")) {
    runOrder.push("company");
    tasks.push(
      companySvc.searchCompanies(q, limit).then((rows: any) =>
        Array.isArray(rows) ? rows.map(normalizeCompany) : [],
      ),
    );
  }
  if (entities.includes("deal")) {
    runOrder.push("deal");
    tasks.push(
      dealSvc.searchDeals(q, limit).then((rows: any) =>
        Array.isArray(rows) ? rows.map(normalizeDeal) : [],
      ),
    );
  }
  if (entities.includes("lead")) {
    // TODO(#439): implementar usp_crm_Lead_Search dedicado. Hoy `usp_CRM_Lead_List`
    // pagina pero no es óptimo para búsquedas rápidas del CommandPalette.
    warnings.push("lead_search_not_implemented");
  }

  try {
    const settled = await Promise.all(tasks);

    const byEntity: Partial<Record<EntityKind, number>> = {};
    const results: SearchResult[] = [];
    settled.forEach((rows, idx) => {
      const kind = runOrder[idx]!;
      byEntity[kind] = rows.length;
      for (const r of rows) results.push(r);
    });
    if (entities.includes("lead")) byEntity.lead = 0;

    const payload: SearchResponse = {
      results,
      total: results.length,
      byEntity,
      ...(warnings.length ? { warnings } : {}),
    };
    res.json(payload);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    res.status(500).json({ error: msg });
  }
});
