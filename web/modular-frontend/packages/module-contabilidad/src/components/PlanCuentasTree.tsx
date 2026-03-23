"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Chip,
  IconButton,
  Collapse,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  Skeleton,
  Alert,
  Divider,
  MenuItem,
  Tooltip,
} from "@mui/material";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import AddIcon from "@mui/icons-material/Add";
import SearchIcon from "@mui/icons-material/Search";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { formatCurrency } from "@zentto/shared-api";
import {
  usePlanCuentas,
  useCreateCuenta,
  type CuentaInput,
} from "../hooks/useContabilidad";

// ─── Types ───────────────────────────────────────────────────

interface CuentaNode {
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
  children: CuentaNode[];
}

// Color mapping by account type (first digit of code)
const TYPE_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  "1": { bg: "#e3f2fd", text: "#1565c0", label: "Activo" },
  "2": { bg: "#ffebee", text: "#c62828", label: "Pasivo" },
  "3": { bg: "#e8f5e9", text: "#2e7d32", label: "Capital" },
  "4": { bg: "#f3e5f5", text: "#6a1b9a", label: "Ingreso" },
  "5": { bg: "#fff3e0", text: "#e65100", label: "Gasto" },
  "6": { bg: "#fff3e0", text: "#e65100", label: "Costo" },
};

function getTypeInfo(code: string) {
  const d = code?.charAt(0) || "0";
  return TYPE_COLORS[d] || { bg: "#f5f5f5", text: "#616161", label: "Otro" };
}

// ─── Build Tree ──────────────────────────────────────────────

function buildTree(accounts: any[]): CuentaNode[] {
  // Sort by code
  const sorted = [...accounts].sort((a, b) =>
    (a.codCuenta || "").localeCompare(b.codCuenta || "")
  );

  const roots: CuentaNode[] = [];
  const map = new Map<string, CuentaNode>();

  for (const acc of sorted) {
    const node: CuentaNode = {
      codCuenta: acc.codCuenta || acc.Cod_Cuenta || "",
      descripcion: acc.descripcion || acc.Desc_Cta || acc.Desc_Cuenta || "",
      tipo: acc.tipo || acc.Tipo || "",
      nivel: acc.nivel || acc.Nivel || 1,
      children: [],
    };
    map.set(node.codCuenta, node);

    // Find parent: try trimming last segment of the code
    // e.g., "1.1.01" parent is "1.1", "1.1" parent is "1"
    const parts = node.codCuenta.split(".");
    let parentFound = false;

    if (parts.length > 1) {
      const parentCode = parts.slice(0, -1).join(".");
      const parent = map.get(parentCode);
      if (parent) {
        parent.children.push(node);
        parentFound = true;
      }
    }

    if (!parentFound && node.nivel === 1) {
      roots.push(node);
    } else if (!parentFound) {
      // Try to find any parent with a shorter code that is a prefix
      let found = false;
      for (let i = parts.length - 1; i >= 1; i--) {
        const candidateCode = parts.slice(0, i).join(".");
        const candidate = map.get(candidateCode);
        if (candidate) {
          candidate.children.push(node);
          found = true;
          break;
        }
      }
      if (!found) {
        roots.push(node);
      }
    }
  }

  return roots;
}

// ─── Tree Row Component ──────────────────────────────────────

