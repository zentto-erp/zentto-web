'use client';
import { CatalogoCrudPage } from '@zentto/module-inventario';

export default function Page() {
    return <CatalogoCrudPage endpoint="categorias" title="Categorías" tableName="Category" schema="master" />;
}
