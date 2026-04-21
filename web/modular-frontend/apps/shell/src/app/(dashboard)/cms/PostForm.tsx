"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Box, Stack, TextField, MenuItem, Button, Typography, Paper, Alert, CircularProgress, Switch, FormControlLabel, Tabs, Tab,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import UnpublishedIcon from "@mui/icons-material/Unpublished";
import DeleteIcon from "@mui/icons-material/Delete";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import { useRouter } from "next/navigation";
import {
  VERTICALS, CATEGORIES, markdownToHtml, slugify,
  type CmsPost,
  createPost, updatePost, publishPost, unpublishPost, deletePost,
} from "./_lib";

interface Props {
  /** undefined = crear; objeto = editar */
  initial?: CmsPost;
}

export function PostForm({ initial }: Props) {
  const router = useRouter();
  const editing = !!initial;

  const [slug, setSlug] = useState(initial?.Slug ?? "");
  const [title, setTitle] = useState(initial?.Title ?? "");
  const [autoSlug, setAutoSlug] = useState(!initial);
  const [excerpt, setExcerpt] = useState(initial?.Excerpt ?? "");
  const [body, setBody] = useState(initial?.Body ?? "");
  const [vertical, setVertical] = useState(initial?.Vertical ?? "corporate");
  const [category, setCategory] = useState(initial?.Category ?? "producto");
  const [tags, setTags] = useState(initial?.Tags ?? "");
  const [readingMin, setReadingMin] = useState(initial?.ReadingMin ?? 5);
  const [coverUrl, setCoverUrl] = useState(initial?.CoverUrl ?? "");
  const [authorName, setAuthorName] = useState(initial?.AuthorName ?? "Equipo Zentto");
  const [authorSlug, setAuthorSlug] = useState(initial?.AuthorSlug ?? "equipo-zentto");
  const [seoTitle, setSeoTitle] = useState(initial?.SeoTitle ?? "");
  const [seoDescription, setSeoDescription] = useState(initial?.SeoDescription ?? "");

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<"edit" | "preview">("edit");

  useEffect(() => {
    if (autoSlug) setSlug(slugify(title));
  }, [title, autoSlug]);

  const status = initial?.Status ?? "draft";
  const published = status === "published";

  const bodyPreview = useMemo(() => markdownToHtml(body), [body]);

  async function handleSave(andPublish = false) {
    setSaving(true);
    setError(null);
    try {
      const input = {
        slug: slug || slugify(title),
        title,
        excerpt,
        body,
        vertical,
        category,
        tags,
        readingMin: Number(readingMin) || 5,
        coverUrl,
        authorName,
        authorSlug,
        seoTitle,
        seoDescription,
      } as any;

      const saved = editing && initial
        ? await updatePost(initial.PostId, input)
        : await createPost(input);

      const postId = editing && initial ? initial.PostId : saved?.post_id;
      if (andPublish && postId) {
        await publishPost(postId);
      }
      router.push("/cms");
    } catch (e: any) {
      setError(e?.message ?? "Error guardando el post");
    } finally {
      setSaving(false);
    }
  }

  async function handlePublishToggle() {
    if (!initial) return;
    setSaving(true);
    try {
      if (published) await unpublishPost(initial.PostId);
      else await publishPost(initial.PostId);
      router.refresh();
    } catch (e: any) {
      setError(e?.message ?? "Error");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!initial) return;
    if (!confirm(`¿Eliminar post "${initial.Title}"? Esto no se puede deshacer.`)) return;
    setSaving(true);
    try {
      await deletePost(initial.PostId);
      router.push("/cms");
    } catch (e: any) {
      setError(e?.message ?? "Error");
      setSaving(false);
    }
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          {editing ? `Editar post #${initial?.PostId}` : "Nuevo post"}
        </Typography>
        <Stack direction="row" spacing={1}>
          <Button onClick={() => router.push("/cms")} disabled={saving}>Cancelar</Button>
          {editing && (
            <Button
              variant="outlined"
              color={published ? "warning" : "success"}
              startIcon={published ? <UnpublishedIcon /> : <PublishIcon />}
              onClick={handlePublishToggle}
              disabled={saving}
            >
              {published ? "Despublicar" : "Publicar"}
            </Button>
          )}
          <Button
            variant="contained"
            startIcon={saving ? <CircularProgress size={18} color="inherit" /> : <SaveIcon />}
            onClick={() => handleSave(false)}
            disabled={saving || !title}
          >
            Guardar borrador
          </Button>
          {!editing && (
            <Button
              variant="contained"
              color="success"
              startIcon={<PublishIcon />}
              onClick={() => handleSave(true)}
              disabled={saving || !title}
            >
              Guardar y publicar
            </Button>
          )}
          {editing && (
            <Button
              variant="outlined"
              color="error"
              startIcon={<DeleteIcon />}
              onClick={handleDelete}
              disabled={saving}
            >
              Eliminar
            </Button>
          )}
        </Stack>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Box sx={{ display: "grid", gridTemplateColumns: { md: "1fr 340px" }, gap: 3 }}>
        <Paper variant="outlined" sx={{ p: 3 }}>
          <TextField
            label="Título"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            fullWidth
            required
            sx={{ mb: 2 }}
          />

          <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2 }}>
            <TextField
              label="Slug"
              value={slug}
              onChange={(e) => { setSlug(e.target.value); setAutoSlug(false); }}
              fullWidth
              helperText="URL-friendly. Se autogenera desde el título mientras no lo edites manualmente."
            />
            <FormControlLabel
              control={<Switch checked={autoSlug} onChange={(e) => setAutoSlug(e.target.checked)} />}
              label="Auto"
              sx={{ whiteSpace: "nowrap" }}
            />
          </Stack>

          <TextField
            label="Excerpt"
            value={excerpt}
            onChange={(e) => setExcerpt(e.target.value)}
            fullWidth
            multiline
            minRows={2}
            maxRows={4}
            sx={{ mb: 2 }}
            helperText={`${excerpt.length}/500 caracteres`}
            inputProps={{ maxLength: 500 }}
          />

          <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 1 }}>
            <Tab value="edit" icon={<EditIcon fontSize="small" />} iconPosition="start" label="Markdown" />
            <Tab value="preview" icon={<VisibilityIcon fontSize="small" />} iconPosition="start" label="Preview" />
          </Tabs>

          {tab === "edit" ? (
            <TextField
              label="Cuerpo (Markdown)"
              value={body}
              onChange={(e) => setBody(e.target.value)}
              fullWidth
              multiline
              minRows={18}
              sx={{
                "& textarea": { fontFamily: "monospace", fontSize: "0.9rem", lineHeight: 1.6 },
              }}
              placeholder={"## Sección\n\nPárrafo de texto...\n\n- Bullet 1\n- Bullet 2\n\n[link](https://zentto.net)"}
            />
          ) : (
            <Box
              sx={{
                minHeight: 420,
                p: 3,
                border: 1,
                borderColor: "divider",
                borderRadius: 1,
                fontSize: "1rem",
                "& img": { maxWidth: "100%" },
              }}
              dangerouslySetInnerHTML={{ __html: bodyPreview || "<em style='opacity:0.5'>Sin contenido</em>" }}
            />
          )}
        </Paper>

        <Stack spacing={2}>
          <Paper variant="outlined" sx={{ p: 2 }}>
            <Typography variant="subtitle2" gutterBottom>Clasificación</Typography>
            <TextField
              select label="Vertical" value={vertical}
              onChange={(e) => setVertical(e.target.value)}
              fullWidth size="small" sx={{ mb: 1.5 }}
            >
              {VERTICALS.map((v) => <MenuItem key={v.value} value={v.value}>{v.label}</MenuItem>)}
            </TextField>
            <TextField
              select label="Categoría" value={category}
              onChange={(e) => setCategory(e.target.value)}
              fullWidth size="small" sx={{ mb: 1.5 }}
            >
              {CATEGORIES.map((c) => <MenuItem key={c.value} value={c.value}>{c.label}</MenuItem>)}
            </TextField>
            <TextField
              label="Tags (CSV)" value={tags}
              onChange={(e) => setTags(e.target.value)}
              fullWidth size="small" sx={{ mb: 1.5 }}
              placeholder="ecosistema,manifiesto"
            />
            <TextField
              label="Min. lectura" type="number" value={readingMin}
              onChange={(e) => setReadingMin(Number(e.target.value))}
              fullWidth size="small"
            />
          </Paper>

          <Paper variant="outlined" sx={{ p: 2 }}>
            <Typography variant="subtitle2" gutterBottom>Autoría</Typography>
            <TextField
              label="Autor" value={authorName}
              onChange={(e) => setAuthorName(e.target.value)}
              fullWidth size="small" sx={{ mb: 1.5 }}
            />
            <TextField
              label="Slug autor" value={authorSlug}
              onChange={(e) => setAuthorSlug(e.target.value)}
              fullWidth size="small"
            />
          </Paper>

          <Paper variant="outlined" sx={{ p: 2 }}>
            <Typography variant="subtitle2" gutterBottom>Portada</Typography>
            <TextField
              label="Cover URL" value={coverUrl}
              onChange={(e) => setCoverUrl(e.target.value)}
              fullWidth size="small"
              placeholder="https://..."
            />
          </Paper>

          <Paper variant="outlined" sx={{ p: 2 }}>
            <Typography variant="subtitle2" gutterBottom>SEO</Typography>
            <TextField
              label="SEO Title" value={seoTitle}
              onChange={(e) => setSeoTitle(e.target.value)}
              fullWidth size="small" sx={{ mb: 1.5 }}
              helperText={seoTitle || title ? `${(seoTitle || title).length} chars` : ""}
            />
            <TextField
              label="SEO Description" value={seoDescription}
              onChange={(e) => setSeoDescription(e.target.value)}
              fullWidth multiline minRows={2} size="small"
              helperText={`${seoDescription.length}/160`}
              inputProps={{ maxLength: 160 }}
            />
          </Paper>
        </Stack>
      </Box>
    </Box>
  );
}
