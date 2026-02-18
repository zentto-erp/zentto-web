"use client";

import React from "react";
import { Box, Typography } from "@mui/material";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";

export default function BancosHome() {
  return (
    <Box sx={{ p: 3 }}>
      <Typography color="text.secondary">
        Gestión de bancos auxiliares, cuentas bancarias y conciliación bancaria.
      </Typography>
    </Box>
  );
}
