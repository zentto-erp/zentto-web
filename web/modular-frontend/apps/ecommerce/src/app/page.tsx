'use client';

import { useRouter } from 'next/navigation';
import { StoreFront } from '@datqbox/module-ecommerce';

export default function Page() {
    const router = useRouter();

    return (
        <StoreFront
            onViewProduct={(code) => router.push(`/productos/${code}`)}
            onViewCategory={(category) => router.push(`/productos?category=${encodeURIComponent(category)}`)}
            onViewAll={() => router.push('/productos')}
        />
    );
}
