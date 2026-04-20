'use client';

import { useState, useEffect } from 'react';
import {
  Box, Container, Typography, Card, CardContent, TextField, Button,
  Grid, MenuItem, Alert, CircularProgress, Stack, Divider,
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { useRegisterAffiliate, useCartStore } from '@zentto/module-ecommerce';

export default function AfiliadoRegistroPage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const customerInfo = useCartStore((s) => s.customerInfo);
  const register = useRegisterAffiliate();

  const [legalName, setLegalName] = useState('');
  const [taxId, setTaxId] = useState('');
  const [contactEmail, setContactEmail] = useState('');
  const [payoutMethod, setPayoutMethod] = useState('paypal');
  const [paypalEmail, setPaypalEmail] = useState('');
  const [bankName, setBankName] = useState('');
  const [bankAccount, setBankAccount] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (!customerToken) {
      router.replace('/login?next=/afiliados/registro');
    } else if (customerInfo?.email && !contactEmail) {
      setContactEmail(customerInfo.email);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [customerToken]);

  const handleSubmit = async () => {
    setError('');
    setSuccess('');
    if (legalName.trim().length < 2) {
      setError('Indica tu nombre legal o razón social (mín. 2 caracteres)');
      return;
    }

    const payoutDetails: Record<string, unknown> = {};
    if (payoutMethod === 'paypal') payoutDetails.paypalEmail = paypalEmail.trim();
    if (payoutMethod === 'bank_transfer') {
      payoutDetails.bankName = bankName.trim();
      payoutDetails.bankAccount = bankAccount.trim();
    }

    try {
      const res = await register.mutateAsync({
        legalName: legalName.trim(),
        taxId: taxId.trim() || undefined,
        contactEmail: contactEmail.trim() || undefined,
        payoutMethod,
        payoutDetails,
      });
      if (!(res as { ok?: boolean }).ok) {
        setError((res as { error?: string }).error || 'No se pudo completar el registro');
        return;
      }
      setSuccess((res as { message?: string }).message || 'Aplicación recibida');
      setTimeout(() => router.push('/afiliados/dashboard'), 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  if (!customerToken) {
    return (
      <Box sx={{ minHeight: '60vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh', py: { xs: 3, md: 6 } }}>
      <Container maxWidth="md">
        <Typography variant="h4" sx={{ fontWeight: 700, color: '#131921', mb: 1 }}>
          Aplica al programa de afiliados
        </Typography>
        <Typography variant="body1" sx={{ color: '#555', mb: 3 }}>
          Completa tus datos. Aprobamos las solicitudes en 24-48h.
        </Typography>

        <Card sx={{ borderRadius: 3 }}>
          <CardContent sx={{ p: { xs: 2, md: 4 } }}>
            <Stack spacing={3}>
              <Box>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>Datos fiscales</Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={7}>
                    <TextField
                      fullWidth
                      label="Nombre legal / Razón social *"
                      value={legalName}
                      onChange={(e) => setLegalName(e.target.value)}
                      inputProps={{ maxLength: 200 }}
                    />
                  </Grid>
                  <Grid item xs={12} md={5}>
                    <TextField
                      fullWidth
                      label="Tax ID / RIF / CUIT"
                      value={taxId}
                      onChange={(e) => setTaxId(e.target.value)}
                      inputProps={{ maxLength: 40 }}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Email de contacto"
                      type="email"
                      value={contactEmail}
                      onChange={(e) => setContactEmail(e.target.value)}
                      inputProps={{ maxLength: 200 }}
                    />
                  </Grid>
                </Grid>
              </Box>

              <Divider />

              <Box>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>Método de pago</Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <TextField
                      select fullWidth label="Método"
                      value={payoutMethod}
                      onChange={(e) => setPayoutMethod(e.target.value)}
                    >
                      <MenuItem value="paypal">PayPal</MenuItem>
                      <MenuItem value="bank_transfer">Transferencia bancaria</MenuItem>
                      <MenuItem value="store_credit">Crédito en tienda</MenuItem>
                    </TextField>
                  </Grid>
                  {payoutMethod === 'paypal' && (
                    <Grid item xs={12} md={6}>
                      <TextField
                        fullWidth label="Email de PayPal"
                        type="email"
                        value={paypalEmail}
                        onChange={(e) => setPaypalEmail(e.target.value)}
                      />
                    </Grid>
                  )}
                  {payoutMethod === 'bank_transfer' && (
                    <>
                      <Grid item xs={12} md={6}>
                        <TextField fullWidth label="Banco" value={bankName} onChange={(e) => setBankName(e.target.value)} />
                      </Grid>
                      <Grid item xs={12}>
                        <TextField
                          fullWidth label="Número de cuenta / IBAN"
                          value={bankAccount}
                          onChange={(e) => setBankAccount(e.target.value)}
                        />
                      </Grid>
                    </>
                  )}
                </Grid>
              </Box>

              {error && <Alert severity="error">{error}</Alert>}
              {success && <Alert severity="success">{success}</Alert>}

              <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                <Button variant="outlined" onClick={() => router.push('/afiliados')}>Cancelar</Button>
                <Button
                  variant="contained"
                  onClick={handleSubmit}
                  disabled={register.isPending}
                  sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
                >
                  {register.isPending ? 'Enviando…' : 'Enviar solicitud'}
                </Button>
              </Box>
            </Stack>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
}
