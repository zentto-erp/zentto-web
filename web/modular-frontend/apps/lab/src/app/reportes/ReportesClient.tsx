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
  ListAlt as PriceListIcon,
  LocalShipping as DeliveryIcon,
  LocalOffer as LabelIcon,
  QrCode2 as QrIcon,
  Badge as BadgeIcon,
  Inventory2 as InventoryIcon,
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
} from "@mui/icons-material";
import type { ReportLayout, DataSet } from "@zentto/report-core";

// ─── Safe imports from @zentto/report-core (pure functions) ─────────
let renderToFullHtml: ((layout: ReportLayout, data: DataSet) => string) | null = null;
let createBlankLayout: (() => ReportLayout) | null = null;
try {
  const core = require("@zentto/report-core");
  renderToFullHtml = core.renderToFullHtml;
  createBlankLayout = core.createBlankLayout;
} catch {
  /* Will be unavailable — fallbacks are used */
}

// ─── Constants ──────────────────────────────────────────────────────

const AUTOSAVE_KEY = "zentto-report-studio:autosave";
const AUTOSAVE_INTERVAL = 30_000; // 30s

// ─── Template: Factura de Venta ─────────────────────────────────────

const INVOICE_LAYOUT: ReportLayout = {
  version: "1.0",
  name: "Factura de Venta",
  description: "Factura con detalle de productos, impuestos y totales",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 15, right: 10, bottom: 15, left: 10 },
  orientation: "portrait",
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object",
      fields: [
        { name: "invoiceNumber", label: "N# Factura", type: "string" },
        { name: "date", label: "Fecha", type: "date" },
        { name: "dueDate", label: "Fecha Vencimiento", type: "date" },
        { name: "clientName", label: "Cliente", type: "string" },
        { name: "clientRif", label: "RIF/NIT", type: "string" },
        { name: "clientAddress", label: "Direccion", type: "string" },
        { name: "clientPhone", label: "Telefono", type: "string" },
        { name: "clientEmail", label: "Email", type: "string" },
        { name: "companyName", label: "Empresa", type: "string" },
        { name: "companyRif", label: "RIF Empresa", type: "string" },
        { name: "companyAddress", label: "Direccion Empresa", type: "string" },
        { name: "companyPhone", label: "Telefono Empresa", type: "string" },
        { name: "companyLogoUrl", label: "Logo URL", type: "string" },
        { name: "subtotal", label: "Subtotal", type: "currency" },
        { name: "taxRate", label: "% IVA", type: "number" },
        { name: "taxAmount", label: "Monto IVA", type: "currency" },
        { name: "discount", label: "Descuento", type: "currency" },
        { name: "grandTotal", label: "Total General", type: "currency" },
        { name: "paymentMethod", label: "Forma de Pago", type: "string" },
        { name: "notes", label: "Observaciones", type: "string" },
      ],
    },
    {
      id: "detail",
      name: "Detalle",
      type: "array",
      fields: [
        { name: "code", label: "Codigo", type: "string" },
        { name: "description", label: "Descripcion", type: "string" },
        { name: "qty", label: "Cantidad", type: "number" },
        { name: "price", label: "Precio", type: "currency" },
        { name: "discount", label: "Descuento", type: "currency" },
        { name: "tax", label: "IVA", type: "currency" },
        { name: "total", label: "Total", type: "currency" },
      ],
    },
  ],
  bands: [
    {
      id: "rh",
      type: "reportHeader",
      height: 35,
      elements: [
        {
          id: "title",
          type: "text",
          content: "FACTURA DE VENTA",
          x: 0, y: 2, width: 190, height: 12,
          style: { fontSize: 20, fontWeight: "bold", textAlign: "center", color: "#1a1a2e" },
        },
        {
          id: "company",
          type: "field",
          dataSource: "header",
          field: "companyName",
          x: 0, y: 16, width: 190, height: 8,
          style: { fontSize: 12, textAlign: "center", color: "#666" },
        },
        {
          id: "line1",
          type: "line",
          x: 0, y: 30, width: 190, height: 0,
          x2: 190, y2: 30,
          lineStyle: { color: "#1a1a2e", width: 2, style: "solid" },
        },
      ],
    },
    {
      id: "ph",
      type: "pageHeader",
      height: 35,
      elements: [
        { id: "invNum", type: "text", content: "Factura N#:", x: 0, y: 2, width: 25, height: 6, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "invNumVal", type: "field", dataSource: "header", field: "invoiceNumber", x: 26, y: 2, width: 40, height: 6, style: { fontSize: 9 } },
        { id: "dateLabel", type: "text", content: "Fecha:", x: 110, y: 2, width: 15, height: 6, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "dateVal", type: "field", dataSource: "header", field: "date", format: "dd/MM/yyyy", x: 126, y: 2, width: 30, height: 6, style: { fontSize: 9 } },
        { id: "dueDateLabel", type: "text", content: "Vence:", x: 156, y: 2, width: 12, height: 6, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "dueDateVal", type: "field", dataSource: "header", field: "dueDate", format: "dd/MM/yyyy", x: 168, y: 2, width: 22, height: 6, style: { fontSize: 9 } },
        { id: "clientLabel", type: "text", content: "Cliente:", x: 0, y: 10, width: 18, height: 6, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "clientVal", type: "field", dataSource: "header", field: "clientName", x: 19, y: 10, width: 80, height: 6, style: { fontSize: 9 } },
        { id: "rifVal", type: "field", dataSource: "header", field: "clientRif", x: 140, y: 10, width: 50, height: 6, style: { fontSize: 9 } },
        { id: "addrVal", type: "field", dataSource: "header", field: "clientAddress", x: 0, y: 18, width: 190, height: 6, style: { fontSize: 8, color: "#666" } },
        { id: "payLabel", type: "text", content: "Forma de Pago:", x: 0, y: 26, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "payVal", type: "field", dataSource: "header", field: "paymentMethod", x: 31, y: 26, width: 60, height: 6, style: { fontSize: 8 } },
      ],
    },
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#1a1a2e",
      elements: [
        { id: "hCode", type: "text", content: "Codigo", x: 0, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hDesc", type: "text", content: "Descripcion", x: 24, y: 1, width: 75, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hQty", type: "text", content: "Cant.", x: 101, y: 1, width: 15, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "hPrice", type: "text", content: "Precio", x: 118, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "hDisc", type: "text", content: "Desc.", x: 142, y: 1, width: 18, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "hTotal", type: "text", content: "Total", x: 163, y: 1, width: 27, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },
    {
      id: "det",
      type: "detail",
      height: 7,
      dataSource: "detail",
      elements: [
        { id: "dCode", type: "field", dataSource: "detail", field: "code", x: 0, y: 1, width: 22, height: 5, style: { fontSize: 8 } },
        { id: "dDesc", type: "field", dataSource: "detail", field: "description", x: 24, y: 1, width: 75, height: 5, style: { fontSize: 8 } },
        { id: "dQty", type: "field", dataSource: "detail", field: "qty", x: 101, y: 1, width: 15, height: 5, format: "#,##0", style: { fontSize: 8, textAlign: "right" } },
        { id: "dPrice", type: "field", dataSource: "detail", field: "price", x: 118, y: 1, width: 22, height: 5, format: "$#,##0.00", style: { fontSize: 8, textAlign: "right" } },
        { id: "dDisc", type: "field", dataSource: "detail", field: "discount", x: 142, y: 1, width: 18, height: 5, format: "$#,##0.00", style: { fontSize: 8, textAlign: "right" } },
        { id: "dTotal", type: "field", dataSource: "detail", field: "total", x: 163, y: 1, width: 27, height: 5, format: "$#,##0.00", style: { fontSize: 8, textAlign: "right" } },
      ],
    },
    {
      id: "rf",
      type: "reportFooter",
      height: 40,
      elements: [
        { id: "lineBottom", type: "line", x: 110, y: 2, width: 80, height: 0, x2: 190, y2: 2, lineStyle: { color: "#333", width: 1, style: "solid" } },
        { id: "subtotalLabel", type: "text", content: "Subtotal:", x: 110, y: 5, width: 50, height: 6, style: { fontSize: 9, textAlign: "right" } },
        { id: "subtotalVal", type: "field", dataSource: "header", field: "subtotal", x: 163, y: 5, width: 27, height: 6, format: "$#,##0.00", style: { fontSize: 9, textAlign: "right" } },
        { id: "discountLabel", type: "text", content: "Descuento:", x: 110, y: 12, width: 50, height: 6, style: { fontSize: 9, textAlign: "right" } },
        { id: "discountVal", type: "field", dataSource: "header", field: "discount", x: 163, y: 12, width: 27, height: 6, format: "$#,##0.00", style: { fontSize: 9, textAlign: "right", color: "#d32f2f" } },
        { id: "taxLabel", type: "text", content: "IVA (16%):", x: 110, y: 19, width: 50, height: 6, style: { fontSize: 9, textAlign: "right" } },
        { id: "taxVal", type: "field", dataSource: "header", field: "taxAmount", x: 163, y: 19, width: 27, height: 6, format: "$#,##0.00", style: { fontSize: 9, textAlign: "right" } },
        { id: "line2", type: "line", x: 140, y: 27, width: 50, height: 0, x2: 190, y2: 27, lineStyle: { color: "#1a1a2e", width: 2, style: "solid" } },
        { id: "totalLabel", type: "text", content: "TOTAL:", x: 110, y: 30, width: 50, height: 8, style: { fontSize: 13, fontWeight: "bold", textAlign: "right" } },
        { id: "totalVal", type: "field", dataSource: "header", field: "grandTotal", x: 160, y: 30, width: 30, height: 8, format: "$#,##0.00", style: { fontSize: 13, fontWeight: "bold", textAlign: "right", color: "#1a1a2e" } },
        { id: "notesLabel", type: "text", content: "Observaciones:", x: 0, y: 5, width: 30, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#666" } },
        { id: "notesVal", type: "field", dataSource: "header", field: "notes", x: 0, y: 12, width: 100, height: 12, style: { fontSize: 8, color: "#666" } },
      ],
    },
    {
      id: "pf",
      type: "pageFooter",
      height: 10,
      elements: [
        { id: "pgNum", type: "pageNumber", format: "Pagina {page} de {pages}", x: 70, y: 2, width: 50, height: 6, style: { fontSize: 8, textAlign: "center", color: "#888" } },
        { id: "genDate", type: "currentDate", format: "dd/MM/yyyy HH:mm", x: 150, y: 2, width: 40, height: 6, style: { fontSize: 7, textAlign: "right", color: "#aaa" } },
      ],
    },
  ],
};

const INVOICE_DATA: DataSet = {
  header: {
    invoiceNumber: "FAC-2026-001547",
    date: "2026-03-27T10:30:00Z",
    dueDate: "2026-04-27T10:30:00Z",
    clientName: "Distribuidora La Esperanza C.A.",
    clientRif: "J-12345678-9",
    clientAddress: "Av. Libertador, Edf. Centro, Piso 3, Oficina 3A, Caracas 1010",
    clientPhone: "+58 212-555-1234",
    clientEmail: "compras@laesperanza.com",
    companyName: "Zentto Solutions C.A.",
    companyRif: "J-50123456-7",
    companyAddress: "Av. Francisco de Miranda, Torre Zentto, Piso 8, Caracas",
    companyPhone: "+58 212-999-8888",
    companyLogoUrl: "https://zentto.net/logo.png",
    subtotal: 8247.00,
    taxRate: 16,
    taxAmount: 1319.52,
    discount: 150.00,
    grandTotal: 9416.52,
    paymentMethod: "Transferencia Bancaria - 30 dias",
    notes: "Precios expresados en USD. Valido por 15 dias. Garantia de 12 meses en equipos.",
  },
  detail: [
    { code: "ART-001", description: "Laptop HP ProBook 450 G10 i7/16GB/512GB", qty: 2, price: 850.00, discount: 0, tax: 272.00, total: 1700.00 },
    { code: "ART-002", description: "Monitor Dell 27\" 4K USB-C P2723QE", qty: 4, price: 420.00, discount: 0, tax: 268.80, total: 1680.00 },
    { code: "ART-003", description: "Teclado Logitech MX Keys Wireless", qty: 6, price: 95.00, discount: 0, tax: 91.20, total: 570.00 },
    { code: "ART-004", description: "Mouse Logitech MX Master 3S Ergonomico", qty: 6, price: 85.00, discount: 0, tax: 81.60, total: 510.00 },
    { code: "ART-005", description: "Docking Station Thunderbolt 4 10-in-1", qty: 2, price: 145.00, discount: 0, tax: 46.40, total: 290.00 },
    { code: "ART-006", description: "Cable HDMI 2.1 Ultra HD Premium 2m", qty: 10, price: 18.50, discount: 0, tax: 29.60, total: 185.00 },
    { code: "ART-007", description: "SSD NVMe M.2 1TB Samsung 990 Pro", qty: 3, price: 129.00, discount: 0, tax: 61.92, total: 387.00 },
    { code: "ART-008", description: "Memoria RAM DDR5 32GB (2x16) 5600MHz", qty: 2, price: 165.00, discount: 0, tax: 52.80, total: 330.00 },
    { code: "ART-009", description: "Webcam Logitech Brio 4K Ultra HD", qty: 4, price: 175.00, discount: 50.00, tax: 108.00, total: 650.00 },
    { code: "ART-010", description: "Headset Jabra Evolve2 75 UC Stereo", qty: 3, price: 280.00, discount: 100.00, tax: 121.60, total: 740.00 },
    { code: "ART-011", description: "Soporte Monitor Ergotron LX Dual Arm", qty: 4, price: 195.00, discount: 0, tax: 124.80, total: 780.00 },
    { code: "ART-012", description: "Hub USB-C 7 puertos con PD 100W", qty: 5, price: 55.00, discount: 0, tax: 44.00, total: 275.00 },
  ],
};

// ─── Template: Lista de Precios ─────────────────────────────────────

const PRICELIST_LAYOUT: ReportLayout = {
  version: "1.0",
  name: "Lista de Precios",
  description: "Catalogo de productos con precios por categoria",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 12, right: 10, bottom: 12, left: 10 },
  orientation: "portrait",
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object",
      fields: [
        { name: "companyName", label: "Empresa", type: "string" },
        { name: "listName", label: "Nombre Lista", type: "string" },
        { name: "validFrom", label: "Vigente Desde", type: "date" },
        { name: "validTo", label: "Vigente Hasta", type: "date" },
        { name: "currency", label: "Moneda", type: "string" },
        { name: "notes", label: "Notas", type: "string" },
      ],
    },
    {
      id: "items",
      name: "Productos",
      type: "array",
      fields: [
        { name: "code", label: "Codigo", type: "string" },
        { name: "description", label: "Descripcion", type: "string" },
        { name: "category", label: "Categoria", type: "string" },
        { name: "unit", label: "Unidad", type: "string" },
        { name: "price", label: "Precio", type: "currency" },
        { name: "taxIncluded", label: "IVA Incluido", type: "boolean" },
      ],
    },
  ],
  bands: [
    {
      id: "rh",
      type: "reportHeader",
      height: 30,
      elements: [
        { id: "title", type: "field", dataSource: "header", field: "listName", x: 0, y: 2, width: 190, height: 12, style: { fontSize: 18, fontWeight: "bold", textAlign: "center", color: "#0d47a1" } },
        { id: "company", type: "field", dataSource: "header", field: "companyName", x: 0, y: 15, width: 190, height: 7, style: { fontSize: 11, textAlign: "center", color: "#666" } },
        { id: "validity", type: "text", content: "Vigencia:", x: 60, y: 23, width: 20, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "validFrom", type: "field", dataSource: "header", field: "validFrom", format: "dd/MM/yyyy", x: 81, y: 23, width: 25, height: 5, style: { fontSize: 8 } },
        { id: "validTo", type: "field", dataSource: "header", field: "validTo", format: "dd/MM/yyyy", x: 110, y: 23, width: 25, height: 5, style: { fontSize: 8 } },
      ],
    },
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#0d47a1",
      elements: [
        { id: "hCode", type: "text", content: "Codigo", x: 0, y: 1, width: 25, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hDesc", type: "text", content: "Descripcion", x: 27, y: 1, width: 70, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hCat", type: "text", content: "Categoria", x: 99, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hUnit", type: "text", content: "Und", x: 136, y: 1, width: 15, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "hPrice", type: "text", content: "Precio", x: 155, y: 1, width: 35, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },
    {
      id: "det",
      type: "detail",
      height: 6,
      dataSource: "items",
      elements: [
        { id: "dCode", type: "field", dataSource: "items", field: "code", x: 0, y: 0.5, width: 25, height: 5, style: { fontSize: 7.5 } },
        { id: "dDesc", type: "field", dataSource: "items", field: "description", x: 27, y: 0.5, width: 70, height: 5, style: { fontSize: 7.5 } },
        { id: "dCat", type: "field", dataSource: "items", field: "category", x: 99, y: 0.5, width: 35, height: 5, style: { fontSize: 7.5, color: "#555" } },
        { id: "dUnit", type: "field", dataSource: "items", field: "unit", x: 136, y: 0.5, width: 15, height: 5, style: { fontSize: 7.5, textAlign: "center" } },
        { id: "dPrice", type: "field", dataSource: "items", field: "price", x: 155, y: 0.5, width: 35, height: 5, format: "$#,##0.00", style: { fontSize: 7.5, fontWeight: "bold", textAlign: "right" } },
      ],
    },
    {
      id: "rf",
      type: "reportFooter",
      height: 15,
      elements: [
        { id: "count", type: "field", dataSource: "items", field: "code", aggregate: "count", x: 0, y: 3, width: 50, height: 6, format: "#,##0 productos", style: { fontSize: 8, color: "#888" } },
        { id: "notesVal", type: "field", dataSource: "header", field: "notes", x: 55, y: 3, width: 135, height: 6, style: { fontSize: 7, color: "#999" } },
      ],
    },
    {
      id: "pf",
      type: "pageFooter",
      height: 8,
      elements: [
        { id: "pgNum", type: "pageNumber", format: "Pagina {page} de {pages}", x: 70, y: 1, width: 50, height: 5, style: { fontSize: 7, textAlign: "center", color: "#aaa" } },
        { id: "genDate", type: "currentDate", format: "dd/MM/yyyy HH:mm", x: 150, y: 1, width: 40, height: 5, style: { fontSize: 7, textAlign: "right", color: "#aaa" } },
      ],
    },
  ],
};

const PRICELIST_DATA: DataSet = {
  header: {
    companyName: "Zentto Solutions C.A.",
    listName: "LISTA DE PRECIOS - TECNOLOGIA 2026",
    validFrom: "2026-01-01T00:00:00Z",
    validTo: "2026-06-30T23:59:59Z",
    currency: "USD",
    notes: "Precios en USD sin IVA. Sujetos a disponibilidad de inventario. Descuentos por volumen disponibles.",
  },
  items: [
    { code: "LAP-001", description: "Laptop HP ProBook 450 G10 i5/8GB/256GB", category: "Laptops", unit: "Und", price: 650.00, taxIncluded: false },
    { code: "LAP-002", description: "Laptop HP ProBook 450 G10 i7/16GB/512GB", category: "Laptops", unit: "Und", price: 850.00, taxIncluded: false },
    { code: "LAP-003", description: "Laptop Dell Latitude 5540 i5/16GB/512GB", category: "Laptops", unit: "Und", price: 920.00, taxIncluded: false },
    { code: "LAP-004", description: "Laptop Lenovo ThinkPad T14s Gen4 AMD", category: "Laptops", unit: "Und", price: 1050.00, taxIncluded: false },
    { code: "MON-001", description: "Monitor Dell 24\" FHD IPS P2422H", category: "Monitores", unit: "Und", price: 245.00, taxIncluded: false },
    { code: "MON-002", description: "Monitor Dell 27\" 4K USB-C P2723QE", category: "Monitores", unit: "Und", price: 420.00, taxIncluded: false },
    { code: "MON-003", description: "Monitor LG 34\" UltraWide QHD 34WP65C", category: "Monitores", unit: "Und", price: 380.00, taxIncluded: false },
    { code: "PER-001", description: "Teclado Logitech MX Keys Wireless", category: "Perifericos", unit: "Und", price: 95.00, taxIncluded: false },
    { code: "PER-002", description: "Mouse Logitech MX Master 3S", category: "Perifericos", unit: "Und", price: 85.00, taxIncluded: false },
    { code: "PER-003", description: "Webcam Logitech Brio 4K Ultra HD", category: "Perifericos", unit: "Und", price: 175.00, taxIncluded: false },
    { code: "PER-004", description: "Headset Jabra Evolve2 75 UC Stereo", category: "Perifericos", unit: "Und", price: 280.00, taxIncluded: false },
    { code: "PER-005", description: "Soporte Monitor Ergotron LX Single Arm", category: "Perifericos", unit: "Und", price: 145.00, taxIncluded: false },
    { code: "PER-006", description: "Soporte Monitor Ergotron LX Dual Arm", category: "Perifericos", unit: "Und", price: 195.00, taxIncluded: false },
    { code: "RED-001", description: "Switch TP-Link 8 Puertos Gigabit", category: "Redes", unit: "Und", price: 35.00, taxIncluded: false },
    { code: "RED-002", description: "Router Ubiquiti UniFi Dream Machine", category: "Redes", unit: "Und", price: 310.00, taxIncluded: false },
    { code: "RED-003", description: "Access Point Ubiquiti U6 Pro WiFi 6", category: "Redes", unit: "Und", price: 150.00, taxIncluded: false },
    { code: "ALM-001", description: "SSD NVMe M.2 512GB Samsung 980 Pro", category: "Almacenamiento", unit: "Und", price: 75.00, taxIncluded: false },
    { code: "ALM-002", description: "SSD NVMe M.2 1TB Samsung 990 Pro", category: "Almacenamiento", unit: "Und", price: 129.00, taxIncluded: false },
    { code: "ALM-003", description: "Disco Externo WD Elements 2TB USB 3.0", category: "Almacenamiento", unit: "Und", price: 65.00, taxIncluded: false },
    { code: "ALM-004", description: "Memoria USB SanDisk Ultra 128GB", category: "Almacenamiento", unit: "Und", price: 12.00, taxIncluded: false },
    { code: "ACC-001", description: "Docking Station Thunderbolt 4 10-in-1", category: "Accesorios", unit: "Und", price: 145.00, taxIncluded: false },
    { code: "ACC-002", description: "Hub USB-C 7 puertos con PD 100W", category: "Accesorios", unit: "Und", price: 55.00, taxIncluded: false },
    { code: "ACC-003", description: "Cable HDMI 2.1 Ultra HD 2m", category: "Accesorios", unit: "Und", price: 18.50, taxIncluded: false },
    { code: "ACC-004", description: "Cable USB-C a USB-C 100W 1.5m", category: "Accesorios", unit: "Und", price: 15.00, taxIncluded: false },
    { code: "MEM-001", description: "Memoria RAM DDR5 16GB (1x16) 5600MHz", category: "Memoria", unit: "Und", price: 85.00, taxIncluded: false },
    { code: "MEM-002", description: "Memoria RAM DDR5 32GB (2x16) 5600MHz", category: "Memoria", unit: "Und", price: 165.00, taxIncluded: false },
  ],
};

// ─── Template: Nota de Entrega ──────────────────────────────────────

const DELIVERY_LAYOUT: ReportLayout = {
  version: "1.0",
  name: "Nota de Entrega",
  description: "Nota de entrega con datos de despacho y transporte",
  pageSize: { width: 210, height: 297, unit: "mm" },
  margins: { top: 12, right: 10, bottom: 12, left: 10 },
  orientation: "portrait",
  dataSources: [
    {
      id: "header",
      name: "Encabezado",
      type: "object",
      fields: [
        { name: "deliveryNumber", label: "N# Nota", type: "string" },
        { name: "date", label: "Fecha Emision", type: "date" },
        { name: "deliveryDate", label: "Fecha Entrega", type: "date" },
        { name: "invoiceRef", label: "Ref. Factura", type: "string" },
        { name: "clientName", label: "Cliente", type: "string" },
        { name: "clientRif", label: "RIF", type: "string" },
        { name: "deliveryAddress", label: "Direccion Entrega", type: "string" },
        { name: "contactName", label: "Persona Contacto", type: "string" },
        { name: "contactPhone", label: "Telefono Contacto", type: "string" },
        { name: "companyName", label: "Empresa", type: "string" },
        { name: "warehouseName", label: "Almacen Origen", type: "string" },
        { name: "warehouseCode", label: "Cod. Almacen", type: "string" },
        { name: "warehouseAddress", label: "Dir. Almacen", type: "string" },
        { name: "driverName", label: "Conductor", type: "string" },
        { name: "driverCI", label: "CI Conductor", type: "string" },
        { name: "vehiclePlate", label: "Placa Vehiculo", type: "string" },
        { name: "vehicleType", label: "Tipo Vehiculo", type: "string" },
        { name: "totalPackages", label: "Total Bultos", type: "number" },
        { name: "totalWeight", label: "Peso Total (kg)", type: "number" },
        { name: "observations", label: "Observaciones", type: "string" },
      ],
    },
    {
      id: "items",
      name: "Items",
      type: "array",
      fields: [
        { name: "code", label: "Codigo", type: "string" },
        { name: "description", label: "Descripcion", type: "string" },
        { name: "qtyOrdered", label: "Cant. Pedida", type: "number" },
        { name: "qtyDelivered", label: "Cant. Entregada", type: "number" },
        { name: "unit", label: "Unidad", type: "string" },
        { name: "lot", label: "Lote", type: "string" },
        { name: "packages", label: "Bultos", type: "number" },
      ],
    },
  ],
  bands: [
    {
      id: "rh",
      type: "reportHeader",
      height: 28,
      elements: [
        { id: "title", type: "text", content: "NOTA DE ENTREGA", x: 0, y: 2, width: 190, height: 12, style: { fontSize: 20, fontWeight: "bold", textAlign: "center", color: "#2e7d32" } },
        { id: "company", type: "field", dataSource: "header", field: "companyName", x: 0, y: 15, width: 190, height: 7, style: { fontSize: 11, textAlign: "center", color: "#666" } },
        { id: "line1", type: "line", x: 0, y: 25, width: 190, height: 0, x2: 190, y2: 25, lineStyle: { color: "#2e7d32", width: 2, style: "solid" } },
      ],
    },
    {
      id: "ph",
      type: "pageHeader",
      height: 52,
      elements: [
        { id: "delNum", type: "text", content: "Nota N#:", x: 0, y: 1, width: 20, height: 5, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "delNumVal", type: "field", dataSource: "header", field: "deliveryNumber", x: 21, y: 1, width: 40, height: 5, style: { fontSize: 9 } },
        { id: "dateLabel", type: "text", content: "Emision:", x: 100, y: 1, width: 18, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "dateVal", type: "field", dataSource: "header", field: "date", format: "dd/MM/yyyy", x: 119, y: 1, width: 28, height: 5, style: { fontSize: 8 } },
        { id: "delDateLabel", type: "text", content: "Entrega:", x: 150, y: 1, width: 17, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "delDateVal", type: "field", dataSource: "header", field: "deliveryDate", format: "dd/MM/yyyy", x: 168, y: 1, width: 22, height: 5, style: { fontSize: 8 } },
        { id: "invRefLabel", type: "text", content: "Ref. Factura:", x: 0, y: 7, width: 25, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "invRefVal", type: "field", dataSource: "header", field: "invoiceRef", x: 26, y: 7, width: 40, height: 5, style: { fontSize: 8 } },
        { id: "clientLabel", type: "text", content: "Cliente:", x: 0, y: 14, width: 15, height: 5, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "clientVal", type: "field", dataSource: "header", field: "clientName", x: 16, y: 14, width: 100, height: 5, style: { fontSize: 9 } },
        { id: "rifVal", type: "field", dataSource: "header", field: "clientRif", x: 150, y: 14, width: 40, height: 5, style: { fontSize: 8 } },
        { id: "delAddrLabel", type: "text", content: "Dir. Entrega:", x: 0, y: 20, width: 25, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "delAddrVal", type: "field", dataSource: "header", field: "deliveryAddress", x: 26, y: 20, width: 164, height: 5, style: { fontSize: 8, color: "#555" } },
        { id: "whLabel", type: "text", content: "Almacen:", x: 0, y: 27, width: 18, height: 5, style: { fontSize: 8, fontWeight: "bold", color: "#2e7d32" } },
        { id: "whVal", type: "field", dataSource: "header", field: "warehouseName", x: 19, y: 27, width: 60, height: 5, style: { fontSize: 8 } },
        { id: "whCodeVal", type: "field", dataSource: "header", field: "warehouseCode", x: 80, y: 27, width: 20, height: 5, style: { fontSize: 8, color: "#888" } },
        { id: "driverLabel", type: "text", content: "Conductor:", x: 0, y: 34, width: 22, height: 5, style: { fontSize: 8, fontWeight: "bold", color: "#2e7d32" } },
        { id: "driverVal", type: "field", dataSource: "header", field: "driverName", x: 23, y: 34, width: 50, height: 5, style: { fontSize: 8 } },
        { id: "driverCIVal", type: "field", dataSource: "header", field: "driverCI", x: 75, y: 34, width: 30, height: 5, style: { fontSize: 8, color: "#888" } },
        { id: "plateLabel", type: "text", content: "Placa:", x: 110, y: 34, width: 14, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "plateVal", type: "field", dataSource: "header", field: "vehiclePlate", x: 125, y: 34, width: 25, height: 5, style: { fontSize: 9, fontWeight: "bold" } },
        { id: "vehicleVal", type: "field", dataSource: "header", field: "vehicleType", x: 152, y: 34, width: 38, height: 5, style: { fontSize: 8, color: "#888" } },
        { id: "pkgLabel", type: "text", content: "Total Bultos:", x: 0, y: 42, width: 26, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "pkgVal", type: "field", dataSource: "header", field: "totalPackages", x: 27, y: 42, width: 15, height: 5, format: "#,##0", style: { fontSize: 8 } },
        { id: "weightLabel", type: "text", content: "Peso Total:", x: 50, y: 42, width: 22, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
        { id: "weightVal", type: "field", dataSource: "header", field: "totalWeight", x: 73, y: 42, width: 20, height: 5, format: "#,##0.0 kg", style: { fontSize: 8 } },
      ],
    },
    {
      id: "ch",
      type: "columnHeader",
      height: 8,
      repeatOnEveryPage: true,
      backgroundColor: "#2e7d32",
      elements: [
        { id: "hCode", type: "text", content: "Codigo", x: 0, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hDesc", type: "text", content: "Descripcion", x: 24, y: 1, width: 70, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hOrd", type: "text", content: "Pedido", x: 96, y: 1, width: 18, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "hDel", type: "text", content: "Entregado", x: 116, y: 1, width: 22, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
        { id: "hUnit", type: "text", content: "Und", x: 140, y: 1, width: 12, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "center" } },
        { id: "hLot", type: "text", content: "Lote", x: 154, y: 1, width: 20, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff" } },
        { id: "hPkg", type: "text", content: "Bultos", x: 176, y: 1, width: 14, height: 6, style: { fontSize: 8, fontWeight: "bold", color: "#fff", textAlign: "right" } },
      ],
    },
    {
      id: "det",
      type: "detail",
      height: 7,
      dataSource: "items",
      elements: [
        { id: "dCode", type: "field", dataSource: "items", field: "code", x: 0, y: 1, width: 22, height: 5, style: { fontSize: 8 } },
        { id: "dDesc", type: "field", dataSource: "items", field: "description", x: 24, y: 1, width: 70, height: 5, style: { fontSize: 8 } },
        { id: "dOrd", type: "field", dataSource: "items", field: "qtyOrdered", x: 96, y: 1, width: 18, height: 5, format: "#,##0", style: { fontSize: 8, textAlign: "right" } },
        { id: "dDel", type: "field", dataSource: "items", field: "qtyDelivered", x: 116, y: 1, width: 22, height: 5, format: "#,##0", style: { fontSize: 8, textAlign: "right", fontWeight: "bold" } },
        { id: "dUnit", type: "field", dataSource: "items", field: "unit", x: 140, y: 1, width: 12, height: 5, style: { fontSize: 8, textAlign: "center" } },
        { id: "dLot", type: "field", dataSource: "items", field: "lot", x: 154, y: 1, width: 20, height: 5, style: { fontSize: 7.5, color: "#888" } },
        { id: "dPkg", type: "field", dataSource: "items", field: "packages", x: 176, y: 1, width: 14, height: 5, format: "#,##0", style: { fontSize: 8, textAlign: "right" } },
      ],
    },
    {
      id: "rf",
      type: "reportFooter",
      height: 30,
      elements: [
        { id: "obsLabel", type: "text", content: "Observaciones:", x: 0, y: 3, width: 30, height: 5, style: { fontSize: 8, fontWeight: "bold", color: "#555" } },
        { id: "obsVal", type: "field", dataSource: "header", field: "observations", x: 0, y: 9, width: 120, height: 10, style: { fontSize: 8, color: "#666" } },
        { id: "signLabel1", type: "text", content: "Entregado por:", x: 0, y: 22, width: 30, height: 5, style: { fontSize: 7, color: "#888" } },
        { id: "signLine1", type: "line", x: 0, y: 27, width: 60, height: 0, x2: 60, y2: 27, lineStyle: { color: "#ccc", width: 1, style: "dashed" } },
        { id: "signLabel2", type: "text", content: "Recibido por:", x: 70, y: 22, width: 30, height: 5, style: { fontSize: 7, color: "#888" } },
        { id: "signLine2", type: "line", x: 70, y: 27, width: 60, height: 0, x2: 130, y2: 27, lineStyle: { color: "#ccc", width: 1, style: "dashed" } },
      ],
    },
    {
      id: "pf",
      type: "pageFooter",
      height: 8,
      elements: [
        { id: "pgNum", type: "pageNumber", format: "Pagina {page} de {pages}", x: 70, y: 1, width: 50, height: 5, style: { fontSize: 7, textAlign: "center", color: "#aaa" } },
      ],
    },
  ],
};

const DELIVERY_DATA: DataSet = {
  header: {
    deliveryNumber: "NE-2026-003218",
    date: "2026-03-27T08:00:00Z",
    deliveryDate: "2026-03-28T14:00:00Z",
    invoiceRef: "FAC-2026-001547",
    clientName: "Distribuidora La Esperanza C.A.",
    clientRif: "J-12345678-9",
    deliveryAddress: "Zona Industrial Los Cortijos, Galpon 15-A, Caracas 1071",
    contactName: "Carlos Mendoza",
    contactPhone: "+58 412-555-7890",
    companyName: "Zentto Solutions C.A.",
    warehouseName: "Almacen Principal - Caracas",
    warehouseCode: "ALM-001",
    warehouseAddress: "Av. Romulo Gallegos, Galpon Z-12, Caracas 1060",
    driverName: "Jose Ramirez Hernandez",
    driverCI: "V-18.456.789",
    vehiclePlate: "AB123CD",
    vehicleType: "Camion 350 - Carga Seca",
    totalPackages: 18,
    totalWeight: 245.5,
    observations: "Entregar en horario de 8am a 5pm. Solicitar firma del responsable de almacen. Productos fragiles: manipular con cuidado.",
  },
  items: [
    { code: "ART-001", description: "Laptop HP ProBook 450 G10 i7/16GB/512GB", qtyOrdered: 2, qtyDelivered: 2, unit: "Und", lot: "LT-2026-0312", packages: 2 },
    { code: "ART-002", description: "Monitor Dell 27\" 4K USB-C P2723QE", qtyOrdered: 4, qtyDelivered: 4, unit: "Und", lot: "LT-2026-0315", packages: 4 },
    { code: "ART-003", description: "Teclado Logitech MX Keys Wireless", qtyOrdered: 6, qtyDelivered: 6, unit: "Und", lot: "LT-2026-0280", packages: 2 },
    { code: "ART-004", description: "Mouse Logitech MX Master 3S Ergonomico", qtyOrdered: 6, qtyDelivered: 6, unit: "Und", lot: "LT-2026-0280", packages: 2 },
    { code: "ART-005", description: "Docking Station Thunderbolt 4 10-in-1", qtyOrdered: 2, qtyDelivered: 2, unit: "Und", lot: "LT-2026-0299", packages: 1 },
    { code: "ART-006", description: "Cable HDMI 2.1 Ultra HD Premium 2m", qtyOrdered: 10, qtyDelivered: 10, unit: "Und", lot: "LT-2026-0250", packages: 1 },
    { code: "ART-007", description: "SSD NVMe M.2 1TB Samsung 990 Pro", qtyOrdered: 3, qtyDelivered: 3, unit: "Und", lot: "LT-2026-0305", packages: 1 },
    { code: "ART-008", description: "Memoria RAM DDR5 32GB Kit", qtyOrdered: 2, qtyDelivered: 2, unit: "Und", lot: "LT-2026-0305", packages: 1 },
    { code: "ART-009", description: "Webcam Logitech Brio 4K Ultra HD", qtyOrdered: 4, qtyDelivered: 3, unit: "Und", lot: "LT-2026-0288", packages: 1 },
    { code: "ART-010", description: "Headset Jabra Evolve2 75 UC Stereo", qtyOrdered: 3, qtyDelivered: 3, unit: "Und", lot: "LT-2026-0310", packages: 1 },
    { code: "ART-011", description: "Soporte Monitor Ergotron LX Dual Arm", qtyOrdered: 4, qtyDelivered: 4, unit: "Und", lot: "LT-2026-0292", packages: 2 },
  ],
};

// ─── Label Templates & Data ─────────────────────────────────────────

const PRODUCT_BARCODE_LABEL: ReportLayout = {
  version: "1.0", name: "Product Barcode Label", description: "Product label with barcode, name and price.",
  pageSize: { width: 50, height: 30, unit: "mm" }, margins: { top: 2, right: 2, bottom: 2, left: 2 }, orientation: "portrait",
  dataSources: [{ id: "product", name: "Product", type: "object", fields: [
    { name: "code", label: "SKU", type: "string" }, { name: "name", label: "Name", type: "string" },
    { name: "price", label: "Price", type: "currency" }, { name: "barcode", label: "Barcode", type: "string" },
  ]}],
  bands: [{ id: "detail", type: "detail", height: 26, dataSource: "product", elements: [
    { id: "name", type: "field", dataSource: "product", field: "name", x: 0, y: 0, width: 46, height: 6, style: { fontSize: 8, fontWeight: "bold" } },
    { id: "sku", type: "field", dataSource: "product", field: "code", x: 0, y: 6, width: 20, height: 4, style: { fontSize: 6, color: "#666" } },
    { id: "price", type: "field", dataSource: "product", field: "price", format: "$#,##0.00", x: 20, y: 6, width: 26, height: 5, style: { fontSize: 10, fontWeight: "bold", textAlign: "right" } },
    { id: "bc", type: "barcode", barcodeType: "code128", value: "{{product.barcode}}", x: 0, y: 12, width: 46, height: 14 },
  ]}],
};

const SHIPPING_LABEL: ReportLayout = {
  version: "1.0", name: "Shipping Label 4x6", description: "Standard shipping label with barcode and QR.",
  pageSize: { width: 102, height: 152, unit: "mm" }, margins: { top: 4, right: 4, bottom: 4, left: 4 }, orientation: "portrait",
  dataSources: [{ id: "shipment", name: "Shipment", type: "object", fields: [
    { name: "trackingNumber", label: "Tracking #", type: "string" }, { name: "fromName", label: "From", type: "string" },
    { name: "fromAddress", label: "From Addr", type: "string" }, { name: "fromCity", label: "From City", type: "string" },
    { name: "toName", label: "To", type: "string" }, { name: "toAddress", label: "To Addr", type: "string" },
    { name: "toCity", label: "To City", type: "string" }, { name: "toZip", label: "ZIP", type: "string" },
    { name: "weight", label: "Weight", type: "string" }, { name: "service", label: "Service", type: "string" },
  ]}],
  bands: [{ id: "label", type: "detail", height: 144, dataSource: "shipment", elements: [
    { id: "fromLabel", type: "text", content: "FROM:", x: 0, y: 0, width: 15, height: 5, style: { fontSize: 7, fontWeight: "bold", color: "#666" } },
    { id: "fromName", type: "field", dataSource: "shipment", field: "fromName", x: 0, y: 5, width: 50, height: 5, style: { fontSize: 8 } },
    { id: "fromAddr", type: "field", dataSource: "shipment", field: "fromAddress", x: 0, y: 10, width: 50, height: 4, style: { fontSize: 7 } },
    { id: "sep1", type: "line", x: 0, y: 20, width: 94, height: 0, x2: 94, y2: 20, lineStyle: { color: "#000", width: 2, style: "solid" } },
    { id: "toLabel", type: "text", content: "TO:", x: 0, y: 23, width: 10, height: 5, style: { fontSize: 8, fontWeight: "bold" } },
    { id: "toName", type: "field", dataSource: "shipment", field: "toName", x: 5, y: 30, width: 85, height: 10, style: { fontSize: 16, fontWeight: "bold" } },
    { id: "toAddr", type: "field", dataSource: "shipment", field: "toAddress", x: 5, y: 41, width: 85, height: 8, style: { fontSize: 12 } },
    { id: "toZip", type: "field", dataSource: "shipment", field: "toZip", x: 60, y: 50, width: 30, height: 10, style: { fontSize: 18, fontWeight: "bold", textAlign: "right" } },
    { id: "service", type: "field", dataSource: "shipment", field: "service", x: 0, y: 65, width: 50, height: 8, style: { fontSize: 14, fontWeight: "bold" } },
    { id: "weight", type: "field", dataSource: "shipment", field: "weight", x: 55, y: 65, width: 39, height: 8, style: { fontSize: 12, textAlign: "right" } },
    { id: "trackingBc", type: "barcode", barcodeType: "code128", value: "{{shipment.trackingNumber}}", x: 0, y: 78, width: 94, height: 25 },
    { id: "trackingNum", type: "field", dataSource: "shipment", field: "trackingNumber", x: 0, y: 104, width: 94, height: 6, style: { fontSize: 9, textAlign: "center", fontFamily: "Courier New" } },
    { id: "qr", type: "barcode", barcodeType: "qr", value: "{{shipment.trackingNumber}}", x: 32, y: 113, width: 25, height: 25 },
  ]}],
};

const INVENTORY_QR_TAG: ReportLayout = {
  version: "1.0", name: "Inventory QR Tag", description: "Warehouse tag with QR code.",
  pageSize: { width: 50, height: 25, unit: "mm" }, margins: { top: 1, right: 1, bottom: 1, left: 1 }, orientation: "landscape",
  dataSources: [{ id: "item", name: "Item", type: "object", fields: [
    { name: "sku", label: "SKU", type: "string" }, { name: "name", label: "Name", type: "string" },
    { name: "location", label: "Location", type: "string" }, { name: "qty", label: "Qty", type: "number" },
  ]}],
  bands: [{ id: "detail", type: "detail", height: 23, dataSource: "item", elements: [
    { id: "qr", type: "barcode", barcodeType: "qr", value: "{{item.sku}}", x: 0, y: 0, width: 21, height: 21 },
    { id: "name", type: "field", dataSource: "item", field: "name", x: 23, y: 0, width: 25, height: 5, style: { fontSize: 7, fontWeight: "bold" } },
    { id: "sku", type: "field", dataSource: "item", field: "sku", x: 23, y: 5, width: 25, height: 4, style: { fontSize: 6, fontFamily: "Courier New" } },
    { id: "loc", type: "field", dataSource: "item", field: "location", x: 23, y: 10, width: 15, height: 5, style: { fontSize: 8, fontWeight: "bold", color: "#d32f2f" } },
    { id: "qty", type: "field", dataSource: "item", field: "qty", format: "#,##0", x: 38, y: 10, width: 10, height: 5, style: { fontSize: 8, textAlign: "right" } },
  ]}],
};

const AVERY_5160_ADDRESS: ReportLayout = {
  version: "1.0", name: "Avery 5160 -- Address Labels", description: "30 labels per Letter sheet",
  pageSize: { width: 216, height: 279, unit: "mm" }, margins: { top: 12.7, right: 4.8, bottom: 12.7, left: 4.8 }, orientation: "portrait",
  dataSources: [{ id: "contacts", name: "Contacts", type: "array", fields: [
    { name: "name", label: "Name", type: "string" }, { name: "address", label: "Address", type: "string" },
    { name: "city", label: "City", type: "string" }, { name: "zip", label: "ZIP", type: "string" },
  ]}],
  bands: [{ id: "detail", type: "detail", height: 25.4, dataSource: "contacts", elements: [
    { id: "name", type: "field", dataSource: "contacts", field: "name", x: 2, y: 3, width: 62, height: 6, style: { fontSize: 10, fontWeight: "bold" } },
    { id: "addr", type: "field", dataSource: "contacts", field: "address", x: 2, y: 9, width: 62, height: 5, style: { fontSize: 9 } },
    { id: "city", type: "field", dataSource: "contacts", field: "city", x: 2, y: 15, width: 40, height: 5, style: { fontSize: 9 } },
    { id: "zip", type: "field", dataSource: "contacts", field: "zip", x: 43, y: 15, width: 21, height: 5, style: { fontSize: 9, fontWeight: "bold" } },
  ]}],
};

const AVERY_5371_BUSINESS_CARD: ReportLayout = {
  version: "1.0", name: "Avery 5371 -- Business Cards", description: "10 cards per Letter sheet",
  pageSize: { width: 216, height: 279, unit: "mm" }, margins: { top: 19, right: 16.5, bottom: 19, left: 16.5 }, orientation: "portrait",
  dataSources: [{ id: "card", name: "Card", type: "object", fields: [
    { name: "name", label: "Name", type: "string" }, { name: "title", label: "Title", type: "string" },
    { name: "company", label: "Company", type: "string" }, { name: "phone", label: "Phone", type: "string" },
    { name: "email", label: "Email", type: "string" }, { name: "website", label: "Website", type: "string" },
  ]}],
  bands: [{ id: "detail", type: "detail", height: 51, dataSource: "card", elements: [
    { id: "company", type: "field", dataSource: "card", field: "company", x: 3, y: 5, width: 83, height: 8, style: { fontSize: 12, fontWeight: "bold", color: "#1a1a2e" } },
    { id: "name", type: "field", dataSource: "card", field: "name", x: 3, y: 15, width: 83, height: 7, style: { fontSize: 11 } },
    { id: "title", type: "field", dataSource: "card", field: "title", x: 3, y: 22, width: 83, height: 5, style: { fontSize: 8, color: "#666" } },
    { id: "phone", type: "field", dataSource: "card", field: "phone", x: 3, y: 32, width: 40, height: 5, style: { fontSize: 8 } },
    { id: "email", type: "field", dataSource: "card", field: "email", x: 3, y: 37, width: 60, height: 5, style: { fontSize: 8 } },
    { id: "web", type: "field", dataSource: "card", field: "website", x: 3, y: 42, width: 60, height: 5, style: { fontSize: 8, color: "#1976d2" } },
  ]}],
};

const PRODUCT_LABEL_DATA: DataSet = {
  product: { code: "ART-001", name: "Laptop HP ProBook 450 G10", price: 850.00, barcode: "7501234567890" },
};
const SHIPPING_LABEL_DATA: DataSet = {
  shipment: { trackingNumber: "1Z999AA10123456784", fromName: "Zentto Solutions C.A.", fromAddress: "Av. Libertador, Torre A, P3", fromCity: "Caracas, VE", fromZip: "1010", toName: "Distribuidora La Esperanza", toAddress: "Calle 5, Zona Industrial", toCity: "Valencia, VE", toZip: "2001", weight: "12.5 kg", service: "EXPRESS" },
};
const ADDRESS_LABEL_DATA: DataSet = {
  contacts: [
    { name: "Maria Garcia", address: "123 Main Street", city: "Miami", state: "FL", zip: "33101" },
    { name: "Carlos Rodriguez", address: "456 Oak Avenue", city: "Houston", state: "TX", zip: "77001" },
    { name: "Ana Martinez", address: "789 Pine Road", city: "Los Angeles", state: "CA", zip: "90001" },
  ],
};
const BUSINESS_CARD_DATA: DataSet = {
  card: { name: "Raul Gonzalez", title: "CTO & Co-Founder", company: "Zentto Solutions", phone: "+58 414-123-4567", email: "raul@zentto.net", website: "https://zentto.net" },
};
const INVENTORY_TAG_DATA: DataSet = {
  item: { sku: "INV-2026-0045", name: "SSD NVMe 1TB", location: "A3-R2-S5", qty: 150 },
};

// ─── Template registry ──────────────────────────────────────────────

type TemplateCategory = "Reportes" | "Etiquetas" | "Tarjetas";

interface TemplateEntry {
  id: string;
  name: string;
  description: string;
  icon: React.ReactNode;
  color: string;
  category: TemplateCategory;
  layout: ReportLayout;
  data: DataSet;
}

const TEMPLATES: TemplateEntry[] = [
  {
    id: "invoice",
    name: "Factura de Venta",
    description: "Factura completa con impuestos, subtotales y observaciones",
    icon: <InvoiceIcon />,
    color: "#1a1a2e",
    category: "Reportes",
    layout: INVOICE_LAYOUT,
    data: INVOICE_DATA,
  },
  {
    id: "pricelist",
    name: "Lista de Precios",
    description: "Catalogo de productos por categoria con precios vigentes",
    icon: <PriceListIcon />,
    color: "#0d47a1",
    category: "Reportes",
    layout: PRICELIST_LAYOUT,
    data: PRICELIST_DATA,
  },
  {
    id: "delivery",
    name: "Nota de Entrega",
    description: "Despacho con datos de almacen, conductor y vehiculo",
    icon: <DeliveryIcon />,
    color: "#2e7d32",
    category: "Reportes",
    layout: DELIVERY_LAYOUT,
    data: DELIVERY_DATA,
  },
  {
    id: "product-label",
    name: "Etiqueta Producto",
    description: "Etiqueta 50x30mm con barcode y precio para productos",
    icon: <LabelIcon />,
    color: "#e65100",
    category: "Etiquetas",
    layout: PRODUCT_BARCODE_LABEL,
    data: PRODUCT_LABEL_DATA,
  },
  {
    id: "shipping-label",
    name: "Etiqueta Envio 4x6",
    description: "Etiqueta de envio estandar con tracking barcode y QR",
    icon: <QrIcon />,
    color: "#4a148c",
    category: "Etiquetas",
    layout: SHIPPING_LABEL,
    data: SHIPPING_LABEL_DATA,
  },
  {
    id: "avery-5160",
    name: "Avery 5160 Direcciones",
    description: "30 etiquetas de direccion por hoja Letter (3x10)",
    icon: <BadgeIcon />,
    color: "#00695c",
    category: "Etiquetas",
    layout: AVERY_5160_ADDRESS,
    data: ADDRESS_LABEL_DATA,
  },
  {
    id: "business-card",
    name: "Tarjeta de Presentacion",
    description: "Avery 5371 -- 10 tarjetas por hoja Letter (2x5)",
    icon: <BadgeIcon />,
    color: "#1a1a2e",
    category: "Tarjetas",
    layout: AVERY_5371_BUSINESS_CARD,
    data: BUSINESS_CARD_DATA,
  },
  {
    id: "inventory-tag",
    name: "Tag Inventario QR",
    description: "Etiqueta 50x25mm con QR code para inventario de almacen",
    icon: <InventoryIcon />,
    color: "#b71c1c",
    category: "Etiquetas",
    layout: INVENTORY_QR_TAG,
    data: INVENTORY_TAG_DATA,
  },
];

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
  const [mode, setMode] = useState<"designer" | "viewer" | "split">("designer");
  const [registered, setRegistered] = useState(false);
  const [layout, setLayout] = useState<ReportLayout>(INVOICE_LAYOUT);
  const [sampleData, setSampleData] = useState<DataSet>(INVOICE_DATA);
  const [snackbar, setSnackbar] = useState<{ message: string; severity: "success" | "info" | "warning" | "error" } | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [fileHandle, setFileHandle] = useState<FileSystemFileHandle | null>(null);
  const [isModified, setIsModified] = useState(false);
  const [lastSaveTime, setLastSaveTime] = useState<Date | null>(null);
  const [zoom, setZoom] = useState(100);
  const [templateDialogOpen, setTemplateDialogOpen] = useState(false);
  const [newMenuAnchor, setNewMenuAnchor] = useState<null | HTMLElement>(null);
  const [recoverySnackbar, setRecoverySnackbar] = useState(false);

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
      const resp = await fetch("/render/pdf", {
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
    setLayout(INVOICE_LAYOUT);
    setSampleData(INVOICE_DATA);
    setFileName(null);
    setFileHandle(null);
    setIsModified(false);
  }, [clearAutosave]);

  // ═══════════════════════════════════════════════════════════════════
  // RENDER
  // ═══════════════════════════════════════════════════════════════════

  const CATEGORY_ORDER: TemplateCategory[] = ["Reportes", "Etiquetas", "Tarjetas"];

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
          {/* ── File group ── */}
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

          <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />

          {/* ── Export group ── */}
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
      {/* STATUS BAR                                                 */}
      {/* ════════════════════════════════════════════════════════════ */}
      <Paper
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
      </Paper>

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
            <Typography variant="h6" sx={{ fontWeight: 700 }}>Galeria de Plantillas</Typography>
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
          <Typography variant="h6" sx={{ fontWeight: 700 }}>Nuevo Reporte</Typography>
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
