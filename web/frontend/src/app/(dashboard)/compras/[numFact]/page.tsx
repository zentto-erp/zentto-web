import CompraDetail from "@/components/modules/compras/CompraDetail";

export const metadata = {
  title: "Detalle de Compra | DatqBox",
  description: "Cabecera, detalle e indicadores de compra"
};

export default async function CompraDetailPage({ params }: { params: Promise<{ numFact: string }> }) {
  const { numFact } = await params;
  return <CompraDetail numFact={decodeURIComponent(numFact)} />;
}

