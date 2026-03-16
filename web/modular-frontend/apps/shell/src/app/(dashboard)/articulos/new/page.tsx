// app/(dashboard)/articulos/new/page.tsx
import { ArticuloForm } from "@zentto/module-admin";

export const metadata = {
  title: "Nuevo Artículo | Zentto",
  description: "Crear nuevo artículo",
};

export default function NewArticuloPage() {
  return <ArticuloForm />;
}
