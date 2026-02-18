// app/(dashboard)/pagos/new/page.tsx
import PagoForm from "@/components/modules/pagos/PagoForm";

export const metadata = {
  title: "Nuevo Pago | DatqBox",
  description: "Registrar nuevo pago",
};

export default function NewPagoPage() {
  return <PagoForm />;
}
