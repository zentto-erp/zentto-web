/**
 * cloudflare.client.ts — Operaciones DNS via Cloudflare API v4
 * Crea/elimina registros DNS para subdominios de tenants en zentto.net
 */

const CF_API = "https://api.cloudflare.com/client/v4";
const SERVER_IP = "178.104.56.185";

function getHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "X-Auth-Email": process.env.CLOUDFLARE_EMAIL ?? "",
    "X-Auth-Key":   process.env.CLOUDFLARE_API_KEY ?? "",
  };
}

/**
 * Crea un registro A proxied para {subdomain}.zentto.net → SERVER_IP
 * Idempotente: si ya existe, no falla.
 * REGLA: proxied: true siempre (sino SSL falla con Cloudflare)
 */
export async function createSubdomainDns(subdomain: string): Promise<{ ok: boolean; error?: string }> {
  const zoneId = process.env.CLOUDFLARE_ZONE_ID;
  if (!zoneId || !process.env.CLOUDFLARE_API_KEY || !process.env.CLOUDFLARE_EMAIL) {
    console.warn("[cloudflare] Variables CF no configuradas — DNS no creado para", subdomain);
    return { ok: false, error: "cloudflare_not_configured" };
  }

  const name = `${subdomain}.zentto.net`;

  try {
    // Verificar si ya existe
    const listRes = await fetch(
      `${CF_API}/zones/${zoneId}/dns_records?type=A&name=${encodeURIComponent(name)}`,
      { headers: getHeaders() }
    );
    const listJson = await listRes.json() as { result: Array<{ id: string }> };
    if (listJson.result?.length > 0) {
      console.log(`[cloudflare] DNS ya existe para ${name} — omitiendo`);
      return { ok: true };
    }

    // Crear registro A proxied
    const createRes = await fetch(`${CF_API}/zones/${zoneId}/dns_records`, {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        type:    "A",
        name,
        content: SERVER_IP,
        ttl:     1,       // auto TTL (Cloudflare managed)
        proxied: true,    // OBLIGATORIO: proxied=true para SSL
      }),
    });
    const createJson = await createRes.json() as { success: boolean; errors?: Array<{ message: string }> };

    if (!createJson.success) {
      const errMsg = createJson.errors?.map(e => e.message).join(", ") ?? "unknown";
      console.error(`[cloudflare] Error creando DNS para ${name}:`, errMsg);
      return { ok: false, error: errMsg };
    }

    console.log(`[cloudflare] DNS A creado: ${name} → ${SERVER_IP} (proxied)`);
    return { ok: true };
  } catch (err: any) {
    console.error(`[cloudflare] Error de red para ${name}:`, err.message);
    return { ok: false, error: err.message };
  }
}

/**
 * Elimina el registro DNS de un subdominio (al cancelar suscripción)
 */
export async function deleteSubdomainDns(subdomain: string): Promise<{ ok: boolean; error?: string }> {
  const zoneId = process.env.CLOUDFLARE_ZONE_ID;
  if (!zoneId || !process.env.CLOUDFLARE_API_KEY || !process.env.CLOUDFLARE_EMAIL) {
    return { ok: false, error: "cloudflare_not_configured" };
  }

  const name = `${subdomain}.zentto.net`;

  try {
    const listRes = await fetch(
      `${CF_API}/zones/${zoneId}/dns_records?type=A&name=${encodeURIComponent(name)}`,
      { headers: getHeaders() }
    );
    const listJson = await listRes.json() as { result: Array<{ id: string }> };

    for (const record of listJson.result ?? []) {
      await fetch(`${CF_API}/zones/${zoneId}/dns_records/${record.id}`, {
        method: "DELETE",
        headers: getHeaders(),
      });
      console.log(`[cloudflare] DNS eliminado: ${name} (id=${record.id})`);
    }
    return { ok: true };
  } catch (err: any) {
    console.error(`[cloudflare] Error eliminando DNS para ${name}:`, err.message);
    return { ok: false, error: err.message };
  }
}
