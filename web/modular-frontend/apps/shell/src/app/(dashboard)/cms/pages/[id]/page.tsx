"use client";

/**
 * Editor de página corporativa CMS.
 *
 * Maneja tanto `/new` (creación) como `/:id` (edición). Para crear una
 * página, el usuario elige un tipo (about, contact, press, legal-terms,
 * legal-privacy, case-study, custom) y se inserta un schema `landingConfig`
 * starter. El admin puede luego editarlo como JSON plano y publicar.
 *
 * Acciones: Guardar (PUT), Publicar (POST /:id/publish), Eliminar (DELETE).
 */

import React, { useEffect, useMemo, useState } from "react";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import {
  Box, Button, Paper, Stack, Chip, Alert, LinearProgress, Typography,
  TextField, MenuItem, IconButton, Tooltip, Divider,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import DeleteIcon from "@mui/icons-material/Delete";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import AutoFixHighIcon from "@mui/icons-material/AutoFixHigh";
import FormatIndentIncreaseIcon from "@mui/icons-material/FormatIndentIncrease";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  listPages, upsertPage, publishPage, deletePage,
  VERTICALS, CMS_PAGE_TYPES, PAGE_TYPE_LABELS, PAGE_TYPE_COLORS,
  pageTemplateMeta, slugify, buildPagePublicUrl,
  type CmsPage, type CmsPageType,
} from "../_lib";

const STATUS_COLOR: Record<string, "default" | "success" | "warning"> = {
  draft: "warning",
  published: "success",
  archived: "default",
};

const LOCALES = [
  { value: "es", label: "Español" },
  { value: "en", label: "English" },
  { value: "pt", label: "Português" },
];

