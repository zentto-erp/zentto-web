"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemButton,
  Divider,
  IconButton,
  Tooltip,
  CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import SaveIcon from "@mui/icons-material/Save";
import PreviewIcon from "@mui/icons-material/Preview";
import DeleteIcon from "@mui/icons-material/Delete";
import InsertDriveFileIcon from "@mui/icons-material/InsertDriveFile";
import {
  useTemplates,
  useTemplate,
  useUpsertTemplate,
  useDeleteTemplate,
  type ReportTemplate,
} from "../hooks/useContabilidadLegal";

// ─── Sample data for preview ────────────────────────────────
const SAMPLE_VARIABLES: Record<string, string> = {
  companyName: "Empresa Demo, C.A.",
  companyRIF: "J-12345678-9",
  reportDate: "15/03/2026",
  currency: "VEF",
  "table:balanceGeneral":
    "| Cuenta | Debe | Haber |\n|---|---|---|\n| Activos | 100.000,00 | - |\n| Pasivos | - | 60.000,00 |\n| Patrimonio | - | 40.000,00 |",
};

const INSERTABLE_VARIABLES = [
  { label: "Empresa", value: "{{companyName}}" },
  { label: "RIF", value: "{{companyRIF}}" },
  { label: "Fecha", value: "{{reportDate}}" },
  { label: "Moneda", value: "{{currency}}" },
  { label: "Tabla balance", value: "{{table:balanceGeneral}}" },
];

const COUNTRY_FILTERS = ["VE", "ES", "Todos"] as const;

const frameworkColor = (fw: string) => {
  switch (fw) {
    case "VEN-NIF":
      return "primary";
    case "NIIF":
      return "success";
    case "PGC":
      return "warning";
    default:
      return "default";
  }
};

function renderPreview(content: string): string {
  let result = content;
  for (const [key, val] of Object.entries(SAMPLE_VARIABLES)) {
    result = result.replaceAll(`{{${key}}}`, val);
  }
  return result;
}

const EMPTY_TEMPLATE: Partial<ReportTemplate> = {
  CountryCode: "VE",
  ReportCode: "",
  ReportName: "",
  LegalFramework: "",
  LegalReference: "",
  TemplateContent: "",
  IsDefault: false,
  Version: 1,
};

