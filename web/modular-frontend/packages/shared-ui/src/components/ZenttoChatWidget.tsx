"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import {
  Box, Fab, Paper, Typography, IconButton, TextField,
  CircularProgress, Chip, Collapse,
} from "@mui/material";
import ChatIcon from "@mui/icons-material/Chat";
import CloseIcon from "@mui/icons-material/Close";
import SendIcon from "@mui/icons-material/Send";
import BoltIcon from "@mui/icons-material/Bolt";

const SUPPORT_URL = "https://notify.zentto.net/api/support/chat";
const CONTACT_URL = "https://zentto.net/contacto";
const DOCS_URL = "https://docs.zentto.net";
const SESSION_KEY = "zentto:chat:store:v1";
const SUPPORT_TIMEOUT_MS = 9000;

type Role = "bot" | "user";
type Mode = "support" | "lead" | "fallback";

interface Message { role: Role; text: string; meta?: string; sources?: { url: string; title?: string }[]; }
interface LeadVars { [k: string]: string; }

interface ChatState {
  mode: Mode;
  sessionId: string | null;
  history: Message[];
  leadCurrent: string;
  leadVars: LeadVars;
}

type LeadOption = { label: string; action?: string; goto?: string; sets?: LeadVars; external?: string; };
type LeadStep = { text: string | ((v: LeadVars) => string); options?: LeadOption[]; input?: { var: string; goto: string; type?: string; }; };

const LEAD_FLOW: Record<string, LeadStep> = {
  menu: {
    text: "Puedo ayudarte con documentación y procesos, o dejarte con el equipo comercial.",
    options: [
      { label: "Documentación y procesos", action: "support" },
      { label: "Ver planes", goto: "ask_name", sets: { topic: "sales" } },
      { label: "Agendar demo", goto: "ask_name", sets: { topic: "demo" } },
      { label: "Contactar equipo", external: CONTACT_URL },
    ],
  },
  ask_name: { text: "Perfecto. ¿Cómo te llamas?", input: { var: "name", goto: "ask_email" } },
  ask_email: { text: (v) => `Gracias ${v.name || ""}. ¿A qué email te contactamos?`, input: { var: "email", goto: "ask_company", type: "email" } },
  ask_company: { text: "¿Para qué empresa trabajas? (si no aplica, escribí \"-\")", input: { var: "company", goto: "ask_message" } },
  ask_message: { text: "Contame brevemente qué necesitás.", input: { var: "message", goto: "confirm" } },
  confirm: {
    text: (v) => {
      const parts = [v.name, v.email, v.company !== "-" ? v.company : null].filter(Boolean);
      return `Voy a compartir esto con el equipo: ${parts.join(" · ")}. ¿Lo envío?`;
    },
    options: [
      { label: "Enviar", action: "submit" },
      { label: "Corregir", goto: "ask_name" },
      { label: "Volver al soporte IA", action: "support" },
    ],
  },
  done_ok: {
    text: "Listo. Un especialista te contactará pronto.",
    options: [
      { label: "Volver al soporte IA", action: "support" },
      { label: "Ir a documentación", external: DOCS_URL },
    ],
  },
  done_error: {
    text: "No pude enviar en este momento. Intenta de nuevo más tarde.",
    options: [
      { label: "Volver al soporte IA", action: "support" },
      { label: "Ir a contacto", external: CONTACT_URL },
    ],
  },
};

function loadState(): ChatState {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY);
    if (raw) return JSON.parse(raw);
  } catch (_) {}
  return { mode: "support", sessionId: null, history: [], leadCurrent: "menu", leadVars: {} };
}

function saveState(s: ChatState) {
  try { sessionStorage.setItem(SESSION_KEY, JSON.stringify(s)); } catch (_) {}
}

async function fetchWithTimeout(url: string, opts: RequestInit, ms: number) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ms);
  try {
    const res = await fetch(url, { ...opts, signal: ctrl.signal });
    clearTimeout(timer);
    return res;
  } catch (e) {
    clearTimeout(timer);
    throw e;
  }
}

