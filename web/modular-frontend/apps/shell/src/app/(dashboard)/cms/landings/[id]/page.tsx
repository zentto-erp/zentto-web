"use client";

/**
 * Editor visual de landings — embebe <ZenttoLandingDesigner> (web component
 * Lit del paquete `@zentto/studio-react/landing-designer`).
 *
 * Reglas técnicas:
 *  - Lit NO puede renderizarse en SSR. Importamos el componente via `next/dynamic`
 *    con `ssr: false` para que solo se monte client-side.
 *  - Auto-save cada 5s vía el evento `auto-save` del designer (`onAutoSave`).
 *  - Publish dispara POST /v1/cms/landings/:id/publish → el API dispara un
 *    webhook revalidate al frontend del vertical (~30s de propagación).
 */

import React, { useCallback, useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import { useParams, useRouter } from "next/navigation";
import {
  Box, Button, Paper, Stack, Chip, Alert, LinearProgress, Typography,
  TextField, MenuItem, IconButton, Tooltip,
} from "@mui/material";
import PublishIcon from "@mui/icons-material/Publish";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import RefreshIcon from "@mui/icons-material/Refresh";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import SaveIcon from "@mui/icons-material/Save";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  getLanding, upsertLandingDraft, publishLanding, rotatePreviewToken,
  VERTICALS, buildPublicUrl, emptyLandingSchema,
  type LandingDetail,
} from "../_lib";

// Lit web component — NUNCA en SSR.
const ZenttoLandingDesigner = dynamic(
  () =>
    import("@zentto/studio-react/landing-designer").then(
      (m) => m.ZenttoLandingDesigner,
    ),
  {
    ssr: false,
    loading: () => (
      <Box sx={{ p: 4 }}>
        <LinearProgress />
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
          Cargando editor visual…
        </Typography>
      </Box>
    ),
  },
);

const STATUS_COLOR: Record<string, "default" | "success" | "warning"> = {
  draft: "warning",
  published: "success",
  archived: "default",
};

