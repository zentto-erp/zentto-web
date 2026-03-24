"use client";

import { useParams } from "next/navigation";
import { FacturaDetail } from "@zentto/module-admin";

export default function FacturaDetailPage() {
  const params = useParams();
  const id = params.id as string;
  if (!id) return null;
  return <FacturaDetail numeroFactura={id} />;
}
