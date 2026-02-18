// app/(dashboard)/proveedores/new/page.tsx
import { ProveedorForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nuevo Proveedor | DatqBox",
  description: "Crear nuevo proveedor",
};

export default function NewProveedorPage() {
  return <ProveedorForm />;
}
