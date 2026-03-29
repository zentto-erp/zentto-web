/**
 * hetzner.provider.ts — Provisiona servidor en Hetzner Cloud via API REST
 */

const HETZNER_API = "https://api.hetzner.cloud/v1";
const POLL_INTERVAL_MS = 5_000;
const TIMEOUT_MS = 10 * 60 * 1000; // 10 minutos

export async function provisionHetzner(
  apiToken: string,
  name: string,
  serverType: string = "cx22",
  location: string = "nbg1"
): Promise<{ serverIp: string; serverId: string }> {
  const headers = {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${apiToken}`,
  };

  // Crear servidor
  const createRes = await fetch(`${HETZNER_API}/servers`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      name,
      server_type: serverType,
      location,
      image: "ubuntu-22.04",
      start_after_create: true,
    }),
  });

  if (!createRes.ok) {
    const body = await createRes.text().catch(() => "");
    throw new Error(`[hetzner] Error al crear servidor (${createRes.status}): ${body}`);
  }

  const createJson = await createRes.json() as {
    server: { id: number; public_net: { ipv4: { ip: string } }; status: string };
  };

  const serverId = String(createJson.server.id);
  const deadline = Date.now() + TIMEOUT_MS;

  // Polling hasta status=running
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));

    const statusRes = await fetch(`${HETZNER_API}/servers/${serverId}`, { headers });
    if (!statusRes.ok) continue;

    const statusJson = await statusRes.json() as {
      server: { status: string; public_net: { ipv4: { ip: string } } };
    };

    const status = statusJson.server?.status;
    if (status === "running") {
      const serverIp = statusJson.server.public_net.ipv4.ip;
      console.log(`[hetzner] Servidor ${serverId} listo: IP=${serverIp}`);
      return { serverIp, serverId };
    }

    if (status === "off" || status === "deleting" || status === "rebuilding") {
      throw new Error(`[hetzner] Servidor ${serverId} en estado inesperado: ${status}`);
    }

    console.log(`[hetzner] Servidor ${serverId} status=${status} — esperando...`);
  }

  throw new Error(`[hetzner] Timeout esperando que el servidor ${serverId} quede running`);
}
