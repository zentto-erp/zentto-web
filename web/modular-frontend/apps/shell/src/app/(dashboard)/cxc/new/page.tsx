import { CobroTxForm } from "@zentto/module-admin";

export const metadata = {
  title: "Cobro CxC TX | Zentto",
  description: "Aplicar cobro transaccional para cuentas por cobrar"
};

export default function CxcTxPage() {
  return <CobroTxForm />;
}

