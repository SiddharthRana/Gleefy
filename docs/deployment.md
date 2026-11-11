# Deployment

One GitHub Actions workflow (`.github/workflows/ci.yml`) tests everything and, on `main`, offers three deploys. Each deploy waits for your approval in its GitHub environment:

| Target  | Environment  | What it does                                                                                 | Host                  |
| ------- | ------------ | -------------------------------------------------------------------------------------------- | --------------------- |
| Backend | `backend`    | `supabase db push` (migrations), then `flyctl deploy` of the API image, then a smoke test    | Supabase + **Fly.io** |
| Website | `web`        | Static export (`next build` → `out/`), then `wrangler pages deploy` to the production branch | **Cloudflare Pages**  |
| Android | `play-store` | Signed app bundle (version code = workflow run number), uploaded to a Play track             | **Google Play**       |

Supabase hosts the database and sign-in but can't run the NestJS API, so the API runs on Fly.io and talks to Supabase. The App Store isn't included: iOS is out of scope until an Apple developer account and iOS payments exist (BUILD_PROMPT §11, §16).

## How a release works

1. Merge `dev` into `main` (day-to-day work goes into `dev` through pull requests). CI runs the usual checks plus an API image build.
2. When everything passes, the run shows **Review deployments**. Tick `backend`, `web` and/or `play-store` and approve; the rest stay waiting (approve later, or reject).
3. Each deploy runs on its own. **Approve `backend` first** when a release needs new API or database changes; migrations must work with the API version already running (add columns before using them; drop them a release later).

Deploys never cancel each other, and only `main` deploys. CI doesn't build the Android app until release signing is set up (build it locally with `scripts/android-build.sh`); `deploy-android` stays off while `DEPLOY_ANDROID` isn't `"true"`. A target whose repository variable isn't `"true"` is skipped, so nothing fails before its accounts exist.

## One-time setup

### 1. GitHub environments (the deploy buttons)

**Settings → Environments → New environment**, three times: `backend`, `web`, `play-store`. For each:

- **Required reviewers:** add yourself. This creates the approval step. (Free for public repositories; private ones need a paid GitHub plan for required reviewers.)
- **Deployment branches and tags:** "Selected branches" → `main`.
- Add the environment's **secrets** and **variables** below.

Then **Settings → Secrets and variables → Actions → Variables** (repository level), set the switches once each target is ready:

| Variable         | Value  |
| ---------------- | ------ |
| `DEPLOY_BACKEND` | `true` |
| `DEPLOY_WEB`     | `true` |
| `DEPLOY_ANDROID` | `true` |

Shared repository variables (read by more than one job):

| Variable                   | Example                               | Used by          |
| -------------------------- | ------------------------------------- | ---------------- |
| `API_URL`                  | `https://api.gleefy.party`            | backend, Android |
| `SITE_URL`                 | `https://gleefy.party`                | web, Android     |
| `SUPABASE_URL`             | `https://<ref>.supabase.co`           | Android          |
| `SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_…` (public by design) | Android          |

### 2. Backend: Supabase + Fly.io

1. **Supabase:** create the project in **Singapore** (`ap-southeast-1`), the same region as the API on Fly (Fly no longer offers Mumbai for new machines), set up email codes and SMTP as in `docs/payments-setup.md` §1. Copy the **session pooler** connection string (Connect → Session pooler, port 5432). The direct connection is IPv6-only, and GitHub's runners have no IPv6.
2. **Fly.io:** install `flyctl`, then once, from the repo root:
   ```bash
   fly apps create gleefy-api          # or another name; set FLY_APP to match
   fly secrets set --app gleefy-api \
     DATABASE_URL='<Supabase pooler connection string>' \
     SUPABASE_URL='https://<ref>.supabase.co' \
     SUPABASE_SECRET_KEY='sb_secret_…' \
     CORS_ORIGINS='https://gleefy.party'
   ```
   Add billing secrets from `apps/api/.env.example` when you set up payments, and optionally `SENTRY_DSN` for API error reports. Non-secret settings (`NODE_ENV`, `PORT`, `TRUST_PROXY_HOPS=1`) are in `apps/api/fly.toml`. Point `api.<domain>` at the app with `fly certs add api.<domain>`.
3. Create a deploy token: `fly tokens create deploy --app gleefy-api`.
4. `backend` environment:

   | Kind     | Name              | Value                                                        |
   | -------- | ----------------- | ------------------------------------------------------------ |
   | secret   | `SUPABASE_DB_URL` | Session pooler connection string, with the database password |
   | secret   | `FLY_API_TOKEN`   | The deploy token                                             |
   | variable | `FLY_APP`         | App name, if not `gleefy-api`                                |

The machine keeps running (`min_machines_running = 1`) because store webhooks and Play notifications can arrive any time. Fly checks `/ready` (API and database up) and rolls machines one at a time.

