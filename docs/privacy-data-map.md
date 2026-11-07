# Privacy data map

Everything MirthMix stores or sends, where it lives and when it's deleted. Keep this, `/privacy`, and `docs/launch/data-safety.md` in step. Reviewed 2026-11-07 against the code.

## On the phone only (never sent anywhere)

| Data                                                                  | Where                        | Deleted when                                             |
| --------------------------------------------------------------------- | ---------------------------- | -------------------------------------------------------- |
| Settings (theme, big text, motion, haptics, analytics opt-in)         | shared_preferences           | App data cleared / uninstall                             |
| Player and team names                                                 | shared_preferences           | Edited, or app data cleared                              |
| Game in progress, last setups, favourites, recent games, party packs  | shared_preferences           | Finished/discarded, or app data cleared                  |
| Progress: XP, level, streak, trophies, games played per mode          | shared_preferences           | App data cleared / uninstall                             |
| Cached Premium entitlement (user id, premium yes/no, one-time unlock) | shared_preferences           | Sign-out, account deletion, or a server answer of "free" |
| Supabase session (sign-in token)                                      | Android Keystore (encrypted) | Sign-out / account deletion                              |

## On the website (browser only)

| Data                                              | Where            | Notes                                                    |
| ------------------------------------------------- | ---------------- | -------------------------------------------------------- |
| Supabase session if signed in                     | localStorage     | No cookies, no analytics on the website                  |
| Shared game links                                 | URL (`/play?c=`) | Mode, categories, rounds and seed only; no personal data |
| Web player progress (XP, level, streak, trophies) | localStorage     | Never sent anywhere; cleared with the site data          |

## On our servers (purchasers only)

| Data                                                                                                  | Service                            | Purpose                            | Retention                                                                                 |
| ----------------------------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------- |
| Email, account creation time; with Google sign-in also the name and profile picture URL Google shares | Supabase Auth                      | Sign-in (only the email is used)   | Until account deletion                                                                    |
| Profile (deletion flag, Play account reference)                                                       | Supabase Postgres `profiles`       | Link Play purchases to the account | Until account deletion (cascade)                                                          |
| Purchases (provider, status, purchase time, provider ids)                                             | Supabase Postgres `subscriptions`  | Entitlements                       | Until account deletion (cascade)                                                          |
| Store/provider webhook events (payload may contain an email)                                          | Supabase Postgres `webhook_events` | Idempotency, troubleshooting       | Payload erased after 30 days by the API's hourly maintenance; the event id/type row stays |
| API request logs (method, path, status, request id; no bodies, headers or query strings)              | Fly.io                             | Operations                         | Fly's log retention                                                                       |

Payment details (cards, UPI) are entered only in Google Play's or the payment partner's checkout and never reach MirthMix.

## Opt-in analytics (only if the person turns it on)

| Data                                                                                                                                    | Service      | Retention                                                         |
| --------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ----------------------------------------------------------------- |
| Events: app opened, game started/completed (mode, rounds, categories count, timer, premium category), Premium viewed, purchase verified | PostHog (EU) | Per the PostHog project's retention setting; set it before launch |
| Error reports: type, message (≤ 500 chars), stack (≤ 40 lines)                                                                          | PostHog (EU) | Same                                                              |
| Random install id, app version, platform                                                                                                | PostHog (EU) | Id forgotten on the phone when sharing is turned off              |

Never sent: player names, questions (including custom ones), answers, email, account id, location, contacts.

## Optional error reports from the API and website (only when a Sentry DSN is configured)

| Data                                                                   | Service | Notes                                                                    |
| ---------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------ |
| API: unexpected (5xx) errors with the route pattern, method and status | Sentry  | No user, IP, cookies, auth or signature headers, bodies or query strings |
| Website: JavaScript errors with the page path                          | Sentry  | No user, headers, query strings, console or click breadcrumbs            |

## Account deletion

`DELETE /v1/me` (app, website, or by email request): marks the profile deleted at once, clears the Play account reference, deletes the Supabase auth user (profile and purchaseons cascade). Without `SUPABASE_SECRET_KEY` the auth user removal is retried hourly. Store subscriptions must be cancelled separately; both UIs say so.

## Age

Play is for 13+; accounts and purchases are for 18+ (self-declared at sign-in), because India's DPDP Act treats under-18s as children needing verifiable parental consent. No features target children, and the app is not in Google Play's Families programme.
