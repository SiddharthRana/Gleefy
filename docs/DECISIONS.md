# Decisions

Short, dated records of non-trivial choices. Newest first.

## 2026-11-03 — Phase 5 polish and launch prep

**New content is mostly premium.** The packs were about 85% free against the ~60% target, so new categories went to premium where possible: This or That, Trivia and Guess now sit at 60% free. Would You Rather stays at 80% free; taking existing free categories away before launch felt worse than missing the ratio there.

**Trivia stays `self-checked` until a second person reviews it.** The spec requires `verified`, which by definition needs someone other than the author. Instead of marking our own work verified, a CSV review sheet (`pnpm content:review` / `content:mark-verified`) makes the review a spreadsheet job. _Rejected:_ hiding unverified questions now (it would ship 0 trivia).

**Analytics: PostHog over plain HTTP, opt-in only.** BUILD_PROMPT §2 allows "PostHog or none". The capture API needs no SDK, so the app gains almost no size and nothing runs unless the build has a key _and_ the person turns it on. Consent everywhere (not only EU/UK) keeps one simple rule. Error reports go to PostHog as `$exception` events instead of adding Sentry (one vendor, no native SDK). The website stays analytics-free. _Trade-off:_ few people may opt in, so the data will be thin.

**Accounts are 18+ by self-declaration.** BUILD_PROMPT §0 and India's DPDP Act: under-18s would need verifiable parental consent, so sign-in asks people to confirm they're 18 or older. Free play needs no account and no age gate beyond the 13+ guidance.

**Game guides are one static route.** `/games/[mode]` renders every mode's guide from shared data (`lib/guides.ts`) with real counts, so adding a mode is data, not a page. Trivia samples sort their choices, because packs list the right answer first.

**Guides in MDX**, as BUILD_PROMPT §2 specifies; two real guides rather than thin SEO pages.

## 2026-10-31 — Deploy pipeline

**One workflow, three approval-gated deploys.** The CI workflow ends with `deploy-backend`, `deploy-web` and `deploy-android` jobs on `main`. Each needs every check to pass and waits on a GitHub environment with required reviewers, so a green build shows "Review deployments" and each target ships only when approved. _Rejected:_ a separate deploy workflow triggered by `workflow_run` (harder to follow, and approvals would sit on a different run).

**Off until configured.** Each deploy job also needs a repository variable (`DEPLOY_BACKEND`, `DEPLOY_WEB`, `DEPLOY_ANDROID`) set to `true`, so `main` stays green before any account exists.

**Backend = Supabase migrations + Fly.io.** Supabase can't run the NestJS API, so the API runs as a container on Fly.io (Weblume's guide also suggests Fly). Migrations run first in the same job (`supabase db push`), so the database is never behind the code. One machine always runs, because webhooks arrive at any time.

**The website is a static export on Cloudflare Pages.** Every page was already prerendered and the web player runs in the browser, so `output: 'export'` loses nothing. Cloudflare's free plan allows commercial use, where Vercel's Hobby plan doesn't (Pro is $20 per seat per month). Security headers moved from `next.config.ts` to `public/_headers`, and the e2e tests run against `wrangler pages dev`, so headers, clean URLs and 404s are tested as Cloudflare serves them. CI builds the files from the commit that passed the checks and uploads them with `wrangler pages deploy`. _Rejected:_ Vercel (cost once Premium is on sale), and OpenNext on Workers (only needed if the site needs a server).

**Android: version code = workflow run number;** Google Play's `internal` track by default. The first upload is manual (Google's API can't create an app). No App Store job until iOS is in scope.

**Main builds never cancel each other.** Branch builds still cancel older ones, but a deploy must not be cut off half way, and a build waiting for approval mustn't block the next one.

## 2026-10-31 — Phase 4 payments

**Weblume's billing module, ported nearly unchanged.** `apps/api` copies Weblume's NestJS billing code (Play verify + acknowledge + RTDN, Paddle/Dodo adapters, `SubscriptionStore` as the single writer, webhook ledger, out-of-order guard, `billing` kill switch) with the plan renamed `starter` → `premium` and the scan features left out. The Flutter purchase gateway and controller are ported too. _Rejected:_ RevenueCat, a rewrite, or a second web provider at once.

