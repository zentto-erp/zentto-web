"use client";

import { useState } from "react";
import { Box, Typography, Radio, IconButton, Button, Chip, Collapse } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import PaymentIcon from "@mui/icons-material/Payment";
import PhoneAndroidIcon from "@mui/icons-material/PhoneAndroid";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import CreditCardIcon from "@mui/icons-material/CreditCard";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import { useMyPaymentMethods, useCreatePaymentMethod, useDeletePaymentMethod, type CustomerPaymentMethod, type PaymentMethodFormData } from "../hooks/useStoreAccount";
import PaymentMethodForm from "./PaymentMethodForm";

const TYPE_CONFIG: Record<string, { icon: React.ReactNode; color: string }> = {
  PAGO_MOVIL: { icon: <PhoneAndroidIcon sx={{ fontSize: 18 }} />, color: "#1565c0" },
  TRANSFERENCIA: { icon: <AccountBalanceIcon sx={{ fontSize: 18 }} />, color: "#2e7d32" },
  ZELLE: { icon: <PaymentIcon sx={{ fontSize: 18 }} />, color: "#6a1b9a" },
  EFECTIVO: { icon: <AttachMoneyIcon sx={{ fontSize: 18 }} />, color: "#e65100" },
  TARJETA: { icon: <CreditCardIcon sx={{ fontSize: 18 }} />, color: "#c62828" },
};

const TYPE_LABELS: Record<string, string> = {
  PAGO_MOVIL: "Pago Movil",
  TRANSFERENCIA: "Transferencia",
  ZELLE: "Zelle",
  EFECTIVO: "Efectivo",
  TARJETA: "Tarjeta",
};

function getMethodSummary(m: CustomerPaymentMethod): string {
  switch (m.MethodType) {
    case "PAGO_MOVIL":
      return [m.BankName, m.AccountPhone].filter(Boolean).join(" · ");
    case "TRANSFERENCIA":
      return [m.BankName, m.AccountNumber ? `****${m.AccountNumber.slice(-4)}` : ""].filter(Boolean).join(" · ");
    case "ZELLE":
      return m.AccountEmail ?? "";
    case "TARJETA":
      return [m.CardType, m.CardLast4 ? `****${m.CardLast4}` : "", m.CardExpiry].filter(Boolean).join(" · ");
    case "EFECTIVO":
      return "Pagar al recibir";
    default:
      return "";
  }
}

interface Props {
  selectedId: number | null;
  onSelect: (id: number, method: CustomerPaymentMethod) => void;
}

export default function PaymentMethodSelector({ selectedId, onSelect }: Props) {
  const { data: methods = [], isLoading } = useMyPaymentMethods();
  const createMutation = useCreatePaymentMethod();
  const deleteMutation = useDeletePaymentMethod();
  const [showForm, setShowForm] = useState(false);

  // Auto-select default
  if (!selectedId && methods.length > 0) {
    const def = methods.find((m) => m.IsDefault) ?? methods[0];
    setTimeout(() => onSelect(def.PaymentMethodId, def), 0);
  }

  const handleSave = async (data: PaymentMethodFormData) => {
    const result = await createMutation.mutateAsync(data);
    if (result.ok && result.paymentMethodId) {
      setShowForm(false);
      setTimeout(() => {
        onSelect(result.paymentMethodId, {
          PaymentMethodId: result.paymentMethodId,
          MethodType: data.methodType,
          Label: data.label,
          BankName: data.bankName ?? null,
          AccountPhone: data.accountPhone ?? null,
          AccountNumber: data.accountNumber ?? null,
          AccountEmail: data.accountEmail ?? null,
          HolderName: data.holderName ?? null,
          HolderFiscalId: data.holderFiscalId ?? null,
          CardType: data.cardType ?? null,
          CardLast4: data.cardLast4 ?? null,
          CardExpiry: data.cardExpiry ?? null,
          IsDefault: data.isDefault ?? false,
        });
      }, 0);
    }
  };

  const handleDelete = async (id: number) => {
    await deleteMutation.mutateAsync(id);
    if (selectedId === id && methods.length > 1) {
      const next = methods.find((m) => m.PaymentMethodId !== id);
      if (next) onSelect(next.PaymentMethodId, next);
    }
  };

  if (isLoading) {
    return <Typography variant="body2" color="text.secondary">Cargando metodos de pago...</Typography>;
  }

  return (
    <Box>
      {methods.map((m) => {
        const cfg = TYPE_CONFIG[m.MethodType] ?? TYPE_CONFIG.EFECTIVO;
        return (
          <Box
            key={m.PaymentMethodId}
            onClick={() => onSelect(m.PaymentMethodId, m)}
            sx={{
              display: "flex",
              alignItems: "center",
              gap: 1,
              p: 1.5,
              mb: 1,
              border: selectedId === m.PaymentMethodId ? "2px solid #007185" : "1px solid #d5d9d9",
              borderRadius: "8px",
              cursor: "pointer",
              bgcolor: selectedId === m.PaymentMethodId ? "#f0f9ff" : "transparent",
              "&:hover": { borderColor: "#007185" },
            }}
          >
            <Radio
              checked={selectedId === m.PaymentMethodId}
              size="small"
              sx={{ p: 0, color: "#007185", "&.Mui-checked": { color: "#007185" } }}
            />
            <Box sx={{ color: cfg.color, display: "flex", alignItems: "center" }}>
              {cfg.icon}
            </Box>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <Typography variant="subtitle2" fontWeight="bold">{m.Label}</Typography>
                <Chip label={TYPE_LABELS[m.MethodType] ?? m.MethodType} size="small" sx={{ height: 20, fontSize: 11, bgcolor: cfg.color, color: "#fff" }} />
                {m.IsDefault && <Chip label="Predeterminado" size="small" color="primary" variant="outlined" sx={{ height: 20, fontSize: 11 }} />}
              </Box>
              <Typography variant="body2" color="text.secondary">{getMethodSummary(m)}</Typography>
            </Box>
            <IconButton size="small" onClick={(e) => { e.stopPropagation(); handleDelete(m.PaymentMethodId); }} disabled={deleteMutation.isPending}>
              <DeleteIcon sx={{ fontSize: 16 }} />
            </IconButton>
          </Box>
        );
      })}

      <Collapse in={showForm}>
        <PaymentMethodForm
          onSave={handleSave}
          onCancel={() => setShowForm(false)}
          saving={createMutation.isPending}
        />
      </Collapse>

      {!showForm && (
        <Button
          variant="outlined"
          size="small"
          startIcon={<AddIcon />}
          onClick={() => setShowForm(true)}
          sx={{ mt: 1, textTransform: "none", color: "#007185", borderColor: "#007185" }}
        >
          Agregar nuevo metodo de pago
        </Button>
      )}
    </Box>
  );
}
