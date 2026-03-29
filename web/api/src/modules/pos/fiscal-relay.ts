/**
 * fiscal-relay.ts
 *
 * Relay WebSocket entre la API y el Zentto Fiscal Agent instalado en la
 * maquina del cliente. El agente conecta hacia afuera (outbound) a
 * wss://api.zentto.net/ws/fiscal-relay, evitando problemas de firewall.
 *
 * Flujo:
 *   1. Agente .NET conecta vía WS y se registra con { companyId, cashRegisterId, agentToken }
 *   2. API valida el token en cfg.AppSetting
 *   3. Frontend llama POST /v1/pos/fiscal/print → API busca la conexión activa
 *   4. API envía el comando JSON por WS → Agente ejecuta localmente → responde
 *   5. API retorna la respuesta al frontend
 */

import { WebSocketServer, WebSocket } from "ws";
import type { Server } from "node:http";
import { randomUUID } from "node:crypto";
import { callSp } from "../../db/query.js";

// ── Tipos de mensajes del protocolo ──────────────────────────────────────────

interface RegisterMsg {
  type: "register";
  companyId: number;
  cashRegisterId: string;
  agentToken: string;
}

interface ResponseMsg {
  type: "response";
  id: string;
  status: number;
  data: unknown;
}

interface PingMsg { type: "ping"; }

type AgentMessage = RegisterMsg | ResponseMsg | PingMsg;

// ── Estado interno ────────────────────────────────────────────────────────────

interface AgentConnection {
  ws: WebSocket;
  companyId: number;
  cashRegisterId: string;
  connectedAt: Date;
  lastPing: Date;
}

interface PendingCommand {
  resolve: (val: { status: number; data: unknown }) => void;
  reject: (err: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

/** Map clave: `${companyId}:${cashRegisterId}` */
const connections = new Map<string, AgentConnection>();

/** Promises pendientes de respuesta del agente */
const pendingCommands = new Map<string, PendingCommand>();

function agentKey(companyId: number, cashRegisterId: string): string {
  return `${companyId}:${String(cashRegisterId || "DEFAULT").toUpperCase()}`;
}

// ── Validación de token ───────────────────────────────────────────────────────

async function validateAgentToken(companyId: number, token: string): Promise<boolean> {
  if (!token || token.length < 16) return false;
  try {
    const rows = await callSp<{ SettingKey: string; SettingValue: string }>(
      "usp_Cfg_AppSetting_ListByModule",
      { CompanyId: companyId, Module: "pos" }
    );
    const setting = rows.find((r) => r.SettingKey === "fiscalAgentToken");
    return setting?.SettingValue === token;
  } catch {
    return false;
  }
}

// ── WebSocket Server ──────────────────────────────────────────────────────────

export function attachFiscalRelayWs(httpServer: Server): void {
  const wss = new WebSocketServer({ server: httpServer, path: "/ws/fiscal-relay" });

  wss.on("connection", (ws: WebSocket) => {
    let registeredKey: string | null = null;

    // Heartbeat: detectar conexiones muertas
    const heartbeat = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) ws.ping();
    }, 30_000);

    ws.on("pong", () => {
      if (registeredKey) {
        const conn = connections.get(registeredKey);
        if (conn) conn.lastPing = new Date();
      }
    });

    ws.on("message", async (raw: Buffer) => {
      let msg: AgentMessage;
      try {
        msg = JSON.parse(raw.toString()) as AgentMessage;
      } catch {
        send(ws, { type: "error", message: "invalid_json" });
        return;
      }

      if (msg.type === "ping") {
        send(ws, { type: "pong" });
        return;
      }

      if (msg.type === "register") {
        const valid = await validateAgentToken(msg.companyId, msg.agentToken);
        if (!valid) {
          send(ws, { type: "error", message: "invalid_token" });
          ws.close(1008, "unauthorized");
          return;
        }

        const key = agentKey(msg.companyId, msg.cashRegisterId);

        // Cerrar conexión previa si ya existía (reconexión del mismo agente)
        const existing = connections.get(key);
        if (existing?.ws.readyState === WebSocket.OPEN) {
          existing.ws.close(1001, "replaced_by_new_connection");
        }

        connections.set(key, {
          ws,
          companyId: msg.companyId,
          cashRegisterId: msg.cashRegisterId,
          connectedAt: new Date(),
          lastPing: new Date(),
        });

        registeredKey = key;
        send(ws, { type: "registered", ok: true });
        console.log(`[fiscal-relay] Agente conectado: ${key}`);
        return;
      }

      if (msg.type === "response") {
        const pending = pendingCommands.get(msg.id);
        if (pending) {
          clearTimeout(pending.timer);
          pendingCommands.delete(msg.id);
          pending.resolve({ status: msg.status, data: msg.data });
        }
        return;
      }
    });

    ws.on("close", () => {
      clearInterval(heartbeat);
      if (registeredKey) {
        connections.delete(registeredKey);
        console.log(`[fiscal-relay] Agente desconectado: ${registeredKey}`);
      }
    });

    ws.on("error", (err) => {
      console.error("[fiscal-relay] WS error:", err.message);
    });
  });

  console.log("[fiscal-relay] WebSocket server escuchando en /ws/fiscal-relay");
}

// ── API pública del relay ─────────────────────────────────────────────────────

/**
 * Envía un comando al agente fiscal vía WebSocket y espera la respuesta.
 * Retorna null si no hay agente conectado.
 * Lanza Error si hay timeout.
 */
export async function sendFiscalCommand(
  companyId: number,
  cashRegisterId: string,
  path: string,
  method: "GET" | "POST",
  payload: unknown,
  timeoutMs = 60_000
): Promise<{ status: number; data: unknown } | null> {
  const key = agentKey(companyId, cashRegisterId);
  const conn = connections.get(key);

  if (!conn || conn.ws.readyState !== WebSocket.OPEN) {
    return null; // sin agente — el caller decide el fallback
  }

  const id = randomUUID();
  const command = { type: "command", id, path, method, payload };

  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pendingCommands.delete(id);
      reject(new Error("agent_timeout"));
    }, timeoutMs);

    pendingCommands.set(id, { resolve, reject, timer });
    conn.ws.send(JSON.stringify(command));
  });
}

/** Verifica si hay un agente conectado para esta empresa/caja */
export function isAgentConnected(companyId: number, cashRegisterId: string): boolean {
  const key = agentKey(companyId, cashRegisterId);
  const conn = connections.get(key);
  return conn?.ws.readyState === WebSocket.OPEN;
}

/** Lista los agentes conectados de una empresa (para UI de administración) */
export function listConnectedAgents(companyId: number) {
  return Array.from(connections.values())
    .filter((c) => c.companyId === companyId)
    .map((c) => ({
      cashRegisterId: c.cashRegisterId,
      connectedAt: c.connectedAt,
      lastPing: c.lastPing,
    }));
}

// ── Helper interno ────────────────────────────────────────────────────────────

function send(ws: WebSocket, msg: object): void {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}
