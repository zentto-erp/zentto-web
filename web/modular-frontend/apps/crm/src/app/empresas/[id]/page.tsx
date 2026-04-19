"use client";

import { useEffect } from "react";
import { useParams, useRouter } from "next/navigation";

/**
 * Retrocompat — deep-links antiguos `/empresas/:id` redirigen a `/empresas?company=<id>`.
 */
export default function CompanyDetailPage() {
    const params = useParams();
    const router = useRouter();

    useEffect(() => {
        const id = Array.isArray(params?.id) ? params.id[0] : params?.id;
        router.replace(id ? `/empresas?company=${id}` : "/empresas");
    }, [params, router]);

    return null;
}
