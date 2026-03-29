'use client';
import { useParams } from 'next/navigation';
import { ArticuloForm } from '@zentto/module-admin';

export default function ArticuloDetailPage() {
  const { codigo } = useParams();
  return <ArticuloForm codigoArticulo={codigo as string} />;
}
