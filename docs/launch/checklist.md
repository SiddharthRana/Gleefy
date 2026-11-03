# Launch checklist

Everything between today and a production release, in order. Code work is done unless listed under "Unfinished work" at the end. Items marked **(owner)** need accounts, money, signatures or a second person, so only the owner can do them.

## 1. Names, accounts and money (owner)

- [ ] Check "MirthMix" for trademark conflicts, and that the Play Store name and a domain are free (BUILD_PROMPT §18).
- [ ] Buy the domain. Replace `mirthmix.example` everywhere: `NEXT_PUBLIC_SITE_URL`, `SITE_URL`, the App Links host in `apps/mobile/android/app/src/main/AndroidManifest.xml`, and `NEXT_PUBLIC_CONTACT_EMAIL`.
- [ ] Set up a support email address (shown on `/contact` and in the Play listing).
- [ ] Google Play developer account (one-time $25 fee); identity verification.
- [ ] Confirm Paddle or Dodo Payments accepts you as a seller (`docs/payments-setup.md` §0), or launch with Google Play billing only (`WEB_PAYMENT_PROVIDER=none`).
- [ ] Supabase project (Free while testing; Pro before taking real payments), Fly.io app, Cloudflare Pages project, optional PostHog project (EU) with a retention period set.

## 2. Content (owner + a second person)

- [ ] **Verify every trivia question.** The spec ships only `verified` questions; today all 200 are `self-checked`. Export the sheet, have a second person check each row against its source and mark `ok` = yes, then import it:
  ```bash
  pnpm content:review ~/trivia-review.csv
  # reviewer fills the "ok" and "reviewer notes" columns
  pnpm content:mark-verified ~/trivia-review.csv
  pnpm content:sync && pnpm content:validate
  ```
  Fix or remove anything the reviewer flags before marking it.
- [ ] Read through every Would You Rather, This or That and Guess card once more for tone and suitability (13+ guidance, content notes).

## 3. Legal (owner, with a lawyer)

- [ ] Review Privacy, Terms and Account deletion pages (all marked as drafts), and remove the draft notices.
- [ ] Decide on tax-inclusive prices and refund wording with the payment partner.

## 4. Configure and deploy (owner, following the guides)

- [ ] Billing in test mode: `docs/payments-setup.md`.
- [ ] Deploy pipeline: GitHub environments, secrets and `DEPLOY_*` variables: `docs/deployment.md`.
- [ ] App Links: put the Play App Signing SHA-256 fingerprint in `apps/web/public/.well-known/assetlinks.json` and deploy the site.
- [ ] Replace the placeholder brand (logo, launcher icon, Play icon) if you want a designed one; regenerate icons.

## 5. Play Console (owner)

- [ ] Store listing: `docs/launch/play-listing.md` (take real screenshots).
- [ ] Data safety: `docs/launch/data-safety.md`.
- [ ] Content rating: `docs/launch/content-rating.md`.
- [ ] Target audience 13+, not in the Families programme; ads: none.
- [ ] Closed test with ≥ 12 testers for 14 days: `docs/launch/closed-test.md`.
- [ ] Run the manual QA checklist (`docs/qa-checklist.md`) on at least one low-end phone, including the Premium section with a license tester.
- [ ] Apply for production; release with a staged rollout.

## 6. After launch

- [ ] Switch billing on (`feature_flags.billing = true`) when the store products are live.
- [ ] Watch PostHog (if configured): completion rate per mode, D1/D7 retention, Premium views → purchases (BUILD_PROMPT §13).
- [ ] Watch Fly.io logs for webhook failures and the API's `/ready`.

## Unfinished work (code)

Known gaps, deliberately left for after launch or for an owner decision:

- **Custom questions** (BUILD_PROMPT §7 describes on-device custom questions with a profanity filter) are not built. Nothing in the app lets people add their own questions yet.
- **The web player is free-only**: web subscribers get Premium in the app, but `/play` doesn't unlock premium categories.
- **Error reporting covers the app only.** The API logs errors on Fly.io; the website has none. Sentry for the API (as in Weblume) is a small addition if needed.
- **Analytics ask happens only in Settings.** There is no first-run prompt, so few people may opt in. Consider one gentle prompt after a finished game.
- **No iOS release** and no App Store payments (out of scope).
- **Cold start on a low-end phone** isn't measured: on a Pixel 10 Pro XL emulator on a fast Mac, cold start was 0.7–0.8 s (1.9 s on the very first launch). Measure on a real budget phone during the closed test (budget: < 2 s).
- **Trivia countdown isn't persisted**: after the app is killed mid-question, that question's timer restarts.
