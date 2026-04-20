"use client";

import React, { useState, useEffect } from "react";
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  Chip,
  CircularProgress,
  FormControl,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import DeleteOutline from "@mui/icons-material/DeleteOutline";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { useRouter } from "next/navigation";
import {
  useAdminPressRelease,
  useUpsertPressRelease,
  usePublishPressRelease,
  useDeletePressRelease,
} from "../hooks/usePressReleases";
import { renderMarkdown } from "./StudioPageRenderer";

interface FormState {
  slug: string;
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl: string;
  tags: string[];
  status: "draft" | "published" | "archived";
}

const EMPTY_FORM: FormState = {
  slug: "",
  title: "",
  excerpt: "",
  body: "# Título del comunicado\n\nPrimer párrafo aquí.\n",
  coverImageUrl: "",
  tags: [],
  status: "draft",
};

export interface AdminPressReleaseEditorProps {
  pressReleaseId?: number | null;
}

export default function AdminPressReleaseEditor({ pressReleaseId }: AdminPressReleaseEditorProps) {
  const router = useRouter();
  const isNew = !pressReleaseId;
  const { data, isLoading } = useAdminPressRelease(pressReleaseId ?? null);
  const upsert = useUpsertPressRelease();
  const publish = usePublishPressRelease();
  const del = useDeletePressRelease();

  const [tab, setTab] = useState(0);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);

  useEffect(() => {
    if (!isNew && data?.item) {
      setForm({
        slug: data.item.slug,
        title: data.item.title,
        excerpt: data.item.excerpt ?? "",
        body: data.item.body ?? "",
        coverImageUrl: data.item.coverImageUrl ?? "",
        tags: data.item.tags ?? [],
        status: (data.item.status as FormState["status"]) ?? "draft",
      });
    }
  }, [data, isNew]);

  function setField<K extends keyof FormState>(k: K, v: FormState[K]) {
    setForm((s) => ({ ...s, [k]: v }));
  }

  async function save() {
    if (!form.slug.trim() || !form.title.trim()) return;
    const payload = {
      pressReleaseId: pressReleaseId ?? undefined,
      slug: form.slug.trim(),
      title: form.title.trim(),
      excerpt: form.excerpt.trim() || null,
      body: form.body,
      coverImageUrl: form.coverImageUrl.trim() || null,
      tags: form.tags,
      status: form.status,
    };
    const res = await upsert.mutateAsync(payload);
    if ((res as any)?.pressReleaseId && isNew) {
      router.push(`/admin/prensa/${(res as any).pressReleaseId}`);
    }
  }

  if (!isNew && isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Stack direction="row" spacing={1} alignItems="center">
          <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/admin/prensa")} sx={{ textTransform: "none" }}>
            Volver
          </Button>
          <Typography variant="h5" fontWeight={700}>
            {isNew ? "Nuevo comunicado" : `Editar: ${form.title || form.slug}`}
          </Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          {!isNew && (
            <>
              <Button
                variant="outlined"
                startIcon={<PublishIcon />}
                disabled={publish.isPending || form.status === "published"}
                onClick={() => publish.mutate(pressReleaseId!)}
                sx={{ textTransform: "none" }}
              >
                Publicar
              </Button>
              <Button
                variant="outlined"
                color="error"
                startIcon={<DeleteOutline />}
                disabled={del.isPending}
                onClick={async () => {
                  if (!confirm("¿Eliminar este comunicado?")) return;
                  await del.mutateAsync(pressReleaseId!);
                  router.push("/admin/prensa");
                }}
                sx={{ textTransform: "none" }}
              >
                Eliminar
              </Button>
            </>
          )}
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            disabled={upsert.isPending}
            onClick={save}
            sx={{ bgcolor: "#ff9900", color: "#131921", fontWeight: 700, textTransform: "none" }}
          >
            {upsert.isPending ? "Guardando…" : "Guardar"}
          </Button>
        </Stack>
      </Stack>

      {upsert.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Comunicado guardado correctamente.
        </Alert>
      )}
      {upsert.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(upsert.error as Error)?.message}
        </Alert>
      )}

      <Paper>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider" }}>
          <Tab label="Info" />
          <Tab label="Cuerpo (Markdown)" />
          <Tab label="Preview" />
        </Tabs>

        {tab === 0 && (
          <Box sx={{ p: 3 }}>
            <Stack spacing={2}>
              <TextField
                label="Slug"
                value={form.slug}
                onChange={(e) => setField("slug", e.target.value)}
                fullWidth
                required
                helperText="URL: /prensa/<slug>"
              />
              <TextField
                label="Título"
                value={form.title}
                onChange={(e) => setField("title", e.target.value)}
                fullWidth
                required
              />
              <TextField
                label="Resumen (excerpt)"
                value={form.excerpt}
                onChange={(e) => setField("excerpt", e.target.value)}
                fullWidth
                multiline
                minRows={2}
                helperText="Texto corto mostrado en la lista de prensa."
              />
              <TextField
                label="Imagen de portada (URL)"
                value={form.coverImageUrl}
                onChange={(e) => setField("coverImageUrl", e.target.value)}
                fullWidth
              />
              <Autocomplete
                multiple
                freeSolo
                options={[]}
                value={form.tags}
                onChange={(_, v) => setField("tags", v.map(String))}
                renderTags={(values, getTagProps) =>
                  values.map((option, index) => (
                    <Chip variant="outlined" label={option} {...getTagProps({ index })} key={option} />
                  ))
                }
                renderInput={(params) => (
                  <TextField {...params} label="Tags" placeholder="Agregar y presionar Enter" />
                )}
              />
              <FormControl fullWidth>
                <InputLabel>Estado</InputLabel>
                <Select
                  label="Estado"
                  value={form.status}
                  onChange={(e) => setField("status", e.target.value as FormState["status"])}
                >
                  <MenuItem value="draft">Borrador</MenuItem>
                  <MenuItem value="published">Publicado</MenuItem>
                  <MenuItem value="archived">Archivado</MenuItem>
                </Select>
              </FormControl>
            </Stack>
          </Box>
        )}

        {tab === 1 && (
          <Box sx={{ p: 3 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              Markdown básico: <code># Título</code>, <code>## Subtítulo</code>, <code>**negrita**</code>, listas con <code>-</code>, separador <code>---</code>.
            </Typography>
            <TextField
              value={form.body}
              onChange={(e) => setField("body", e.target.value)}
              fullWidth
              multiline
              minRows={24}
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
            />
          </Box>
        )}

        {tab === 2 && (
          <Box sx={{ p: 4, bgcolor: "#fff" }}>
            <Typography variant="h3" fontWeight={700} gutterBottom>
              {form.title || "(sin título)"}
            </Typography>
            {form.excerpt && (
              <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
                {form.excerpt}
              </Typography>
            )}
            <Box>{renderMarkdown(form.body || "")}</Box>
          </Box>
        )}
      </Paper>
    </Box>
  );
}
