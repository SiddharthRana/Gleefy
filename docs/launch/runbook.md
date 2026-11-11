# Launch runbook: from today to Gleefy on Google Play

Step by step, in the order to do it. Written for where things stand on 2026-11-11: **gleefy.party is bought on Cloudflare, the Google Play developer account exists, and Dodo Payments already accepts you as a seller (Weblume).** The code is finished; these steps are accounts, settings and deploys.

**Why this order:** a new personal Play account must run a **closed test with at least 12 testers for 14 days** before it can publish to everyone. That is the longest wait, so the plan gets a first (free-only) build to testers as early as possible, then adds sign-in and Premium while the 14 days run. New versions during the test don't reset the clock.

| Day  | Phase                                                   | Result                                                  |
| ---- | ------------------------------------------------------- | ------------------------------------------------------- |
| 1    | 1. Email · 2. Website                                   | hello@gleefy.party works; https://gleefy.party is live  |
| 1–2  | 3. Android app in Play Console                          | First build on the internal track; store forms done     |
| 2–3  | 4. Closed test starts                                   | 12+ testers opted in: **the 14 days start**             |
| 3–5  | 5. Backend · 6. Google sign-in                          | API at api.gleefy.party; sign-in works                  |
| 5–7  | 7. Payments (test mode) · 8. Automatic Android releases | Premium can be bought with test cards / license testers |
| 7–17 | 9. During the test: content, legal, QA                  | Trivia verified, legal pages reviewed                   |
| 17+  | 10. Production                                          | Live payments, production access, staged rollout        |

Keep a password manager entry for every secret you create below. Never commit secrets.

---

## Phase 1 — Email on gleefy.party (30 minutes)

1. **Cloudflare dashboard → gleefy.party → Email → Email Routing → Get started.** Let it add the MX/TXT records.
2. Add a custom address **hello@gleefy.party** → forward to your Gmail. Confirm the verification email.
   (Optional: add **support@** and **privacy@** the same way.)
3. To _reply_ from that address later, Gmail → Settings → Accounts → "Send mail as" needs an SMTP server; use the Resend account from Phase 5 step 3, or simply reply from Gmail for now.
4. **GitHub → SiddharthRana/Gleefy → Settings → Secrets and variables → Actions → Variables → New repository variable:**
   - `CONTACT_EMAIL` = `hello@gleefy.party`
5. Claim social handles (Instagram, TikTok, X, YouTube) as `gleefy` or `gleefy.party` if free.

## Phase 2 — Website live at https://gleefy.party (1 hour)

The site works without the backend: games are free and Premium says checkout isn't available yet.

1. In a terminal, from the repo folder:
   ```bash
   pnpm --filter @gleefy/web exec wrangler login
   pnpm --filter @gleefy/web exec wrangler pages project create gleefy --production-branch main
   ```
2. **Cloudflare → Workers & Pages → gleefy → Custom domains → Set up a domain:** add `gleefy.party`, then also `www.gleefy.party` (Cloudflare creates the DNS records because the domain is on Cloudflare).
3. **Cloudflare → My Profile → API Tokens → Create token → Custom token:** permission **Account → Cloudflare Pages → Edit**, your account only. Copy the token. Copy your **Account ID** from the right sidebar of the dashboard home.
4. **GitHub → Settings → Environments → New environment `web`:**
   - Required reviewers: add yourself.
   - Deployment branches: Selected branches → `main`.
   - Secret `CLOUDFLARE_API_TOKEN` = the token.
   - Variable `CLOUDFLARE_ACCOUNT_ID` = the account ID.
5. **Repository variables** (Settings → Secrets and variables → Actions → Variables):
   - `SITE_URL` = `https://gleefy.party`
   - `API_URL` = `https://api.gleefy.party` (the API comes in Phase 5; the site already handles it being down)
   - `DEPLOY_WEB` = `true`
