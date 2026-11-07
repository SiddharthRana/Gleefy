import Link from 'next/link';

export function SiteFooter() {
  return (
    <footer className="mt-24 border-t border-border">
      <div className="mx-auto flex max-w-5xl flex-col gap-4 px-4 py-8 text-muted sm:flex-row sm:items-center sm:justify-between">
        <p>© {new Date().getFullYear()} Gleefy · Made for ages 13+</p>
        <nav aria-label="Footer">
          <ul className="flex flex-wrap gap-x-6 gap-y-2 font-bold">
            <li>
              <Link href="/games" className="inline-flex min-h-12 items-center hover:text-text">
                Games
              </Link>
            </li>
            <li>
              <Link
                href="/how-to-play"
                className="inline-flex min-h-12 items-center hover:text-text"
              >
                How to play
              </Link>
            </li>
            <li>
              <Link href="/guides" className="inline-flex min-h-12 items-center hover:text-text">
                Guides
              </Link>
            </li>
            <li>
              <Link href="/faq" className="inline-flex min-h-12 items-center hover:text-text">
                FAQ
              </Link>
            </li>
            <li>
              <Link href="/contact" className="inline-flex min-h-12 items-center hover:text-text">
                Contact
              </Link>
            </li>
            <li>
              <Link href="/account" className="inline-flex min-h-12 items-center hover:text-text">
                Account
              </Link>
            </li>
            <li>
              <Link href="/privacy" className="inline-flex min-h-12 items-center hover:text-text">
                Privacy
              </Link>
            </li>
            <li>
              <Link href="/terms" className="inline-flex min-h-12 items-center hover:text-text">
                Terms
              </Link>
            </li>
          </ul>
        </nav>
      </div>
    </footer>
  );
}
