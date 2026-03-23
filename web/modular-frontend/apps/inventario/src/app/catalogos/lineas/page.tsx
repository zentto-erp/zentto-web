'use client';
import { CatalogoCrudPage } from '@zentto/module-inventario';

export default function Page() {
    return <CatalogoCrudPage endpoint="lineas" title="Líneas" tableName="SupplierLine" schema="master" />;
}
