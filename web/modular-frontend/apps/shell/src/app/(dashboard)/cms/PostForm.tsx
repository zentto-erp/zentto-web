"use client";

import React, { useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import {
  Box, Stack, TextField, MenuItem, Button, Typography, Paper, Alert, CircularProgress, Switch, FormControlLabel,
  ToggleButton, ToggleButtonGroup, useMediaQuery, useTheme,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import UnpublishedIcon from "@mui/icons-material/Unpublished";
import DeleteIcon from "@mui/icons-material/Delete";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import VerticalSplitIcon from "@mui/icons-material/VerticalSplit";
import { useRouter } from "next/navigation";

// Monaco requiere `window`/`document` — dynamic con SSR disabled es obligatorio
// en Next. Lazy-load del chunk pesado solo cuando el editor está en pantalla.
const MonacoEditor = dynamic(() => import("@monaco-editor/react"), {
  ssr: false,
  loading: () => (
    <Box sx={{ height: 420, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <CircularProgress size={24} />
    </Box>
  ),
});
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
  // `view` controla qué mostrar en el editor:
  //   'edit'    — solo Monaco
  //   'split'   — Monaco (izq) + preview HTML (der) en desktop
  //   'preview' — solo preview HTML
  // En mobile colapsamos 'split' a tabs porque el ancho no alcanza.
  const [view, setView] = useState<"edit" | "split" | "preview">("split");
  const theme = useTheme();
  const isDesktop = useMediaQuery(theme.breakpoints.up("md"));
  const effectiveView: "edit" | "split" | "preview" =
    view === "split" && !isDesktop ? "edit" : view;

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
    <Box sx={{ p: 3, maxWidth: 1600, mx: "auto" }}>
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

          <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 1 }}>
            <Typography variant="subtitle2" color="text.secondary">
              Cuerpo (Markdown)
            </Typography>
            <ToggleButtonGroup
              value={effectiveView}
              exclusive
              size="small"
              onChange={(_, v) => { if (v) setView(v); }}
            >
              <ToggleButton value="edit" aria-label="Solo editor">
                <EditIcon fontSize="small" />
              </ToggleButton>
              {isDesktop && (
                <ToggleButton value="split" aria-label="Split editor + preview">
                  <VerticalSplitIcon fontSize="small" />
                </ToggleButton>
              )}
              <ToggleButton value="preview" aria-label="Solo preview">
                <VisibilityIcon fontSize="small" />
              </ToggleButton>
            </ToggleButtonGroup>
          </Stack>

          <Box
            sx={{
              display: "grid",
              gap: 2,
              gridTemplateColumns: effectiveView === "split" ? "1fr 1fr" : "1fr",
              alignItems: "stretch",
              minHeight: 500,
            }}
          >
            {effectiveView !== "preview" && (
              <Box sx={{ border: 1, borderColor: "divider", borderRadius: 1, overflow: "hidden" }}>
                <MonacoEditor
                  height="500px"
                  defaultLanguage="markdown"
                  theme={theme.palette.mode === "dark" ? "vs-dark" : "vs-light"}
                  value={body}
                  onChange={(v) => setBody(v ?? "")}
                  options={{
                    wordWrap: "on",
                    minimap: { enabled: false },
                    fontSize: 14,
                    lineNumbers: "on",
                    scrollBeyondLastLine: false,
                    smoothScrolling: true,
                    automaticLayout: true,
                    padding: { top: 12, bottom: 12 },
                  }}
                />
              </Box>
            )}
            {effectiveView !== "edit" && (
              <Box
                sx={{
                  p: 3,
                  border: 1,
                  borderColor: "divider",
                  borderRadius: 1,
                  fontSize: "1rem",
                  overflow: "auto",
                  maxHeight: 500,
                  bgcolor: "background.paper",
                  "& img": { maxWidth: "100%" },
                  "& a": { color: "primary.main" },
                }}
                // CMS preview: bodyPreview viene de marked/sanitize-html en el editor del autor (rol admin),
                // NO de input público. Necesitamos renderizar HTML editado para preview WYSIWYG.
                // nosemgrep: typescript.react.security.audit.react-dangerouslysetinnerhtml.react-dangerouslysetinnerhtml
                dangerouslySetInnerHTML={{ __html: bodyPreview || "<em style='opacity:0.5'>Sin contenido — empieza a escribir markdown a la izquierda.</em>" }}
              />
            )}
          </Box>
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