function TreeRow({
  node,
  depth,
  expanded,
  onToggle,
  onSelect,
  selectedCode,
}: {
  node: CuentaNode;
  depth: number;
  expanded: Set<string>;
  onToggle: (code: string) => void;
  onSelect: (node: CuentaNode) => void;
  selectedCode: string | null;
}) {
  const hasChildren = node.children.length > 0;
  const isExpanded = expanded.has(node.codCuenta);
  const isSelected = selectedCode === node.codCuenta;
  const typeInfo = getTypeInfo(node.codCuenta);

  return (
    <>
      <Box
        onClick={() => onSelect(node)}
        sx={{
          display: "flex",
          alignItems: "center",
          py: 0.8,
          px: 1,
          pl: 1 + depth * 3,
          cursor: "pointer",
          bgcolor: isSelected ? "action.selected" : "transparent",
          borderLeft: isSelected ? `3px solid ${typeInfo.text}` : "3px solid transparent",
          "&:hover": { bgcolor: "action.hover" },
          transition: "background-color 0.15s",
        }}
      >
        {/* Expand/Collapse */}
        {hasChildren ? (
          <Tooltip title={isExpanded ? "Colapsar" : "Expandir"}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                onToggle(node.codCuenta);
              }}
              sx={{ mr: 0.5, p: 0.3 }}
            >
              {isExpanded ? (
                <ExpandMoreIcon fontSize="small" />
              ) : (
                <ChevronRightIcon fontSize="small" />
              )}
            </IconButton>
          </Tooltip>
        ) : (
          <Box sx={{ width: 28, mr: 0.5 }} />
        )}

        {/* Code */}
        <Typography
          variant="body2"
          sx={{
            fontFamily: "monospace",
            fontWeight: node.nivel <= 2 ? 700 : 500,
            color: typeInfo.text,
            minWidth: 100,
            mr: 2,
          }}
        >
          {node.codCuenta}
        </Typography>

        {/* Name */}
        <Typography
          variant="body2"
          sx={{
            flex: 1,
            fontWeight: node.nivel <= 2 ? 600 : 400,
            color: "text.primary",
          }}
        >
          {node.descripcion}
        </Typography>

        {/* Type badge */}
        <Chip
          label={typeInfo.label}
          size="small"
          sx={{
            bgcolor: typeInfo.bg,
            color: typeInfo.text,
            fontWeight: 600,
            fontSize: "0.7rem",
            height: 22,
            mr: 1,
          }}
        />

        {/* Level */}
        <Chip
          label={`N${node.nivel}`}
          size="small"
          variant="outlined"
          sx={{ fontSize: "0.7rem", height: 22 }}
        />
      </Box>

      {/* Children */}
      {hasChildren && (
        <Collapse in={isExpanded} timeout="auto" unmountOnExit>
          {node.children.map((child) => (
            <TreeRow
              key={child.codCuenta}
              node={child}
              depth={depth + 1}
              expanded={expanded}
              onToggle={onToggle}
              onSelect={onSelect}
              selectedCode={selectedCode}
            />
          ))}
        </Collapse>
      )}
    </>
  );
}

// ─── Detail Panel ────────────────────────────────────────────

function DetailPanel({ account }: { account: CuentaNode | null }) {
  if (!account) {
    return (
      <Box
        sx={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          height: "100%",
          color: "text.secondary",
          p: 4,
        }}
      >
        <InfoOutlinedIcon sx={{ fontSize: 48, mb: 2, opacity: 0.4 }} />
        <Typography variant="body1">
          Seleccione una cuenta para ver su detalle
        </Typography>
      </Box>
    );
  }

  const typeInfo = getTypeInfo(account.codCuenta);

  return (
    <Box sx={{ p: 3 }}>
      <Box
        sx={{
          bgcolor: typeInfo.bg,
          borderRadius: 2,
          p: 2,
          mb: 3,
        }}
      >
        <Typography
          variant="h6"
          sx={{ fontFamily: "monospace", color: typeInfo.text, fontWeight: 700 }}
        >
          {account.codCuenta}
        </Typography>
        <Typography variant="h6" sx={{ fontWeight: 600, mt: 0.5 }}>
          {account.descripcion}
        </Typography>
      </Box>

      <Stack spacing={2}>
        <Box>
          <Typography variant="caption" color="text.secondary">
            Tipo de Cuenta
          </Typography>
          <Box sx={{ mt: 0.5 }}>
            <Chip
              label={typeInfo.label}
              sx={{
                bgcolor: typeInfo.bg,
                color: typeInfo.text,
                fontWeight: 600,
              }}
            />
          </Box>
        </Box>

        <Box>
          <Typography variant="caption" color="text.secondary">
            Naturaleza
          </Typography>
          <Typography variant="body1" fontWeight={500}>
            {account.tipo === "D" ? "Deudora" : account.tipo === "A" ? "Acreedora" : account.tipo || "N/A"}
          </Typography>
        </Box>

        <Box>
          <Typography variant="caption" color="text.secondary">
            Nivel
          </Typography>
          <Typography variant="body1" fontWeight={500}>
            {account.nivel}
          </Typography>
        </Box>

        <Box>
          <Typography variant="caption" color="text.secondary">
            Sub-cuentas
          </Typography>
          <Typography variant="body1" fontWeight={500}>
            {account.children.length}
          </Typography>
        </Box>

        {account.children.length > 0 && (
          <Box>
            <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: "block" }}>
              Cuentas hijas
            </Typography>
            {account.children.map((child) => (
              <Typography
                key={child.codCuenta}
                variant="body2"
                sx={{ fontFamily: "monospace", py: 0.3 }}
              >
                {child.codCuenta} - {child.descripcion}
              </Typography>
            ))}
          </Box>
        )}
      </Stack>
    </Box>
  );
}

