"use client";

// ── Components ──────────────────────────────────────────────
export { MapaMesas } from "./components/MapaMesas";
export { MesaCard } from "./components/MesaCard";
export { PanelPedido } from "./components/PanelPedido";
export { VistaCocina } from "./components/VistaCocina";
export { RestauranteSettingsModal } from "./components/RestauranteSettingsModal";

// ── Hooks ───────────────────────────────────────────────────
export {
  useRestaurante,
  type Mesa,
  type Ambiente,
  type Pedido,
  type ItemPedido,
  type ProductoMenu,
  type ComandaCocina,
} from "./hooks/useRestaurante";
export * from "./hooks/useRestauranteAdmin";
export { useScopedGridId, useGridRegistration } from "./lib/zentto-grid";

// ── Pages ───────────────────────────────────────────────────
export { RestauranteDashboardPage } from "./pages/RestauranteDashboardPage";
export { CocinaPage } from "./pages/CocinaPage";
export { FiscalPage } from "./pages/FiscalPage";
export { ReportesPage } from "./pages/ReportesPage";
export { AmbientesPage } from "./pages/admin/AmbientesPage";
export { ComprasPage } from "./pages/admin/ComprasPage";
export { ConfiguracionPage } from "./pages/admin/ConfiguracionPage";
export { InsumosPage } from "./pages/admin/InsumosPage";
export { ProductosPage } from "./pages/admin/ProductosPage";
export { RecetasPage } from "./pages/admin/RecetasPage";
