import { ComprasTable } from "@datqbox/module-admin";

export const metadata = {
  title: "Compras | DatqBox",
  description: "Listado y gestion de compras"
};

export default function ComprasPage() {
  return <ComprasTable />;
}