**One entitlement, `premiumContent`.** Premium unlocks premium categories in every mode. "Advanced customisation" and "longer sessions" from BUILD_PROMPT §11 aren't built, so they aren't entitlements yet; adding one is a field in `packages/plans` plus the check where it's used.

**`packages/plans` instead of Weblume's `packages/shared`.** MirthMix already has content and engine packages; plans and access rules are the only billing code the API and website share, so they get a small package of their own.

**Purchasers sign in with an email one-time code.** No passwords to reset and no deep links to configure; the same flow works in the app (`signInWithOtp` / `verifyOTP`) and on the website. Weblume uses email + password; a party game's buyers sign in rarely, so a code is simpler. _Rejected:_ Google sign-in (needs OAuth client setup per platform) for v1.

**The API says when to re-check (`validUntil`), and the app adds a 3-day offline grace.** The app caches the last verified answer (user id, premium, `validUntil`, checked at) and keeps Premium until the end of the paid period plus 3 days without a connection, so it doesn't vanish at a party with bad signal. Any successful refresh replaces the cache, so a refund, cancellation or the kill switch takes effect as soon as the phone is online; 401/403 signs out and drops it. A cache for another user id is ignored. _Trade-off:_ the cache lives on the phone and premium content is in the bundle, so a rooted phone could unlock it; acceptable for v1 per §11.

**Account deletion in the app and on the website.** Google Play requires in-app deletion for apps that create accounts. Deletion disables the account at once and removes the Supabase auth user (subscriptions cascade); without `SUPABASE_SECRET_KEY` it stays pending and the hourly maintenance retries. Store subscriptions aren't cancelled automatically; both UIs say to cancel first.

**Maintenance on a timer, not pg-boss.** Weblume runs retention in a pg-boss worker because it already has scan jobs. MirthMix's only periodic work is purging webhook payloads after 30 days and retrying deletions, so an hourly `setInterval` (unref'd, idempotent) is enough.

**The web player stays free-only for now.** Unlocking premium categories in `/play` for web subscribers needs the player to check the entitlement; it's a small follow-up, not needed to sell Premium.

**Premium is visible but honest when unconfigured.** A build without `--dart-define`s, or a website without Supabase, says Premium isn't available instead of hiding it, and every free feature works without any backend.

## 2026-10-30 — Phase 3 web player and sharing

**A share link carries the setup and the seed, nothing else** (base64url JSON, validated strictly on decode). No server, no rooms, no personal data; two devices opening the same link get the same deal. _Rejected:_ short links stored server-side (needs a backend and storage).

**The web player is one client component using the shared engine and packs.** Pages stay static; only `/play` hydrates. Web play is single-group for now (no names or timers).

**App Links open `/play?c=` in the app** via an `autoVerify` intent filter; the domain and signing fingerprint are placeholders until the domain exists.

## 2026-10-30 — Phase 2 core modes

**This or That reuses the two-choice engine.** It is Would You Rather with a different pack and UI: one tap reveals for the room, or the vote cap equals the number of players when passing the phone, so vote _i_ is player _i_'s pick. Rounds now store their votes so "most in sync" can be computed. _Rejected:_ a separate engine (duplicate logic in two languages).

**Trivia choices are shuffled per question with `seed + dealIndex + 1`.** Every pack lists the correct answer first; the engine never shows that order. The seed keeps the order reproducible for vectors and share links.

**Scoring:** Trivia gives 100 for a correct answer plus `floor(50 × timeLeft / limit)`; Guess gives 3/2/1 by clues used. Integer maths only, so Dart and TypeScript agree.

**Players and teams are one list of names.** Trivia and Guess treat each name as a team taking turns; with no names, the group plays together. Names are snapshotted with the session so editing the list mid-game can't relabel scores.

**Countdowns count ticks, not wall-clock time,** and stop while the app is hidden, so a phone call never costs a turn. The countdown isn't persisted; after a process kill the question's timer restarts.

**Favourites, recents and party packs share one model** (`SavedGame` = a name plus a list of `GameSetup`s). A favourite is one setup, a party pack is several. Party packs use each mode's free categories.

