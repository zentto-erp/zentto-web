// app/(dashboard)/abonos/page.tsx
import { AbonosTable } from "@zentto/module-admin";

export const metadata = {
  title: "Abonos | Zentto",
  description: "Registro de abonos",
};

export default function AbonosPage() {
  return <AbonosTable />;
}
