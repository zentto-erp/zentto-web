/**
 * Mapa de ayuda contextual — vincula cada ruta del frontend con documentación.
 *
 * El componente HelpButton usa este mapa para mostrar el enlace correcto
 * según la ruta actual del usuario.
 *
 * Base URL de documentación: https://zentto.net/docs
 * Formato: pathPrefix → { title, url, description }
 */

export interface HelpEntry {
  title: string;
  url: string;
  description: string;
}

const DOCS_BASE = "https://zentto.net/docs";

export const HELP_MAP: Record<string, HelpEntry> = {
  // ═══════════════════════════════════════════════════════════
  // DASHBOARD / SHELL
  // ═══════════════════════════════════════════════════════════
  "/": {
    title: "Dashboard",
    url: `${DOCS_BASE}/inicio/dashboard`,
    description: "Vista general del sistema, accesos rápidos a módulos y resumen de actividad.",
  },
  "/aplicaciones": {
    title: "Aplicaciones",
    url: `${DOCS_BASE}/inicio/aplicaciones`,
    description: "Catálogo de módulos disponibles. Active o desactive funcionalidades según su plan.",
  },
  "/configuracion": {
    title: "Configuración",
    url: `${DOCS_BASE}/configuracion/general`,
    description: "Ajustes generales del sistema, empresa, sucursales y preferencias.",
  },
  "/configuracion/usuarios": {
    title: "Usuarios",
    url: `${DOCS_BASE}/configuracion/usuarios`,
    description: "Gestión de usuarios, roles y permisos de acceso.",
  },

  // ═══════════════════════════════════════════════════════════
  // CONTABILIDAD
  // ═══════════════════════════════════════════════════════════
  "/contabilidad": {
    title: "Contabilidad",
    url: `${DOCS_BASE}/contabilidad/inicio`,
    description: "Módulo de contabilidad financiera y analítica.",
  },
  "/contabilidad/asientos": {
    title: "Asientos Contables",
    url: `${DOCS_BASE}/contabilidad/asientos`,
    description: "Crear, consultar y anular asientos contables. Los asientos automáticos se generan desde otros módulos.",
  },
  "/contabilidad/plan-cuentas": {
    title: "Plan de Cuentas",
    url: `${DOCS_BASE}/contabilidad/plan-cuentas`,
    description: "Estructura del plan de cuentas contable de su empresa.",
  },
  "/contabilidad/centros-costo": {
    title: "Centros de Costo",
    url: `${DOCS_BASE}/contabilidad/centros-costo`,
    description: "Definición de centros de costo para análisis de gastos.",
  },
  "/contabilidad/activos-fijos": {
    title: "Activos Fijos",
    url: `${DOCS_BASE}/contabilidad/activos-fijos`,
    description: "Registro y control de activos fijos con depreciación automática.",
  },
  "/contabilidad/activos-fijos/depreciacion": {
    title: "Depreciación",
    url: `${DOCS_BASE}/contabilidad/depreciacion`,
    description: "Cálculo y registro de depreciación mensual de activos fijos.",
  },
  "/contabilidad/fiscal/retenciones": {
    title: "Retenciones Fiscales",
    url: `${DOCS_BASE}/contabilidad/retenciones`,
    description: "Comprobantes de retención ISLR/IVA/IRPF, conceptos y unidad tributaria.",
  },
  "/contabilidad/conciliacion": {
    title: "Conciliación Bancaria",
    url: `${DOCS_BASE}/contabilidad/conciliacion-bancaria`,
    description: "Conciliación de movimientos bancarios con extractos del banco.",
  },
  "/contabilidad/presupuestos": {
    title: "Presupuestos",
    url: `${DOCS_BASE}/contabilidad/presupuestos`,
    description: "Definición y seguimiento de presupuestos por centro de costo.",
  },
  "/contabilidad/cierre": {
    title: "Cierre Contable",
    url: `${DOCS_BASE}/contabilidad/cierre`,
    description: "Proceso de cierre de período contable.",
  },

  // ═══════════════════════════════════════════════════════════
  // BANCOS
  // ═══════════════════════════════════════════════════════════
  "/bancos": {
    title: "Bancos",
    url: `${DOCS_BASE}/bancos/inicio`,
    description: "Gestión de cuentas bancarias, movimientos y conciliación.",
  },
  "/bancos/movimientos": {
    title: "Movimientos Bancarios",
    url: `${DOCS_BASE}/bancos/movimientos`,
    description: "Registrar depósitos, cheques, transferencias y notas de débito/crédito.",
  },
  "/bancos/conciliacion": {
    title: "Conciliación",
    url: `${DOCS_BASE}/bancos/conciliacion`,
    description: "Wizard de conciliación bancaria paso a paso.",
  },
  "/bancos/caja-chica": {
    title: "Caja Chica",
    url: `${DOCS_BASE}/bancos/caja-chica`,
    description: "Control de fondos de caja chica y gastos menores.",
  },

  // ═══════════════════════════════════════════════════════════
  // VENTAS
  // ═══════════════════════════════════════════════════════════
  "/ventas": {
    title: "Ventas",
    url: `${DOCS_BASE}/ventas/inicio`,
    description: "Módulo de facturación, presupuestos y gestión de clientes.",
  },
  "/ventas/facturas": {
    title: "Facturas",
    url: `${DOCS_BASE}/ventas/facturas`,
    description: "Emitir, consultar y anular facturas de venta.",
  },
  "/ventas/pedidos-ecommerce": {
    title: "Pedidos Ecommerce",
    url: `${DOCS_BASE}/ventas/pedidos-ecommerce`,
    description: "Pedidos recibidos de la tienda online pendientes de facturar.",
  },
  "/ventas/clientes": {
    title: "Clientes",
    url: `${DOCS_BASE}/ventas/clientes`,
    description: "Gestión de la base de datos de clientes.",
  },
  "/ventas/cxc": {
    title: "Cuentas por Cobrar",
    url: `${DOCS_BASE}/ventas/cuentas-por-cobrar`,
    description: "Cobros, abonos y estado de cuenta de clientes.",
  },

  // ═══════════════════════════════════════════════════════════
  // COMPRAS
  // ═══════════════════════════════════════════════════════════
  "/compras": {
    title: "Compras",
    url: `${DOCS_BASE}/compras/inicio`,
    description: "Órdenes de compra, recepción de facturas y proveedores.",
  },
  "/compras/proveedores": {
    title: "Proveedores",
    url: `${DOCS_BASE}/compras/proveedores`,
    description: "Gestión de proveedores y sus datos fiscales.",
  },
  "/compras/cxp": {
    title: "Cuentas por Pagar",
    url: `${DOCS_BASE}/compras/cuentas-por-pagar`,
    description: "Pagos a proveedores, aplicación de abonos y retenciones.",
  },

  // ═══════════════════════════════════════════════════════════
  // INVENTARIO
  // ═══════════════════════════════════════════════════════════
  "/inventario": {
    title: "Inventario",
    url: `${DOCS_BASE}/inventario/inicio`,
    description: "Control de stock, artículos, movimientos y reportes.",
  },
  "/inventario/articulos": {
    title: "Artículos",
    url: `${DOCS_BASE}/inventario/articulos`,
    description: "Catálogo de productos y servicios.",
  },
  "/inventario/movimientos": {
    title: "Movimientos",
    url: `${DOCS_BASE}/inventario/movimientos`,
    description: "Entradas, salidas y ajustes de inventario.",
  },
  "/inventario/seriales": {
    title: "Seriales",
    url: `${DOCS_BASE}/inventario/seriales`,
    description: "Trazabilidad de productos por número de serie.",
  },
  "/inventario/lotes": {
    title: "Lotes",
    url: `${DOCS_BASE}/inventario/lotes`,
    description: "Control de lotes con fecha de vencimiento y costo.",
  },
  "/inventario/almacenes-wms": {
    title: "Almacenes WMS",
    url: `${DOCS_BASE}/inventario/almacenes-wms`,
    description: "Gestión de almacenes, zonas y ubicaciones (bins).",
  },

  // ═══════════════════════════════════════════════════════════
  // NÓMINA
  // ═══════════════════════════════════════════════════════════
  "/nomina": {
    title: "Nómina",
    url: `${DOCS_BASE}/nomina/inicio`,
    description: "Procesamiento de nómina, vacaciones y liquidaciones.",
  },
  "/nomina/empleados": {
    title: "Empleados",
    url: `${DOCS_BASE}/nomina/empleados`,
    description: "Gestión de empleados y datos laborales.",
  },
  "/nomina/procesar": {
    title: "Procesar Nómina",
    url: `${DOCS_BASE}/nomina/procesar`,
    description: "Cálculo y procesamiento de nómina por período.",
  },
  "/nomina/vacaciones": {
    title: "Vacaciones",
    url: `${DOCS_BASE}/nomina/vacaciones`,
    description: "Solicitudes, aprobaciones y liquidación de vacaciones.",
  },

  // ═══════════════════════════════════════════════════════════
  // POS / RESTAURANTE
  // ═══════════════════════════════════════════════════════════
  "/pos": {
    title: "Punto de Venta",
    url: `${DOCS_BASE}/pos/inicio`,
    description: "Facturación rápida, gestión de caja y reportes POS.",
  },
  "/restaurante": {
    title: "Restaurante",
    url: `${DOCS_BASE}/restaurante/inicio`,
    description: "Gestión de mesas, pedidos, comandas y cierres.",
  },

  // ═══════════════════════════════════════════════════════════
  // ECOMMERCE
  // ═══════════════════════════════════════════════════════════
  "/ecommerce": {
    title: "E-Commerce",
    url: `${DOCS_BASE}/ecommerce/inicio`,
    description: "Tienda en línea, productos, órdenes y pagos.",
  },

  // ═══════════════════════════════════════════════════════════
  // LOGÍSTICA
  // ═══════════════════════════════════════════════════════════
  "/logistica": {
    title: "Logística",
    url: `${DOCS_BASE}/logistica/inicio`,
    description: "Recepción de mercancía, devoluciones, albaranes y transportistas.",
  },
  "/logistica/recepciones": {
    title: "Recepción de Mercancía",
    url: `${DOCS_BASE}/logistica/recepciones`,
    description: "Registrar la recepción de productos comprados con inspección de calidad.",
  },
  "/logistica/devoluciones": {
    title: "Devoluciones",
    url: `${DOCS_BASE}/logistica/devoluciones`,
    description: "Procesar devoluciones de mercancía a proveedores.",
  },
  "/logistica/albaranes": {
    title: "Albaranes / Guías de Despacho",
    url: `${DOCS_BASE}/logistica/albaranes`,
    description: "Generar notas de entrega, despachar y confirmar entregas.",
  },
  "/logistica/transportistas": {
    title: "Transportistas",
    url: `${DOCS_BASE}/logistica/transportistas`,
    description: "Gestión de empresas de transporte y conductores.",
  },

  // ═══════════════════════════════════════════════════════════
  // CRM
  // ═══════════════════════════════════════════════════════════
  "/crm": {
    title: "CRM",
    url: `${DOCS_BASE}/crm/inicio`,
    description: "Pipeline de ventas, leads, actividades y seguimiento comercial.",
  },
  "/crm/pipeline": {
    title: "Pipeline",
    url: `${DOCS_BASE}/crm/pipeline`,
    description: "Tablero Kanban con etapas de venta y leads por columna.",
  },
  "/crm/leads": {
    title: "Leads",
    url: `${DOCS_BASE}/crm/leads`,
    description: "Gestión de oportunidades de negocio y seguimiento.",
  },
  "/crm/actividades": {
    title: "Actividades",
    url: `${DOCS_BASE}/crm/actividades`,
    description: "Llamadas, emails, reuniones y tareas de seguimiento.",
  },

  // ═══════════════════════════════════════════════════════════
  // MANUFACTURA
  // ═══════════════════════════════════════════════════════════
  "/manufactura": {
    title: "Manufactura",
    url: `${DOCS_BASE}/manufactura/inicio`,
    description: "Listas de materiales, centros de trabajo y órdenes de producción.",
  },
  "/manufactura/bom": {
    title: "Lista de Materiales (BOM)",
    url: `${DOCS_BASE}/manufactura/bom`,
    description: "Definir recetas de producción con componentes, cantidades y costos.",
  },
  "/manufactura/centros-trabajo": {
    title: "Centros de Trabajo",
    url: `${DOCS_BASE}/manufactura/centros-trabajo`,
    description: "Configurar estaciones de trabajo con capacidad y costo por hora.",
  },
  "/manufactura/ordenes": {
    title: "Órdenes de Producción",
    url: `${DOCS_BASE}/manufactura/ordenes`,
    description: "Crear y gestionar órdenes de producción con seguimiento de estado.",
  },

  // ═══════════════════════════════════════════════════════════
  // FLOTA
  // ═══════════════════════════════════════════════════════════
  "/flota": {
    title: "Control de Flota",
    url: `${DOCS_BASE}/flota/inicio`,
    description: "Vehículos, combustible, mantenimiento y viajes.",
  },
  "/flota/vehiculos": {
    title: "Vehículos",
    url: `${DOCS_BASE}/flota/vehiculos`,
    description: "Registro de vehículos con datos técnicos, seguros y documentos.",
  },
  "/flota/combustible": {
    title: "Combustible",
    url: `${DOCS_BASE}/flota/combustible`,
    description: "Registro de cargas de combustible con costos y rendimiento.",
  },
  "/flota/mantenimiento": {
    title: "Mantenimiento",
    url: `${DOCS_BASE}/flota/mantenimiento`,
    description: "Órdenes de mantenimiento preventivo y correctivo.",
  },
  "/flota/viajes": {
    title: "Viajes",
    url: `${DOCS_BASE}/flota/viajes`,
    description: "Registro de viajes con origen, destino y kilometraje.",
  },

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  "/auditoria": {
    title: "Auditoría",
    url: `${DOCS_BASE}/auditoria/inicio`,
    description: "Registro de acciones, alertas del sistema y trazabilidad.",
  },
};

/**
 * Busca la entrada de ayuda más específica para una ruta dada.
 * Ejemplo: "/contabilidad/activos-fijos/depreciacion" → match exacto
 *          "/contabilidad/activos-fijos/123" → match "/contabilidad/activos-fijos"
 *          "/contabilidad/algo-raro" → match "/contabilidad"
 */
export function getHelpForPath(pathname: string): HelpEntry | null {
  // Intentar match exacto
  if (HELP_MAP[pathname]) return HELP_MAP[pathname];

  // Intentar match parcial (remover segmentos del final)
  const parts = pathname.split("/").filter(Boolean);
  while (parts.length > 0) {
    const partial = "/" + parts.join("/");
    if (HELP_MAP[partial]) return HELP_MAP[partial];
    parts.pop();
  }

  return HELP_MAP["/"] || null;
}
