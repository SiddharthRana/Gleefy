import type { MetadataRoute } from 'next';
import { isWarmup, siteUrl } from '@/lib/site';

// Generated once at build time (static export).
export const dynamic = 'force-static';

export default function robots(): MetadataRoute.Robots {
  // The warmup copy is for testing only: keep every crawler out.
  if (isWarmup) return { rules: { userAgent: '*', disallow: '/' } };
  return { rules: { userAgent: '*', allow: '/' }, sitemap: `${siteUrl}/sitemap.xml` };
}
