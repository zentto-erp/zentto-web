/**
 * CRM Companies / Contacts / Deals — endpoints /v1/crm (ADR-CRM-001).
 * Todas las rutas respetan tenant via getActiveScope().
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as companySvc from "./companyService.js";
import * as contactSvc from "./contactService.js";
import * as dealSvc    from "./dealService.js";
import { obs } from "../integrations/observability.js";

export const contactsDealsRouter = Router();

function userId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

function userContext(req: Request) {
  const u = (req as any).user ?? {};
  return {
    userId:    u.userId ?? u.id ?? null,
    userName:  u.userName ?? u.name ?? null,
    companyId: u.companyId ?? null,
  };
}

function intOrUndef(v: unknown): number | undefined {
  if (v === undefined || v === null || v === "") return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

function boolOrUndef(v: unknown): boolean | undefined {
  if (v === undefined || v === null || v === "") return undefined;
  if (v === "true"  || v === true)  return true;
  if (v === "false" || v === false) return false;
  return undefined;
}

function fail(res: Response, err: unknown, status = 500) {
  const msg = err instanceof Error ? err.message : String(err);
  res.status(status).json({ error: msg });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPANIES
// ═══════════════════════════════════════════════════════════════════════════════

const companyUpsertSchema = z.object({
  crmCompanyId:    z.number().int().positive().optional().nullable(),
  name:            z.string().min(1).max(200),
  legalName:       z.string().max(200).optional().nullable(),
  taxId:           z.string().max(50).optional().nullable(),
  industry:        z.string().max(100).optional().nullable(),
  size:            z.enum(["1-10","11-50","51-200","201-500","501-1000","1000+"]).optional().nullable(),
  website:         z.string().max(255).optional().nullable(),
  phone:           z.string().max(50).optional().nullable(),
  email:           z.string().email().max(255).optional().nullable(),
  billingAddress:  z.any().optional().nullable(),
  shippingAddress: z.any().optional().nullable(),
  notes:           z.string().optional().nullable(),
  isActive:        z.boolean().optional(),
});

contactsDealsRouter.get("/companies", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await companySvc.listCompanies({
      search:   (q.search as string) || undefined,
      industry: (q.industry as string) || undefined,
      isActive: boolOrUndef(q.active),
      page:     intOrUndef(q.page),
      limit:    intOrUndef(q.limit),
    });
    res.json(result);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/companies/search", async (req: Request, res: Response) => {
  try {
    const rows = await companySvc.searchCompanies(
      String(req.query.q || ""),
      intOrUndef(req.query.limit) ?? 20,
    );
    res.json(rows);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/companies/:id", async (req: Request, res: Response) => {
  try {
    const row = await companySvc.getCompany(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.post("/companies", async (req: Request, res: Response) => {
  try {
    const body = companyUpsertSchema.parse(req.body);
    const result = await companySvc.upsertCompany({ ...body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.company.created", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.put("/companies/:id", async (req: Request, res: Response) => {
  try {
    const body = companyUpsertSchema.parse(req.body);
    const result = await companySvc.upsertCompany({
      ...body,
      crmCompanyId: Number(req.params.id),
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.company.updated", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.delete("/companies/:id", async (req: Request, res: Response) => {
  try {
    const result = await companySvc.deleteCompany(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.company.deleted", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err); }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACTS
// ═══════════════════════════════════════════════════════════════════════════════

const contactUpsertSchema = z.object({
  contactId:    z.number().int().positive().optional().nullable(),
  crmCompanyId: z.number().int().positive().optional().nullable(),
  firstName:    z.string().min(1).max(100),
  lastName:     z.string().max(100).optional().nullable(),
  email:        z.string().email().max(255).optional().nullable(),
  phone:        z.string().max(50).optional().nullable(),
  mobile:       z.string().max(50).optional().nullable(),
  title:        z.string().max(100).optional().nullable(),
  department:   z.string().max(100).optional().nullable(),
  linkedIn:     z.string().max(255).optional().nullable(),
  notes:        z.string().optional().nullable(),
  isActive:     z.boolean().optional(),
});

contactsDealsRouter.get("/contacts", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await contactSvc.listContacts({
      crmCompanyId: intOrUndef(q.crmCompanyId ?? q.companyId),
      search:       (q.search as string) || undefined,
      isActive:     boolOrUndef(q.active),
      page:         intOrUndef(q.page),
      limit:        intOrUndef(q.limit),
    });
    res.json(result);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/contacts/search", async (req: Request, res: Response) => {
  try {
    const rows = await contactSvc.searchContacts(
      String(req.query.q || ""),
      intOrUndef(req.query.limit) ?? 20,
    );
    res.json(rows);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/contacts/:id", async (req: Request, res: Response) => {
  try {
    const row = await contactSvc.getContact(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.post("/contacts", async (req: Request, res: Response) => {
  try {
    const body = contactUpsertSchema.parse(req.body);
    const result = await contactSvc.upsertContact({ ...body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.contact.created", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.put("/contacts/:id", async (req: Request, res: Response) => {
  try {
    const body = contactUpsertSchema.parse(req.body);
    const result = await contactSvc.upsertContact({
      ...body,
      contactId: Number(req.params.id),
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.contact.updated", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.delete("/contacts/:id", async (req: Request, res: Response) => {
  try {
    const result = await contactSvc.deleteContact(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.contact.deleted", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.post("/contacts/:id/promote-customer", async (req: Request, res: Response) => {
  try {
    const customerCode = typeof req.body?.customerCode === "string" ? req.body.customerCode : null;
    const result = await contactSvc.promoteContactToCustomer(
      Number(req.params.id),
      customerCode,
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.contact.promoted", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err); }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  DEALS
// ═══════════════════════════════════════════════════════════════════════════════

const dealUpsertSchema = z.object({
  dealId:        z.number().int().positive().optional().nullable(),
  name:          z.string().min(1).max(255),
  pipelineId:    z.number().int().positive().optional().nullable(),
  stageId:       z.number().int().positive().optional().nullable(),
  contactId:     z.number().int().positive().optional().nullable(),
  crmCompanyId:  z.number().int().positive().optional().nullable(),
  ownerAgentId:  z.number().int().positive().optional().nullable(),
  value:         z.number().nonnegative().optional(),
  currency:      z.string().length(3).optional(),
  probability:   z.number().min(0).max(100).optional().nullable(),
  expectedClose: z.string().optional().nullable(),
  priority:      z.enum(["URGENT","HIGH","MEDIUM","LOW"]).optional(),
  source:        z.string().max(50).optional().nullable(),
  notes:         z.string().optional().nullable(),
  tags:          z.string().max(500).optional().nullable(),
  branchId:      z.number().int().positive().optional(),
});

contactsDealsRouter.get("/deals", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await dealSvc.listDeals({
      pipelineId:   intOrUndef(q.pipelineId),
      stageId:      intOrUndef(q.stageId),
      status:       (q.status as string) || undefined,
      ownerAgentId: intOrUndef(q.ownerAgentId),
      contactId:    intOrUndef(q.contactId),
      crmCompanyId: intOrUndef(q.crmCompanyId),
      search:       (q.search as string) || undefined,
      page:         intOrUndef(q.page),
      limit:        intOrUndef(q.limit),
    });
    res.json(result);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/deals/search", async (req: Request, res: Response) => {
  try {
    const rows = await dealSvc.searchDeals(
      String(req.query.q || ""),
      intOrUndef(req.query.limit) ?? 20,
    );
    res.json(rows);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/deals/:id", async (req: Request, res: Response) => {
  try {
    const row = await dealSvc.getDeal(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.get("/deals/:id/timeline", async (req: Request, res: Response) => {
  try {
    const rows = await dealSvc.getDealTimeline(
      Number(req.params.id),
      intOrUndef(req.query.limit) ?? 100,
    );
    res.json(rows);
  } catch (err) { fail(res, err); }
});

contactsDealsRouter.post("/deals", async (req: Request, res: Response) => {
  try {
    const body = dealUpsertSchema.parse(req.body);
    const result = await dealSvc.upsertDeal({ ...body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.created", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.put("/deals/:id", async (req: Request, res: Response) => {
  try {
    const body = dealUpsertSchema.parse(req.body);
    const result = await dealSvc.upsertDeal({
      ...body,
      dealId: Number(req.params.id),
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.updated", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

const moveStageSchema = z.object({
  newStageId: z.number().int().positive(),
  notes:      z.string().optional().nullable(),
});

contactsDealsRouter.post("/deals/:id/move-stage", async (req: Request, res: Response) => {
  try {
    const body = moveStageSchema.parse(req.body);
    const result = await dealSvc.moveDealStage(
      Number(req.params.id),
      body.newStageId,
      body.notes ?? null,
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.stage_moved", { entityId: result.id, newStageId: body.newStageId, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

const closeSchema = z.object({ reason: z.string().max(500).optional().nullable() });

contactsDealsRouter.post("/deals/:id/close-won", async (req: Request, res: Response) => {
  try {
    const body = closeSchema.parse(req.body ?? {});
    const result = await dealSvc.closeDealWon(
      Number(req.params.id),
      body.reason ?? null,
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.won", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.post("/deals/:id/close-lost", async (req: Request, res: Response) => {
  try {
    const body = closeSchema.parse(req.body ?? {});
    const result = await dealSvc.closeDealLost(
      Number(req.params.id),
      body.reason ?? null,
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.lost", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});

contactsDealsRouter.delete("/deals/:id", async (req: Request, res: Response) => {
  try {
    const result = await dealSvc.deleteDeal(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.deal.deleted", { entityId: result.id, ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err); }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  LEAD CONVERT
// ═══════════════════════════════════════════════════════════════════════════════

const convertSchema = z.object({
  dealName:      z.string().max(255).optional().nullable(),
  pipelineId:    z.number().int().positive().optional().nullable(),
  stageId:       z.number().int().positive().optional().nullable(),
  crmCompanyId:  z.number().int().positive().optional().nullable(),
});

contactsDealsRouter.post("/leads/:id/convert", async (req: Request, res: Response) => {
  try {
    const body = convertSchema.parse(req.body ?? {});
    const result = await dealSvc.convertLeadToDeal(Number(req.params.id), {
      ...body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit("crm.lead.converted", { entityId: result.id, leadId: Number(req.params.id), ...userContext(req), module: "crm" }); } catch {}
    }
  } catch (err) { fail(res, err, 400); }
});
