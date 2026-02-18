'use client';

import {
  Box,
  Typography,
  Card,
  CardContent,
  CardHeader,
  TextField,
  Button,
  Stack,
  Switch,
  FormControlLabel,
  Alert,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import { useAuth } from '@datqbox/shared-auth';

export default function ConfiguracionPage() {
  const { isAdmin } = useAuth();

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
                  defaultValue="DatqBox"
                  size="small"
                />
                <TextField
                  fullWidth
                  label="RIF"
                  placeholder="Ingresa el RIF de la empresa"
                  size="small"
                />
                <TextField
                  fullWidth
                  label="Teléfono"
                  placeholder="+58..."
                  size="small"
                />
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Dirección"
                  placeholder="Dirección de la empresa"
                  size="small"
                />
                <Button variant="contained" color="primary">
                  Guardar Cambios
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Parámetros del Sistema */}
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardHeader title="Parámetros del Sistema" />
            <CardContent>
              <Stack spacing={2}>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Habilitar nuevas facturas"
                />
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Permitir descuentos"
                />
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Requerir autorización para compras mayores a $1000"
                />
                <FormControlLabel
                  control={<Switch />}
                  label="Modo mantenimiento"
                />
                <Button variant="contained" color="primary">
                  Guardar Parámetros
                </Button>
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
