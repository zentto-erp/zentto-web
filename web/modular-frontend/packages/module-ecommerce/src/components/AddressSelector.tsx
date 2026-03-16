"use client";

import { useState } from "react";
import { Box, Typography, Radio, IconButton, Button, Chip, Collapse } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import HomeIcon from "@mui/icons-material/Home";
import { useMyAddresses, useCreateAddress, useDeleteAddress, type CustomerAddress, type AddressFormData } from "../hooks/useStoreAccount";
import AddressForm from "./AddressForm";

interface Props {
  selectedId: number | null;
  onSelect: (id: number, address: CustomerAddress) => void;
}

export default function AddressSelector({ selectedId, onSelect }: Props) {
  const { data: addresses = [], isLoading } = useMyAddresses();
  const createMutation = useCreateAddress();
  const deleteMutation = useDeleteAddress();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);

  // Auto-select default on first load
  if (!selectedId && addresses.length > 0) {
    const def = addresses.find((a) => a.IsDefault) ?? addresses[0];
    setTimeout(() => onSelect(def.AddressId, def), 0);
  }

  const handleSave = async (data: AddressFormData) => {
    const result = await createMutation.mutateAsync(data);
    if (result.ok && result.addressId) {
      setShowForm(false);
      // Select the newly created address
      setTimeout(() => {
        onSelect(result.addressId, {
          AddressId: result.addressId,
          Label: data.label,
          RecipientName: data.recipientName,
          Phone: data.phone ?? null,
          AddressLine: data.addressLine,
          City: data.city ?? null,
          State: data.state ?? null,
          ZipCode: data.zipCode ?? null,
          Country: data.country ?? "Venezuela",
          Instructions: data.instructions ?? null,
          IsDefault: data.isDefault ?? false,
        });
      }, 0);
    }
  };

  const handleDelete = async (id: number) => {
    await deleteMutation.mutateAsync(id);
    if (selectedId === id && addresses.length > 1) {
      const next = addresses.find((a) => a.AddressId !== id);
      if (next) onSelect(next.AddressId, next);
    }
  };

  if (isLoading) {
    return <Typography variant="body2" color="text.secondary">Cargando direcciones...</Typography>;
  }

  return (
    <Box>
      {addresses.map((addr) => (
        <Box
          key={addr.AddressId}
          onClick={() => onSelect(addr.AddressId, addr)}
          sx={{
            display: "flex",
            alignItems: "flex-start",
            gap: 1,
            p: 1.5,
            mb: 1,
            border: selectedId === addr.AddressId ? "2px solid #007185" : "1px solid #d5d9d9",
            borderRadius: "8px",
            cursor: "pointer",
            bgcolor: selectedId === addr.AddressId ? "#f0f9ff" : "transparent",
            "&:hover": { borderColor: "#007185" },
          }}
        >
          <Radio
            checked={selectedId === addr.AddressId}
            size="small"
            sx={{ p: 0, mt: 0.3, color: "#007185", "&.Mui-checked": { color: "#007185" } }}
          />
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.3 }}>
              <HomeIcon sx={{ fontSize: 16, color: "#555" }} />
              <Typography variant="subtitle2" fontWeight="bold">{addr.Label}</Typography>
              {addr.IsDefault && <Chip label="Predeterminada" size="small" color="primary" variant="outlined" sx={{ height: 20, fontSize: 11 }} />}
            </Box>
            <Typography variant="body2" sx={{ color: "#333" }}>
              {addr.RecipientName}{addr.Phone ? ` · ${addr.Phone}` : ""}
            </Typography>
            <Typography variant="body2" color="text.secondary">{addr.AddressLine}</Typography>
            {(addr.City || addr.State) && (
              <Typography variant="caption" color="text.secondary">
                {[addr.City, addr.State, addr.ZipCode].filter(Boolean).join(", ")}
              </Typography>
            )}
            {addr.Instructions && (
              <Typography variant="caption" color="text.secondary" sx={{ fontStyle: "italic", display: "block" }}>
                {addr.Instructions}
              </Typography>
            )}
          </Box>
          <Box sx={{ display: "flex", gap: 0.5 }}>
            <IconButton size="small" onClick={(e) => { e.stopPropagation(); setEditingId(addr.AddressId); setShowForm(false); }}>
              <EditIcon sx={{ fontSize: 16 }} />
            </IconButton>
            <IconButton size="small" onClick={(e) => { e.stopPropagation(); handleDelete(addr.AddressId); }} disabled={deleteMutation.isPending}>
              <DeleteIcon sx={{ fontSize: 16 }} />
            </IconButton>
          </Box>
        </Box>
      ))}

      {editingId && (
        <Box sx={{ mb: 1 }}>
          <AddressForm
            initial={(() => {
              const a = addresses.find((x) => x.AddressId === editingId);
              if (!a) return undefined;
              return {
                label: a.Label,
                recipientName: a.RecipientName,
                phone: a.Phone ?? "",
                addressLine: a.AddressLine,
                city: a.City ?? "",
                state: a.State ?? "",
                zipCode: a.ZipCode ?? "",
                country: a.Country,
                instructions: a.Instructions ?? "",
                isDefault: a.IsDefault,
              };
            })()}
            onSave={async (data) => {
              // Use update mutation inline
              const token = (await import("../store/useCartStore")).useCartStore.getState().customerToken;
              if (!token) return;
              const API_BASE = typeof window !== "undefined" ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000" : "http://localhost:4000";
              const res = await fetch(`${API_BASE}/store/my/addresses/${editingId}`, {
                method: "PUT",
                headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
                body: JSON.stringify(data),
              });
              if (res.ok) {
                setEditingId(null);
                createMutation.reset();
                // Force refetch
                window.dispatchEvent(new Event("focus"));
              }
            }}
            onCancel={() => setEditingId(null)}
          />
        </Box>
      )}

      <Collapse in={showForm && !editingId}>
        <AddressForm
          onSave={handleSave}
          onCancel={() => setShowForm(false)}
          saving={createMutation.isPending}
        />
      </Collapse>

      {!showForm && !editingId && (
        <Button
          variant="outlined"
          size="small"
          startIcon={<AddIcon />}
          onClick={() => setShowForm(true)}
          sx={{ mt: 1, textTransform: "none", color: "#007185", borderColor: "#007185" }}
        >
          Agregar nueva direccion
        </Button>
      )}
    </Box>
  );
}
