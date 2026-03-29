"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Alert,
  Box,
  Chip,
  Drawer,
  Fab,
  IconButton,
  List,
  ListItem,
  ListItemText,
  Snackbar,
  Tooltip,
  Typography,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import ListAltIcon from "@mui/icons-material/ListAlt";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-page-designer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

/* ------------------------------------------------------------------ */
/*  Constantes                                                         */
/* ------------------------------------------------------------------ */

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000";

const MAX_LOG_ENTRIES = 20;
const LOG_DRAWER_WIDTH = 380;

const EVENT_NAMES = [
  "studio-action",
  "studio-submit",
  "studio-navigate",
  "studio-reset",
  "studio-action-start",
  "studio-action-result",
  "schema-change",
  "field-change",
  "field-action",
  "grid-config-change",
] as const;

type StudioEventName = (typeof EVENT_NAMES)[number];

interface LogEntry {
  time: string;
  type: string;
  data: unknown;
}

interface SnackState {
  open: boolean;
  msg: string;
  sev: "success" | "error" | "info" | "warning";
}

/* ------------------------------------------------------------------ */
/*  Colores por tipo de evento (chips)                                 */
/* ------------------------------------------------------------------ */

const chipColor: Record<string, "primary" | "secondary" | "success" | "error" | "info" | "warning" | "default"> = {
  "studio-action": "primary",
  "studio-submit": "success",
  "studio-navigate": "secondary",
  "studio-reset": "warning",
  "studio-action-start": "info",
  "studio-action-result": "info",
  "schema-change": "default",
  "field-change": "default",
  "field-action": "secondary",
  "grid-config-change": "default",
  "api-response": "success",
  "api-error": "error",
};

/* ------------------------------------------------------------------ */
/*  Schema inicial vacío                                               */
/* ------------------------------------------------------------------ */

function blankSchema() {
  return {
    id: `schema-${Date.now()}`,
    version: "1",
    title: "Nuevo Formulario",
    layout: { type: "form", columns: 2 },
    sections: [{ id: "s1", title: "Sección 1", fields: [] }],
  };
}

/* ------------------------------------------------------------------ */
/*  Componente: Panel de log de eventos                                */
/* ------------------------------------------------------------------ */

function EventLogPanel({
  events,
  onClose,
}: {
  events: LogEntry[];
  onClose: () => void;
}) {
  return (
    <Box sx={{ width: LOG_DRAWER_WIDTH, height: "100%", display: "flex", flexDirection: "column" }}>
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          px: 2,
          py: 1,
          borderBottom: 1,
          borderColor: "divider",
        }}
      >
        <Typography variant="subtitle1" fontWeight={600}>
          Event Log
        </Typography>
        <IconButton size="small" onClick={onClose}>
          <CloseIcon fontSize="small" />
        </IconButton>
      </Box>

      {events.length === 0 ? (
        <Box sx={{ p: 2 }}>
          <Typography variant="body2" color="text.secondary">
            Sin eventos registrados.
          </Typography>
        </Box>
      ) : (
        <List dense sx={{ flex: 1, overflowY: "auto" }}>
          {events.map((entry, idx) => (
            <ListItem
              key={`${entry.time}-${idx}`}
              sx={{
                alignItems: "flex-start",
                borderBottom: 1,
                borderColor: "divider",
              }}
            >
              <ListItemText
                primary={
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.5 }}>
                    <Chip
                      label={entry.type}
                      size="small"
                      color={chipColor[entry.type] ?? "default"}
                      variant="outlined"
                    />
                    <Typography variant="caption" color="text.secondary">
                      {entry.time}
                    </Typography>
                  </Box>
                }
                secondary={
                  <Typography
                    component="pre"
                    variant="caption"
                    sx={{
                      whiteSpace: "pre-wrap",
                      wordBreak: "break-all",
                      maxHeight: 120,
                      overflow: "auto",
                      mt: 0.5,
                      fontSize: "0.7rem",
                      color: "text.secondary",
                    }}
                  >
                    {JSON.stringify(entry.data, null, 2)}
                  </Typography>
                }
              />
            </ListItem>
          ))}
        </List>
      )}
    </Box>
  );
}

