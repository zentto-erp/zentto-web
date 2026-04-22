/**
 * ContactFormAdapter — render de una sección de contacto para páginas
 * corporativas (`cms.Page.PageType = 'contact'`).
 *
 * Server Component stub con el scaffolding visual; la **submisión** se hace
 * en el Client Component `ContactFormClient` (importado dinámicamente) para
 * no romper SSG.
 *
 * Schema esperado (libre, passthrough):
 * ```json
 * {
 *   "type": "contact-form",
 *   "contactFormConfig": {
 *     "eyebrow": "Contacto",
 *     "title": "Hablemos",
 *     "description": "Respondemos en menos de 24h.",
 *     "email": "hola@zentto.net",
 *     "phone": "+58 212 555 1234",
 *     "address": "Caracas, Venezuela",
 *     "submitEndpoint": "/v1/public/cms/contact/submit",
 *     "subjects": ["Ventas", "Soporte", "Prensa"]
 *   }
 * }
 * ```
 *
 * El `submitEndpoint` queda reservado para un endpoint futuro — por ahora el
 * form muestra un estado "enviado" mock para testear flujo visual.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import Link from "@mui/material/Link";
import EmailOutlined from "@mui/icons-material/EmailOutlined";
import PhoneOutlined from "@mui/icons-material/PhoneOutlined";
import LocationOnOutlined from "@mui/icons-material/LocationOnOutlined";
import { SectionShell } from "../../components/SectionShell";
import type { SectionAdapterProps } from "../types";
import { ContactFormClient } from "./ContactFormClient";

interface ContactFormConfig {
  eyebrow?: string;
  title?: string;
  description?: string;
  email?: string;
  phone?: string;
  address?: string;
  submitEndpoint?: string;
  subjects?: string[];
  /** Texto del botón submit. Default: "Enviar mensaje" */
  submitLabel?: string;
  /** Mensaje de éxito. Default: "Gracias, te responderemos pronto." */
  successMessage?: string;
}

export function ContactFormAdapter({ section, tokens }: SectionAdapterProps) {
  const cfg = ((section as unknown as Record<string, unknown>)
    .contactFormConfig ?? {}) as ContactFormConfig;

  return (
    <SectionShell
      tokens={tokens}
      id={section.id ?? "contact"}
      eyebrow={cfg.eyebrow ?? "Contacto"}
      title={cfg.title ?? "Hablemos"}
      description={cfg.description}
      align="left"
    >
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "1fr 2fr" },
          gap: `${tokens.spacing.gridGap}px`,
        }}
      >
        {/* Columna izquierda: datos de contacto */}
        <Stack spacing={2.5}>
          {cfg.email && (
            <ContactLine
              icon={<EmailOutlined sx={{ color: tokens.color.brand }} />}
              label="Email"
              value={cfg.email}
              href={`mailto:${cfg.email}`}
              tokens={tokens}
            />
          )}
          {cfg.phone && (
            <ContactLine
              icon={<PhoneOutlined sx={{ color: tokens.color.brand }} />}
              label="Teléfono"
              value={cfg.phone}
              href={`tel:${cfg.phone.replace(/\s+/g, "")}`}
              tokens={tokens}
            />
          )}
          {cfg.address && (
            <ContactLine
              icon={<LocationOnOutlined sx={{ color: tokens.color.brand }} />}
              label="Dirección"
              value={cfg.address}
              tokens={tokens}
            />
          )}
        </Stack>

        {/* Columna derecha: form interactivo (Client Component) */}
        <ContactFormClient
          tokens={tokens}
          submitEndpoint={cfg.submitEndpoint}
          subjects={cfg.subjects ?? []}
          submitLabel={cfg.submitLabel ?? "Enviar mensaje"}
          successMessage={
            cfg.successMessage ?? "Gracias, te responderemos pronto."
          }
        />
      </Box>
    </SectionShell>
  );
}

function ContactLine({
  icon,
  label,
  value,
  href,
  tokens,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  href?: string;
  tokens: SectionAdapterProps["tokens"];
}) {
  return (
    <Stack direction="row" spacing={1.5} alignItems="flex-start">
      <Box sx={{ mt: 0.25 }}>{icon}</Box>
      <Box>
        <Typography
          sx={{
            fontSize: "0.75rem",
            textTransform: "uppercase",
            letterSpacing: "0.06em",
            fontWeight: 600,
            color: tokens.color.textMuted,
            mb: 0.5,
          }}
        >
          {label}
        </Typography>
        {href ? (
          <Link
            href={href}
            sx={{
              color: tokens.color.textPrimary,
              textDecoration: "none",
              fontSize: "1rem",
              fontWeight: 500,
              "&:hover": { color: tokens.color.brand },
            }}
          >
            {value}
          </Link>
        ) : (
          <Typography
            sx={{
              color: tokens.color.textPrimary,
              fontSize: "1rem",
              fontWeight: 500,
            }}
          >
            {value}
          </Typography>
        )}
      </Box>
    </Stack>
  );
}
