"use client";

import { useParams } from "next/navigation";
import { useEffect, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Collapse,
  IconButton,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";
import KeyboardArrowDownIcon from "@mui/icons-material/KeyboardArrowDown";
import KeyboardArrowUpIcon from "@mui/icons-material/KeyboardArrowUp";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import { formsApi } from "@/lib/api";

interface Submission {
  id: string;
  formId?: string;
  createdAt: string;
  data: Record<string, any>;
}

/* ------------------------------------------------------------------ */
/* Expandable row                                                      */
/* ------------------------------------------------------------------ */
function SubmissionRow({ row }: { row: Submission }) {
  const [open, setOpen] = useState(false);

  const dataPreview = Object.entries(row.data || {})
    .slice(0, 3)
    .map(([k, v]) => `${k}: ${v}`)
    .join(" | ");

  return (
    <>
      <TableRow hover sx={{ "& > *": { borderBottom: "unset" } }}>
        <TableCell padding="checkbox">
          <IconButton size="small" onClick={() => setOpen(!open)}>
            {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
          </IconButton>
        </TableCell>
        <TableCell>
          {new Date(row.createdAt).toLocaleString()}
        </TableCell>
        <TableCell>{row.formId || "--"}</TableCell>
        <TableCell>
          <Typography variant="body2" noWrap sx={{ maxWidth: 400 }}>
            {dataPreview || "--"}
          </Typography>
        </TableCell>
      </TableRow>
      <TableRow>
        <TableCell colSpan={4} sx={{ py: 0 }}>
          <Collapse in={open} timeout="auto" unmountOnExit>
            <Box sx={{ py: 2, px: 1 }}>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>
                Datos completos
              </Typography>
              <Paper variant="outlined" sx={{ p: 2, bgcolor: "grey.50" }}>
                <pre style={{ margin: 0, whiteSpace: "pre-wrap", fontSize: 13 }}>
                  {JSON.stringify(row.data, null, 2)}
                </pre>
              </Paper>
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </>
  );
}

/* ------------------------------------------------------------------ */
/* CSV export                                                          */
/* ------------------------------------------------------------------ */
function exportCsv(submissions: Submission[]) {
  if (submissions.length === 0) return;

  const allKeys = new Set<string>();
  submissions.forEach((s) =>
    Object.keys(s.data || {}).forEach((k) => allKeys.add(k)),
  );
  const keys = ["id", "formId", "createdAt", ...Array.from(allKeys)];

  const escape = (v: any) => {
    const str = String(v ?? "");
    return str.includes(",") || str.includes('"') || str.includes("\n")
      ? `"${str.replace(/"/g, '""')}"`
      : str;
  };

  const rows = submissions.map((s) =>
    keys
      .map((k) => {
        if (k === "id") return escape(s.id);
        if (k === "formId") return escape(s.formId);
        if (k === "createdAt") return escape(s.createdAt);
        return escape(s.data?.[k]);
      })
      .join(","),
  );

  const csv = [keys.join(","), ...rows].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "form-submissions.csv";
  a.click();
  URL.revokeObjectURL(url);
}

/* ------------------------------------------------------------------ */
/* Main page                                                           */
/* ------------------------------------------------------------------ */
export default function FormSubmissionsPage() {
  const params = useParams<{ siteId: string }>();
  const siteId = params.siteId;

  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!siteId) return;
    formsApi
      .list(siteId)
      .then((data) => setSubmissions(Array.isArray(data) ? data : []))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [siteId]);

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={300} />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={700}>
          Envios de formularios
        </Typography>
        <Button
          variant="outlined"
          startIcon={<FileDownloadIcon />}
          onClick={() => exportCsv(submissions)}
          disabled={submissions.length === 0}
        >
          Exportar CSV
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox" />
              <TableCell>Fecha</TableCell>
              <TableCell>Formulario</TableCell>
              <TableCell>Vista previa</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {submissions.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} align="center">
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    sx={{ py: 4 }}
                  >
                    No hay envios de formularios.
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              submissions.map((sub) => (
                <SubmissionRow key={sub.id} row={sub} />
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
