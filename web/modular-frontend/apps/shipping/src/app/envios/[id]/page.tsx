'use client';

import { useRouter, useParams } from 'next/navigation';
import { ShipmentDetail } from '@zentto/module-shipping';

export default function EnvioDetailPage() {
    const router = useRouter();
    const params = useParams();
    const id = Number(params.id);

    if (!id) return null;

    return <ShipmentDetail shipmentId={id} onNavigate={(path) => router.push(path)} />;
}
