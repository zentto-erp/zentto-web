'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import MenuItem from '@mui/material/MenuItem';
import Alert from '@mui/material/Alert';
import Paper from '@mui/material/Paper';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import SendIcon from '@mui/icons-material/Send';
import { apiPost } from '@zentto/shared-api';

const TYPES = [
  { value: 'bug', label: 'Reporte de error' },
  { value: 'feature', label: 'Solicitar funcionalidad' },
  { value: 'question', label: 'Pregunta general' },
];

const MODULES = [
  { value: '', label: 'General' },
  { value: 'ventas', label: 'Ventas / Facturación' },
  { value: 'compras', label: 'Compras' },
  { value: 'inventario', label: 'Inventario' },
  { value: 'contabilidad', label: 'Contabilidad' },
  { value: 'bancos', label: 'Bancos / Tesorería' },
  { value: 'nomina', label: 'Nómina / RRHH' },
  { value: 'pos', label: 'Punto de Venta' },
  { value: 'restaurante', label: 'Restaurante' },
  { value: 'ecommerce', label: 'E-Commerce' },
  { value: 'crm', label: 'CRM' },
  { value: 'logistica', label: 'Logística' },
  { value: 'auditoria', label: 'Auditoría' },
  { value: 'fiscal', label: 'Fiscal / Impresoras' },
  { value: 'mobile', label: 'Aplicación Móvil' },
];

const SEVERITIES = [
  { value: 'bajo', label: 'Bajo — cosmético o menor' },
  { value: 'medio', label: 'Medio — funcionalidad afectada' },
  { value: 'alto', label: 'Alto — bloquea trabajo' },
  { value: 'critico', label: 'Crítico — sistema caído' },
];

export default function NuevoTicketPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    type: 'bug',
    module: '',
    severity: 'medio',
    title: '',
    description: '',
    steps: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const isBug = form.type === 'bug';

  const handleChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const payload: Record<string, string> = {
        type: form.type,
        title: form.title,
        description: form.description,
      };
      if (form.module) payload.module = form.module;
      if (isBug) {
        payload.severity = form.severity;
        if (form.steps) payload.steps = form.steps;
      }

      const res = await apiPost('/v1/support/ticket', payload);
      if (res?.ok) {
        router.push(`/soporte/${res.ticketNumber}`);
      } else {
        setError(res?.message || 'Error al crear el ticket');
      }
    } catch {
      setError('Error de conexión. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ p: 3, maxWidth: 700, mx: 'auto' }}>
      <Button
        startIcon={<ArrowBackIcon />}
        onClick={() => router.push('/soporte')}
        sx={{ mb: 2 }}
      >
        Volver a tickets
      </Button>

      <Typography variant="h5" fontWeight={700} gutterBottom>
        Nuevo Ticket de Soporte
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper sx={{ p: 3 }}>
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
          <TextField
            select
            label="Tipo de solicitud"
            value={form.type}
            onChange={handleChange('type')}
            required
          >
            {TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
          </TextField>

          <TextField
            select
            label="Módulo"
            value={form.module}
            onChange={handleChange('module')}
          >
            {MODULES.map((m) => <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>)}
          </TextField>

          {isBug && (
            <TextField
              select
              label="Severidad"
              value={form.severity}
              onChange={handleChange('severity')}
              required
            >
              {SEVERITIES.map((s) => <MenuItem key={s.value} value={s.value}>{s.label}</MenuItem>)}
            </TextField>
          )}

          <TextField
            label="Título"
            value={form.title}
            onChange={handleChange('title')}
            required
            placeholder="Resumen breve del problema o solicitud"
          />

          <TextField
            label="Descripción"
            value={form.description}
            onChange={handleChange('description')}
            required
            multiline
            rows={4}
            placeholder="Describe en detalle lo que ocurre o lo que necesitas"
          />

          {isBug && (
            <TextField
              label="Pasos para reproducir"
              value={form.steps}
              onChange={handleChange('steps')}
              multiline
              rows={3}
              placeholder="1. Ir a...\n2. Hacer clic en...\n3. Ver error..."
            />
          )}

          {isBug && (
            <Alert severity="info" variant="outlined">
              Los reportes de errores son analizados automáticamente por nuestro agente de IA,
              que intentará crear una corrección. Recibirás notificaciones por email del progreso.
            </Alert>
          )}

          <Button
            type="submit"
            variant="contained"
            size="large"
            endIcon={<SendIcon />}
            disabled={loading || !form.title || !form.description}
          >
            {loading ? 'Creando ticket...' : 'Crear Ticket'}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
