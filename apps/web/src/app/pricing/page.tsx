import type { Metadata } from 'next';
import { formatPrice, PLANS } from '@gleefy/plans';
import { modeNames, packs } from '@/lib/packs';
import { UnlockButton } from './unlock-button';
import Link from 'next/link';
import { ForFree, ForPremium } from '@/components/premium-status';
import { primary } from '@/lib/ui';

export const metadata: Metadata = {
  title: 'Premium',
  description:
    'Gleefy is free to play. Premium is a one-time unlock for every premium category in every game, in the Android and iOS apps and on the web.',
  alternates: { canonical: '/pricing' },
};

const premiumCategories = Object.entries(packs).flatMap(([mode, pack]) =>
  pack.categories
    .filter((c) => c.tier === 'premium')
    .map((c) => ({
      id: `${mode}-${c.id}`,
      name: c.name,
      mode: modeNames[mode as keyof typeof modeNames],
      count: (pack.items as { category: string }[]).filter((i) => i.category === c.id).length,
    })),
);

export default function PricingPage() {
  const p = PLANS.premium.displayPrice!;
  const price = formatPrice(p.amount, p.currency);
  return (
    <div className="py-12">
      <h1 className="font-display text-5xl font-bold">Premium</h1>
      <ForFree>
        <p className="mt-3 max-w-2xl text-lg text-muted">
          Every game is free to play, with no account. Premium adds the extra categories for groups
          who want more.
        </p>
      </ForFree>
      <ForPremium>
        <section
          aria-label="Your Premium"
          className="mt-6 max-w-2xl rounded-card border-2 border-accent bg-surface p-5"
        >
          <p className="flex flex-wrap items-center gap-2 text-lg font-bold">
            <span className="premium-tag premium-tag-lg">★ Premium</span> Unlocked on this account
          </p>
          <p className="mt-2 text-muted">
            Every premium category in every game is yours, on the website and in the apps. Thanks
            for supporting Gleefy!
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <Link href="/play" className={`${primary} inline-flex items-center`}>
              Play now
            </Link>
            <Link href="/account" className="inline-flex min-h-12 items-center font-bold underline">
              Your account
            </Link>
          </div>
        </section>
      </ForPremium>

      <ForFree>
        <div className="mt-10 grid gap-4 md:grid-cols-2">
          <section
            aria-labelledby="free-plan"
            className="rounded-card border border-border bg-surface p-5"
          >
            <h2 id="free-plan" className="font-display text-3xl font-semibold">
              Free
            </h2>
            <p className="mt-1 text-2xl font-bold">$0</p>
            <ul className="mt-4 list-disc space-y-2 pl-6">
              <li>All four games and custom party packs</li>
              <li>Every free category</li>
              <li>The web player and share links</li>
              <li>No account, no ads</li>
            </ul>
          </section>

          <section
            aria-labelledby="premium-plan"
            className="rounded-card border-2 border-primary bg-surface p-5"
          >
            <h2 id="premium-plan" className="font-display text-3xl font-semibold">
              {PLANS.premium.name}
            </h2>
            <p className="mt-1 text-2xl font-bold">
              {price} <span className="text-lg text-muted">once</span>
            </p>
            <p className="mt-1 text-sm text-muted">
              No subscription. The amount you pay, including any tax, is shown at checkout and may
              vary by country.
            </p>
            <ul className="mt-4 list-disc space-y-2 pl-6">
              <li>Everything in Free</li>
              <li>Every premium category in every game</li>
              <li>One account for the Android and iOS apps and the website</li>
              <li>Pay once, keep it for good</li>
            </ul>
            <UnlockButton price={price} />
          </section>
        </div>
      </ForFree>

      <section aria-labelledby="included" className="mt-12">
        <h2 id="included" className="font-display text-3xl font-semibold">
          <ForFree>Premium categories</ForFree>
          <ForPremium>Your Premium categories</ForPremium>
        </h2>
        <ul className="mt-4 grid gap-3 sm:grid-cols-2">
          {premiumCategories.map((c) => (
            <li key={c.id} className="rounded-card border border-border bg-surface p-4">
              <p className="font-bold">{c.name}</p>
              <p className="text-muted">
                {c.mode} · {c.count} {c.count === 1 ? 'question' : 'questions'}
              </p>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="apps" className="mt-12 max-w-3xl">
        <h2 id="apps" className="font-display text-3xl font-semibold">
          In the apps
        </h2>
        <p className="mt-3">
          <ForFree>
            Gleefy is coming to Android and iOS. In the apps, Premium is a one-time purchase through
            Google Play or the App Store. Sign in with the same account on the website and the app,
            and one purchase unlocks both.
          </ForFree>
          <ForPremium>
            Gleefy is coming to Android and iOS. Sign in to the apps with this same account and your
            Premium is there too, with nothing more to buy.
          </ForPremium>
        </p>
      </section>
    </div>
  );
}
