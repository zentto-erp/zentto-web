"use client";

import React, { useEffect, useRef, useState, useCallback, useMemo } from "react";
import {
  Box,
  Typography,
  Paper,
  Button,
  Snackbar,
  Alert,
  Tooltip,
  IconButton,
  Card,
  CardContent,
  CardActionArea,
  Divider,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  AppBar,
  Toolbar,
  Chip,
  ButtonGroup,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemButton,
  TextField,
  LinearProgress,
  Select,
  FormControl,
  InputLabel,
  InputAdornment,
  Fade,
  Skeleton,
  Badge,
} from "@mui/material";
import {
  Edit as DesignIcon,
  Visibility as ViewIcon,
  NoteAdd as NewIcon,
  FolderOpen as OpenIcon,
  Save as SaveIcon,
  SaveAs as SaveAsIcon,
  PictureAsPdf as PdfIcon,
  Code as HtmlIcon,
  Print as PrintIcon,
  ViewColumn as SplitIcon,
  Receipt as InvoiceIcon,
  LocalOffer as LabelIcon,
  Badge as BadgeIcon,
  ZoomIn as ZoomInIcon,
  ZoomOut as ZoomOutIcon,
  Description as TemplateIcon,
  InsertDriveFileOutlined as BlankIcon,
  Close as CloseIcon,
  Remove as MinusIcon,
  Add as PlusIcon,
  Api as ApiIcon,
  UploadFile as UploadFileIcon,
  EditNote as ManualIcon,
  Block as NoDataIcon,
  CheckCircle as CheckIcon,
  Storefront as StoreIcon,
  Search as SearchIcon,
  Download as DownloadIcon,
  OpenInNew as OpenInNewIcon,
  FilterList as FilterIcon,
  Public as PublicIcon,
  Person as PersonIcon,
  Category as CategoryIcon,
} from "@mui/icons-material";
import type { ReportLayout, DataSet } from "@zentto/report-core";

// ─── Safe imports from @zentto/report-core (pure functions) ─────────
let renderToFullHtml: ((layout: ReportLayout, data: DataSet) => string) | null = null;
let createBlankLayout: (() => ReportLayout) | null = null;
let CORE_TEMPLATES: Array<{
  id: string; name: string; description: string; category: string;
  icon: string; color: string; layout: ReportLayout; sampleData: DataSet;
}> = [];
try {
  const core = require("@zentto/report-core");
  renderToFullHtml = core.renderToFullHtml;
  createBlankLayout = core.createBlankLayout;
  CORE_TEMPLATES = core.REPORT_TEMPLATES || [];
} catch {
  /* Will be unavailable — fallbacks are used */
}

// ─── Constants ──────────────────────────────────────────────────────

const AUTOSAVE_KEY = "zentto-report-studio:autosave";
const AUTOSAVE_INTERVAL = 30_000; // 30s

// ─── Templates from core (single source of truth) ──────────────────

const CATEGORY_MAP: Record<string, string> = {
  report: "Reportes",
  label: "Etiquetas",
  card: "Tarjetas",
  receipt: "Recibos",
  envelope: "Sobres",
};

const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  report: <InvoiceIcon />,
  label: <LabelIcon />,
  card: <BadgeIcon />,
  receipt: <InvoiceIcon />,
  envelope: <BadgeIcon />,
};

interface TemplateEntry {
  id: string;
  name: string;
  description: string;
  icon: React.ReactNode;
  color: string;
  category: string;
  layout: ReportLayout;
  data: DataSet;
}

const TEMPLATES: TemplateEntry[] = CORE_TEMPLATES.map((t) => ({
  id: t.id,
  name: t.name,
  description: t.description,
  icon: CATEGORY_ICONS[t.category] || <TemplateIcon />,
  color: t.color,
  category: CATEGORY_MAP[t.category] || t.category,
  layout: t.layout,
  data: t.sampleData,
}));

const DEFAULT_BLANK_LAYOUT: ReportLayout = {
  version: "1.0",
  name: "Reporte en Blanco",
  description: "",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 10, bottom: 15, left: 10 },
  orientation: "portrait",
  dataSources: [],
  bands: [],
};

// ─── Zentto API endpoints for data browser ──────────────────────────

const ZENTTO_API_ENDPOINTS = [
  { id: "articulos", label: "Articulos", endpoint: "/api/v1/articulos" },
  { id: "documentos-venta", label: "Documentos de Venta", endpoint: "/api/v1/documentos-venta" },
  { id: "clientes", label: "Clientes", endpoint: "/api/v1/clientes" },
  { id: "proveedores", label: "Proveedores", endpoint: "/api/v1/proveedores" },
  { id: "productos", label: "Productos", endpoint: "/api/v1/productos" },
];

// ─── CSV / JSON parse helpers ───────────────────────────────────────

function parseCSV(text: string): { fields: string[]; rows: Record<string, string>[] } {
  const lines = text.split(/\r?\n/).filter((l) => l.trim());
  if (lines.length === 0) return { fields: [], rows: [] };
  const sep = lines[0].includes("\t") ? "\t" : ",";
  const fields = lines[0].split(sep).map((f) => f.trim().replace(/^"|"$/g, ""));
  const rows = lines.slice(1).map((line) => {
    const vals = line.split(sep).map((v) => v.trim().replace(/^"|"$/g, ""));
    const obj: Record<string, string> = {};
    fields.forEach((f, i) => { obj[f] = vals[i] ?? ""; });
    return obj;
  });
  return { fields, rows };
}

function detectFieldType(values: any[]): "string" | "number" | "date" | "boolean" {
  const sample = values.filter((v) => v != null && v !== "").slice(0, 20);
  if (sample.length === 0) return "string";
  if (sample.every((v) => typeof v === "boolean" || v === "true" || v === "false")) return "boolean";
  if (sample.every((v) => !isNaN(Number(v)) && v !== "")) return "number";
  if (sample.every((v) => !isNaN(Date.parse(String(v))))) return "date";
  return "string";
}

function inferFieldsFromData(rows: Record<string, any>[]): { name: string; label: string; type: string }[] {
  if (rows.length === 0) return [];
  const keys = Object.keys(rows[0]);
  return keys.map((k) => ({
    name: k,
    label: k.charAt(0).toUpperCase() + k.slice(1).replace(/([A-Z])/g, " $1"),
    type: detectFieldType(rows.map((r) => r[k])),
  }));
}

// ─── JSX type declarations for web components ───────────────────────

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-report-viewer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
      "zentto-report-designer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

// ─── Helpers ────────────────────────────────────────────────────────

function countElements(layout: ReportLayout): number {
  return (layout.bands ?? []).reduce((acc: number, b: any) => acc + (b.elements?.length ?? 0), 0);
}

function formatPageSize(layout: ReportLayout): string {
  const { width, height, unit } = layout.pageSize;
  const label =
    width === 210 && height === 297 ? "A4" :
    width === 216 && height === 279 ? "Letter" :
    `${width}x${height}`;
  const orient = layout.orientation === "portrait" ? "Vertical" : "Horizontal";
  return `${label} ${orient} -- ${width} x ${height} ${unit}`;
}

function safeFileName(name: string): string {
  return (name || "reporte").replace(/\s+/g, "-").toLowerCase();
}

// ─── File System Access API helpers ─────────────────────────────────

const FILE_PICKER_TYPES = [
  {
    description: "Report JSON",
    accept: { "application/json": [".report.json", ".json"] as `.${string}`[] },
  },
];

async function openFilePicker(): Promise<{ handle: FileSystemFileHandle | null; content: string; name: string } | null> {
  // Try File System Access API first
  if (typeof window !== "undefined" && "showOpenFilePicker" in window) {
    try {
      const [handle] = await (window as any).showOpenFilePicker({
        types: FILE_PICKER_TYPES,
        multiple: false,
      });
      const file = await handle.getFile();
      const content = await file.text();
      return { handle, content, name: file.name };
    } catch (e: any) {
      if (e.name === "AbortError") return null;
      // Fall through to input fallback
    }
  }
  return null; // Caller should use input fallback
}

async function saveToFileHandle(handle: FileSystemFileHandle, content: string): Promise<boolean> {
  try {
    const writable = await (handle as any).createWritable();
    await writable.write(content);
    await writable.close();
    return true;
  } catch {
    return false;
  }
}

async function showSaveFilePicker(suggestedName: string): Promise<FileSystemFileHandle | null> {
  if (typeof window !== "undefined" && "showSaveFilePicker" in window) {
    try {
      const handle = await (window as any).showSaveFilePicker({
        suggestedName,
        types: FILE_PICKER_TYPES,
      });
      return handle;
    } catch (e: any) {
      if (e.name === "AbortError") return null;
    }
  }
  return null;
}

