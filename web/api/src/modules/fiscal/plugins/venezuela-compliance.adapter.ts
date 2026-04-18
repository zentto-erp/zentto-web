/**
 * Adapter SENIAT Compliance (Homologacion Providencia 121) — fire-and-forget.
 *
 * Separado de venezuela-digital.adapter.ts (imprenta). Son dos servicios
 * independientes con responsabilidades distintas:
 *   - venezuela-digital.adapter: factura individual → zentto-imprenta-seniat
 *   - venezuela-compliance.adapter: eventos fiscales → zentto-seniat-compliance
 *
 * DISEÑO NO BLOQUEANTE:
 *   - Feature flag cfg.AppSetting "seniat.complianceEnabled"
 *   - Publicacion fire-and-forget (no espera respuesta al usuario)
 *   - Si el micro falla: encola en fiscal.PendingComplianceEvent
 *   - ERP SIEMPRE continua sin interrupcion
 */
import { query, execute } from "../../../db/query.js";

type ComplianceClientLike = {
  publishEvent: (event: any) => Promise<any | null>;
};

let clientInstance: ComplianceClientLike | null = null;
let clientLoadFailed = false;

async function getClient(): Promise<ComplianceClientLike | null> {
  if (clientInstance) return clientInstance;
  if (clientLoadFailed) return null;
  try {
    const baseUrl = process.env.ZENTTO_COMPLIANCE_URL;
    const apiKey = process.env.ZENTTO_COMPLIANCE_KEY;
    if (!baseUrl || !apiKey) {
      clientLoadFailed = true;
      return null;
    }
    const mod = await import("@zentto/seniat-compliance-client" as any).catch(() => null);
    if (!mod?.ComplianceClient) {
      clientLoadFailed = true;
      return null;
    }
    clientInstance = new mod.ComplianceClient({
      baseUrl, apiKey, timeoutMs: 2000,
      circuitBreaker: { failureThreshold: 5, resetMs: 30_000 },
      onFailure: async (ev: any, err: Error) => {
        // Encolar para reintento local
        try {
          await execute(
            `INSERT INTO fiscal."PendingComplianceEvent"
               ("CompanyId","RifEmisor","EventType","ReferenceType","ReferenceId",
                "PayloadJson","OccurredAt","LastError")
             VALUES (@cid, @rif, @et, @rt, @rid, @payload::jsonb, @occurred, @err)`,
            {
              cid: ev._companyId ?? 0,
              rif: ev.rifEmisor,
              et: ev.eventType,
              rt: ev.referenceType ?? null,
              rid: ev.referenceId ?? null,
              payload: JSON.stringify(ev.payload),
              occurred: ev.occurredAt,
              err: err.message.substring(0, 500),
            }
          );
        } catch (qErr) {
          console.error("[compliance] queue enqueue failed (non-blocking):", qErr);
        }
      },
    });
    return clientInstance;
  } catch {
    clientLoadFailed = true;
    return null;
  }
}

async function isFeatureEnabled(companyId: number): Promise<boolean> {
  try {
    const rows = await query<{ SettingValue: string }>(
      `SELECT "SettingValue" FROM cfg."AppSetting"
        WHERE "CompanyId" = @companyId AND "Module" = @module AND "SettingKey" = @key
        LIMIT 1`,
      { companyId, module: "fiscal", key: "seniat.complianceEnabled" }
    );
    return rows[0]?.SettingValue === "true";
  } catch {
    return false;
  }
}

export type ComplianceEventType =
  | "INVOICE_ISSUED" | "INVOICE_CANCELLED" | "CREDIT_NOTE" | "DEBIT_NOTE"
  | "WITHHOLDING_ISSUED" | "PERIOD_CLOSED" | "ADJUSTMENT" | "ERROR_CORRECTION";

export interface ComplianceEventInput {
  companyId: number;
  rifEmisor: string;
  eventType: ComplianceEventType;
  referenceType?: string;
  referenceId?: string;
  payload: Record<string, unknown>;
  occurredAt?: Date | string;
}

/**
 * Publica evento al micro de compliance. Fire-and-forget.
 * NO lanza errores, NO bloquea. Si falla, encola para reintento async.
 *
 * Uso típico (después de emitir factura en el ERP):
 *   publishComplianceEvent({
 *     companyId, rifEmisor, eventType: 'INVOICE_ISSUED',
 *     referenceId: facturaCorrelativo, payload: { ... }
 *   }).catch(() => {});
 */
export async function publishComplianceEvent(input: ComplianceEventInput): Promise<void> {
  try {
    const enabled = await isFeatureEnabled(input.companyId);
    if (!enabled) return;  // feature flag OFF — silencio total

    const client = await getClient();
    const occurredAt = input.occurredAt
      ? (typeof input.occurredAt === "string" ? input.occurredAt : input.occurredAt.toISOString())
      : new Date().toISOString();

    if (!client) {
      // Micro no disponible o paquete no instalado → encolar
      await execute(
        `INSERT INTO fiscal."PendingComplianceEvent"
           ("CompanyId","RifEmisor","EventType","ReferenceType","ReferenceId",
            "PayloadJson","OccurredAt","LastError")
         VALUES (@cid, @rif, @et, @rt, @rid, @payload::jsonb, @occurred, @err)`,
        {
          cid: input.companyId,
          rif: input.rifEmisor.toUpperCase(),
          et: input.eventType,
          rt: input.referenceType ?? null,
          rid: input.referenceId ?? null,
          payload: JSON.stringify(input.payload),
          occurred: occurredAt,
          err: "client_not_configured",
        }
      ).catch(() => {});
      return;
    }

    // Fire-and-forget — no await en caller
    void client.publishEvent({
      rifEmisor: input.rifEmisor.toUpperCase(),
      eventType: input.eventType,
      referenceType: input.referenceType,
      referenceId: input.referenceId,
      payload: input.payload,
      occurredAt,
      _companyId: input.companyId,  // se usa en onFailure para encolar
    } as any);
  } catch (err) {
    // Nunca propagar errores — no debe bloquear al ERP
    console.warn("[compliance-adapter] non-blocking error:", err);
  }
}
