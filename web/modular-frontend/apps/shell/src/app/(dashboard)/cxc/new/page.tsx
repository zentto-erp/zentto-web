import { CobroTxForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Cobro CxC TX | DatqBox",
  description: "Aplicar cobro transaccional para cuentas por cobrar"
};

export default function CxcTxPage() {
  return <CobroTxForm />;
}

