"use client";

/**
 * Inbox admin de mensajes de contacto — lee los enviados desde el
 * `ContactFormAdapter` del `@zentto/landing-kit` en las landings de cada
 * vertical (`POST /v1/public/cms/contact/submit`).
 *
 * Patrón UI: coherente con `cms/landings/page.tsx` — Paper cards expandibles
 * (regla crítica del workspace: nunca `<table>` HTML).
 */

import React, { useMemo, useState } from "react";
import {
  Box, Button, Stack, Typography, Chip, Paper, Skeleton, Alert, MenuItem, TextField,
  IconButton, Tooltip, Collapse,
} from "@mui/material";
import EmailIcon from "@mui/icons-material/Email";
import ReplyIcon from "@mui/icons-material/Reply";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
import MarkEmailReadIcon from "@mui/icons-material/MarkEmailRead";
import ArchiveIcon from "@mui/icons-material/Archive";
import { useQuery } from "@tanstack/react-query";
import {
  listContactSubmissions, VERTICALS, CONTACT_STATUSES, buildMailtoReply,
  type ContactStatus, type ContactSubmission,
} from "./_lib";

function fmtDateTime(iso: string | null) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString("es", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "—";
  }
}

function truncate(s: string, n = 120): string {
  if (!s) return "";
  return s.length > n ? s.slice(0, n) + "…" : s;
}

export default function CmsContactInboxPage() {
  const [verticalFilter, setVerticalFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [expanded, setExpanded] = useState<Record<number, boolean>>({});

  const { data, isLoading, error } = useQuery({
    queryKey: ["cms-contact-submissions", verticalFilter, statusFilter],
    queryFn: () =>
      listContactSubmissions({
        vertical: verticalFilter || undefined,
        status: (statusFilter || undefined) as ContactStatus | undefined,
        limit: 100,
      }),
  });

  const submissions: ContactSubmission[] = data?.data ?? [];
  const total = data?.total ?? submissions.length;

  function toggleExpand(id: number) {
    setExpanded((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  const statusLookup = useMemo(() => {
    const m = new Map<string, { label: string; color: "default" | "success" | "warning" }>();
    CONTACT_STATUSES.forEach((s) => m.set(s.value, { label: s.label, color: s.color }));
    return m;
  }, []);

  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: "auto" }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Stack>
          <Typography variant="h5" fontWeight={700}>
            CMS · Inbox de contacto
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Mensajes enviados desde los formularios de contacto de las landings
            del ecosistema Zentto (ContactFormAdapter).
          </Typography>
        </Stack>
      </Stack>

      <Stack direction="row" spacing={2} sx={{ mb: 2, flexWrap: "wrap" }}>
        <TextField
          select
          size="small"
          label="Vertical"
          value={verticalFilter}
          onChange={(e) => setVerticalFilter(e.target.value)}
          sx={{ minWidth: 180 }}
        >
          <MenuItem value="">Todos</MenuItem>
          {VERTICALS.map((v) => (
            <MenuItem key={v.value} value={v.value}>
              {v.label}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Estado"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">Todos</MenuItem>
          {CONTACT_STATUSES.map((s) => (
            <MenuItem key={s.value} value={s.value}>
              {s.label}
            </MenuItem>
          ))}
        </TextField>
        <Box sx={{ flex: 1 }} />
        <Typography variant="caption" color="text.secondary" sx={{ alignSelf: "center" }}>
          {total} mensaje{total === 1 ? "" : "s"}
        </Typography>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(error as Error).message}
        </Alert>
      )}

      {isLoading ? (
        Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} variant="rounded" height={90} sx={{ mb: 1.5 }} />
        ))
      ) : submissions.length === 0 ? (
        <Paper variant="outlined" sx={{ p: 6, textAlign: "center" }}>
          <EmailIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
          <Typography variant="subtitle1" fontWeight={600} gutterBottom>
            No hay mensajes {statusFilter ? `en "${statusFilter}"` : ""}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Cuando alguien envíe el formulario de contacto de cualquier landing
            verás aquí el mensaje con nombre, email y contenido.
          </Typography>
        </Paper>
      ) : (
        <Stack spacing={1}>
          {submissions.map((s) => {
            const verticalLabel = VERTICALS.find((v) => v.value === s.Vertical)?.label ?? s.Vertical;
            const statusInfo = statusLookup.get(s.Status) ?? { label: s.Status, color: "default" as const };
            const isOpen = expanded[s.ContactSubmissionId] === true;
            return (
              <Paper
                key={s.ContactSubmissionId}
                variant="outlined"
                sx={{
                  p: 2,
                  transition: "border-color 0.15s",
                  "&:hover": { borderColor: "primary.main" },
                }}
              >
                <Stack direction={{ xs: "column", md: "row" }} spacing={2} alignItems={{ md: "center" }}>
                  <Stack sx={{ flex: 1, minWidth: 0 }}>
                    <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5, flexWrap: "wrap" }}>
                      <Chip label={statusInfo.label} size="small" color={statusInfo.color} />
                      <Chip label={verticalLabel} size="small" variant="outlined" />
                      <Typography variant="caption" color="text.secondary">
                        {fmtDateTime(s.CreatedAt)} · /{s.Slug}
                      </Typography>
                    </Stack>
                    <Typography variant="subtitle1" fontWeight={600} noWrap>
                      {s.Subject || "(sin asunto)"}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      De: <strong>{s.Name}</strong> &lt;{s.Email}&gt;
                    </Typography>
                    {!isOpen && (
                      <Typography variant="body2" sx={{ mt: 0.5, color: "text.secondary" }}>
                        {truncate(s.Message, 140)}
                      </Typography>
                    )}
                  </Stack>

                  <Stack direction="row" spacing={0.5} alignSelf={{ xs: "flex-start", md: "center" }}>
                    <Tooltip title={isOpen ? "Colapsar mensaje" : "Ver mensaje completo"}>
                      <IconButton size="small" onClick={() => toggleExpand(s.ContactSubmissionId)}>
                        {isOpen ? <ExpandLessIcon fontSize="small" /> : <ExpandMoreIcon fontSize="small" />}
                      </IconButton>
                    </Tooltip>
                    <Button
                      size="small"
                      startIcon={<ReplyIcon />}
                      href={buildMailtoReply(s)}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Responder
                    </Button>
                    <Tooltip title="Marcar como leído (endpoint backend pendiente)">
                      <span>
                        <IconButton size="small" disabled>
                          <MarkEmailReadIcon fontSize="small" />
                        </IconButton>
                      </span>
                    </Tooltip>
                    <Tooltip title="Archivar (endpoint backend pendiente)">
                      <span>
                        <IconButton size="small" disabled>
                          <ArchiveIcon fontSize="small" />
                        </IconButton>
                      </span>
                    </Tooltip>
                  </Stack>
                </Stack>

                <Collapse in={isOpen} unmountOnExit>
                  <Box
                    sx={{
                      mt: 2,
                      p: 2,
                      bgcolor: "action.hover",
                      borderRadius: 1,
                      whiteSpace: "pre-wrap",
                      fontSize: "0.9rem",
                      lineHeight: 1.6,
                    }}
                  >
                    {s.Message || "(mensaje vacío)"}
                  </Box>
                </Collapse>
              </Paper>
            );
          })}
        </Stack>
      )}
    </Box>
  );
}
