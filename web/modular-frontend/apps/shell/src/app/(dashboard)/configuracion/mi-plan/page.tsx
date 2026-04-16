'use client';

import React from 'react';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  LinearProgress,
  Stack,
  Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';

import { useAuth } from '@zentto/shared-auth';
import { useLicenseLimits, useMySubscription, useMyEntitlements } from '@zentto/shared-api';

// ─── Mapa de etiquetas de modulos ──────────────────────────────────────────
const MODULE_LABELS: Record<string, string> = {
  dashboard: 'Dashboard',
  facturas: 'Facturas',
  compras: 'Compras',
  clientes: 'Clientes',
  proveedores: 'Proveedores',
  inventario: 'Inventario',
  articulos: 'Articulos',
  pagos: 'Pagos',
  abonos: 'Abonos',
  cxc: 'CxC',
  cxp: 'CxP',
  bancos: 'Bancos',
  contabilidad: 'Contabilidad',
  nomina: 'Nomina',
  pos: 'POS',
  restaurante: 'Restaurante',
  ecommerce: 'E-Commerce',
  auditoria: 'Auditoria',
  logistica: 'Logistica',
  crm: 'CRM',
  shipping: 'Shipping',
  manufactura: 'Manufactura',
  flota: 'Flota',
  configuracion: 'Configuracion',
  usuarios: 'Usuarios',
  reportes: 'Reportes',
};

// ─── Helpers ────────────────────────────────────────────────────────────────

const PLAN_COLORS: Record<string, 'default' | 'info' | 'primary' | 'secondary'> = {
  FREE: 'default',
  STARTER: 'info',
  PRO: 'primary',
  ENTERPRISE: 'secondary',
};

const STATUS_COLORS: Record<string, 'success' | 'warning' | 'error' | 'default'> = {
  active: 'success',
  trialing: 'warning',
  past_due: 'error',
  paused: 'default',
  cancelled: 'default',
  expired: 'default',
};

const STATUS_LABELS: Record<string, string> = {
  active: 'Activa',
  trialing: 'Prueba',
  past_due: 'Pago pendiente',
  paused: 'Pausada',
  cancelled: 'Cancelada',
  expired: 'Expirada',
};

