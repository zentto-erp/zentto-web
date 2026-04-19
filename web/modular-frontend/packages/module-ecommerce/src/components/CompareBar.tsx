"use client";

import { Box, Paper, Typography, Button, IconButton, Slide } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import { useCompareStore } from "../store/useCompareStore";

interface Props {
  onOpen?: () => void;
}

export default function CompareBar({ onOpen }: Props) {
  const codes = useCompareStore((s) => s.codes);
  const toggle = useCompareStore((s) => s.toggle);
  const clear = useCompareStore((s) => s.clear);

  return (
    <Slide direction="up" in={codes.length > 0} mountOnEnter unmountOnExit>
      <Paper
        elevation={8}
        sx={{
          position: "fixed",
          bottom: 16,
          left: "50%",
          transform: "translateX(-50%)",
          zIndex: 1300,
          px: 2,
          py: 1.5,
          borderRadius: 3,
          display: "flex",
          alignItems: "center",
          gap: 2,
          maxWidth: "calc(100vw - 32px)",
          minWidth: 320,
          bgcolor: "#0f1111",
          color: "#fff",
        }}
      >
        <CompareArrowsIcon />
        <Typography variant="body2" fontWeight={600} sx={{ flex: 1 }}>
          Comparando {codes.length} producto{codes.length !== 1 && "s"}
        </Typography>
        <Box sx={{ display: "flex", gap: 0.5 }}>
          {codes.map((c) => (
            <Box
              key={c}
              sx={{
                px: 1, py: 0.3, borderRadius: 1, fontSize: 11,
                bgcolor: "rgba(255,255,255,0.15)", display: "flex",
                alignItems: "center", gap: 0.5,
              }}
            >
              {c}
              <IconButton size="small" sx={{ p: 0.2, color: "#fff" }} onClick={() => toggle(c)}>
                <CloseIcon sx={{ fontSize: 14 }} />
              </IconButton>
            </Box>
          ))}
        </Box>
        <Button
          variant="contained"
          color="warning"
          size="small"
          onClick={onOpen}
          disabled={codes.length < 2}
          sx={{ textTransform: "none", fontWeight: 700 }}
        >
          Comparar
        </Button>
        <IconButton size="small" sx={{ color: "#aaa" }} onClick={clear}>
          <CloseIcon />
        </IconButton>
      </Paper>
    </Slide>
  );
}
