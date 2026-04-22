"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Box, CircularProgress, Alert } from "@mui/material";
import { PostForm } from "../../PostForm";
import { listPosts, getPost, type CmsPost } from "../../_lib";

export default function EditPostPage() {
  const params = useParams();
  const id = Number(params.id);
  const [post, setPost] = useState<CmsPost | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!Number.isFinite(id) || id <= 0) {
      setError("ID inválido");
      setLoading(false);
      return;
    }
    // 2-step load:
    //   1. listPosts → encontrar el card del post (devuelve metadata pero
    //      `usp_cms_post_list` NO trae el campo `Body`).
    //   2. getPost(slug, locale) → trae el detalle completo, incluido `Body`,
    //      `SeoTitle`, `SeoDescription`. Sin este segundo fetch el editor
    //      arrancaba con body vacío y mostraba el placeholder, simulando
    //      que el post no tenía contenido.
    let cancelled = false;
    (async () => {
      try {
        // Multi-status: el endpoint admin filtra por status (default published)
        // y el SP no soporta "all". Pedimos los 3 estados en paralelo y
        // unimos para encontrar el post sin importar dónde está.
        const lists = await Promise.all([
          listPosts({ limit: 100, status: "published" }).catch(() => null),
          listPosts({ limit: 100, status: "draft" }).catch(() => null),
          listPosts({ limit: 100, status: "archived" }).catch(() => null),
        ]);
        const allCards = lists
          .filter((r) => r !== null)
          .flatMap((r) => r!.data ?? []);
        const card = allCards.find((p) => p.PostId === id);
        if (!card) throw new Error(`Post #${id} no encontrado`);

        const detail = await getPost(card.Slug, card.Locale ?? "es");
        if (cancelled) return;
        // El SP devuelve Body, SeoTitle, etc. Mergeamos con la metadata
        // de list para conservar PostId/CompanyId que el detail no incluye.
        setPost({ ...card, ...(detail.data ?? {}) } as CmsPost);
      } catch (e: any) {
        if (!cancelled) setError(e?.message ?? "Error cargando el post");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  if (loading) {
    return (
      <Box sx={{ p: 6, display: "flex", justifyContent: "center" }}>
        <CircularProgress />
      </Box>
    );
  }
  if (error) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }
  if (!post) return null;
  return <PostForm initial={post} />;
}
