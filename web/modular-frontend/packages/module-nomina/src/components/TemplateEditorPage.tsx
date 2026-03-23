"use client";
import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Stack, Typography, Button, IconButton, Tooltip, Chip,
  TextField, FormControl, InputLabel, Select, MenuItem, Alert,
  Divider, CircularProgress, ToggleButtonGroup, ToggleButton,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import PreviewIcon from "@mui/icons-material/Preview";
import CodeIcon from "@mui/icons-material/Code";
import PictureAsPdfIcon from "@mui/icons-material/PictureAsPdf";
import DescriptionIcon from "@mui/icons-material/Description";
import HelpOutlineIcon from "@mui/icons-material/HelpOutline";
import DataObjectIcon from "@mui/icons-material/DataObject";
import RefreshIcon from "@mui/icons-material/Refresh";
import Editor from "@monaco-editor/react";
import { useDocumentTemplate, useSaveDocumentTemplate } from "../hooks/useNomina";
import { apiGet, useCountries } from "@zentto/shared-api";

// Lazy-import marked para evitar problemas de SSR
let markedInstance: any = null;
async function renderMarkdown(md: string): Promise<string> {
  if (!markedInstance) {
    const { marked } = await import('marked');
    markedInstance = marked;
    markedInstance.setOptions({ breaks: true, gfm: true });
  }
  return markedInstance.parse(md);
}

// Referencia de variables de plantilla
const VARIABLES_REF = [
  { group: "Empresa", vars: ["{{empresa.nombre}}", "{{empresa.rif}}", "{{empresa.direccion}}", "{{empresa.representante}}"] },
  { group: "Empleado", vars: ["{{empleado.nombre}}", "{{empleado.cedula}}", "{{empleado.cargo}}", "{{empleado.departamento}}", "{{empleado.fechaIngreso}}", "{{empleado.antiguedad}}"] },
  { group: "Período", vars: ["{{periodo.desde}}", "{{periodo.hasta}}", "{{periodo.tipo}}"] },
  { group: "Nómina", vars: ["{{nomina.tipo}}", "{{nomina.totalAsignaciones}}", "{{nomina.totalDeducciones}}", "{{nomina.neto}}", "{{nomina.netoLetras}}"] },
  { group: "Tablas (se reemplazan auto)", vars: ["{{tabla_asignaciones}}", "{{tabla_deducciones}}", "{{tabla_todos}}"] },
  { group: "Conceptos", vars: ["{{concepto.CODIGO.monto}}", "{{concepto.CODIGO.cantidad}}"] },
  { group: "Fecha/Misc", vars: ["{{fecha.generacion}}", "{{anio}}", "{{mes}}"] },
];

const TEMPLATE_TYPES = ['RECIBO_PAGO', 'RECIBO_VAC', 'UTILIDADES', 'LIQUIDACION', 'NOMINA_ES', 'FINIQUITO_ES', 'CUSTOM'];

// CSS para la vista previa del documento (apariencia profesional)
const PREVIEW_CSS = `
  .doc-preview {
    font-family: 'Georgia', serif;
    font-size: 13px;
    line-height: 1.6;
    color: #1a1a1a;
    max-width: 780px;
    margin: 0 auto;
    padding: 32px 40px;
    background: white;
    box-shadow: 0 2px 12px rgba(0,0,0,0.12);
  }
  .doc-preview h1 { font-size: 18px; text-align: center; text-transform: uppercase; letter-spacing: 1px; border-bottom: 2px solid #1a237e; padding-bottom: 8px; color: #1a237e; }
  .doc-preview h2 { font-size: 13px; text-transform: uppercase; color: #1a237e; border-bottom: 1px solid #e0e0e0; padding-bottom: 4px; margin-top: 20px; }
  .doc-preview blockquote { background: #e8eaf6; border-left: 4px solid #3949ab; padding: 6px 12px; margin: 12px 0; font-size: 11px; color: #283593; }
  .doc-preview table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 12px; }
  .doc-preview th { background: #1a237e; color: white; padding: 6px 8px; text-align: left; font-size: 11px; }
  .doc-preview td { padding: 5px 8px; border-bottom: 1px solid #e0e0e0; }
  .doc-preview tr:nth-child(even) td { background: #f5f5f5; }
  .doc-preview p { margin: 8px 0; }
  .doc-preview hr { border: none; border-top: 1px solid #ccc; margin: 16px 0; }
  .doc-preview strong { font-weight: 700; }
  .doc-preview em { font-style: italic; color: #555; }
  @media print {
    .doc-preview { box-shadow: none; padding: 20px; }
    body { margin: 0; }
  }
`;

