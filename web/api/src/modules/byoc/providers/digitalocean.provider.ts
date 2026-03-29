/**
 * digitalocean.provider.ts — Provisiona Droplet en DigitalOcean via API REST
 */

const DO_API = "https://api.digitalocean.com/v2";
const POLL_INTERVAL_MS = 5_000;
const TIMEOUT_MS = 10 * 60 * 1000; // 10 minutos

export async function provisionDigitalOcean(
  apiToken: string,
  name: string,
  size: string = "s-2vcpu-4gb",
  region: string = "nyc3"
): Promise<{ serverIp: string; dropletId: number }> {
  const headers = {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${apiToken}`,
  };

  // Crear droplet
  const createRes = await fetch(`${DO_API}/droplets`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      name,
      region,
      size,
      image: "ubuntu-22-04-x64",
      backups: false,
      ipv6: false,
    }),
  });

  if (!createRes.ok) {
    const body = await createRes.text().catch(() => "");
    throw new Error(`[digitalocean] Error al crear droplet (${createRes.status}): ${body}`);
  }

  const createJson = await createRes.json() as { droplet: { id: number; status: string } };
  const dropletId = createJson.droplet.id;
  const deadline = Date.now() + TIMEOUT_MS;

  // Polling hasta status=active con IP asignada
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));

    const statusRes = await fetch(`${DO_API}/droplets/${dropletId}`, { headers });
    if (!statusRes.ok) continue;

    const statusJson = await statusRes.json() as {
      droplet: {
        id: number;
        status: string;
        networks: { v4: Array<{ ip_address: string; type: string }> };
      };
    };

    const droplet = statusJson.droplet;
    if (droplet.status === "active") {
      const publicNet = droplet.networks.v4.find((n) => n.type === "public");
      if (publicNet?.ip_address) {
        console.log(`[digitalocean] Droplet ${dropletId} listo: IP=${publicNet.ip_address}`);
        return { serverIp: publicNet.ip_address, dropletId };
      }
    }

    if (droplet.status === "errored") {
      throw new Error(`[digitalocean] Droplet ${dropletId} en estado errored`);
    }

    console.log(`[digitalocean] Droplet ${dropletId} status=${droplet.status} — esperando...`);
  }

  throw new Error(`[digitalocean] Timeout esperando que el droplet ${dropletId} quede active`);
}
