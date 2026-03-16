import { z } from "zod";

export const loginSchema = z.object({
  usuario: z.string().min(1),
  clave: z.string().min(1),
  companyId: z.coerce.number().int().positive().optional(),
  branchId: z.coerce.number().int().positive().optional(),
  captchaToken: z.string().optional(),
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

export const registerSchema = z.object({
  usuario: z
    .string()
    .min(3, "Usuario minimo 3 caracteres")
    .max(10, "Usuario maximo 10 caracteres")
    .regex(/^[A-Za-z0-9._-]+$/, "Usuario invalido"),
  nombre: z.string().min(3, "Nombre minimo 3 caracteres").max(100, "Nombre muy largo"),
  email: z.string().email("Correo invalido").max(254, "Correo muy largo"),
  password: z
    .string()
    .min(8, "Minimo 8 caracteres")
    .regex(/[A-Z]/, "Debe contener al menos una mayuscula")
    .regex(/[a-z]/, "Debe contener al menos una minuscula")
    .regex(/[0-9]/, "Debe contener al menos un numero"),
  captchaToken: z.string().optional(),
});

export const verifyEmailSchema = z.object({
  token: z.string().min(20, "Token invalido"),
  captchaToken: z.string().optional(),
});

export const forgotPasswordSchema = z.object({
  identifier: z.string().min(1, "Usuario o correo requerido"),
  captchaToken: z.string().optional(),
});

export const resetPasswordByTokenSchema = z.object({
  token: z.string().min(20, "Token invalido"),
  newPassword: z
    .string()
    .min(8, "Minimo 8 caracteres")
    .regex(/[A-Z]/, "Debe contener al menos una mayuscula")
    .regex(/[a-z]/, "Debe contener al menos una minuscula")
    .regex(/[0-9]/, "Debe contener al menos un numero"),
  captchaToken: z.string().optional(),
});

export const resendVerificationSchema = z.object({
  identifier: z.string().min(1, "Usuario o correo requerido"),
  captchaToken: z.string().optional(),
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
