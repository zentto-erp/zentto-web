'use client';

import { useRouter } from 'next/navigation';
import { ShippingDashboard } from '@zentto/module-shipping';

export default function DashboardPage() {
    const router = useRouter();
    return <ShippingDashboard onNavigate={(path) => router.push(path)} />;
}
