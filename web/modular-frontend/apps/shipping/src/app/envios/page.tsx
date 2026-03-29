'use client';

import { useRouter } from 'next/navigation';
import { ShipmentsList } from '@zentto/module-shipping';

export default function EnviosPage() {
    const router = useRouter();
    return <ShipmentsList onNavigate={(path) => router.push(path)} />;
}