function fmtTime(d: Date | null) {
  if (!d) return "";
  try {
    return d.toLocaleTimeString("es", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  } catch {
    return "";
  }
}

export default function CmsPageEditorPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const search = useSearchParams();
  const qc = useQueryClient();

  const rawId = params?.id ?? "new";
  const isNew = rawId === "new";
  const numericId = isNew ? 0 : Number(rawId);
  const idValid = isNew || (Number.isFinite(numericId) && numericId > 0);

  // ── Fields ────────────────────────────────────────────────────────────────
  const initialPageType = (search?.get("pageType") as CmsPageType | null) ?? "about";
  const [pageType, setPageType] = useState<CmsPageType>(initialPageType);
  const [title, setTitle] = useState<string>("");
  const [slug, setSlug] = useState<string>("");
  const [autoSlug, setAutoSlug] = useState<boolean>(true);
  const [vertical, setVertical] = useState<string>("corporate");
  const [locale, setLocale] = useState<string>("es");
  const [seoTitle, setSeoTitle] = useState<string>("");
  const [seoDescription, setSeoDescription] = useState<string>("");
  const [status, setStatus] = useState<string>("draft");

  // `meta` se edita como string JSON y se parsea al guardar.
  const [metaJson, setMetaJson] = useState<string>(() =>
    JSON.stringify(pageTemplateMeta(initialPageType, "corporate"), null, 2),
  );
  const [jsonError, setJsonError] = useState<string | null>(null);
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null);
  const [banner, setBanner] = useState<{ level: "success" | "info" | "error"; msg: string } | null>(
    null,
  );

  // ── Edit mode: obtener la página por list + filtrar por id ───────────────
  // El endpoint GET /pages/:slug usa slug, no id — para buscar por ID, hacemos
  // list y tomamos la que coincida. Si el admin abre /cms/pages/123, listamos
  // (con límite alto) y localizamos la page.
  const { data: listData, isLoading, error } = useQuery({
    queryKey: ["cms-pages-admin", "all"],
    queryFn: () => listPages({ limit: 200 }),
    enabled: !isNew && idValid,
  });

  const current: CmsPage | undefined = useMemo(() => {
    if (isNew) return undefined;
    return listData?.data?.find((p) => Number(p.PageId) === numericId);
  }, [isNew, listData?.data, numericId]);

  // Hidratar campos al cargar
  useEffect(() => {
    if (!current) return;
    setTitle(current.Title ?? "");
    setSlug(current.Slug ?? "");
    setAutoSlug(false);
    setVertical(current.Vertical ?? "corporate");
    setLocale(current.Locale ?? "es");
    setSeoTitle(current.SeoTitle ?? "");
    setSeoDescription(current.SeoDescription ?? "");
    setStatus(current.Status ?? "draft");
    setPageType((current.PageType as CmsPageType) ?? "custom");
    try {
      setMetaJson(JSON.stringify(current.Meta ?? {}, null, 2));
    } catch {
      setMetaJson("{}");
    }
  }, [current]);

  // auto-slug si está activo
  useEffect(() => {
    if (autoSlug) setSlug(slugify(title));
  }, [title, autoSlug]);

  // ── Mutations ────────────────────────────────────────────────────────────
  const saveMut = useMutation({
    mutationFn: async (opts: { publishAfter?: boolean } = {}) => {
      let parsedMeta: Record<string, unknown> = {};
      try {
        parsedMeta = JSON.parse(metaJson || "{}");
      } catch (e: any) {
        throw new Error("JSON inválido en meta: " + e.message);
      }

      const body: Partial<CmsPage> = {
        Slug: slug || slugify(title) || "sin-titulo",
        Title: title || "Sin título",
        Vertical: vertical,
        Locale: locale,
        PageType: pageType,
        Meta: parsedMeta,
        SeoTitle: seoTitle,
        SeoDescription: seoDescription,
      };

      const res = await upsertPage(isNew ? "new" : numericId, body);
      if (!res.ok) throw new Error(res.mensaje || "Error guardando página");

      if (opts.publishAfter && res.page_id) {
        const pub = await publishPage(res.page_id);
        if (!pub.ok) throw new Error(pub.mensaje || "Error publicando");
      }
      return res;
    },
    onSuccess: (res, vars) => {
      setLastSavedAt(new Date());
      setBanner({
        level: "success",
        msg: vars?.publishAfter
          ? "Página guardada y publicada. Disponible en ~30s."
          : "Borrador guardado.",
      });
      qc.invalidateQueries({ queryKey: ["cms-pages-admin"] });
      if (isNew && res?.page_id) {
        router.replace(`/cms/pages/${res.page_id}`);
      }
    },
    onError: (err: any) => {
      setBanner({ level: "error", msg: err?.message ?? "Error guardando" });
    },
  });

  const deleteMut = useMutation({
    mutationFn: () => {
      if (!current) throw new Error("Página no cargada");
      return deletePage(current.PageId);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["cms-pages-admin"] });
      router.push("/cms/pages");
    },
    onError: (err: any) => {
      setBanner({ level: "error", msg: err?.message ?? "Error eliminando" });
    },
  });

  // ── JSON helpers ─────────────────────────────────────────────────────────
  function handleValidateJson() {
    try {
      JSON.parse(metaJson || "{}");
      setJsonError(null);
      setBanner({ level: "success", msg: "JSON válido." });
    } catch (e: any) {
      setJsonError(e.message);
      setBanner({ level: "error", msg: "JSON inválido: " + e.message });
    }
  }

  function handleFormatJson() {
    try {
      const parsed = JSON.parse(metaJson || "{}");
      setMetaJson(JSON.stringify(parsed, null, 2));
      setJsonError(null);
    } catch (e: any) {
      setJsonError(e.message);
      setBanner({ level: "error", msg: "No se puede formatear: " + e.message });
    }
  }

  function handleLoadTemplate(t: CmsPageType) {
    setPageType(t);
    setMetaJson(JSON.stringify(pageTemplateMeta(t, vertical), null, 2));
    setBanner({ level: "info", msg: `Plantilla "${PAGE_TYPE_LABELS[t]}" cargada.` });
  }

  // ── Render ───────────────────────────────────────────────────────────────
  if (!idValid) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="error">ID inválido: {rawId}</Alert>
      </Box>
    );
  }

  if (!isNew && isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <LinearProgress />
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
          Cargando página…
        </Typography>
      </Box>
    );
  }

  if (!isNew && error) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="error">{(error as Error).message}</Alert>
      </Box>
    );
  }

  if (!isNew && !current) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="warning">
          No se encontró la página #{numericId}. Puede estar en otra vertical o haber sido eliminada.
        </Alert>
        <Button sx={{ mt: 2 }} onClick={() => router.push("/cms/pages")} startIcon={<ArrowBackIcon />}>
          Volver al listado
        </Button>
      </Box>
    );
  }

  const previewUrl = buildPagePublicUrl(vertical, slug || "default");
  const isPublished = status === "published";

  return (
    <Box sx={{ p: 3, maxWidth: 1400, mx: "auto" }}>
      {/* Top bar */}
      <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
        <Tooltip title="Volver al listado">
          <IconButton size="small" onClick={() => router.push("/cms/pages")}>
            <ArrowBackIcon />
          </IconButton>
        </Tooltip>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography variant="h5" fontWeight={700} noWrap>
            {isNew ? "Nueva página" : `Editar: ${title || "(sin título)"}`}
          </Typography>
          <Stack direction="row" spacing={1} alignItems="center" sx={{ mt: 0.5 }}>
            <Chip
              label={status}
              size="small"
              color={STATUS_COLOR[status] ?? "default"}
              sx={{ textTransform: "capitalize" }}
            />
            <Chip
              label={PAGE_TYPE_LABELS[pageType] ?? pageType}
              size="small"
              color={PAGE_TYPE_COLORS[pageType] ?? "default"}
            />
            {!isNew && current && (
              <Typography variant="caption" color="text.secondary">
                #{current.PageId}
              </Typography>
            )}
            {saveMut.isPending ? (
              <Typography variant="caption" color="text.secondary">Guardando…</Typography>
            ) : lastSavedAt ? (
              <Stack direction="row" spacing={0.5} alignItems="center">
                <CheckCircleIcon fontSize="inherit" color="success" />
                <Typography variant="caption" color="success.main">
                  Guardado {fmtTime(lastSavedAt)}
                </Typography>
              </Stack>
            ) : null}
          </Stack>
        </Box>
        <Button
          variant="outlined"
          size="small"
          startIcon={<OpenInNewIcon />}
          disabled={!isPublished}
          onClick={() => window.open(previewUrl, "_blank", "noopener,noreferrer")}
        >
          Ver pública
        </Button>
        <Button
          variant="outlined"
          size="small"
          startIcon={<SaveIcon />}
          onClick={() => saveMut.mutate({})}
          disabled={saveMut.isPending}
        >
          Guardar borrador
        </Button>
        <Button
          variant="contained"
          size="small"
          color="primary"
          startIcon={<PublishIcon />}
          onClick={() => saveMut.mutate({ publishAfter: true })}
          disabled={saveMut.isPending}
        >
          {saveMut.isPending ? "Publicando…" : "Publicar"}
        </Button>
        {!isNew && (
          <Button
            variant="outlined"
            size="small"
            color="error"
            startIcon={<DeleteIcon />}
            onClick={() => {
              if (confirm(`¿Eliminar "${title}"? No se puede deshacer.`)) {
                deleteMut.mutate();
              }
            }}
            disabled={deleteMut.isPending}
          >
            Eliminar
          </Button>
        )}
      </Stack>

      {banner && (
        <Alert severity={banner.level} onClose={() => setBanner(null)} sx={{ mb: 2 }}>
          {banner.msg}
        </Alert>
      )}

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", lg: "minmax(0, 1fr) minmax(0, 1fr)" },
          gap: 2,
        }}
      >
        {/* ── Columna izquierda: campos básicos ─────────────────────── */}
        <Paper variant="outlined" sx={{ p: 3 }}>
          <Typography variant="subtitle2" fontWeight={700} gutterBottom>
            Datos básicos
          </Typography>
          <Stack spacing={2}>
            <TextField
              label="Título"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              fullWidth
              size="small"
              required
            />

            <Stack direction="row" spacing={1} alignItems="center">
              <TextField
                label="Slug"
                value={slug}
                onChange={(e) => {
                  setSlug(e.target.value);
                  setAutoSlug(false);
                }}
                fullWidth
                size="small"
                helperText={autoSlug ? "Se genera automáticamente desde el título" : undefined}
              />
              <Button
                size="small"
                variant={autoSlug ? "contained" : "outlined"}
                onClick={() => setAutoSlug((v) => !v)}
                startIcon={<AutoFixHighIcon />}
              >
                Auto
              </Button>
            </Stack>

            <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
              <TextField
                select
                label="Vertical"
                value={vertical}
                onChange={(e) => setVertical(e.target.value)}
                size="small"
                fullWidth
              >
                {VERTICALS.map((v) => (
                  <MenuItem key={v.value} value={v.value}>
                    {v.label}
                  </MenuItem>
                ))}
              </TextField>
              <TextField
                select
                label="Tipo de página"
                value={pageType}
                onChange={(e) => setPageType(e.target.value as CmsPageType)}
                size="small"
                fullWidth
              >
                {CMS_PAGE_TYPES.map((t) => (
                  <MenuItem key={t} value={t}>
                    {PAGE_TYPE_LABELS[t]}
                  </MenuItem>
                ))}
              </TextField>
              <TextField
                select
                label="Locale"
                value={locale}
                onChange={(e) => setLocale(e.target.value)}
                size="small"
                sx={{ minWidth: 140 }}
              >
                {LOCALES.map((l) => (
                  <MenuItem key={l.value} value={l.value}>
                    {l.label}
                  </MenuItem>
                ))}
              </TextField>
            </Stack>

            <Divider />

            <Typography variant="subtitle2" fontWeight={700}>
              SEO
            </Typography>
            <TextField
              label="SEO Title"
              value={seoTitle}
              onChange={(e) => setSeoTitle(e.target.value)}
              fullWidth
              size="small"
              inputProps={{ maxLength: 300 }}
            />
            <TextField
              label="SEO Description"
              value={seoDescription}
              onChange={(e) => setSeoDescription(e.target.value)}
              fullWidth
              size="small"
              multiline
              minRows={2}
              inputProps={{ maxLength: 500 }}
            />
          </Stack>
        </Paper>

        {/* ── Columna derecha: editor JSON del schema ───────────────── */}
        <Paper variant="outlined" sx={{ p: 3, display: "flex", flexDirection: "column" }}>
          <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
            <Typography variant="subtitle2" fontWeight={700}>
              Schema (meta.landingConfig)
            </Typography>
            <Stack direction="row" spacing={1}>
              <Tooltip title="Validar JSON">
                <Button size="small" onClick={handleValidateJson}>
                  Validar
                </Button>
              </Tooltip>
              <Tooltip title="Formatear (indentar)">
                <Button
                  size="small"
                  startIcon={<FormatIndentIncreaseIcon />}
                  onClick={handleFormatJson}
                >
                  Formato
                </Button>
              </Tooltip>
              <TextField
                select
                size="small"
                label="Plantilla"
                value=""
                onChange={(e) => handleLoadTemplate(e.target.value as CmsPageType)}
                sx={{ minWidth: 180 }}
              >
                <MenuItem value="" disabled>
                  Cargar plantilla…
                </MenuItem>
                {CMS_PAGE_TYPES.map((t) => (
                  <MenuItem key={t} value={t}>
                    {PAGE_TYPE_LABELS[t]}
                  </MenuItem>
                ))}
              </TextField>
            </Stack>
          </Stack>

          {jsonError && (
            <Alert severity="error" sx={{ mb: 1 }} onClose={() => setJsonError(null)}>
              {jsonError}
            </Alert>
          )}

          <TextField
            value={metaJson}
            onChange={(e) => {
              setMetaJson(e.target.value);
              setJsonError(null);
            }}
            fullWidth
            multiline
            minRows={20}
            maxRows={30}
            InputProps={{
              sx: {
                fontFamily: '"JetBrains Mono", "Fira Code", Consolas, monospace',
                fontSize: "0.8125rem",
                lineHeight: 1.5,
              },
            }}
            placeholder='{ "landingConfig": { "hero": { "title": "..." } } }'
          />

          <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
            El objeto se guarda en `cms.Page.Meta` (JSONB). El renderer en cada
            landing lee `meta.landingConfig` y lo pasa a `@zentto/landing-kit`.
          </Typography>
        </Paper>
      </Box>

      {/* Preview iframe (opcional, si la página ya tiene slug + vertical) */}
      {!isNew && isPublished && (
        <Paper variant="outlined" sx={{ mt: 2, overflow: "hidden" }}>
          <Stack direction="row" alignItems="center" spacing={1} sx={{ px: 2, py: 1, borderBottom: 1, borderColor: "divider" }}>
            <Typography variant="subtitle2" fontWeight={700} sx={{ flex: 1 }}>
              Preview (iframe)
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {previewUrl}
            </Typography>
            <IconButton
              size="small"
              onClick={() => window.open(previewUrl, "_blank", "noopener,noreferrer")}
            >
              <OpenInNewIcon fontSize="small" />
            </IconButton>
          </Stack>
          <Box
            component="iframe"
            src={previewUrl}
            sx={{ width: "100%", height: 600, border: 0, display: "block" }}
            title="Preview"
          />
        </Paper>
      )}
    </Box>
  );
}
