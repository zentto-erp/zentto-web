"use client";

import React from "react";
import { Box, Typography, Grid, Paper } from "@mui/material";
import DashboardIcon from "@mui/icons-material/Dashboard";
import ReceiptIcon from "@mui/icons-material/Receipt";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import PeopleIcon from "@mui/icons-material/People";
import InventoryIcon from "@mui/icons-material/Inventory";

const stats = [
  { label: "Facturas", icon: <ReceiptIcon fontSize="large" />, color: "#1976d2" },
  { label: "Compras", icon: <ShoppingCartIcon fontSize="large" />, color: "#2e7d32" },
  { label: "Clientes", icon: <PeopleIcon fontSize="large" />, color: "#ed6c02" },
  { label: "Inventario", icon: <InventoryIcon fontSize="large" />, color: "#9c27b0" },
];

export default function AdminHome() {
  return (
    <Box sx={{ p: 3 }}>
      <Grid container spacing={3}>
        {stats.map((s) => (
          <Grid item xs={12} sm={6} md={3} key={s.label}>
            <Paper
              elevation={2}
              sx={{
                p: 3,
                display: "flex",
                alignItems: "center",
                gap: 2,
                borderLeft: `4px solid ${s.color}`,
              }}
            >
              <Box sx={{ color: s.color }}>{s.icon}</Box>
              <Typography variant="h6">{s.label}</Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
}
