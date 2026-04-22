"use client";

/**
 * Service layer para el inbox de contact-submissions CMS.
 *
 * Backend: GET /v1/cms/contact-submissions — admin endpoint (requiere JWT +
 * rol admin o CMS_EDITOR). Lista mensajes enviados desde el
 * `ContactFormAdapter` de `@zentto/landing-kit`.
 *
 * NOTA: el backend NO expone (todavía) un endpoint PUT/PATCH para actualizar
 * status (read/archived). Esa capacidad se marca como TODO en la UI y sólo
 * se habilitará cuando exista el SP + endpoint (seguimiento: siguiente PR
 * del plan CMS Dogfooding).
 */

import { apiGet } from "@zentto/shared-api";
import { VERTICALS } from "../_lib";

export { VERTICALS };

export type ContactStatus = "pending" | "read" | "archived" | string;

export const CONTACT_STATUSES: { value: ContactStatus; label: string; color: "default" | "success" | "warning" }[] = [
  { value: "pending", label: "Pendiente", color: "warning" },
  { value: "read", label: "Leído", color: "default" },
  { value: "archived", label: "Archivado", color: "default" },
];

export interface ContactSubmission {
  ContactSubmissionId: number;
  CompanyId: number;
  Vertical: string;
  Slug: string;
  Name: string;
  Email: string;
  Subject: string;
  Message: string;
  Status: ContactStatus;
  CreatedAt: string;
}

export interface ContactListResponse {
  ok: boolean;
  data: ContactSubmission[];
  total: number;
  limit: number;
  offset: number;
}

export async function listContactSubmissions(
  opts: { vertical?: string; status?: ContactStatus; limit?: number; offset?: number } = {},
): Promise<ContactListResponse> {
  return apiGet("/v1/cms/contact-submissions", opts as Record<string, unknown>);
}

/** Construye un link mailto pre-rellenado para responder. */
export function buildMailtoReply(s: ContactSubmission): string {
  const subject = s.Subject ? `Re: ${s.Subject}` : "Re: tu mensaje en Zentto";
  const body =
    `Hola ${s.Name || ""},\n\n` +
    `Gracias por tu mensaje. \n\n` +
    `---\n` +
    `Mensaje original:\n` +
    `${s.Message || ""}\n`;
  return `mailto:${encodeURIComponent(s.Email)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}
