// app/(dashboard)/pagos/new/page.tsx
import { PagoForm } from "@zentto/module-admin";

export const metadata = {
  title: "Nuevo Pago | Zentto",
  description: "Registrar nuevo pago",
};

export default function NewPagoPage() {
  return <PagoForm />;
}
