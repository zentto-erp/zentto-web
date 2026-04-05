"use client";

import { useParams } from "next/navigation";
import { useEffect, useState, useCallback } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Skeleton,
  Snackbar,
  Switch,
  Tab,
  Tabs,
  TextField,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SaveIcon from "@mui/icons-material/Save";
import AnalyticsIcon from "@mui/icons-material/Analytics";
import CampaignIcon from "@mui/icons-material/Campaign";
import ChatIcon from "@mui/icons-material/Chat";
import GavelIcon from "@mui/icons-material/Gavel";
import ExtensionIcon from "@mui/icons-material/Extension";
import { integrationsApi } from "@/lib/api";

/* ------------------------------------------------------------------ */
/* Types                                                               */
/* ------------------------------------------------------------------ */

interface IntegrationField {
  name: string;
  label: string;
  placeholder?: string;
  type?: "text" | "textarea";
  required: boolean;
}

interface CatalogItem {
  id: string;
  name: string;
  category: string;
  icon: string;
  description?: string;
  fields: IntegrationField[];
  hasHeadScript: boolean;
  hasBodyScript: boolean;
}

interface ActiveIntegration {
  id: string;
  enabled: boolean;
  config: Record<string, string>;
}

/* ------------------------------------------------------------------ */
/* Category config                                                     */
/* ------------------------------------------------------------------ */

const CATEGORIES = [
  { value: "all", label: "Todas", icon: <ExtensionIcon fontSize="small" /> },
  { value: "analytics", label: "Analytics", icon: <AnalyticsIcon fontSize="small" /> },
  { value: "marketing", label: "Marketing", icon: <CampaignIcon fontSize="small" /> },
  { value: "chat", label: "Chat", icon: <ChatIcon fontSize="small" /> },
  { value: "legal", label: "Legal", icon: <GavelIcon fontSize="small" /> },
  { value: "other", label: "Otros", icon: <ExtensionIcon fontSize="small" /> },
];

/* ------------------------------------------------------------------ */
/* Icon mapping                                                        */
/* ------------------------------------------------------------------ */

function getCategoryIcon(category: string) {
  switch (category) {
    case "analytics":
      return <AnalyticsIcon sx={{ fontSize: 32, color: "primary.main" }} />;
    case "marketing":
      return <CampaignIcon sx={{ fontSize: 32, color: "secondary.main" }} />;
    case "chat":
      return <ChatIcon sx={{ fontSize: 32, color: "success.main" }} />;
    case "legal":
      return <GavelIcon sx={{ fontSize: 32, color: "warning.main" }} />;
    default:
      return <ExtensionIcon sx={{ fontSize: 32, color: "info.main" }} />;
  }
}

/* ------------------------------------------------------------------ */
/* Main page                                                           */
/* ------------------------------------------------------------------ */

