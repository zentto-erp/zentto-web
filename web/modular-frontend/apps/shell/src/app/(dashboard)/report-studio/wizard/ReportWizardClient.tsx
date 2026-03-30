"use client";

import React, { useState, useCallback, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Typography,
  Button,
  Stepper,
  Step,
  StepLabel,
  TextField,
  Card,
  CardContent,
  CardActionArea,
  Grid,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
  Select,
  MenuItem,
  Stack,
  Alert,
  Breadcrumbs,
  Link,
  IconButton,
  Tooltip,
  Chip,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import NavigateNextIcon from "@mui/icons-material/NavigateNext";
import { REPORT_TEMPLATES, createBlankLayout } from "@zentto/report-core";
import { createSavedReport } from "@zentto/shared-api";

/* ── Types ─────────────────────────────────────────────────────── */

interface ManualField {
  fieldName: string;
  fieldType: "string" | "number" | "boolean" | "date";
}

type DataSourceMode = "endpoint" | "file" | "manual" | "none";

const STEPS = ["Seleccionar Plantilla", "Fuente de Datos", "Guardar"];

const CATEGORY_LABELS: Record<string, string> = {
  report: "Reportes",
  label: "Etiquetas",
  receipt: "Recibos",
  card: "Tarjetas",
  envelope: "Sobres",
};

const ENDPOINTS = [
  { label: "Articulos", value: "/v1/articulos" },
  { label: "Facturas", value: "/v1/documentos-venta" },
  { label: "Clientes", value: "/v1/clientes" },
  { label: "Proveedores", value: "/v1/proveedores" },
  { label: "Empleados", value: "/v1/empleados" },
];

/* ── Component ─────────────────────────────────────────────────── */

export default function ReportWizardClient() {
  const router = useRouter();

  // Stepper
  const [activeStep, setActiveStep] = useState(0);

  // Step 1 — template
  const [selectedLayout, setSelectedLayout] = useState<Record<string, unknown> | null>(null);
  const [selectedTemplateName, setSelectedTemplateName] = useState<string>("");

  // Step 2 — data source
  const [dataSourceMode, setDataSourceMode] = useState<DataSourceMode>("none");
  const [selectedEndpoint, setSelectedEndpoint] = useState(ENDPOINTS[0].value);
  const [fileData, setFileData] = useState<Record<string, unknown> | null>(null);
  const [fileName, setFileName] = useState("");
  const [manualFields, setManualFields] = useState<ManualField[]>([
    { fieldName: "", fieldType: "string" },
  ]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Step 3 — save
  const [reportName, setReportName] = useState("");
  const [reportDescription, setReportDescription] = useState("");
  const [reportIcon, setReportIcon] = useState("\uD83D\uDCCA");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /* ── Helpers ───────────────────────────────────────────────────── */

  const handleSelectTemplate = useCallback(
    (layout: Record<string, unknown>, name: string) => {
      setSelectedLayout(layout);
      setSelectedTemplateName(name);
      setReportName(name);
      setActiveStep(1);
    },
    [],
  );

  const handleSelectBlank = useCallback(() => {
    const blank = createBlankLayout("Nuevo Reporte") as unknown as Record<string, unknown>;
    setSelectedLayout(blank);
    setSelectedTemplateName("En blanco");
    setReportName("Nuevo Reporte");
    setActiveStep(1);
  }, []);

  const buildSampleData = useCallback((): Record<string, unknown> => {
    if (dataSourceMode === "endpoint") {
      return { endpoint: selectedEndpoint, rows: [] };
    }
    if (dataSourceMode === "file" && fileData) {
      return fileData;
    }
    if (dataSourceMode === "manual") {
      const fields = manualFields.filter((f) => f.fieldName.trim());
      return {
        fields: fields.map((f) => ({ name: f.fieldName, type: f.fieldType })),
        rows: [],
      };
    }
    return {};
  }, [dataSourceMode, selectedEndpoint, fileData, manualFields]);

  const handleFileChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const text = reader.result as string;
        if (file.name.endsWith(".json")) {
          setFileData(JSON.parse(text));
        } else {
          // CSV: parse header + rows
          const lines = text.split("\n").filter((l) => l.trim());
          const headers = lines[0].split(",").map((h) => h.trim());
          const rows = lines.slice(1).map((line) => {
            const vals = line.split(",");
            const row: Record<string, string> = {};
            headers.forEach((h, i) => {
              row[h] = (vals[i] ?? "").trim();
            });
            return row;
          });
          setFileData({ fields: headers, rows });
        }
      } catch {
        setFileData(null);
        setError("No se pudo leer el archivo. Verifique el formato.");
      }
    };
    reader.readAsText(file);
  }, []);

  const handleSaveAndPublish = useCallback(async () => {
    if (!reportName.trim()) {
      setError("El nombre es obligatorio.");
      return;
    }
    if (!selectedLayout) return;
    setSaving(true);
    setError(null);
    try {
      await createSavedReport({
        name: reportName.trim(),
        description: reportDescription.trim(),
        icon: reportIcon || "\uD83D\uDCCA",
        layout: selectedLayout,
        sampleData: buildSampleData(),
      });
      router.push("/report-studio");
    } catch (err) {
      setError(String(err));
    } finally {
      setSaving(false);
    }
  }, [reportName, reportDescription, reportIcon, selectedLayout, buildSampleData, router]);

  const handlePreview = useCallback(() => {
    if (!selectedLayout) return;
    const config = {
      layout: selectedLayout,
      sampleData: buildSampleData(),
    };
    localStorage.setItem("zentto-report-studio-config", JSON.stringify(config));
    router.push("/report-studio/preview");
  }, [selectedLayout, buildSampleData, router]);

  /* ── Step 1: Template selection ────────────────────────────────── */

  const renderStep1 = () => {
    const categories = [...new Set(REPORT_TEMPLATES.map((t) => t.category))];
    return (
      <Box>
        {/* Blank option */}
        <Typography variant="subtitle1" sx={{ mb: 1, fontWeight: 600 }}>
          Empezar desde cero
        </Typography>
        <Card
          variant="outlined"
          sx={{
            mb: 3,
            border: selectedTemplateName === "En blanco" ? "2px solid" : undefined,
            borderColor: "primary.main",
          }}
        >
          <CardActionArea onClick={handleSelectBlank} sx={{ p: 2 }}>
            <Stack direction="row" spacing={2} alignItems="center">
              <Typography variant="h4">{"\uD83D\uDCC4"}</Typography>
              <Box>
                <Typography fontWeight={600}>En blanco</Typography>
                <Typography variant="body2" color="text.secondary">
                  Comienza con un reporte vacio y disenalo desde cero
                </Typography>
              </Box>
            </Stack>
          </CardActionArea>
        </Card>

        {/* By category */}
        {categories.map((cat) => {
          const templates = REPORT_TEMPLATES.filter((t) => t.category === cat);
          if (templates.length === 0) return null;
          return (
            <Box key={cat} sx={{ mb: 3 }}>
              <Typography variant="subtitle1" sx={{ mb: 1, fontWeight: 600 }}>
                {CATEGORY_LABELS[cat] ?? cat}
              </Typography>
              <Grid container spacing={2}>
                {templates.map((tpl) => (
                  <Grid item xs={12} sm={6} md={4} lg={3} key={tpl.id}>
                    <Card
                      variant="outlined"
                      sx={{
                        height: "100%",
                        border:
                          selectedTemplateName === tpl.name ? "2px solid" : undefined,
                        borderColor: "primary.main",
                      }}
                    >
                      <CardActionArea
                        onClick={() =>
                          handleSelectTemplate(
                            tpl.layout as unknown as Record<string, unknown>,
                            tpl.name,
                          )
                        }
                        sx={{ p: 2, height: "100%" }}
                      >
                        <Stack spacing={1}>
                          <Stack direction="row" spacing={1} alignItems="center">
                            <Typography variant="h5">{tpl.icon}</Typography>
                            <Chip
                              label={CATEGORY_LABELS[tpl.category] ?? tpl.category}
                              size="small"
                              variant="outlined"
                            />
                          </Stack>
                          <Typography fontWeight={600} variant="body1">
                            {tpl.name}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {tpl.description}
                          </Typography>
                        </Stack>
                      </CardActionArea>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            </Box>
          );
        })}
      </Box>
    );
  };

  /* ── Step 2: Data source ───────────────────────────────────────── */

  const renderStep2 = () => (
    <Box>
      <FormControl component="fieldset" sx={{ width: "100%" }}>
        <RadioGroup
          value={dataSourceMode}
          onChange={(e) => setDataSourceMode(e.target.value as DataSourceMode)}
        >
          {/* Endpoint */}
          <FormControlLabel value="endpoint" control={<Radio />} label="Endpoint API" />
          {dataSourceMode === "endpoint" && (
            <Box sx={{ pl: 4, mb: 2 }}>
              <Select
                value={selectedEndpoint}
                onChange={(e) => setSelectedEndpoint(e.target.value)}
                size="small"
                fullWidth
                sx={{ maxWidth: 400 }}
              >
                {ENDPOINTS.map((ep) => (
                  <MenuItem key={ep.value} value={ep.value}>
                    {ep.label} &mdash; <code>{ep.value}</code>
                  </MenuItem>
                ))}
              </Select>
            </Box>
          )}

          {/* File */}
          <FormControlLabel value="file" control={<Radio />} label="Archivo CSV/JSON" />
          {dataSourceMode === "file" && (
            <Box sx={{ pl: 4, mb: 2 }}>
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv,.json"
                onChange={handleFileChange}
                style={{ display: "none" }}
              />
              <Stack direction="row" spacing={2} alignItems="center">
                <Button
                  variant="outlined"
                  size="small"
                  onClick={() => fileInputRef.current?.click()}
                >
                  Seleccionar archivo
                </Button>
                {fileName && (
                  <Typography variant="body2" color="text.secondary">
                    {fileName}
                  </Typography>
                )}
              </Stack>
              {fileData && (
                <Alert severity="success" sx={{ mt: 1 }}>
                  Archivo cargado correctamente.
                </Alert>
              )}
            </Box>
          )}

          {/* Manual */}
          <FormControlLabel
            value="manual"
            control={<Radio />}
            label="Campos manuales"
          />
          {dataSourceMode === "manual" && (
            <Box sx={{ pl: 4, mb: 2 }}>
              {manualFields.map((field, idx) => (
                <Stack key={idx} direction="row" spacing={1} sx={{ mb: 1 }} alignItems="center">
                  <TextField
                    size="small"
                    label="Nombre del campo"
                    value={field.fieldName}
                    onChange={(e) => {
                      const updated = [...manualFields];
                      updated[idx] = { ...updated[idx], fieldName: e.target.value };
                      setManualFields(updated);
                    }}
                    sx={{ flex: 1 }}
                  />
                  <Select
                    size="small"
                    value={field.fieldType}
                    onChange={(e) => {
                      const updated = [...manualFields];
                      updated[idx] = {
                        ...updated[idx],
                        fieldType: e.target.value as ManualField["fieldType"],
                      };
                      setManualFields(updated);
                    }}
                    sx={{ minWidth: 120 }}
                  >
                    <MenuItem value="string">Texto</MenuItem>
                    <MenuItem value="number">Numero</MenuItem>
                    <MenuItem value="boolean">Booleano</MenuItem>
                    <MenuItem value="date">Fecha</MenuItem>
                  </Select>
                  <Button
                    size="small"
                    color="error"
                    disabled={manualFields.length <= 1}
                    onClick={() => setManualFields(manualFields.filter((_, i) => i !== idx))}
                  >
                    Quitar
                  </Button>
                </Stack>
              ))}
              <Button
                size="small"
                onClick={() =>
                  setManualFields([...manualFields, { fieldName: "", fieldType: "string" }])
                }
              >
                + Agregar campo
              </Button>
            </Box>
          )}

          {/* None */}
          <FormControlLabel value="none" control={<Radio />} label="Sin datos" />
        </RadioGroup>
      </FormControl>
    </Box>
  );

  /* ── Step 3: Save ──────────────────────────────────────────────── */

  const renderStep3 = () => (
    <Box sx={{ maxWidth: 500 }}>
      <Stack spacing={3}>
        <TextField
          label="Nombre"
          required
          fullWidth
          value={reportName}
          onChange={(e) => setReportName(e.target.value)}
        />
        <TextField
          label="Descripcion"
          multiline
          minRows={3}
          fullWidth
          value={reportDescription}
          onChange={(e) => setReportDescription(e.target.value)}
        />
        <TextField
          label="Icono (emoji)"
          fullWidth
          value={reportIcon}
          onChange={(e) => setReportIcon(e.target.value.slice(0, 4))}
          inputProps={{ maxLength: 4 }}
          helperText="Maximo 4 caracteres. Ej: \uD83D\uDCCA"
        />

        {error && <Alert severity="error">{error}</Alert>}

        <Stack direction="row" spacing={2}>
          <Button
            variant="contained"
            onClick={handleSaveAndPublish}
            disabled={saving || !reportName.trim()}
          >
            {saving ? "Guardando..." : "Guardar y publicar"}
          </Button>
          <Button variant="outlined" onClick={handlePreview} disabled={!selectedLayout}>
            Solo preview
          </Button>
        </Stack>
      </Stack>
    </Box>
  );

  /* ── Step content router ───────────────────────────────────────── */

  const renderStepContent = () => {
    switch (activeStep) {
      case 0:
        return renderStep1();
      case 1:
        return renderStep2();
      case 2:
        return renderStep3();
      default:
        return null;
    }
  };

  /* ── Main render ───────────────────────────────────────────────── */

  return (
    <Box sx={{ minHeight: "100vh", bgcolor: "background.default" }}>
      {/* Header */}
      <Box
        sx={{
          px: 3,
          py: 2,
          borderBottom: 1,
          borderColor: "divider",
          bgcolor: "background.paper",
          display: "flex",
          alignItems: "center",
          gap: 2,
        }}
      >
        <Tooltip title="Volver a Report Studio">
          <IconButton onClick={() => router.push("/report-studio")} size="small">
            <ArrowBackIcon />
          </IconButton>
        </Tooltip>
        <Breadcrumbs separator={<NavigateNextIcon fontSize="small" />}>
          <Link
            underline="hover"
            color="inherit"
            sx={{ cursor: "pointer" }}
            onClick={() => router.push("/report-studio")}
          >
            Report Studio
          </Link>
          <Typography color="text.primary">Wizard</Typography>
        </Breadcrumbs>
      </Box>

      {/* Stepper */}
      <Box sx={{ px: 3, pt: 3, pb: 1 }}>
        <Stepper activeStep={activeStep} alternativeLabel>
          {STEPS.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
      </Box>

      {/* Content */}
      <Box sx={{ px: 3, py: 3 }}>{renderStepContent()}</Box>

      {/* Navigation */}
      {activeStep > 0 && (
        <Box
          sx={{
            px: 3,
            py: 2,
            borderTop: 1,
            borderColor: "divider",
            display: "flex",
            justifyContent: "space-between",
          }}
        >
          <Button onClick={() => setActiveStep((s) => s - 1)}>Atras</Button>
          {activeStep < 2 && (
            <Button variant="contained" onClick={() => setActiveStep((s) => s + 1)}>
              Siguiente
            </Button>
          )}
        </Box>
      )}
    </Box>
  );
}
