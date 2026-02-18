import { z } from "zod";

export const documentoCobroSchema = z.object({
  tipoDoc: z.enum(["FACT", "N/C", "N/D"]),
  numDoc: z.string().min(1),
  montoAplicar: z.number().positive(),
});

export const formaPagoCobroSchema = z.object({
  formaPago: z.string().min(1),
  monto: z.number().positive(),
  banco: z.string().optional(),
  numCheque: z.string().optional(),
  fechaVencimiento: z.string().optional(),
});

export const aplicarCobroSchema = z.object({
  requestId: z.string().min(1),
  codCliente: z.string().min(1),
  fecha: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  montoTotal: z.number().positive(),
  documentos: z.array(documentoCobroSchema).min(1),
  formasPago: z.array(formaPagoCobroSchema).min(1),
  codUsuario: z.string().min(1),
  observaciones: z.string().optional(),
});

export type DocumentoCobro = z.infer<typeof documentoCobroSchema>;
export type FormaPagoCobro = z.infer<typeof formaPagoCobroSchema>;
export type AplicarCobroDTO = z.infer<typeof aplicarCobroSchema>;
