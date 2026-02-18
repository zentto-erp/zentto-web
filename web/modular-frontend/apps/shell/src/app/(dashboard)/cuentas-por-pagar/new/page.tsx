// app/(dashboard)/cuentas-por-pagar/new/page.tsx
import { CuentaPorPagarForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nueva Cuenta por Pagar | DatqBox",
  description: "Crear nueva cuenta por pagar",
};

export default function NewCuentaPorPagarPage() {
  return <CuentaPorPagarForm />;
}
