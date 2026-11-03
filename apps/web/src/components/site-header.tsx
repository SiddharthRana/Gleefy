import Link from 'next/link';
import { Logo } from './logo';

export function SiteHeader() {
  return (
    <header className="border-b border-border">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-3">
        <Link
          href="/"
          className="flex min-h-12 items-center gap-2 font-display text-2xl font-bold"
          aria-label="MirthMix home"
        >
          <span className="wiggle inline-flex">
            <Logo />
          </span>
          <span>MirthMix</span>
        </Link>
        <nav aria-label="Main">
          <ul className="flex items-center gap-1 font-bold">
            <li>
              <Link
                href="/games"
                className="nav-link inline-flex min-h-12 items-center whitespace-nowrap rounded-full px-3 hover:bg-surface-muted sm:px-4"
              >
                Games
              </Link>
            </li>
            <li>
              <Link
                href="/play"
                className="nav-link inline-flex min-h-12 items-center whitespace-nowrap rounded-full px-3 hover:bg-surface-muted sm:px-4"
              >
                Play
              </Link>
            </li>
            <li>
              <Link
                href="/pricing"
                className="nav-link inline-flex min-h-12 items-center whitespace-nowrap rounded-full px-3 hover:bg-surface-muted sm:px-4"
              >
                Premium
              </Link>
            </li>
            <li className="hidden md:block">
              <Link
                href="/how-to-play"
                className="nav-link inline-flex min-h-12 items-center whitespace-nowrap rounded-full px-3 hover:bg-surface-muted sm:px-4"
              >
                How to play
              </Link>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}
