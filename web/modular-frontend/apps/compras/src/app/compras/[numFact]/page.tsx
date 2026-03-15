'use client';
import { CompraDetail } from '@datqbox/module-compras';
import { useParams } from 'next/navigation';

export default function Page() {
    const { numFact } = useParams<{ numFact: string }>();
    return <CompraDetail numFact={numFact} />;
}