export default function PlantillasReportePage() {
  const [countryFilter, setCountryFilter] = useState<string>("Todos");
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [editContent, setEditContent] = useState("");
  const [editMeta, setEditMeta] = useState<Partial<ReportTemplate>>(EMPTY_TEMPLATE);
  const [isNew, setIsNew] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);

  const queryCountry = countryFilter === "Todos" ? undefined : countryFilter;
  const { data: templatesData, isLoading: loadingList } = useTemplates(queryCountry);
  const { data: templateDetail, isLoading: loadingDetail } = useTemplate(selectedId);
  const upsertMutation = useUpsertTemplate();
  const deleteMutation = useDeleteTemplate();

  const templates: ReportTemplate[] = templatesData?.rows ?? templatesData ?? [];

  // Sync detail into editor when loaded
  useEffect(() => {
    if (templateDetail && !isNew) {
      const t = templateDetail.row ?? templateDetail;
      setEditContent(t.TemplateContent ?? "");
      setEditMeta({
        ReportTemplateId: t.ReportTemplateId,
        CountryCode: t.CountryCode,
        ReportCode: t.ReportCode,
        ReportName: t.ReportName,
        LegalFramework: t.LegalFramework,
        LegalReference: t.LegalReference,
        IsDefault: t.IsDefault,
        Version: t.Version,
      });
    }
  }, [templateDetail, isNew]);

  const handleSelectTemplate = useCallback((id: number) => {
    setSelectedId(id);
    setIsNew(false);
  }, []);

  const handleNewTemplate = useCallback(() => {
    setSelectedId(null);
    setIsNew(true);
    setEditContent("");
    setEditMeta({ ...EMPTY_TEMPLATE });
  }, []);

  const handleSave = async () => {
    const payload: Partial<ReportTemplate> = {
      ...editMeta,
      TemplateContent: editContent,
    };
    if (!isNew && selectedId) {
      payload.ReportTemplateId = selectedId;
    }
    await upsertMutation.mutateAsync(payload);
    setIsNew(false);
  };

  const handleDelete = async () => {
    if (!selectedId) return;
    await deleteMutation.mutateAsync(selectedId);
    setSelectedId(null);
    setEditContent("");
    setEditMeta({ ...EMPTY_TEMPLATE });
  };

  const insertVariable = (variable: string) => {
    setEditContent((prev) => prev + variable);
  };

  const hasSelection = isNew || selectedId !== null;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", gap: 2, minHeight: 0 }}>
        {/* ─── Left Panel: Template List ─────────────────────────── */}
        <Paper
          sx={{
            width: 300,
            minWidth: 300,
            display: "flex",
            flexDirection: "column",
            border: "1px solid #E5E7EB",
            elevation: 0,
          }}
        >
          <Box sx={{ p: 2, borderBottom: "1px solid #E5E7EB" }}>
            <Typography variant="subtitle1" fontWeight={700} gutterBottom>
              Plantillas de Reporte
            </Typography>
            <Stack direction="row" spacing={1}>
              {COUNTRY_FILTERS.map((c) => (
                <Chip
                  key={c}
                  label={c}
                  size="small"
                  color={countryFilter === c ? "primary" : "default"}
                  variant={countryFilter === c ? "filled" : "outlined"}
                  onClick={() => setCountryFilter(c)}
                  clickable
                />
              ))}
            </Stack>
          </Box>

          <Box sx={{ flex: 1, overflow: "auto" }}>
            {loadingList ? (
              <Box sx={{ display: "flex", justifyContent: "center", p: 3 }}>
                <CircularProgress size={24} />
              </Box>
            ) : templates.length === 0 ? (
              <Typography variant="body2" color="text.secondary" sx={{ p: 2 }}>
                No hay plantillas disponibles.
              </Typography>
            ) : (
              <List disablePadding>
                {templates.map((t, idx) => (
                  <React.Fragment key={t.ReportTemplateId}>
                    {idx > 0 && <Divider />}
                    <ListItem disablePadding>
                      <ListItemButton
                        selected={selectedId === t.ReportTemplateId && !isNew}
                        onClick={() => handleSelectTemplate(t.ReportTemplateId)}
                      >
                        <ListItemText
                          primary={t.ReportName}
                          secondary={
                            <Stack direction="row" spacing={0.5} alignItems="center" mt={0.5}>
                              <Chip
                                label={t.LegalFramework}
                                size="small"
                                color={frameworkColor(t.LegalFramework) as any}
                                variant="outlined"
                              />
                              <Chip label={t.CountryCode} size="small" variant="outlined" />
                            </Stack>
                          }
                        />
                      </ListItemButton>
                    </ListItem>
                  </React.Fragment>
                ))}
              </List>
            )}
          </Box>

          <Box sx={{ p: 1.5, borderTop: "1px solid #E5E7EB" }}>
            <Button
              fullWidth
              variant="outlined"
              startIcon={<AddIcon />}
              onClick={handleNewTemplate}
            >
              Nueva Plantilla
            </Button>
          </Box>
        </Paper>

        {/* ─── Right Panel: Editor ───────────────────────────────── */}
        <Paper
          sx={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            border: "1px solid #E5E7EB",
            elevation: 0,
            minHeight: 0,
          }}
        >
          {!hasSelection ? (
            <Box
              sx={{
                flex: 1,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 2,
              }}
            >
              <InsertDriveFileIcon sx={{ fontSize: 64, color: "text.disabled" }} />
              <Typography variant="body1" color="text.secondary">
                Seleccione una plantilla o cree una nueva para comenzar a editar.
              </Typography>
            </Box>
          ) : (
            <>
              {/* Header */}
              <Box sx={{ p: 2, borderBottom: "1px solid #E5E7EB" }}>
                <Stack direction="row" spacing={2} alignItems="flex-start" flexWrap="wrap">
                  <TextField
                    label="Nombre del Reporte"
                    size="small"
                    value={editMeta.ReportName ?? ""}
                    onChange={(e) =>
                      setEditMeta((m) => ({ ...m, ReportName: e.target.value }))
                    }
                    sx={{ flex: 1, minWidth: 200 }}
                  />
                  <TextField
                    label="Codigo"
                    size="small"
                    value={editMeta.ReportCode ?? ""}
                    onChange={(e) =>
                      setEditMeta((m) => ({ ...m, ReportCode: e.target.value }))
                    }
                    sx={{ width: 140 }}
                  />
                  <TextField
                    label="Marco legal"
                    size="small"
                    value={editMeta.LegalFramework ?? ""}
                    onChange={(e) =>
                      setEditMeta((m) => ({ ...m, LegalFramework: e.target.value }))
                    }
                    sx={{ width: 140 }}
                  />
                  <TextField
                    label="Pais"
                    size="small"
                    value={editMeta.CountryCode ?? ""}
                    onChange={(e) =>
                      setEditMeta((m) => ({ ...m, CountryCode: e.target.value }))
                    }
                    sx={{ width: 80 }}
                  />
                </Stack>
                <Stack direction="row" spacing={2} alignItems="center" mt={1.5}>
                  <TextField
                    label="Referencia legal"
                    size="small"
                    value={editMeta.LegalReference ?? ""}
                    onChange={(e) =>
                      setEditMeta((m) => ({ ...m, LegalReference: e.target.value }))
                    }
                    sx={{ flex: 1 }}
                  />
                  {editMeta.LegalFramework && (
                    <Chip
                      label={editMeta.LegalFramework}
                      size="small"
                      color={frameworkColor(editMeta.LegalFramework) as any}
                    />
                  )}
                  <Chip
                    label={`v${editMeta.Version ?? 1}`}
                    size="small"
                    variant="outlined"
                    color="info"
                  />
                </Stack>
              </Box>

              {/* Toolbar */}
              <Box sx={{ px: 2, py: 1, borderBottom: "1px solid #E5E7EB" }}>
                <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
                  <Button
                    variant="contained"
                    size="small"
                    startIcon={
                      upsertMutation.isPending ? (
                        <CircularProgress size={16} />
                      ) : (
                        <SaveIcon />
                      )
                    }
                    onClick={handleSave}
                    disabled={upsertMutation.isPending || !editMeta.ReportName}
                  >
                    Guardar
                  </Button>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<PreviewIcon />}
                    onClick={() => setPreviewOpen(true)}
                    disabled={!editContent}
                  >
                    Vista Previa
                  </Button>
                  {selectedId && !isNew && (
                    <Tooltip title="Eliminar plantilla">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={handleDelete}
                        disabled={deleteMutation.isPending}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  )}

                  <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />

                  <Typography variant="caption" color="text.secondary" sx={{ mr: 0.5 }}>
                    Insertar:
                  </Typography>
                  {INSERTABLE_VARIABLES.map((v) => (
                    <Chip
                      key={v.value}
                      label={v.label}
                      size="small"
                      variant="outlined"
                      clickable
                      onClick={() => insertVariable(v.value)}
                    />
                  ))}
                </Stack>
              </Box>

              {/* Editor */}
              <Box sx={{ flex: 1, display: "flex", minHeight: 0, p: 2 }}>
                {loadingDetail && !isNew ? (
                  <Box
                    sx={{
                      flex: 1,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <CircularProgress />
                  </Box>
                ) : (
                  <textarea
                    value={editContent}
                    onChange={(e) => setEditContent(e.target.value)}
                    placeholder="Escriba el contenido de la plantilla en Markdown con {{variables}}..."
                    style={{
                      flex: 1,
                      fontFamily: "Consolas, monospace",
                      fontSize: 14,
                      lineHeight: 1.6,
                      padding: 16,
                      border: "1px solid #E5E7EB",
                      borderRadius: 8,
                      resize: "none",
                      outline: "none",
                      backgroundColor: "#FAFAFA",
                    }}
                  />
                )}
              </Box>
            </>
          )}
        </Paper>
      </Box>

      {/* ─── Preview Dialog ──────────────────────────────────────── */}
      <Dialog
        open={previewOpen}
        onClose={() => setPreviewOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Vista Previa de Plantilla</DialogTitle>
        <DialogContent dividers>
          <Box
            sx={{
              fontFamily: "Consolas, monospace",
              fontSize: 14,
              lineHeight: 1.8,
              whiteSpace: "pre-wrap",
              p: 2,
              backgroundColor: "#FAFAFA",
              borderRadius: 1,
              minHeight: 300,
            }}
          >
            {renderPreview(editContent)}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPreviewOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
