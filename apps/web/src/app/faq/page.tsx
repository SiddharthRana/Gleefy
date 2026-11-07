import type { Metadata } from 'next';
import Link from 'next/link';
import { contactEmail } from '@/lib/contact';

export const metadata: Metadata = {
  title: 'FAQ',
  description:
    'Answers about Gleefy: free play, Premium, accounts, privacy, offline play, sharing and devices.',
  alternates: { canonical: '/faq' },
};

const faqs: { q: string; a: React.ReactNode }[] = [
  {
    q: 'Is Gleefy free?',
    a: 'Yes. Every game and every free category is free to play, with no ads and no account. Premium adds extra categories in every game.',
  },
  {
    q: 'What does Premium include?',
    a: (
      <>
        Every premium category in every game, in the Android and iOS apps and on the website, for
        one small payment. It isn’t a subscription. See <Link href="/pricing">Premium</Link> for the
        price and the full list.
      </>
    ),
  },
  {
    q: 'Do I need an account?',
    a: 'Only to buy Premium or use it on another device. You sign in with Google, or with your email and a one-time code; there’s no password. Accounts and purchases are for people aged 18 or over.',
  },
  {
    q: 'Is Premium a subscription?',
    a: (
      <>
        No. You pay once and keep Premium, with nothing to cancel. To use it on another phone or on
        the website, sign in to the same account on your <Link href="/account">Account</Link> page
        or in the app’s Settings.
      </>
    ),
  },
  {
    q: 'Can I add my own questions?',
    a: 'Yes, in the app: Settings → My questions, or “Write your own questions” when you set up Would You Rather or This or That. They stay on your phone and are never uploaded or shared.',
  },
  {
    q: 'Does it work offline?',
    a: 'Yes. All the games and questions are on your phone, and once Premium is unlocked it stays on without a connection.',
  },
  {
    q: 'What do you know about me?',
    a: (
      <>
        Nothing, unless you buy Premium (then your email and that you bought it) or choose to share
        anonymous usage statistics. Player names never leave your phone. See{' '}
        <Link href="/privacy">Privacy</Link>.
      </>
    ),
  },
  {
    q: 'Is there an app for iPhone and Android?',
    a: 'Yes, Gleefy is coming to both Android and iOS. Until then, anyone can play the four games in the browser on the Play page, and shared game links open there too.',
  },
  {
    q: 'Who is Gleefy for?',
    a: 'Friends, couples and families playing together in person, aged 13 and up. Each category shows its age guidance and any content note before you play.',
  },
  {
    q: 'I found a wrong trivia answer or an unsuitable question.',
    a: (
      <>
        Please tell us at <a href={`mailto:${contactEmail}`}>{contactEmail}</a> with the question
        text. We check every report.
      </>
    ),
  },
];

export default function FaqPage() {
  return (
    <div className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">FAQ</h1>
      <dl className="mt-8 space-y-8">
        {faqs.map((f) => (
          <div key={f.q}>
            <dt className="font-display text-2xl font-semibold">{f.q}</dt>
            <dd className="mt-2 text-lg [&_a]:font-bold [&_a]:text-primary [&_a]:underline">
              {f.a}
            </dd>
          </div>
        ))}
      </dl>
    </div>
  );
}
