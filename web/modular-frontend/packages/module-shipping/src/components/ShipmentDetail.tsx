"use client";

import {
  Box, Typography, Paper, Grid2 as Grid, Chip, CircularProgress,
  Stepper, Step, StepLabel, StepContent, Button, Divider,
} from "@mui/material";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import DownloadIcon from "@mui/icons-material/Download";
import GavelIcon from "@mui/icons-material/Gavel";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import { useShipmentDetail } from "../hooks/useShipping";
import { StatusChip } from "./ShippingDashboard";

interface Props {
  shipmentId: number;
  onNavigate: (path: string) => void;
}

export default function ShipmentDetail({ shipmentId, onNavigate }: Props) {
  const { data, isLoading } = useShipmentDetail(shipmentId);

  if (isLoading) return <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}><CircularProgress /></Box>;
  if (!data?.shipment) return <Typography color="error">Envío no encontrado</Typography>;

  const s = data.shipment;
  const events = data.events || [];
  const packages = data.packages || [];

  const copyTracking = () => {
    const text = s.TrackingNumber || s.ShipmentNumber;
    navigator.clipboard?.writeText(text);
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Box>
          <Box sx={{ display: "flex", gap: 1, alignItems: "center", mb: 0.5 }}>
            <Typography variant="h5" fontWeight={700}>{s.ShipmentNumber}</Typography>
            <StatusChip status={s.Status} />
            {s.IsInternational && <Chip label="Internacional" size="small" color="secondary" />}
          </Box>
          {s.TrackingNumber && (
            <Box sx={{ display: "flex", gap: 0.5, alignItems: "center" }}>
              <Typography variant="body2" color="text.secondary">Guía: <strong>{s.TrackingNumber}</strong></Typography>
              <IconBtn onClick={copyTracking}><ContentCopyIcon sx={{ fontSize: 14 }} /></IconBtn>
            </Box>
          )}
          {s.CarrierCode && <Chip label={s.CarrierCode} size="small" variant="outlined" sx={{ mt: 0.5 }} />}
        </Box>
        <Box sx={{ display: "flex", gap: 1 }}>
          {s.LabelUrl && (
            <Button variant="outlined" startIcon={<DownloadIcon />} href={s.LabelUrl} target="_blank" size="small">
              Etiqueta
            </Button>
          )}
          {s.IsInternational && (
            <Button variant="outlined" startIcon={<GavelIcon />} onClick={() => onNavigate(`/envios/${shipmentId}/aduanas`)} size="small">
              Aduanas
            </Button>
          )}
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Left: Info */}
        <Grid size={{ xs: 12, md: 7 }}>
          {/* Route */}
          <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
            <Grid container spacing={2}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="subtitle2" fontWeight={700} color="primary" sx={{ mb: 1 }}>Origen</Typography>
                <Typography variant="body2" fontWeight={600}>{s.OriginContactName}</Typography>
                <Typography variant="body2" color="text.secondary">{s.OriginAddress}</Typography>
                <Typography variant="body2" color="text.secondary">{s.OriginCity}, {s.OriginState} {s.OriginPostalCode}</Typography>
                <Chip label={s.OriginCountryCode} size="small" sx={{ mt: 0.5 }} />
                {s.OriginPhone && <Typography variant="caption" color="text.secondary" display="block">{s.OriginPhone}</Typography>}
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="subtitle2" fontWeight={700} color="error" sx={{ mb: 1 }}>Destino</Typography>
                <Typography variant="body2" fontWeight={600}>{s.DestContactName}</Typography>
                <Typography variant="body2" color="text.secondary">{s.DestAddress}</Typography>
                <Typography variant="body2" color="text.secondary">{s.DestCity}, {s.DestState} {s.DestPostalCode}</Typography>
                <Chip label={s.DestCountryCode} size="small" sx={{ mt: 0.5 }} />
                {s.DestPhone && <Typography variant="caption" color="text.secondary" display="block">{s.DestPhone}</Typography>}
              </Grid>
            </Grid>
          </Paper>

          {/* Packages */}
          {packages.length > 0 && (
            <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
              <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 2 }}>
                Paquetes ({packages.length})
              </Typography>
              {packages.map((pkg: any, i: number) => (
                <Box key={i} sx={{ display: "flex", gap: 2, mb: 1, flexWrap: "wrap" }}>
                  <Chip label={`#${pkg.PackageNumber}`} size="small" />
                  <Typography variant="body2">{pkg.Weight} {pkg.WeightUnit}</Typography>
                  {pkg.Length && <Typography variant="body2">{pkg.Length}x{pkg.Width}x{pkg.Height} {pkg.DimensionUnit}</Typography>}
                  {pkg.ContentDescription && <Typography variant="body2" color="text.secondary">{pkg.ContentDescription}</Typography>}
                  {pkg.DeclaredValue > 0 && <Typography variant="body2" fontWeight={600}>${pkg.DeclaredValue}</Typography>}
                </Box>
              ))}
              <Divider sx={{ my: 1 }} />
              <Typography variant="body2" fontWeight={700}>
                Peso total: {s.TotalWeight} kg
                {s.ShippingCost > 0 && ` · Costo: $${s.ShippingCost} ${s.Currency}`}
              </Typography>
            </Paper>
          )}

          {/* Details */}
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Detalles</Typography>
            <InfoRow label="Servicio" value={s.ServiceType} />
            <InfoRow label="Método de pago" value={s.PaymentMethod} />
            {s.Description && <InfoRow label="Descripción" value={s.Description} />}
            {s.Reference && <InfoRow label="Referencia" value={s.Reference} />}
            {s.EstimatedDelivery && <InfoRow label="Entrega estimada" value={new Date(s.EstimatedDelivery).toLocaleDateString("es")} />}
            {s.ActualDelivery && <InfoRow label="Entregado" value={new Date(s.ActualDelivery).toLocaleString("es")} />}
            {s.DeliveredToName && <InfoRow label="Recibido por" value={s.DeliveredToName} />}
            <InfoRow label="Creado" value={new Date(s.CreatedAt).toLocaleString("es")} />
          </Paper>
        </Grid>

        {/* Right: Timeline */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 2 }}>
              <LocalShippingIcon sx={{ fontSize: 18, mr: 0.5, verticalAlign: "text-bottom" }} />
              Timeline de Rastreo
            </Typography>
            {events.length === 0 ? (
              <Typography variant="body2" color="text.secondary">Sin eventos aún</Typography>
            ) : (
              <Stepper orientation="vertical" activeStep={-1}>
                {events.map((e: any, i: number) => (
                  <Step key={i} active completed={false}>
                    <StepLabel
                      StepIconComponent={() => (
                        <Box sx={{
                          width: 12, height: 12, borderRadius: "50%",
                          bgcolor: i === 0 ? "#1565c0" : "#ccc",
                          border: `2px solid ${i === 0 ? "#1565c0" : "#e0e0e0"}`,
                        }} />
                      )}
                    >
                      <Box>
                        <Typography variant="body2" fontWeight={i === 0 ? 700 : 400}>
                          {e.Description}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {new Date(e.EventAt).toLocaleString("es")}
                          {e.City && ` · ${e.City}`}
                          {e.Location && ` · ${e.Location}`}
                        </Typography>
                      </Box>
                    </StepLabel>
                    <StepContent />
                  </Step>
                ))}
              </Stepper>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <Box sx={{ display: "flex", gap: 1, mb: 0.5 }}>
      <Typography variant="body2" color="text.secondary" sx={{ minWidth: 140 }}>{label}:</Typography>
      <Typography variant="body2" fontWeight={500}>{value}</Typography>
    </Box>
  );
}

function IconBtn({ children, onClick }: { children: React.ReactNode; onClick: () => void }) {
  return (
    <Box component="span" onClick={onClick} sx={{ cursor: "pointer", opacity: 0.6, "&:hover": { opacity: 1 } }}>
      {children}
    </Box>
  );
}
