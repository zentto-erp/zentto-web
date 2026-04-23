"use client";

/**
 * ContactFormClient — form interactivo de la sección de contacto.
 *
 * Separado del adapter Server Component para que la página se mantenga SSG.
 * Los estados locales (loading, success, error) viven solo en client.
 *
 * Hoy: POST al `submitEndpoint` con JSON estándar. Si no hay endpoint
 * configurado, simula éxito tras 800ms (demo mode, útil para pilotos antes
 * de que el backend `/v1/public/cms/contact/submit` exista).
 *
 * Futuro: extender para incluir reCAPTCHA + honeypot (ver spec del designer).
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import TextField from "@mui/material/TextField";
import Button from "@mui/material/Button";
import MenuItem from "@mui/material/MenuItem";
import Alert from "@mui/material/Alert";
import CircularProgress from "@mui/material/CircularProgress";
import type { LandingTokens } from "../../tokens";

export interface ContactFormClientProps {
  tokens: LandingTokens;
  submitEndpoint?: string;
  /** Vertical a mandar en el body del submit — resuelve scoping en backend. */
  vertical?: string;
  /** Slug de la página de origen — default "contacto". */
  slug?: string;
  subjects: string[];
  submitLabel: string;
  successMessage: string;
}

type FormState = "idle" | "submitting" | "success" | "error";

export function ContactFormClient({
  tokens,
  submitEndpoint,
  vertical,
  slug,
  subjects,
  submitLabel,
  successMessage,
}: ContactFormClientProps) {
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  const [subject, setSubject] = React.useState(subjects[0] ?? "");
  const [message, setMessage] = React.useState("");
  const [state, setState] = React.useState<FormState>("idle");
  const [errorMsg, setErrorMsg] = React.useState("");
  // Honeypot — bots suelen rellenar cualquier input. Si esto no está vacío
  // rechazamos silenciosamente con "success" para no dar feedback.
  const [website, setWebsite] = React.useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (state === "submitting") return;

    if (website) {
      // Honeypot triggered — finge éxito.
      setState("success");
      return;
    }
    if (!name.trim() || !email.trim() || !message.trim()) {
      setState("error");
      setErrorMsg("Completa nombre, email y mensaje.");
      return;
    }

    setState("submitting");
    setErrorMsg("");

    try {
      if (submitEndpoint) {
        const res = await fetch(submitEndpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({
            name,
            email,
            subject,
            message,
            vertical: vertical ?? "corporate",
            slug: slug ?? "contacto",
          }),
        });
        if (!res.ok) {
          // El backend responde `{ ok: false, error: "..." }`. Mapeamos los
          // errores conocidos a mensajes legibles; el resto → mensaje genérico.
          let errBody: { error?: string } | null = null;
          try {
            errBody = await res.json();
          } catch {
            // no JSON response
          }
          const errCode = errBody?.error ?? `HTTP ${res.status}`;
          const MSG_MAP: Record<string, string> = {
            invalid_body: "Completa los campos requeridos.",
            email_invalid: "Email con formato inválido.",
            name_required: "El nombre es obligatorio.",
            message_required: "Escribe un mensaje.",
            tenant_required: "No pudimos identificar tu organización.",
            rate_limited: "Demasiados envíos. Intenta en 1 minuto.",
          };
          throw new Error(MSG_MAP[errCode] ?? "No pudimos enviar el mensaje.");
        }
      } else {
        // Demo mode: sin endpoint configurado, simulamos latencia.
        await new Promise((r) => setTimeout(r, 800));
      }
      setState("success");
      setName("");
      setEmail("");
      setMessage("");
    } catch (err) {
      setState("error");
      setErrorMsg(
        err instanceof Error
          ? err.message
          : "No pudimos enviar el mensaje. Intenta nuevamente.",
      );
    }
  }

  if (state === "success") {
    return (
      <Alert
        severity="success"
        sx={{
          borderRadius: 2,
          fontSize: "1rem",
          py: 2,
        }}
      >
        {successMessage}
      </Alert>
    );
  }

  return (
    <Box component="form" onSubmit={handleSubmit} noValidate>
      {/* Honeypot escondido */}
      <Box
        component="input"
        type="text"
        name="website"
        autoComplete="off"
        tabIndex={-1}
        value={website}
        onChange={(e) => setWebsite((e.target as HTMLInputElement).value)}
        sx={{
          position: "absolute",
          left: "-10000px",
          top: "auto",
          width: 1,
          height: 1,
          overflow: "hidden",
        }}
      />

      <Stack spacing={2}>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
          <TextField
            required
            fullWidth
            label="Nombre"
            value={name}
            onChange={(e) => setName(e.target.value)}
            disabled={state === "submitting"}
          />
          <TextField
            required
            fullWidth
            type="email"
            label="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={state === "submitting"}
          />
        </Stack>

        {subjects.length > 0 && (
          <TextField
            select
            fullWidth
            label="Tema"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            disabled={state === "submitting"}
          >
            {subjects.map((s) => (
              <MenuItem key={s} value={s}>
                {s}
              </MenuItem>
            ))}
          </TextField>
        )}

        <TextField
          required
          fullWidth
          multiline
          minRows={4}
          label="Mensaje"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          disabled={state === "submitting"}
        />

        {state === "error" && errorMsg && (
          <Alert severity="error" sx={{ borderRadius: 2 }}>
            {errorMsg}
          </Alert>
        )}

        <Box>
          <Button
            type="submit"
            variant="contained"
            disabled={state === "submitting"}
            sx={{
              bgcolor: tokens.color.brand,
              color: "#fff",
              fontWeight: 700,
              textTransform: "none",
              borderRadius: 2,
              px: 4,
              py: 1.25,
              fontSize: "1rem",
              "&:hover": { bgcolor: tokens.color.brandStrong ?? tokens.color.brand },
            }}
            startIcon={
              state === "submitting" ? (
                <CircularProgress size={16} sx={{ color: "#fff" }} />
              ) : undefined
            }
          >
            {state === "submitting" ? "Enviando…" : submitLabel}
          </Button>
        </Box>
      </Stack>
    </Box>
  );
}
