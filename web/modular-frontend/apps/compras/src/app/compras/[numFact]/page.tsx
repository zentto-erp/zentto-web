'use client';
import { CompraDetail } from '@zentto/module-compras';
import { useParams } from 'next/navigation';

export default function Page() {
    const { numFact } = useParams<{ numFact: string }>();
    return <CompraDetail numFact={numFact} />;
}
