"use client";
import { CatalogoCrudPage } from "@zentto/module-inventario";
export default function AlmacenesPage() {
  return <CatalogoCrudPage endpoint="almacen" title="Almacenes" tableName="Warehouse" schema="master" />;
}
