// app/(dashboard)/abonos/page.tsx
import AbonosTable from "@/components/modules/abonos/AbonosaTable";

export const metadata = {
  title: "Abonos | DatqBox",
  description: "Registro de abonos",
};

export default function AbonosPage() {
  return <AbonosTable />;
}
