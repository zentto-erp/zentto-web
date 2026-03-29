"use client";

import React, { useState, useCallback, useEffect } from "react";
import {
  Drawer, Box, Typography, IconButton, Divider, TextField, Button,
  Stack, Chip, Alert, CircularProgress, Tooltip,
  Table, TableBody, TableCell, TableHead, TableRow,
  Dialog, DialogTitle, DialogContent, DialogActions,
  FormControl, InputLabel, Select, MenuItem,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import SaveIcon from "@mui/icons-material/Save";
import AddIcon from "@mui/icons-material/Add";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import EditNoteIcon from "@mui/icons-material/EditNote";
import DescriptionIcon from "@mui/icons-material/Description";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import {
  useBatchEmployeeLines,
  useSaveDraftLine,
  useBatchAddLine,
  useBatchRemoveLine,
  type EmployeeLine,
} from "../hooks/useNominaBatch";
import dynamic from "next/dynamic";
const DocumentViewerModal = dynamic(() => import("./DocumentViewerModal"), { ssr: false });

interface Props {
  batchId: number;
  employeeCode: string | null;
  onClose: () => void;
}

export default function PayrollEmployeePanel({ batchId, employeeCode, onClose }: Props) {
  const [docViewerOpen, setDocViewerOpen] = React.useState(false);
  const lines = useBatchEmployeeLines(batchId, employeeCode);
  const saveLine = useSaveDraftLine();
  const addLine = useBatchAddLine();
  const removeLine = useBatchRemoveLine();

  const [editingLine, setEditingLine] = useState<number | null>(null);
  const [editValues, setEditValues] = useState({ quantity: 0, amount: 0, notes: "" });
  const [addOpen, setAddOpen] = useState(false);
  const [newLine, setNewLine] = useState({
    conceptCode: "",
    conceptName: "",
    conceptType: "ASIGNACION" as "ASIGNACION" | "DEDUCCION" | "BONO",
    quantity: 1,
    amount: 0,
  });

  const lineData: EmployeeLine[] = Array.isArray(lines.data?.data) ? lines.data.data : (Array.isArray(lines.data) ? lines.data : []);

  const assignments = lineData.filter((l) => l.conceptType !== "DEDUCCION");
  const deductions = lineData.filter((l) => l.conceptType === "DEDUCCION");
  const totalAssignments = assignments.reduce((s, l) => s + (l.total ?? 0), 0);
  const totalDeductions = deductions.reduce((s, l) => s + (l.total ?? 0), 0);
  const totalNet = totalAssignments - totalDeductions;

  const handleStartEdit = useCallback((line: EmployeeLine) => {
    setEditingLine(line.lineId);
    setEditValues({ quantity: line.quantity, amount: line.amount, notes: line.notes ?? "" });
  }, []);

  const handleSave = useCallback(async () => {
    if (editingLine == null) return;
    await saveLine.mutateAsync({
      lineId: editingLine,
      quantity: editValues.quantity,
      amount: editValues.amount,
      notes: editValues.notes || undefined,
    });
    setEditingLine(null);
  }, [editingLine, editValues, saveLine]);

  const handleAddLine = useCallback(async () => {
    if (!employeeCode) return;
    await addLine.mutateAsync({
      batchId,
      employeeCode,
      conceptCode: newLine.conceptCode,
      conceptName: newLine.conceptName,
      conceptType: newLine.conceptType,
      quantity: newLine.quantity,
      amount: newLine.amount,
    });
    setAddOpen(false);
    setNewLine({ conceptCode: "", conceptName: "", conceptType: "ASIGNACION", quantity: 1, amount: 0 });
  }, [batchId, employeeCode, newLine, addLine]);

  const handleRemoveLine = useCallback(async (lineId: number) => {
    await removeLine.mutateAsync(lineId);
  }, [removeLine]);

  const renderLineRow = (line: EmployeeLine) => {
    const isEditing = editingLine === line.lineId;
    return (
      <TableRow key={line.lineId} sx={{ "&:hover": { bgcolor: "action.hover" } }}>
        <TableCell sx={{ py: 1, fontSize: 13 }}>
          <Box>
            <Typography variant="body2" sx={{ fontWeight: 500, fontSize: 13 }}>
              {line.conceptName}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {line.conceptCode}
            </Typography>
          </Box>
        </TableCell>
        <TableCell sx={{ py: 1 }}>
          {isEditing ? (
            <TextField
             
              type="number"
              value={editValues.quantity}
              onChange={(e) => setEditValues((v) => ({ ...v, quantity: Number(e.target.value) }))}
              sx={{ width: 70 }}
              inputProps={{ step: "0.01" }}
            />
          ) : (
            <Typography variant="body2" sx={{ fontFamily: "monospace", fontSize: 13 }}>
              {line.quantity}
            </Typography>
          )}
        </TableCell>
        <TableCell sx={{ py: 1 }}>
          {isEditing ? (
            <TextField
             
              type="number"
              value={editValues.amount}
              onChange={(e) => setEditValues((v) => ({ ...v, amount: Number(e.target.value) }))}
              sx={{ width: 100 }}
              inputProps={{ step: "0.01" }}
            />
          ) : (
            <Typography variant="body2" sx={{ fontFamily: "monospace", fontSize: 13 }}>
              {formatCurrency(line.amount)}
            </Typography>
          )}
        </TableCell>
        <TableCell sx={{ py: 1 }}>
          <Typography variant="body2" sx={{ fontWeight: 600, fontFamily: "monospace", fontSize: 13 }}>
            {isEditing ? formatCurrency(editValues.quantity * editValues.amount) : formatCurrency(line.total)}
          </Typography>
        </TableCell>
        <TableCell sx={{ py: 1 }}>
          {line.isModified && <Chip label="Editado" size="small" sx={{ height: 18, fontSize: 10, bgcolor: brandColors.accent, color: brandColors.dark }} />}
        </TableCell>
        <TableCell sx={{ py: 1 }}>
          <Stack direction="row" spacing={0.5}>
            {isEditing ? (
              <Tooltip title="Guardar">
                <IconButton size="small" onClick={handleSave} disabled={saveLine.isPending} color="primary">
                  {saveLine.isPending ? <CircularProgress size={16} /> : <SaveIcon fontSize="small" />}
                </IconButton>
              </Tooltip>
            ) : (
              <Tooltip title="Editar">
                <IconButton size="small" onClick={() => handleStartEdit(line)}>
                  <EditNoteIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            <Tooltip title="Eliminar">
              <IconButton size="small" color="error" onClick={() => handleRemoveLine(line.lineId)} disabled={removeLine.isPending}>
                <DeleteOutlineIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Stack>
        </TableCell>
      </TableRow>
    );
  };

  return (
    <>
      <Drawer
        anchor="right"
        open={!!employeeCode}
        onClose={onClose}
        PaperProps={{ sx: { width: { xs: "100%", md: 600 }, p: 0 } }}
      >
        {/* Header */}
        <Box sx={{ p: 2, bgcolor: brandColors.dark, color: "#fff", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>
              Detalle del Empleado
            </Typography>
            <Typography variant="body2" sx={{ opacity: 0.7 }}>
              Cédula: {employeeCode}
            </Typography>
          </Box>
          <Stack direction="row" spacing={1} alignItems="center">
            <Tooltip title="Generar Recibo de Pago">
              <Button
                size="small"
                variant="outlined"
                startIcon={<DescriptionIcon />}
                onClick={() => setDocViewerOpen(true)}
                sx={{ color: "#fff", borderColor: "rgba(255,255,255,0.4)", "&:hover": { borderColor: "#fff" } }}
              >
                Recibo
              </Button>
            </Tooltip>
            <Tooltip title="Cerrar">
              <IconButton onClick={onClose} sx={{ color: "#fff" }}>
                <CloseIcon />
              </IconButton>
            </Tooltip>
          </Stack>
        </Box>

        {lines.isLoading ? (
          <Box sx={{ p: 4, textAlign: "center" }}>
            <CircularProgress />
          </Box>
        ) : (
          <Box sx={{ flex: 1, overflow: "auto" }}>
            {/* Totals Bar */}
            <Box sx={{ p: 2, display: "flex", gap: 2, bgcolor: "background.default", borderBottom: "1px solid", borderColor: "divider" }}>
              <Box sx={{ flex: 1, textAlign: "center" }}>
                <Typography variant="caption" color="text.secondary">Asignaciones</Typography>
                <Typography variant="h6" sx={{ fontWeight: 700, color: brandColors.success }}>
                  {formatCurrency(totalAssignments)}
                </Typography>
              </Box>
              <Divider orientation="vertical" flexItem />
              <Box sx={{ flex: 1, textAlign: "center" }}>
                <Typography variant="caption" color="text.secondary">Deducciones</Typography>
                <Typography variant="h6" sx={{ fontWeight: 700, color: brandColors.danger }}>
                  {formatCurrency(totalDeductions)}
                </Typography>
              </Box>
              <Divider orientation="vertical" flexItem />
              <Box sx={{ flex: 1, textAlign: "center" }}>
                <Typography variant="caption" color="text.secondary">Neto</Typography>
                <Typography variant="h6" sx={{ fontWeight: 700 }}>
                  {formatCurrency(totalNet)}
                </Typography>
              </Box>
            </Box>

            {/* Add Line Button */}
            <Box sx={{ p: 2, display: "flex", justifyContent: "flex-end" }}>
              <Button
                size="small"
                variant="outlined"
                startIcon={<AddIcon />}
                onClick={() => setAddOpen(true)}
              >
                Agregar Concepto
              </Button>
            </Box>

            {/* Assignments Section */}
            <Box sx={{ px: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: brandColors.success }}>
                Asignaciones ({assignments.length})
              </Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12 }}>Concepto</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 80 }}>Cant.</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 100 }}>Monto</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 100 }}>Total</TableCell>
                    <TableCell sx={{ width: 60 }} />
                    <TableCell sx={{ width: 80 }} />
                  </TableRow>
                </TableHead>
                <TableBody>
                  {assignments.map(renderLineRow)}
                </TableBody>
              </Table>
            </Box>

            <Divider sx={{ my: 2 }} />

            {/* Deductions Section */}
            <Box sx={{ px: 2, pb: 3 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1, color: brandColors.danger }}>
                Deducciones ({deductions.length})
              </Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12 }}>Concepto</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 80 }}>Cant.</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 100 }}>Monto</TableCell>
                    <TableCell sx={{ fontWeight: 600, fontSize: 12, width: 100 }}>Total</TableCell>
                    <TableCell sx={{ width: 60 }} />
                    <TableCell sx={{ width: 80 }} />
                  </TableRow>
                </TableHead>
                <TableBody>
                  {deductions.map(renderLineRow)}
                </TableBody>
              </Table>
            </Box>
          </Box>
        )}
      </Drawer>

      {/* Document Viewer */}
      <DocumentViewerModal
        open={docViewerOpen}
        onClose={() => setDocViewerOpen(false)}
        batchId={batchId}
        employeeCode={employeeCode ?? undefined}
        documentType="payroll"
      />

      {/* Add Line Dialog */}
      <Dialog open={addOpen} onClose={() => setAddOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Agregar Concepto</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Código"
              fullWidth
             
              value={newLine.conceptCode}
              onChange={(e) => setNewLine((n) => ({ ...n, conceptCode: e.target.value }))}
            />
            <TextField
              label="Nombre"
              fullWidth
             
              value={newLine.conceptName}
              onChange={(e) => setNewLine((n) => ({ ...n, conceptName: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={newLine.conceptType}
                label="Tipo"
                onChange={(e) => setNewLine((n) => ({ ...n, conceptType: e.target.value as any }))}
              >
                <MenuItem value="ASIGNACION">Asignación</MenuItem>
                <MenuItem value="DEDUCCION">Deducción</MenuItem>
                <MenuItem value="BONO">Bono</MenuItem>
              </Select>
            </FormControl>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Cantidad"
                type="number"
               
                value={newLine.quantity}
                onChange={(e) => setNewLine((n) => ({ ...n, quantity: Number(e.target.value) }))}
                sx={{ flex: 1 }}
              />
              <TextField
                label="Monto"
                type="number"
               
                value={newLine.amount}
                onChange={(e) => setNewLine((n) => ({ ...n, amount: Number(e.target.value) }))}
                sx={{ flex: 1 }}
              />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleAddLine}
            disabled={!newLine.conceptCode || !newLine.conceptName || addLine.isPending}
          >
            Agregar
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
