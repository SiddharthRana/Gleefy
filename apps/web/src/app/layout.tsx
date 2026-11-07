import type { Metadata, Viewport } from 'next';
import { Fredoka, Nunito } from 'next/font/google';
import { ErrorMonitoring } from '@/components/error-monitoring';
import { SiteFooter } from '@/components/site-footer';
import { SiteHeader } from '@/components/site-header';
import { siteUrl } from '@/lib/site';
import './globals.css';

const fredoka = Fredoka({
  subsets: ['latin'],
  weight: ['500', '600', '700'],
  variable: '--font-fredoka',
});
const nunito = Nunito({
  subsets: ['latin'],
  weight: ['400', '600', '700', '800'],
  variable: '--font-nunito',
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: { default: 'MirthMix: party games for one phone', template: '%s · MirthMix' },
  description:
    'Quick party games for friends, couples and families, played together on one phone. No sign-up needed.',
  openGraph: { type: 'website', siteName: 'MirthMix', locale: 'en_GB' },
  alternates: { canonical: '/' },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#FFF8F1' },
    { media: '(prefers-color-scheme: dark)', color: '#120B1F' },
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${fredoka.variable} ${nunito.variable}`}>
      <body className="min-h-dvh">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-10 focus:rounded-full focus:bg-primary focus:px-4 focus:py-2 focus:text-on-primary"
        >
          Skip to content
        </a>
        <SiteHeader />
        <main id="main" className="mx-auto max-w-5xl px-4">
          {children}
        </main>
        <SiteFooter />
        <ErrorMonitoring />
      </body>
    </html>
  );
}
