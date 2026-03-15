/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    '@datqbox/shared-auth',
    '@datqbox/shared-ui',
    '@datqbox/shared-api',
    '@datqbox/module-admin',
    '@datqbox/module-bancos',
    '@datqbox/module-compras',
    '@datqbox/module-inventario',
    '@datqbox/module-contabilidad',
    '@datqbox/module-nomina',
    '@datqbox/pos',
    '@datqbox/restaurante',
  ],
  async rewrites() {
    return [
      // Contabilidad - Puerto 3001
      {
        source: '/contabilidad',
        destination: `http://localhost:3001/contabilidad`,
      },
      {
        source: '/contabilidad/:path*',
        destination: `http://localhost:3001/contabilidad/:path*`,
      },
      // POS - Puerto 3002
      {
        source: '/pos',
        destination: `http://localhost:3002/pos`,
      },
      {
        source: '/pos/:path*',
        destination: `http://localhost:3002/pos/:path*`,
      },
      // Nómina - Puerto 3003
      {
        source: '/nomina',
        destination: `http://localhost:3003/nomina`,
      },
      {
        source: '/nomina/:path*',
        destination: `http://localhost:3003/nomina/:path*`,
      },


      // Bancos - Puerto 3004
      {
        source: '/bancos',
        destination: `http://localhost:3004/bancos`,
      },
      {
        source: '/bancos/:path*',
        destination: `http://localhost:3004/bancos/:path*`,
      },
      // Inventario - Puerto 3005
      {
        source: '/inventario',
        destination: `http://localhost:3005/inventario`,
      },
      {
        source: '/inventario/:path*',
        destination: `http://localhost:3005/inventario/:path*`,
      },
      // Ventas - Puerto 3006
      {
        source: '/ventas',
        destination: `http://localhost:3006/ventas`,
      },
      {
        source: '/ventas/:path*',
        destination: `http://localhost:3006/ventas/:path*`,
      },
      // Compras - Puerto 3007
      {
        source: '/compras',
        destination: `http://localhost:3007/compras`,
      },
      {
        source: '/compras/:path*',
        destination: `http://localhost:3007/compras/:path*`,
      },
      // Restaurante - Puerto 3008
      {
        source: '/restaurante',
        destination: `http://localhost:3008/restaurante`,
      },
      {
        source: '/restaurante/:path*',
        destination: `http://localhost:3008/restaurante/:path*`,
      },
      // E-commerce - Puerto 3009
      {
        source: '/ecommerce',
        destination: `http://localhost:3009/ecommerce`,
      },
      {
        source: '/ecommerce/:path*',
        destination: `http://localhost:3009/ecommerce/:path*`,
      },
      // Auditoría - Puerto 3010
      {
        source: '/auditoria',
        destination: `http://localhost:3010/auditoria`,
      },
      {
        source: '/auditoria/:path*',
        destination: `http://localhost:3010/auditoria/:path*`,
      }
    ]
  },
};

export default nextConfig;
