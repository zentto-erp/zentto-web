"use client";

// ── Components ──────────────────────────────────────────────
export { PosCart, type CartItem } from "./components/PosCart";
export { PosNumpad } from "./components/PosNumpad";
export { PosPaymentButton } from "./components/PosPaymentButton";
export { PosProductGrid, type Product } from "./components/PosProductGrid";
export { PosHeader } from "./components/PosHeader";
export { PosPaymentModal } from "./components/PosPaymentModal";
export { PosCustomerSearch, type Customer } from "./components/PosCustomerSearch";
export { PosEsperaDrawer } from "./components/PosEsperaDrawer";
export { PosSettingsModal } from "./components/PosSettingsModal";

// ── Hooks ───────────────────────────────────────────────────
export {
  useBuscarProductos,
  useBuscarClientes,
  useCrearFactura,
  usePrinterStatus,
  useConfiguracionCaja,
  useCategoriasPOS,
  usePosReporteResumen,
  usePosReporteVentas,
  usePosReporteProductosTop,
  usePosReporteFormasPago,
  usePosReporteCajas,
  usePosCorrelativosFiscales,
  useGuardarPosCorrelativoFiscal,
  useCart,
  type Producto,
  type Cliente,
  type FacturaPayload,
  type PosReporteResumen,
  type PosReporteVenta,
  type PosReporteProductoTop,
  type PosReporteFormaPago,
  type PosReporteCaja,
  type PosCorrelativoFiscal,
} from "./hooks/usePosApi";
export { useBarcodeScanner } from "./hooks/useBarcodeScanner";

// ── Pages ───────────────────────────────────────────────────
export { PosDashboardPage } from "./pages/PosDashboardPage";
export { FacturacionPage } from "./pages/FacturacionPage";
export { CierreCajaPage } from "./pages/CierreCajaPage";
export { ConfiguracionPage } from "./pages/ConfiguracionPage";
export { CorrelativosFiscalesPage } from "./pages/CorrelativosFiscalesPage";
export { FiscalPage } from "./pages/FiscalPage";
export { ReportesPage } from "./pages/ReportesPage";
