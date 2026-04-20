"use client";

import { useState } from "react";
import {
  Box, Typography, Paper, TextField, Button, Stepper, Step, StepLabel,
  Grid2 as Grid, Alert, MenuItem, IconButton, Divider, CircularProgress, Chip,
} from "@mui/material";
import AddCircleIcon from "@mui/icons-material/AddCircle";
import DeleteIcon from "@mui/icons-material/Delete";
import { useCreateShipment, useShippingQuote, useShippingAddresses } from "../hooks/useShipping";

interface Props {
  onNavigate: (path: string) => void;
}

const steps = ["Origen", "Destino", "Paquetes", "Cotizar", "Confirmar"];

const defaultPkg = { weight: 1, weightUnit: "kg", length: 30, width: 20, height: 15, dimensionUnit: "cm", contentDescription: "", declaredValue: 0 };

export default function CreateShipment({ onNavigate }: Props) {
  const [step, setStep] = useState(0);
  const [error, setError] = useState("");
  const [origin, setOrigin] = useState({ contactName: "", phone: "", address: "", city: "", state: "", postalCode: "", countryCode: "VE" });
  const [destination, setDestination] = useState({ contactName: "", phone: "", address: "", city: "", state: "", postalCode: "", countryCode: "VE" });
  const [packages, setPackages] = useState([{ ...defaultPkg }]);
  const [selectedRate, setSelectedRate] = useState<any>(null);
  const [description, setDescription] = useState("");

  const quoteMutation = useShippingQuote();
  const createMutation = useCreateShipment();
  const { data: addresses } = useShippingAddresses();

  const handleQuote = async () => {
    setError("");
    try {
      const result = await quoteMutation.mutateAsync({
        originCity: origin.city, originState: origin.state, originPostalCode: origin.postalCode, originCountryCode: origin.countryCode,
        destCity: destination.city, destState: destination.state, destPostalCode: destination.postalCode, destCountryCode: destination.countryCode,
        packages: packages.map((p) => ({
          weight: Number(p.weight), weightUnit: p.weightUnit,
          length: Number(p.length), width: Number(p.width), height: Number(p.height),
          dimensionUnit: p.dimensionUnit, declaredValue: Number(p.declaredValue) || 0,
        })),
      });
      if (result.rates?.length > 0) setSelectedRate(result.rates[0]);
      setStep(3);
    } catch (err: any) {
      setError(err.message || "Error al cotizar");
    }
  };

  const handleCreate = async () => {
    setError("");
    try {
      const result = await createMutation.mutateAsync({
        carrierCode: selectedRate?.carrierCode || null,
        serviceType: selectedRate?.serviceType || "STANDARD",
        origin, destination, packages, description,
        declaredValue: packages.reduce((sum, p) => sum + (Number(p.declaredValue) || 0), 0),
      });
      if (result.ok) {
        onNavigate(`/envios/${result.shipmentId}`);
      } else {
        setError(result.error || "Error al crear");
      }
    } catch (err: any) {
      setError(err.message || "Error al crear");
    }
  };

  const fillFromAddress = (addr: any, target: "origin" | "destination") => {
    const data = {
      contactName: addr.ContactName || "", phone: addr.Phone || "",
      address: [addr.AddressLine1, addr.AddressLine2].filter(Boolean).join(", "),
      city: addr.City || "", state: addr.State || "",
      postalCode: addr.PostalCode || "", countryCode: addr.CountryCode || "VE",
    };
    target === "origin" ? setOrigin(data) : setDestination(data);
  };

  const updatePkg = (i: number, field: string, value: any) => {
    setPackages((prev) => prev.map((p, idx) => idx === i ? { ...p, [field]: value } : p));
  };

  const addPkg = () => setPackages((prev) => [...prev, { ...defaultPkg }]);
  const removePkg = (i: number) => setPackages((prev) => prev.filter((_, idx) => idx !== i));

  const AddressForm = ({ data, setData, label }: { data: any; setData: (v: any) => void; label: string }) => (
    <Box>
      <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>{label}</Typography>
      {(addresses as any[])?.length > 0 && (
        <Box sx={{ mb: 2, display: "flex", gap: 1, flexWrap: "wrap" }}>
          <Typography variant="caption" color="text.secondary" sx={{ width: "100%" }}>Usar dirección guardada:</Typography>
          {(addresses as any[]).map((a: any) => (
            <Chip key={a.ShippingAddressId} label={`${a.Label} - ${a.City}`} size="small"
              onClick={() => fillFromAddress(a, label === "Origen" ? "origin" : "destination")}
              sx={{ cursor: "pointer" }} variant="outlined" />
          ))}
        </Box>
      )}
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6 }}><TextField label="Nombre contacto" required fullWidth value={data.contactName} onChange={(e) => setData({ ...data, contactName: e.target.value })} /></Grid>
        <Grid size={{ xs: 12, sm: 6 }}><TextField label="Teléfono" fullWidth value={data.phone} onChange={(e) => setData({ ...data, phone: e.target.value })} /></Grid>
        <Grid size={{ xs: 12 }}><TextField label="Dirección" required fullWidth value={data.address} onChange={(e) => setData({ ...data, address: e.target.value })} /></Grid>
        <Grid size={{ xs: 12, sm: 4 }}><TextField label="Ciudad" required fullWidth value={data.city} onChange={(e) => setData({ ...data, city: e.target.value })} /></Grid>
        <Grid size={{ xs: 12, sm: 4 }}><TextField label="Estado/Provincia" fullWidth value={data.state} onChange={(e) => setData({ ...data, state: e.target.value })} /></Grid>
        <Grid size={{ xs: 6, sm: 2 }}><TextField label="C.P." fullWidth value={data.postalCode} onChange={(e) => setData({ ...data, postalCode: e.target.value })} /></Grid>
        <Grid size={{ xs: 6, sm: 2 }}>
          <TextField label="País" select fullWidth value={data.countryCode} onChange={(e) => setData({ ...data, countryCode: e.target.value })}>
            {["VE","CO","ES","MX","US","PA","DO","EC","CL","PT"].map((c) => <MenuItem key={c} value={c}>{c}</MenuItem>)}
          </TextField>
        </Grid>
      </Grid>
    </Box>
  );

  return (
    <Box sx={{ maxWidth: 900, mx: "auto" }}>
      <Stepper activeStep={step} sx={{ mb: 4 }}>
        {steps.map((s) => <Step key={s}><StepLabel>{s}</StepLabel></Step>)}
      </Stepper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper sx={{ p: 3, borderRadius: 2 }}>
        {/* Step 0: Origin */}
        {step === 0 && (
          <>
            <AddressForm data={origin} setData={setOrigin} label="Origen" />
            <Box sx={{ mt: 3, textAlign: "right" }}>
              <Button variant="contained" onClick={() => setStep(1)} disabled={!origin.contactName || !origin.address || !origin.city}>
                Siguiente
              </Button>
            </Box>
          </>
        )}

        {/* Step 1: Destination */}
        {step === 1 && (
          <>
            <AddressForm data={destination} setData={setDestination} label="Destino" />
            <Box sx={{ mt: 3, display: "flex", justifyContent: "space-between" }}>
              <Button onClick={() => setStep(0)}>Atrás</Button>
              <Button variant="contained" onClick={() => setStep(2)} disabled={!destination.contactName || !destination.address || !destination.city}>
                Siguiente
              </Button>
            </Box>
          </>
        )}

        {/* Step 2: Packages */}
        {step === 2 && (
          <>
            <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>Paquetes</Typography>
            {packages.map((pkg, i) => (
              <Box key={i} sx={{ mb: 2 }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 1 }}>
                  <Typography variant="subtitle2" fontWeight={600}>Paquete {i + 1}</Typography>
                  {packages.length > 1 && (
                    <IconButton size="small" color="error" onClick={() => removePkg(i)}><DeleteIcon /></IconButton>
                  )}
                </Box>
                <Grid container spacing={2}>
                  <Grid size={{ xs: 4, sm: 2 }}><TextField label="Peso" type="number" fullWidth size="small" value={pkg.weight} onChange={(e) => updatePkg(i, "weight", e.target.value)} /></Grid>
                  <Grid size={{ xs: 4, sm: 2 }}><TextField label="Largo" type="number" fullWidth size="small" value={pkg.length} onChange={(e) => updatePkg(i, "length", e.target.value)} /></Grid>
                  <Grid size={{ xs: 4, sm: 2 }}><TextField label="Ancho" type="number" fullWidth size="small" value={pkg.width} onChange={(e) => updatePkg(i, "width", e.target.value)} /></Grid>
                  <Grid size={{ xs: 4, sm: 2 }}><TextField label="Alto" type="number" fullWidth size="small" value={pkg.height} onChange={(e) => updatePkg(i, "height", e.target.value)} /></Grid>
                  <Grid size={{ xs: 4, sm: 2 }}><TextField label="Valor $" type="number" fullWidth size="small" value={pkg.declaredValue} onChange={(e) => updatePkg(i, "declaredValue", e.target.value)} /></Grid>
                  <Grid size={{ xs: 12, sm: 2 }}><TextField label="Contenido" fullWidth size="small" value={pkg.contentDescription} onChange={(e) => updatePkg(i, "contentDescription", e.target.value)} /></Grid>
                </Grid>
                {i < packages.length - 1 && <Divider sx={{ mt: 2 }} />}
              </Box>
            ))}
            <Button startIcon={<AddCircleIcon />} onClick={addPkg} sx={{ mb: 2 }}>Agregar paquete</Button>
            <TextField label="Descripción general del envío" fullWidth multiline rows={2} value={description} onChange={(e) => setDescription(e.target.value)} sx={{ mb: 2 }} />
            <Box sx={{ display: "flex", justifyContent: "space-between" }}>
              <Button onClick={() => setStep(1)}>Atrás</Button>
              <Button variant="contained" onClick={handleQuote} disabled={quoteMutation.isPending}>
                {quoteMutation.isPending ? <CircularProgress size={20} /> : "Cotizar"}
              </Button>
            </Box>
          </>
        )}

        {/* Step 3: Rates */}
        {step === 3 && (
          <>
            <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>Cotizaciones</Typography>
            {(quoteMutation.data?.rates || []).length === 0 ? (
              <Alert severity="info">No hay cotizaciones disponibles. Se creará como envío manual.</Alert>
            ) : (
              (quoteMutation.data?.rates || []).map((rate: any, i: number) => (
                <Paper
                  key={i}
                  variant={selectedRate === rate ? "elevation" : "outlined"}
                  onClick={() => setSelectedRate(rate)}
                  sx={{
                    p: 2, mb: 1.5, cursor: "pointer", borderRadius: 2,
                    border: selectedRate === rate ? "2px solid #1565c0" : undefined,
                    bgcolor: selectedRate === rate ? "#e3f2fd" : undefined,
                    "&:hover": { bgcolor: "#f5f8ff" },
                  }}
                >
                  <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <Box>
                      <Typography variant="subtitle1" fontWeight={700}>{rate.carrierName}</Typography>
                      <Typography variant="body2" color="text.secondary">{rate.serviceName}</Typography>
                      {rate.estimatedDays && (
                        <Typography variant="caption" color="text.secondary">
                          Entrega estimada: {rate.estimatedDays} días
                        </Typography>
                      )}
                    </Box>
                    <Typography variant="h5" fontWeight={800} color="primary">
                      ${rate.price.toFixed(2)} <Typography component="span" variant="caption">{rate.currency}</Typography>
                    </Typography>
                  </Box>
                </Paper>
              ))
            )}
            <Box sx={{ mt: 3, display: "flex", justifyContent: "space-between" }}>
              <Button onClick={() => setStep(2)}>Atrás</Button>
              <Button variant="contained" onClick={() => setStep(4)}>Continuar</Button>
            </Box>
          </>
        )}

        {/* Step 4: Confirm */}
        {step === 4 && (
          <>
            <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>Confirmar Envío</Typography>
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Paper variant="outlined" sx={{ p: 2 }}>
                  <Typography variant="subtitle2" fontWeight={700} color="primary">Origen</Typography>
                  <Typography variant="body2">{origin.contactName}</Typography>
                  <Typography variant="caption" color="text.secondary">{origin.address}, {origin.city}, {origin.countryCode}</Typography>
                </Paper>
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Paper variant="outlined" sx={{ p: 2 }}>
                  <Typography variant="subtitle2" fontWeight={700} color="primary">Destino</Typography>
                  <Typography variant="body2">{destination.contactName}</Typography>
                  <Typography variant="caption" color="text.secondary">{destination.address}, {destination.city}, {destination.countryCode}</Typography>
                </Paper>
              </Grid>
            </Grid>
            <Typography variant="body2" sx={{ mb: 1 }}><strong>Paquetes:</strong> {packages.length} — Peso total: {packages.reduce((s, p) => s + Number(p.weight), 0)} kg</Typography>
            {selectedRate && (
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Carrier:</strong> {selectedRate.carrierName} — {selectedRate.serviceName} — <strong>${selectedRate.price.toFixed(2)}</strong></Typography>
            )}
            {origin.countryCode !== destination.countryCode && (
              <Alert severity="info" sx={{ mb: 2 }}>Envío internacional — se requerirá declaración aduanera</Alert>
            )}
            <Box sx={{ mt: 3, display: "flex", justifyContent: "space-between" }}>
              <Button onClick={() => setStep(3)}>Atrás</Button>
              <Button variant="contained" size="large" onClick={handleCreate} disabled={createMutation.isPending}
                sx={{ bgcolor: "#1565c0", px: 5 }}>
                {createMutation.isPending ? <CircularProgress size={20} /> : "Crear Envío"}
              </Button>
            </Box>
          </>
        )}
      </Paper>
    </Box>
  );
}
