import type { MetadataRoute } from 'next';
import { articles } from '@/lib/guide-articles';
import { modes, siteUrl } from '@/lib/site';

// Generated once at build time (static export).
export const dynamic = 'force-static';

export default function sitemap(): MetadataRoute.Sitemap {
  const paths = [
    '/',
    '/games',
    ...modes.flatMap((m) => (m.href ? [m.href] : [])),
    '/how-to-play',
    '/play',
    '/pricing',
    '/faq',
    '/guides',
    ...articles.map((a) => a.href),
    '/contact',
    '/account-deletion',
    '/privacy',
    '/terms',
  ];
  return paths.map((p) => ({ url: `${siteUrl}${p === '/' ? '' : p}` }));
}
