import type { Metadata } from 'next';
import RootClient from './root-client';

export const metadata: Metadata = {
  title: {
    default: 'Zentto — ERP en la nube para empresas que crecen',
    template: '%s | Zentto',
  },
  description:
    'Sistema ERP SaaS todo-en-uno para PYMEs. Facturación fiscal, contabilidad, inventario, nómina, POS, restaurante y ecommerce. Multi-país, multi-moneda.',
  metadataBase: new URL('https://zentto.net'),
  alternates: {
    canonical: 'https://zentto.net',
  },
  openGraph: {
    title: 'Zentto — ERP en la nube para empresas que crecen',
    description:
      'Sistema ERP SaaS todo-en-uno para PYMEs. Facturación fiscal, contabilidad, inventario, nómina, POS, restaurante y ecommerce.',
    url: 'https://zentto.net',
    siteName: 'Zentto',
    type: 'website',
    locale: 'es_ES',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Zentto ERP — Plataforma empresarial en la nube',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Zentto — ERP en la nube',
    description: 'Sistema ERP SaaS todo-en-uno para PYMEs. Multi-país, multi-moneda.',
    images: ['/og-image.png'],
  },
  robots: {
    index: false,
    follow: false,
    nocache: true,
  },
  icons: {
    icon: '/favicon.ico',
    apple: '/apple-touch-icon.png',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
      <body>
        <RootClient>{children}</RootClient>
      </body>
    </html>
  );
}
