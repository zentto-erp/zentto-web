"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Paper,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Alert,
  Breadcrumbs,
  Link,
  Divider,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { postsApi, categoriesApi, tagsApi } from "@/lib/api";

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export default function NewPostPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [slugManual, setSlugManual] = useState(false);
  const [content, setContent] = useState("");
  const [status, setStatus] = useState("draft");
  const [categoryId, setCategoryId] = useState("");
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("");
  const [featuredImage, setFeaturedImage] = useState("");
  const [seoTitle, setSeoTitle] = useState("");
  const [seoDescription, setSeoDescription] = useState("");
  const [author, setAuthor] = useState("");
  const [excerpt, setExcerpt] = useState("");

  const [categories, setCategories] = useState<any[]>([]);
  const [availableTags, setAvailableTags] = useState<any[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!siteId) return;
    categoriesApi.list(siteId).then((r) => setCategories(Array.isArray(r) ? r : r?.data ?? [])).catch(() => {});
    tagsApi.list(siteId).then((r) => setAvailableTags(Array.isArray(r) ? r : r?.data ?? [])).catch(() => {});
  }, [siteId]);

  useEffect(() => {
    if (!slugManual) setSlug(slugify(title));
  }, [title, slugManual]);

  const buildPayload = () => ({
    title,
    slug,
    content,
    status,
    categoryId: categoryId || undefined,
    tags: selectedTags,
    featuredImage: featuredImage || undefined,
    seoTitle: seoTitle || undefined,
    seoDescription: seoDescription || undefined,
    author: author || undefined,
    excerpt: excerpt || undefined,
  });

  const handleSave = async (publishNow?: boolean) => {
    setSaving(true);
    setError(null);
    try {
      const payload = buildPayload();
      if (publishNow) payload.status = "published";
      const created = await postsApi.create(siteId, payload);
      router.push(`/sites/${siteId}/blog/${created.id || created.postId}`);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAddTag = () => {
    const tag = tagInput.trim();
    if (tag && !selectedTags.includes(tag)) {
      setSelectedTags([...selectedTags, tag]);
    }
    setTagInput("");
  };

  const handleRemoveTag = (tag: string) => {
    setSelectedTags(selectedTags.filter((t) => t !== tag));
  };

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      {/* Breadcrumbs */}
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push("/sites")}>
          Mis Sitios
        </Link>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push(`/sites/${siteId}`)}>
          Sitio
        </Link>
        <Link underline="hover" color="inherit" sx={{ cursor: "pointer" }} onClick={() => router.push(`/sites/${siteId}/blog`)}>
          Blog
        </Link>
        <Typography color="text.primary">Nuevo Post</Typography>
      </Breadcrumbs>

      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Typography variant="h4" fontWeight={700}>
          Nuevo Post
        </Typography>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Button variant="outlined" startIcon={<SaveIcon />} onClick={() => handleSave()} disabled={saving || !title}>
            Guardar borrador
          </Button>
          <Button variant="contained" startIcon={<PublishIcon />} onClick={() => handleSave(true)} disabled={saving || !title}>
            Publicar
          </Button>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Main content */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper sx={{ p: 3 }}>
            <TextField
              fullWidth
              placeholder="Titulo del post..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              variant="standard"
              InputProps={{ sx: { fontSize: 28, fontWeight: 700 }, disableUnderline: true }}
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              label="Slug"
              size="small"
              value={slug}
              onChange={(e) => { setSlug(e.target.value); setSlugManual(true); }}
              sx={{ mb: 3 }}
              helperText="URL del post. Se genera automaticamente del titulo."
            />
            <Divider sx={{ mb: 3 }} />
            <TextField
              fullWidth
              label="Contenido (Markdown)"
              multiline
              minRows={16}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 14 } }}
            />
          </Paper>
        </Grid>

        {/* Sidebar */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 2 }}>
              Configuracion
            </Typography>

            <FormControl fullWidth size="small" sx={{ mb: 2 }}>
              <InputLabel>Estado</InputLabel>
              <Select value={status} label="Estado" onChange={(e) => setStatus(e.target.value)}>
                <MenuItem value="draft">Borrador</MenuItem>
                <MenuItem value="published">Publicado</MenuItem>
              </Select>
            </FormControl>

            <FormControl fullWidth size="small" sx={{ mb: 2 }}>
              <InputLabel>Categoria</InputLabel>
              <Select value={categoryId} label="Categoria" onChange={(e) => setCategoryId(e.target.value)}>
                <MenuItem value="">Sin categoria</MenuItem>
                {categories.map((cat) => (
                  <MenuItem key={cat.id} value={cat.id}>{cat.name}</MenuItem>
                ))}
              </Select>
            </FormControl>

            <Typography variant="caption" color="text.secondary" sx={{ mb: 0.5, display: "block" }}>
              Tags
            </Typography>
            <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5, mb: 1 }}>
              {selectedTags.map((tag) => (
                <Chip key={tag} label={tag} size="small" onDelete={() => handleRemoveTag(tag)} />
              ))}
            </Box>
            <TextField
              fullWidth
              size="small"
              placeholder="Agregar tag y presionar Enter"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); handleAddTag(); } }}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              size="small"
              label="Imagen destacada (URL)"
              value={featuredImage}
              onChange={(e) => setFeaturedImage(e.target.value)}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              size="small"
              label="Autor"
              value={author}
              onChange={(e) => setAuthor(e.target.value)}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              size="small"
              label="Extracto"
              multiline
              minRows={2}
              value={excerpt}
              onChange={(e) => setExcerpt(e.target.value)}
            />
          </Paper>

          <Paper sx={{ p: 3 }}>
            <Typography variant="subtitle2" fontWeight={600} sx={{ mb: 2 }}>
              SEO
            </Typography>
            <TextField
              fullWidth
              size="small"
              label="Titulo SEO"
              value={seoTitle}
              onChange={(e) => setSeoTitle(e.target.value)}
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              size="small"
              label="Descripcion SEO"
              multiline
              minRows={2}
              value={seoDescription}
              onChange={(e) => setSeoDescription(e.target.value)}
            />
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
