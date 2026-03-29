"use client";
import React, { useEffect, useState, useRef } from "react";
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Box, CircularProgress, Alert, Typography,
  FormControl, InputLabel, Select, MenuItem, Stack, Chip, IconButton, Tooltip,
} from "@mui/material";
import PrintIcon from "@mui/icons-material/Print";
import CloseIcon from "@mui/icons-material/Close";
import DescriptionIcon from "@mui/icons-material/Description";
import { useDocumentTemplate, useDocumentTemplatesList, useRenderDocument } from "../hooks/useNomina";

let markedInstance: any = null;
async function renderMarkdown(md: string): Promise<string> {
  if (!markedInstance) {
    const { marked } = await import('marked');
    markedInstance = marked;
    markedInstance.setOptions({ breaks: true, gfm: true });
  }
  return markedInstance.parse(md) as string;
}

function interpolate(content: string, vars: Record<string, string>): string {
  return content.replace(/\{\{([^}]+)\}\}/g, (_, key) => vars[key.trim()] ?? `{{${key}}}`);
}

function buildTable(lines: DirectLine[], filterType?: string): string {
  const filtered = filterType ? lines.filter(l => l.ConceptType === filterType) : lines;
  if (filtered.length === 0) return '*Sin conceptos*';
  let md = '| Código | Concepto | Tipo | Monto |\n|:-------|:---------|:-----|------:|\n';
  for (const l of filtered) md += `| ${l.ConceptCode} | ${l.ConceptName} | ${l.ConceptType} | ${Number(l.Total ?? 0).toFixed(2)} |\n`;
  return md;
}

// CSS profesional para impresión
const PREVIEW_CSS = `
  .doc-preview { font-family: 'Georgia', serif; font-size: 13px; line-height: 1.6; color: #1a1a1a; max-width: 780px; margin: 0 auto; padding: 32px 40px; background: white; }
  .doc-preview h1 { font-size: 18px; text-align: center; text-transform: uppercase; letter-spacing: 1px; border-bottom: 2px solid #1a237e; padding-bottom: 8px; color: #1a237e; }
  .doc-preview h2 { font-size: 13px; text-transform: uppercase; color: #1a237e; border-bottom: 1px solid #e0e0e0; padding-bottom: 4px; margin-top: 20px; }
  .doc-preview blockquote { background: #e8eaf6; border-left: 4px solid #3949ab; padding: 6px 12px; margin: 12px 0; font-size: 11px; color: #283593; }
  .doc-preview table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 12px; }
  .doc-preview th { background: #1a237e; color: white; padding: 6px 8px; text-align: left; font-size: 11px; }
  .doc-preview td { padding: 5px 8px; border-bottom: 1px solid #e0e0e0; }
  .doc-preview tr:nth-child(even) td { background: #f5f5f5; }
  .doc-preview p { margin: 8px 0; }
  .doc-preview hr { border: none; border-top: 1px solid #ccc; margin: 16px 0; }
  @media print { .doc-preview { padding: 20px; } body { margin: 0; } }
`;

// Template type → default templateCode mapping
const TYPE_DEFAULTS: Record<string, string> = {
  payroll: 'VE_RECIBO_PAGO',
  vacation: 'VE_RECIBO_VACACIONES',
  liquidacion: 'VE_LIQUIDACION',
  utilidades: 'VE_PARTICIPACION_GANANCIAS',
};

interface DirectLine {
  ConceptCode: string;
  ConceptName: string;
  ConceptType: string;
  Total: number;
  Quantity: number;
}

interface Props {
  open: boolean;
  onClose: () => void;
  // Source A: API render (payrollRunId o batchId+employeeCode)
  payrollRunId?: number;
  batchId?: number;
  employeeCode?: string;
  employeeName?: string;
  // Source B: render local con vars directas (sin backend lookup)
  directVars?: Record<string, string>;
  directLines?: DirectLine[];
  // Hint for default template
  documentType?: 'payroll' | 'vacation' | 'liquidacion' | 'utilidades';
  // Override template code directly
  templateCode?: string;
}

