'use client';

import {
  Box, Typography, Card, CardContent, CardHeader,
  TextField, Button, Stack, Switch, FormControlLabel,
  Alert, Select, MenuItem, InputLabel, FormControl, Divider
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import { useAuth } from '@datqbox/shared-auth';
import { useConfigStore } from '@datqbox/shared-api';

export default function ConfiguracionPage() {
  const { isAdmin } = useAuth();
  const {
    config, setConfig,
    setContabilidadConfig, setNominaConfig,
    setBancosConfig, setInventarioConfig
  } = useConfigStore();

  if (!isAdmin) {
    return (
      <Box>
        <Alert severity="error">
          No tienes permisos para acceder a esta sección. Solo administradores pueden configurar el sistema.
        </Alert>
      </Box>
    );
  }

  return (
    <Box>

      <Grid container spacing={3}>
        {/* Configuración General */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Configuración General" />
            <CardContent>
              <Stack spacing={2}>
                <TextField
                  fullWidth
                  label="Nombre de la Empresa"
                  value={config.nombreEmpresa}
                  onChange={(e) => setConfig({ nombreEmpresa: e.target.value })}
                  size="small"
                />
                <FormControl fullWidth size="small">
                  <InputLabel>País / Régimen Fiscal</InputLabel>
                  <Select
                    value={config.pais}
                    label="País / Régimen Fiscal"
                    onChange={(e) => setConfig({ pais: e.target.value as string })}
                  >
                    <MenuItem value="VE">Venezuela (SENIAT)</MenuItem>
                    <MenuItem value="CO">Colombia (DIAN)</MenuItem>
                    <MenuItem value="MX">México (SAT)</MenuItem>
                    <MenuItem value="ES">España (AEAT)</MenuItem>
                    <MenuItem value="US">USA (IRS)</MenuItem>
                  </Select>
                </FormControl>

                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2" color="primary">Módulo Contable</Typography>

                <TextField
                  fullWidth
                  label="Nombre Identificador Fiscal (ej. RIF, NIT, RFC)"
                  value={config.contabilidad.nombreIdentificacion}
                  onChange={(e) => setContabilidadConfig({ nombreIdentificacion: e.target.value })}
                  size="small"
                />
                <TextField
                  fullWidth
                  label="Nombre Impuesto Principal (ej. IVA, IGV)"
                  value={config.contabilidad.nombreImpuestoPrincipal}
                  onChange={(e) => setContabilidadConfig({ nombreImpuestoPrincipal: e.target.value })}
                  size="small"
                />
                <TextField
                  fullWidth
                  label="Formato Plan de Cuentas"
                  value={config.contabilidad.formatoPlanCuentas}
                  onChange={(e) => setContabilidadConfig({ formatoPlanCuentas: e.target.value })}
                  size="small"
                  helperText="Define como se estructuran las sub-cuentas (ej. X.X.XX.XX)"
                />
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Configuración de Nómina y RRHH */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Módulo Nómina y RRHH" />
            <CardContent>
              <Stack spacing={2}>
                <FormControl fullWidth size="small">
                  <InputLabel>Frecuencia de Pago</InputLabel>
                  <Select
                    value={config.nomina.periodoPago}
                    label="Frecuencia de Pago"
                    onChange={(e) => setNominaConfig({ periodoPago: e.target.value as any })}
                  >
                    <MenuItem value="semanal">Semanal</MenuItem>
                    <MenuItem value="quincenal">Quincenal</MenuItem>
                    <MenuItem value="mensual">Mensual</MenuItem>
                  </Select>
                </FormControl>
                <FormControlLabel
                  control={<Switch checked={config.nomina.aplicaISR} onChange={(e) => setNominaConfig({ aplicaISR: e.target.checked })} />}
                  label="Deducir Impuesto sobre la Renta (ISLR / ISR)"
                />
                <FormControlLabel
                  control={<Switch checked={config.nomina.aplicaSeguroSocial} onChange={(e) => setNominaConfig({ aplicaSeguroSocial: e.target.checked })} />}
                  label="Deducir Seguro Social (IVSS)"
                />
                <Divider sx={{ my: 1 }} />

                <Typography variant="subtitle2" color="primary">Módulo Bancos</Typography>
                <TextField
                  fullWidth size="small" type="number"
                  label="Precisión Decimal (Tránsito Bancario)"
                  value={config.bancos.precisionBancaria}
                  onChange={e => setBancosConfig({ precisionBancaria: Number(e.target.value) })}
                />
                <FormControl fullWidth size="small">
                  <InputLabel>Formato de Conciliación Bancaria</InputLabel>
                  <Select
                    value={config.bancos.formatoExportacion}
                    label="Formato de Exportación"
                    onChange={(e) => setBancosConfig({ formatoExportacion: e.target.value as any })}
                  >
                    <MenuItem value="csv">Excel CSV</MenuItem>
                    <MenuItem value="mt940">SWIFT MT940</MenuItem>
                    <MenuItem value="qbo">QuickBooks QBO</MenuItem>
                  </Select>
                </FormControl>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Modos Inventario y Operaciones */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Módulo Inventario" />
            <CardContent>
              <Stack spacing={2}>
                <FormControl fullWidth size="small">
                  <InputLabel>Método de Valoración (Costeo)</InputLabel>
                  <Select
                    value={config.inventario.metodoCosteo}
                    label="Método de Valoración (Costeo)"
                    onChange={(e) => setInventarioConfig({ metodoCosteo: e.target.value as any })}
                  >
                    <MenuItem value="PROMEDIO">Promedio Móvil Ponderado</MenuItem>
                    <MenuItem value="FIFO">FIFO (PEPS)</MenuItem>
                    <MenuItem value="LIFO">LIFO (UEPS)</MenuItem>
                  </Select>
                </FormControl>

                <FormControlLabel
                  control={<Switch checked={config.inventario.permitirStockNegativo} onChange={e => setInventarioConfig({ permitirStockNegativo: e.target.checked })} />}
                  label="Permitir Facturar con Stock Negativo (Riesgo Contable)"
                />
                <FormControlLabel
                  control={<Switch checked={config.inventario.manejarLotesYVencimiento} onChange={e => setInventarioConfig({ manejarLotesYVencimiento: e.target.checked })} />}
                  label="Validación Estricta de Lotes y Vencimiento"
                />
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Gestión de Usuarios */}
        <Grid size={{ xs: 12 }}>
          <Card>
            <CardHeader title="Gestión de Usuarios" />
            <CardContent>
              <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                Desde aquí puedes crear, editar y eliminar usuarios del sistema
              </Typography>
              <Button variant="contained" color="primary">
                Administrar Usuarios
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Respaldo de Base de Datos */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Respaldo de Base de Datos" />
            <CardContent>
              <Stack spacing={2}>
                <Typography variant="body2" color="textSecondary">
                  Último respaldo: Hoy a las 03:45 AM
                </Typography>
                <Stack direction="row" gap={1}>
                  <Button variant="contained" color="primary">
                    Crear Respaldo Ahora
                  </Button>
                  <Button variant="outlined">
                    Descargar Respaldo
                  </Button>
                </Stack>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Información del Sistema */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Información del Sistema" />
            <CardContent>
              <Stack spacing={1}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" color="textSecondary">
                    Versión:
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    1.0.0
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" color="textSecondary">
                    Base de Datos:
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    SQL Server
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2" color="textSecondary">
                    Usuarios Activos:
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    12
                  </Typography>
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
