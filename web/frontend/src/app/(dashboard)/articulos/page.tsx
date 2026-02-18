// app/(dashboard)/articulos/page.tsx
import ArticulosTable from "@/components/modules/articulos/ArticulosTable";

export const metadata = {
  title: "Artículos | DatqBox",
  description: "Gestión de artículos",
};

export default function ArticulosPage() {
  return <ArticulosTable />;
}