function downloadAsFile(content: string, filename: string, mimeType = "application/json") {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

// ─── Main component ─────────────────────────────────────────────────

export default function ReportStudio() {
  // ── State ──
  const [mode, setMode] = useState<"store" | "designer" | "viewer" | "split">("store");
  const [registered, setRegistered] = useState(false);
  const [layout, setLayout] = useState<ReportLayout>(CORE_TEMPLATES[0]?.layout || DEFAULT_BLANK_LAYOUT);
  const [sampleData, setSampleData] = useState<DataSet>(CORE_TEMPLATES[0]?.sampleData || {});
  const [snackbar, setSnackbar] = useState<{ message: string; severity: "success" | "info" | "warning" | "error" } | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [fileHandle, setFileHandle] = useState<FileSystemFileHandle | null>(null);
  const [isModified, setIsModified] = useState(false);
  const [lastSaveTime, setLastSaveTime] = useState<Date | null>(null);
  const [zoom, setZoom] = useState(100);
  const [templateDialogOpen, setTemplateDialogOpen] = useState(false);
  const [newMenuAnchor, setNewMenuAnchor] = useState<null | HTMLElement>(null);
  const [recoverySnackbar, setRecoverySnackbar] = useState(false);

  // ── Store state ──
  const [storeSearch, setStoreSearch] = useState("");
  const [storeCategory, setStoreCategory] = useState<string>("all");
  const [savedReports, setSavedReports] = useState<{ id: string; name: string; updatedAt?: string }[]>([]);
  const [savedReportsLoading, setSavedReportsLoading] = useState(false);
  const [publicReports, setPublicReports] = useState<{ id: string; name: string; updatedAt?: string; description?: string }[]>([]);
  const [publicReportsLoading, setPublicReportsLoading] = useState(false);
  const [previewLayout, setPreviewLayout] = useState<ReportLayout | null>(null);
  const [previewData, setPreviewData] = useState<DataSet>({});
  const [previewOpen, setPreviewOpen] = useState(false);
  const [previewTitle, setPreviewTitle] = useState("");

  // ── New Report Wizard state ──
  const [wizardOpen, setWizardOpen] = useState(false);
  const [wizardTab, setWizardTab] = useState(0); // 0=templates, 1=blank+datasource
  const [dsMode, setDsMode] = useState<"api" | "file" | "manual" | "none">("none");
  const [apiEndpointId, setApiEndpointId] = useState<string | null>(null);
  const [apiLoading, setApiLoading] = useState(false);
  const [apiFields, setApiFields] = useState<{ name: string; label: string; type: string }[]>([]);
  const [apiSampleRows, setApiSampleRows] = useState<Record<string, any>[]>([]);
  const [fileFields, setFileFields] = useState<{ name: string; label: string; type: string }[]>([]);
  const [fileSampleRows, setFileSampleRows] = useState<Record<string, any>[]>([]);
  const [fileSourceName, setFileSourceName] = useState<string>("");
  const [manualFields, setManualFields] = useState<{ name: string; label: string; type: string }[]>([{ name: "", label: "", type: "string" }]);
  const dataFileInputRef = useRef<HTMLInputElement>(null);

  const designerRef = useRef<any>(null);
  const viewerRef = useRef<any>(null);
  const splitViewerRef = useRef<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const printIframeRef = useRef<HTMLIFrameElement | null>(null);
  const autosaveTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const layoutRef = useRef(layout);
  const sampleDataRef = useRef(sampleData);

  // Keep refs in sync
  useEffect(() => { layoutRef.current = layout; }, [layout]);
  useEffect(() => { sampleDataRef.current = sampleData; }, [sampleData]);

  // ── Computed ──
  const displayTitle = useMemo(() => {
    const name = fileName || layout.name || "Sin titulo";
    return isModified ? `${name} *` : name;
  }, [fileName, layout.name, isModified]);

  const pageSizeText = useMemo(() => formatPageSize(layout), [layout]);
  const elementCount = useMemo(() => countElements(layout), [layout]);
  const bandCount = useMemo(() => layout.bands?.length ?? 0, [layout]);

  // ── Show notification ──
  const notify = useCallback((message: string, severity: "success" | "info" | "warning" | "error" = "success") => {
    setSnackbar({ message, severity });
  }, []);

  // ── Mark as modified ──
  const markModified = useCallback(() => {
    setIsModified(true);
  }, []);

  // ── Register web components ──
  useEffect(() => {
    import("./register-components").then(() => setRegistered(true)).catch((err) => {
      console.error("Failed to register report components:", err);
    });
  }, []);

  // ── Auto-recovery on load ──
  useEffect(() => {
    try {
      const saved = localStorage.getItem(AUTOSAVE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        const savedAt = new Date(parsed.savedAt);
        const ageMs = Date.now() - savedAt.getTime();
        if (ageMs < 5 * 60 * 1000 && ageMs > 60_000) {
          // Recovered data is between 1 min and 5 min old
          setLayout(parsed.layout);
          if (parsed.sampleData) setSampleData(parsed.sampleData);
          if (parsed.fileName) setFileName(parsed.fileName);
          setIsModified(true);
          setRecoverySnackbar(true);
        }
      }
    } catch {
      // Ignore parse errors
    }
  }, []);

  // ── Auto-save to localStorage every 30s ──
  useEffect(() => {
    autosaveTimerRef.current = setInterval(() => {
      try {
        const payload = {
          layout: layoutRef.current,
          sampleData: sampleDataRef.current,
          fileName: fileName,
          savedAt: new Date().toISOString(),
        };
        localStorage.setItem(AUTOSAVE_KEY, JSON.stringify(payload));
      } catch {
        // Storage full or unavailable
      }
    }, AUTOSAVE_INTERVAL);
    return () => {
      if (autosaveTimerRef.current) clearInterval(autosaveTimerRef.current);
    };
  }, [fileName]);

  // ── Clear autosave on explicit save ──
  const clearAutosave = useCallback(() => {
    try { localStorage.removeItem(AUTOSAVE_KEY); } catch { /* ignore */ }
  }, []);

  // ── Keyboard shortcuts ──
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const ctrl = e.ctrlKey || e.metaKey;
      if (!ctrl) return;

      switch (e.key.toLowerCase()) {
        case "n":
          if (!e.shiftKey) {
            e.preventDefault();
            handleOpenWizard();
          }
          break;
        case "o":
          e.preventDefault();
          handleOpenFile();
          break;
        case "s":
          e.preventDefault();
          if (e.shiftKey) {
            handleSaveAs();
          } else {
            handleSave();
          }
          break;
        case "p":
          e.preventDefault();
          handlePrint();
          break;
        case "e":
          e.preventDefault();
          if (e.shiftKey) {
            handleExportHtml();
          } else {
            handleExportPdf();
          }
          break;
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [layout, sampleData, fileHandle, isModified]);

  // ── Bind data to designer ──
  useEffect(() => {
    if (!registered || (mode !== "designer" && mode !== "split")) return;
    const el = designerRef.current;
    if (!el) return;

    el.layout = layout;
    el.dataSources = layout.dataSources;
    el.sampleData = sampleData;

    // Zentto ERP data source provider
    // Uses /v1/meta/schema for real DB tables/columns
    // Uses /v1/meta/relations for FK relationships
    let zenttoToken = "";
    el.zenttoProvider = {
      login: async (_url: string, usuario: string, clave: string, companyId?: number) => {
        const res = await fetch("/api/v1/auth/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ usuario, clave, ...(companyId ? { companyId } : {}) }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.message || err.error || "Login failed");
        }
        const data = await res.json();
        zenttoToken = data.token;

        // Fetch real tables from /v1/meta/schema
        const schemaRes = await fetch("/api/v1/meta/schema", {
          headers: { Authorization: `Bearer ${zenttoToken}` },
        });
        let tableNames: string[] = [];
        if (schemaRes.ok) {
          const schema = await schemaRes.json();
          tableNames = (schema.tables || []).map((t: any) => `${t.schema}.${t.table}`);
        }

        return {
          token: data.token,
          userName: data.userName || data.usuario?.nombre || usuario,
          company: data.company?.companyName || "Zentto",
          modules: tableNames,
        };
      },
      getModules: async () => {
        const res = await fetch("/api/v1/meta/schema", {
          headers: { Authorization: `Bearer ${zenttoToken}` },
        });
        if (!res.ok) return [];
        const schema = await res.json();
        return (schema.tables || []).map((t: any) => `${t.schema}.${t.table}`);
      },
      getSchema: async (mod: string) => {
        // mod = "schema.table" — fetch columns from meta
        const res = await fetch("/api/v1/meta/schema", {
          headers: { Authorization: `Bearer ${zenttoToken}` },
        });
        if (!res.ok) return [];
        const schema = await res.json();
        const [s, t] = mod.split(".");
        const cols = (schema.columns || []).filter(
          (c: any) => c.schema === s && c.table === t,
        );
        return cols.map((c: any) => ({
          name: c.column,
          type: c.type,
          label: c.column,
        }));
      },
      getData: async (mod: string) => {
        // mod = "schema.table" — use CRUD endpoint
        const [s, t] = mod.split(".");
        const endpoint = t.toLowerCase();
        const res = await fetch(`/api/v1/crud/${endpoint}?pageSize=10`, {
          headers: { Authorization: `Bearer ${zenttoToken}` },
        });
        if (!res.ok) return [];
        const data = await res.json();
        return data.data || data.items || (Array.isArray(data) ? data : []);
      },
      logout: async () => { zenttoToken = ""; },
    };

    // Report storage provider (zentto-cache via API proxy)
    // In production this will be the client's database
    el.storageProvider = {
      list: async () => {
        try {
          const res = await fetch("/api/v1/reportes/saved", {
            headers: zenttoToken ? { Authorization: `Bearer ${zenttoToken}` } : {},
          });
          if (!res.ok) return [];
          const data = await res.json();
          return (data.data || data || []).map((r: any) => ({
            id: r.id || r.templateId,
            name: r.name || r.layout?.name || "Untitled",
            updatedAt: r.updatedAt || r.savedAt,
          }));
        } catch { return []; }
      },
      load: async (id: string) => {
        try {
          const res = await fetch(`/api/v1/reportes/saved/${id}`, {
            headers: zenttoToken ? { Authorization: `Bearer ${zenttoToken}` } : {},
          });
          if (!res.ok) return null;
          const data = await res.json();
          return { layout: data.layout, sampleData: data.sampleData };
        } catch { return null; }
      },
      save: async (id: string, layoutData: any, sampleDataVal?: any) => {
        await fetch(`/api/v1/reportes/saved/${id}`, {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            ...(zenttoToken ? { Authorization: `Bearer ${zenttoToken}` } : {}),
          },
          body: JSON.stringify({ layout: layoutData, sampleData: sampleDataVal }),
        });
      },
      delete: async (id: string) => {
        await fetch(`/api/v1/reportes/saved/${id}`, {
          method: "DELETE",
          headers: zenttoToken ? { Authorization: `Bearer ${zenttoToken}` } : {},
        });
      },
    };

    // Listen for sample data updates from DB connector
    const onSampleData = (e: CustomEvent) => {
      if (e.detail?.sampleData) {
        setSampleData((prev: any) => ({ ...prev, ...e.detail.sampleData }));
      }
    };
    el.addEventListener("sample-data-update", onSampleData);

    const onLayoutChange = (e: CustomEvent) => {
      setLayout(e.detail.layout);
      markModified();
    };
    const onSave = () => {
      setLastSaveTime(new Date());
      notify("Layout guardado en designer");
    };

    el.addEventListener("layout-change", onLayoutChange);
    el.addEventListener("save", onSave);
    return () => {
      el.removeEventListener("layout-change", onLayoutChange);
      el.removeEventListener("save", onSave);
      el.removeEventListener("sample-data-update", onSampleData);
    };
  }, [registered, mode, sampleData, markModified, notify]);

  // ── Bind data to viewer ──
  useEffect(() => {
    if (!registered || mode !== "viewer") return;
    const el = viewerRef.current;
    if (!el) return;

    el.layout = layout;
    el.data = sampleData;
  }, [registered, mode, layout, sampleData]);

  // ── Bind data to split viewer ──
  useEffect(() => {
    if (!registered || mode !== "split") return;
    const el = splitViewerRef.current;
    if (!el) return;

    el.layout = layout;
    el.data = sampleData;
  }, [registered, mode, layout, sampleData]);

  // ── Sync zoom to viewer ──
  useEffect(() => {
    if (mode === "viewer" && viewerRef.current) {
      viewerRef.current.zoom = zoom;
    }
    if (mode === "split" && splitViewerRef.current) {
      splitViewerRef.current.zoom = zoom;
    }
  }, [zoom, mode]);

  // ═══════════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  const handleNewBlank = useCallback(() => {
    const blank = createBlankLayout ? createBlankLayout() : DEFAULT_BLANK_LAYOUT;
    setLayout(blank);
    setSampleData({});
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
    setLastSaveTime(null);
    notify("Nuevo reporte en blanco creado");
  }, [notify]);

  const handleNewFromTemplate = useCallback(() => {
    setNewMenuAnchor(null);
    setTemplateDialogOpen(true);
  }, []);

  // ── Wizard: open ──
  const handleOpenWizard = useCallback(() => {
    setNewMenuAnchor(null);
    setWizardTab(0);
    setDsMode("none");
    setApiEndpointId(null);
    setApiFields([]);
    setApiSampleRows([]);
    setFileFields([]);
    setFileSampleRows([]);
    setFileSourceName("");
    setManualFields([{ name: "", label: "", type: "string" }]);
    setWizardOpen(true);
  }, []);

  // ── Wizard: fetch API endpoint ──
  const handleApiFetch = useCallback(async (endpointId: string) => {
    setApiEndpointId(endpointId);
    const ep = ZENTTO_API_ENDPOINTS.find((e) => e.id === endpointId);
    if (!ep) return;
    setApiLoading(true);
    setApiFields([]);
    setApiSampleRows([]);
    try {
      const resp = await fetch(`${ep.endpoint}?page=1&limit=5`);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const json = await resp.json();
      const rows: Record<string, any>[] = Array.isArray(json) ? json : (json.data ?? json.items ?? json.rows ?? []);
      if (rows.length > 0) {
        setApiFields(inferFieldsFromData(rows));
        setApiSampleRows(rows.slice(0, 5));
      } else {
        setApiFields([]);
        notify("El endpoint no devolvio datos", "warning");
      }
    } catch (err: any) {
      notify(`Error al consultar API: ${err.message}`, "error");
    } finally {
      setApiLoading(false);
    }
  }, [notify]);

  // ── Wizard: parse uploaded file ──
  const handleDataFileUpload = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileSourceName(file.name);
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      try {
        if (file.name.endsWith(".json")) {
          const parsed = JSON.parse(text);
          const rows: Record<string, any>[] = Array.isArray(parsed) ? parsed : (parsed.data ?? parsed.items ?? [parsed]);
          if (rows.length > 0 && typeof rows[0] === "object") {
            setFileFields(inferFieldsFromData(rows));
            setFileSampleRows(rows.slice(0, 10));
          } else {
            notify("El JSON no contiene objetos validos", "warning");
          }
        } else {
          // CSV
          const { fields, rows } = parseCSV(text);
          if (fields.length > 0) {
            setFileFields(fields.map((f) => ({
              name: f,
              label: f.charAt(0).toUpperCase() + f.slice(1),
              type: detectFieldType(rows.map((r) => r[f])),
            })));
            setFileSampleRows(rows.slice(0, 10));
          } else {
            notify("No se detectaron campos en el CSV", "warning");
          }
        }
      } catch {
        notify("Error al parsear el archivo", "error");
      }
    };
    reader.readAsText(file);
    e.target.value = "";
  }, [notify]);

  // ── Wizard: create report with chosen data source ──
  const handleWizardCreate = useCallback((fields: { name: string; label: string; type: string }[], sampleRows: Record<string, any>[], sourceName?: string) => {
    const blank = createBlankLayout ? createBlankLayout() : { ...DEFAULT_BLANK_LAYOUT };
    if (fields.length > 0) {
      blank.dataSources = [
        {
          id: "data",
          name: sourceName || "Datos",
          type: "array",
          fields: fields.map((f) => ({ name: f.name, label: f.label, type: f.type as "string" | "number" | "boolean" | "date" | "currency" | "image" })),
        },
      ];
    }
    setLayout(blank);
    setSampleData(sampleRows.length > 0 ? { data: sampleRows } : {});
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
    setLastSaveTime(null);
    setWizardOpen(false);
    notify(fields.length > 0
      ? `Reporte creado con ${fields.length} campos desde ${sourceName || "data source"}`
      : "Nuevo reporte en blanco creado");
  }, [notify]);

  const handleSelectTemplate = useCallback((template: TemplateEntry) => {
    setLayout(template.layout);
    setSampleData(template.data);
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
    setLastSaveTime(null);
    setTemplateDialogOpen(false);
    notify(`Plantilla "${template.name}" cargada`);
  }, [notify]);

  const handleOpenFile = useCallback(async () => {
    const result = await openFilePicker();
    if (result) {
      try {
        const parsed = JSON.parse(result.content) as ReportLayout;
        if (parsed.version && parsed.bands) {
          setLayout(parsed);
          setFileName(result.name);
          setFileHandle(result.handle);
          setIsModified(false);
          setLastSaveTime(null);
          notify(`Archivo "${result.name}" abierto`);
          return;
        }
        notify("El archivo no tiene un formato de ReportLayout valido", "error");
      } catch {
        notify("Error al parsear el archivo JSON", "error");
      }
    } else {
      // Fallback: trigger hidden file input
      fileInputRef.current?.click();
    }
  }, [notify]);

  const handleFileInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const parsed = JSON.parse(ev.target?.result as string) as ReportLayout;
        if (parsed.version && parsed.bands) {
          setLayout(parsed);
          setFileName(file.name);
          setFileHandle(null);
          setIsModified(false);
          setLastSaveTime(null);
          notify(`Archivo "${file.name}" abierto`);
        } else {
          notify("El archivo no tiene un formato de ReportLayout valido", "error");
        }
      } catch {
        notify("Error al parsear el archivo JSON", "error");
      }
    };
    reader.readAsText(file);
    e.target.value = "";
  }, [notify]);

  const handleSave = useCallback(async () => {
    const json = JSON.stringify(layout, null, 2);
    if (fileHandle) {
      const ok = await saveToFileHandle(fileHandle, json);
      if (ok) {
        setIsModified(false);
        setLastSaveTime(new Date());
        clearAutosave();
        notify("Archivo guardado");
        return;
      }
    }
    // No handle — do Save As
    await handleSaveAs();
  }, [layout, fileHandle, clearAutosave, notify]);

  const handleSaveAs = useCallback(async () => {
    const json = JSON.stringify(layout, null, 2);
    const suggestedName = `${safeFileName(layout.name)}.report.json`;
    const handle = await showSaveFilePicker(suggestedName);
    if (handle) {
      const ok = await saveToFileHandle(handle, json);
      if (ok) {
        const file = await handle.getFile();
        setFileName(file.name);
        setFileHandle(handle);
        setIsModified(false);
        setLastSaveTime(new Date());
        clearAutosave();
        notify(`Guardado como "${file.name}"`);
        return;
      }
    }
    // Fallback: download
    downloadAsFile(json, suggestedName);
    setIsModified(false);
    setLastSaveTime(new Date());
    clearAutosave();
    notify("Archivo descargado");
  }, [layout, clearAutosave, notify]);

  // ═══════════════════════════════════════════════════════════════════
  // EXPORT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  const generateFullHtml = useCallback((): string | null => {
    if (renderToFullHtml) {
      try {
        return renderToFullHtml(layout, sampleData);
      } catch (err) {
        console.error("renderToFullHtml failed:", err);
      }
    }
    // Fallback: basic HTML with layout JSON embedded
    return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>${layout.name || "Reporte Zentto"}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
    .report-meta { color: #666; font-size: 12px; margin-bottom: 16px; }
  </style>
</head>
<body>
  <div class="report-meta">
    <strong>${layout.name || "Reporte"}</strong> |
    ${layout.pageSize.width}x${layout.pageSize.height} ${layout.pageSize.unit} |
    ${countElements(layout)} elementos | ${layout.bands?.length ?? 0} bandas
  </div>
  <p>Este reporte requiere el visor Zentto para renderizarse completamente.</p>
  <script>window.__ZENTTO_LAYOUT__ = ${JSON.stringify(layout)};</script>
  <script>window.__ZENTTO_DATA__ = ${JSON.stringify(sampleData)};</script>
</body>
</html>`;
  }, [layout, sampleData]);

  const handleExportPdf = useCallback(async () => {
    // Try Python PDF service
    try {
      const html = generateFullHtml();
      if (!html) {
        notify("No se pudo generar HTML para el PDF", "error");
        return;
      }
      const resp = await fetch("/api/v1/reportes/render", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ html, layout, data: sampleData }),
      });
      if (resp.ok) {
        const blob = await resp.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${safeFileName(layout.name)}.pdf`;
        a.click();
        URL.revokeObjectURL(url);
        notify("PDF exportado exitosamente");
        return;
      }
    } catch {
      // PDF service not available — fall through to print
    }
    // Fallback: window.print with print-optimized CSS
    handlePrint();
    notify("Servicio PDF no disponible. Usa Imprimir > Guardar como PDF", "info");
  }, [layout, sampleData, generateFullHtml, notify]);

  const handleExportHtml = useCallback(() => {
    const html = generateFullHtml();
    if (!html) {
      notify("No se pudo generar el HTML", "error");
      return;
    }
    downloadAsFile(html, `${safeFileName(layout.name)}.html`, "text/html");
    notify("HTML exportado");
  }, [layout, generateFullHtml, notify]);

  const handlePrint = useCallback(() => {
    const html = generateFullHtml();
    if (!html) {
      window.print();
      return;
    }

    // Create or reuse hidden iframe
    if (!printIframeRef.current) {
      const iframe = document.createElement("iframe");
      iframe.style.position = "fixed";
      iframe.style.left = "-9999px";
      iframe.style.top = "-9999px";
      iframe.style.width = "0";
      iframe.style.height = "0";
      iframe.style.border = "none";
      document.body.appendChild(iframe);
      printIframeRef.current = iframe;
    }

    const iframe = printIframeRef.current;
    const doc = iframe.contentDocument || iframe.contentWindow?.document;
    if (!doc) {
      window.print();
      return;
    }

    doc.open();
    doc.write(html);
    doc.close();

    // Wait for content to load then print
    setTimeout(() => {
      try {
        iframe.contentWindow?.print();
      } catch {
        window.print();
      }
    }, 500);
  }, [generateFullHtml]);

  // ── Discard recovery ──
  const handleDiscardRecovery = useCallback(() => {
    setRecoverySnackbar(false);
    clearAutosave();
    setLayout(CORE_TEMPLATES[0]?.layout || DEFAULT_BLANK_LAYOUT);
    setSampleData(CORE_TEMPLATES[0]?.sampleData || {});
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
  }, [clearAutosave]);

  // ═══════════════════════════════════════════════════════════════════
  // STORE — fetch saved reports + actions
  // ═══════════════════════════════════════════════════════════════════

  const fetchSavedReports = useCallback(async () => {
    setSavedReportsLoading(true);
    try {
      const resp = await fetch("/api/v1/reportes/saved");
      if (resp.ok) {
        const json = await resp.json();
        setSavedReports(json.data || []);
      }
    } catch {
      // Cache service not available
    } finally {
      setSavedReportsLoading(false);
    }
  }, []);

  const fetchPublicReports = useCallback(async () => {
    setPublicReportsLoading(true);
    try {
      const resp = await fetch("/api/v1/reportes/public");
      if (resp.ok) {
        const json = await resp.json();
        setPublicReports(json.data || []);
      }
    } catch {
      // Cache service not available
    } finally {
      setPublicReportsLoading(false);
    }
  }, []);

  // Fetch saved + public reports when entering store mode
  useEffect(() => {
    if (mode === "store") {
      fetchSavedReports();
      fetchPublicReports();
    }
  }, [mode, fetchSavedReports, fetchPublicReports]);

  const handleStoreUseTemplate = useCallback((tmpl: TemplateEntry) => {
    setLayout(tmpl.layout);
    setSampleData(tmpl.data);
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
    setLastSaveTime(null);
    setMode("designer");
    notify(`Plantilla "${tmpl.name}" cargada en el diseñador`);
  }, [notify]);

  const handleStorePreview = useCallback((tmpl: TemplateEntry) => {
    setPreviewLayout(tmpl.layout);
    setPreviewData(tmpl.data);
    setPreviewTitle(tmpl.name);
    setPreviewOpen(true);
  }, []);

  const handleStoreDownload = useCallback((tmpl: TemplateEntry) => {
    const json = JSON.stringify(tmpl.layout, null, 2);
    downloadAsFile(json, `${safeFileName(tmpl.layout.name)}.report.json`);
    notify(`"${tmpl.name}" descargado`);
  }, [notify]);

  const handleStoreLoadSaved = useCallback(async (report: { id: string; name: string }) => {
    try {
      const resp = await fetch(`/api/v1/reportes/saved/${report.id}`);
      if (!resp.ok) { notify("Error al cargar el reporte", "error"); return; }
      const json = await resp.json();
      if (json.layout) {
        setLayout(json.layout);
        setSampleData(json.sampleData || {});
        setFileName(report.name);
        setFileHandle(null);
        setIsModified(false);
        setLastSaveTime(null);
        setMode("designer");
        notify(`Reporte "${report.name}" cargado`);
      }
    } catch {
      notify("Error de conexión al cargar el reporte", "error");
    }
  }, [notify]);

  const handleStorePreviewSaved = useCallback(async (report: { id: string; name: string }) => {
    try {
      const resp = await fetch(`/api/v1/reportes/saved/${report.id}`);
      if (!resp.ok) return;
      const json = await resp.json();
      if (json.layout) {
        setPreviewLayout(json.layout);
        setPreviewData(json.sampleData || {});
        setPreviewTitle(report.name);
        setPreviewOpen(true);
      }
    } catch { /* ignore */ }
  }, []);

  const handleStoreDownloadSaved = useCallback(async (report: { id: string; name: string }) => {
    try {
      const resp = await fetch(`/api/v1/reportes/saved/${report.id}`);
      if (!resp.ok) return;
      const json = await resp.json();
      if (json.layout) {
        downloadAsFile(JSON.stringify(json.layout, null, 2), `${safeFileName(report.name)}.report.json`);
        notify(`"${report.name}" descargado`);
      }
    } catch { /* ignore */ }
  }, [notify]);

  // ── Store: compute filtered templates ──
  const filteredTemplates = useMemo(() => {
    let list = TEMPLATES;
    if (storeCategory !== "all") {
      list = list.filter((t) => t.category === storeCategory);
    }
    if (storeSearch.trim()) {
      const q = storeSearch.toLowerCase();
      list = list.filter((t) =>
        t.name.toLowerCase().includes(q) ||
        t.description.toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q)
      );
    }
    return list;
  }, [storeSearch, storeCategory]);

  const filteredSavedReports = useMemo(() => {
    if (!storeSearch.trim()) return savedReports;
    const q = storeSearch.toLowerCase();
    return savedReports.filter((r) => r.name.toLowerCase().includes(q));
  }, [storeSearch, savedReports]);

  // ═══════════════════════════════════════════════════════════════════
  // RENDER
  // ═══════════════════════════════════════════════════════════════════

  const CATEGORY_ORDER: string[] = ["Reportes", "Etiquetas", "Tarjetas", "Recibos", "Sobres"];

  return (
    <Box sx={{ height: "100vh", display: "flex", flexDirection: "column", overflow: "hidden", bgcolor: "#fafafa" }}>
      {/* ════════════════════════════════════════════════════════════ */}
      {/* APP BAR / TOOLBAR                                          */}
      {/* ════════════════════════════════════════════════════════════ */}
      <AppBar
        position="static"
        elevation={1}
        sx={{ bgcolor: "background.paper", color: "text.primary", borderBottom: "1px solid", borderColor: "divider" }}
      >
        <Toolbar variant="dense" sx={{ gap: 0.5, minHeight: 48, px: "12px !important" }}>
          {/* ── Back to Store (visible in designer/viewer/split) ── */}
          {mode !== "store" && (
            <Tooltip title="Volver al Store" arrow>
              <Button
                size="small"
                variant="outlined"
                startIcon={<StoreIcon sx={{ fontSize: 16 }} />}
                onClick={() => setMode("store")}
                sx={{
                  textTransform: "none", fontSize: 12, fontWeight: 700, mr: 1,
                  borderColor: "#1a237e", color: "#1a237e",
                  "&:hover": { bgcolor: "#1a237e", color: "#fff", borderColor: "#1a237e" },
                }}
              >
                Store
              </Button>
            </Tooltip>
          )}

          {/* ── File group (hidden in store mode) ── */}
          {mode !== "store" && (
            <>
              <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

              <Tooltip title="Nuevo (Ctrl+N)" arrow>
                <IconButton
                  size="small"
                  onClick={handleOpenWizard}
                  sx={{ borderRadius: 1 }}
                >
                  <NewIcon fontSize="small" />
                </IconButton>
              </Tooltip>

              <Tooltip title="Abrir archivo (Ctrl+O)" arrow>
                <IconButton size="small" onClick={handleOpenFile} sx={{ borderRadius: 1 }}>
                  <OpenIcon fontSize="small" />
                </IconButton>
              </Tooltip>

              <Tooltip title="Guardar (Ctrl+S)" arrow>
                <span>
                  <IconButton
                    size="small"
                    onClick={handleSave}
                    disabled={!isModified}
                    sx={{ borderRadius: 1 }}
                  >
                    <SaveIcon fontSize="small" />
                  </IconButton>
                </span>
              </Tooltip>

              <Tooltip title="Guardar como (Ctrl+Shift+S)" arrow>
                <IconButton size="small" onClick={handleSaveAs} sx={{ borderRadius: 1 }}>
                  <SaveAsIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </>
          )}

          {/* ── Export group (hidden in store mode) ── */}
          {mode !== "store" && (
            <>
              <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

              <Tooltip title="Exportar PDF (Ctrl+E)" arrow>
                <IconButton size="small" onClick={handleExportPdf} sx={{ borderRadius: 1, color: "#d32f2f" }}>
                  <PdfIcon fontSize="small" />
                </IconButton>
              </Tooltip>

              <Tooltip title="Exportar HTML (Ctrl+Shift+E)" arrow>
                <IconButton size="small" onClick={handleExportHtml} sx={{ borderRadius: 1, color: "#1565c0" }}>
                  <HtmlIcon fontSize="small" />
                </IconButton>
              </Tooltip>

              <Tooltip title="Imprimir (Ctrl+P)" arrow>
                <IconButton size="small" onClick={handlePrint} sx={{ borderRadius: 1 }}>
                  <PrintIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </>
          )}

          <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

          {/* ── Mode group ── */}
          <ButtonGroup size="small" variant="outlined" sx={{ "& .MuiButton-root": { textTransform: "none", fontSize: 12, px: 1.5, py: 0.5 } }}>
            <Button
              variant={mode === "designer" ? "contained" : "outlined"}
              startIcon={<DesignIcon sx={{ fontSize: 16 }} />}
              onClick={() => setMode("designer")}
            >
              Designer
            </Button>
            <Button
              variant={mode === "viewer" ? "contained" : "outlined"}
              startIcon={<ViewIcon sx={{ fontSize: 16 }} />}
              onClick={() => setMode("viewer")}
            >
              Viewer
            </Button>
            <Button
              variant={mode === "split" ? "contained" : "outlined"}
              startIcon={<SplitIcon sx={{ fontSize: 16 }} />}
              onClick={() => setMode("split")}
            >
              Split
            </Button>
          </ButtonGroup>

          <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

          {/* ── Zoom controls (visible in viewer/split) ── */}
          {(mode === "viewer" || mode === "split") && (
            <Box sx={{ display: "flex", alignItems: "center", gap: 0.25 }}>
              <Tooltip title="Reducir zoom" arrow>
                <IconButton size="small" onClick={() => setZoom((z) => Math.max(25, z - 10))} sx={{ borderRadius: 1 }}>
                  <ZoomOutIcon sx={{ fontSize: 18 }} />
                </IconButton>
              </Tooltip>
              <Chip
                label={`${zoom}%`}
                size="small"
                variant="outlined"
                sx={{ height: 24, fontSize: 11, minWidth: 48 }}
                onClick={() => setZoom(100)}
              />
              <Tooltip title="Aumentar zoom" arrow>
                <IconButton size="small" onClick={() => setZoom((z) => Math.min(300, z + 10))} sx={{ borderRadius: 1 }}>
                  <ZoomInIcon sx={{ fontSize: 18 }} />
                </IconButton>
              </Tooltip>
            </Box>
          )}

          <Box sx={{ flex: 1 }} />

          {/* ── Title display ── */}
          <Typography
            variant="body2"
            sx={{
              fontWeight: 600,
              fontSize: 13,
              color: isModified ? "warning.main" : "text.primary",
              maxWidth: 300,
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {displayTitle}
          </Typography>

          <Chip label="Zentto Report Studio" size="small" variant="outlined" sx={{ height: 22, fontSize: 10, ml: 1 }} />
        </Toolbar>
      </AppBar>

      {/* ════════════════════════════════════════════════════════════ */}
      {/* MAIN CONTENT                                               */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Box sx={{ flex: 1, display: "flex", overflow: "hidden" }}>
        {!registered ? (
          <Box sx={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <CircularProgress size={32} sx={{ mr: 2 }} />
            <Typography color="text.secondary">Cargando componentes web...</Typography>
          </Box>
        ) : (
          <>
            {/* ── Store mode ── */}
            {mode === "store" && (
              <Box sx={{ flex: 1, overflow: "auto", bgcolor: "#f5f5f5" }}>
                {/* ── Store Header ── */}
                <Box
                  sx={{
                    px: 4, pt: 4, pb: 3,
                    background: "linear-gradient(135deg, #1a237e 0%, #283593 50%, #3949ab 100%)",
                    color: "#fff",
                  }}
                >
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 1 }}>
                    <StoreIcon sx={{ fontSize: 28 }} />
                    <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: -0.5 }}>
                      Report Store
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ opacity: 0.85, mb: 2.5, maxWidth: 500 }}>
                    Plantillas profesionales listas para usar. Explora, previsualiza y descarga reportes para tu negocio.
                  </Typography>

                  {/* Search + Filter bar */}
                  <Box sx={{ display: "flex", gap: 2, alignItems: "center", flexWrap: "wrap" }}>
                    <TextField
                      size="small"
                      placeholder="Buscar reportes..."
                      value={storeSearch}
                      onChange={(e) => setStoreSearch(e.target.value)}
                      sx={{
                        minWidth: 300, bgcolor: "rgba(255,255,255,0.15)", borderRadius: 1,
                        "& .MuiOutlinedInput-root": {
                          color: "#fff",
                          "& fieldset": { borderColor: "rgba(255,255,255,0.3)" },
                          "&:hover fieldset": { borderColor: "rgba(255,255,255,0.5)" },
                          "&.Mui-focused fieldset": { borderColor: "#fff" },
                        },
                        "& .MuiInputAdornment-root": { color: "rgba(255,255,255,0.7)" },
                      }}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment>
                        ),
                      }}
                    />

                    <Box sx={{ display: "flex", gap: 0.5, flexWrap: "wrap" }}>
                      {[
                        { key: "all", label: "Todos" },
                        ...CATEGORY_ORDER.map((c) => ({ key: c, label: c })),
                      ].map((cat) => (
                        <Chip
                          key={cat.key}
                          label={cat.label}
                          size="small"
                          onClick={() => setStoreCategory(cat.key)}
                          sx={{
                            fontWeight: 600, fontSize: 11, height: 28,
                            bgcolor: storeCategory === cat.key ? "rgba(255,255,255,0.95)" : "rgba(255,255,255,0.15)",
                            color: storeCategory === cat.key ? "#1a237e" : "#fff",
                            "&:hover": { bgcolor: storeCategory === cat.key ? "#fff" : "rgba(255,255,255,0.25)" },
                            cursor: "pointer",
                          }}
                        />
                      ))}
                    </Box>
                  </Box>
                </Box>

                <Box sx={{ px: 4, py: 3 }}>
                  {/* ── Built-in Templates Section ── */}
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2 }}>
                    <CategoryIcon sx={{ fontSize: 20, color: "text.secondary" }} />
                    <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                      Plantillas del Sistema
                    </Typography>
                    <Chip label={filteredTemplates.length} size="small" sx={{ height: 20, fontSize: 10, fontWeight: 700 }} />
                  </Box>

                  {filteredTemplates.length === 0 ? (
                    <Paper variant="outlined" sx={{ p: 4, textAlign: "center", mb: 4, borderStyle: "dashed" }}>
                      <SearchIcon sx={{ fontSize: 40, color: "text.disabled", mb: 1 }} />
                      <Typography color="text.secondary">No se encontraron plantillas con ese filtro</Typography>
                    </Paper>
                  ) : (
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 2.5, mb: 4 }}>
                      {filteredTemplates.map((t) => (
                        <Fade in key={t.id}>
                          <Card
                            variant="outlined"
                            sx={{
                              transition: "all 0.2s ease",
                              "&:hover": {
                                borderColor: t.color,
                                boxShadow: `0 4px 20px ${t.color}25`,
                                transform: "translateY(-2px)",
                              },
                              display: "flex",
                              flexDirection: "column",
                            }}
                          >
                            {/* Preview area */}
                            <Box
                              sx={{
                                height: 140,
                                bgcolor: `${t.color}08`,
                                borderBottom: "1px solid",
                                borderColor: "divider",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                position: "relative",
                                overflow: "hidden",
                                cursor: "pointer",
                              }}
                              onClick={() => handleStorePreview(t)}
                            >
                              <Box sx={{ color: t.color, opacity: 0.15, transform: "scale(5)", position: "absolute" }}>
                                {t.icon}
                              </Box>
                              <Box sx={{ color: t.color, opacity: 0.8, transform: "scale(2.5)", zIndex: 1 }}>
                                {t.icon}
                              </Box>
                              {/* Hover overlay */}
                              <Box
                                sx={{
                                  position: "absolute", inset: 0,
                                  bgcolor: "rgba(0,0,0,0.5)",
                                  display: "flex", alignItems: "center", justifyContent: "center",
                                  opacity: 0,
                                  transition: "opacity 0.2s",
                                  "&:hover": { opacity: 1 },
                                }}
                              >
                                <Chip
                                  icon={<ViewIcon sx={{ fontSize: 14, color: "#fff !important" }} />}
                                  label="Vista previa"
                                  size="small"
                                  sx={{ bgcolor: "rgba(255,255,255,0.2)", color: "#fff", fontWeight: 600, fontSize: 11, backdropFilter: "blur(4px)" }}
                                />
                              </Box>
                            </Box>

                            <CardContent sx={{ py: 1.5, px: 2, flex: 1, display: "flex", flexDirection: "column" }}>
                              <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: 13, lineHeight: 1.3, mb: 0.5 }}>
                                {t.name}
                              </Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: "block", lineHeight: 1.4, mb: 1, flex: 1 }}>
                                {t.description}
                              </Typography>

                              {/* Metadata chips */}
                              <Box sx={{ display: "flex", gap: 0.5, mb: 1.5, flexWrap: "wrap" }}>
                                <Chip label={t.category} size="small" variant="outlined" sx={{ height: 20, fontSize: 10, fontWeight: 600 }} />
                                <Chip label={`${t.layout.pageSize.width}x${t.layout.pageSize.height} ${t.layout.pageSize.unit}`} size="small" variant="outlined" sx={{ height: 20, fontSize: 10 }} />
                                <Chip label={`${countElements(t.layout)} elem.`} size="small" variant="outlined" sx={{ height: 20, fontSize: 10 }} />
                              </Box>

                              {/* Actions */}
                              <Box sx={{ display: "flex", gap: 1 }}>
                                <Button
                                  size="small"
                                  variant="contained"
                                  startIcon={<DesignIcon sx={{ fontSize: 14 }} />}
                                  onClick={() => handleStoreUseTemplate(t)}
                                  sx={{ textTransform: "none", fontSize: 11, flex: 1, fontWeight: 600 }}
                                >
                                  Usar
                                </Button>
                                <Tooltip title="Vista previa" arrow>
                                  <IconButton size="small" onClick={() => handleStorePreview(t)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <ViewIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                                <Tooltip title="Descargar .report.json" arrow>
                                  <IconButton size="small" onClick={() => handleStoreDownload(t)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <DownloadIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </CardContent>
                          </Card>
                        </Fade>
                      ))}
                    </Box>
                  )}

                  {/* ── Saved Reports Section ── */}
                  <Divider sx={{ mb: 3 }} />
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2 }}>
                    <PersonIcon sx={{ fontSize: 20, color: "text.secondary" }} />
                    <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                      Mis Reportes Guardados
                    </Typography>
                    {!savedReportsLoading && (
                      <Chip label={filteredSavedReports.length} size="small" sx={{ height: 20, fontSize: 10, fontWeight: 700 }} />
                    )}
                    <Box sx={{ flex: 1 }} />
                    <Tooltip title="Recargar" arrow>
                      <IconButton size="small" onClick={fetchSavedReports} disabled={savedReportsLoading}>
                        <OpenInNewIcon sx={{ fontSize: 16 }} />
                      </IconButton>
                    </Tooltip>
                  </Box>

                  {savedReportsLoading ? (
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 2.5, mb: 3 }}>
                      {[1, 2, 3].map((i) => (
                        <Card key={i} variant="outlined">
                          <Skeleton variant="rectangular" height={100} />
                          <CardContent>
                            <Skeleton width="60%" height={20} />
                            <Skeleton width="40%" height={16} sx={{ mt: 0.5 }} />
                          </CardContent>
                        </Card>
                      ))}
                    </Box>
                  ) : filteredSavedReports.length === 0 ? (
                    <Paper variant="outlined" sx={{ p: 4, textAlign: "center", mb: 4, borderStyle: "dashed" }}>
                      <SaveIcon sx={{ fontSize: 40, color: "text.disabled", mb: 1 }} />
                      <Typography color="text.secondary" sx={{ mb: 1 }}>
                        {savedReports.length === 0
                          ? "No tienes reportes guardados aun"
                          : "No se encontraron reportes con ese filtro"}
                      </Typography>
                      <Typography variant="caption" color="text.disabled">
                        Los reportes que guardes desde el Designer apareceran aqui
                      </Typography>
                    </Paper>
                  ) : (
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 2.5, mb: 3 }}>
                      {filteredSavedReports.map((r) => (
                        <Fade in key={r.id}>
                          <Card
                            variant="outlined"
                            sx={{
                              transition: "all 0.2s ease",
                              "&:hover": {
                                borderColor: "primary.main",
                                boxShadow: "0 4px 20px rgba(25,118,210,0.15)",
                                transform: "translateY(-2px)",
                              },
                            }}
                          >
                            {/* Saved report header */}
                            <Box
                              sx={{
                                height: 80,
                                bgcolor: "#e3f2fd",
                                borderBottom: "1px solid",
                                borderColor: "divider",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                cursor: "pointer",
                                position: "relative",
                              }}
                              onClick={() => handleStorePreviewSaved(r)}
                            >
                              <TemplateIcon sx={{ fontSize: 32, color: "#1565c0", opacity: 0.6 }} />
                              <Box
                                sx={{
                                  position: "absolute", inset: 0,
                                  bgcolor: "rgba(0,0,0,0.4)",
                                  display: "flex", alignItems: "center", justifyContent: "center",
                                  opacity: 0, transition: "opacity 0.2s",
                                  "&:hover": { opacity: 1 },
                                }}
                              >
                                <Chip
                                  icon={<ViewIcon sx={{ fontSize: 14, color: "#fff !important" }} />}
                                  label="Vista previa"
                                  size="small"
                                  sx={{ bgcolor: "rgba(255,255,255,0.2)", color: "#fff", fontWeight: 600, fontSize: 11, backdropFilter: "blur(4px)" }}
                                />
                              </Box>
                            </Box>

                            <CardContent sx={{ py: 1.5, px: 2 }}>
                              <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: 13, mb: 0.5 }}>
                                {r.name}
                              </Typography>
                              {r.updatedAt && (
                                <Typography variant="caption" color="text.secondary" sx={{ display: "block", mb: 1.5, fontSize: 10 }}>
                                  Actualizado: {new Date(r.updatedAt).toLocaleDateString("es-VE", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}
                                </Typography>
                              )}

                              <Box sx={{ display: "flex", gap: 1 }}>
                                <Button
                                  size="small"
                                  variant="contained"
                                  startIcon={<DesignIcon sx={{ fontSize: 14 }} />}
                                  onClick={() => handleStoreLoadSaved(r)}
                                  sx={{ textTransform: "none", fontSize: 11, flex: 1, fontWeight: 600 }}
                                >
                                  Editar
                                </Button>
                                <Tooltip title="Vista previa" arrow>
                                  <IconButton size="small" onClick={() => handleStorePreviewSaved(r)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <ViewIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                                <Tooltip title="Descargar .report.json" arrow>
                                  <IconButton size="small" onClick={() => handleStoreDownloadSaved(r)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <DownloadIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </CardContent>
                          </Card>
                        </Fade>
                      ))}
                    </Box>
                  )}

                  {/* ── Public Reports Section ── */}
                  <Divider sx={{ mb: 3 }} />
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2 }}>
                    <PublicIcon sx={{ fontSize: 20, color: "text.secondary" }} />
                    <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                      Reportes Publicos de la Empresa
                    </Typography>
                    {!publicReportsLoading && (
                      <Chip label={publicReports.length} size="small" sx={{ height: 20, fontSize: 10, fontWeight: 700 }} />
                    )}
                  </Box>

                  {publicReportsLoading ? (
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 2.5, mb: 3 }}>
                      {[1, 2].map((i) => (
                        <Card key={i} variant="outlined">
                          <Skeleton variant="rectangular" height={80} />
                          <CardContent>
                            <Skeleton width="60%" height={20} />
                            <Skeleton width="40%" height={16} sx={{ mt: 0.5 }} />
                          </CardContent>
                        </Card>
                      ))}
                    </Box>
                  ) : publicReports.length === 0 ? (
                    <Paper variant="outlined" sx={{ p: 4, textAlign: "center", mb: 4, borderStyle: "dashed" }}>
                      <PublicIcon sx={{ fontSize: 40, color: "text.disabled", mb: 1 }} />
                      <Typography color="text.secondary" sx={{ mb: 1 }}>
                        No hay reportes publicos de la empresa
                      </Typography>
                      <Typography variant="caption" color="text.disabled">
                        Los administradores pueden publicar reportes para toda la organizacion
                      </Typography>
                    </Paper>
                  ) : (
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 2.5, mb: 3 }}>
                      {publicReports.map((r) => (
                        <Fade in key={r.id}>
                          <Card
                            variant="outlined"
                            sx={{
                              transition: "all 0.2s ease",
                              "&:hover": {
                                borderColor: "#4caf50",
                                boxShadow: "0 4px 20px rgba(76,175,80,0.15)",
                                transform: "translateY(-2px)",
                              },
                            }}
                          >
                            <Box
                              sx={{
                                height: 80,
                                bgcolor: "#e8f5e9",
                                borderBottom: "1px solid",
                                borderColor: "divider",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                cursor: "pointer",
                                position: "relative",
                              }}
                              onClick={() => handleStorePreviewSaved(r)}
                            >
                              <PublicIcon sx={{ fontSize: 32, color: "#2e7d32", opacity: 0.6 }} />
                              <Box
                                sx={{
                                  position: "absolute", inset: 0,
                                  bgcolor: "rgba(0,0,0,0.4)",
                                  display: "flex", alignItems: "center", justifyContent: "center",
                                  opacity: 0, transition: "opacity 0.2s",
                                  "&:hover": { opacity: 1 },
                                }}
                              >
                                <Chip
                                  icon={<ViewIcon sx={{ fontSize: 14, color: "#fff !important" }} />}
                                  label="Vista previa"
                                  size="small"
                                  sx={{ bgcolor: "rgba(255,255,255,0.2)", color: "#fff", fontWeight: 600, fontSize: 11, backdropFilter: "blur(4px)" }}
                                />
                              </Box>
                            </Box>

                            <CardContent sx={{ py: 1.5, px: 2 }}>
                              <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: 13, mb: 0.5 }}>
                                {r.name}
                              </Typography>
                              {r.description && (
                                <Typography variant="caption" color="text.secondary" sx={{ display: "block", mb: 1, lineHeight: 1.3 }}>
                                  {r.description}
                                </Typography>
                              )}
                              {r.updatedAt && (
                                <Typography variant="caption" color="text.secondary" sx={{ display: "block", mb: 1.5, fontSize: 10 }}>
                                  {new Date(r.updatedAt).toLocaleDateString("es-VE", { day: "2-digit", month: "short", year: "numeric" })}
                                </Typography>
                              )}

                              <Box sx={{ display: "flex", gap: 1 }}>
                                <Button
                                  size="small"
                                  variant="contained"
                                  color="success"
                                  startIcon={<DesignIcon sx={{ fontSize: 14 }} />}
                                  onClick={() => handleStoreLoadSaved(r)}
                                  sx={{ textTransform: "none", fontSize: 11, flex: 1, fontWeight: 600 }}
                                >
                                  Usar
                                </Button>
                                <Tooltip title="Vista previa" arrow>
                                  <IconButton size="small" onClick={() => handleStorePreviewSaved(r)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <ViewIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                                <Tooltip title="Descargar" arrow>
                                  <IconButton size="small" onClick={() => handleStoreDownloadSaved(r)} sx={{ border: "1px solid", borderColor: "divider", borderRadius: 1 }}>
                                    <DownloadIcon sx={{ fontSize: 16 }} />
                                  </IconButton>
                                </Tooltip>
                              </Box>
                            </CardContent>
                          </Card>
                        </Fade>
                      ))}
                    </Box>
                  )}
                </Box>
              </Box>
            )}

            {/* ── Designer mode ── */}
            {mode === "designer" && (
              <Box sx={{ flex: 1, overflow: "hidden" }}>
                <zentto-report-designer
                  ref={designerRef}
                  grid-snap={1}
                  auto-save-ms={2000}
                  ai-proxy-url="/api/v1/ai-report"
                  style={{ display: "block", height: "100%" }}
                />
              </Box>
            )}

            {/* ── Viewer mode ── */}
            {mode === "viewer" && (
              <Box sx={{ flex: 1, overflow: "hidden", bgcolor: "#f0f0f0" }}>
                <zentto-report-viewer
                  ref={viewerRef}
                  show-toolbar
                  zoom={zoom}
                  style={{ display: "block", height: "100%" }}
                />
              </Box>
            )}

            {/* ── Split mode ── */}
            {mode === "split" && (
              <Box sx={{ flex: 1, display: "grid", gridTemplateColumns: "1fr 4px 1fr", overflow: "hidden" }}>
                {/* Designer pane */}
                <Box sx={{ overflow: "hidden" }}>
                  <zentto-report-designer
                    ref={designerRef}
                    grid-snap={5}
                    auto-save-ms={2000}
                    style={{ display: "block", height: "100%" }}
                  />
                </Box>

                {/* Resizer handle */}
                <Box
                  sx={{
                    cursor: "col-resize",
                    bgcolor: "divider",
                    "&:hover": { bgcolor: "primary.main", opacity: 0.5 },
                    transition: "background-color 0.15s",
                  }}
                />

                {/* Viewer pane */}
                <Box sx={{ overflow: "hidden", bgcolor: "#f0f0f0" }}>
                  <zentto-report-viewer
                    ref={splitViewerRef}
                    show-toolbar
                    zoom={zoom}
                    style={{ display: "block", height: "100%" }}
                  />
                </Box>
              </Box>
            )}
          </>
        )}
      </Box>

      {/* ════════════════════════════════════════════════════════════ */}
      {/* STATUS BAR (hidden in store mode)                          */}
      {/* ════════════════════════════════════════════════════════════ */}
      {mode !== "store" && <Paper
        elevation={0}
        sx={{
          px: 2,
          py: 0.25,
          display: "flex",
          alignItems: "center",
          gap: 2,
          borderTop: "1px solid",
          borderColor: "divider",
          flexShrink: 0,
          minHeight: 26,
          bgcolor: "grey.50",
        }}
      >
        {/* Left: file name + modified */}
        <Typography variant="caption" sx={{ fontSize: 11, fontWeight: 500, color: isModified ? "warning.main" : "text.secondary" }}>
          {fileName || "Sin titulo"}{isModified ? " *" : ""}
        </Typography>

        <Divider orientation="vertical" flexItem />

        {/* Center: page size */}
        <Typography variant="caption" color="text.secondary" sx={{ fontSize: 11 }}>
          {pageSizeText}
        </Typography>

        <Box sx={{ flex: 1 }} />

        {/* Right: element count, zoom, last saved */}
        <Typography variant="caption" color="text.secondary" sx={{ fontSize: 11 }}>
          {elementCount} elementos | {bandCount} bandas
        </Typography>

        <Divider orientation="vertical" flexItem />

        <Typography variant="caption" color="text.secondary" sx={{ fontSize: 11 }}>
          Zoom: {zoom}%
        </Typography>

        <Divider orientation="vertical" flexItem />

        <Typography variant="caption" color="text.secondary" sx={{ fontSize: 11 }}>
          {lastSaveTime
            ? `Guardado: ${lastSaveTime.toLocaleTimeString("es-VE", { hour: "2-digit", minute: "2-digit", second: "2-digit" })}`
            : "Sin guardar"}
        </Typography>
      </Paper>}

      {/* ════════════════════════════════════════════════════════════ */}
      {/* STORE PREVIEW DIALOG                                       */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Dialog
        open={previewOpen}
        onClose={() => setPreviewOpen(false)}
        maxWidth="lg"
        fullWidth
        PaperProps={{ sx: { maxHeight: "90vh", minHeight: 500 } }}
      >
        <DialogTitle sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", pb: 1 }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <ViewIcon sx={{ color: "primary.main" }} />
            <span style={{ fontWeight: 700, fontSize: "1.1rem" }}>{previewTitle}</span>
          </Box>
          <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
            {previewLayout && (
              <>
                <Button
                  size="small"
                  variant="contained"
                  startIcon={<DesignIcon sx={{ fontSize: 14 }} />}
                  onClick={() => {
                    setLayout(previewLayout);
                    setSampleData(previewData);
                    setFileName(null);
                    setFileHandle(null);
                    setIsModified(false);
                    setMode("designer");
                    setPreviewOpen(false);
                    notify(`"${previewTitle}" cargado en el diseñador`);
                  }}
                  sx={{ textTransform: "none", fontSize: 12, fontWeight: 600 }}
                >
                  Usar en Designer
                </Button>
                <Button
                  size="small"
                  variant="outlined"
                  startIcon={<DownloadIcon sx={{ fontSize: 14 }} />}
                  onClick={() => {
                    downloadAsFile(JSON.stringify(previewLayout, null, 2), `${safeFileName(previewTitle)}.report.json`);
                    notify(`"${previewTitle}" descargado`);
                  }}
                  sx={{ textTransform: "none", fontSize: 12, fontWeight: 600 }}
                >
                  Descargar
                </Button>
              </>
            )}
            <IconButton onClick={() => setPreviewOpen(false)} size="small"><CloseIcon /></IconButton>
          </Box>
        </DialogTitle>
        <DialogContent sx={{ p: 0, bgcolor: "#e0e0e0", overflow: "auto" }}>
          {previewLayout && renderToFullHtml ? (
            <Box sx={{ display: "flex", justifyContent: "center", py: 3, minHeight: 400 }}>
              <Paper
                elevation={4}
                sx={{
                  width: previewLayout.orientation === "landscape" ? "min(95%, 1000px)" : "min(95%, 700px)",
                  bgcolor: "#fff",
                  overflow: "hidden",
                }}
                dangerouslySetInnerHTML={{
                  __html: (() => {
                    try {
                      const full = renderToFullHtml(previewLayout, previewData);
                      // Extract body content from the full HTML
                      const bodyMatch = full.match(/<body[^>]*>([\s\S]*)<\/body>/i);
                      const styleMatch = full.match(/<style[^>]*>([\s\S]*?)<\/style>/gi);
                      const styles = styleMatch ? styleMatch.join("") : "";
                      const body = bodyMatch ? bodyMatch[1] : full;
                      return `${styles}<div style="transform-origin: top center;">${body}</div>`;
                    } catch {
                      return '<div style="padding: 40px; text-align: center; color: #999;">Error al renderizar la vista previa</div>';
                    }
                  })(),
                }}
              />
            </Box>
          ) : (
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: 400 }}>
              <Typography color="text.secondary">Motor de renderizado no disponible</Typography>
            </Box>
          )}
        </DialogContent>
      </Dialog>

      {/* ════════════════════════════════════════════════════════════ */}
      {/* TEMPLATE GALLERY DIALOG (legacy — kept for direct calls)   */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Dialog
        open={templateDialogOpen}
        onClose={() => setTemplateDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{ sx: { maxHeight: "80vh" } }}
      >
        <DialogTitle sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", pb: 1 }}>
          <Box>
            <span style={{ fontWeight: 700, fontSize: "1.1rem" }}>Galeria de Plantillas</span>
            <Typography variant="body2" color="text.secondary">Selecciona una plantilla para crear un nuevo reporte</Typography>
          </Box>
          <IconButton onClick={() => setTemplateDialogOpen(false)} size="small"><CloseIcon /></IconButton>
        </DialogTitle>
        <DialogContent dividers sx={{ p: 3 }}>
          {CATEGORY_ORDER.map((category) => {
            const categoryTemplates = TEMPLATES.filter((t) => t.category === category);
            if (categoryTemplates.length === 0) return null;
            return (
              <Box key={category} sx={{ mb: 3 }}>
                <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 700, color: "text.secondary", textTransform: "uppercase", fontSize: 11, letterSpacing: 1 }}>{category}</Typography>
                <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 2 }}>
                  {categoryTemplates.map((t) => (
                    <Card key={t.id} variant="outlined" sx={{ transition: "all 0.2s", "&:hover": { borderColor: t.color, boxShadow: `0 0 0 1px ${t.color}40` } }}>
                      <CardActionArea onClick={() => handleSelectTemplate(t)} sx={{ height: "100%" }}>
                        <Box sx={{ height: 80, bgcolor: `${t.color}12`, display: "flex", alignItems: "center", justifyContent: "center", borderBottom: "1px solid", borderColor: "divider" }}>
                          <Box sx={{ color: t.color, opacity: 0.7, transform: "scale(2)" }}>{t.icon}</Box>
                        </Box>
                        <CardContent sx={{ py: 1.5, px: 2 }}>
                          <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: 13, lineHeight: 1.3 }}>{t.name}</Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.5, lineHeight: 1.3 }}>{t.description}</Typography>
                          <Box sx={{ display: "flex", gap: 1, mt: 1 }}>
                            <Chip label={`${t.layout.pageSize.width}x${t.layout.pageSize.height} ${t.layout.pageSize.unit}`} size="small" variant="outlined" sx={{ height: 18, fontSize: 10 }} />
                            <Chip label={`${countElements(t.layout)} elem.`} size="small" variant="outlined" sx={{ height: 18, fontSize: 10 }} />
                          </Box>
                        </CardContent>
                      </CardActionArea>
                    </Card>
                  ))}
                </Box>
              </Box>
            );
          })}
        </DialogContent>
      </Dialog>

      {/* ════════════════════════════════════════════════════════════ */}
      {/* NEW REPORT WIZARD DIALOG                                   */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Dialog
        open={wizardOpen}
        onClose={() => setWizardOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{ sx: { maxHeight: "85vh", minHeight: 520 } }}
      >
        <DialogTitle sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", pb: 0 }}>
          <span style={{ fontWeight: 700, fontSize: "1.1rem" }}>Nuevo Reporte</span>
          <IconButton onClick={() => setWizardOpen(false)} size="small"><CloseIcon /></IconButton>
        </DialogTitle>

        <Tabs value={wizardTab} onChange={(_, v) => setWizardTab(v)} sx={{ px: 3, borderBottom: 1, borderColor: "divider" }}>
          <Tab label="Plantillas" sx={{ textTransform: "none", fontWeight: 600 }} />
          <Tab label="En Blanco + Data Source" sx={{ textTransform: "none", fontWeight: 600 }} />
        </Tabs>

        <DialogContent sx={{ p: 0, overflow: "auto" }}>
          {/* ─── Tab 0: Templates ─── */}
          {wizardTab === 0 && (
            <Box sx={{ p: 3 }}>
              {CATEGORY_ORDER.map((category) => {
                const categoryTemplates = TEMPLATES.filter((t) => t.category === category);
                if (categoryTemplates.length === 0) return null;
                return (
                  <Box key={category} sx={{ mb: 3 }}>
                    <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 700, color: "text.secondary", textTransform: "uppercase", fontSize: 11, letterSpacing: 1 }}>{category}</Typography>
                    <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 2 }}>
                      {categoryTemplates.map((t) => (
                        <Card key={t.id} variant="outlined" sx={{ transition: "all 0.2s", "&:hover": { borderColor: t.color, boxShadow: `0 0 0 1px ${t.color}40` } }}>
                          <CardActionArea onClick={() => { handleSelectTemplate(t); setWizardOpen(false); }} sx={{ height: "100%" }}>
                            <Box sx={{ height: 64, bgcolor: `${t.color}12`, display: "flex", alignItems: "center", justifyContent: "center", borderBottom: "1px solid", borderColor: "divider" }}>
                              <Box sx={{ color: t.color, opacity: 0.7, transform: "scale(1.8)" }}>{t.icon}</Box>
                            </Box>
                            <CardContent sx={{ py: 1, px: 1.5 }}>
                              <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: 12, lineHeight: 1.3 }}>{t.name}</Typography>
                              <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.3, lineHeight: 1.2, fontSize: 10 }}>{t.description}</Typography>
                            </CardContent>
                          </CardActionArea>
                        </Card>
                      ))}
                    </Box>
                  </Box>
                );
              })}
            </Box>
          )}

          {/* ─── Tab 1: Blank + Data Source ─── */}
          {wizardTab === 1 && (
            <Box sx={{ p: 3 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Elige como conectar datos a tu reporte en blanco.
              </Typography>

              {/* Data source mode selector */}
              <Box sx={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 1.5, mb: 3 }}>
                {([
                  { mode: "api" as const, icon: <ApiIcon />, label: "Zentto API", desc: "Datos del sistema" },
                  { mode: "file" as const, icon: <UploadFileIcon />, label: "Archivo CSV/JSON", desc: "Subir archivo" },
                  { mode: "manual" as const, icon: <ManualIcon />, label: "Manual", desc: "Definir campos" },
                  { mode: "none" as const, icon: <NoDataIcon />, label: "Sin Datos", desc: "Reporte vacio" },
                ]).map((opt) => (
                  <Card
                    key={opt.mode}
                    variant="outlined"
                    sx={{
                      cursor: "pointer",
                      transition: "all 0.15s",
                      borderColor: dsMode === opt.mode ? "primary.main" : "divider",
                      bgcolor: dsMode === opt.mode ? "primary.50" : "transparent",
                      boxShadow: dsMode === opt.mode ? "0 0 0 2px rgba(25,118,210,0.3)" : "none",
                      "&:hover": { borderColor: "primary.light" },
                    }}
                    onClick={() => setDsMode(opt.mode)}
                  >
                    <CardContent sx={{ textAlign: "center", py: 2, px: 1 }}>
                      <Box sx={{ color: dsMode === opt.mode ? "primary.main" : "text.secondary", mb: 0.5 }}>{opt.icon}</Box>
                      <Typography variant="subtitle2" sx={{ fontSize: 12, fontWeight: 700 }}>{opt.label}</Typography>
                      <Typography variant="caption" color="text.secondary" sx={{ fontSize: 10 }}>{opt.desc}</Typography>
                    </CardContent>
                  </Card>
                ))}
              </Box>

              <Divider sx={{ mb: 2 }} />

              {/* ── API mode ── */}
              {dsMode === "api" && (
                <Box>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700 }}>Selecciona un endpoint:</Typography>
                  <List dense sx={{ bgcolor: "grey.50", borderRadius: 1, mb: 2 }}>
                    {ZENTTO_API_ENDPOINTS.map((ep) => (
                      <ListItem key={ep.id} disablePadding>
                        <ListItemButton
                          selected={apiEndpointId === ep.id}
                          onClick={() => handleApiFetch(ep.id)}
                          sx={{ borderRadius: 1 }}
                        >
                          <ListItemIcon sx={{ minWidth: 36 }}><ApiIcon fontSize="small" color={apiEndpointId === ep.id ? "primary" : "inherit"} /></ListItemIcon>
                          <ListItemText
                            primary={ep.label}
                            secondary={ep.endpoint}
                            primaryTypographyProps={{ fontSize: 13, fontWeight: 600 }}
                            secondaryTypographyProps={{ fontSize: 11, fontFamily: "monospace" }}
                          />
                        </ListItemButton>
                      </ListItem>
                    ))}
                  </List>
                  {apiLoading && <LinearProgress sx={{ mb: 2 }} />}
                  {apiFields.length > 0 && (
                    <Box>
                      <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700 }}>
                        <CheckIcon sx={{ fontSize: 16, color: "success.main", mr: 0.5, verticalAlign: "text-bottom" }} />
                        {apiFields.length} campos detectados:
                      </Typography>
                      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5, mb: 2 }}>
                        {apiFields.map((f) => (
                          <Chip key={f.name} label={`${f.name} (${f.type})`} size="small" variant="outlined" sx={{ height: 22, fontSize: 10 }} />
                        ))}
                      </Box>
                      <Button
                        variant="contained"
                        size="small"
                        onClick={() => {
                          const ep = ZENTTO_API_ENDPOINTS.find((e) => e.id === apiEndpointId);
                          handleWizardCreate(apiFields, apiSampleRows, ep?.label);
                        }}
                      >
                        Crear reporte con estos datos
                      </Button>
                    </Box>
                  )}
                </Box>
              )}

              {/* ── File mode ── */}
              {dsMode === "file" && (
                <Box>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700 }}>Sube un archivo .csv o .json:</Typography>
                  <Button
                    variant="outlined"
                    startIcon={<UploadFileIcon />}
                    onClick={() => dataFileInputRef.current?.click()}
                    sx={{ mb: 2, textTransform: "none" }}
                  >
                    {fileSourceName || "Seleccionar archivo..."}
                  </Button>
                  <input
                    ref={dataFileInputRef}
                    type="file"
                    accept=".csv,.json"
                    style={{ display: "none" }}
                    onChange={handleDataFileUpload}
                  />
                  {fileFields.length > 0 && (
                    <Box>
                      <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700 }}>
                        <CheckIcon sx={{ fontSize: 16, color: "success.main", mr: 0.5, verticalAlign: "text-bottom" }} />
                        {fileFields.length} campos detectados ({fileSampleRows.length} filas de muestra):
                      </Typography>
                      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5, mb: 2 }}>
                        {fileFields.map((f) => (
                          <Chip key={f.name} label={`${f.name} (${f.type})`} size="small" variant="outlined" sx={{ height: 22, fontSize: 10 }} />
                        ))}
                      </Box>
                      <Button
                        variant="contained"
                        size="small"
                        onClick={() => handleWizardCreate(fileFields, fileSampleRows, fileSourceName)}
                      >
                        Crear reporte con estos datos
                      </Button>
                    </Box>
                  )}
                </Box>
              )}

              {/* ── Manual mode ── */}
              {dsMode === "manual" && (
                <Box>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700 }}>Define los campos manualmente:</Typography>
                  {manualFields.map((field, idx) => (
                    <Box key={idx} sx={{ display: "flex", gap: 1, mb: 1, alignItems: "center" }}>
                      <TextField
                        size="small"
                        label="Nombre"
                        value={field.name}
                        onChange={(e) => {
                          const next = [...manualFields];
                          next[idx] = { ...next[idx], name: e.target.value };
                          setManualFields(next);
                        }}
                        sx={{ flex: 1 }}
                        inputProps={{ style: { fontSize: 13 } }}
                        InputLabelProps={{ sx: { fontSize: 13 } }}
                      />
                      <TextField
                        size="small"
                        label="Etiqueta"
                        value={field.label}
                        onChange={(e) => {
                          const next = [...manualFields];
                          next[idx] = { ...next[idx], label: e.target.value };
                          setManualFields(next);
                        }}
                        sx={{ flex: 1 }}
                        inputProps={{ style: { fontSize: 13 } }}
                        InputLabelProps={{ sx: { fontSize: 13 } }}
                      />
                      <FormControl size="small" sx={{ minWidth: 110 }}>
                        <InputLabel sx={{ fontSize: 13 }}>Tipo</InputLabel>
                        <Select
                          value={field.type}
                          label="Tipo"
                          onChange={(e) => {
                            const next = [...manualFields];
                            next[idx] = { ...next[idx], type: e.target.value };
                            setManualFields(next);
                          }}
                          sx={{ fontSize: 13 }}
                          native
                        >
                          <option value="string">string</option>
                          <option value="number">number</option>
                          <option value="date">date</option>
                          <option value="boolean">boolean</option>
                          <option value="currency">currency</option>
                        </Select>
                      </FormControl>
                      <IconButton
                        size="small"
                        onClick={() => {
                          if (manualFields.length > 1) {
                            setManualFields(manualFields.filter((_, i) => i !== idx));
                          }
                        }}
                        disabled={manualFields.length <= 1}
                      >
                        <MinusIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  ))}
                  <Box sx={{ display: "flex", gap: 1, mt: 1 }}>
                    <Button
                      size="small"
                      startIcon={<PlusIcon />}
                      onClick={() => setManualFields([...manualFields, { name: "", label: "", type: "string" }])}
                      sx={{ textTransform: "none" }}
                    >
                      Agregar campo
                    </Button>
                    <Box sx={{ flex: 1 }} />
                    <Button
                      variant="contained"
                      size="small"
                      disabled={manualFields.every((f) => !f.name.trim())}
                      onClick={() => {
                        const validFields = manualFields.filter((f) => f.name.trim());
                        handleWizardCreate(validFields.map((f) => ({
                          name: f.name.trim(),
                          label: f.label.trim() || f.name.trim(),
                          type: f.type,
                        })), [], "Manual");
                      }}
                    >
                      Crear reporte
                    </Button>
                  </Box>
                </Box>
              )}

              {/* ── No data mode ── */}
              {dsMode === "none" && (
                <Box sx={{ textAlign: "center", py: 3 }}>
                  <NoDataIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Se creara un reporte en blanco sin conexion de datos.<br />
                    Puedes agregar data sources despues desde el diseñador.
                  </Typography>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => handleWizardCreate([], [])}
                  >
                    Crear reporte en blanco
                  </Button>
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
      </Dialog>

      {/* ════════════════════════════════════════════════════════════ */}
      {/* HIDDEN FILE INPUT (fallback)                               */}
      {/* ════════════════════════════════════════════════════════════ */}
      <input
        ref={fileInputRef}
        type="file"
        accept=".report.json,.json"
        style={{ display: "none" }}
        onChange={handleFileInputChange}
      />

      {/* ════════════════════════════════════════════════════════════ */}
      {/* SNACKBAR NOTIFICATIONS                                     */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Snackbar
        open={!!snackbar}
        autoHideDuration={4000}
        onClose={() => setSnackbar(null)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity={snackbar?.severity ?? "success"}
          onClose={() => setSnackbar(null)}
          variant="filled"
          sx={{ minWidth: 280 }}
        >
          {snackbar?.message}
        </Alert>
      </Snackbar>

      {/* ── Recovery snackbar ── */}
      <Snackbar
        open={recoverySnackbar}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity="info"
          variant="filled"
          sx={{ minWidth: 320 }}
          action={
            <Box sx={{ display: "flex", gap: 0.5 }}>
              <Button color="inherit" size="small" onClick={() => setRecoverySnackbar(false)}>
                Aceptar
              </Button>
              <Button color="inherit" size="small" onClick={handleDiscardRecovery}>
                Descartar
              </Button>
            </Box>
          }
        >
          Reporte no guardado recuperado
        </Alert>
      </Snackbar>
    </Box>
  );
}
