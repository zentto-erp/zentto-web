// app/(dashboard)/pagos/page.tsx
import { PagosTable } from "@zentto/module-admin";

export const metadata = {
  title: "Pagos | Zentto",
  description: "Registro de pagos",
};

export default function PagosPage() {
  return <PagosTable />;
}
