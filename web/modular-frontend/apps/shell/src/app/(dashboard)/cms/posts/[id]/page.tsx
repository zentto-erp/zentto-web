"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Box, CircularProgress, Alert } from "@mui/material";
import { PostForm } from "../../PostForm";
import { listPosts, type CmsPost } from "../../_lib";

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
    // El SP getPost usa slug. Para editar por id, listamos todo y filtramos
    // (admin list ve también drafts). Barato: un solo query, hasta 100 posts.
    listPosts({ limit: 100 })
      .then((r) => {
        const found = (r.data ?? []).find((p) => p.PostId === id);
        if (!found) {
          setError(`Post #${id} no encontrado`);
        } else {
          setPost(found as CmsPost);
        }
      })
      .catch((e: any) => setError(e?.message ?? "Error cargando el post"))
      .finally(() => setLoading(false));
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
