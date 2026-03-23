"use client";

import { useState } from "react";
import { Box, TextField, Button, Checkbox, FormControlLabel, CircularProgress, MenuItem } from "@mui/material";
import { FormGrid, FormField } from "@zentto/shared-ui";
import type { AddressFormData } from "../hooks/useStoreAccount";

const COUNTRIES = [
  { code: "VE", name: "Venezuela" },
  { code: "ES", name: "España" },
  { code: "CO", name: "Colombia" },
  { code: "MX", name: "México" },
  { code: "US", name: "Estados Unidos" },
];

const STATES: Record<string, string[]> = {
  VE: ["Distrito Capital", "Miranda", "Zulia", "Carabobo", "Aragua", "Lara", "Bolívar", "Anzoátegui", "Táchira", "Mérida"],
  ES: ["Madrid", "Barcelona", "Valencia", "Sevilla", "Málaga", "Bilbao"],
  CO: ["Bogotá D.C.", "Antioquia", "Valle del Cauca", "Atlántico", "Santander"],
  MX: ["CDMX", "Jalisco", "Nuevo León", "Estado de México", "Puebla"],
  US: ["California", "Texas", "Florida", "New York", "Illinois"],
};

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
  const [country, setCountry] = useState(initial?.country ?? "VE");
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
      <FormGrid spacing={2}>
        <FormField xs={12} sm={4}>
          <TextField label="Etiqueta" placeholder='Ej: Casa, Oficina' value={label} onChange={(e) => setLabel(e.target.value)} size="small" required />
        </FormField>
        <FormField xs={12} sm={4}>
          <TextField label="Nombre del receptor" value={recipientName} onChange={(e) => setRecipientName(e.target.value)} size="small" required />
        </FormField>
        <FormField xs={12} sm={4}>
          <TextField label="Telefono" value={phone} onChange={(e) => setPhone(e.target.value)} size="small" />
        </FormField>
        <FormField xs={12}>
          <TextField label="Direccion completa" value={addressLine} onChange={(e) => setAddressLine(e.target.value)} size="small" multiline rows={2} required />
        </FormField>
        <FormField xs={12} sm={4}>
          <TextField label="Ciudad" value={city} onChange={(e) => setCity(e.target.value)} size="small" />
        </FormField>
        <FormField xs={12} sm={4}>
          <TextField
            select
            label="Estado"
            value={state}
            onChange={(e) => setState(e.target.value)}
            size="small"
            disabled={!STATES[country]}
          >
            {(STATES[country] ?? []).map((s) => (
              <MenuItem key={s} value={s}>{s}</MenuItem>
            ))}
          </TextField>
        </FormField>
        <FormField xs={6} sm={2}>
          <TextField label="Cod. postal" value={zipCode} onChange={(e) => setZipCode(e.target.value)} size="small" />
        </FormField>
        <FormField xs={6} sm={2}>
          <TextField
            select
            label="Pais"
            value={country}
            onChange={(e) => {
              setCountry(e.target.value);
              setState("");
            }}
            size="small"
          >
            {COUNTRIES.map((c) => (
              <MenuItem key={c.code} value={c.code}>{c.name}</MenuItem>
            ))}
          </TextField>
        </FormField>
        <FormField xs={12}>
          <TextField label="Instrucciones de entrega" placeholder="Ej: Porton azul, 2do piso" value={instructions} onChange={(e) => setInstructions(e.target.value)} size="small" />
        </FormField>
        <FormField xs={12}>
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
        </FormField>
      </FormGrid>
    </Box>
  );
}
