"use client";
import React, { useState } from "react";
import {
  Box, Button, Stack, Typography, Chip, IconButton, Tooltip,
  FormControl, InputLabel, Select, MenuItem, Alert, Grid,
  Card, CardContent, CardActions, Divider
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import DescriptionIcon from "@mui/icons-material/Description";
import LockIcon from "@mui/icons-material/Lock";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import { useCountries, useLookup } from "@zentto/shared-api";
import { useDocumentTemplatesList, useDeleteDocumentTemplate, type DocumentTemplate } from "../hooks/useNomina";

const FLAG_MAP: Record<string, string> = { VE: '\u{1F1FB}\u{1F1EA}', ES: '\u{1F1EA}\u{1F1F8}', MX: '\u{1F1F2}\u{1F1FD}', CO: '\u{1F1E8}\u{1F1F4}', US: '\u{1F1FA}\u{1F1F8}' };

const TYPE_COLORS: Record<string, string> = {
  RECIBO_PAGO: '#1565c0',
  RECIBO_VAC: '#2e7d32',
  UTILIDADES: '#e65100',
  LIQUIDACION: '#6a1b9a',
  NOMINA_ES: '#c62828',
  FINIQUITO_ES: '#ad1457',
  CUSTOM: '#546e7a',
};

export default function DocumentosPage({ onEditTemplate }: { onEditTemplate?: (code: string) => void }) {
  const [filterCountry, setFilterCountry] = useState('');
  const [filterType, setFilterType] = useState('');

  const { data: countriesData = [] } = useCountries();
  const COUNTRIES = [
    ...countriesData.map(c => ({ code: c.CountryCode, label: c.CountryName, flag: FLAG_MAP[c.CountryCode] ?? '\u{1F3F3}' })),
    { code: 'ALL', label: 'Todos los pa\u00edses', flag: '\u{1F30D}' },
  ];

  const { data: templateTypesData = [] } = useLookup('TEMPLATE_TYPE');
  const TEMPLATE_TYPES = templateTypesData.map(t => ({
    value: t.Code,
    label: t.Label,
    icon: t.Extra ?? '\u{1F4C4}',
  }));

  const { data, isLoading } = useDocumentTemplatesList(filterCountry || undefined, filterType || undefined);
  const deleteMutation = useDeleteDocumentTemplate();

  const templates: DocumentTemplate[] = (data as any)?.data ?? (data as any) ?? [];

  const grouped = templates.reduce<Record<string, DocumentTemplate[]>>((acc, t) => {
    const key = t.countryCode;
    if (!acc[key]) acc[key] = [];
    acc[key].push(t);
    return acc;
  }, {});

  const getTypeLabel = (type: string) => TEMPLATE_TYPES.find(t => t.value === type)?.label ?? type;
  const getTypeIcon = (type: string) => TEMPLATE_TYPES.find(t => t.value === type)?.icon ?? '\u{1F4C4}';
  const getCountryLabel = (code: string) => {
    const c = COUNTRIES.find(c => c.code === code);
    return c ? `${c.flag} ${c.label}` : code;
  };

  const handleDelete = async (tpl: DocumentTemplate) => {
    if (tpl.isSystem) return;
    if (!window.confirm(`¿Eliminar plantilla "${tpl.templateName}"?`)) return;
    await deleteMutation.mutateAsync(tpl.templateCode);
  };

  const handleDuplicate = (tpl: DocumentTemplate) => {
    if (onEditTemplate) onEditTemplate(`__clone__${tpl.templateCode}`);
  };

  return (
    <Box>
      {/* Filters + New button */}
      <Stack direction="row" spacing={2} mb={3} alignItems="center" flexWrap="wrap">
        <Box sx={{ flexGrow: 1 }} />
        <FormControl sx={{ minWidth: 150 }}>
          <InputLabel>País</InputLabel>
          <Select value={filterCountry} label="País" onChange={e => setFilterCountry(e.target.value)}>
            <MenuItem value="">Todos</MenuItem>
            {COUNTRIES.map(c => <MenuItem key={c.code} value={c.code}>{c.flag} {c.label}</MenuItem>)}
          </Select>
        </FormControl>
        <FormControl sx={{ minWidth: 180 }}>
          <InputLabel>Tipo</InputLabel>
          <Select value={filterType} label="Tipo" onChange={e => setFilterType(e.target.value)}>
            <MenuItem value="">Todos</MenuItem>
            {TEMPLATE_TYPES.map(t => <MenuItem key={t.value} value={t.value}>{t.icon} {t.label}</MenuItem>)}
          </Select>
        </FormControl>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => onEditTemplate?.('__new__')}>
          Nueva Plantilla
        </Button>
      </Stack>

      {isLoading && <Typography color="text.secondary">Cargando plantillas...</Typography>}

      {Object.entries(grouped).map(([country, tpls]) => (
        <Box key={country} mb={3}>
          <Typography variant="subtitle1" fontWeight={700} mb={1} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {getCountryLabel(country)}
            <Chip label={`${tpls.length} plantillas`} size="small" />
          </Typography>
          <Grid container spacing={2}>
            {tpls.map(tpl => (
              <Grid item xs={12} sm={6} md={4} key={tpl.templateCode}>
                <Card variant="outlined" sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                  <CardContent sx={{ flex: 1 }}>
                    <Stack direction="row" alignItems="flex-start" spacing={1}>
                      <Typography fontSize="1.5rem">{getTypeIcon(tpl.templateType)}</Typography>
                      <Box flex={1}>
                        <Typography variant="subtitle2" fontWeight={700} gutterBottom>
                          {tpl.templateName}
                          {tpl.isSystem && (
                            <Tooltip title="Plantilla legal del sistema (protegida)">
                              <LockIcon fontSize="small" sx={{ ml: 0.5, color: 'warning.main', verticalAlign: 'middle' }} />
                            </Tooltip>
                          )}
                        </Typography>
                        <Chip
                          label={getTypeLabel(tpl.templateType)}
                          size="small"
                          sx={{ bgcolor: (TYPE_COLORS[tpl.templateType] ?? '#546e7a') + '22', color: TYPE_COLORS[tpl.templateType] ?? '#546e7a', fontWeight: 600, fontSize: '0.7rem' }}
                        />
                      </Box>
                    </Stack>
                    <Typography variant="caption" color="text.secondary" display="block" mt={1}>
                      Código: <code>{tpl.templateCode}</code>
                      {tpl.payrollCode && ` · Nómina: ${tpl.payrollCode}`}
                    </Typography>
                  </CardContent>
                  <Divider />
                  <CardActions>
                    <Tooltip title="Editar plantilla">
                      <IconButton size="small" color="primary" onClick={() => onEditTemplate?.(tpl.templateCode)}>
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Duplicar como nueva">
                      <IconButton size="small" onClick={() => handleDuplicate(tpl)}>
                        <ContentCopyIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    {!tpl.isSystem && (
                      <Tooltip title="Eliminar">
                        <IconButton size="small" color="error" onClick={() => handleDelete(tpl)}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    )}
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      ))}

      {!isLoading && templates.length === 0 && (
        <Alert severity="info">No hay plantillas configuradas. Crea una nueva o ajusta los filtros.</Alert>
      )}
    </Box>
  );
}
