import { ConciliacionWizard } from "@zentto/module-bancos";

export const metadata = {
  title: "Conciliacion Bancaria",
  description: "Conciliacion bancaria con extracto y ajustes"
};

export default function Page() {
  return <ConciliacionWizard />;
}

