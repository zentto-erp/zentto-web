import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@zentto/studio', '@zentto/studio-core'],
};

export default nextConfig;
