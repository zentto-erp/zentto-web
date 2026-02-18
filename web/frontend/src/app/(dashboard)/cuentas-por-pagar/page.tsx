// app/(dashboard)/cuentas-por-pagar/page.tsx
import CuentasPorPagarTable from "@/components/modules/cuentas-por-pagar/CuentasPorPagarTable";

export const metadata = {
  title: "Cuentas por Pagar | DatqBox",
  description: "Gestión de cuentas por pagar",
};

export default function CuentasPorPagarPage() {
  return <CuentasPorPagarTable />;
}
