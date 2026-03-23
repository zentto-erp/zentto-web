"use client";

import { useState } from "react";
import { Box, TextField, Button, Checkbox, FormControlLabel, CircularProgress, MenuItem } from "@mui/material";
import { FormGrid, FormField } from "@zentto/shared-ui";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@zentto/shared-api";
import type { PaymentMethodFormData } from "../hooks/useStoreAccount";

const METHOD_TYPES = [
  { value: "PAGO_MOVIL", label: "Pago Movil" },
  { value: "TRANSFERENCIA", label: "Transferencia Bancaria" },
  { value: "ZELLE", label: "Zelle" },
  { value: "EFECTIVO", label: "Efectivo / Contra entrega" },
  { value: "TARJETA", label: "Tarjeta de Credito / Debito" },
];

const CARD_TYPES = [
  { value: "VISA", label: "Visa" },
  { value: "MASTERCARD", label: "Mastercard" },
  { value: "AMEX", label: "American Express" },
];

interface Props {
  initial?: Partial<PaymentMethodFormData>;
  onSave: (data: PaymentMethodFormData) => Promise<void>;
  onCancel: () => void;
  saving?: boolean;
}

export default function PaymentMethodForm({ initial, onSave, onCancel, saving }: Props) {
  const { data: bancosData } = useQuery({
    queryKey: ["bancos-ecommerce"],
    queryFn: () => apiGet("/api/v1/bancos"),
  });
  const bancos: any[] = (bancosData as any)?.rows ?? (bancosData as any)?.data ?? [];
  const [methodType, setMethodType] = useState(initial?.methodType ?? "");
  const [label, setLabel] = useState(initial?.label ?? "");
  const [bankName, setBankName] = useState(initial?.bankName ?? "");
  const [accountPhone, setAccountPhone] = useState(initial?.accountPhone ?? "");
  const [accountNumber, setAccountNumber] = useState(initial?.accountNumber ?? "");
  const [accountEmail, setAccountEmail] = useState(initial?.accountEmail ?? "");
  const [holderName, setHolderName] = useState(initial?.holderName ?? "");
  const [holderFiscalId, setHolderFiscalId] = useState(initial?.holderFiscalId ?? "");
  const [cardType, setCardType] = useState(initial?.cardType ?? "");
  const [cardLast4, setCardLast4] = useState(initial?.cardLast4 ?? "");
  const [cardExpiry, setCardExpiry] = useState(initial?.cardExpiry ?? "");
  const [isDefault, setIsDefault] = useState(initial?.isDefault ?? false);

  // Auto-suggest label
  const suggestLabel = (type: string, bank: string) => {
    if (bank) return `Mi ${bank}`;
    const found = METHOD_TYPES.find((t) => t.value === type);
    return found ? found.label : "";
  };

  const handleTypeChange = (type: string) => {
    setMethodType(type);
    if (!label || label === suggestLabel(methodType, bankName)) {
      setLabel(suggestLabel(type, bankName));
    }
  };

  const handleBankChange = (bank: string) => {
    setBankName(bank);
    if (!label || label === suggestLabel(methodType, bankName)) {
      setLabel(suggestLabel(methodType, bank));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSave({
      methodType,
      label: label.trim(),
      bankName: bankName.trim() || undefined,
      accountPhone: accountPhone.trim() || undefined,
      accountNumber: accountNumber.trim() || undefined,
      accountEmail: accountEmail.trim() || undefined,
      holderName: holderName.trim() || undefined,
      holderFiscalId: holderFiscalId.trim() || undefined,
      cardType: cardType || undefined,
      cardLast4: cardLast4.trim() || undefined,
      cardExpiry: cardExpiry.trim() || undefined,
      isDefault,
    });
  };

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ p: 2, border: "1px dashed #ccc", borderRadius: 2, bgcolor: "#fafafa" }}>
      <FormGrid spacing={2}>
        <FormField xs={12} sm={6}>
          <TextField
            select label="Tipo de metodo" value={methodType}
            onChange={(e) => handleTypeChange(e.target.value)}
            size="small" required
          >
            {METHOD_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
          </TextField>
        </FormField>
        <FormField xs={12} sm={6}>
          <TextField label="Etiqueta" placeholder='Ej: Mi Banesco' value={label} onChange={(e) => setLabel(e.target.value)} size="small" required />
        </FormField>

        {/* Pago Movil */}
        {methodType === "PAGO_MOVIL" && (
          <>
            <FormField xs={12} sm={4}>
              <TextField select label="Banco" value={bankName} onChange={(e) => handleBankChange(e.target.value)} size="small" required>
                {bancos.map((b: any) => (
                  <MenuItem key={b.BankName ?? b.bankName} value={b.BankName ?? b.bankName}>{b.BankName ?? b.bankName}</MenuItem>
                ))}
              </TextField>
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Telefono" placeholder="0414-1234567" value={accountPhone} onChange={(e) => setAccountPhone(e.target.value)} size="small" required />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="CI / RIF del titular" value={holderFiscalId} onChange={(e) => setHolderFiscalId(e.target.value)} size="small" required />
            </FormField>
          </>
        )}

        {/* Transferencia */}
        {methodType === "TRANSFERENCIA" && (
          <>
            <FormField xs={12} sm={4}>
              <TextField select label="Banco" value={bankName} onChange={(e) => handleBankChange(e.target.value)} size="small" required>
                {bancos.map((b: any) => (
                  <MenuItem key={b.BankName ?? b.bankName} value={b.BankName ?? b.bankName}>{b.BankName ?? b.bankName}</MenuItem>
                ))}
              </TextField>
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Nro. de cuenta" value={accountNumber} onChange={(e) => setAccountNumber(e.target.value)} size="small" required />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Titular" value={holderName} onChange={(e) => setHolderName(e.target.value)} size="small" />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="CI / RIF" value={holderFiscalId} onChange={(e) => setHolderFiscalId(e.target.value)} size="small" />
            </FormField>
          </>
        )}

        {/* Zelle */}
        {methodType === "ZELLE" && (
          <>
            <FormField xs={12} sm={6}>
              <TextField label="Email de Zelle" type="email" value={accountEmail} onChange={(e) => setAccountEmail(e.target.value)} size="small" required />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Nombre del titular" value={holderName} onChange={(e) => setHolderName(e.target.value)} size="small" />
            </FormField>
          </>
        )}

        {/* Tarjeta */}
        {methodType === "TARJETA" && (
          <>
            <FormField xs={12} sm={3}>
              <TextField select label="Tipo" value={cardType} onChange={(e) => setCardType(e.target.value)} size="small" required>
                {CARD_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
              </TextField>
            </FormField>
            <FormField xs={12} sm={3}>
              <TextField label="Ultimos 4 digitos" value={cardLast4} onChange={(e) => setCardLast4(e.target.value.replace(/\D/g, "").slice(0, 4))} size="small" required inputProps={{ maxLength: 4 }} />
            </FormField>
            <FormField xs={12} sm={3}>
              <TextField label="Vencimiento" placeholder="MM/YYYY" value={cardExpiry} onChange={(e) => setCardExpiry(e.target.value)} size="small" required />
            </FormField>
            <FormField xs={12} sm={3}>
              <TextField label="Titular" value={holderName} onChange={(e) => setHolderName(e.target.value)} size="small" />
            </FormField>
          </>
        )}

        {/* Efectivo: sin campos adicionales */}

        <FormField xs={12}>
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <FormControlLabel
              control={<Checkbox checked={isDefault} onChange={(e) => setIsDefault(e.target.checked)} size="small" />}
              label="Establecer como predeterminado"
            />
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button variant="outlined" size="small" onClick={onCancel} disabled={saving}>Cancelar</Button>
              <Button type="submit" variant="contained" size="small" disabled={saving || !methodType || !label.trim()}>
                {saving ? <CircularProgress size={18} /> : "Guardar"}
              </Button>
            </Box>
          </Box>
        </FormField>
      </FormGrid>
    </Box>
  );
}
