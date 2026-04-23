"use client";

/**
 * Listado admin de páginas corporativas CMS.
 *
 * Cubre los pending del plan dogfooding landings CMS — permite editar
 * páginas tipo About / Contact / Press / Legal / Case-Study / Custom
 * desde appdev.zentto.net/cms/pages.
 *
 * Patrón UI: coherente con `cms/landings/page.tsx` — Paper cards en lugar
 * de tabla HTML (regla crítica del workspace: nunca <table> HTML).
 */

import React, { useMemo, useState } from "react";
import {
  Box, Button, Stack, Typography, Chip, Paper, Skeleton, Alert, MenuItem, TextField,
  Tooltip, IconButton,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import PublishIcon from "@mui/icons-material/Publish";
import DeleteIcon from "@mui/icons-material/Delete";
import DescriptionIcon from "@mui/icons-material/Description";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import { useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  listPages, publishPage, deletePage,
  VERTICALS, CMS_PAGE_TYPES, PAGE_TYPE_LABELS, PAGE_TYPE_COLORS,
  buildPagePublicUrl,
  type CmsPage, type CmsPageType,
} from "./_lib";

const STATUS_COLOR: Record<string, "default" | "success" | "warning"> = {
  draft: "warning",
  published: "success",
  archived: "default",
};

function fmtDateTime(iso: string | null | undefined) {
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

export default function CmsPagesIndexPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const [verticalFilter, setVerticalFilter] = useState<string>("");
  const [pageTypeFilter, setPageTypeFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("");

  const { data, isLoading, error } = useQuery({
    queryKey: ["cms-pages-admin", verticalFilter, pageTypeFilter, statusFilter],
    queryFn: () =>
      listPages({
        vertical: verticalFilter || undefined,
        pageType: pageTypeFilter || undefined,
        status: statusFilter || undefined,
        limit: 100,
      }),
  });

  const pages: CmsPage[] = data?.data ?? [];
  const total = pages.length;

  const publishMut = useMutation({
    mutationFn: (p: CmsPage) => publishPage(p.PageId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["cms-pages-admin"] }),
  });

  const deleteMut = useMutation({
    mutationFn: (p: CmsPage) => deletePage(p.PageId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["cms-pages-admin"] }),
  });

  function handlePublish(p: CmsPage) {
    if (p.Status === "published") return;
    publishMut.mutate(p);
  }

  function handleDelete(p: CmsPage) {
    if (!confirm(`¿Eliminar "${p.Title}"? Esta acción no se puede deshacer.`)) return;
    deleteMut.mutate(p);
  }

  const groupedTypes = useMemo(() => {
    return CMS_PAGE_TYPES.map((t) => ({ value: t, label: PAGE_TYPE_LABELS[t] }));
  }, []);

  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: "auto" }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Stack>
          <Typography variant="h5" fontWeight={700}>
            CMS · Páginas corporativas
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Edita páginas corporativas (Acerca, Contacto, Prensa, Legales, Casos).
            Cada página es un schema `landingConfig` editable como JSON.
          </Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          <Button
            variant="outlined"
            startIcon={<DescriptionIcon />}
            onClick={() => router.push("/cms")}
          >
            Posts del blog
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => router.push("/cms/pages/new")}
          >
            Nueva página
          </Button>
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
          label="Tipo de página"
          value={pageTypeFilter}
          onChange={(e) => setPageTypeFilter(e.target.value)}
          sx={{ minWidth: 200 }}
        >
          <MenuItem value="">Todos</MenuItem>
          {groupedTypes.map((t) => (
            <MenuItem key={t.value} value={t.value}>
              {t.label}
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
          {total} página{total === 1 ? "" : "s"}
        </Typography>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(error as Error).message}
        </Alert>
      )}

      {isLoading ? (
        Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} variant="rounded" height={80} sx={{ mb: 1.5 }} />
        ))
      ) : pages.length === 0 ? (
        <Paper variant="outlined" sx={{ p: 6, textAlign: "center" }}>
          <DescriptionIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
          <Typography variant="subtitle1" fontWeight={600} gutterBottom>
            Aún no hay páginas {statusFilter ? `en ${statusFilter}` : ""}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Empieza creando una página corporativa. Podrás elegir una plantilla
            (Acerca, Contacto, Prensa, Legales, Caso de éxito o personalizada).
          </Typography>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/cms/pages/new")}>
            Crear primera página
          </Button>
        </Paper>
      ) : (
        <Stack spacing={1}>
          {pages.map((p) => {
            const verticalLabel = VERTICALS.find((v) => v.value === p.Vertical)?.label ?? p.Vertical;
            const pageTypeKey = (p.PageType as CmsPageType) ?? "custom";
            const pageTypeLabel = PAGE_TYPE_LABELS[pageTypeKey] ?? pageTypeKey;
            const pageTypeColor = PAGE_TYPE_COLORS[pageTypeKey] ?? "default";
            const isPublished = p.Status === "published";
            return (
              <Paper
                key={p.PageId}
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
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5, flexWrap: "wrap" }}>
                    <Chip
                      label={p.Status}
                      size="small"
                      color={STATUS_COLOR[p.Status] ?? "default"}
                      sx={{ textTransform: "capitalize" }}
                    />
                    <Chip label={verticalLabel} size="small" variant="outlined" />
                    <Chip label={pageTypeLabel} size="small" color={pageTypeColor} />
                    {p.Locale !== "es" && <Chip label={p.Locale} size="small" />}
                  </Stack>
                  <Typography variant="subtitle1" fontWeight={600}>
                    {p.Title}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    /{p.Slug} · Actualizada {fmtDateTime(p.UpdatedAt)}
                    {p.PublishedAt ? ` · Publicada ${fmtDateTime(p.PublishedAt)}` : ""}
                  </Typography>
                </Stack>
                <Stack direction="row" spacing={0.5}>
                  <Tooltip title="Abrir pública">
                    <span>
                      <IconButton
                        size="small"
                        disabled={!isPublished}
                        onClick={() => {
                          const url = buildPagePublicUrl(p.Vertical, p.Slug);
                          window.open(url, "_blank", "noopener,noreferrer");
                        }}
                      >
                        <OpenInNewIcon fontSize="small" />
                      </IconButton>
                    </span>
                  </Tooltip>
                  <Button
                    size="small"
                    startIcon={<PublishIcon />}
                    color="success"
                    disabled={isPublished || publishMut.isPending}
                    onClick={() => handlePublish(p)}
                  >
                    {isPublished ? "Publicada" : "Publicar"}
                  </Button>
                  <Button
                    size="small"
                    startIcon={<EditIcon />}
                    onClick={() => router.push(`/cms/pages/${p.PageId}`)}
                  >
                    Editar
                  </Button>
                  <Button
                    size="small"
                    color="error"
                    startIcon={<DeleteIcon />}
                    onClick={() => handleDelete(p)}
                    disabled={deleteMut.isPending}
                  >
                    Borrar
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
