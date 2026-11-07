# Handoff — resume Gleefy in a new chat

Paste this into a new Claude Code session on the `siddharthrana/gleefy` repository:

> Continue building Gleefy. Read `docs/HANDOFF.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` and `docs/BUILD_PROMPT.md` first, then carry on from "Next" in PROGRESS.md. Branch from `main` for new work. Payments are built (`apps/api`, ported from Weblume) and set up per `docs/payments-setup.md`. Commit and push after each step.

## Status

All five phases are complete in code. What's left is the owner's launch work in `docs/launch/checklist.md`: accounts, domain, legal review, a second-person trivia review, billing and deploy setup, Play Console forms and the closed test.

## Where things are

- **Branches** (same as Weblume): `dev` is the default branch; start new work on a branch from `dev` and open a PR into it. `main` is the release branch: merging `dev` into `main` is what deploys (each target still waits for approval).
- **Launch:** `docs/launch/` (checklist, Play listing, Data safety, content rating, closed test) and `docs/privacy-data-map.md`.
- **Analytics:** opt-in only, `apps/mobile/lib/telemetry/analytics.dart`; off unless built with `POSTHOG_KEY`.
- **Deploys:** `.github/workflows/ci.yml` has approval-gated deploy jobs (environments `backend`, `web`, `play-store`), switched on by `DEPLOY_*` repository variables. Setup: `docs/deployment.md`.
- **Payments:** `apps/api` (NestJS billing API), `supabase/migrations`, `packages/plans`, app `lib/account` + `lib/billing`, web `/pricing` + `/account`. Setup steps: `docs/payments-setup.md`.
- **Status and next steps:** `docs/PROGRESS.md` (always the source of truth; updated at every commit).
- **Why things are the way they are:** `docs/DECISIONS.md`.
- **The full product spec and phases:** `docs/BUILD_PROMPT.md`.

## Environment setup (cloud container)

```bash
pnpm install
pnpm --filter "./packages/*" run build
# Flutter isn't preinstalled; this worked here:
curl -sSLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz
tar xf flutter_linux_3.47.9-stable.tar.xz -C /opt && git config --global --add safe.directory /opt/flutter
export PATH=/opt/flutter/bin:$PATH
cd apps/mobile && flutter pub get
```

CI doesn't build the Android app (to save build minutes) until release signing for Play testing is set up. Build it on a Mac with the Android SDK: `scripts/android-build.sh`.

Database tests need Postgres 17 and `psql`. Without a local `psql`, run Postgres in Docker and point `DB_ADMIN_URL` at it:

```bash
docker run -d --name gleefy-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:17
pnpm db:verify && pnpm db:test-setup
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/gleefy_test pnpm test
```

## Checks to run before every commit

```bash
pnpm format && pnpm format:check && pnpm content:validate && pnpm lint && pnpm typecheck && pnpm test   # with TEST_DATABASE_URL for the API e2e
pnpm db:verify
pnpm --filter @gleefy/web build && pnpm --filter @gleefy/web test:e2e
cd apps/mobile && dart format lib test && flutter analyze && flutter test
```

## Conventions that matter

- Content lives in `packages/content/packs/*.json`; after editing run `pnpm content:validate` and `pnpm content:sync`.
- Game rules exist twice: TypeScript (`packages/game-engine`) is the reference, Dart (`apps/mobile/lib/game`) is a port. After changing rules, run `pnpm --filter @gleefy/game-engine vectors` and make `flutter test` pass.
- UI strings go in `apps/mobile/lib/l10n/app_en.arb`.
- Never trust a client-side premium flag: `premiumProvider` derives only from the server-verified entitlement (`lib/account/entitlement.dart`). Entitlements change in `packages/plans`; the API's `SubscriptionStore` is the only writer of `subscriptions`.
- API errors carry a stable `code`; the app and website branch on codes, not messages.
- Commit after each step and push to the branch; keep `docs/PROGRESS.md` accurate.
- Widget tests: use the scroll-aware `tapText`/`reveal` helpers; on screens with a running countdown use `tester.pump(...)` instead of `pumpAndSettle()`.