export default function IntegrationsPage() {
  const params = useParams<{ siteId: string }>();
  const siteId = params.siteId;

  const [catalog, setCatalog] = useState<CatalogItem[]>([]);
  const [activeIntegrations, setActiveIntegrations] = useState<ActiveIntegration[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [snackbar, setSnackbar] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState("all");
  const [dirty, setDirty] = useState(false);

  /* Load catalog + active integrations */
  useEffect(() => {
    if (!siteId) return;
    Promise.all([
      integrationsApi.catalog(),
      integrationsApi.list(siteId),
    ])
      .then(([catalogRes, activeRes]) => {
        setCatalog(Array.isArray(catalogRes?.data) ? catalogRes.data : []);
        setActiveIntegrations(Array.isArray(activeRes?.data) ? activeRes.data : []);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [siteId]);

  /* Find active integration by id */
  const getActive = useCallback(
    (integrationId: string): ActiveIntegration | undefined =>
      activeIntegrations.find((a) => a.id === integrationId),
    [activeIntegrations],
  );

  /* Toggle integration on/off */
  const handleToggle = (integrationId: string) => {
    setDirty(true);
    setActiveIntegrations((prev) => {
      const exists = prev.find((a) => a.id === integrationId);
      if (exists) {
        return prev.map((a) =>
          a.id === integrationId ? { ...a, enabled: !a.enabled } : a,
        );
      }
      return [...prev, { id: integrationId, enabled: true, config: {} }];
    });
  };

  /* Update config field */
  const handleConfigChange = (integrationId: string, fieldName: string, value: string) => {
    setDirty(true);
    setActiveIntegrations((prev) => {
      const exists = prev.find((a) => a.id === integrationId);
      if (exists) {
        return prev.map((a) =>
          a.id === integrationId
            ? { ...a, config: { ...a.config, [fieldName]: value } }
            : a,
        );
      }
      return [...prev, { id: integrationId, enabled: true, config: { [fieldName]: value } }];
    });
  };

  /* Save */
  const handleSave = async () => {
    if (!siteId) return;
    setSaving(true);
    setError(null);
    try {
      // Only send integrations that are enabled or have config
      const toSave = activeIntegrations.filter(
        (a) => a.enabled || Object.values(a.config).some((v) => v),
      );
      await integrationsApi.update(siteId, toSave);
      setDirty(false);
      setSnackbar("Integraciones guardadas correctamente");
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  /* Filter by category */
  const filteredCatalog =
    activeTab === "all"
      ? catalog
      : catalog.filter((c) => c.category === activeTab);

  /* Count active */
  const activeCount = activeIntegrations.filter((a) => a.enabled).length;

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="text" width={300} height={48} />
        <Skeleton variant="rectangular" height={400} sx={{ mt: 2 }} />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      {/* Header */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
          flexWrap: "wrap",
          gap: 2,
        }}
      >
        <Box>
          <Typography variant="h5" fontWeight={700}>
            Integraciones
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {activeCount} {activeCount === 1 ? "integracion activa" : "integraciones activas"}
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={handleSave}
          disabled={saving || !dirty}
        >
          {saving ? "Guardando..." : "Guardar cambios"}
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Category tabs */}
      <Tabs
        value={activeTab}
        onChange={(_e, v) => setActiveTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{ mb: 3, borderBottom: 1, borderColor: "divider" }}
      >
        {CATEGORIES.map((cat) => (
          <Tab
            key={cat.value}
            value={cat.value}
            label={cat.label}
            icon={cat.icon}
            iconPosition="start"
            sx={{ minHeight: 48, textTransform: "none" }}
          />
        ))}
      </Tabs>

      {/* Integration cards */}
      <Grid container spacing={3}>
        {filteredCatalog.map((item) => {
          const active = getActive(item.id);
          const isEnabled = active?.enabled ?? false;
          const config = active?.config ?? {};

          return (
            <Grid key={item.id} size={{ xs: 12, md: 6 }}>
              <Card
                variant="outlined"
                sx={{
                  borderColor: isEnabled ? "primary.main" : "divider",
                  borderWidth: isEnabled ? 2 : 1,
                  transition: "border-color 0.2s",
                }}
              >
                <CardContent>
                  {/* Card header */}
                  <Box
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      mb: 1,
                    }}
                  >
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                      {getCategoryIcon(item.category)}
                      <Box>
                        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                          <Typography variant="subtitle1" fontWeight={600}>
                            {item.name}
                          </Typography>
                          {isEnabled && (
                            <Box
                              sx={{
                                width: 8,
                                height: 8,
                                borderRadius: "50%",
                                bgcolor: "success.main",
                                flexShrink: 0,
                              }}
                            />
                          )}
                        </Box>
                        <Chip
                          label={item.category}
                          size="small"
                          variant="outlined"
                          sx={{ fontSize: 11, height: 20 }}
                        />
                      </Box>
                    </Box>
                    <Switch
                      checked={isEnabled}
                      onChange={() => handleToggle(item.id)}
                      color="primary"
                    />
                  </Box>

                  {/* Description */}
                  {item.description && (
                    <Typography
                      variant="body2"
                      color="text.secondary"
                      sx={{ mb: 2, ml: 0.5 }}
                    >
                      {item.description}
                    </Typography>
                  )}

                  {/* Config fields (shown when enabled) */}
                  {isEnabled && item.fields.length > 0 && (
                    <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5, mt: 1 }}>
                      {item.fields.map((field) => (
                        <TextField
                          key={field.name}
                          label={field.label}
                          placeholder={field.placeholder}
                          value={config[field.name] ?? ""}
                          onChange={(e) =>
                            handleConfigChange(item.id, field.name, e.target.value)
                          }
                          size="small"
                          fullWidth
                          required={field.required}
                          multiline={field.type === "textarea"}
                          rows={field.type === "textarea" ? 3 : undefined}
                        />
                      ))}
                    </Box>
                  )}
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      {filteredCatalog.length === 0 && (
        <Box sx={{ textAlign: "center", py: 6 }}>
          <Typography variant="body1" color="text.secondary">
            No hay integraciones en esta categoria.
          </Typography>
        </Box>
      )}

      {/* Snackbar */}
      <Snackbar
        open={!!snackbar}
        autoHideDuration={3000}
        onClose={() => setSnackbar(null)}
        message={snackbar}
      />
    </Box>
  );
}
