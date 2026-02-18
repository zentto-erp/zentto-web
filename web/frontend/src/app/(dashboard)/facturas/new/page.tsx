// app/(dashboard)/facturas/new/page.tsx
import FacturaForm from "@/components/modules/facturas/FacturaForm";

export const metadata = {
  title: "Nueva Factura | DatqBox",
  description: "Crear nueva factura",
};

export default function NewFacturaPage() {
  return <FacturaForm />;
}
