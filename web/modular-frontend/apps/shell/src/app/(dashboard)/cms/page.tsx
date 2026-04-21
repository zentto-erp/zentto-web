"use client";

import React, { useMemo, useState } from "react";
import {
  Box, Button, Stack, Typography, Chip, Tabs, Tab, Paper, Skeleton, Alert,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import ArticleIcon from "@mui/icons-material/Article";
import DescriptionIcon from "@mui/icons-material/Description";
import PublishIcon from "@mui/icons-material/Publish";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  listPosts, publishPost, unpublishPost, deletePost,
  VERTICALS, CATEGORIES,
} from "./_lib";
import type { CmsPost } from "./_lib";

const STATUS_COLOR: Record<string, "default" | "success" | "warning"> = {
  draft: "warning",
  published: "success",
  archived: "default",
};

function fmtDate(iso: string | null) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString("es", { year: "numeric", month: "short", day: "numeric" });
  } catch {
    return "—";
  }
}

export default function CmsIndexPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);

  const { data, isLoading, error } = useQuery({
    queryKey: ["cms-posts-admin", statusFilter],
    queryFn: () => listPosts({ status: statusFilter, limit: 100 }),
  });

  const posts: CmsPost[] = data?.data ?? [];
  const total = data?.total ?? 0;

  const publishMut = useMutation({
    mutationFn: (p: CmsPost) => p.Status === "published" ? unpublishPost(p.PostId) : publishPost(p.PostId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["cms-posts-admin"] }),
  });

  const deleteMut = useMutation({
    mutationFn: (p: CmsPost) => deletePost(p.PostId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["cms-posts-admin"] }),
  });

  async function handlePublishToggle(p: CmsPost) {
    publishMut.mutate(p);
  }

  async function handleDelete(p: CmsPost) {
    if (!confirm(`¿Eliminar "${p.Title}"? No se puede deshacer.`)) return;
    deleteMut.mutate(p);
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: "auto" }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Stack>
          <Typography variant="h5" fontWeight={700}>CMS · Posts del blog</Typography>
          <Typography variant="body2" color="text.secondary">
            Administra posts del ecosistema Zentto. Publicados aparecen en zentto.net/blog y en el
            &lt;BlogTeaser&gt; de las 8 landings verticales.
          </Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          <Button
            variant="outlined"
            startIcon={<DescriptionIcon />}
            onClick={() => router.push("/cms/pages")}
          >
            Páginas
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => router.push("/cms/posts/new")}
          >
            Nuevo post
          </Button>
        </Stack>
      </Stack>

      <Tabs
        value={statusFilter ?? "all"}
        onChange={(_, v) => setStatusFilter(v === "all" ? undefined : v)}
        sx={{ mb: 2, borderBottom: 1, borderColor: "divider" }}
      >
        <Tab value="all" label={`Todos (${total})`} />
        <Tab value="published" label="Publicados" />
        <Tab value="draft" label="Borradores" />
        <Tab value="archived" label="Archivados" />
      </Tabs>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{(error as Error).message}</Alert>}

      {isLoading ? (
        Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} variant="rounded" height={80} sx={{ mb: 1.5 }} />
        ))
      ) : posts.length === 0 ? (
        <Paper variant="outlined" sx={{ p: 6, textAlign: "center" }}>
          <ArticleIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
          <Typography variant="subtitle1" fontWeight={600} gutterBottom>
            Aún no hay posts {statusFilter ? `en ${statusFilter}` : ""}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Empieza creando el primer post del blog corporativo.
          </Typography>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/cms/posts/new")}>
            Crear primer post
          </Button>
        </Paper>
      ) : (
        <Stack spacing={1}>
          {posts.map((p) => {
            const verticalLabel = VERTICALS.find((v) => v.value === p.Vertical)?.label ?? p.Vertical;
            const categoryLabel = CATEGORIES.find((c) => c.value === p.Category)?.label ?? p.Category;
            return (
              <Paper
                key={p.PostId}
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
                      label={p.Status}
                      size="small"
                      color={STATUS_COLOR[p.Status] ?? "default"}
                      sx={{ textTransform: "capitalize" }}
                    />
                    <Chip label={verticalLabel} size="small" variant="outlined" />
                    <Chip label={categoryLabel} size="small" variant="outlined" />
                    {p.Locale !== "es" && <Chip label={p.Locale} size="small" />}
                  </Stack>
                  <Typography variant="subtitle1" fontWeight={600}>{p.Title}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    /{p.Slug} · {p.ReadingMin} min · {fmtDate(p.PublishedAt)} · por {p.AuthorName || "—"}
                  </Typography>
                </Stack>
                <Stack direction="row" spacing={0.5}>
                  <Button
                    size="small"
                    startIcon={p.Status === "published" ? undefined : <PublishIcon />}
                    onClick={() => handlePublishToggle(p)}
                    disabled={publishMut.isPending}
                    color={p.Status === "published" ? "warning" : "success"}
                  >
                    {p.Status === "published" ? "Despublicar" : "Publicar"}
                  </Button>
                  <Button
                    size="small"
                    startIcon={<EditIcon />}
                    onClick={() => router.push(`/cms/posts/${p.PostId}`)}
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
