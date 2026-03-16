'use client';
import { useParams } from 'next/navigation';
import { ClienteForm } from '@zentto/module-admin';
export default function Page() {
    const { id } = useParams();
    return <ClienteForm clienteCodigo={id as string} />;
}
