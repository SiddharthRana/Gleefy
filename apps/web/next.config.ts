import createMDX from '@next/mdx';
import type { NextConfig } from 'next';

// Every page is static (the web player runs in the browser), so the site is exported as plain files
// to `out/` and served by Cloudflare Pages. Security headers live in public/_headers, because
// `headers()` doesn't apply to a static export.
const nextConfig: NextConfig = {
  output: 'export',
  pageExtensions: ['ts', 'tsx', 'md', 'mdx'],
  reactCompiler: true,
  typedRoutes: true,
  poweredByHeader: false,
  transpilePackages: [
    '@gleefy/content',
    '@gleefy/design-tokens',
    '@gleefy/game-engine',
    '@gleefy/plans',
  ],
};

// Guides are MDX pages under src/app/guides.
const withMDX = createMDX({});

export default withMDX(nextConfig);