function fmtTime(d: Date | null) {
  if (!d) return "";
  try {
    return d.toLocaleTimeString("es", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  } catch {
    return "";
  }
}

// ─── Sidebar para crear una landing nueva (vertical + slug + locale) ─────────
function NewLandingForm({ onCreated }: { onCreated: (id: number) => void }) {
  const [vertical, setVertical] = useState<string>("hotel");
  const [slug, setSlug] = useState<string>("default");
  const [locale, setLocale] = useState<string>("es");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCreate() {
    setSaving(true);
    setError(null);
    try {
      const res = await upsertLandingDraft("new", {
        vertical,
        slug: slug || "default",
        locale,
        draftSchema: emptyLandingSchema(vertical, slug || "default"),
      });
      const id = res?.data?.landingSchemaId;
      if (!id) throw new Error("No se recibió landingSchemaId del backend");
      onCreated(id);
    } catch (e: any) {
      setError(e?.message ?? "Error creando landing");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Box sx={{ p: 3, maxWidth: 560, mx: "auto" }}>
      <Paper variant="outlined" sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Nueva landing
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Inicia con un schema vacío. Luego podrás agregar secciones visualmente desde el editor.
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <TextField
          select
          label="Vertical"
          value={vertical}
          onChange={(e) => setVertical(e.target.value)}
          fullWidth
          sx={{ mb: 2 }}
          required
        >
          {VERTICALS.map((v) => (
            <MenuItem key={v.value} value={v.value}>
              {v.label}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          label="Slug"
          value={slug}
          onChange={(e) => setSlug(e.target.value)}
          fullWidth
          sx={{ mb: 2 }}
          helperText='Ej: "default" (home del vertical) o "para-hoteles-premium".'
        />

        <TextField
          select
          label="Locale"
          value={locale}
          onChange={(e) => setLocale(e.target.value)}
          fullWidth
          sx={{ mb: 3 }}
        >
          <MenuItem value="es">es</MenuItem>
          <MenuItem value="en">en</MenuItem>
          <MenuItem value="pt">pt</MenuItem>
        </TextField>

        <Stack direction="row" spacing={1} justifyContent="flex-end">
          <Button onClick={() => history.back()} disabled={saving}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={handleCreate}
            disabled={saving || !vertical || !slug}
          >
            Crear y abrir editor
          </Button>
        </Stack>
      </Paper>
    </Box>
  );
}

// ─── Editor principal ────────────────────────────────────────────────────────
export default function LandingEditorPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();

  const rawId = params?.id ?? "new";
  const isNew = rawId === "new";
  const numericId = isNew ? 0 : Number(rawId);
  const idValid = isNew || (Number.isFinite(numericId) && numericId > 0);

  const { data, isLoading, error } = useQuery({
    queryKey: ["cms-landing", numericId],
    queryFn: () => getLanding(numericId),
    enabled: !isNew && idValid,
  });

  const landing: LandingDetail | undefined = data?.data;

  const [config, setConfig] = useState<Record<string, unknown> | null>(null);
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null);
  const [banner, setBanner] = useState<{ level: "success" | "info" | "error"; msg: string } | null>(
    null,
  );

  // Inicializa el config local cuando llega el detalle.
  useEffect(() => {
    if (landing?.draftSchema) {
      setConfig(landing.draftSchema);
    }
  }, [landing?.draftSchema]);

  const saveMut = useMutation({
    mutationFn: (newConfig: Record<string, unknown>) => {
      if (!landing) throw new Error("Landing no cargada");
      return upsertLandingDraft(numericId, {
        vertical: landing.vertical,
        slug: landing.slug,
        locale: landing.locale,
        draftSchema: newConfig,
        themeTokens: landing.themeTokens ?? null,
        seoMeta: landing.seoMeta ?? null,
      });
    },
    onSuccess: () => {
      setLastSavedAt(new Date());
    },
    onError: (err: any) => {
      setBanner({ level: "error", msg: err?.message ?? "Error guardando borrador" });
    },
  });

  const publishMut = useMutation({
    mutationFn: () => publishLanding(numericId),
    onSuccess: (res) => {
      const v = res?.data?.version ?? "?";
      setBanner({
        level: "success",
        msg: `Landing publicada (v${v}). Visible en ~30s en el frontend del vertical.`,
      });
      qc.invalidateQueries({ queryKey: ["cms-landing", numericId] });
      qc.invalidateQueries({ queryKey: ["cms-landings"] });
    },
    onError: (err: any) => {
      setBanner({ level: "error", msg: err?.message ?? "Error publicando landing" });
    },
  });

  const rotateTokenMut = useMutation({
    mutationFn: () => rotatePreviewToken(numericId),
    onSuccess: () => {
      setBanner({ level: "info", msg: "Token de preview rotado." });
      qc.invalidateQueries({ queryKey: ["cms-landing", numericId] });
    },
    onError: (err: any) => {
      setBanner({ level: "error", msg: err?.message ?? "Error rotando token" });
    },
  });

  // Handler para el evento `auto-save` del designer (disparado cada `autoSaveMs`).
  const handleAutoSave = useCallback(
    (event: Event) => {
      const detail = (event as CustomEvent).detail as Record<string, unknown> | undefined;
      if (!detail) return;
      setConfig(detail);
      saveMut.mutate(detail);
    },
    [saveMut],
  );

  const previewUrl = useMemo(() => {
    if (!landing) return null;
    return buildPublicUrl(landing.vertical, landing.slug, landing.previewToken);
  }, [landing]);

  // ─── Gating / estados ──────────────────────────────────────────────────────
  if (isNew) {
    return <NewLandingForm onCreated={(id) => router.replace(`/cms/landings/${id}`)} />;
  }

  if (!idValid) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="error">ID inválido: {rawId}</Alert>
      </Box>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <LinearProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: "auto" }}>
        <Alert severity="error">{(error as Error).message}</Alert>
      </Box>
    );
  }

  if (!landing) return null;

  const verticalLabel =
    VERTICALS.find((v) => v.value === landing.vertical)?.label ?? landing.vertical;

  return (
    <Box sx={{ height: "calc(100vh - 64px)", display: "flex", flexDirection: "column" }}>
      {/* ── Top bar ────────────────────────────────────────────────── */}
      <Paper
        variant="outlined"
        sx={{
          p: 1.5,
          borderRadius: 0,
          borderLeft: 0,
          borderRight: 0,
          borderTop: 0,
        }}
      >
        <Stack direction="row" alignItems="center" spacing={2}>
          <Tooltip title="Volver a lista">
            <IconButton size="small" onClick={() => router.push("/cms/landings")}>
              <ArrowBackIcon />
            </IconButton>
          </Tooltip>

          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="subtitle1" fontWeight={700} noWrap>
              {verticalLabel} · /{landing.slug}{" "}
              <Typography component="span" variant="caption" color="text.secondary">
                #{landing.landingSchemaId}
              </Typography>
            </Typography>
            <Stack direction="row" spacing={1} alignItems="center" mt={0.25}>
              <Chip
                label={landing.status}
                size="small"
                color={STATUS_COLOR[landing.status] ?? "default"}
                sx={{ textTransform: "capitalize" }}
              />
              <Chip label={`v${landing.version}`} size="small" variant="outlined" />
              <Chip label={landing.locale} size="small" variant="outlined" />
              {saveMut.isPending ? (
                <Typography variant="caption" color="text.secondary">
                  Guardando…
                </Typography>
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

          <Tooltip title="Rotar token de preview">
            <span>
              <IconButton
                size="small"
                onClick={() => rotateTokenMut.mutate()}
                disabled={rotateTokenMut.isPending}
              >
                <RefreshIcon />
              </IconButton>
            </span>
          </Tooltip>

          <Button
            variant="outlined"
            size="small"
            startIcon={<OpenInNewIcon />}
            disabled={!previewUrl}
            onClick={() => {
              if (previewUrl) window.open(previewUrl, "_blank", "noopener,noreferrer");
            }}
          >
            Preview
          </Button>

          <Button
            variant="contained"
            size="small"
            color="primary"
            startIcon={<PublishIcon />}
            onClick={() => publishMut.mutate()}
            disabled={publishMut.isPending || saveMut.isPending}
          >
            {publishMut.isPending ? "Publicando…" : "Publicar"}
          </Button>
        </Stack>

        {banner && (
          <Alert
            severity={banner.level}
            onClose={() => setBanner(null)}
            sx={{ mt: 1 }}
          >
            {banner.msg}
          </Alert>
        )}
      </Paper>

      {/* ── Canvas del designer ────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "hidden", position: "relative" }}>
        {config ? (
          // El designer es un web component Lit: sus props aceptan objetos nativos
          // y los eventos viajan como CustomEvent vía @lit/react.
          <ZenttoLandingDesigner
            config={config as any}
            autoSaveMs={5000}
            onAutoSave={handleAutoSave as any}
            style={{ width: "100%", height: "100%", display: "block" }}
          />
        ) : (
          <Box sx={{ p: 4 }}>
            <LinearProgress />
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: "block" }}>
              Inicializando editor…
            </Typography>
          </Box>
        )}
      </Box>
    </Box>
  );
}
