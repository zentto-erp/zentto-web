'use client';
import { CatalogoCrudPage } from '@zentto/module-inventario';

export default function Page() {
    return <CatalogoCrudPage endpoint="marcas" title="Marcas" tableName="Brand" schema="master" />;
}
