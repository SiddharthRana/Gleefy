# Closed test plan

New personal Google Play developer accounts must run a **closed test with at least 12 testers who stay opted in for 14 consecutive days** before applying for production access. Check the current numbers in Play Console (Dashboard → "Apply for production") before you start, because Google has changed them before.

## Before day 1

1. Play Console developer account verified, app created as `com.gleefy.app`, first bundle uploaded by hand (see `docs/deployment.md` §4).
2. Store listing, Data safety, content rating and target audience filled in (`docs/launch/`).
3. Billing configured in **test mode**, testers added under Setup → License testing so test purchases are free (`docs/payments-setup.md`).
4. Recruit **15–20 testers** (some always drop out): friends, family, colleagues with Android phones, ideally including a few low-end phones and older Android versions. Collect their Google account emails in a Google Group or an email list.
5. Create the closed testing track (e.g. `alpha`), add the testers' list, and publish a release there. Set the deploy workflow's `PLAY_TRACK` variable to `alpha` so approved releases go to it.
6. Share the opt-in link. Each tester must open it, tap **Become a tester**, then install from Play.

## What to ask testers to do

Send a short message with the opt-in link and these tasks, spread over the two weeks:

- Play each game at least once with other people: Would You Rather, This or That (also pass-the-phone), Trivia Blitz with two teams, Guess the Answer, and a custom party pack.
- Try the accessibility settings (big text, dark theme, reduced motion) and TalkBack if they use it.
- Open a shared game link from the website.
- Sign in (with Google and with an email code) and "buy" Premium (free as a license tester); check it unlocks on the website too.
- Report anything confusing, broken, wrong (trivia answers!) or unsuitable.

Feedback route: a simple form (Google Forms is fine) with: phone model, Android version, game, what happened, screenshot. Play also collects private feedback from testers on the listing.

## During the 14 days

- Keep the release live and **don't remove testers**; the 14 days must be continuous for at least 12 of them.
- Ship fixes to the same track (approve the Android deploy). New versions don't reset the clock.
- Turn on "Share anonymous usage stats" in a few testers' builds (or ask testers to) to check that analytics and error reports arrive.
- Track feedback in issues; fix crashes and wrong answers first.

## Applying for production

Play asks about the test: how testers were recruited, how many engaged, what feedback you got and what you changed, and why the app is ready. Keep notes during the test so these answers are easy. After approval, promote the tested release to production with a staged rollout (e.g. 20% first).
