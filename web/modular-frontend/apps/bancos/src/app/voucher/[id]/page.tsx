'use client';
import { useParams } from 'next/navigation';
import { VoucherView } from '@zentto/module-bancos';
export default function Page() {
    const params = useParams();
    const id = params?.id as string;
    return <VoucherView movimientoId={id} />;
}
