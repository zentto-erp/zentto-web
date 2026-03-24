"use client";

import React, { useState, useMemo } from "react";
import {
  AppBar,
  Box,
  Button,
  CssBaseline,
  Toolbar,
  Typography,
  Chip,
} from "@mui/material";
import {
  Science as LabIcon,
  Inventory as ArticulosIcon,
  Receipt as FacturasIcon,
} from "@mui/icons-material";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { usePathname, useRouter } from "next/navigation";

const NAV_ITEMS = [
  { label: "Articulos", href: "/articulos", icon: <ArticulosIcon fontSize="small" /> },
  { label: "Facturas", href: "/facturas", icon: <FacturasIcon fontSize="small" /> },
];

// Tema minimo — sin depender de shared-ui theme
const labTheme = createTheme({
  palette: {
    primary: { main: "#f59e0b" },
    secondary: { main: "#1a1a2e" },
  },
});

function LabNav() {
  const pathname = usePathname();
  const router = useRouter();

  return (
    <AppBar position="static" sx={{ bgcolor: "#1a1a2e" }}>
      <Toolbar sx={{ gap: 2 }}>
        <LabIcon />
        <Typography variant="h6" sx={{ mr: 2 }}>
          Zentto Lab
        </Typography>
        <Chip label="SANDBOX" color="warning" size="small" variant="filled" />
        <Box sx={{ flex: 1 }} />
        {NAV_ITEMS.map((item) => (
          <Button
            key={item.href}
            startIcon={item.icon}
            onClick={() => router.push(item.href)}
            variant={pathname === item.href ? "contained" : "text"}
            color={pathname === item.href ? "warning" : "inherit"}
            sx={{ color: pathname === item.href ? undefined : "#fff" }}
          >
            {item.label}
          </Button>
        ))}
      </Toolbar>
    </AppBar>
  );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false },
        },
      })
  );

  return (
    <html lang="es">
      <head>
        <title>Zentto Lab — Sandbox ZenttoDataGrid</title>
      </head>
      <body style={{ margin: 0 }}>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider theme={labTheme}>
            <CssBaseline />
            <Box sx={{ display: "flex", flexDirection: "column", height: "100vh" }}>
              <LabNav />
              <Box sx={{ flex: 1, overflow: "auto", p: 2 }}>
                {children}
              </Box>
            </Box>
          </ThemeProvider>
        </QueryClientProvider>
      </body>
    </html>
  );
}
