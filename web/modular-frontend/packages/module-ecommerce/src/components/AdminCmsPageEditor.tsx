"use client";

import React, { useState, useMemo, useEffect } from "react";
import {
  Alert,
  Box,
  Button,
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
  useAdminCmsPage,
  useUpsertCmsPage,
  usePublishCmsPage,
  useDeleteCmsPage,
} from "../hooks/useCmsPage";
import StudioPageRenderer, { type LandingConfig } from "./StudioPageRenderer";

interface FormState {
  slug: string;
  title: string;
  subtitle: string;
  templateKey: string;
  status: "draft" | "published" | "archived";
  configJson: string;
  seoJson: string;
}

const EMPTY_FORM: FormState = {
  slug: "",
  title: "",
  subtitle: "",
  templateKey: "content",
  status: "draft",
  configJson: JSON.stringify({ sections: [{ type: "hero", title: "Nueva página" }] }, null, 2),
  seoJson: "{}",
};

export interface AdminCmsPageEditorProps {
  cmsPageId?: number | null;
}

export default function AdminCmsPageEditor({ cmsPageId }: AdminCmsPageEditorProps) {
  const router = useRouter();
  const isNew = !cmsPageId;
  const { data, isLoading } = useAdminCmsPage(cmsPageId ?? null);
  const upsert = useUpsertCmsPage();
  const publish = usePublishCmsPage();
  const del = useDeleteCmsPage();

  const [tab, setTab] = useState(0);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [configError, setConfigError] = useState<string>("");
  const [seoError, setSeoError] = useState<string>("");

  useEffect(() => {
    if (!isNew && data?.page) {
      setForm({
        slug: data.page.slug,
        title: data.page.title,
        subtitle: data.page.subtitle ?? "",
        templateKey: data.page.templateKey ?? "",
        status: (data.page.status as FormState["status"]) ?? "draft",
        configJson: JSON.stringify(data.page.config ?? { sections: [] }, null, 2),
        seoJson: JSON.stringify(data.page.seo ?? {}, null, 2),
      });
    }
  }, [data, isNew]);

  const parsedConfig: LandingConfig | null = useMemo(() => {
    try {
      const obj = JSON.parse(form.configJson);
      setConfigError("");
      return obj;
    } catch (e) {
      setConfigError((e as Error).message);
      return null;
    }
  }, [form.configJson]);

  const parsedSeo = useMemo(() => {
    try {
      JSON.parse(form.seoJson);
      setSeoError("");
      return true;
    } catch (e) {
      setSeoError((e as Error).message);
      return false;
    }
  }, [form.seoJson]);

  function setField<K extends keyof FormState>(k: K, v: FormState[K]) {
    setForm((s) => ({ ...s, [k]: v }));
  }

  async function save() {
    if (configError || seoError) return;
    if (!form.slug.trim() || !form.title.trim()) return;
    const payload = {
      cmsPageId: cmsPageId ?? undefined,
      slug: form.slug.trim(),
      title: form.title.trim(),
      subtitle: form.subtitle.trim() || null,
      templateKey: form.templateKey.trim() || null,
      config: JSON.parse(form.configJson),
      seo: JSON.parse(form.seoJson),
      status: form.status,
    };
    const res = await upsert.mutateAsync(payload);
    if ((res as any)?.cmsPageId && isNew) {
      router.push(`/admin/cms/${(res as any).cmsPageId}`);
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
          <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/admin/cms")} sx={{ textTransform: "none" }}>
            Volver
          </Button>
          <Typography variant="h5" fontWeight={700}>
            {isNew ? "Nueva página" : `Editar: ${form.title || form.slug}`}
          </Typography>
        </Stack>
        <Stack direction="row" spacing={1}>
          {!isNew && (
            <>
              <Button
                variant="outlined"
                color="primary"
                startIcon={<PublishIcon />}
                disabled={publish.isPending || form.status === "published"}
                onClick={() => publish.mutate(cmsPageId!)}
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
                  if (!confirm("¿Eliminar esta página? Esta acción no se puede deshacer.")) return;
                  await del.mutateAsync(cmsPageId!);
                  router.push("/admin/cms");
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
            disabled={!!configError || !!seoError || upsert.isPending}
            onClick={save}
            sx={{ bgcolor: "#ff9900", color: "#131921", fontWeight: 700, textTransform: "none" }}
          >
            {upsert.isPending ? "Guardando…" : "Guardar"}
          </Button>
        </Stack>
      </Stack>

      {upsert.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Página guardada correctamente.
        </Alert>
      )}
      {upsert.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(upsert.error as Error)?.message}
        </Alert>
      )}

      <Paper sx={{ p: 0 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider" }}>
          <Tab label="Info" />
          <Tab label="Secciones (JSON)" />
          <Tab label="SEO" />
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
                helperText="Identificador en la URL (ej: acerca, contacto, centro-de-ayuda)"
              />
              <TextField
                label="Título"
                value={form.title}
                onChange={(e) => setField("title", e.target.value)}
                fullWidth
                required
              />
              <TextField
                label="Subtítulo"
                value={form.subtitle}
                onChange={(e) => setField("subtitle", e.target.value)}
                fullWidth
              />
              <TextField
                label="Template key"
                value={form.templateKey}
                onChange={(e) => setField("templateKey", e.target.value)}
                fullWidth
                helperText="Referencia al template del studio (ej: content, faq, contact). Opcional."
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
              JSON con array <code>sections</code>. Tipos soportados: hero, content, features, faq, cta, contact, stats.
            </Typography>
            <TextField
              value={form.configJson}
              onChange={(e) => setField("configJson", e.target.value)}
              fullWidth
              multiline
              minRows={20}
              error={!!configError}
              helperText={configError || "JSON válido del LandingConfig."}
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
            />
          </Box>
        )}

        {tab === 2 && (
          <Box sx={{ p: 3 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              JSON con metadatos SEO (title, description, ogImage, etc.).
            </Typography>
            <TextField
              value={form.seoJson}
              onChange={(e) => setField("seoJson", e.target.value)}
              fullWidth
              multiline
              minRows={10}
              error={!!seoError}
              helperText={seoError || "JSON válido del SEO config."}
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
            />
          </Box>
        )}

        {tab === 3 && (
          <Box sx={{ p: 0 }}>
            {configError ? (
              <Alert severity="error" sx={{ m: 3 }}>
                JSON inválido: {configError}
              </Alert>
            ) : (
              <StudioPageRenderer config={parsedConfig} />
            )}
          </Box>
        )}
      </Paper>
    </Box>
  );
}
