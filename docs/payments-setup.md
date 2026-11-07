# Payments setup

Gleefy sells one thing: **Gleefy Premium, a one-time unlock** (indicative price **$2.99**, no subscription). It's sold through two channels that grant the same entitlement (`premiumContent`). The design and code are ported from Weblume (`apps/api/src/billing`), including Weblume's later fixes (Dodo as the web provider, payer-email matching, honest checkout results, token refresh in the app, Google sign-in). Weblume sells subscriptions; Gleefy uses the same pipeline for a one-time product.

| Channel                                     | Who it's for                                                         | How it works                                                                                                     |
| ------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Google Play Billing**                     | Android app users (required by Play policy for in-app digital goods) | One-time product bought in the app → API verifies with Google and acknowledges → RTDN reports refunds and voids  |
| **Web: Dodo Payments** (Merchant of Record) | Website visitors                                                     | Hosted checkout → signed `payment.succeeded` webhook → Premium; `refund.succeeded` / `dispute.lost` take it away |

Guests never need an account. Only purchasers sign in (**Continue with Google**, or an email one-time code, in the app and on the website), so one purchase works on every device.

Everything below uses **test** modes. Nothing is charged until you switch to live keys. Nothing here has been set up yet: no Supabase project, Play Console app or Dodo account exists.

## 0. Why one-time, why Dodo

