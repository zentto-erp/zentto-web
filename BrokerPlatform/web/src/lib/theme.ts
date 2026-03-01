"use client";
import { createTheme } from "@mui/material/styles";

export const theme = createTheme({
    palette: {
        mode: "dark",
        primary: {
            main: "#6C63FF",
            light: "#9D97FF",
            dark: "#4A42CC",
        },
        secondary: {
            main: "#FF6584",
            light: "#FF8FA3",
            dark: "#CC516A",
        },
        background: {
            default: "#0A0E1A",
            paper: "#121829",
        },
        text: {
            primary: "#E8EAED",
            secondary: "#9AA0B4",
        },
        success: { main: "#00C9A7" },
        warning: { main: "#FFB547" },
        error: { main: "#FF5252" },
        info: { main: "#4FC3F7" },
    },
    typography: {
        fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        h1: { fontWeight: 700, letterSpacing: "-0.02em" },
        h2: { fontWeight: 700, letterSpacing: "-0.01em" },
        h3: { fontWeight: 600 },
        h4: { fontWeight: 600 },
        h5: { fontWeight: 600 },
        h6: { fontWeight: 600 },
        button: { textTransform: "none", fontWeight: 600 },
    },
    shape: {
        borderRadius: 12,
    },
    components: {
        MuiButton: {
            styleOverrides: {
                root: {
                    borderRadius: 10,
                    padding: "10px 24px",
                    fontSize: "0.95rem",
                },
                contained: {
                    boxShadow: "0 4px 14px 0 rgba(108, 99, 255, 0.39)",
                    "&:hover": {
                        boxShadow: "0 6px 20px rgba(108, 99, 255, 0.5)",
                    },
                },
            },
        },
        MuiCard: {
            styleOverrides: {
                root: {
                    backgroundImage: "none",
                    border: "1px solid rgba(255,255,255,0.06)",
                    backdropFilter: "blur(20px)",
                },
            },
        },
        MuiTextField: {
            styleOverrides: {
                root: {
                    "& .MuiOutlinedInput-root": {
                        borderRadius: 10,
                        "& fieldset": {
                            borderColor: "rgba(255,255,255,0.1)",
                        },
                        "&:hover fieldset": {
                            borderColor: "rgba(108, 99, 255, 0.5)",
                        },
                    },
                },
            },
        },
        MuiPaper: {
            styleOverrides: {
                root: {
                    backgroundImage: "none",
                },
            },
        },
        MuiChip: {
            styleOverrides: {
                root: {
                    borderRadius: 8,
                },
            },
        },
    },
});
