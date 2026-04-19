"use client";

import { useEffect } from "react";
import { useParams, useRouter } from "next/navigation";

/**
 * Retrocompat — deep-links antiguos `/deals/:id` redirigen a `/deals?deal=<id>`.
 */
export default function DealDetailPage() {
    const params = useParams();
    const router = useRouter();

    useEffect(() => {
        const id = Array.isArray(params?.id) ? params.id[0] : params?.id;
        router.replace(id ? `/deals?deal=${id}` : "/deals");
    }, [params, router]);

    return null;
}
