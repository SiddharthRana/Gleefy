import type { Metadata } from 'next';
import { contactEmail } from '@/lib/contact';

export const metadata: Metadata = {
  title: 'Contact',
  description: 'Get in touch with MirthMix: questions, feedback, content reports and account help.',
  alternates: { canonical: '/contact' },
};

export default function ContactPage() {
  return (
    <div className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Contact</h1>
      <p className="mt-3 text-lg">
        Email us at{' '}
        <a href={`mailto:${contactEmail}`} className="font-bold text-primary underline">
          {contactEmail}
        </a>
        . We read everything and usually reply within a few working days.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Helpful details to include</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6 text-lg">
        <li>
          <strong>Wrong or unsuitable question:</strong> the game, the category and the question
          text.
        </li>
        <li>
          <strong>Premium or billing:</strong> the email you signed in with and whether you bought
          in the app or on the website. Never send card details.
        </li>
        <li>
          <strong>Something broken:</strong> your phone model, Android or iOS version and what you
          were doing.
        </li>
      </ul>
    </div>
  );
}
