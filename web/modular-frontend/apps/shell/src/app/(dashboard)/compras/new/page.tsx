// app/(dashboard)/compras/new/page.tsx
import { CompraForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nueva Compra | DatqBox",
  description: "Crear nueva compra",
};

export default function NewCompraPage() {
  return <CompraForm />;
}
