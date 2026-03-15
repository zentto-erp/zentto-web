'use client';
import { useParams } from 'next/navigation';
import { FacturaForm } from '@datqbox/module-admin';
export default function Page() {
    const { id } = useParams();
    return <FacturaForm numeroFactura={id as string} />;
}