### 3. Website: Cloudflare Pages

Every page is static (the web player runs in the browser), so the site is exported as plain files and served by Cloudflare Pages. Security headers come from `apps/web/public/_headers`; Pages serves `/pricing` from `pricing.html` and unknown paths from `404.html` with a 404 status.

1. Create the project once (no Git connection, so production only changes through the approved workflow):
   ```bash
   pnpm --filter @gleefy/web exec wrangler login
   pnpm --filter @gleefy/web exec wrangler pages project create gleefy --production-branch main
   ```
2. Add your domain under the project's **Custom domains**, and add it to the API's `CORS_ORIGINS`.
3. Create an API token (My Profile → API Tokens → Create token) with **Account → Cloudflare Pages → Edit**. Copy your account ID from the dashboard sidebar.
4. `web` environment:

   | Kind     | Name                       | Value                         |
   | -------- | -------------------------- | ----------------------------- |
   | secret   | `CLOUDFLARE_API_TOKEN`     | The token                     |
   | variable | `CLOUDFLARE_ACCOUNT_ID`    | Account ID                    |
   | variable | `CLOUDFLARE_PAGES_PROJECT` | Project name, if not `gleefy` |

   The site also reads the shared `SITE_URL`, `API_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` and `AUTH_GOOGLE_ENABLED` repository variables (the last one, `true` once Google sign-in is set up in Supabase, also goes into the Android build). They're baked into the files at build time, so redeploy after changing them.

Cloudflare's free plan covers a static site of this size (check Cloudflare's current limits and terms before launch). Because nothing runs server-side, there's no server to pay for or scale.

### 4. Android: Google Play

1. Create the upload keystore and enrol in Play App Signing (`apps/mobile/README.md`).
2. **Create the app in Play Console and upload the first bundle by hand.** Google's API can't create an app or make its first upload. Build it locally with the same `--dart-define`s the workflow uses, with a version code below the workflow's run numbers (the default `+1` is fine).
3. Google Cloud: a service account with a JSON key; in Play Console → Users and permissions, give it **Release to testing tracks** (and production, if the workflow should release there). The billing service account from `docs/payments-setup.md` §5 can be reused if it has these permissions.
4. `play-store` environment:

   | Kind     | Name                        | Value                                                        |
   | -------- | --------------------------- | ------------------------------------------------------------ |
   | secret   | `ANDROID_KEYSTORE_BASE64`   | `base64 -i gleefy-upload.jks` output                         |
   | secret   | `ANDROID_KEYSTORE_PASSWORD` | Keystore password                                            |
   | secret   | `ANDROID_KEY_ALIAS`         | `upload`                                                     |
   | secret   | `ANDROID_KEY_PASSWORD`      | Key password                                                 |
   | secret   | `PLAY_SERVICE_ACCOUNT_JSON` | Service account key JSON                                     |
   | variable | `PLAY_TRACK`                | `internal` (default), `alpha` (closed testing), `production` |
   | variable | `PLAY_RELEASE_STATUS`       | `completed` (default) or `draft` to review in Play Console   |

Start on `internal`, move to `alpha` for the closed test (≥ 12 testers for 14 days, required for new personal accounts), and promote to production in Play Console or by changing `PLAY_TRACK`.

## Warmup: the test copy (warmup.gleefy.party)

A full second copy for trying changes before production, deployed from the `dev` branch on every push, with no approval. It shares nothing with production except the Cloudflare account, so a broken warmup deploy or a test purchase can't touch real players. The site shows a "Warmup" banner and is hidden from search engines.

|          | Production                              | Warmup                                                            |
| -------- | --------------------------------------- | ----------------------------------------------------------------- |
| Website  | Pages project `gleefy` → `gleefy.party` | Pages project `gleefy-warmup` → `warmup.gleefy.party`             |
| API      | Fly app `gleefy-api` (always on)        | Fly app `gleefy-warmup-api` (`fly.warmup.toml`, sleeps when idle) |
| Database | Supabase project (Pro organisation)     | Supabase project `gleefy-warmup` in a **Free** organisation       |
| Payments | Dodo live, Play production              | Dodo test mode, Play license testers                              |
| Deploys  | push to `main`, approved per target     | push to `dev`, automatic                                          |

The API is `warmup-api`, not `api.warmup`: Cloudflare's free certificate covers one level of subdomain (`*.gleefy.party`).

**Cost:** about $0 to $2 a month. The Fly machine stops when idle, Pages is free, and a project in a Free Supabase organisation costs nothing. Supabase bills compute per project _inside a paid organisation_, so warmup must not live in the Pro one. A Free project pauses after a week without use; restore it from the dashboard.

Set up once:

