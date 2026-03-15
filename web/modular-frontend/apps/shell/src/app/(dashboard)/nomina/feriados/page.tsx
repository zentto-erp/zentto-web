"use client";
import CatalogoCrudPage from "@/components/modules/inventario/CatalogoCrudPage";

export default function FeriadosPage() {
  return (
    <CatalogoCrudPage
      endpoint="maestros/feriados"
      title="Feriados"
      tableName="Holiday"
      schema="cfg"
    />
  );
}
