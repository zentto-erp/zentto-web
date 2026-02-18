// app/(dashboard)/pagos/page.tsx
import PagosTable from "@/components/modules/pagos/PagosTable";

export const metadata = {
  title: "Pagos | DatqBox",
  description: "Registro de pagos",
};

export default function PagosPage() {
  return <PagosTable />;
}
