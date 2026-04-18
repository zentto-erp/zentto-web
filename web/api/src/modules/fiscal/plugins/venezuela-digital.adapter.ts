/**
 * Adapter SENIAT Digital — punto de acoplamiento con zentto-imprenta-seniat.
 *
 * DISEÑO NO BLOQUEANTE:
 *   - Feature flag por tenant (cfg.AppSetting "seniat.digitalEnabled")
 *   - Si flag OFF o cliente retorna null: se marca como PENDING en fiscal.PendingSeniatReceipt
 *   - El ERP SIEMPRE continua su flujo (emite factura con correlativo local)
 *   - Un worker procesa la cola async cuando el micro este disponible
 *
 * Uso esperado:
 *   const status = await submitToSeniatImprenta(companyId, receipt);
 *   // status.ok === true → NCFD asignado; integrar en la factura
 *   // status.ok === false → factura sigue emitida localmente, se reenvia async
 */
import { query, execute } from "../../../db/query.js";

type ImprentaClientLike = {
  submitReceipt: (receipt: any) => Promise<any | null>;
};

let clientInstance: ImprentaClientLike | null = null;
let clientLoadFailed = false;

async function getClient(): Promise<ImprentaClientLike | null> {
  if (clientInstance) return clientInstance;
  if (clientLoadFailed) return null;
  try {
    const baseUrl = process.env.ZENTTO_IMPRENTA_URL;
    const apiKey = process.env.ZENTTO_IMPRENTA_KEY;
    if (!baseUrl || !apiKey) {
      clientLoadFailed = true;
      return null;
    }
    // Dynamic import para no romper build si el paquete no esta instalado aun
    const mod = await import("@zentto/imprenta-client" as any).catch(() => null);
    if (!mod?.ImprentaClient) {
      clientLoadFailed = true;
      return null;
    }
    clientInstance = new mod.ImprentaClient({
      baseUrl, apiKey, timeoutMs: 3000,
      circuitBreaker: { failureThreshold: 5, resetMs: 30_000 },
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
      { companyId, module: "fiscal", key: "seniat.digitalEnabled" }
    );
    return rows[0]?.SettingValue === "true";
  } catch {
    return false;
  }
}

async function enqueuePending(companyId: number, documentId: number | null, payload: Record<string, unknown>, error?: string) {
  try {
    await execute(
      `INSERT INTO fiscal."PendingSeniatReceipt"
         ("CompanyId","DocumentId","PayloadJson","LastError")
       VALUES (@cid, @did, @payload::jsonb, @err)`,
      {
        cid: companyId,
        did: documentId,
        payload: JSON.stringify(payload),
        err: error ?? null,
      }
    );
  } catch (err) {
    console.error("[seniat-digital] enqueue pending failed (non-blocking):", err);
  }
}

export interface SubmitResult {
  ok: boolean;
  ncfd?: string;
  invoiceId?: number;
  hash?: string;
  xml?: string;
  qrData?: string;
  queued: boolean;
  reason?: string;
}

/**
 * Intenta someter una factura al microservicio.
 * SIEMPRE retorna (no lanza). Si falla, la factura queda en cola.
 */
export async function submitToSeniatImprenta(
  companyId: number,
  documentId: number | null,
  receipt: Record<string, unknown>
): Promise<SubmitResult> {
  const enabled = await isFeatureEnabled(companyId);
  if (!enabled) {
    return { ok: false, queued: false, reason: "feature_disabled" };
  }

  const client = await getClient();
  if (!client) {
    await enqueuePending(companyId, documentId, receipt, "client_not_configured");
    return { ok: false, queued: true, reason: "client_not_configured" };
  }

  try {
    const result = await client.submitReceipt(receipt);
    if (!result?.ok) {
      await enqueuePending(companyId, documentId, receipt, "micro_unavailable_or_rejected");
      return { ok: false, queued: true, reason: "micro_unavailable_or_rejected" };
    }
    // Actualizar fiscal.Record con tracking
    if (documentId) {
      try {
        await execute(
          `UPDATE fiscal."Record"
             SET "SeniatDigitalStatus" = 'SENT',
                 "SeniatNCFD" = @ncfd,
                 "SeniatDispatchedAt" = NOW(),
                 "SeniatImprentaInvoiceId" = @invId
           WHERE "RecordId" = @docId`,
          { ncfd: result.ncfd, invId: result.invoiceId, docId: documentId }
        );
      } catch (err) {
        console.warn("[seniat-digital] tracking update failed (non-blocking):", err);
      }
    }
    return {
      ok: true,
      queued: false,
      ncfd: result.ncfd,
      invoiceId: result.invoiceId,
      hash: result.hash,
      xml: result.xml,
      qrData: result.qrData,
    };
  } catch (err: any) {
    await enqueuePending(companyId, documentId, receipt, err?.message ?? "unknown_error");
    return { ok: false, queued: true, reason: err?.message ?? "unknown_error" };
  }
}
