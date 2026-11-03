# Deployment

One GitHub Actions workflow (`.github/workflows/ci.yml`) tests everything and, on `main`, offers three deploys. Each deploy waits for your approval in its GitHub environment:

| Target  | Environment  | What it does                                                                                 | Host                  |
| ------- | ------------ | -------------------------------------------------------------------------------------------- | --------------------- |
| Backend | `backend`    | `supabase db push` (migrations), then `flyctl deploy` of the API image, then a smoke test    | Supabase + **Fly.io** |
| Website | `web`        | Static export (`next build` → `out/`), then `wrangler pages deploy` to the production branch | **Cloudflare Pages**  |
| Android | `play-store` | Signed app bundle (version code = workflow run number), uploaded to a Play track             | **Google Play**       |

Supabase hosts the database and sign-in but can't run the NestJS API, so the API runs on Fly.io and talks to Supabase. The App Store isn't included: iOS is out of scope until an Apple developer account and iOS payments exist (BUILD_PROMPT §11, §16).

## How a release works

1. Merge to `main`. CI runs the usual checks plus an API image build.
2. When everything passes, the run shows **Review deployments**. Tick `backend`, `web` and/or `play-store` and approve; the rest stay waiting (approve later, or reject).
3. Each deploy runs on its own. **Approve `backend` first** when a release needs new API or database changes; migrations must work with the API version already running (add columns before using them; drop them a release later).

Deploys never cancel each other, and branch builds never deploy. A target whose repository variable isn't `"true"` is skipped, so nothing fails before its accounts exist.

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
| `API_URL`                  | `https://api.mirthmix.example`        | backend, Android |
| `SITE_URL`                 | `https://mirthmix.example`            | web, Android     |
| `SUPABASE_URL`             | `https://<ref>.supabase.co`           | Android          |
| `SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_…` (public by design) | Android          |

### 2. Backend: Supabase + Fly.io

1. **Supabase:** create the project (Mumbai is nearest India), set up email codes and SMTP as in `docs/payments-setup.md` §1. Copy the **session pooler** connection string (Connect → Session pooler, port 5432). The direct connection is IPv6-only, and GitHub's runners have no IPv6.
2. **Fly.io:** install `flyctl`, then once, from the repo root:
   ```bash
   fly apps create mirthmix-api          # or another name; set FLY_APP to match
   fly secrets set --app mirthmix-api \
     DATABASE_URL='<Supabase pooler connection string>' \
     SUPABASE_URL='https://<ref>.supabase.co' \
     SUPABASE_SECRET_KEY='sb_secret_…' \
     CORS_ORIGINS='https://mirthmix.example'
   ```
   Add billing secrets from `apps/api/.env.example` when you set up payments, and optionally `SENTRY_DSN` for API error reports. Non-secret settings (`NODE_ENV`, `PORT`, `TRUST_PROXY_HOPS=1`) are in `apps/api/fly.toml`. Point `api.<domain>` at the app with `fly certs add api.<domain>`.
3. Create a deploy token: `fly tokens create deploy --app mirthmix-api`.
4. `backend` environment:

   | Kind     | Name              | Value                                                        |
   | -------- | ----------------- | ------------------------------------------------------------ |
   | secret   | `SUPABASE_DB_URL` | Session pooler connection string, with the database password |
   | secret   | `FLY_API_TOKEN`   | The deploy token                                             |
   | variable | `FLY_APP`         | App name, if not `mirthmix-api`                              |

The machine keeps running (`min_machines_running = 1`) because store webhooks and Play notifications can arrive any time. Fly checks `/ready` (API and database up) and rolls machines one at a time.

### 3. Website: Cloudflare Pages

Every page is static (the web player runs in the browser), so the site is exported as plain files and served by Cloudflare Pages. Security headers come from `apps/web/public/_headers`; Pages serves `/pricing` from `pricing.html` and unknown paths from `404.html` with a 404 status.

1. Create the project once (no Git connection, so production only changes through the approved workflow):
   ```bash
   pnpm --filter @mirthmix/web exec wrangler login
   pnpm --filter @mirthmix/web exec wrangler pages project create mirthmix --production-branch main
   ```
2. Add your domain under the project's **Custom domains**, and add it to the API's `CORS_ORIGINS`.
3. Create an API token (My Profile → API Tokens → Create token) with **Account → Cloudflare Pages → Edit**. Copy your account ID from the dashboard sidebar.
4. `web` environment:

   | Kind     | Name                       | Value                                       |
   | -------- | -------------------------- | ------------------------------------------- |
   | secret   | `CLOUDFLARE_API_TOKEN`     | The token                                   |
   | variable | `CLOUDFLARE_ACCOUNT_ID`    | Account ID                                  |
   | variable | `CLOUDFLARE_PAGES_PROJECT` | Project name, if not `mirthmix`             |
   | variable | `PADDLE_CLIENT_TOKEN`      | Paddle client-side token (public by design) |
   | variable | `PADDLE_ENV`               | `sandbox` or `production`                   |

   The site also reads the shared `SITE_URL`, `API_URL`, `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` repository variables. They're baked into the files at build time, so redeploy after changing them.

Cloudflare's free plan covers a static site of this size (check Cloudflare's current limits and terms before launch). Because nothing runs server-side, there's no server to pay for or scale.

### 4. Android: Google Play

1. Create the upload keystore and enrol in Play App Signing (`apps/mobile/README.md`).
2. **Create the app in Play Console and upload the first bundle by hand.** Google's API can't create an app or make its first upload. Build it locally with the same `--dart-define`s the workflow uses, with a version code below the workflow's run numbers (the default `+1` is fine).
3. Google Cloud: a service account with a JSON key; in Play Console → Users and permissions, give it **Release to testing tracks** (and production, if the workflow should release there). The billing service account from `docs/payments-setup.md` §5 can be reused if it has these permissions.
4. `play-store` environment:

   | Kind     | Name                        | Value                                                        |
   | -------- | --------------------------- | ------------------------------------------------------------ |
   | secret   | `ANDROID_KEYSTORE_BASE64`   | `base64 -i mirthmix-upload.jks` output                       |
   | secret   | `ANDROID_KEYSTORE_PASSWORD` | Keystore password                                            |
   | secret   | `ANDROID_KEY_ALIAS`         | `upload`                                                     |
   | secret   | `ANDROID_KEY_PASSWORD`      | Key password                                                 |
   | secret   | `PLAY_SERVICE_ACCOUNT_JSON` | Service account key JSON                                     |
   | variable | `PLAY_TRACK`                | `internal` (default), `alpha` (closed testing), `production` |
   | variable | `PLAY_RELEASE_STATUS`       | `completed` (default) or `draft` to review in Play Console   |

Start on `internal`, move to `alpha` for the closed test (≥ 12 testers for 14 days, required for new personal accounts), and promote to production in Play Console or by changing `PLAY_TRACK`.

## Rollback

- **API:** `fly releases --app mirthmix-api`, then `fly deploy --image <previous image>`; or revert the commit on `main` and approve the backend deploy.
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
