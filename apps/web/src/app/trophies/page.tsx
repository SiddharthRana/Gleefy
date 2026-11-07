import type { Metadata } from 'next';
import { TrophyRoom } from './trophy-room';

export const metadata: Metadata = {
  title: 'Trophies',
  description: 'Your Gleefy level, streak and trophies, kept on this device.',
  alternates: { canonical: '/trophies' },
  robots: { index: false, follow: true },
};

export default function TrophiesPage() {
  return (
    <div className="py-12">
      <h1 className="font-display text-5xl font-bold">Trophies</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">
        Finish games in the web player to earn XP, level up and keep your streak alive. Your
        progress stays in this browser: no account, nothing sent anywhere.
      </p>
      <TrophyRoom />
    </div>
  );
}
