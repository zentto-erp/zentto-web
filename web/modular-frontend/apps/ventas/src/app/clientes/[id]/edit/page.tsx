'use client';
import { useParams } from 'next/navigation';
import { ClienteForm } from '@zentto/module-admin';

export default function ClienteEditPage() {
  const { id } = useParams();
  return <ClienteForm clienteCodigo={id as string} />;
}
