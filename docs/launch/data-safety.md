# Google Play Data safety answers (draft)

Answers for Play Console → App content → Data safety, based on what the code does (see [`../privacy-data-map.md`](../privacy-data-map.md)). Google changes the form's wording; check each answer against the current form and the privacy policy before submitting. Not legal advice.

## Overview

| Question                                                              | Answer                                                                                             |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Does your app collect or share any of the required user data?         | **Yes** (only for purchasers, and analytics only after opt-in)                                     |
| Is all of the user data encrypted in transit?                         | **Yes** (HTTPS to the API, Supabase and PostHog)                                                   |
| Do you provide a way for users to request that their data is deleted? | **Yes**: in the app (Settings → Account → Delete account), on the website, and `/account-deletion` |

**Sharing:** Supabase (database and sign-in), Fly.io (API hosting) and PostHog (analytics) process data on our behalf as service providers, which Google's definitions don't count as "sharing". Google Play, Paddle and Dodo Payments handle payments as the store or merchant of record. Answer **No data shared** unless a provider is used for its own purposes.

## Data types collected

| Data type (Play category)                                                         | Collected                      | Optional?                                  | Purposes                              | Notes                                                                  |
| --------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------ | ------------------------------------- | ---------------------------------------------------------------------- |
| Personal info → **Email address**                                                 | Yes                            | Yes (only to buy or restore Premium)       | Account management, App functionality | Supabase Auth; deleted with the account                                |
| Financial info → **Purchase history**                                             | Yes                            | Yes                                        | App functionality, Account management | Subscription status and period, from Google Play / the payment partner |
| App activity → **App interactions**                                               | Yes                            | Yes (opt-in "Share anonymous usage stats") | Analytics                             | Games started/finished, rounds, Premium screen views                   |
| App info and performance → **Crash logs**                                         | Yes                            | Yes (same opt-in)                          | Analytics                             | Error type, truncated message and stack trace                          |
| App info and performance → **Diagnostics**                                        | No                             |                                            |                                       |                                                                        |
| Device or other IDs → **Device or other IDs**                                     | Yes                            | Yes (same opt-in)                          | Analytics                             | Random install id, reset when sharing is turned off                    |
| Location, contacts, photos, audio, files, calendar, health, messages, web history | **No**                         |                                            |                                       | Player names never leave the phone                                     |
| Financial info → Payment info (cards, UPI)                                        | **No** (the app never sees it) |                                            |                                       | Entered in Google Play's or the payment partner's own checkout         |

For each collected type, answer **"processed ephemerally": No** and **"collected, not shared"**.

## Before submitting

- The privacy policy at `/privacy` must describe the same data (it currently does, as a draft awaiting legal review).
- If analytics are never configured (`POSTHOG_KEY` unset in the release build), remove the three analytics rows: the app can't send them.
- Re-check this page whenever the app starts collecting something new.
