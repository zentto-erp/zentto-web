// app/(dashboard)/articulos/new/page.tsx
import { ArticuloForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nuevo Artículo | DatqBox",
  description: "Crear nuevo artículo",
};

export default function NewArticuloPage() {
  return <ArticuloForm />;
}
