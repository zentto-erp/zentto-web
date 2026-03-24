"use client";

import { useParams } from "next/navigation";
import { LeadDetailPanel } from "@zentto/module-crm";

export default function LeadDetailPage() {
  const params = useParams();
  const id = Number(params.id);
  if (!id) return null;
  return <LeadDetailPanel leadId={id} />;
}
