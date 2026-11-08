'use client';

import Link from 'next/link';
import type { ReactNode } from 'react';
import { primary, secondary } from '@/lib/ui';
import { Confetti } from './confetti';

export type CheckoutState = 'confirming' | 'active' | 'pending' | 'failed';

/**
 * Statuses Dodo puts on the return URL (`?status=`) for a checkout that didn't go through.
 * Anything else (succeeded, processing or none) waits for the webhook.
 */
const FAILED_STATUSES = new Set([
  'failed',
  'cancelled',
  'canceled',
  'expired',
  'declined',
  'requires_payment_method',
]);

export function checkoutFailed(status: string | null): boolean {
  return status !== null && FAILED_STATUSES.has(status.toLowerCase());
}

/** The card shown at the top of the account page after coming back from checkout (as in Weblume). */
export function CheckoutStatus({
  state,
  onCheckAgain,
  onDismiss,
}: {
  state: CheckoutState;
  onCheckAgain: () => void;
  onDismiss: () => void;
}) {
  const dismiss = (
    <button type="button" onClick={onDismiss} className={secondary}>
      Dismiss
    </button>
  );
  switch (state) {
    case 'confirming':
      return (
        <Card tone="var(--gf-primary)" badge={<ConfirmingBadge />} live="polite">
          <Title>Confirming your payment…</Title>
          <Body>This usually takes a few seconds. You can stay on this page.</Body>
        </Card>
      );
    case 'active':
      return (
        <Card tone="var(--gf-success)" badge={<SuccessBadge />} live="polite" confetti>
          <Title>Premium is unlocked!</Title>
          <Body>Thank you! Every premium category is yours, on the website and in the app.</Body>
          <Actions>
            <Link href="/play" className={`${primary} inline-flex items-center`}>
              Play now
            </Link>
            {dismiss}
          </Actions>
        </Card>
      );
    case 'pending':
      return (
        <Card tone="var(--gf-accent)" badge={<PendingBadge />} live="polite">
          <Title>Still confirming your payment</Title>
          <Body>
            Our payment partner hasn’t confirmed it yet, which can take a minute or two. Premium
            unlocks as soon as it does.
          </Body>
          <Actions>
            <button type="button" onClick={onCheckAgain} className={primary}>
              Check again
            </button>
            {dismiss}
          </Actions>
        </Card>
      );
    case 'failed':
      return (
        <Card tone="var(--gf-danger)" badge={<FailedBadge />} live="assertive">
          <Title>Your payment didn’t go through</Title>
          <Body>
            You haven’t been charged. Try again with a different card or payment method, or contact
            your bank if it keeps happening.
          </Body>
          <Actions>
            <Link href="/pricing" className={`${primary} inline-flex items-center`}>
              Try again
            </Link>
            {dismiss}
          </Actions>
        </Card>
      );
  }
}

function Card({
  tone,
  badge,
  live,
  confetti = false,
  children,
}: {
  tone: string;
  badge: ReactNode;
  live: 'polite' | 'assertive';
  confetti?: boolean;
  children: ReactNode;
}) {
  return (
    <div
      role={live === 'assertive' ? 'alert' : 'status'}
      aria-live={live}
      style={{ borderColor: tone, color: 'var(--gf-text)' }}
      className="pop-big relative flex items-start gap-4 rounded-card border-2 bg-surface p-5"
    >
      {confetti && <Confetti />}
      <div aria-hidden="true" className="shrink-0" style={{ color: tone }}>
        {badge}
      </div>
      <div className="min-w-0 flex-1">{children}</div>
    </div>
  );
}

function Title({ children }: { children: ReactNode }) {
  return <p className="font-display text-2xl font-semibold">{children}</p>;
}

function Body({ children }: { children: ReactNode }) {
  return <p className="mt-1 text-muted">{children}</p>;
}

function Actions({ children }: { children: ReactNode }) {
  return <div className="mt-4 flex flex-wrap gap-3">{children}</div>;
}

const badge = 'checkout-badge-in grid size-14 place-items-center rounded-full';
const tint = { background: 'color-mix(in oklab, currentColor 15%, transparent)' };

function ConfirmingBadge() {
  return (
    <span className="relative grid size-14 place-items-center">
      <span className="checkout-ring absolute inset-0 rounded-full border-4 border-current border-t-transparent" />
      <span className="font-display text-xl font-bold">$</span>
    </span>
  );
}

function SuccessBadge() {
  return (
    <span className={badge} style={tint}>
      <svg
        viewBox="0 0 24 24"
        className="size-8"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.75"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M5 12.5l4.5 4.5L19 7.5" pathLength={1} className="checkout-draw" />
      </svg>
    </span>
  );
}

function PendingBadge() {
  return (
    <span className={badge} style={tint}>
      <svg
        viewBox="0 0 24 24"
        className="size-8"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.25"
        strokeLinecap="round"
      >
        <circle cx="12" cy="12" r="8.5" />
        <path d="M12 7.5V12" className="checkout-tick origin-[12px_12px]" />
        <path d="M12 12l3 2" />
      </svg>
    </span>
  );
}

function FailedBadge() {
  return (
    <span className={`${badge} checkout-shake`} style={tint}>
      <svg
        viewBox="0 0 24 24"
        className="size-8"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.75"
        strokeLinecap="round"
      >
        <path d="M7 7l10 10" pathLength={1} className="checkout-draw" />
        <path d="M17 7L7 17" pathLength={1} className="checkout-draw [animation-delay:0.15s]" />
      </svg>
    </span>
  );
}
