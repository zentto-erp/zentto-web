// app/(dashboard)/articulos/new/page.tsx
import ArticuloForm from "@/components/modules/articulos/ArticuloForm";

export const metadata = {
  title: "Nuevo Artículo | DatqBox",
  description: "Crear nuevo artículo",
};

export default function NewArticuloPage() {
  return <ArticuloForm />;
}
