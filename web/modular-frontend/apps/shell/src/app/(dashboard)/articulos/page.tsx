// app/(dashboard)/articulos/page.tsx
import { ArticulosTable } from "@zentto/module-admin";

export const metadata = {
  title: "Artículos | Zentto",
  description: "Gestión de artículos",
};

export default function ArticulosPage() {
  return <ArticulosTable />;
}
