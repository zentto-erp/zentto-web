// app/(dashboard)/proveedores/new/page.tsx
import { ProveedorForm } from "@zentto/module-admin";

export const metadata = {
  title: "Nuevo Proveedor | Zentto",
  description: "Crear nuevo proveedor",
};

export default function NewProveedorPage() {
  return <ProveedorForm />;
}
