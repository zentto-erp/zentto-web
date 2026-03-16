// app/(dashboard)/facturas/new/page.tsx
import { FacturaForm } from "@zentto/module-admin";

export const metadata = {
  title: "Nueva Factura | Zentto",
  description: "Crear nueva factura",
};

export default function NewFacturaPage() {
  return <FacturaForm />;
}
