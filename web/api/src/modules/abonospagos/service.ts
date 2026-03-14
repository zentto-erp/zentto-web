import { createAbono, deleteAbono, getAbono, listAbonos, updateAbono } from "../abonos/service.js";

export async function listAbonosPagos(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  return listAbonos(params);
}

export async function getAbonosPagos(id: string) {
  return getAbono(id);
}

export async function createAbonosPagos(body: Record<string, unknown>) {
  return createAbono(body);
}

export async function updateAbonosPagos(id: string, body: Record<string, unknown>) {
  return updateAbono(id, body);
}

export async function deleteAbonosPagos(id: string) {
  return deleteAbono(id);
}
