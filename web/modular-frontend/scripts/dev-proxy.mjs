/**
 * Zentto — Dev Proxy
 *
 * Simula lo que hace Nginx en producción: un solo puerto (3080) que
 * rutea las requests a las micro-apps por path.
 *
 * Esto resuelve el problema de cookies/sesión entre puertos diferentes.
 *
 * Uso: node scripts/dev-proxy.mjs
 *      o: npm run dev:proxy (ejecutar JUNTO con dev:all)
 */
import http from "http";
import httpProxy from "http-proxy";

const PROXY_PORT = 3080;

const routes = {
  "/pos":         3003,
  "/ventas":      3006,
  "/restaurante": 3008,
  "/ecommerce":   3009,
  "/auditoria":   3010,
};

const DEFAULT_PORT = 3000; // Shell

const proxy = httpProxy.createProxyServer({ ws: true });

proxy.on("error", (err, req, res) => {
  console.error(`[proxy] Error: ${err.message} → ${req.url}`);
  if (res.writeHead) {
    res.writeHead(502, { "Content-Type": "text/plain" });
    res.end("Proxy error — app may not be running yet");
  }
});

const server = http.createServer((req, res) => {
  const path = req.url || "/";
  let targetPort = DEFAULT_PORT;

  for (const [prefix, port] of Object.entries(routes)) {
    if (path.startsWith(prefix)) {
      targetPort = port;
      break;
    }
  }

  proxy.web(req, res, { target: `http://127.0.0.1:${targetPort}` });
});

// WebSocket support (HMR)
server.on("upgrade", (req, socket, head) => {
  const path = req.url || "/";
  let targetPort = DEFAULT_PORT;

  for (const [prefix, port] of Object.entries(routes)) {
    if (path.startsWith(prefix)) {
      targetPort = port;
      break;
    }
  }

  proxy.ws(req, socket, head, { target: `http://127.0.0.1:${targetPort}` });
});

server.listen(PROXY_PORT, () => {
  console.log("");
  console.log("  ╔══════════════════════════════════════════╗");
  console.log("  ║  Zentto Dev Proxy — http://localhost:" + PROXY_PORT + "  ║");
  console.log("  ╠══════════════════════════════════════════╣");
  console.log("  ║  /              → Shell     :3000        ║");
  console.log("  ║  /pos/*         → POS       :3003        ║");
  console.log("  ║  /ventas/*      → Ventas    :3006        ║");
  console.log("  ║  /restaurante/* → Restaur.  :3008        ║");
  console.log("  ║  /ecommerce/*   → Ecommerce :3009        ║");
  console.log("  ║  /auditoria/*   → Auditoria :3010        ║");
  console.log("  ╚══════════════════════════════════════════╝");
  console.log("");
  console.log("  Abre http://localhost:" + PROXY_PORT + " para desarrollo");
  console.log("  Las cookies y sesión se comparten entre todas las apps.");
  console.log("");
});
