import { PagoTxForm } from "@zentto/module-admin";

export const metadata = {
  title: "Pago CxP TX | Zentto",
  description: "Aplicar pago transaccional para cuentas por pagar"
};

export default function CxpTxPage() {
  return <PagoTxForm />;
}

