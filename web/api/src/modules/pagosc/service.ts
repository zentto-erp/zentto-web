import { createPago, createPagoTx, deletePago, getPago, getPagoDetalle, listPagos, updatePago } from "../pagos/service.js";

const VES = "VES";

export async function listPagosC(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  return listPagos(params, { currencyCode: VES });
}

export async function getPagoC(id: string) {
  return getPago(id, { currencyCode: VES });
}

export async function getPagoCDetalle(id: string) {
  return getPagoDetalle(id, { currencyCode: VES });
}

export async function createPagoC(body: Record<string, unknown>) {
  return createPago(body, { currencyCode: VES });
}

export async function updatePagoC(id: string, body: Record<string, unknown>) {
  return updatePago(id, body, { currencyCode: VES });
}

export async function deletePagoC(id: string) {
  return deletePago(id, { currencyCode: VES });
}

export async function createPagoCTx(payload: { pago: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return createPagoTx(payload, { currencyCode: VES });
}
