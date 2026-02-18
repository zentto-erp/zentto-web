// app/(dashboard)/inventario/ajuste/page.tsx
import { AjusteInventarioForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Ajuste de Inventario | DatqBox",
  description: "Registrar ajuste de inventario",
};

export default function AjusteInventarioPage() {
  return <AjusteInventarioForm />;
}
