"use client";

import { useEffect } from "react";
import { useParams, useRouter } from "next/navigation";

/**
 * Retrocompat: antes esta ruta renderizaba `LeadDetailPanel` full-width.
 * Ahora el detalle se ve como `RightDetailDrawer` sobre la lista
 * (ver DESIGN.md §5.1, issue #376 / CRM-102).
 *
 * Se preserva la ruta `/leads/[id]` para deep-links antiguos (email, enlaces
 * externos, bookmarks) redirigiendo a `/leads?lead=<id>`, que abre el drawer.
 */
export default function LeadDetailPage() {
  const params = useParams();
  const router = useRouter();

  useEffect(() => {
    const id = Array.isArray(params?.id) ? params.id[0] : params?.id;
    if (id) {
      router.replace(`/leads?lead=${id}`);
    } else {
      router.replace(`/leads`);
    }
  }, [params, router]);

  return null;
}
