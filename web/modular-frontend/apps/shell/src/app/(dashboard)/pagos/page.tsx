// app/(dashboard)/pagos/page.tsx
import { PagosTable } from "@datqbox/module-admin";

export const metadata = {
  title: "Pagos | DatqBox",
  description: "Registro de pagos",
};

export default function PagosPage() {
  return <PagosTable />;
}
