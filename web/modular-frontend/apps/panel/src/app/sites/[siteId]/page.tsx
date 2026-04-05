"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Paper,
  Button,
  Chip,
  Skeleton,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import EditIcon from "@mui/icons-material/Edit";
import PublishIcon from "@mui/icons-material/Publish";
import SettingsIcon from "@mui/icons-material/Settings";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import DescriptionIcon from "@mui/icons-material/Description";
import ImageIcon from "@mui/icons-material/Image";
import InboxIcon from "@mui/icons-material/Inbox";
import { sitesApi, pagesApi, mediaApi, formsApi, revisionsApi } from "@/lib/api";

interface Revision {
  id: string;
  createdAt: string;
  message?: string;
}

export default function SiteDashboardPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [site, setSite] = useState<any>(null);
  const [pages, setPages] = useState<any[]>([]);
  const [media, setMedia] = useState<any[]>([]);
  const [submissions, setSubmissions] = useState<any[]>([]);
  const [revisions, setRevisions] = useState<Revision[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [publishing, setPublishing] = useState(false);

  useEffect(() => {
    if (!siteId) return;
    Promise.all([
      sitesApi.get(siteId),
      pagesApi.list(siteId).catch(() => []),
      mediaApi.list(siteId).catch(() => []),
      formsApi.list(siteId).catch(() => []),
      revisionsApi.list(siteId).catch(() => []),
    ])
      .then(([siteData, pagesData, mediaData, formsData, revisionsData]) => {
        setSite(siteData);
        setPages(Array.isArray(pagesData) ? pagesData : []);
        setMedia(Array.isArray(mediaData) ? mediaData : []);
        setSubmissions(Array.isArray(formsData) ? formsData : []);
        setRevisions(Array.isArray(revisionsData) ? revisionsData : []);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [siteId]);

  const handlePublish = async () => {
    if (!siteId) return;
    setPublishing(true);
    try {
      await sitesApi.publish(siteId);
      const updated = await sitesApi.get(siteId);
      setSite(updated);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setPublishing(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="text" width={300} height={48} />
        <Skeleton variant="rectangular" height={200} sx={{ mt: 2 }} />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }

  if (!site) return null;

  const siteUrl = `https://${site.slug || siteId}.zentto.net`;
  const statusColor =
    site.status === "published"
      ? "success"
      : site.status === "draft"
        ? "warning"
        : "default";

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      {/* Header */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          mb: 3,
          flexWrap: "wrap",
          gap: 2,
        }}
      >
        <Box>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
            <Typography variant="h4" fontWeight={700}>
              {site.title || site.name || "Sin titulo"}
            </Typography>
            <Chip
              label={site.status || "draft"}
              color={statusColor as any}
              size="small"
            />
          </Box>
          <Typography
            variant="body2"
            color="text.secondary"
            component="a"
            href={siteUrl}
            target="_blank"
            rel="noopener noreferrer"
            sx={{ textDecoration: "none", "&:hover": { textDecoration: "underline" } }}
          >
            {siteUrl} <OpenInNewIcon sx={{ fontSize: 14, ml: 0.5, verticalAlign: "middle" }} />
          </Typography>
        </Box>

        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
          <Button
            variant="contained"
            startIcon={<EditIcon />}
            onClick={() => router.push(`/sites/${siteId}/editor`)}
          >
            Editar en Designer
          </Button>
          <Button
            variant="outlined"
            startIcon={<PublishIcon />}
            onClick={handlePublish}
            disabled={publishing}
          >
            {publishing ? "Publicando..." : "Publicar"}
          </Button>
          <Button
            variant="outlined"
            startIcon={<SettingsIcon />}
            onClick={() => router.push(`/sites/${siteId}/settings`)}
          >
            Configuracion
          </Button>
          <Button
            variant="outlined"
            startIcon={<OpenInNewIcon />}
            component="a"
            href={siteUrl}
            target="_blank"
            rel="noopener noreferrer"
          >
            Ver Sitio
          </Button>
        </Box>
      </Box>

      {/* Stats */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 4 }}>
          <Paper
            sx={{ p: 3, cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
            onClick={() => router.push(`/sites/${siteId}/pages`)}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
              <DescriptionIcon color="primary" sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h4" fontWeight={700}>
                  {pages.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Paginas
                </Typography>
              </Box>
            </Box>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <Paper
            sx={{ p: 3, cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
            onClick={() => router.push(`/sites/${siteId}/media`)}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
              <ImageIcon color="secondary" sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h4" fontWeight={700}>
                  {media.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Archivos multimedia
                </Typography>
              </Box>
            </Box>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <Paper
            sx={{ p: 3, cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
            onClick={() => router.push(`/sites/${siteId}/forms`)}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
              <InboxIcon color="info" sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h4" fontWeight={700}>
                  {submissions.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Envios de formularios
                </Typography>
              </Box>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* Recent activity */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
          Actividad reciente
        </Typography>
        {revisions.length === 0 ? (
          <Typography variant="body2" color="text.secondary">
            No hay revisiones registradas.
          </Typography>
        ) : (
          <Box component="ul" sx={{ listStyle: "none", p: 0, m: 0 }}>
            {revisions.slice(0, 10).map((rev) => (
              <Box
                component="li"
                key={rev.id}
                sx={{
                  py: 1,
                  px: 1,
                  borderBottom: "1px solid",
                  borderColor: "divider",
                  "&:last-child": { borderBottom: "none" },
                }}
              >
                <Typography variant="body2">
                  {rev.message || `Revision ${rev.id}`}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {new Date(rev.createdAt).toLocaleString()}
                </Typography>
              </Box>
            ))}
          </Box>
        )}
      </Paper>
    </Box>
  );
}
