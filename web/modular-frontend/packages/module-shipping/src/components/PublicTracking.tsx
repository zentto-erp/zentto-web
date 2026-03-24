"use client";

import { useState, useCallback } from "react";
import {
  Box, Typography, Paper, TextField, Button, InputAdornment,
  CircularProgress, Alert, Stepper, Step, StepLabel, StepContent, Chip,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import { usePublicTracking } from "../hooks/useShipping";
import { StatusChip } from "./ShippingDashboard";
import { TurnstileCaptcha } from "@zentto/shared-auth";

interface Props {
  initialTracking?: string;
}

export default function PublicTracking({ initialTracking }: Props) {
  const [input, setInput] = useState(initialTracking || "");
  const [trackingNumber, setTrackingNumber] = useState<string | null>(initialTracking || null);
  const [captchaToken, setCaptchaToken] = useState<string | null>(null);
  const [captchaKey, setCaptchaKey] = useState(0); // fuerza re-render del widget tras cada búsqueda
  const handleCaptchaToken = useCallback((token: string) => setCaptchaToken(token || null), []);
  const { data, isLoading, error } = usePublicTracking(trackingNumber, captchaToken);

  const handleSearch = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!input.trim()) return;
    setTrackingNumber(input.trim());
    // Resetea el widget después de cada búsqueda (el token es de un solo uso)
    setCaptchaKey((k) => k + 1);
    setCaptchaToken(null);
  };

  return (
    <Box sx={{ maxWidth: 700, mx: "auto" }}>
      <Box sx={{ textAlign: "center", mb: 4 }}>
        <LocalShippingIcon sx={{ fontSize: 48, color: "#1565c0", mb: 1 }} />
        <Typography variant="h4" fontWeight={700}>Rastrear Envío</Typography>
        <Typography variant="body1" color="text.secondary">Ingresa tu número de guía o número de envío</Typography>
      </Box>

      <Paper sx={{ p: 3, mb: 4, borderRadius: 2 }} component="form" onSubmit={handleSearch}>
        <TextField
          placeholder="Ej: ZS-000001, ZM-A1B2C3..."
          fullWidth
          value={input}
          onChange={(e) => setInput(e.target.value)}
          InputProps={{
            startAdornment: <InputAdornment position="start"><SearchIcon /></InputAdornment>,
          }}
          sx={{ mb: 2 }}
        />
        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 2 }}>
          <TurnstileCaptcha key={captchaKey} onTokenChange={handleCaptchaToken} />
          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={isLoading || !input.trim()}
            sx={{ bgcolor: "#1565c0", minWidth: 120 }}
          >
            {isLoading ? <CircularProgress size={20} color="inherit" /> : "Buscar"}
          </Button>
        </Box>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 3 }}>{(error as Error).message}</Alert>}

      {data?.shipment && (
        <Paper sx={{ p: 3, borderRadius: 2 }}>
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", mb: 3, flexWrap: "wrap", gap: 1 }}>
            <Box>
              <Typography variant="h5" fontWeight={700}>{data.shipment.ShipmentNumber}</Typography>
              {data.shipment.TrackingNumber && data.shipment.TrackingNumber !== data.shipment.ShipmentNumber && (
                <Typography variant="body2" color="text.secondary">Guía: {data.shipment.TrackingNumber}</Typography>
              )}
              <Chip label={data.shipment.CarrierCode || "Manual"} size="small" sx={{ mt: 0.5 }} />
            </Box>
            <StatusChip status={data.shipment.Status} />
          </Box>

          {/* Route */}
          <Box sx={{ display: "flex", gap: 2, mb: 3, flexWrap: "wrap" }}>
            <Paper variant="outlined" sx={{ p: 2, flex: 1, minWidth: 200, borderRadius: 2 }}>
              <Typography variant="caption" fontWeight={700} color="primary">ORIGEN</Typography>
              <Typography variant="body2">{data.shipment.OriginCity}, {data.shipment.OriginCountryCode}</Typography>
            </Paper>
            <Box sx={{ display: "flex", alignItems: "center" }}>
              <Typography sx={{ fontSize: 24 }}>→</Typography>
            </Box>
            <Paper variant="outlined" sx={{ p: 2, flex: 1, minWidth: 200, borderRadius: 2 }}>
              <Typography variant="caption" fontWeight={700} color="error">DESTINO</Typography>
              <Typography variant="body2">{data.shipment.DestCity}, {data.shipment.DestCountryCode}</Typography>
            </Paper>
          </Box>

          {data.shipment.EstimatedDelivery && (
            <Typography variant="body2" sx={{ mb: 2 }}>
              Entrega estimada: <strong>{new Date(data.shipment.EstimatedDelivery).toLocaleDateString("es")}</strong>
            </Typography>
          )}
          {data.shipment.DeliveredToName && (
            <Alert severity="success" sx={{ mb: 2 }}>
              Entregado a: <strong>{data.shipment.DeliveredToName}</strong> el {new Date(data.shipment.ActualDelivery).toLocaleString("es")}
            </Alert>
          )}

          {/* Timeline */}
          <Typography variant="subtitle1" fontWeight={700} sx={{ mt: 3, mb: 2 }}>Historial</Typography>
          {(data.events || []).length === 0 ? (
            <Typography variant="body2" color="text.secondary">Sin eventos registrados</Typography>
          ) : (
            <Stepper orientation="vertical" activeStep={-1}>
              {(data.events || []).map((e: any, i: number) => (
                <Step key={i} active completed={false}>
                  <StepLabel
                    StepIconComponent={() => (
                      <Box sx={{
                        width: 12, height: 12, borderRadius: "50%",
                        bgcolor: i === 0 ? "#1565c0" : "#ccc",
                      }} />
                    )}
                  >
                    <Typography variant="body2" fontWeight={i === 0 ? 700 : 400}>{e.Description}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {new Date(e.EventAt).toLocaleString("es")}
                      {e.City && ` · ${e.City}`}
                      {e.Location && `, ${e.Location}`}
                    </Typography>
                  </StepLabel>
                  <StepContent />
                </Step>
              ))}
            </Stepper>
          )}
        </Paper>
      )}
    </Box>
  );
}
