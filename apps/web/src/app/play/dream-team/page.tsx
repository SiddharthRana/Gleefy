import type { Metadata } from 'next';
import { DreamTeamPlayer } from './dream-team-player';

export const metadata: Metadata = {
  title: 'Play Dream Team',
  description:
    'Play Dream Team in your browser: draft a squad blind on one shared screen, then argue whose team wins.',
  alternates: { canonical: '/play/dream-team' },
};

export default function DreamTeamPage() {
  return (
    <div className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Dream Team</h1>
      <p className="mt-3 mb-8 text-lg text-muted">
        Draft a squad blind, one random card at a time. Then the room argues who wins.
      </p>
      <DreamTeamPlayer />
    </div>
  );
}
