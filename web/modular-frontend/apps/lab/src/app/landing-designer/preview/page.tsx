"use client";

import React, { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { Box, AppBar, Toolbar, Typography, Button, CircularProgress } from "@mui/material";
import { ArrowBack as BackIcon, ContentCopy as CopyIcon } from "@mui/icons-material";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-studio-app": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

const STORAGE_KEY = "zentto-landing-designer-config";

export default function LandingPreviewPage() {
  const router = useRouter();
  const appRef = useRef<any>(null);
  const [ready, setReady] = useState(false);
  const [config, setConfig] = useState<any>(null);

  useEffect(() => {
    try {
      setConfig(JSON.parse(localStorage.getItem(STORAGE_KEY) || "null"));
    } catch {
      /* noop */
    }
    Promise.all([
      import("@zentto/studio/app"),
      import("@zentto/studio/landing"),
    ]).then(() => setReady(true));
  }, []);

  useEffect(() => {
    if (!ready || !appRef.current || !config) return;
    appRef.current.config = config;
  }, [ready, config]);

  if (!config) {
    return (
      <Box sx={{ p: 4, textAlign: "center" }}>
        <Typography variant="h6" color="text.secondary">
          No hay configuracion de landing para preview.
        </Typography>
        <Button sx={{ mt: 2 }} onClick={() => router.push("/landing-designer")}>
          Ir al Designer
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Button
            size="small"
            startIcon={<BackIcon />}
            onClick={() => router.push("/landing-designer")}
          >
            Designer
          </Button>
          <Typography fontWeight={600}>Landing Preview</Typography>
          <Box flex={1} />
          <Button
            size="small"
            startIcon={<CopyIcon />}
            onClick={() => navigator.clipboard.writeText(JSON.stringify(config, null, 2))}
          >
            Copiar JSON
          </Button>
        </Toolbar>
      </AppBar>
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        {!ready ? (
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%" }}>
            <CircularProgress />
          </Box>
        ) : (
          <zentto-studio-app
            ref={appRef}
            style={{ display: "block", width: "100%", height: "100%" }}
          />
        )}
      </Box>
    </Box>
  );
}
