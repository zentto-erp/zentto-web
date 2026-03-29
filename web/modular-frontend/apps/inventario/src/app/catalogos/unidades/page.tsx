'use client';
import { CatalogoCrudPage } from '@zentto/module-inventario';

export default function Page() {
    return <CatalogoCrudPage endpoint="unidades" title="Unidades" tableName="Unit" schema="master" />;
}