export default function ZenttoChatWidget() {
  const [open, setOpen] = useState(false);
  const [unread, setUnread] = useState(false);
  const [chat, setChat] = useState<ChatState>(() => ({ mode: "support", sessionId: null, history: [], leadCurrent: "menu", leadVars: {} }));
  const [options, setOptions] = useState<LeadOption[]>([]);
  const [inputVal, setInputVal] = useState("");
  const [inputDisabled, setInputDisabled] = useState(false);
  const [inputType, setInputType] = useState<"text" | "email">("text");
  const [loading, setLoading] = useState(false);
  const [statusLabel, setStatusLabel] = useState("Soporte IA");
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const stateRef = useRef(chat);
  stateRef.current = chat;

  useEffect(() => {
    const loaded = loadState();
    setChat(loaded);
    if (loaded.history.length === 0) {
      const timer = setTimeout(() => setUnread(true), 10000);
      return () => clearTimeout(timer);
    }
  }, []);

  useEffect(() => {
    if (open) messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chat.history, open, loading]);

  const pushMessage = useCallback((role: Role, text: string, meta?: string, sources?: Message["sources"]) => {
    setChat((prev) => {
      const next = { ...prev, history: [...prev.history, { role, text, meta, sources: sources ?? [] }] };
      saveState(next);
      return next;
    });
  }, []);

  const updateChat = useCallback((updater: (s: ChatState) => ChatState) => {
    setChat((prev) => {
      const next = updater(prev);
      saveState(next);
      return next;
    });
  }, []);

  const showMenu = useCallback((initial: boolean) => {
    setStatusLabel("Soporte IA");
    setInputDisabled(false);
    setOptions(LEAD_FLOW.menu.options!);
    if (initial) {
      pushMessage("bot", "Hola. Soy el asistente de Zentto Store. Puedo ayudarte con dudas de pedidos, devoluciones y más.");
    }
  }, [pushMessage]);

  const goToStep = useCallback((stepId: string, vars: LeadVars) => {
    const step = LEAD_FLOW[stepId];
    if (!step) return;
    updateChat((s) => ({ ...s, mode: "lead", leadCurrent: stepId }));
    setStatusLabel("Equipo Zentto");
    const text = typeof step.text === "function" ? step.text(vars) : step.text;
    pushMessage("bot", text);
    if (step.options) {
      setInputDisabled(true);
      setOptions(step.options);
    } else if (step.input) {
      setInputDisabled(false);
      setInputType((step.input.type as "email" | "text") ?? "text");
      setOptions([]);
    }
  }, [pushMessage, updateChat]);

  const activateSupport = useCallback(() => {
    updateChat((s) => ({ ...s, mode: "support" }));
    setStatusLabel("Soporte IA");
    setInputDisabled(false);
    setOptions([]);
    pushMessage("bot", "Perfecto. Hazme tu pregunta sobre pedidos, envíos, devoluciones o cómo funciona Zentto Store.");
  }, [pushMessage, updateChat]);

  const submitLead = useCallback(async (vars: LeadVars) => {
    setLoading(true);
    try {
      const clean = (v?: string) => { const s = (v || "").trim(); return s === "" || s === "-" ? null : s; };
      const res = await fetch("https://zentto.net/api/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: vars.email, name: vars.name,
          company: clean(vars.company), message: clean(vars.message),
          topic: vars.topic || "store-support", source: "chat-widget-store",
        }),
      });
      setLoading(false);
      goToStep(res.ok ? "done_ok" : "done_error", vars);
    } catch (_) {
      setLoading(false);
      goToStep("done_error", vars);
    }
  }, [goToStep]);

  const handleOption = useCallback((opt: LeadOption) => {
    if (opt.external) { window.open(opt.external, "_blank", "noreferrer"); return; }
    pushMessage("user", opt.label);
    if (opt.action === "support") { activateSupport(); return; }
    const newVars = { ...stateRef.current.leadVars, ...(opt.sets ?? {}) };
    updateChat((s) => ({ ...s, leadVars: newVars }));
    if (opt.action === "submit") { submitLead(newVars); return; }
    if (opt.goto) goToStep(opt.goto, newVars);
  }, [pushMessage, activateSupport, updateChat, submitLead, goToStep]);

  const sendSupport = useCallback(async (text: string) => {
    if (!text.trim()) return;
    setLoading(true);
    setOptions([]);
    try {
      const s = stateRef.current;
      const res = await fetchWithTimeout(SUPPORT_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sessionId: s.sessionId || undefined,
          message: text,
          locale: "es",
          pageUrl: window.location.href,
          visitorType: "anonymous",
          appContext: "store",
        }),
      }, SUPPORT_TIMEOUT_MS);
      const payload = await res.json();
      setLoading(false);
      if (!res.ok || payload.ok !== true) throw new Error("support_failed");
      if (payload.sessionId) updateChat((st) => ({ ...st, sessionId: payload.sessionId }));
      const meta = payload.status === "answered"
        ? `confianza ${Math.round((payload.confidence || 0) * 100)}%`
        : "Escalado sugerido";
      pushMessage("bot", payload.answer || "No encontré una respuesta concluyente.", meta, payload.sources);
      setOptions([
        { label: "Otra pregunta", action: "support" },
        { label: "Ver documentación", external: DOCS_URL },
        { label: "Hablar con el equipo", goto: "ask_name", sets: { topic: "support" } },
      ]);
    } catch (_) {
      setLoading(false);
      pushMessage("bot", "No pude responder en este momento. ¿Quieres que te contacte el equipo?");
      updateChat((s) => ({ ...s, mode: "lead" }));
      setStatusLabel("fallback");
      setOptions([
        { label: "Hablar con el equipo", goto: "ask_name", sets: { topic: "support" } },
        { label: "Ir a contacto", external: CONTACT_URL },
      ]);
    }
  }, [pushMessage, updateChat]);

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault();
    const text = inputVal.trim();
    if (!text || inputDisabled) return;
    setInputVal("");
    const s = stateRef.current;
    if (s.mode === "lead") {
      const step = LEAD_FLOW[s.leadCurrent];
      if (step?.input) {
        const newVars = { ...s.leadVars, [step.input.var]: text };
        updateChat((st) => ({ ...st, leadVars: newVars }));
        pushMessage("user", text);
        goToStep(step.input.goto, newVars);
      }
      return;
    }
    pushMessage("user", text);
    sendSupport(text);
  }, [inputVal, inputDisabled, pushMessage, sendSupport, goToStep, updateChat]);

  const handleOpen = useCallback(() => {
    setOpen(true);
    setUnread(false);
    if (chat.history.length === 0) showMenu(true);
  }, [chat.history.length, showMenu]);

  return (
    <>
      {/* FAB */}
      <Box sx={{ position: "fixed", bottom: 24, right: 24, zIndex: 1400 }}>
        <Fab
          onClick={() => open ? setOpen(false) : handleOpen()}
          sx={{
            bgcolor: "#6C63FF", color: "#fff", textTransform: "none", gap: 1,
            "&:hover": { bgcolor: "#5b54e6" },
            pl: open ? 2 : { xs: 0, sm: 2 },
            pr: open ? 2 : { xs: 0, sm: 2 },
            width: open ? "auto" : { xs: 56, sm: "auto" },
            borderRadius: "28px",
          }}
          variant="extended"
        >
          {open ? <CloseIcon sx={{ fontSize: 20 }} /> : <ChatIcon sx={{ fontSize: 20 }} />}
          <Box component="span" sx={{ display: { xs: "none", sm: "inline" }, ml: 0.5, fontSize: 14, fontWeight: 600 }}>
            {open ? "Cerrar" : "Habla con Zentto"}
          </Box>
          {unread && !open && (
            <Box sx={{ position: "absolute", top: 6, right: 6, width: 10, height: 10, borderRadius: "50%", bgcolor: "#FFB547", border: "2px solid #6C63FF" }} />
          )}
        </Fab>
      </Box>

      {/* Panel */}
      <Collapse in={open} timeout={200}>
        <Paper
          elevation={8}
          sx={{
            position: "fixed", bottom: 90, right: 24, zIndex: 1399,
            width: { xs: "calc(100vw - 40px)", sm: 380 },
            height: { xs: "calc(100vh - 120px)", sm: 520 },
            maxHeight: 520,
            borderRadius: 3,
            display: "flex", flexDirection: "column", overflow: "hidden",
          }}
        >
          {/* Header */}
          <Box sx={{ background: "linear-gradient(135deg,#6C63FF,#5b54e6)", color: "#fff", px: 2, py: 1.5, display: "flex", alignItems: "center", gap: 1.5 }}>
            <Box sx={{ width: 36, height: 36, borderRadius: "50%", bgcolor: "rgba(255,255,255,.15)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
              <BoltIcon sx={{ fontSize: 18 }} />
            </Box>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <Typography variant="body2" fontWeight={700} fontSize={13}>Zentto Assistant</Typography>
                <Chip label={statusLabel} size="small" sx={{ height: 18, fontSize: 10, bgcolor: "rgba(16,185,129,.2)", color: "#6EE7B7", "& .MuiChip-label": { px: 1 } }} />
              </Box>
              <Typography variant="caption" sx={{ color: "rgba(255,255,255,.75)", fontSize: 11 }}>Soporte de Zentto Store</Typography>
            </Box>
            <IconButton size="small" onClick={() => setOpen(false)} sx={{ color: "#fff" }}>
              <CloseIcon fontSize="small" />
            </IconButton>
          </Box>

          {/* Messages */}
          <Box sx={{ flex: 1, overflowY: "auto", p: 1.5, bgcolor: "#f9fafb", display: "flex", flexDirection: "column", gap: 1 }}>
            {chat.history.map((msg, i) => (
              <Box key={i} sx={{ display: "flex", alignItems: "flex-end", gap: 1, justifyContent: msg.role === "user" ? "flex-end" : "flex-start" }}>
                {msg.role === "bot" && (
                  <Box sx={{ width: 26, height: 26, borderRadius: "50%", bgcolor: "#6C63FF", color: "#fff", fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>Z</Box>
                )}
                <Box sx={{
                  maxWidth: "82%", px: 1.5, py: 1, borderRadius: 3,
                  borderBottomLeftRadius: msg.role === "bot" ? 4 : 12,
                  borderBottomRightRadius: msg.role === "user" ? 4 : 12,
                  bgcolor: msg.role === "bot" ? "#fff" : "#6C63FF",
                  color: msg.role === "bot" ? "#374151" : "#fff",
                  border: msg.role === "bot" ? "1px solid #e5e7eb" : "none",
                  fontSize: 13, whiteSpace: "pre-line",
                }}>
                  {msg.text}
                  {msg.meta && <Box sx={{ fontSize: 10, mt: 0.5, opacity: .6 }}>{msg.meta}</Box>}
                  {msg.sources?.map((s, si) => (
                    <Box key={si} component="a" href={s.url} target="_blank" rel="noreferrer" sx={{ display: "block", fontSize: 11, color: "#6C63FF", mt: 0.5, textDecoration: "none", "&:hover": { textDecoration: "underline" } }}>
                      {s.title || s.url}
                    </Box>
                  ))}
                </Box>
                {msg.role === "user" && (
                  <Box sx={{ width: 26, height: 26, borderRadius: "50%", bgcolor: "#10B981", color: "#fff", fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>T</Box>
                )}
              </Box>
            ))}
            {loading && (
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <Box sx={{ width: 26, height: 26, borderRadius: "50%", bgcolor: "#6C63FF", color: "#fff", fontSize: 11, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" }}>Z</Box>
                <CircularProgress size={16} sx={{ color: "#6C63FF" }} />
              </Box>
            )}
            <div ref={messagesEndRef} />
          </Box>

          {/* Options */}
          {options.length > 0 && (
            <Box sx={{ px: 1.5, py: 1, bgcolor: "#fff", display: "flex", flexWrap: "wrap", gap: 0.75, borderTop: "1px solid #e5e7eb" }}>
              {options.map((opt) => (
                <Chip
                  key={opt.label}
                  label={opt.label}
                  size="small"
                  onClick={() => handleOption(opt)}
                  variant="outlined"
                  sx={{ fontSize: 11, color: "#6C63FF", borderColor: "#6C63FF44", cursor: "pointer", "&:hover": { bgcolor: "#6C63FF", color: "#fff" } }}
                />
              ))}
            </Box>
          )}

          {/* Input */}
          <Box component="form" onSubmit={handleSubmit} sx={{ px: 1.5, py: 1, bgcolor: "#fff", display: "flex", gap: 1, borderTop: "1px solid #e5e7eb" }}>
            <TextField
              size="small" fullWidth
              type={inputType}
              value={inputVal}
              onChange={(e) => setInputVal(e.target.value)}
              disabled={inputDisabled}
              placeholder={inputDisabled ? "Selecciona una opción" : "Escribe tu pregunta…"}
              sx={{ "& .MuiOutlinedInput-root": { borderRadius: 2, fontSize: 13 } }}
            />
            <IconButton type="submit" disabled={inputDisabled || !inputVal.trim()} sx={{ bgcolor: "#6C63FF", color: "#fff", borderRadius: 2, "&:hover": { bgcolor: "#5b54e6" }, "&.Mui-disabled": { bgcolor: "#e5e7eb" } }}>
              <SendIcon sx={{ fontSize: 18 }} />
            </IconButton>
          </Box>
          <Typography variant="caption" sx={{ textAlign: "center", fontSize: 10, color: "#9ca3af", py: 0.5, bgcolor: "#fff" }}>
            Powered by{" "}
            <Box component="a" href="https://zentto.net/productos/notify" target="_blank" rel="noreferrer" sx={{ color: "#6C63FF", textDecoration: "none" }}>
              Zentto Notify
            </Box>
          </Typography>
        </Paper>
      </Collapse>
    </>
  );
}