// ─── Create Account Dialog ───────────────────────────────────

function CreateCuentaDialog({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const createMutation = useCreateCuenta();
  const [form, setForm] = useState<CuentaInput>({
    codCuenta: "",
    descripcion: "",
    tipo: "D",
    nivel: 1,
  });
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!form.codCuenta || !form.descripcion) {
      setError("Codigo y descripcion son obligatorios");
      return;
    }
    try {
      await createMutation.mutateAsync(form);
      onClose();
      setForm({ codCuenta: "", descripcion: "", tipo: "D", nivel: 1 });
      setError(null);
    } catch (err: any) {
      setError(err.message || "Error al crear la cuenta");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Crear cuenta contable</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2, mt: 1 }}>
            {error}
          </Alert>
        )}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Codigo de Cuenta"
            value={form.codCuenta}
            onChange={(e) => setForm({ ...form, codCuenta: e.target.value })}
            placeholder="Ej: 1.1.01.001"
            fullWidth
            size="small"
          />
          <TextField
            label="Descripcion"
            value={form.descripcion}
            onChange={(e) => setForm({ ...form, descripcion: e.target.value })}
            fullWidth
            size="small"
          />
          <TextField
            label="Naturaleza"
            select
            value={form.tipo}
            onChange={(e) => setForm({ ...form, tipo: e.target.value })}
            size="small"
          >
            <MenuItem value="D">Deudora</MenuItem>
            <MenuItem value="A">Acreedora</MenuItem>
          </TextField>
          <TextField
            label="Nivel"
            type="number"
            value={form.nivel}
            onChange={(e) => setForm({ ...form, nivel: Number(e.target.value) })}
            size="small"
            inputProps={{ min: 1, max: 6 }}
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={createMutation.isPending}
        >
          {createMutation.isPending ? "Creando..." : "Crear"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Main Component ──────────────────────────────────────────

export default function PlanCuentasTree() {
  const [search, setSearch] = useState("");
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [selectedCode, setSelectedCode] = useState<string | null>(null);
  const [selectedNode, setSelectedNode] = useState<CuentaNode | null>(null);
  const [createOpen, setCreateOpen] = useState(false);

  const { data, isLoading, error } = usePlanCuentas({ search });

  const accounts = useMemo(() => data?.data || [], [data]);

  const tree = useMemo(() => buildTree(accounts), [accounts]);

  // Filtered tree based on search (shows all if search hits, with parents expanded)
  const filteredTree = useMemo(() => {
    if (!search.trim()) return tree;

    const lower = search.toLowerCase();
    const matchingCodes = new Set<string>();

    // Find all matching accounts and their ancestor codes
    for (const acc of accounts) {
      const code = acc.codCuenta || acc.Cod_Cuenta || "";
      const desc = acc.descripcion || acc.Desc_Cta || acc.Desc_Cuenta || "";
      if (
        code.toLowerCase().includes(lower) ||
        desc.toLowerCase().includes(lower)
      ) {
        matchingCodes.add(code);
        // Add all parent codes
        const parts = code.split(".");
        for (let i = 1; i < parts.length; i++) {
          matchingCodes.add(parts.slice(0, i).join("."));
        }
      }
    }

    // Auto-expand matching parents
    const newExpanded = new Set(expanded);
    matchingCodes.forEach((code) => newExpanded.add(code));
    if (newExpanded.size !== expanded.size) {
      setExpanded(newExpanded);
    }

    return tree;
  }, [search, tree, accounts, expanded]);

  const handleToggle = (code: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(code)) {
        next.delete(code);
      } else {
        next.add(code);
      }
      return next;
    });
  };

  const handleSelect = (node: CuentaNode) => {
    setSelectedCode(node.codCuenta);
    setSelectedNode(node);
  };

  const handleExpandAll = () => {
    const allCodes = new Set<string>();
    const walk = (nodes: CuentaNode[]) => {
      for (const n of nodes) {
        if (n.children.length > 0) {
          allCodes.add(n.codCuenta);
          walk(n.children);
        }
      }
    };
    walk(tree);
    setExpanded(allCodes);
  };

  const handleCollapseAll = () => {
    setExpanded(new Set());
  };

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Header */}
      <Stack
        direction="row"
        alignItems="center"
        justifyContent="space-between"
        sx={{ mb: 2 }}
      >
        <Typography variant="h5" fontWeight={700}>
          Plan de cuentas - vista árbol
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setCreateOpen(true)}
        >
          Crear cuenta
        </Button>
      </Stack>

      {/* Search & Actions */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          placeholder="Buscar por codigo o nombre..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          size="small"
          sx={{ flex: 1, maxWidth: 400 }}
          InputProps={{
            startAdornment: (
              <SearchIcon sx={{ mr: 1, color: "text.secondary" }} />
            ),
          }}
        />
        <Button size="small" onClick={handleExpandAll}>
          Expandir Todo
        </Button>
        <Button size="small" onClick={handleCollapseAll}>
          Colapsar Todo
        </Button>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error al cargar el plan de cuentas
        </Alert>
      )}

      {/* Main Content */}
      <Box sx={{ display: "flex", flex: 1, gap: 2, minHeight: 0 }}>
        {/* Tree Panel */}
        <Paper
          sx={{
            flex: 2,
            overflow: "auto",
            borderRadius: 2,
          }}
        >
          {isLoading ? (
            <Box sx={{ p: 2 }}>
              {Array.from({ length: 10 }).map((_, i) => (
                <Skeleton key={i} height={36} sx={{ mb: 0.5 }} />
              ))}
            </Box>
          ) : filteredTree.length === 0 ? (
            <Box sx={{ p: 4, textAlign: "center" }}>
              <Typography color="text.secondary">
                No se encontraron cuentas
              </Typography>
            </Box>
          ) : (
            <Box sx={{ py: 1 }}>
              {filteredTree.map((node) => (
                <TreeRow
                  key={node.codCuenta}
                  node={node}
                  depth={0}
                  expanded={expanded}
                  onToggle={handleToggle}
                  onSelect={handleSelect}
                  selectedCode={selectedCode}
                />
              ))}
            </Box>
          )}
        </Paper>

        {/* Detail Panel */}
        <Paper
          sx={{
            flex: 1,
            minWidth: 300,
            overflow: "auto",
            borderRadius: 2,
          }}
        >
          <DetailPanel account={selectedNode} />
        </Paper>
      </Box>

      {/* Create Dialog */}
      <CreateCuentaDialog open={createOpen} onClose={() => setCreateOpen(false)} />
    </Box>
  );
}