- **One-time, $2.99:** party games are an occasional purchase, and many players won't subscribe to one. A single small payment that's "yours to keep" converts better. Fees bite hard at low prices, so this stays above $2.
- **Fees on $2.99** (third-party 2026 figures; confirm on each provider's pricing page): Google Play takes 15% (≈ $0.45). Dodo takes about 4% + 15¢ for Indian sellers (≈ $0.27), plus 4% currency conversion paid by the customer unless **Fees Inclusive** is on. Paddle (5% + 50¢, ≈ $0.65, and custom pricing for products under $10) was dropped; Weblume made the same call (DECISIONS).
- Dodo is India-based, accepts Indian sellers, supports UPI, and is the legal seller: it charges the customer, handles VAT/GST/sales tax, issues receipts and handles refunds and chargebacks. Confirm your eligibility with Dodo before launch, or launch Android-only with `WEB_PAYMENT_PROVIDER=none`.

## 1. Supabase (purchaser accounts)

1. Create a project. Copy the **project URL** and the **publishable key** (or legacy anon key).
2. **Authentication → Providers → Email:** enabled. **Authentication → Email templates:** edit **Confirm signup** (first sign-in) and **Magic Link** (later sign-ins) to show `{{ .Token }}`, so people get a 6-digit code rather than a link. Check the OTP length is 6.
3. **Continue with Google** (same as Weblume):
   1. In Google Cloud → **APIs & Services → Credentials**, create an **OAuth client ID** of type **Web application**. Authorised redirect URI: `https://<ref>.supabase.co/auth/v1/callback`. Fill in the OAuth consent screen (app name Gleefy, support email, privacy policy URL; scopes `email`, `profile`, `openid` only).
   2. **Supabase → Authentication → Providers → Google:** enable it and paste the client ID and secret.
   3. **Authentication → URL configuration:** site URL = your website; **Redirect URLs:** `https://<your-site>/auth/callback` and `gleefy://auth-callback` (the Android app's deep link).
   4. Set the GitHub repository variable **`AUTH_GOOGLE_ENABLED=true`**. It turns the button on in the website build (`NEXT_PUBLIC_AUTH_GOOGLE_ENABLED`) and the Android build (`--dart-define=AUTH_GOOGLE_ENABLED`). Leave it unset until the provider works, and the button stays hidden.
   5. Test once from the website and once from the app: the browser opens Google, then returns to `/auth/callback` (website) or straight back into the app.
4. Apply the database migrations: `supabase db push`, or run `supabase/migrations/*.sql` in the SQL editor. They create `profiles`, `subscriptions` (the purchase records), `webhook_events` and `feature_flags` with row-level security (users can only read their own rows; all writes go through the API).
5. Copy the **pooled connection string** into the API's `DATABASE_URL`, and the **secret key** (`sb_secret_…`) into `SUPABASE_SECRET_KEY` (used only to delete auth users on account deletion).
6. Set up custom SMTP (Supabase's built-in email is rate-limited and meant for testing).

## 2. Price

- **Entitlements** and the indicative price shown on the website live in `packages/plans/src/plans.ts` (`displayPrice`: 299 US cents).
- **The real price** lives in Google Play Console and the Dodo dashboard. Set it in **US dollars** in both; customers pay in local currency (Play converts per country, with optional per-country overrides; Dodo's **Adaptive Currency** converts at checkout, with optional **Localized Pricing** or **Purchasing Power Parity**). A cheaper Indian price (for example ₹99) is a per-country override, not a code change.
- Decide whether displayed prices include tax, and keep `/pricing` consistent.

## 3. Dodo Payments (test mode)

1. Create an account, complete business verification, and stay in **Test mode**.
2. **Products:** create a **one-time** product "Gleefy Premium" at $2.99. Copy its product ID → **`DODO_PRODUCT_PREMIUM`**.
3. **Developer → API keys:** `DODO_API_KEY`; `DODO_ENV=test`; `WEB_PAYMENT_PROVIDER=dodo`.
4. **Developer → Webhooks:** `https://<your-api>/v1/billing/webhooks/dodo`, with at least `payment.succeeded`, `refund.succeeded` and `dispute.lost`. Signing secret (`whsec_…`) → `DODO_WEBHOOK_SECRET`.
5. `BILLING_RETURN_URL=https://<your-site>/account?checkout=success`. Dodo adds `payment_id` and `status`; the account page reads them, shows a "confirming / unlocked / still waiting / didn't go through" card, and removes them from the address.
6. Run one purchase end to end with a test card: checkout opens, a processed `payment.succeeded` webhook appears in the API logs, and **Account** says "Premium is unlocked". Then refund it in the dashboard and check Premium goes away. If field names differ, adjust `apps/api/src/billing/providers/dodo.provider.ts` and its tests (fields checked against Dodo's API reference on 2026-11-07).

The checkout carries the user id in `metadata`; if Dodo doesn't copy it onto the payment, the API matches the payer's email (case-insensitive) to an account. That can only ever unlock the account the payer chose.

## 4. Google Play Billing

### Play Console

1. Create the app with package name **`com.gleefy.app`** and upload a release (internal testing is fine) signed with the upload key (`apps/mobile/README.md`). Play only offers billing to uploaded apps.
2. **Monetize → Products → One-time products:** create **`gleefy_premium_unlock`** (must match `GOOGLE_PLAY_PRODUCT_ID`), non-consumable, price $2.99 (Play suggests converted prices per country). Activate it.
3. **Setup → License testing:** add tester accounts so test purchases aren't charged.

### Google Cloud: server access

1. In the Cloud project linked to Play Console, enable the **Google Play Android Developer API**.
2. Create a service account and a JSON key → **`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`** (raw or base64; API-only secret).
3. **Play Console → Users and permissions:** invite the service account with **View financial data** and **Manage orders and subscriptions**.
4. Set **`BILLING_ACCOUNT_SECRET`** to at least 32 random characters (`openssl rand -hex 32`). It derives the opaque account id sent to Play with each purchase. **Set it once**: changing it breaks matching for existing purchases. The API refuses to start in production with Play configured and no secret.

### Real-time Developer Notifications (RTDN)

1. **Pub/Sub:** create a topic (e.g. `play-billing`) and grant `google-play-developer-notifications@system.gserviceaccount.com` the **Pub/Sub Publisher** role on it.
2. **Play Console → Monetization setup:** set the topic, tick **voided purchase notifications**, and send a test notification (logged and ignored).
3. Create a **push subscription** to `https://<your-api>/v1/billing/google-play/rtdn` with **authentication** on: a service account (e.g. `pubsub-push@<project>.iam.gserviceaccount.com`) and audience `https://<your-api>/v1/billing/google-play/rtdn`. Put the same values in **`GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT`** and **`GOOGLE_PLAY_RTDN_AUDIENCE`**.

### How a Play purchase flows

1. The person signs in, opens **Premium**, and taps **Unlock Premium for $2.99** (the price comes from Play, in local currency). The app gets their account reference (`GET /v1/billing/google-play/account-ref`) and starts the purchase with it as `obfuscatedAccountId`.
2. Play returns a purchase token; the app sends it to `POST /v1/billing/google-play/verify`.
3. The API reads `purchases.products` for `gleefy_premium_unlock` from Google (a token for any other product is "not found"), checks the account reference matches the signed-in user (so a token can't be claimed by another account), saves the purchase and **acknowledges** it (unacknowledged purchases are refunded after 3 days).
4. Only then does the app complete the purchase on the device and refresh the entitlement; an animated card shows confirming → unlocked (with confetti), or why it didn't work, with **Try again** for a paid purchase the server couldn't confirm yet. If the app is killed mid-way, Play redelivers the purchase on next launch, and RTDN also acknowledges it as a fallback.
5. **Pending payments** (cash or bank methods) unlock nothing until Play reports them paid (`oneTimeProductNotification` PURCHASED). **Refunds and chargebacks** arrive as `voidedPurchaseNotification` and set the purchase to `refunded`.

## 5. Building the app and website with accounts

App (`--dart-define`; without these the app is fully playable and Premium says it isn't available in this build):

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.<domain> \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key> \
  --dart-define=AUTH_GOOGLE_ENABLED=true \
  --dart-define=SITE_URL=https://<domain>
```

The app keeps the sign-in session in the Android Keystore (`flutter_secure_storage`), not plain preferences.

Website: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` and `NEXT_PUBLIC_AUTH_GOOGLE_ENABLED`. Add the website origin to the API's `CORS_ORIGINS`. The deploy workflow fills these from repository variables (`docs/deployment.md`).

## 6. Switching billing on

1. Set the env vars above and deploy the API (health at `/health`, readiness at `/ready`).
2. Flip the kill switch: `update public.feature_flags set enabled = true where key = 'billing';`. It takes effect within 30 seconds.
3. `GET /v1/billing/config` shows what's available per channel; the website and app read it. If the API can't be reached, the pricing page says so after at most 10 seconds instead of spinning.

Switching `billing` off again stops new purchases **and** makes everyone Free (entitlements ignore purchases while it's off), and the app's cached entitlement follows on its next refresh. Use it only before launch or in an emergency.

## 7. Behaviour reference

- **Entitlements** come only from `subscriptions` rows (purchase records) written by verified events (`apps/api/src/billing/subscription-store.ts`). A one-time unlock is a row with `billing_interval = 'one_time'`, status `active` and no end date; `refunded` removes it; `on_hold` (payment pending) grants nothing.
- **Offline:** the app caches the last verified answer. A one-time unlock stays on without a connection for good; a refund takes effect the next time the phone is online (`apps/mobile/lib/account/entitlement.dart`). It refreshes on launch, on resume, after sign-in and on the Premium screen.
- **Expired sign-ins:** the app refreshes an expired token before calling the API, retries once with a fresh token after a 401, and treats "can't refresh while offline" as a connection problem so the cached Premium stays (ported from Weblume).
- **Idempotency:** each provider event ID (Pub/Sub `messageId` for Play, `webhook-id` for Dodo) is stored once in `webhook_events`; duplicates return `{"status":"duplicate"}`. Payloads are purged after 30 days.
- **Out-of-order events:** a row is updated only if the event is newer than the last applied one (`last_event_at`), so a late `payment.succeeded` can't undo a refund.
- **Failures** return 5xx so the provider retries. Signature failures return 401 and nothing is recorded.
- **Buying twice:** web checkout is refused (`already_purchased`) when the account already has Premium; the app shows "Premium is unlocked" instead of a price. If someone still ends up paying on both channels, both account pages say so and point to support for a refund.
- **Account deletion** (`DELETE /v1/me`, in the app and on the website) disables the account at once and deletes the auth user (and by cascade its purchases). Premium can't be moved to a new account afterwards; both UIs say so.
- **iOS:** no App Store purchases until iOS is in scope.
