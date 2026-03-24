"use client";

import { useState } from "react";
import {
  Box, Typography, Paper, TextField, Button, InputAdornment,
  ToggleButton, ToggleButtonGroup, CircularProgress, Chip, Pagination,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import AddBoxIcon from "@mui/icons-material/AddBox";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import { useShipmentsList } from "../hooks/useShipping";
import { StatusChip } from "./ShippingDashboard";

interface Props {
  onNavigate: (path: string) => void;
}

const statuses = [
  { value: "", label: "Todos" },
  { value: "DRAFT", label: "Borrador" },
  { value: "IN_TRANSIT", label: "En tránsito" },
  { value: "IN_CUSTOMS", label: "Aduana" },
  { value: "DELIVERED", label: "Entregados" },
  { value: "EXCEPTION", label: "Incidencias" },
];

export default function ShipmentsList({ onNavigate }: Props) {
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading } = useShipmentsList({ status: status || undefined, search: search || undefined, page, limit: 20 });
  const rows = data?.rows || [];
  const totalCount = data?.totalCount || 0;
  const totalPages = Math.ceil(totalCount / 20);

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3, flexWrap: "wrap", gap: 2 }}>
        <Typography variant="h5" fontWeight={700}>Mis Envíos</Typography>
        <Button variant="contained" startIcon={<AddBoxIcon />} onClick={() => onNavigate("/envios/nuevo")}>
          Nuevo Envío
        </Button>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3, borderRadius: 2 }}>
        <Box sx={{ display: "flex", gap: 2, flexWrap: "wrap", alignItems: "center" }}>
          <TextField
            placeholder="Buscar por número, guía o destinatario..."
            size="small"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            sx={{ minWidth: 300 }}
            InputProps={{
              startAdornment: <InputAdornment position="start"><SearchIcon /></InputAdornment>,
            }}
          />
          <ToggleButtonGroup
            value={status}
            exclusive
            onChange={(_e, v) => { if (v !== null) { setStatus(v); setPage(1); } }}
            size="small"
          >
            {statuses.map((s) => (
              <ToggleButton key={s.value} value={s.value} sx={{ textTransform: "none", fontSize: 12, px: 1.5 }}>
                {s.label}
              </ToggleButton>
            ))}
          </ToggleButtonGroup>
        </Box>
      </Paper>

      {/* List */}
      {isLoading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}><CircularProgress /></Box>
      ) : rows.length === 0 ? (
        <Paper sx={{ p: 6, textAlign: "center", borderRadius: 2 }}>
          <LocalShippingIcon sx={{ fontSize: 64, color: "#ccc", mb: 2 }} />
          <Typography variant="h6" color="text.secondary">No hay envíos</Typography>
          <Button variant="contained" sx={{ mt: 2 }} onClick={() => onNavigate("/envios/nuevo")}>
            Crear primer envío
          </Button>
        </Paper>
      ) : (
        <Box>
          {rows.map((s: any) => (
            <Paper
              key={s.ShipmentId}
              onClick={() => onNavigate(`/envios/${s.ShipmentId}`)}
              sx={{
                p: 2, mb: 1.5, cursor: "pointer", borderRadius: 2,
                "&:hover": { bgcolor: "#f5f8ff", boxShadow: 2 },
                transition: "all 0.2s",
              }}
            >
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 1 }}>
                <Box sx={{ flex: 1, minWidth: 200 }}>
                  <Box sx={{ display: "flex", gap: 1, alignItems: "center", mb: 0.5 }}>
                    <Typography variant="subtitle1" fontWeight={700}>{s.ShipmentNumber}</Typography>
                    {s.TrackingNumber && (
                      <Chip label={s.TrackingNumber} size="small" variant="outlined" sx={{ fontSize: 11 }} />
                    )}
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    {s.OriginCity}, {s.OriginCountryCode} → {s.DestCity}, {s.DestCountryCode}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {s.DestContactName} · {new Date(s.CreatedAt).toLocaleDateString("es")}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", gap: 1, alignItems: "center", flexWrap: "wrap" }}>
                  {s.CarrierCode && <Chip label={s.CarrierCode} size="small" color="primary" variant="outlined" />}
                  {s.IsInternational && <Chip label="Internacional" size="small" color="secondary" variant="outlined" sx={{ fontSize: 10 }} />}
                  <StatusChip status={s.Status} />
                  {s.ShippingCost > 0 && (
                    <Typography variant="subtitle2" fontWeight={700} color="text.secondary">
                      ${s.ShippingCost} {s.Currency}
                    </Typography>
                  )}
                </Box>
              </Box>
              {s.LastEvent && (
                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block", fontStyle: "italic" }}>
                  {s.LastEvent}
                </Typography>
              )}
            </Paper>
          ))}

          {totalPages > 1 && (
            <Box sx={{ display: "flex", justifyContent: "center", mt: 3 }}>
              <Pagination count={totalPages} page={page} onChange={(_e, v) => setPage(v)} color="primary" />
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
}
