"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
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
  ToggleButton,
  ToggleButtonGroup,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import DeleteOutline from "@mui/icons-material/DeleteOutline";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import DesktopWindowsOutlined from "@mui/icons-material/DesktopWindowsOutlined";
import TabletMacOutlined from "@mui/icons-material/TabletMacOutlined";
import PhoneIphoneOutlined from "@mui/icons-material/PhoneIphoneOutlined";
import { useRouter } from "next/navigation";
import {
  useAdminCmsPage,
  useUpsertCmsPage,
  usePublishCmsPage,
  useDeleteCmsPage,
} from "../hooks/useCmsPage";
import StudioPageRenderer, { type LandingConfig } from "./StudioPageRenderer";

/** Ancho simulado del preview por dispositivo — Ola 3 spec. */
const PREVIEW_WIDTHS: Record<string, number | string> = {
  desktop: "100%",
  tablet: 820,
  mobile: 390,
};

type PreviewDevice = "desktop" | "tablet" | "mobile";

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
  const theme = useTheme();
  const isDesktop = useMediaQuery(theme.breakpoints.up("lg"));
  const isNew = !cmsPageId;
  const { data, isLoading } = useAdminCmsPage(cmsPageId ?? null);
  const upsert = useUpsertCmsPage();
  const publish = usePublishCmsPage();
  const del = useDeleteCmsPage();

  const [tab, setTab] = useState(0);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [configError, setConfigError] = useState<string>("");
  const [seoError, setSeoError] = useState<string>("");
  const [previewDevice, setPreviewDevice] = useState<PreviewDevice>("desktop");

  // Debounce 500 ms para el preview live (Ola 3 spec).
  const [debouncedConfigJson, setDebouncedConfigJson] = useState(form.configJson);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setDebouncedConfigJson(form.configJson);
    }, 500);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [form.configJson]);

  useEffect(() => {
    if (!isNew && data?.page) {
      const nextConfigJson = JSON.stringify(data.page.config ?? { sections: [] }, null, 2);
      setForm({
        slug: data.page.slug,
        title: data.page.title,
        subtitle: data.page.subtitle ?? "",
        templateKey: data.page.templateKey ?? "",
        status: (data.page.status as FormState["status"]) ?? "draft",
        configJson: nextConfigJson,
        seoJson: JSON.stringify(data.page.seo ?? {}, null, 2),
      });
      setDebouncedConfigJson(nextConfigJson);
    }
  }, [data, isNew]);

  const parsedConfig: LandingConfig | null = useMemo(() => {
    try {
      const obj = JSON.parse(debouncedConfigJson);
      setConfigError("");
      return obj;
    } catch (e) {
      setConfigError((e as Error).message);
      return null;
    }
  }, [debouncedConfigJson]);

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

      {/* Editor form (Info / Secciones / SEO) */}
      {(() => {
        const editorPane = (
          <Paper sx={{ p: 0, height: "100%", display: "flex", flexDirection: "column" }}>
            <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider" }}>
              <Tab label="Info" />
              <Tab label="Secciones (JSON)" />
              <Tab label="SEO" />
              {!isDesktop && <Tab label="Preview" />}
            </Tabs>

            {tab === 0 && (
              <Box sx={{ p: 3, flex: 1, overflow: "auto" }}>
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
              <Box sx={{ p: 3, flex: 1, overflow: "auto" }}>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  JSON con array <code>sections</code>. Tipos soportados: hero, content, features, faq, cta,
                  contact, stats, team, timeline, jobs, return-steps.
                </Typography>
                <TextField
                  value={form.configJson}
                  onChange={(e) => setField("configJson", e.target.value)}
                  fullWidth
                  multiline
                  minRows={20}
                  error={!!configError}
                  helperText={configError || "JSON válido del LandingConfig — preview se refresca con debounce de 500 ms."}
                  InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
                />
              </Box>
            )}

            {tab === 2 && (
              <Box sx={{ p: 3, flex: 1, overflow: "auto" }}>
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

            {!isDesktop && tab === 3 && (
              <Box sx={{ p: 0, flex: 1, overflow: "auto" }}>
                <PreviewPane
                  configError={configError}
                  parsedConfig={parsedConfig}
                  previewDevice={previewDevice}
                  onDeviceChange={setPreviewDevice}
                />
              </Box>
            )}
          </Paper>
        );

        const previewPane = (
          <Paper sx={{ p: 0, height: "100%", display: "flex", flexDirection: "column" }}>
            <PreviewPane
              configError={configError}
              parsedConfig={parsedConfig}
              previewDevice={previewDevice}
              onDeviceChange={setPreviewDevice}
            />
          </Paper>
        );

        if (isDesktop) {
          return (
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 2,
                height: "calc(100vh - 240px)",
                minHeight: 600,
              }}
            >
              {editorPane}
              {previewPane}
            </Box>
          );
        }
        return editorPane;
      })()}
    </Box>
  );
}

/**
 * Panel de preview con toggle desktop/tablet/mobile — Ola 3.
 */
function PreviewPane({
  configError,
  parsedConfig,
  previewDevice,
  onDeviceChange,
}: {
  configError: string;
  parsedConfig: LandingConfig | null;
  previewDevice: PreviewDevice;
  onDeviceChange: (d: PreviewDevice) => void;
}) {
  return (
    <>
      <Box
        sx={{
          px: 2,
          py: 1.5,
          borderBottom: 1,
          borderColor: "divider",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 2,
        }}
      >
        <Typography variant="subtitle2" fontWeight={700}>
          Preview live
        </Typography>
        <ToggleButtonGroup
          size="small"
          exclusive
          value={previewDevice}
          onChange={(_, v: PreviewDevice | null) => {
            if (v) onDeviceChange(v);
          }}
        >
          <ToggleButton value="desktop" aria-label="Escritorio">
            <DesktopWindowsOutlined sx={{ fontSize: 18 }} />
          </ToggleButton>
          <ToggleButton value="tablet" aria-label="Tablet">
            <TabletMacOutlined sx={{ fontSize: 18 }} />
          </ToggleButton>
          <ToggleButton value="mobile" aria-label="Móvil">
            <PhoneIphoneOutlined sx={{ fontSize: 18 }} />
          </ToggleButton>
        </ToggleButtonGroup>
      </Box>
      <Box sx={{ flex: 1, overflow: "auto", bgcolor: "#eaeded", p: 2 }}>
        {configError ? (
          <Alert severity="error">JSON inválido: {configError}</Alert>
        ) : (
          <Box
            sx={{
              width: PREVIEW_WIDTHS[previewDevice],
              maxWidth: "100%",
              mx: "auto",
              bgcolor: "#fff",
              boxShadow: previewDevice === "desktop" ? "none" : "0 4px 20px rgba(0,0,0,0.1)",
              borderRadius: previewDevice === "desktop" ? 0 : 2,
              overflow: "hidden",
              transition: "width 200ms ease",
            }}
          >
            <StudioPageRenderer config={parsedConfig} />
          </Box>
        )}
      </Box>
    </>
  );
}
