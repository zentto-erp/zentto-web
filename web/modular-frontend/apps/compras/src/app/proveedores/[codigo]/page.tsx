'use client';
import { ProveedorForm } from '@zentto/module-compras';
import { useParams } from 'next/navigation';

export default function Page() {
    const { codigo } = useParams<{ codigo: string }>();
    return <ProveedorForm codigo={codigo} />;
}
