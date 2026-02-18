// app/(dashboard)/compras/new/page.tsx
import CompraForm from "@/components/modules/compras/CompraForm";

export const metadata = {
  title: "Nueva Compra | DatqBox",
  description: "Crear nueva compra",
};

export default function NewCompraPage() {
  return <CompraForm />;
}
