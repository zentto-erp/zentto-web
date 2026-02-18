import { PagoTxForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Pago CxP TX | DatqBox",
  description: "Aplicar pago transaccional para cuentas por pagar"
};

export default function CxpTxPage() {
  return <PagoTxForm />;
}

