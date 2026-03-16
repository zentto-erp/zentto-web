"use client";

import { useState } from "react";
import { Box, TextField, Button, Checkbox, FormControlLabel, CircularProgress } from "@mui/material";
import Grid from "@mui/material/Grid2";
import type { AddressFormData } from "../hooks/useStoreAccount";

interface Props {
  initial?: Partial<AddressFormData>;
  onSave: (data: AddressFormData) => Promise<void>;
  onCancel: () => void;
  saving?: boolean;
}

export default function AddressForm({ initial, onSave, onCancel, saving }: Props) {
  const [label, setLabel] = useState(initial?.label ?? "");
  const [recipientName, setRecipientName] = useState(initial?.recipientName ?? "");
  const [phone, setPhone] = useState(initial?.phone ?? "");
  const [addressLine, setAddressLine] = useState(initial?.addressLine ?? "");
  const [city, setCity] = useState(initial?.city ?? "");
  const [state, setState] = useState(initial?.state ?? "");
  const [zipCode, setZipCode] = useState(initial?.zipCode ?? "");
  const [country, setCountry] = useState(initial?.country ?? "Venezuela");
  const [instructions, setInstructions] = useState(initial?.instructions ?? "");
  const [isDefault, setIsDefault] = useState(initial?.isDefault ?? false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSave({
      label: label.trim(),
      recipientName: recipientName.trim(),
      phone: phone.trim() || undefined,
      addressLine: addressLine.trim(),
      city: city.trim() || undefined,
      state: state.trim() || undefined,
      zipCode: zipCode.trim() || undefined,
      country: country.trim() || undefined,
      instructions: instructions.trim() || undefined,
      isDefault,
    });
  };

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ p: 2, border: "1px dashed #ccc", borderRadius: 2, bgcolor: "#fafafa" }}>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Etiqueta" placeholder='Ej: Casa, Oficina' value={label} onChange={(e) => setLabel(e.target.value)} fullWidth size="small" required />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Nombre del receptor" value={recipientName} onChange={(e) => setRecipientName(e.target.value)} fullWidth size="small" required />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Telefono" value={phone} onChange={(e) => setPhone(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 12 }}>
          <TextField label="Direccion completa" value={addressLine} onChange={(e) => setAddressLine(e.target.value)} fullWidth size="small" multiline rows={2} required />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Ciudad" value={city} onChange={(e) => setCity(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField label="Estado" value={state} onChange={(e) => setState(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 6, sm: 2 }}>
          <TextField label="Cod. postal" value={zipCode} onChange={(e) => setZipCode(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 6, sm: 2 }}>
          <TextField label="Pais" value={country} onChange={(e) => setCountry(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 12 }}>
          <TextField label="Instrucciones de entrega" placeholder="Ej: Porton azul, 2do piso" value={instructions} onChange={(e) => setInstructions(e.target.value)} fullWidth size="small" />
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <FormControlLabel
              control={<Checkbox checked={isDefault} onChange={(e) => setIsDefault(e.target.checked)} size="small" />}
              label="Establecer como predeterminada"
            />
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button variant="outlined" size="small" onClick={onCancel} disabled={saving}>Cancelar</Button>
              <Button type="submit" variant="contained" size="small" disabled={saving || !label.trim() || !recipientName.trim() || !addressLine.trim()}>
                {saving ? <CircularProgress size={18} /> : "Guardar"}
              </Button>
            </Box>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
}
