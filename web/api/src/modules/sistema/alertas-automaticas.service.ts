/**
 * Servicio de alertas automáticas del sistema.
 * Genera notificaciones automáticas basadas en eventos y condiciones del negocio.
 * Diseñado para ejecutarse vía cron job periódicamente.
 */
import { callSp } from "../../db/query.js";

interface AlertaGenerada {
  tipo: "info" | "success" | "warning" | "error";
  titulo: string;
  mensaje: string;
  usuarioId: string | null; // null = global (todos los usuarios)
  rutaNavegacion: string | null;
  /**
   * Codigo de la app donde aparece la notificacion: 'nomina',
   * 'inventario', 'ventas', 'compras', 'contabilidad', 'bancos', etc.
   * null = broadcast a todas las apps.
   */
  appCode: string | null;
  /** Empresa a la que pertenece la alerta. null = global. */
  companyId: number | null;
}

async function insertNotificacion(alerta: AlertaGenerada) {
  await callSp("usp_Sys_Notificacion_Insert", {
    Tipo: alerta.tipo,
    Titulo: alerta.titulo,
    Mensaje: alerta.mensaje,
    UsuarioId: alerta.usuarioId,
    RutaNavegacion: alerta.rutaNavegacion,
    CompanyId: alerta.companyId,
    AppCode: alerta.appCode,
  });
}

// ── Facturas vencidas (CxC) ──────────────────────────────────
async function checkFacturasVencidas(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number; montoTotal: number }>(
      "usp_Sys_Alert_FacturasVencidas"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "warning",
        titulo: "Facturas vencidas",
        mensaje: `Hay ${r.cantidad} facturas vencidas por un total de ${r.montoTotal?.toFixed(2) ?? "0.00"}`,
        usuarioId: null,
        rutaNavegacion: "/ventas/cxc",
        appCode: "ventas",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── Stock bajo (Inventario) ──────────────────────────────────
async function checkStockBajo(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number }>(
      "usp_Sys_Alert_StockBajo"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "error",
        titulo: "Stock bajo",
        mensaje: `${r.cantidad} artículos están por debajo del stock mínimo`,
        usuarioId: null,
        rutaNavegacion: "/inventario",
        appCode: "inventario",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── CxP por vencer (Compras) ─────────────────────────────────
async function checkCxpPorVencer(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number; montoTotal: number }>(
      "usp_Sys_Alert_CxpPorVencer"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "warning",
        titulo: "Pagos próximos a vencer",
        mensaje: `${r.cantidad} documentos por pagar vencen en los próximos 7 días (${r.montoTotal?.toFixed(2) ?? "0.00"})`,
        usuarioId: null,
        rutaNavegacion: "/compras/cxp",
        appCode: "compras",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── Conciliación bancaria pendiente ──────────────────────────
async function checkConciliacionPendiente(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number }>(
      "usp_Sys_Alert_ConciliacionPendiente"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "info",
        titulo: "Conciliaciones pendientes",
        mensaje: `${r.cantidad} cuentas bancarias tienen conciliación pendiente este mes`,
        usuarioId: null,
        rutaNavegacion: "/bancos/conciliacion",
        appCode: "bancos",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── Nómina sin procesar ──────────────────────────────────────
async function checkNominaPendiente(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ pendiente: number }>(
      "usp_Sys_Alert_NominaPendiente"
    );
    const r = rows[0];
    if (r && r.pendiente > 0) {
      alertas.push({
        tipo: "warning",
        titulo: "Nómina pendiente",
        mensaje: "La nómina del período actual no ha sido procesada",
        usuarioId: null,
        rutaNavegacion: "/nomina",
        appCode: "nomina",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── Asientos contables sin aprobar ───────────────────────────
async function checkAsientosBorrador(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number }>(
      "usp_Sys_Alert_AsientosBorrador"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "info",
        titulo: "Asientos en borrador",
        mensaje: `${r.cantidad} asientos contables pendientes de aprobación`,
        usuarioId: null,
        rutaNavegacion: "/contabilidad/asientos",
        appCode: "contabilidad",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

// ── Vacaciones por aprobar ───────────────────────────────────
async function checkVacacionesPendientes(): Promise<AlertaGenerada[]> {
  const alertas: AlertaGenerada[] = [];
  try {
    const rows = await callSp<{ cantidad: number }>(
      "usp_Sys_Alert_VacacionesPendientes"
    );
    const r = rows[0];
    if (r && r.cantidad > 0) {
      alertas.push({
        tipo: "info",
        titulo: "Solicitudes de vacaciones",
        mensaje: `${r.cantidad} solicitudes de vacaciones pendientes de aprobación`,
        usuarioId: null,
        rutaNavegacion: "/nomina/vacaciones/solicitudes",
        appCode: "nomina",
        companyId: null,
      });
    }
  } catch { /* SP no existe aún — skip */ }
  return alertas;
}

/**
 * Ejecuta todas las verificaciones y genera notificaciones.
 * Diseñado para llamarse desde un cron job (ej: cada hora).
 */
export async function processSystemAlerts(): Promise<{
  generated: number;
  checks: string[];
  errors: string[];
}> {
  const checks: string[] = [];
  const errors: string[] = [];
  let generated = 0;

  const allChecks = [
    { name: "facturas_vencidas", fn: checkFacturasVencidas },
    { name: "stock_bajo", fn: checkStockBajo },
    { name: "cxp_por_vencer", fn: checkCxpPorVencer },
    { name: "conciliacion_pendiente", fn: checkConciliacionPendiente },
    { name: "nomina_pendiente", fn: checkNominaPendiente },
    { name: "asientos_borrador", fn: checkAsientosBorrador },
    { name: "vacaciones_pendientes", fn: checkVacacionesPendientes },
  ];

  for (const check of allChecks) {
    try {
      const alertas = await check.fn();
      for (const alerta of alertas) {
        try {
          await insertNotificacion(alerta);
          generated++;
        } catch {
          errors.push(`insert_${check.name}`);
        }
      }
      checks.push(check.name);
    } catch {
      errors.push(check.name);
    }
  }

  return { generated, checks, errors };
}
