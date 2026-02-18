import { z } from "zod";

export const loginSchema = z.object({
  usuario: z.string().min(1),
  clave: z.string().min(1)
});

export type LoginRequest = z.infer<typeof loginSchema>;

export type UsuarioRecord = {
  Cod_Usuario: string;
  Password: string | null;
  Nombre: string | null;
  Tipo: string | null;
  Updates: boolean | null;
  Addnews: boolean | null;
  Deletes: boolean | null;
  Creador: boolean | null;
  Cambiar: boolean | null;
  PrecioMinimo: boolean | null;
  Credito: boolean | null;
};

export type UsuarioPermisos = {
  canUpdate: boolean;
  canCreate: boolean;
  canDelete: boolean;
  canChangePrice: boolean;
  canGiveCredit: boolean;
  canChangePwd: boolean;
  isCreator: boolean;
};

export type ModuloAcceso = {
  modulo: string;
  permitido: boolean;
};

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, "Contraseña actual requerida"),
  newPassword: z
    .string()
    .min(6, "Mínimo 6 caracteres")
    .regex(/[A-Z]/, "Debe contener al menos una mayúscula")
    .regex(/[0-9]/, "Debe contener al menos un número"),
});

export const resetPasswordSchema = z.object({
  codUsuario: z.string().min(1),
  newPassword: z.string().min(6, "Mínimo 6 caracteres"),
});

export const setModulosSchema = z.object({
  modulos: z.array(z.object({
    modulo: z.string().min(1),
    permitido: z.boolean(),
  })),
});

/** All identifiable modules in the system */
export const SYSTEM_MODULES = [
  "dashboard",
  "facturas",
  "compras",
  "clientes",
  "proveedores",
  "inventario",
  "articulos",
  "pagos",
  "abonos",
  "cuentas-por-pagar",
  "cxc",
  "cxp",
  "bancos",
  "contabilidad",
  "nomina",
  "configuracion",
  "reportes",
  "usuarios",
] as const;

export type SystemModule = typeof SYSTEM_MODULES[number];
