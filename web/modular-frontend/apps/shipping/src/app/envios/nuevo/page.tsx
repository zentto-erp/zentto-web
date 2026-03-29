'use client';

import { useRouter } from 'next/navigation';
import { CreateShipment } from '@zentto/module-shipping';

export default function NuevoEnvioPage() {
    const router = useRouter();
    return <CreateShipment onNavigate={(path) => router.push(path)} />;
}
