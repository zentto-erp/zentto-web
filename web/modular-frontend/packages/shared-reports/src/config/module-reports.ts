/**
 * Mapeo módulo → reportes disponibles.
 *
 * Cada módulo del ERP tiene una lista de reportes asociados, organizados por
 * categoría (category) y país (country). El campo `templateId` coincide con
 * el `id` registrado en @zentto/report-core REPORT_TEMPLATES.
 *
 * Los clientes pueden reemplazar el template asignado a un slot mediante la
 * API de configuración (solo administradores).
 */

export interface ModuleReportSlot {
  /** Identificador único del slot dentro del módulo */
  slotId: string;
  /** Nombre legible para UI */
  label: string;
  /** Descripción corta */
  description: string;
  /** Categoría funcional */
  category: 'nomina' | 'facturacion' | 'liquidacion' | 'contabilidad' | 'rrhh' | 'compras' | 'ventas' | 'pos' | 'inventario' | 'logistica' | 'general';
  /** País (ISO 3166-1 alpha-2) o 'all' para genéricos */
  country: 'VE' | 'ES' | 'CO' | 'MX' | 'US' | 'all';
  /** Template por defecto (de la galería built-in) */
  defaultTemplateId: string;
  /** Icono para UI */
  icon: string;
}

export interface ModuleReportConfig {
  moduleId: string;
  moduleName: string;
  slots: ModuleReportSlot[];
}

// ─── Definiciones por módulo ─────────────────────────────────────────

