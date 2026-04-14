import { redirect } from 'next/navigation';

type SearchParams = Record<string, string | string[] | undefined>;

/**
 * /signup está deprecated — redirige a /registro conservando query params.
 * El flujo unificado vive ahora en /registro (ver RegistroPage).
 */
export default async function SignupRedirectPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const qs = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (typeof value === 'string') qs.set(key, value);
    else if (Array.isArray(value) && value.length > 0) qs.set(key, value[0]);
  }
  const query = qs.toString();
  redirect(`/registro${query ? `?${query}` : ''}`);
}