1. **Supabase, in a free organisation:** Dashboard → organisation switcher → **New organization** (for example "Playground"), plan **Free**. Create the project `gleefy-warmup` in it. (The Free plan allows two active free projects in total.) Then do what `docs/payments-setup.md` §1 says, with these URLs: Site URL `https://warmup.gleefy.party`; redirect URLs `https://warmup.gleefy.party/auth/callback` and `gleefy://auth-callback`. To move an existing project out of the Pro organisation instead: Project Settings → General → **Transfer project** → the free organisation (you must own both; it takes about two minutes of downtime).
2. **Pages:** `pnpm --filter @gleefy/web exec wrangler pages project create gleefy-warmup --production-branch main --force` (`--force` makes a classic Pages project; newer wranglers otherwise try to create a Workers project and fail), then add the custom domain `warmup.gleefy.party` and click **Activate domain** so Cloudflare adds the `warmup` CNAME to `gleefy-warmup.pages.dev`.
3. **Fly:**
   ```bash
   fly apps create gleefy-warmup-api
   fly secrets set --app gleefy-warmup-api \
     DATABASE_URL='<warmup session pooler string>' \
     SUPABASE_URL='https://<warmup-ref>.supabase.co' \
     SUPABASE_SECRET_KEY='sb_secret_…' \
     CORS_ORIGINS='https://warmup.gleefy.party' \
     BILLING_RETURN_URL='https://warmup.gleefy.party/account?checkout=success'
   fly certs add warmup-api.gleefy.party --app gleefy-warmup-api
   fly tokens create deploy --app gleefy-warmup-api --expiry 8760h
   ```
   Add the DNS-only (grey cloud) records Fly prints in Cloudflare. Payment settings are the test-mode ones from `docs/payments-setup.md` (Dodo `DODO_ENV=test`, its own webhook to `https://warmup-api.gleefy.party/v1/billing/webhooks/dodo`, and its own `BILLING_ACCOUNT_SECRET`).
4. **GitHub → Environments → New environment `warmup`:** no required reviewers; deployment branches: Selected → `dev`.
   - Secrets: `SUPABASE_DB_URL` (warmup pooler string), `FLY_API_TOKEN` (the warmup token), `CLOUDFLARE_API_TOKEN`.
   - Variables: `SITE_URL=https://warmup.gleefy.party`, `API_URL=https://warmup-api.gleefy.party`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (warmup values), `CLOUDFLARE_ACCOUNT_ID`, and `AUTH_GOOGLE_ENABLED` if Google sign-in is set up for warmup (add `https://<warmup-ref>.supabase.co/auth/v1/callback` to the OAuth client's redirect URIs).
   - Environment variables override the repository ones with the same name, so production keeps its own.
5. **Switch it on:** repository variable `DEPLOY_WARMUP_WEB=true` deploys the site on every push to `dev` (it only needs the Pages project and `CLOUDFLARE_API_TOKEN`), and `DEPLOY_WARMUP_BACKEND=true` also migrates the warmup database and deploys the API once steps 1 and 3 are done. The site works before the API exists: games are free and Premium says checkout isn't available.
6. **Android warmup build** (CI doesn't build the app, to save minutes):
   ```bash
   cd apps/mobile
   flutter build apk --release --split-per-abi \
     --dart-define=API_BASE_URL=https://warmup-api.gleefy.party \
     --dart-define=SITE_URL=https://warmup.gleefy.party \
     --dart-define=SUPABASE_URL=https://<warmup-ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=<warmup publishable key>
   ```
   Play purchases only work in a build installed from a Play testing track.

**Flow:** branch from `dev` → PR → merge into `dev` → try it on warmup.gleefy.party → merge `dev` into `main` → approve the production deploys.

## Rollback

- **API:** `fly releases --app gleefy-api`, then `fly deploy --image <previous image>`; or revert the commit on `main` and approve the backend deploy.
- **Website:** in the Pages project's **Deployments**, open an earlier production deployment and choose **Rollback**.
- **Android:** halt the rollout in Play Console; ship a fix with a higher version code (Play never accepts a lower one).
- **Database:** migrations are forward-only. Write a new migration to undo a change and check it with `pnpm db:verify`.
- **Emergency:** `update public.feature_flags set enabled = false where key = 'billing';` stops purchases within 30 seconds, no deploy needed.

## Verified so far

- The workflow passes `actionlint`.
- The API image builds and runs as the `node` user. Against a migrated Postgres 17 it reports healthy and answers `/health`, `/ready` and `/v1/billing/config`.
- `supabase db push` applies the migration to a fresh Postgres (with the auth stub), records it, and on a second run reports the database up to date.
- The site exports as static files, and all 84 Playwright tests (axe, headers, clean URLs, 404 status) pass against `wrangler pages dev`, Cloudflare's local Pages server.
- **Not verified:** the deploy jobs against real Supabase, Fly.io, Cloudflare or Google Play (no accounts exist yet), and the approval flow on GitHub. The first approved deploy of each target is the real test; watch its log.
