// app/(dashboard)/proveedores/new/page.tsx
import ProveedorForm from "@/components/modules/proveedores/ProveedorForm";

export const metadata = {
  title: "Nuevo Proveedor | DatqBox",
  description: "Crear nuevo proveedor",
};

export default function NewProveedorPage() {
  return <ProveedorForm />;
}
