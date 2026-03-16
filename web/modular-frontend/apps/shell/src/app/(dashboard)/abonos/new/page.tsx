// app/(dashboard)/abonos/new/page.tsx
import { AbonoForm } from "@zentto/module-admin";

export const metadata = {
  title: "Nuevo Abono | Zentto",
  description: "Registrar nuevo abono",
};

export default function NewAbonoPage() {
  return <AbonoForm />;
}
