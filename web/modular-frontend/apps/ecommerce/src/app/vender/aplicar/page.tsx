'use client';

import { useState, useEffect } from 'react';
import {
  Box, Container, Typography, Card, CardContent, Stepper, Step, StepLabel,
  TextField, Button, Grid, MenuItem, Alert, Stack, Divider,
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { useApplySeller, useCartStore } from '@zentto/module-ecommerce';

const steps = ['Datos de la empresa', 'Documentos', 'Método de pago', 'Confirmar'];

export default function VenderAplicarPage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const customerInfo = useCartStore((s) => s.customerInfo);
  const apply = useApplySeller();

  const [step, setStep] = useState(0);
  const [legalName, setLegalName] = useState('');
  const [taxId, setTaxId] = useState('');
  const [storeSlug, setStoreSlug] = useState('');
  const [description, setDescription] = useState('');
  const [contactEmail, setContactEmail] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [logoUrl, setLogoUrl] = useState('');
  const [payoutMethod, setPayoutMethod] = useState('bank_transfer');
  const [paypalEmail, setPaypalEmail] = useState('');
  const [bankName, setBankName] = useState('');
  const [bankAccount, setBankAccount] = useState('');

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (!customerToken) router.replace('/login?next=/vender/aplicar');
    else if (customerInfo?.email && !contactEmail) setContactEmail(customerInfo.email);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [customerToken]);

  const canNext = () => {
    if (step === 0) return legalName.trim().length >= 2;
    if (step === 1) return true; // documentos opcionales en MVP
    if (step === 2) {
      if (payoutMethod === 'paypal') return paypalEmail.trim().length > 3;
      if (payoutMethod === 'bank_transfer') return bankName.trim().length > 1 && bankAccount.trim().length > 3;
      return true;
    }
    return true;
  };

  const handleSubmit = async () => {
    setError('');
    setSuccess('');

    const payoutDetails: Record<string, unknown> = {};
    if (payoutMethod === 'paypal') payoutDetails.paypalEmail = paypalEmail.trim();
    if (payoutMethod === 'bank_transfer') {
      payoutDetails.bankName = bankName.trim();
      payoutDetails.bankAccount = bankAccount.trim();
    }

    try {
      const res = await apply.mutateAsync({
        legalName: legalName.trim(),
        taxId: taxId.trim() || undefined,
        storeSlug: storeSlug.trim() || undefined,
        description: description.trim() || undefined,
        logoUrl: logoUrl.trim() || undefined,
        contactEmail: contactEmail.trim() || undefined,
        contactPhone: contactPhone.trim() || undefined,
        payoutMethod,
        payoutDetails,
      });
      if (!(res as { ok?: boolean }).ok) {
        setError((res as { error?: string }).error || 'No se pudo registrar tu solicitud');
        return;
      }
      setSuccess((res as { message?: string }).message || 'Solicitud enviada');
      setTimeout(() => router.push('/vender/dashboard'), 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  };

  if (!customerToken) return null;

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh', py: { xs: 3, md: 6 } }}>
      <Container maxWidth="md">
        <Typography variant="h4" sx={{ fontWeight: 700, color: '#131921', mb: 1 }}>
          Solicitud de vendedor
        </Typography>
        <Typography variant="body1" sx={{ color: '#555', mb: 3 }}>
          Completa los 4 pasos. Aprobamos tu tienda en 24-48h.
        </Typography>

        <Card sx={{ borderRadius: 3 }}>
          <CardContent sx={{ p: { xs: 2, md: 4 } }}>
            <Stepper activeStep={step} alternativeLabel sx={{ mb: 4 }}>
              {steps.map((label) => (
                <Step key={label}><StepLabel>{label}</StepLabel></Step>
              ))}
            </Stepper>

            {step === 0 && (
              <Stack spacing={2}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>Datos de la empresa</Typography>
                <TextField
                  label="Razón social / Nombre legal *"
                  value={legalName} onChange={(e) => setLegalName(e.target.value)} fullWidth
                  inputProps={{ maxLength: 200 }}
                />
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <TextField label="Tax ID / RIF" value={taxId} onChange={(e) => setTaxId(e.target.value)} fullWidth />
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <TextField
                      label="Slug de la tienda (opcional)"
                      value={storeSlug}
                      onChange={(e) => setStoreSlug(e.target.value)}
                      helperText="Ej. mi-tienda-verde → https://zentto.net/s/mi-tienda-verde"
                      fullWidth
                    />
                  </Grid>
                </Grid>
                <TextField
                  label="Descripción de la tienda"
                  value={description} onChange={(e) => setDescription(e.target.value)}
                  fullWidth multiline rows={3} inputProps={{ maxLength: 2000 }}
                />
              </Stack>
            )}

            {step === 1 && (
              <Stack spacing={2}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>Documentos y contacto</Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <TextField label="Email de contacto" type="email" value={contactEmail} onChange={(e) => setContactEmail(e.target.value)} fullWidth />
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <TextField label="Teléfono" value={contactPhone} onChange={(e) => setContactPhone(e.target.value)} fullWidth />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      label="URL del logo"
                      value={logoUrl} onChange={(e) => setLogoUrl(e.target.value)} fullWidth
                      helperText="URL pública (p. ej. Imgur o tu CDN)"
                    />
                  </Grid>
                </Grid>
              </Stack>
            )}

            {step === 2 && (
              <Stack spacing={2}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>Método de pago</Typography>
                <TextField select label="Método" value={payoutMethod} onChange={(e) => setPayoutMethod(e.target.value)} fullWidth>
                  <MenuItem value="bank_transfer">Transferencia bancaria</MenuItem>
                  <MenuItem value="paypal">PayPal</MenuItem>
                  <MenuItem value="store_credit">Crédito en tienda</MenuItem>
                </TextField>
                {payoutMethod === 'paypal' && (
                  <TextField label="Email de PayPal" type="email" value={paypalEmail} onChange={(e) => setPaypalEmail(e.target.value)} fullWidth />
                )}
                {payoutMethod === 'bank_transfer' && (
                  <>
                    <TextField label="Banco" value={bankName} onChange={(e) => setBankName(e.target.value)} fullWidth />
                    <TextField label="Número de cuenta / IBAN" value={bankAccount} onChange={(e) => setBankAccount(e.target.value)} fullWidth />
                  </>
                )}
              </Stack>
            )}

            {step === 3 && (
              <Stack spacing={1.5}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>Confirmar</Typography>
                <Divider />
                <Typography variant="body2"><b>Razón social:</b> {legalName}</Typography>
                <Typography variant="body2"><b>Tax ID:</b> {taxId || '—'}</Typography>
                <Typography variant="body2"><b>Slug:</b> {storeSlug || '(autogenerado)'}</Typography>
                <Typography variant="body2"><b>Email:</b> {contactEmail || '—'}</Typography>
                <Typography variant="body2"><b>Método de pago:</b> {payoutMethod}</Typography>
                <Typography variant="body2"><b>Comisión de la plataforma:</b> 15%</Typography>
              </Stack>
            )}

            {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ mt: 2 }}>{success}</Alert>}

            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 4 }}>
              <Button onClick={() => (step === 0 ? router.push('/vende') : setStep(step - 1))}>
                {step === 0 ? 'Cancelar' : 'Atrás'}
              </Button>
              {step < steps.length - 1 ? (
                <Button
                  variant="contained" disabled={!canNext()} onClick={() => setStep(step + 1)}
                  sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
                >
                  Continuar
                </Button>
              ) : (
                <Button
                  variant="contained"
                  disabled={apply.isPending || !canNext()}
                  onClick={handleSubmit}
                  sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700, '&:hover': { bgcolor: '#e68a00' } }}
                >
                  {apply.isPending ? 'Enviando…' : 'Enviar solicitud'}
                </Button>
              )}
            </Box>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
}