/* ------------------------------------------------------------------ */
/*  Página principal                                                   */
/* ------------------------------------------------------------------ */

export default function StudioDesignerPage() {
  const ref = useRef<any>(null);
  const router = useRouter();

  const [ready, setReady] = useState(false);
  const [eventLog, setEventLog] = useState<LogEntry[]>([]);
  const [showLog, setShowLog] = useState(false);
  const [snack, setSnack] = useState<SnackState>({ open: false, msg: "", sev: "info" });

  /* ---- helpers --------------------------------------------------- */

  const pushLog = useCallback((type: string, data: unknown) => {
    setEventLog((prev) =>
      [{ time: new Date().toLocaleTimeString(), type, data }, ...prev].slice(0, MAX_LOG_ENTRIES),
    );
  }, []);

  const toast = useCallback((msg: string, sev: SnackState["sev"] = "info") => {
    setSnack({ open: true, msg, sev });
  }, []);

  /* ---- cargar studio --------------------------------------------- */

  useEffect(() => {
    import("@zentto/studio").then(() => setReady(true));
  }, []);

  /* ---- schema inicial -------------------------------------------- */

  useEffect(() => {
    if (!ready || !ref.current) return;
    ref.current.schema = blankSchema();
  }, [ready]);

  /* ---- escuchar TODOS los eventos -------------------------------- */

  useEffect(() => {
    if (!ready || !ref.current) return;
    const el = ref.current;

    /* -- studio-action (orquestador principal) -- */
    const handleAction = async (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-action", d);

      switch (d.actionType) {
        case "apiCall": {
          if (!d.actionUrl) {
            toast("Acción API sin URL configurada", "warning");
            return;
          }
          const url = d.actionUrl.startsWith("http") ? d.actionUrl : `${API_URL}${d.actionUrl}`;
          try {
            const res = await fetch(url, {
              method: d.actionMethod || "POST",
              headers: { "Content-Type": "application/json" },
              ...(d.actionBody ? { body: JSON.stringify(d.actionBody) } : {}),
            });
            const data = await res.json();
            toast(d.successMessage || `API respondió ${res.status}`, res.ok ? "success" : "warning");
            pushLog("api-response", { status: res.status, data });
          } catch (err: any) {
            toast(d.errorMessage || `Error: ${err.message}`, "error");
            pushLog("api-error", { error: err.message });
          }
          break;
        }
        case "navigate": {
          if (d.navigateTo) {
            toast(`Navegando a ${d.navigateTo}`, "info");
            router.push(d.navigateTo);
          }
          break;
        }
        case "submit": {
          toast("Formulario enviado desde acción", "success");
          break;
        }
        case "reset": {
          toast("Formulario reseteado", "info");
          break;
        }
        case "print": {
          toast("Impresión solicitada", "info");
          break;
        }
        case "custom": {
          toast(`Evento personalizado: ${d.eventName || "sin nombre"}`, "info");
          break;
        }
        default: {
          toast(`Acción: ${d.actionType || "desconocida"}`, "info");
        }
      }
    };

    /* -- studio-submit -- */
    const handleSubmit = async (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-submit", d);

      const endpoint = d.endpoint || d.actionUrl;
      if (endpoint) {
        const url = endpoint.startsWith("http") ? endpoint : `${API_URL}${endpoint}`;
        try {
          const res = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(d.formData ?? d),
          });
          const data = await res.json();
          toast(res.ok ? "Formulario guardado correctamente" : `Error al guardar: ${data.mensaje || res.status}`, res.ok ? "success" : "error");
          pushLog("api-response", { status: res.status, data });
        } catch (err: any) {
          toast(`Error al enviar: ${err.message}`, "error");
          pushLog("api-error", { error: err.message });
        }
      } else {
        toast("Formulario enviado (sin endpoint configurado)", "info");
      }
    };

    /* -- studio-navigate -- */
    const handleNavigate = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-navigate", d);
      if (d.path || d.url) {
        const target = d.path || d.url;
        toast(`Navegando a ${target}`, "info");
        router.push(target);
      } else {
        toast("Evento de navegación recibido", "info");
      }
    };

    /* -- studio-reset -- */
    const handleReset = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-reset", d);
      toast("Formulario limpiado", "info");
    };

    /* -- studio-action-start -- */
    const handleActionStart = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-action-start", d);
      toast(`Acción iniciada: ${d.actionId || d.actionType || ""}`, "info");
    };

    /* -- studio-action-result -- */
    const handleActionResult = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("studio-action-result", d);
      const ok = d.success !== false;
      toast(
        ok
          ? `Acción completada: ${d.actionId || ""}`
          : `Acción fallida: ${d.error || d.actionId || ""}`,
        ok ? "success" : "error",
      );
    };

    /* -- schema-change -- */
    const handleSchemaChange = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("schema-change", d);
      toast("Schema actualizado", "info");
    };

    /* -- field-change -- */
    const handleFieldChange = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("field-change", d);
      toast(`Campo cambiado: ${d.fieldId || d.field || ""}`, "info");
    };

    /* -- field-action -- */
    const handleFieldAction = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("field-action", d);
      toast(`Acción de campo: ${d.action || d.fieldId || ""}`, "info");
    };

    /* -- grid-config-change -- */
    const handleGridConfigChange = (e: Event) => {
      const d = (e as CustomEvent).detail;
      pushLog("grid-config-change", d);
      toast("Configuración del grid actualizada", "info");
    };

    /* -- registrar listeners -- */
    el.addEventListener("studio-action", handleAction);
    el.addEventListener("studio-submit", handleSubmit);
    el.addEventListener("studio-navigate", handleNavigate);
    el.addEventListener("studio-reset", handleReset);
    el.addEventListener("studio-action-start", handleActionStart);
    el.addEventListener("studio-action-result", handleActionResult);
    el.addEventListener("schema-change", handleSchemaChange);
    el.addEventListener("field-change", handleFieldChange);
    el.addEventListener("field-action", handleFieldAction);
    el.addEventListener("grid-config-change", handleGridConfigChange);

    return () => {
      el.removeEventListener("studio-action", handleAction);
      el.removeEventListener("studio-submit", handleSubmit);
      el.removeEventListener("studio-navigate", handleNavigate);
      el.removeEventListener("studio-reset", handleReset);
      el.removeEventListener("studio-action-start", handleActionStart);
      el.removeEventListener("studio-action-result", handleActionResult);
      el.removeEventListener("schema-change", handleSchemaChange);
      el.removeEventListener("field-change", handleFieldChange);
      el.removeEventListener("field-action", handleFieldAction);
      el.removeEventListener("grid-config-change", handleGridConfigChange);
    };
  }, [ready, pushLog, toast, router]);

  /* ---- render ---------------------------------------------------- */

  if (!ready) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "80vh" }}>
        <Typography>Cargando Studio Designer...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", height: "calc(100vh - 64px)", position: "relative" }}>
      {/* Designer principal */}
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <zs-page-designer
          ref={ref}
          save-api-url={API_URL}
          style={{ display: "block", width: "100%", height: "100%" }}
        />
      </Box>

      {/* Panel lateral de Event Log */}
      <Drawer
        variant="persistent"
        anchor="right"
        open={showLog}
        sx={{
          "& .MuiDrawer-paper": {
            width: LOG_DRAWER_WIDTH,
            position: "relative",
            border: "none",
            borderLeft: 1,
            borderColor: "divider",
          },
        }}
      >
        <EventLogPanel events={eventLog} onClose={() => setShowLog(false)} />
      </Drawer>

      {/* FAB para abrir/cerrar log */}
      <Tooltip title={showLog ? "Cerrar Event Log" : "Abrir Event Log"} placement="left">
        <Fab
          size="small"
          color="primary"
          onClick={() => setShowLog((v) => !v)}
          sx={{ position: "fixed", bottom: 24, right: showLog ? LOG_DRAWER_WIDTH + 16 : 24, zIndex: 1300, transition: "right 225ms ease" }}
        >
          <ListAltIcon />
        </Fab>
      </Tooltip>

      {/* Snackbar de notificaciones */}
      <Snackbar
        open={snack.open}
        autoHideDuration={3000}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "left" }}
      >
        <Alert
          onClose={() => setSnack((s) => ({ ...s, open: false }))}
          severity={snack.sev}
          variant="filled"
          sx={{ width: "100%" }}
        >
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
}
