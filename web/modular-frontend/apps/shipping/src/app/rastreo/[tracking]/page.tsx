'use client';

import { useParams } from 'next/navigation';
import { PublicTracking } from '@zentto/module-shipping';

export default function TrackingResultPage() {
    const params = useParams();
    const tracking = params.tracking ? decodeURIComponent(String(params.tracking)) : undefined;
    return <PublicTracking initialTracking={tracking} />;
}