export default function DocumentViewerModal({
  open, onClose,
  payrollRunId, batchId, employeeCode, employeeName,
  directVars, directLines,
  documentType = 'payroll',
  templateCode: propTemplateCode,
}: Props) {
  const [selectedCode, setSelectedCode] = useState('');
  const [renderedHtml, setRenderedHtml] = useState('');
  const [renderError, setRenderError] = useState('');
  const [localLoading, setLocalLoading] = useState(false);

  const renderMutation = useRenderDocument();
  const { data: templatesData } = useDocumentTemplatesList();
  const templates: any[] = (templatesData as any)?.data ?? [];

  // For local (direct) rendering: fetch template content
  const { data: templateData } = useDocumentTemplate(
    (directVars && selectedCode) ? selectedCode : ''
  );

  // Mode: "direct" when directVars provided, "api" otherwise
  const isDirectMode = !!directVars;

  // Set default template on open
  useEffect(() => {
    if (open) {
      const defaultCode = propTemplateCode || TYPE_DEFAULTS[documentType] || '';
      setSelectedCode(defaultCode);
      setRenderedHtml('');
      setRenderError('');
    }
  }, [open, documentType, propTemplateCode]);

  // API render
  useEffect(() => {
    if (!open || !selectedCode || isDirectMode) return;
    if (!payrollRunId && !batchId) return;
    const source = payrollRunId ? { payrollRunId } : { batchId, employeeCode };
    renderMutation.mutate(
      { templateCode: selectedCode, ...source } as any,
      {
        onSuccess: (data: any) => {
          setRenderedHtml(data?.contentRendered ?? '');
          setRenderError('');
        },
        onError: (err: any) => {
          setRenderError(String(err?.message ?? 'Error al generar el documento'));
        },
      }
    );
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, selectedCode, isDirectMode]);

  // Local (direct) render — uses template ContentMD + interpolates directVars
  useEffect(() => {
    if (!open || !selectedCode || !isDirectMode) return;
    const tpl = (templateData as any);
    if (!tpl?.contentMD) return;
    setLocalLoading(true);
    let content: string = tpl.contentMD;
    content = interpolate(content, directVars!);
    const dl = directLines ?? [];
    const tablaAsig = buildTable(dl.filter(l => l.ConceptType !== 'DEDUCCION' && l.ConceptType !== 'PATRONAL'));
    const tablaDed = buildTable(dl.filter(l => l.ConceptType === 'DEDUCCION'));
    const tablaTodos = buildTable(dl.filter(l => l.ConceptType !== 'PATRONAL'));
    content = content.replace(/\{\{tabla_asignaciones\}\}/g, tablaAsig);
    content = content.replace(/\{\{tabla_deducciones\}\}/g, tablaDed);
    content = content.replace(/\{\{tabla_todos\}\}/g, tablaTodos);
    for (const l of dl) {
      const code = String(l.ConceptCode ?? '').toUpperCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      content = content.replace(new RegExp(`\\{\\{concepto\\.${code}\\.monto\\}\\}`, 'g'), Number(l.Total ?? 0).toFixed(2));
      content = content.replace(new RegExp(`\\{\\{concepto\\.${code}\\.cantidad\\}\\}`, 'g'), String(l.Quantity ?? 0));
    }
    renderMarkdown(content).then(html => {
      setRenderedHtml(html);
      setRenderError('');
      setLocalLoading(false);
    }).catch(() => {
      setRenderError('Error al renderizar el documento');
      setLocalLoading(false);
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, selectedCode, templateData, isDirectMode]);

  const handlePrint = () => {
    const win = window.open('', '_blank');
    if (!win) return;
    win.document.write(`<!DOCTYPE html><html><head><style>${PREVIEW_CSS}</style><title>Documento</title></head><body><div class="doc-preview">${renderedHtml}</div></body></html>`);
    win.document.close();
    win.focus();
    setTimeout(() => win.print(), 500);
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth
      PaperProps={{ sx: { height: '90vh', display: 'flex', flexDirection: 'column' } }}
    >
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1, pb: 1 }}>
        <DescriptionIcon color="primary" />
        <Box flex={1}>
          <Typography variant="subtitle1" fontWeight={700}>Generar Documento</Typography>
          {employeeName && (
            <Typography variant="caption" color="text.secondary">{employeeName}</Typography>
          )}
        </Box>
        <Tooltip title="Cerrar"><IconButton size="small" onClick={onClose}><CloseIcon /></IconButton></Tooltip>
      </DialogTitle>

      <Box sx={{ px: 3, pb: 1, display: 'flex', gap: 2, alignItems: 'center' }}>
        <FormControl sx={{ minWidth: 280 }}>
          <InputLabel>Plantilla</InputLabel>
          <Select
            value={selectedCode}
            label="Plantilla"
            onChange={e => setSelectedCode(e.target.value)}
          >
            {templates.map((t: any) => (
              <MenuItem key={t.templateCode} value={t.templateCode}>
                {t.countryCode} — {t.templateName}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        {batchId && (
          <Chip label={`Lote #${batchId}`} size="small" color="primary" variant="outlined" />
        )}
        {payrollRunId && (
          <Chip label={`Run #${payrollRunId}`} size="small" color="primary" variant="outlined" />
        )}
      </Box>

      <DialogContent sx={{ flex: 1, overflow: 'auto', bgcolor: '#f0f0f0', p: 2 }}>
        {(renderMutation.isPending || localLoading) && (
          <Box display="flex" justifyContent="center" alignItems="center" height="100%">
            <CircularProgress />
          </Box>
        )}
        {renderError && <Alert severity="error" sx={{ mb: 2 }}>{renderError}</Alert>}
        {!renderMutation.isPending && !localLoading && renderedHtml && (
          <>
            <style>{PREVIEW_CSS}</style>
            <div className="doc-preview" dangerouslySetInnerHTML={{ __html: renderedHtml }} />
          </>
        )}
        {!renderMutation.isPending && !localLoading && !renderedHtml && !renderError && (
          <Box display="flex" justifyContent="center" alignItems="center" height="100%">
            <Typography color="text.secondary">Selecciona una plantilla para generar el documento</Typography>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 1.5 }}>
        <Button onClick={onClose} color="inherit">Cerrar</Button>
        <Button
          variant="contained"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          disabled={!renderedHtml || renderMutation.isPending || localLoading}
        >
          Imprimir / PDF
        </Button>
      </DialogActions>
    </Dialog>
  );
}