interface Props {
  templateCode?: string; // '__new__' para nuevo, código para editar, '__clone__XX' para clonar
  onBack?: () => void;
}

export default function TemplateEditorPage({ templateCode, onBack }: Props) {
  const isNew = !templateCode || templateCode === '__new__';
  const isClone = templateCode?.startsWith('__clone__');
  const sourceCode = isClone ? templateCode!.replace('__clone__', '') : templateCode;

  const { data: existingTemplate, isLoading } = useDocumentTemplate(
    (!isNew && !isClone) ? sourceCode! : ''
  );
  const { data: cloneSource } = useDocumentTemplate(isClone ? sourceCode! : '');

  const saveMutation = useSaveDocumentTemplate();
  const { data: countriesData = [] } = useCountries();
  const countryOptions = [...countriesData.map(c => c.CountryCode), 'ALL'];

  const [form, setForm] = useState({
    templateCode: '',
    templateName: '',
    templateType: 'RECIBO_PAGO',
    countryCode: 'VE',
    payrollCode: '',
    contentMD: '',
  });

  const [previewHtml, setPreviewHtml] = useState('');
  const [activeTab, setActiveTab] = useState<'editor' | 'preview' | 'split'>('split');
  const [showVarsPanel, setShowVarsPanel] = useState(false);
  const [previewLoading, setPreviewLoading] = useState(false);
  const previewTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);

  // ─── Datos reales para preview ────────────────────────────────
  const [showRealData, setShowRealData] = useState(false);
  const [realBatchId, setRealBatchId] = useState('');
  const [realEmpCode, setRealEmpCode] = useState('');
  const [realVars, setRealVars] = useState<Record<string, string> | null>(null);
  const [realVarsLoading, setRealVarsLoading] = useState(false);
  const [realVarsError, setRealVarsError] = useState('');

  // Cargar plantilla existente
  useEffect(() => {
    const source = isClone ? cloneSource : existingTemplate;
    if (source && (typeof source === 'object')) {
      const tpl = (source as any).data ?? (source as any);
      setForm({
        templateCode: isClone ? '' : (tpl.templateCode ?? ''),
        templateName: isClone ? `Copia de ${tpl.templateName}` : (tpl.templateName ?? ''),
        templateType: tpl.templateType ?? 'RECIBO_PAGO',
        countryCode: tpl.countryCode ?? 'VE',
        payrollCode: tpl.payrollCode ?? '',
        contentMD: tpl.contentMD ?? '',
      });
    }
  }, [existingTemplate, cloneSource, isClone]);

  // Actualizar preview con debounce (con o sin datos reales)
  useEffect(() => {
    if (previewTimeout.current) clearTimeout(previewTimeout.current);
    previewTimeout.current = setTimeout(async () => {
      if (!form.contentMD) { setPreviewHtml(''); return; }
      setPreviewLoading(true);
      try {
        let content = form.contentMD;
        if (realVars) {
          // Interpolar con datos reales
          content = content.replace(/\{\{([^}]+)\}\}/g, (_, key) => realVars[key.trim()] ?? `{{${key}}}`);
        }
        const html = await renderMarkdown(content);
        setPreviewHtml(html as string);
      } catch {
        setPreviewHtml('<p>Error al renderizar el Markdown</p>');
      }
      setPreviewLoading(false);
    }, 500);
  }, [form.contentMD, realVars]);

  const handleSave = async () => {
    await saveMutation.mutateAsync(form as any);
    if (onBack) onBack();
  };

  const handlePrint = () => {
    const win = window.open('', '_blank');
    if (!win) return;
    win.document.write(`<!DOCTYPE html><html><head><style>${PREVIEW_CSS}</style><title>${form.templateName}</title></head><body><div class="doc-preview">${previewHtml}</div></body></html>`);
    win.document.close();
    win.focus();
    setTimeout(() => win.print(), 500);
  };

  const insertVariable = (v: string) => {
    setForm(f => ({ ...f, contentMD: f.contentMD + v }));
  };

  const handleLoadRealVars = async () => {
    if (!realBatchId || !realEmpCode) {
      setRealVarsError('Ingresa el Lote # y la cédula del empleado');
      return;
    }
    setRealVarsLoading(true);
    setRealVarsError('');
    try {
      const data: any = await apiGet(`/v1/nomina/documentos/templates/vars/batch/${realBatchId}/${realEmpCode}`);
      setRealVars(data?.vars ?? {});
    } catch (e: any) {
      setRealVarsError(String(e?.message ?? 'No se pudo cargar los datos'));
    }
    setRealVarsLoading(false);
  };

  const handleClearRealVars = () => {
    setRealVars(null);
    setRealVarsError('');
  };

  const editorPane = (
    <Box sx={{ flex: 1, minWidth: 0, height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Typography variant="caption" color="text.secondary" sx={{ px: 1, py: 0.5, bgcolor: '#1e1e1e', color: '#858585', display: 'flex', alignItems: 'center', gap: 1 }}>
        <CodeIcon fontSize="small" /> Markdown — usa {`{{variable}}`} para datos dinámicos
      </Typography>
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <Editor
          language="markdown"
          value={form.contentMD}
          onChange={v => setForm(f => ({ ...f, contentMD: v ?? '' }))}
          theme="vs-dark"
          options={{
            wordWrap: 'on',
            minimap: { enabled: false },
            lineNumbers: 'on',
            fontSize: 13,
            renderWhitespace: 'none',
            scrollBeyondLastLine: false,
          }}
          height="100%"
        />
      </Box>
    </Box>
  );

  const previewPane = (
    <Box sx={{ flex: 1, minWidth: 0, height: '100%', overflow: 'auto', bgcolor: '#f0f0f0', p: 2 }}>
      <style>{PREVIEW_CSS}</style>
      {previewLoading ? (
        <Box display="flex" justifyContent="center" pt={4}><CircularProgress size={24} /></Box>
      ) : (
        <div
          className="doc-preview"
          dangerouslySetInnerHTML={{ __html: previewHtml || '<p style="color:#999; text-align:center; padding: 40px">Escribe en el editor para ver la vista previa</p>' }}
        />
      )}
    </Box>
  );

  if (isLoading) return <Box p={4}><CircularProgress /></Box>;

  return (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', gap: 0 }}>
      {/* Cabecera */}
      <Paper sx={{ px: 2, py: 1.5, borderRadius: 0, borderBottom: '1px solid', borderColor: 'divider' }} elevation={1}>
        <Stack direction="row" alignItems="center" spacing={2}>
          {onBack && (
            <Tooltip title="Volver">
              <IconButton size="small" onClick={onBack}><ArrowBackIcon /></IconButton>
            </Tooltip>
          )}
          <DescriptionIcon color="primary" />
          <Stack sx={{ flex: 1 }} spacing={0}>
            <TextField
             
              placeholder="Nombre de la plantilla"
              value={form.templateName}
              onChange={e => setForm(f => ({ ...f, templateName: e.target.value }))}
              variant="standard"
              inputProps={{ style: { fontSize: '1rem', fontWeight: 700 } }}
              sx={{ minWidth: 300 }}
            />
          </Stack>

          {/* Campos de metadatos */}
          <FormControl sx={{ minWidth: 130 }}>
            <InputLabel>Tipo</InputLabel>
            <Select value={form.templateType} label="Tipo" onChange={e => setForm(f => ({ ...f, templateType: e.target.value }))}>
              {TEMPLATE_TYPES.map(t => <MenuItem key={t} value={t}>{t}</MenuItem>)}
            </Select>
          </FormControl>
          <FormControl sx={{ minWidth: 90 }}>
            <InputLabel>País</InputLabel>
            <Select value={form.countryCode} label="País" onChange={e => setForm(f => ({ ...f, countryCode: e.target.value }))}>
              {countryOptions.map(c => <MenuItem key={c} value={c}>{c}</MenuItem>)}
            </Select>
          </FormControl>
          {isNew && (
            <TextField
             
              label="Código"
              placeholder="MI_PLANTILLA"
              value={form.templateCode}
              onChange={e => setForm(f => ({ ...f, templateCode: e.target.value.toUpperCase() }))}
              sx={{ width: 160 }}
            />
          )}

          {/* Toggles de vista */}
          <ToggleButtonGroup size="small" value={activeTab} exclusive onChange={(_, v) => v && setActiveTab(v)}>
            <ToggleButton value="editor"><Tooltip title="Solo editor"><CodeIcon fontSize="small" /></Tooltip></ToggleButton>
            <ToggleButton value="split"><Tooltip title="Editor + Preview"><PreviewIcon fontSize="small" /></Tooltip></ToggleButton>
            <ToggleButton value="preview"><Tooltip title="Solo preview"><DescriptionIcon fontSize="small" /></Tooltip></ToggleButton>
          </ToggleButtonGroup>

          <Tooltip title={realVars ? "Datos reales cargados" : "Previsualizar con datos reales"}>
            <IconButton
              size="small"
              onClick={() => setShowRealData(v => !v)}
              color={realVars ? "success" : "default"}
            >
              <DataObjectIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="Variables disponibles">
            <IconButton size="small" onClick={() => setShowVarsPanel(v => !v)}>
              <HelpOutlineIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="Imprimir / Guardar PDF">
            <span>
              <IconButton size="small" onClick={handlePrint} disabled={!previewHtml}>
                <PictureAsPdfIcon />
              </IconButton>
            </span>
          </Tooltip>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={handleSave}
            disabled={saveMutation.isPending || !form.templateName || !form.contentMD}
          >
            Guardar
          </Button>
        </Stack>
      </Paper>

      {saveMutation.isError && (
        <Alert severity="error" sx={{ borderRadius: 0 }}>
          Error al guardar: {(saveMutation.error as any)?.message}
        </Alert>
      )}

      {/* Panel lateral de variables */}
      {showVarsPanel && (
        <Paper sx={{ mx: 2, mt: 1, p: 1.5, bgcolor: '#fffde7', border: '1px solid #f9a825' }} elevation={0}>
          <Typography variant="caption" fontWeight={700} display="block" mb={1}>
            Variables disponibles — haz clic para insertar
          </Typography>
          <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap>
            {VARIABLES_REF.map(group => (
              <Box key={group.group}>
                <Typography variant="caption" color="text.secondary" fontWeight={700}>{group.group}</Typography>
                <Stack direction="row" spacing={0.5} flexWrap="wrap" useFlexGap mt={0.5}>
                  {group.vars.map(v => (
                    <Chip
                      key={v}
                      label={v}
                      size="small"
                      clickable
                      onClick={() => insertVariable(v)}
                      sx={{ fontFamily: 'monospace', fontSize: '0.65rem', height: 20 }}
                    />
                  ))}
                </Stack>
              </Box>
            ))}
          </Stack>
        </Paper>
      )}

      {/* Panel de datos reales para preview */}
      {showRealData && (
        <Paper sx={{ mx: 2, mt: 1, p: 1.5, bgcolor: realVars ? '#e8f5e9' : '#e3f2fd', border: '1px solid', borderColor: realVars ? '#66bb6a' : '#42a5f5' }} elevation={0}>
          <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap" useFlexGap>
            <Typography variant="caption" fontWeight={700} color={realVars ? 'success.dark' : 'primary.main'}>
              {realVars ? '✓ Datos reales activos' : 'Preview con datos reales'}
            </Typography>
            <TextField
             
              label="Lote #"
              value={realBatchId}
              onChange={e => setRealBatchId(e.target.value)}
              sx={{ width: 100 }}
              disabled={!!realVars}
            />
            <TextField
             
              label="Cédula empleado"
              value={realEmpCode}
              onChange={e => setRealEmpCode(e.target.value)}
              sx={{ width: 160 }}
              placeholder="V-12345678"
              disabled={!!realVars}
            />
            {!realVars ? (
              <Button
                size="small"
                variant="contained"
                startIcon={realVarsLoading ? <CircularProgress size={14} color="inherit" /> : <RefreshIcon />}
                onClick={handleLoadRealVars}
                disabled={realVarsLoading}
              >
                Cargar datos
              </Button>
            ) : (
              <Button size="small" variant="outlined" color="warning" onClick={handleClearRealVars}>
                Limpiar datos
              </Button>
            )}
            {realVarsError && <Typography variant="caption" color="error">{realVarsError}</Typography>}
            {realVars && (
              <Typography variant="caption" color="success.dark">
                {Object.keys(realVars).length} variables cargadas
              </Typography>
            )}
          </Stack>
        </Paper>
      )}

      {/* Área principal del editor */}
      <Box sx={{ flex: 1, minHeight: 0, display: 'flex', overflow: 'hidden' }}>
        {activeTab === 'editor' && editorPane}
        {activeTab === 'preview' && previewPane}
        {activeTab === 'split' && (
          <>
            <Box sx={{ flex: 1, minWidth: 0, height: '100%', display: 'flex', flexDirection: 'column' }}>
              {editorPane}
            </Box>
            <Divider orientation="vertical" />
            <Box sx={{ flex: 1, minWidth: 0, height: '100%' }}>
              {previewPane}
            </Box>
          </>
        )}
      </Box>
    </Box>
  );
}