**Trivia review status has three levels** (`draft`, `self-checked`, `verified`). Drafts never ship. The starter questions are `self-checked`; a human must verify them before launch.

**Guess the Answer shows the answer to the reader.** The reader must know it to judge guesses; the card is labelled "Reader only".

## 2026-10-30 — Phase 1 foundation

**Same stack and payment design as Weblume.** The owner asked for the latest tech and for payments to match the Weblume app. MirthMix copies Weblume's monorepo layout, tooling (pnpm 10, Node 22, ESLint 10 flat config, Prettier, Vitest 5, Playwright + axe), design-token pipeline and CI shape. Phase 4 will port Weblume's billing module: Google Play Billing verified by a NestJS API (subscriptionsv2, server-side acknowledge, RTDN) plus a Merchant of Record on the web (Paddle or Dodo, chosen by `WEB_PAYMENT_PROVIDER`). _Rejected:_ RevenueCat, which v2 of the prompt had considered; consistency with Weblume wins and that code is already written and tested.

**TypeScript 6.0, not 7.0.** TypeScript 7.0.2 is out, but typescript-eslint 8.72 supports `<6.1.0`. Move up when typescript-eslint does.

**No backend in Phase 1.** Everything runs on the device; the NestJS API and Supabase arrive with billing in Phase 4. Nothing in Phase 1 needs a server.

**Content tier lives on the category, not on each question.** A category is free or premium as a whole, which is how players will see it. Game logic never reads the tier; only setup (through `premiumProvider`) does.

**Premium is locked, not hidden, in Phase 1.** The premium "Time Travel" category is visible with a lock and "coming soon", so the separation is tested now. `premiumProvider` returns false until Phase 4, when it will come from server-verified entitlements only.

**Single source for content, copied into the app.** `pnpm content:sync` copies packs to `apps/mobile/assets/content/`; `pnpm content:validate` fails if the copy is stale. _Rejected:_ a Flutter asset path outside the app folder (Flutter doesn't allow it) and a symlink (breaks on Windows and in some CI caches).

**Zod 4 schema, JSON Schema generated from it.** One definition drives runtime validation and editor autocompletion (`schema/pack.schema.json` via `z.toJSONSchema`). The Dart app re-checks only what it needs to avoid crashing; a damaged pack shows an error screen.

**Deterministic engine with integer-only shuffling.** mulberry32 plus Fisher–Yates using `next() % (i + 1)` (no floating point), so the Dart port produces exactly the same order. The slight modulo bias is irrelevant for shuffling a few hundred questions. This also lets a future share link carry a seed.

**Test vectors instead of a shared runtime.** The TypeScript engine is the reference and writes `packages/game-engine/test-vectors/*.json`; Flutter tests replay them. _Rejected:_ running JS in Flutter or compiling Dart to JS for the web; both add weight for little gain.

**Would You Rather as a host-tallied vote.** One phone, many people: the host taps once per raised hand, with undo, an optional group-size cap, reveal and a split. Skip swaps in a spare question without using up a round; when none are left it spends the round as skipped. Results highlight the most divisive and most unanimous questions (only with at least two votes, and never the same question twice).

**Session persisted on every action** (shared_preferences, JSON). A killed app offers Resume on Home. Saved sessions that reference questions no longer in the content are discarded rather than crashing.

**Reducer is pure and returns the identical object for no-ops**, so the controller skips needless writes and rebuilds.

**`SkipQuestion`, not `Skip`.** `flutter_test` exports a `Skip` class; the action was renamed to avoid the clash.

**Fonts bundled, not fetched.** Fredoka and Nunito (OFL) are bundled in the app (≈650 KB) so it works offline at parties and doesn't depend on Google at runtime. The website uses `next/font`, which self-hosts them at build time.

**Screen-awake behind an interface** (`ScreenAwake`) so widget tests run without the platform plugin.

**Big text multiplies the system text scale** (× 1.25) rather than replacing it, so it stacks with accessibility settings.

**Placeholder brand.** An original geometric mark (two overlapping answer circles and a spark) drawn in code; launcher icons generated from it. Replace with a designed logo before launch.

**Website says "Android app coming soon"** rather than linking to a store listing that doesn't exist, and lists unbuilt modes as "In development" without links. Question counts on the site are computed from the real pack.
