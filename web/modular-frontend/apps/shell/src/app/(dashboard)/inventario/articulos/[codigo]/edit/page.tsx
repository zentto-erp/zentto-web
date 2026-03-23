"use client";

import { useParams } from "next/navigation";
import { ArticuloForm } from "@zentto/module-admin";

export default function EditArticuloPage() {
  const params = useParams<{ codigo: string }>();
  const codigo = decodeURIComponent(params.codigo ?? "");
  return <ArticuloForm codigoArticulo={codigo} />;
}
