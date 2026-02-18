// app/(dashboard)/articulos/page.tsx
import { ArticulosTable } from "@datqbox/module-admin";

export const metadata = {
  title: "Artículos | DatqBox",
  description: "Gestión de artículos",
};

export default function ArticulosPage() {
  return <ArticulosTable />;
}
