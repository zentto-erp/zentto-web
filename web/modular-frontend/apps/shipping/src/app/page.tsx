'use client';

import { useRouter } from 'next/navigation';
import { ShippingHome } from '@zentto/module-shipping';

export default function HomePage() {
    const router = useRouter();
    return <ShippingHome onNavigate={(path) => router.push(path)} />;
}
