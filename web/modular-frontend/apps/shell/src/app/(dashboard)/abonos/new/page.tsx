// app/(dashboard)/abonos/new/page.tsx
import { AbonoForm } from "@datqbox/module-admin";

export const metadata = {
  title: "Nuevo Abono | DatqBox",
  description: "Registrar nuevo abono",
};

export default function NewAbonoPage() {
  return <AbonoForm />;
}
