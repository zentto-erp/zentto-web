'use client';

import { use } from 'react';
import { AdminCmsPageEditor } from '@zentto/module-ecommerce';

export default function AdminCmsEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const num = Number(id);
  return <AdminCmsPageEditor cmsPageId={Number.isFinite(num) ? num : null} />;
}
