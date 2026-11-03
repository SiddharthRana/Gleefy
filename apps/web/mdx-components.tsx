import type { MDXComponents } from 'mdx/types';
import Link from 'next/link';
import type { Route } from 'next';

/** Typography for MDX guides, matching the rest of the site. */
const components: MDXComponents = {
  h1: (p) => <h1 className="font-display text-5xl font-bold" {...p} />,
  h2: (p) => <h2 className="mt-10 font-display text-3xl font-semibold" {...p} />,
  h3: (p) => <h3 className="mt-6 font-display text-2xl font-semibold" {...p} />,
  p: (p) => <p className="mt-3 text-lg" {...p} />,
  ul: (p) => <ul className="mt-3 list-disc space-y-2 pl-6 text-lg" {...p} />,
  ol: (p) => <ol className="mt-3 list-decimal space-y-2 pl-6 text-lg" {...p} />,
  a: ({ href = '', ...p }) =>
    href.startsWith('/') ? (
      <Link href={href as Route} className="font-bold text-primary underline" {...p} />
    ) : (
      <a href={href} className="font-bold text-primary underline" rel="noopener" {...p} />
    ),
  strong: (p) => <strong className="font-bold" {...p} />,
};

export function useMDXComponents(): MDXComponents {
  return components;
}