export const MODULE_REPORT_MAP: ModuleReportConfig[] = [
  // ── Nómina ──────────────────────────────────────────────────────────
  {
    moduleId: 'nomina',
    moduleName: 'Nómina',
    slots: [
      // Recibos de pago por país
      { slotId: 'nomina-recibo-ve', label: 'Recibo de Nómina (VE)', description: 'LOTTT Art. 106', category: 'nomina', country: 'VE', defaultTemplateId: 've-payroll-receipt', icon: '🇻🇪' },
      { slotId: 'nomina-recibo-es', label: 'Recibo de Salarios (ES)', description: 'Orden ESS/2098/2014', category: 'nomina', country: 'ES', defaultTemplateId: 'es-payslip', icon: '🇪🇸' },
      { slotId: 'nomina-recibo-co', label: 'Comprobante Nómina (CO)', description: 'CST Art. 135', category: 'nomina', country: 'CO', defaultTemplateId: 'co-payroll-receipt', icon: '🇨🇴' },
      { slotId: 'nomina-recibo-mx', label: 'CFDI Nómina (MX)', description: 'Art. 99 LISR', category: 'nomina', country: 'MX', defaultTemplateId: 'mx-cfdi-payroll', icon: '🇲🇽' },
      { slotId: 'nomina-recibo-us', label: 'Pay Stub (US)', description: 'FLSA + state laws', category: 'nomina', country: 'US', defaultTemplateId: 'us-pay-stub', icon: '🇺🇸' },
      // Liquidaciones por país
      { slotId: 'nomina-liquidacion-ve', label: 'Liquidación (VE)', description: 'LOTTT Arts. 141-147', category: 'liquidacion', country: 'VE', defaultTemplateId: 've-final-settlement', icon: '🇻🇪' },
      { slotId: 'nomina-liquidacion-es', label: 'Finiquito (ES)', description: 'ET Art. 49.2', category: 'liquidacion', country: 'ES', defaultTemplateId: 'es-settlement', icon: '🇪🇸' },
      { slotId: 'nomina-liquidacion-co', label: 'Liquidación Prestaciones (CO)', description: 'CST Arts. 64, 249', category: 'liquidacion', country: 'CO', defaultTemplateId: 'co-benefits-settlement', icon: '🇨🇴' },
      { slotId: 'nomina-liquidacion-mx', label: 'Finiquito (MX)', description: 'Arts. 48-50 LFT', category: 'liquidacion', country: 'MX', defaultTemplateId: 'mx-settlement', icon: '🇲🇽' },
      { slotId: 'nomina-liquidacion-us', label: 'Termination (US)', description: 'State employment laws', category: 'liquidacion', country: 'US', defaultTemplateId: 'us-termination', icon: '🇺🇸' },
    ],
  },

  // ── Ventas ──────────────────────────────────────────────────────────
  {
    moduleId: 'ventas',
    moduleName: 'Ventas',
    slots: [
      { slotId: 'ventas-factura-ve', label: 'Factura Fiscal (VE)', description: 'Providencia SNAT/2011/0071', category: 'facturacion', country: 'VE', defaultTemplateId: 've-fiscal-invoice', icon: '🇻🇪' },
      { slotId: 'ventas-factura-es', label: 'Factura Ordinaria (ES)', description: 'RD 1619/2012', category: 'facturacion', country: 'ES', defaultTemplateId: 'es-invoice', icon: '🇪🇸' },
      { slotId: 'ventas-factura-co', label: 'Factura Electrónica (CO)', description: 'Art. 617 ET', category: 'facturacion', country: 'CO', defaultTemplateId: 'co-electronic-invoice', icon: '🇨🇴' },
      { slotId: 'ventas-factura-mx', label: 'CFDI Factura (MX)', description: 'Art. 29 CFF', category: 'facturacion', country: 'MX', defaultTemplateId: 'mx-cfdi-income', icon: '🇲🇽' },
      { slotId: 'ventas-factura-us', label: 'Commercial Invoice (US)', description: 'UCC Art 2', category: 'facturacion', country: 'US', defaultTemplateId: 'us-commercial-invoice', icon: '🇺🇸' },
      { slotId: 'ventas-factura-generica', label: 'Factura Genérica', description: 'Template multi-país', category: 'facturacion', country: 'all', defaultTemplateId: 'invoice', icon: '🧾' },
      { slotId: 'ventas-nota-credito', label: 'Nota de Crédito', description: 'Crédito referenciado a factura', category: 'ventas', country: 'all', defaultTemplateId: 'credit-note', icon: '↩️' },
      { slotId: 'ventas-cotizacion', label: 'Cotización / Presupuesto', description: 'Cotización con validez y condiciones', category: 'ventas', country: 'all', defaultTemplateId: 'quote', icon: '📝' },
    ],
  },

  // ── Compras ─────────────────────────────────────────────────────────
  {
    moduleId: 'compras',
    moduleName: 'Compras',
    slots: [
      { slotId: 'compras-orden', label: 'Orden de Compra', description: 'Orden a proveedor con items y condiciones', category: 'compras', country: 'all', defaultTemplateId: 'purchase-order', icon: '🛒' },
    ],
  },

  // ── Inventario ─────────────────────────────────────────────────────
  {
    moduleId: 'inventario',
    moduleName: 'Inventario',
    slots: [
      { slotId: 'inventario-nota-entrega', label: 'Nota de Entrega', description: 'Guía de despacho / remisión', category: 'inventario', country: 'all', defaultTemplateId: 'delivery-note', icon: '📦' },
      { slotId: 'inventario-lista-precios', label: 'Lista de Precios', description: 'Catálogo de productos con precios', category: 'inventario', country: 'all', defaultTemplateId: 'pricelist', icon: '💲' },
      { slotId: 'inventario-etiqueta-producto', label: 'Etiqueta Producto', description: 'Etiqueta 50x30mm con código de barras', category: 'inventario', country: 'all', defaultTemplateId: 'product-barcode', icon: '🏷️' },
      { slotId: 'inventario-etiqueta-qr', label: 'Etiqueta QR Almacén', description: 'Etiqueta con QR para control de inventario', category: 'inventario', country: 'all', defaultTemplateId: 'inventory-qr-tag', icon: '📦' },
    ],
  },

  // ── POS ─────────────────────────────────────────────────────────────
  {
    moduleId: 'pos',
    moduleName: 'Punto de Venta',
    slots: [
      { slotId: 'pos-recibo-80mm', label: 'Recibo POS 80mm', description: 'Recibo para impresora térmica 80mm', category: 'pos', country: 'all', defaultTemplateId: 'pos-receipt-80mm', icon: '🧾' },
      { slotId: 'pos-recibo-58mm', label: 'Recibo POS 58mm', description: 'Recibo compacto 58mm', category: 'pos', country: 'all', defaultTemplateId: 'pos-receipt-58mm', icon: '🧾' },
      { slotId: 'pos-etiqueta-precio', label: 'Etiqueta de Precio', description: 'Etiqueta de góndola/estantería', category: 'pos', country: 'all', defaultTemplateId: 'price-tag', icon: '💲' },
    ],
  },

  // ── Contabilidad ───────────────────────────────────────────────────
  {
    moduleId: 'contabilidad',
    moduleName: 'Contabilidad',
    slots: [
      // Fase 2 — por ahora mapea genéricos
      { slotId: 'contabilidad-balance-general', label: 'Balance General', description: 'Estado de situación financiera', category: 'contabilidad', country: 'all', defaultTemplateId: 'invoice', icon: '📊' },
      { slotId: 'contabilidad-estado-resultados', label: 'Estado de Resultados', description: 'Pérdidas y ganancias', category: 'contabilidad', country: 'all', defaultTemplateId: 'invoice', icon: '📈' },
    ],
  },

  // ── Bancos ─────────────────────────────────────────────────────────
  {
    moduleId: 'bancos',
    moduleName: 'Bancos',
    slots: [
      { slotId: 'bancos-conciliacion', label: 'Reporte Conciliación', description: 'Conciliación bancaria con diferencias', category: 'general', country: 'all', defaultTemplateId: 'invoice', icon: '🏦' },
    ],
  },

  // ── Restaurante ────────────────────────────────────────────────────
  {
    moduleId: 'restaurante',
    moduleName: 'Restaurante',
    slots: [
      { slotId: 'restaurante-comanda', label: 'Comanda de Cocina', description: 'Orden para cocina/barra', category: 'pos', country: 'all', defaultTemplateId: 'pos-receipt-80mm', icon: '🍽️' },
      { slotId: 'restaurante-cuenta', label: 'Cuenta de Mesa', description: 'Detalle de consumo por mesa', category: 'pos', country: 'all', defaultTemplateId: 'pos-receipt-80mm', icon: '🧾' },
    ],
  },

  // ── E-commerce ─────────────────────────────────────────────────────
  {
    moduleId: 'ecommerce',
    moduleName: 'E-commerce',
    slots: [
      { slotId: 'ecommerce-etiqueta-envio', label: 'Etiqueta de Envío', description: 'Etiqueta 4x6" para paquetes', category: 'logistica', country: 'all', defaultTemplateId: 'shipping-label', icon: '📦' },
      { slotId: 'ecommerce-factura', label: 'Factura E-commerce', description: 'Factura para venta online', category: 'facturacion', country: 'all', defaultTemplateId: 'invoice', icon: '🧾' },
    ],
  },

  // ── Logística ──────────────────────────────────────────────────────
  {
    moduleId: 'logistica',
    moduleName: 'Logística',
    slots: [
      { slotId: 'logistica-etiqueta-envio', label: 'Etiqueta de Envío', description: 'Etiqueta de despacho 4x6"', category: 'logistica', country: 'all', defaultTemplateId: 'shipping-label', icon: '📦' },
      { slotId: 'logistica-guia-despacho', label: 'Guía de Despacho', description: 'Documento de transporte', category: 'logistica', country: 'all', defaultTemplateId: 'delivery-note', icon: '🚚' },
    ],
  },

  // ── CRM ────────────────────────────────────────────────────────────
  {
    moduleId: 'crm',
    moduleName: 'CRM',
    slots: [
      { slotId: 'crm-cotizacion', label: 'Cotización CRM', description: 'Propuesta comercial para prospecto', category: 'ventas', country: 'all', defaultTemplateId: 'quote', icon: '📝' },
      { slotId: 'crm-tarjeta-presentacion', label: 'Tarjeta de Presentación', description: 'Avery 5371 business cards', category: 'general', country: 'all', defaultTemplateId: 'business-card', icon: '💼' },
    ],
  },

  // ── Manufactura ────────────────────────────────────────────────────
  {
    moduleId: 'manufactura',
    moduleName: 'Manufactura',
    slots: [
      { slotId: 'manufactura-orden-produccion', label: 'Orden de Producción', description: 'Orden de trabajo con BOM y pasos', category: 'general', country: 'all', defaultTemplateId: 'purchase-order', icon: '🏭' },
      { slotId: 'manufactura-etiqueta-lote', label: 'Etiqueta de Lote', description: 'Etiqueta con QR para trazabilidad', category: 'inventario', country: 'all', defaultTemplateId: 'inventory-qr-tag', icon: '🏷️' },
    ],
  },

  // ── Flota ──────────────────────────────────────────────────────────
  {
    moduleId: 'flota',
    moduleName: 'Flota',
    slots: [
      { slotId: 'flota-inspeccion', label: 'Reporte Inspección', description: 'Checklist de inspección vehicular', category: 'general', country: 'all', defaultTemplateId: 'invoice', icon: '🚗' },
    ],
  },

  // ── Shipping ───────────────────────────────────────────────────────
  {
    moduleId: 'shipping',
    moduleName: 'Shipping',
    slots: [
      { slotId: 'shipping-etiqueta', label: 'Etiqueta de Envío', description: 'Etiqueta carrier UPS/FedEx/DHL', category: 'logistica', country: 'all', defaultTemplateId: 'shipping-label', icon: '📦' },
      { slotId: 'shipping-direcciones', label: 'Etiquetas Dirección', description: 'Avery 5160 — 30 por hoja', category: 'logistica', country: 'all', defaultTemplateId: 'avery-5160-address', icon: '✉️' },
    ],
  },

  // ── Auditoría ──────────────────────────────────────────────────────
  {
    moduleId: 'auditoria',
    moduleName: 'Auditoría',
    slots: [
      { slotId: 'auditoria-log', label: 'Reporte de Auditoría', description: 'Log de eventos y cambios del sistema', category: 'general', country: 'all', defaultTemplateId: 'invoice', icon: '🔍' },
    ],
  },

  // ── Shell (Dashboard) ──────────────────────────────────────────────
  {
    moduleId: 'shell',
    moduleName: 'Dashboard',
    slots: [
      { slotId: 'shell-credencial', label: 'Credencial / Gafete', description: 'Credencial de empleado con QR', category: 'rrhh', country: 'all', defaultTemplateId: 'id-badge', icon: '🪪' },
    ],
  },
];

// ─── Helpers ─────────────────────────────────────────────────────────

/** Obtener configuración de reportes para un módulo */
export function getModuleReports(moduleId: string): ModuleReportConfig | undefined {
  return MODULE_REPORT_MAP.find(m => m.moduleId === moduleId);
}

/** Obtener todos los slots de un módulo */
export function getModuleSlots(moduleId: string): ModuleReportSlot[] {
  return MODULE_REPORT_MAP.find(m => m.moduleId === moduleId)?.slots ?? [];
}

/** Obtener slots filtrados por país */
export function getModuleSlotsByCountry(moduleId: string, country: string): ModuleReportSlot[] {
  const slots = getModuleSlots(moduleId);
  return slots.filter(s => s.country === country || s.country === 'all');
}

/** Obtener un slot específico */
export function getSlot(moduleId: string, slotId: string): ModuleReportSlot | undefined {
  return getModuleSlots(moduleId).find(s => s.slotId === slotId);
}

/** Todos los módulos que tienen reportes configurados */
export function getModulesWithReports(): ModuleReportConfig[] {
  return MODULE_REPORT_MAP;
}
