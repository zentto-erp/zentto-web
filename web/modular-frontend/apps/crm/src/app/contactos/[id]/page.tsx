"use client";

import { useEffect } from "react";
import { useParams, useRouter } from "next/navigation";

/**
 * Retrocompat — deep-links antiguos `/contactos/:id` redirigen a `/contactos?contact=<id>`
 * que abre el drawer (ver DESIGN.md §5.1, CRM-111).
 */
export default function ContactDetailPage() {
    const params = useParams();
    const router = useRouter();

    useEffect(() => {
        const id = Array.isArray(params?.id) ? params.id[0] : params?.id;
        router.replace(id ? `/contactos?contact=${id}` : "/contactos");
    }, [params, router]);

    return null;
}
