"use client";

import React, { useState } from "react";
import {
  Box, Button, Stack, Typography, Chip, Paper, Skeleton, Alert, MenuItem, TextField,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import WebIcon from "@mui/icons-material/Web";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  listLandings, VERTICALS, buildPublicUrl,
  type LandingListItem, type LandingStatus,
} from "./_lib";

const STATUS_COLOR: Record<string, "default" | "success" | "warning"> = {
  draft: "warning",
  published: "success",
  archived: "default",
};

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

export default function CmsLandingsIndexPage() {
  const router = useRouter();
  const [verticalFilter, setVerticalFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("");

  const { data, isLoading, error } = useQuery({
    queryKey: ["cms-landings", verticalFilter, statusFilter],
    queryFn: () =>
      listLandings({
        vertical: verticalFilter || undefined,
        status: (statusFilter || undefined) as LandingStatus | undefined,
        limit: 100,
      }),
  });

  const landings: LandingListItem[] = data?.data ?? [];
  const total = data?.total ?? 0;

  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: "auto" }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Stack>
          <Typography variant="h5" fontWeight={700}>
            CMS · Landings
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Edita visualmente las landings de cada vertical. Publicar dispara revalidate
            del frontend correspondiente (~30s).
          </Typography>
        </Stack>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/cms/landings/new")}
        >
          Nueva landing
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          select
          size="small"
          label="Vertical"
          value={verticalFilter}
          onChange={(e) => setVerticalFilter(e.target.value)}
          sx={{ minWidth: 180 }}
        >
          <MenuItem value="">Todas</MenuItem>
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
          <MenuItem value="draft">Borrador</MenuItem>
          <MenuItem value="published">Publicado</MenuItem>
          <MenuItem value="archived">Archivado</MenuItem>
        </TextField>
        <Box sx={{ flex: 1 }} />
        <Typography variant="caption" color="text.secondary" sx={{ alignSelf: "center" }}>
          {total} landing{total === 1 ? "" : "s"}
        </Typography>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(error as Error).message}
        </Alert>
      )}

      {isLoading ? (
        Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} variant="rounded" height={76} sx={{ mb: 1.5 }} />
        ))
      ) : landings.length === 0 ? (
        <Paper variant="outlined" sx={{ p: 6, textAlign: "center" }}>
          <WebIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
          <Typography variant="subtitle1" fontWeight={600} gutterBottom>
            Aún no hay landings {statusFilter ? `en ${statusFilter}` : ""}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Empieza creando el primer schema de landing para un vertical.
          </Typography>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/cms/landings/new")}>
            Crear primera landing
          </Button>
        </Paper>
      ) : (
        <Stack spacing={1}>
          {landings.map((l) => {
            const verticalLabel = VERTICALS.find((v) => v.value === l.vertical)?.label ?? l.vertical;
            return (
              <Paper
                key={l.landingSchemaId}
                variant="outlined"
                sx={{
                  p: 2,
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "1fr auto" },
                  gap: 2,
                  alignItems: "center",
                  transition: "border-color 0.15s",
                  "&:hover": { borderColor: "primary.main" },
                }}
              >
                <Stack>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
                    <Chip
                      label={l.status}
                      size="small"
                      color={STATUS_COLOR[l.status] ?? "default"}
                      sx={{ textTransform: "capitalize" }}
                    />
                    <Chip label={verticalLabel} size="small" variant="outlined" />
                    {l.locale !== "es" && <Chip label={l.locale} size="small" />}
                    <Chip label={`v${l.version}`} size="small" variant="outlined" />
                  </Stack>
                  <Typography variant="subtitle1" fontWeight={600}>
                    /{l.slug}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Actualizado: {fmtDateTime(l.updatedAt)}
                    {l.publishedAt ? ` · Publicado: ${fmtDateTime(l.publishedAt)}` : ""}
                  </Typography>
                </Stack>
                <Stack direction="row" spacing={0.5}>
                  <Button
                    size="small"
                    startIcon={<EditIcon />}
                    onClick={() => router.push(`/cms/landings/${l.landingSchemaId}`)}
                  >
                    Editar
                  </Button>
                  <Button
                    size="small"
                    startIcon={<OpenInNewIcon />}
                    disabled={l.status !== "published"}
                    onClick={() => {
                      const url = buildPublicUrl(l.vertical, l.slug);
                      window.open(url, "_blank", "noopener,noreferrer");
                    }}
                  >
                    Ver publicado
                  </Button>
                </Stack>
              </Paper>
            );
          })}
        </Stack>
      )}
    </Box>
  );
}
