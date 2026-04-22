/**
 * Formatea errores del API admin ecommerce para UI.
 *
 * El backend retorna distintos shapes:
 *   - Zod validation: { error: "invalid_body", details: { fieldErrors: { campo: ["msg"] } } }
 *   - Errores SP:     { error: "server_error", message: "..." }
 *   - Errores plano:  { error: "not_found" }  o  { message: "..." }
 *
 * Este helper extrae el mensaje mas util disponible, priorizando
 * errores de validacion Zod sobre mensajes genericos.
 */
export function formatApiError(data: unknown, fallback: string): string {
  if (!data || typeof data !== "object") return fallback;
  const d = data as Record<string, any>;
  const fieldErrors = d?.details?.fieldErrors;
  if (fieldErrors && typeof fieldErrors === "object") {
    const parts: string[] = [];
    for (const [field, msgs] of Object.entries(fieldErrors)) {
      const m = Array.isArray(msgs) ? (msgs as string[]).join(", ") : String(msgs);
      parts.push(`${field}: ${m}`);
    }
    if (parts.length) return `Validacion: ${parts.join(" | ")}`;
  }
  return d?.message || d?.error || fallback;
}