const SOURCE_LABELS: Record<string, string> = {
  trial: 'Prueba gratuita',
  paddle: 'Paddle',
  manual: 'Manual',
};

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('es', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

function usagePercent(current: number, max: number): number {
  if (max === -1) return 0;
  return Math.min((current / max) * 100, 100);
}

// ─── Page ───────────────────────────────────────────────────────────────────

export default function MiPlanPage() {
  const { isAdmin } = useAuth();
  const { data: licenseLimits, isLoading: loadingLimits } = useLicenseLimits();
  const { data: subData, isLoading: loadingSub } = useMySubscription();
  const { data: entData, isLoading: loadingEnt } = useMyEntitlements();

  const isLoading = loadingLimits || loadingSub || loadingEnt;

  // ── Guards ──────────────────────────────────────────────────────────────
  if (!isAdmin) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="warning">
          Solo administradores pueden ver esta seccion.
        </Alert>
      </Box>
    );
  }

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
        <CircularProgress />
      </Box>
    );
  }

  const subscription = subData?.subscription ?? null;
  const entitlements = entData?.entitlements ?? null;
  const plan = licenseLimits?.plan ?? 'FREE';
  const status = subscription?.Status ?? 'active';

  // ── Render ──────────────────────────────────────────────────────────────
  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1000, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} gutterBottom>
        Mi Plan
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>
        Consulta tu suscripcion actual, uso de recursos y modulos habilitados.
      </Typography>

      {/* ── Section 1: Plan Overview ──────────────────────────────────── */}
      <Card variant="outlined" sx={{ mb: 3 }}>
        <CardContent>
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            justifyContent="space-between"
            alignItems={{ sm: 'center' }}
            spacing={2}
          >
            <Box>
              <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1 }}>
                <Typography variant="h6" fontWeight={700}>
                  Plan
                </Typography>
                <Chip
                  label={plan}
                  color={PLAN_COLORS[plan] ?? 'default'}
                  sx={{ fontWeight: 700, fontSize: '0.9rem' }}
                />
                <Chip
                  label={STATUS_LABELS[status] ?? status}
                  color={STATUS_COLORS[status] ?? 'default'}
                  variant="outlined"
                  size="small"
                />
              </Stack>

              {subscription ? (
                <Stack spacing={0.5}>
                  {subscription.Status === 'trialing' && subscription.TrialEndsAt && (
                    <Alert severity="info" sx={{ py: 0 }}>
                      Tu prueba expira el {fmtDate(subscription.TrialEndsAt)}
                    </Alert>
                  )}
                  {subscription.CancelledAt && (
                    <Typography variant="body2" color="error">
                      Cancelada el {fmtDate(subscription.CancelledAt)}
                    </Typography>
                  )}
                  {subscription.CurrentPeriodStart && subscription.CurrentPeriodEnd && (
                    <Typography variant="body2" color="text.secondary">
                      Periodo: {fmtDate(subscription.CurrentPeriodStart)} — {fmtDate(subscription.CurrentPeriodEnd)}
                    </Typography>
                  )}
                </Stack>
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No hay suscripcion activa.
                </Typography>
              )}
            </Box>

            <Button
              variant="contained"
              endIcon={<OpenInNewIcon />}
              href="https://zentto.net/pricing"
              target="_blank"
              rel="noopener"
              sx={{ whiteSpace: 'nowrap', flexShrink: 0 }}
            >
              Cambiar plan
            </Button>
          </Stack>
        </CardContent>
      </Card>

      {/* ── Section 2: Usage ──────────────────────────────────────────── */}
      {licenseLimits && (
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' },
            gap: 3,
            mb: 3,
          }}
        >
          {/* Usuarios */}
          <Card variant="outlined">
            <CardContent>
              <Stack direction="row" justifyContent="space-between" sx={{ mb: 1 }}>
                <Typography variant="subtitle2" fontWeight={600}>
                  Usuarios
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {licenseLimits.currentUsers} / {licenseLimits.maxUsers === -1 ? 'Ilimitados' : licenseLimits.maxUsers}
                </Typography>
              </Stack>
              <LinearProgress
                variant="determinate"
                value={usagePercent(licenseLimits.currentUsers, licenseLimits.maxUsers)}
                sx={{ height: 10, borderRadius: 5 }}
                color={
                  licenseLimits.maxUsers !== -1 &&
                  usagePercent(licenseLimits.currentUsers, licenseLimits.maxUsers) > 80
                    ? 'error'
                    : 'primary'
                }
              />
            </CardContent>
          </Card>

          {/* Empresas */}
          <Card variant="outlined">
            <CardContent>
              <Stack direction="row" justifyContent="space-between" sx={{ mb: 1 }}>
                <Typography variant="subtitle2" fontWeight={600}>
                  Empresas
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {licenseLimits.currentCompanies} / {licenseLimits.maxCompanies === -1 ? 'Ilimitadas' : licenseLimits.maxCompanies}
                </Typography>
              </Stack>
              <LinearProgress
                variant="determinate"
                value={usagePercent(licenseLimits.currentCompanies, licenseLimits.maxCompanies)}
                sx={{ height: 10, borderRadius: 5 }}
                color={
                  licenseLimits.maxCompanies !== -1 &&
                  usagePercent(licenseLimits.currentCompanies, licenseLimits.maxCompanies) > 80
                    ? 'error'
                    : 'primary'
                }
              />
              <Stack direction="row" alignItems="center" spacing={1} sx={{ mt: 2 }}>
                <Typography variant="body2" fontWeight={600}>
                  Multi-empresa:
                </Typography>
                <Chip
                  label={licenseLimits.multiCompany ? 'Habilitado' : 'No disponible'}
                  size="small"
                  color={licenseLimits.multiCompany ? 'success' : 'default'}
                  variant="outlined"
                />
              </Stack>
            </CardContent>
          </Card>
        </Box>
      )}

      {/* ── Section 3: Modulos Activos ─────────────────────────────────── */}
      <Card variant="outlined" sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 2 }}>
            Modulos Activos
          </Typography>

          {entitlements && !entitlements.IsActive && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              Los entitlements de tu suscripcion no estan activos. Contacta soporte.
            </Alert>
          )}

          {entitlements && entitlements.ModuleCodes.length > 0 ? (
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
              {entitlements.ModuleCodes.map((code) => (
                <Chip
                  key={code}
                  label={MODULE_LABELS[code] ?? code}
                  color="primary"
                  variant="outlined"
                />
              ))}
            </Box>
          ) : (
            <Typography variant="body2" color="text.secondary">
              No hay modulos asignados a tu plan actual.
            </Typography>
          )}
        </CardContent>
      </Card>

      {/* ── Section 4: Detalles de Suscripcion (Accordion) ────────────── */}
      {subscription && (
        <Accordion variant="outlined" defaultExpanded={false}>
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Typography variant="subtitle1" fontWeight={700}>
              Detalles de Suscripcion
            </Typography>
          </AccordionSummary>
          <AccordionDetails>
            <Stack spacing={1.5}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  Origen
                </Typography>
                <Typography variant="body1">
                  {SOURCE_LABELS[subscription.Source] ?? subscription.Source}
                </Typography>
              </Box>

              {subscription.PaddleSubscriptionId && (
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Paddle Subscription ID
                  </Typography>
                  <Typography variant="body1" sx={{ fontFamily: 'monospace' }}>
                    {subscription.PaddleSubscriptionId}
                  </Typography>
                </Box>
              )}

              {subscription.PaddleCustomerId && (
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    Paddle Customer ID
                  </Typography>
                  <Typography variant="body1" sx={{ fontFamily: 'monospace' }}>
                    {subscription.PaddleCustomerId}
                  </Typography>
                </Box>
              )}

              <Box>
                <Typography variant="body2" color="text.secondary">
                  Periodo
                </Typography>
                <Typography variant="body1">
                  {fmtDate(subscription.CurrentPeriodStart)} — {fmtDate(subscription.CurrentPeriodEnd)}
                </Typography>
              </Box>

              {subscription.ItemsJson && subscription.ItemsJson.length > 0 && (
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                    Items de suscripcion
                  </Typography>
                  <Stack spacing={1}>
                    {subscription.ItemsJson.map((item) => (
                      <Card key={item.SubscriptionItemId} variant="outlined" sx={{ p: 1.5 }}>
                        <Stack
                          direction={{ xs: 'column', sm: 'row' }}
                          justifyContent="space-between"
                          alignItems={{ sm: 'center' }}
                          spacing={1}
                        >
                          <Box>
                            <Typography variant="body2" fontWeight={600}>
                              {item.PlanName}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {item.ProductCode} {item.IsAddon ? '(Add-on)' : ''} — {item.BillingCycle}
                            </Typography>
                          </Box>
                          <Typography variant="body2" fontWeight={600}>
                            ${item.UnitPrice} x {item.Quantity}
                          </Typography>
                        </Stack>
                      </Card>
                    ))}
                  </Stack>
                </Box>
              )}
            </Stack>
          </AccordionDetails>
        </Accordion>
      )}
    </Box>
  );
}
