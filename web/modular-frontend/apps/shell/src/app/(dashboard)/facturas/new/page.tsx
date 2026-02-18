// app/(dashboard)/facturas/new/page.tsx
import { FacturaForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nueva Factura | DatqBox",
  description: "Crear nueva factura",
};

export default function NewFacturaPage() {
  return <FacturaForm />;
}