6. **Deploy:** GitHub → Actions → the latest run on `main` → **Re-run all jobs**. When the checks pass, click **Review deployments**, tick `web`, **Approve and deploy**.
7. Open https://gleefy.party, /play, /privacy and /terms. (They still show "draft" notices until Phase 9.)

## Phase 3 — The app in Play Console (half a day)

### 3a. Upload key (once, keep it forever)

```bash
keytool -genkey -v -keystore ~/gleefy-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the file and both passwords in your password manager **and** a second safe place. Losing it means asking Google to reset the upload key.

Create `apps/mobile/android/key.properties` (git-ignored):

```
storeFile=/Users/siddharthrana/gleefy-upload.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

### 3b. Create the app

1. **Play Console → Create app:** name **Gleefy**, default language English (US), **Game**, **Free**, accept the declarations.
2. **Dashboard → Set up your app**, fill in:
   - **Privacy policy:** `https://gleefy.party/privacy`
   - **App access:** "All functionality is available without special access" (Premium testing comes later via license testers).
   - **Ads:** No.
   - **Content rating:** answer from `docs/launch/content-rating.md`.
   - **Target audience:** 13–15, 16–17, 18+; not designed for children; not in Families.
   - **News app:** No. **Data safety:** answer from `docs/launch/data-safety.md` (if PostHog isn't set up, leave out the analytics rows).
   - **Government app / Financial features / Health:** No.
   - **Store listing:** copy from `docs/launch/play-listing.md`. Icon: `docs/brand/play-store-icon-512.png`. Feature graphic (1024×500) and at least 2 phone screenshots (take them on the emulator or your phone: Home, a game, results with XP, Trophies, Premium).
   - **Category:** Games → Casual (or Trivia/Word). Contact email: hello@gleefy.party. Website: https://gleefy.party.

### 3c. First build, uploaded by hand

Google's API can't make the very first upload, so do this one manually (later releases come from GitHub in Phase 8):

```bash
cd apps/mobile
flutter build appbundle --release --build-number=1 \
  --dart-define=SITE_URL=https://gleefy.party
```

1. **Play Console → Testing → Internal testing → Create new release.**
2. Accept **Play App Signing** (Google holds the app signing key; you keep the upload key).
3. Upload `apps/mobile/build/app/outputs/bundle/release/app-release.aab`, release name `0.1.0 (1)`, notes "First test build", **Save → Review → Start rollout**.
4. **Testers tab:** create an email list with your own Google account; open the opt-in link on your phone and install. Check it runs.

### 3d. App Links (share links open the app)

1. **Play Console → Test and release → Setup → App signing:** copy the **SHA-256** of the _App signing key certificate_.
2. In `apps/web/public/.well-known/assetlinks.json`, replace `REPLACE_WITH_PLAY_APP_SIGNING_SHA256_FINGERPRINT` with it. Commit on a branch → PR into `dev` → merge `dev` into `main` → approve the `web` deploy.
3. Check: `https://gleefy.party/.well-known/assetlinks.json` shows the fingerprint.

## Phase 4 — Start the closed test (do this as early as possible)

Follow `docs/launch/closed-test.md`. In short:

1. Recruit **15–20 testers** with Android phones (friends, family, colleagues; some drop out). Collect their Google account emails in a **Google Group**.
2. **Play Console → Testing → Closed testing → Create track** (call it `alpha`), add the Google Group, promote the internal release to it (or upload the same .aab), **Start rollout**. The first review can take a few days.
3. Send testers the opt-in link with the tasks in `closed-test.md`. The 14 days count from when 12 testers are opted in. **Don't remove testers** during the 14 days.

## Phase 5 — Backend: Supabase + Fly.io (half a day)

### 5a. Supabase project

1. **supabase.com → New project:** name `gleefy`, region **Southeast Asia (Singapore)**, the same region as the API on Fly (Fly no longer offers Mumbai), a strong database password (save it).
2. **Project Settings → API:** copy the **Project URL** (`https://<ref>.supabase.co`), the **publishable key** (`sb_publishable_…`) and the **secret key** (`sb_secret_…`).
3. **Connect → Session pooler:** copy that connection string (port 5432) and put your database password in it. Use this one everywhere (GitHub's runners have no IPv6).
4. **Authentication → Providers → Email:** enabled; "Confirm email" off is fine (codes verify the address).
5. **Authentication → Email templates:** in **Magic Link** and **Confirm signup**, make the body show the code, for example:
   ```
   <h2>Your Gleefy code</h2><p>Enter this code in Gleefy: <strong>{{ .Token }}</strong></p>
   ```
6. **SMTP (needed; Supabase's own email is for testing only):** the **Resend** domain `gleefy.party` is already verified (done for warmup with Resend's Cloudflare auto-setup: CNAMEs `send` and `rsend`, TXT `resend._domainkey`). Create a separate API key for production (sending access, domain `gleefy.party`). **Supabase → Authentication → SMTP Settings:** host `smtp.resend.com`, port 465, user `resend`, password = the Resend API key, sender `Gleefy <hello@gleefy.party>`.
7. **Authentication → URL Configuration:** Site URL `https://gleefy.party`; Redirect URLs `https://gleefy.party/auth/callback` and `gleefy://auth-callback`.

### 5b. Fly.io API

1. Install flyctl (`brew install flyctl`) and `fly auth login` (create an account; it needs a card).
2. From the repo root:
   ```bash
   fly apps create gleefy-api
   fly secrets set --app gleefy-api \
     DATABASE_URL='<session pooler string>' \
     SUPABASE_URL='https://<ref>.supabase.co' \
     SUPABASE_SECRET_KEY='sb_secret_…' \
     CORS_ORIGINS='https://gleefy.party,https://www.gleefy.party'
   fly tokens create deploy --app gleefy-api
   ```
   Copy the deploy token. (The region is Singapore, `primary_region = "sin"` in `apps/api/fly.toml`, next to the database; change both together if your players are mostly elsewhere.)
3. **GitHub → Environments → New environment `backend`:** required reviewer you, branch `main`.
   - Secret `SUPABASE_DB_URL` = the session pooler string.
   - Secret `FLY_API_TOKEN` = the deploy token.
4. **Repository variables:** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `DEPLOY_BACKEND` = `true`.
5. **Deploy:** re-run the latest `main` workflow, approve **backend** (it runs the database migrations, then deploys the API, then checks `/ready`). Approve **web** too so the site picks up the Supabase variables.
6. **Custom domain for the API:**
   ```bash
   fly certs add api.gleefy.party --app gleefy-api
   ```
   Fly prints the DNS records. In **Cloudflare DNS**, add them with the proxy **off** (grey cloud, "DNS only"). Then `fly certs check api.gleefy.party --app gleefy-api` until it's issued.
7. Check: `https://api.gleefy.party/ready` returns OK, and the website's Account page shows the sign-in form. Try an email code sign-in on the website.

## Phase 6 — "Continue with Google" (30 minutes)

Warmup already has this working (2026-11-11): Google Cloud project **Gleefy**, published, with branding links on `warmup.gleefy.party` and one web client. For production, reuse that project:

1. **Google Auth Platform → Branding:** change the home page, privacy and terms links from `https://warmup.gleefy.party/...` to `https://gleefy.party`, `https://gleefy.party/privacy` and `https://gleefy.party/terms`. Under **Authorized domains**, add the production project's `<ref>.supabase.co` (the bare `supabase.co` is refused as "must be a top private domain"). Keep the logo empty unless you want Google's brand verification (adding one starts a review; basic scopes otherwise need none).
2. **Clients → Create client → Web application** `Gleefy production`: JavaScript origin `https://gleefy.party`; redirect URI `https://<ref>.supabase.co/auth/v1/callback`. Copy the client ID and secret.
3. **Supabase (production) → Authentication → Sign In / Providers → Google:** enable, paste the client ID and secret.
4. **GitHub → Environments → web:** variable `AUTH_GOOGLE_ENABLED` = `true`, then redeploy **web** (re-run `main`, approve web).
5. Check on the website: Account → tick 18+ → Continue with Google → back on the site, signed in.

## Phase 7 — Payments in test mode (half a day)

Everything here is test mode: nobody is charged.

### 7a. Google Play product and access

1. **Play Console → Monetize → Products → In-app products → Create:** product ID **`gleefy_premium_unlock`**, name "Gleefy Premium", description "Unlock every premium category, once.", price **USD 2.99** (let Play convert; optionally set INR 99 for India). **Activate.**
2. **Play Console → Settings → License testing:** add your Google account and testers who'll try Premium (purchases are free for them).
3. **Google Cloud (project gleefy) → APIs & Services → Library:** enable **Google Play Android Developer API**.
4. **IAM → Service accounts → Create** `play-api`; **Keys → Add key → JSON** (download it).
5. **Play Console → Users and permissions → Invite new user:** the service account's email; app permissions for Gleefy: **View financial data**, **Manage orders and subscriptions**, and **Release to testing tracks** (used in Phase 8). The same key serves both.
6. Generate the account secret: `openssl rand -hex 32` (save it; never change it later).

### 7b. Play notifications (RTDN)

1. **Google Cloud → Pub/Sub → Create topic** `play-billing`. On the topic's **Permissions**, add `google-play-developer-notifications@system.gserviceaccount.com` as **Pub/Sub Publisher**.
2. **IAM → Service accounts → Create** `pubsub-push`.
3. **Pub/Sub → Subscriptions → Create:** topic `play-billing`, type **Push**, endpoint `https://api.gleefy.party/v1/billing/google-play/rtdn`, **Enable authentication** with service account `pubsub-push@<project>.iam.gserviceaccount.com`, audience `https://api.gleefy.party/v1/billing/google-play/rtdn`.
4. **Play Console → Monetize → Monetization setup:** topic `projects/<project>/topics/play-billing`, tick voided purchase notifications, **Send test notification**.

### 7c. Dodo Payments (test mode)

1. **Dodo dashboard (test mode):** if Dodo asks for each website to be approved, add **gleefy.party** as a new brand or website first.
2. **Products → Create:** one-time product "Gleefy Premium", **USD 2.99**, turn on Adaptive Currency. Copy the product ID (`pdt_…`).
3. **Developer → API keys:** create a test key.
4. **Developer → Webhooks → Add endpoint:** `https://api.gleefy.party/v1/billing/webhooks/dodo`, events **payment.succeeded, refund.succeeded, dispute.lost**. Copy the signing secret (`whsec_…`).

### 7d. Give the API the billing settings

```bash
fly secrets set --app gleefy-api \
  WEB_PAYMENT_PROVIDER=dodo \
  DODO_ENV=test \
  DODO_API_KEY='<test API key>' \
  DODO_WEBHOOK_SECRET='whsec_…' \
  DODO_PRODUCT_PREMIUM='pdt_…' \
  BILLING_RETURN_URL='https://gleefy.party/account?checkout=success' \
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(base64 -i ~/Downloads/<play-api-key>.json)" \
  GOOGLE_PLAY_RTDN_AUDIENCE='https://api.gleefy.party/v1/billing/google-play/rtdn' \
  GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT='pubsub-push@<project>.iam.gserviceaccount.com' \
  BILLING_ACCOUNT_SECRET='<the openssl value>'
```

Then switch billing on (for testing): **Supabase → SQL editor:**

```sql
update public.feature_flags set enabled = true where key = 'billing';
```

### 7e. Test both channels

- **Website:** sign in → Premium → **Unlock Premium for $2.99** → pay with a Dodo test card → back on Account you should see "Premium is unlocked!". Refund it in Dodo → Premium goes away.
- **Android:** needs the build from Phase 8 (with the API and Supabase settings), installed from the test track by a license tester: Settings → Sign in → Premium → buy → "Premium is unlocked!".

## Phase 8 — Automatic Android releases from GitHub (1 hour)

1. Encode the keystore: `base64 -i ~/gleefy-upload.jks | pbcopy`.
2. **GitHub → Environments → New environment `play-store`:** required reviewer you, branch `main`.
   - Secrets: `ANDROID_KEYSTORE_BASE64` (pasted), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` = `upload`, `ANDROID_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON` (the full JSON text of the play-api key).
   - Variables: `PLAY_TRACK` = `alpha` (the closed test), `PLAY_RELEASE_STATUS` = `completed`.
3. Repository variable `DEPLOY_ANDROID` = `true`. Optional: `POSTHOG_KEY` for opt-in analytics.
4. Re-run the latest `main` workflow and approve **play-store**. It builds a signed bundle with your API, Supabase and Google settings (version code = the run number) and puts it on the closed test. Testers get it as an update.

From now on, every release is: merge `dev` into `main` → approve `backend`, `web`, `play-store`.

## Phase 9 — While the 14 days run

1. **Trivia review (a second person):**
   ```bash
   pnpm content:review ~/trivia-review.csv
   ```
   They check every row against its source and fill `ok` = yes (and notes). Then:
   ```bash
   pnpm content:mark-verified ~/trivia-review.csv
   pnpm content:sync && pnpm content:validate
   ```
   Fix or delete flagged questions first. Commit → PR → release.
2. Read every Would You Rather, This or That and Guess card once for tone.
3. **Legal:** have a lawyer review /privacy, /terms and /account-deletion; decide tax-inclusive pricing and refund wording with Dodo; then remove the draft notices (ask me and I'll do it).
4. **Trademark:** professional clearance search; consider filing "Gleefy" in classes 9 and 41.
5. **QA:** run `docs/qa-checklist.md` on a cheap Android phone, including Premium as a license tester and a Dodo test purchase. Measure cold start (< 2 s).
6. Fix what testers report (ship to the same track; it doesn't reset the clock). Keep notes: Play asks how the test went.

## Optional: the warmup test copy

Once production works, set up **warmup.gleefy.party**, a full test copy that updates on every merge into `dev` (no approval) so you can try changes before releasing them. It costs about $0–2 a month if its Supabase project lives in a **Free** organisation, not the Pro one. Steps: `docs/deployment.md` → Warmup.

## Phase 10 — Go live

1. **Dodo → live mode:** create the live product ($2.99) and webhook (same URL and events) and a live API key, then:
   ```bash
   fly secrets set --app gleefy-api DODO_ENV=live DODO_API_KEY='<live key>' \
     DODO_WEBHOOK_SECRET='<live whsec>' DODO_PRODUCT_PREMIUM='<live pdt_>'
   ```
2. **Supabase:** move to **Pro** before taking real payments (backups, no pausing).
3. **Play Console → Dashboard → Apply for production** (after 14 days with 12+ testers). Answer the questions from your notes.
4. When approved: **Production → Create release** from the tested bundle (or set `PLAY_TRACK=production`), **staged rollout 20%**, then 50% and 100% over a few days while watching crashes and reviews.
5. Billing stays on (`feature_flags.billing = true`). Watch `https://api.gleefy.party/ready`, `fly logs --app gleefy-api` for webhook errors, and PostHog if set up.

## If something breaks

- Stop all purchases instantly: `update public.feature_flags set enabled = false where key = 'billing';` (takes effect within 30 seconds).
- Roll back the API, website or app: `docs/deployment.md` → Rollback.

## Monthly running costs (approximate)

| Service                              | Cost                                         |
| ------------------------------------ | -------------------------------------------- |
| gleefy.party (Cloudflare)            | ~$5 a year                                   |
| Cloudflare Pages + Email Routing     | Free                                         |
| Fly.io (one small always-on machine) | ~$2–5                                        |
| Supabase                             | Free while testing; Pro $25 at launch        |
| Resend (email codes)                 | Free up to 3,000 emails a month              |
| Google Play                          | 15% of sales (one-time $25 account: done)    |
| Dodo Payments                        | ~4% + $0.15 per sale (+ currency conversion) |
