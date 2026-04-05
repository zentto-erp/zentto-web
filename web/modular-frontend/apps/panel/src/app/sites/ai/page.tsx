"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import TextField from "@mui/material/TextField";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import Chip from "@mui/material/Chip";
import Alert from "@mui/material/Alert";
import Select from "@mui/material/Select";
import MenuItem from "@mui/material/MenuItem";
import FormControl from "@mui/material/FormControl";
import InputLabel from "@mui/material/InputLabel";
import AutoAwesomeIcon from "@mui/icons-material/AutoAwesome";
import RocketLaunchIcon from "@mui/icons-material/RocketLaunch";
import LanguageIcon from "@mui/icons-material/Language";
import PaletteIcon from "@mui/icons-material/Palette";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { sitesApi, aiApi } from "@/lib/api";

const STYLES = [
  { label: "Moderno", value: "moderno" },
  { label: "Corporativo", value: "corporativo" },
  { label: "Minimalista", value: "minimalista" },
  { label: "Colorido", value: "colorido" },
];

const LOCALES = [
  { label: "Espanol", value: "es" },
  { label: "English", value: "en" },
  { label: "Portugues", value: "pt" },
];

export default function AiGeneratorPage() {
  const router = useRouter();
  const [prompt, setPrompt] = useState("");
  const [locale, setLocale] = useState("es");
  const [style, setStyle] = useState("moderno");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<any>(null);
  const [saving, setSaving] = useState(false);

  const handleGenerate = async () => {
    if (!prompt.trim() || prompt.trim().length < 5) {
      setError("Describe tu negocio con al menos 5 caracteres");
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const res = await aiApi.generateSite({ prompt, locale, style });
      setResult(res.data);
    } catch (err: any) {
      setError(err.message || "Error generando el sitio");
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSite = async () => {
    if (!result) return;

    setSaving(true);
    setError(null);

    try {
      const slug = result.analysis.businessName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "")
        .slice(0, 40);

      const res = await sitesApi.create({
        title: result.analysis.businessName,
        slug: `${slug}-${Date.now().toString(36)}`,
        description: `Sitio generado con IA: ${prompt.slice(0, 200)}`,
        config: result.config,
        locale,
      });

      const siteId = res.data?.SiteId || res.data?.siteId;
      if (siteId) {
        router.push(`/sites/${siteId}/editor`);
      } else {
        router.push("/sites");
      }
    } catch (err: any) {
      setError(err.message || "Error creando el sitio");
      setSaving(false);
    }
  };

  return (
    <Box
      sx={{
        maxWidth: 720,
        mx: "auto",
        py: { xs: 3, md: 6 },
        px: 2,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
      }}
    >
      {/* Header */}
      <Box
        sx={{
          width: 64,
          height: 64,
          borderRadius: 3,
          background: "linear-gradient(135deg, #6366f1, #a855f7)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          mb: 3,
        }}
      >
        <AutoAwesomeIcon sx={{ color: "#fff", fontSize: 32 }} />
      </Box>

      <Typography
        variant="h4"
        sx={{ fontWeight: 800, textAlign: "center", mb: 1, color: "#1e293b" }}
      >
        Crea tu sitio con IA
      </Typography>

      <Typography
        variant="body1"
        sx={{ color: "#64748b", textAlign: "center", mb: 4, maxWidth: 480 }}
      >
        Describe tu negocio en una frase y generaremos un sitio web completo
        listo para publicar.
      </Typography>

      {/* Prompt input */}
      <TextField
        multiline
        rows={3}
        fullWidth
        placeholder="Describe tu negocio en una frase... Ejemplo: Soy una cafeteria artesanal en Madrid con cafe de especialidad y reposteria casera"
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        disabled={loading}
        sx={{
          mb: 3,
          "& .MuiOutlinedInput-root": {
            borderRadius: 3,
            fontSize: 16,
          },
        }}
      />

      {/* Options row */}
      <Box
        sx={{
          display: "flex",
          gap: 2,
          width: "100%",
          mb: 3,
          flexWrap: "wrap",
        }}
      >
        {/* Language */}
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>
            <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
              <LanguageIcon sx={{ fontSize: 16 }} /> Idioma
            </Box>
          </InputLabel>
          <Select
            value={locale}
            onChange={(e) => setLocale(e.target.value)}
            label="Idioma"
            disabled={loading}
          >
            {LOCALES.map((l) => (
              <MenuItem key={l.value} value={l.value}>
                {l.label}
              </MenuItem>
            ))}
          </Select>
        </FormControl>

        {/* Style chips */}
        <Box sx={{ display: "flex", gap: 1, alignItems: "center", flexWrap: "wrap", flex: 1 }}>
          <PaletteIcon sx={{ fontSize: 18, color: "#94a3b8" }} />
          {STYLES.map((s) => (
            <Chip
              key={s.value}
              label={s.label}
              onClick={() => setStyle(s.value)}
              color={style === s.value ? "primary" : "default"}
              variant={style === s.value ? "filled" : "outlined"}
              disabled={loading}
              sx={{ fontWeight: style === s.value ? 600 : 400 }}
            />
          ))}
        </Box>
      </Box>

      {/* Generate button */}
      <Button
        variant="contained"
        size="large"
        onClick={handleGenerate}
        disabled={loading || !prompt.trim()}
        startIcon={loading ? undefined : <RocketLaunchIcon />}
        sx={{
          borderRadius: 3,
          px: 5,
          py: 1.5,
          fontSize: 16,
          fontWeight: 700,
          textTransform: "none",
          mb: 3,
          minWidth: 220,
          background: loading ? undefined : "linear-gradient(135deg, #6366f1, #8b5cf6)",
          "&:hover": {
            background: "linear-gradient(135deg, #4f46e5, #7c3aed)",
          },
        }}
      >
        {loading ? <LoadingDots /> : "Generar Sitio"}
      </Button>

      {/* Error */}
      {error && (
        <Alert severity="error" sx={{ width: "100%", mb: 3, borderRadius: 2 }}>
          {error}
        </Alert>
      )}

      {/* Result preview */}
      {result && (
        <Card
          elevation={0}
          sx={{
            width: "100%",
            border: "2px solid #e2e8f0",
            borderRadius: 4,
            overflow: "hidden",
          }}
        >
          {/* Preview header bar */}
          <Box
            sx={{
              px: 3,
              py: 2,
              bgcolor: result.config?.theme?.tokens?.["--zl-primary"] || "#6366f1",
              color: "#fff",
              display: "flex",
              alignItems: "center",
              gap: 1.5,
            }}
          >
            <CheckCircleIcon />
            <Typography variant="h6" sx={{ fontWeight: 700, fontSize: 16 }}>
              Sitio generado exitosamente
            </Typography>
          </Box>

          <CardContent sx={{ p: 3 }}>
            {/* Analysis info */}
            <Box sx={{ mb: 3 }}>
              <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
                {result.analysis.businessName}
              </Typography>
              <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mb: 2 }}>
                <Chip
                  size="small"
                  label={`Plantilla: ${result.analysis.templateId}`}
                  color="primary"
                  variant="outlined"
                />
                <Chip
                  size="small"
                  label={`Tema: ${result.analysis.theme}`}
                  sx={{
                    bgcolor: result.config?.theme?.tokens?.["--zl-primary-light"] || "#e0e7ff",
                    color: result.config?.theme?.tokens?.["--zl-primary"] || "#6366f1",
                    fontWeight: 600,
                  }}
                />
                <Chip
                  size="small"
                  label={`Categoria: ${result.analysis.category}`}
                  variant="outlined"
                />
                <Chip
                  size="small"
                  label={`Estilo: ${result.analysis.style}`}
                  variant="outlined"
                />
              </Box>
            </Box>

            {/* Sections preview */}
            <Typography variant="subtitle2" sx={{ color: "#64748b", mb: 1 }}>
              Secciones incluidas:
            </Typography>
            <Box sx={{ display: "flex", gap: 0.5, flexWrap: "wrap", mb: 3 }}>
              {result.analysis.sections.map((s: string) => (
                <Chip key={s} size="small" label={s} variant="outlined" sx={{ fontSize: 12 }} />
              ))}
            </Box>

            {/* Theme preview */}
            <Typography variant="subtitle2" sx={{ color: "#64748b", mb: 1 }}>
              Paleta de colores:
            </Typography>
            <Box sx={{ display: "flex", gap: 1, mb: 3 }}>
              {["--zl-primary", "--zl-accent", "--zl-primary-light", "--zl-bg-alt"].map((token) => {
                const color = result.config?.theme?.tokens?.[token];
                if (!color) return null;
                return (
                  <Box
                    key={token}
                    sx={{
                      width: 36,
                      height: 36,
                      borderRadius: 2,
                      bgcolor: color,
                      border: "1px solid #e2e8f0",
                    }}
                    title={`${token}: ${color}`}
                  />
                );
              })}
            </Box>

            {/* Create button */}
            <Button
              variant="contained"
              size="large"
              fullWidth
              onClick={handleCreateSite}
              disabled={saving}
              sx={{
                borderRadius: 3,
                py: 1.5,
                fontWeight: 700,
                textTransform: "none",
                fontSize: 16,
                background: "linear-gradient(135deg, #059669, #10b981)",
                "&:hover": { background: "linear-gradient(135deg, #047857, #059669)" },
              }}
            >
              {saving ? "Creando sitio..." : "Crear sitio y abrir editor"}
            </Button>
          </CardContent>
        </Card>
      )}
    </Box>
  );
}

/** Animated loading dots */
function LoadingDots() {
  return (
    <Box sx={{ display: "flex", gap: 0.5, alignItems: "center" }}>
      <Typography sx={{ fontWeight: 600 }}>Generando</Typography>
      {[0, 1, 2].map((i) => (
        <Box
          key={i}
          sx={{
            width: 6,
            height: 6,
            borderRadius: "50%",
            bgcolor: "rgba(255,255,255,0.8)",
            animation: "pulse 1.2s ease-in-out infinite",
            animationDelay: `${i * 0.2}s`,
            "@keyframes pulse": {
              "0%, 80%, 100%": { transform: "scale(0.4)", opacity: 0.4 },
              "40%": { transform: "scale(1)", opacity: 1 },
            },
          }}
        />
      ))}
    </Box>
  );
}
