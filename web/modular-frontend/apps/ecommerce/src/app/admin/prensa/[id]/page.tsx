'use client';

import { use } from 'react';
import { AdminPressReleaseEditor } from '@zentto/module-ecommerce';

export default function AdminPrensaEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const num = Number(id);
  return <AdminPressReleaseEditor pressReleaseId={Number.isFinite(num) ? num : null} />;
}
