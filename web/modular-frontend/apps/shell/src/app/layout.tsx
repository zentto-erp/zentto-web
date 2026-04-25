import type { Metadata } from 'next';
import Script from 'next/script';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
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
  // Icons auto-detectados por Next.js App Router desde
  // src/app/{favicon.ico, icon.png, apple-icon.png}. Declararlos aqui
  // apuntando a /favicon.ico y /apple-touch-icon.png (que no existen
  // en public/) forzaba 404 en el browser.
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
      <head>
        <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
      </head>
      {/*
        InitColorSchemeScript inyecta atributos de tema en <html>/<body>
        antes de hydration para evitar flash de tema incorrecto. Esto
        causa un diff server vs client que React 18 reporta como error
        #418 en produccion (solo warning en dev). suppressHydrationWarning
        a nivel body cubre el gap sin afectar validacion de hijos.
      */}
      <body suppressHydrationWarning>
        <RootClient>{children}</RootClient>
        {/*
          Widget unificado del ecosistema Zentto (Web Component).
          Auto-detecta appContext desde el pathname (/contabilidad,
          /pos, /crm, etc) y se conecta a notify.zentto.net/api/support/chat.
          Una sola línea inyecta el widget en los 15 modulos del ERP.
        */}
        <Script src="https://docs.zentto.net/widget.js" strategy="afterInteractive" />
      </body>
    </html>
  );
}
