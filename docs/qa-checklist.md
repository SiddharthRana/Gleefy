# Manual QA checklist

Run on a real Android phone (ideally a small, low-end one) before each release. Tick every box; note the device, Android version and app version.

## First launch

- [ ] Onboarding shows three pages; Next, Skip and "Let's play" all reach Home.
- [ ] The age note (13+) is visible on onboarding.
- [ ] Relaunching the app goes straight to Home.
- [ ] Settings → "Show the introduction again" shows onboarding again.

## Would You Rather — Quick play

- [ ] Home → Quick play starts round 1 of 10 immediately.
- [ ] The screen stays on while playing (wait longer than the screen-off timeout).
- [ ] Tapping each option adds a vote; the counter updates; Undo removes the last vote.
- [ ] Reveal shows percentages and a short verdict (split / everyone agrees / no votes); voting is locked after reveal.
- [ ] Skip replaces the question without using up a round.
- [ ] Next round advances; the last round says "See results".
- [ ] Results show rounds and votes, most divisive / most unanimous (when there are enough votes) and every round's split.
- [ ] Play again starts a new shuffle with the same settings; Change setup opens setup; Home returns home.

## Setup

- [ ] All free categories can be ticked; the premium category shows a lock and can't be ticked.
- [ ] The 13+ category shows its content note.
- [ ] Deselecting every category disables Start.
- [ ] 5 / 10 / 15 / 20 rounds work; choosing more rounds than questions shows the explanation.
- [ ] Group size: "Any" by default; with 3 players, a 4th vote is ignored and the counter shows "3 of 3 votes".
- [ ] The last setup is remembered next time.

## Interruptions

- [ ] Mid-game, press Home, open other apps, return: the game is unchanged.
- [ ] Mid-game, swipe the app away from recents, relaunch: Home offers "Resume" with the right round; votes cast are kept.
- [ ] Discard on Home removes the saved game.
- [ ] System back and the close button both ask before quitting; "Keep playing" returns to the same state.
- [ ] Rotate the phone (if rotation is on): nothing is lost.
- [ ] Receive a call mid-game: the game is unchanged afterwards.

## This or That

- [ ] Room mode: one tap reveals, shows a discussion prompt; Next works.
- [ ] Pass the phone (3+ names): each player's name shows in turn; the reveal lists who picked each side; results show the most in-sync pair.
- [ ] 5-second timer: running out reveals "Time's up!"; leaving the app pauses it.

## Trivia Blitz

- [ ] With team names, turns alternate; scores and the winner are right.
- [ ] Choices appear in a different order each game; the explanation shows after answering.
- [ ] Timer 10/20/30 s counts down, pauses during a phone call or when the app is hidden, and "Time's up!" scores 0.
- [ ] Timer Off: no bar, no bonus.

## Guess the Answer

- [ ] The answer card is visible to the reader; clues reveal one at a time; points drop 3 → 2 → 1.
- [ ] Got it / Give up / Skip behave as labelled; the scoreboard is right.

## Players, favourites and party packs

- [ ] Players screen: add, remove, clear; the 13th name is refused.
- [ ] Save a favourite from any setup screen; it starts from Home; remove works.
- [ ] Recent games show on Home and start the same setup.
- [ ] Custom party pack: games play in order, "Next: …" moves on, "Finish party" returns home; quitting mid-party ends it.

## Accessibility and display

- [ ] TalkBack: options read as "Add a vote for: …" with the current count; reveal reads percentages.
- [ ] System font size at maximum: questions remain readable and nothing is cut off.
- [ ] Big text setting enlarges text further.
- [ ] Reduce motion (in-app and the system "Remove animations") turns off transitions and the reveal animation.
- [ ] Dark theme and light theme both look right; theme setting follows the system when set to System.
- [ ] Every tappable control is comfortable to hit with a thumb.

## Premium and accounts (Phase 4; needs a build with `--dart-define`s and a license tester)

- [ ] Without the dart-defines, Premium says it isn't available and every free game still works.
- [ ] A locked premium category shows "See Premium"; Premium lists the premium categories.
- [ ] Settings shows "Sign in" while signed out; the website header shows "Sign in".
- [ ] Sign-in needs "I'm 18 or older" ticked (for Google and for the email code); an email code arrives, a wrong code is refused, the right one signs in.
- [ ] Continue with Google (app): the browser opens Google, then the app comes back to the screen you were on, signed in. Cancelling on Google's page says "Google sign-in was cancelled."
- [ ] Continue with Google (website): comes back through `/auth/callback` to Account (or Premium if you started there).
- [ ] The price button says "Unlock Premium for …" with Google Play's local price, and "One payment. Yours to keep".
- [ ] Buying as a license tester: Play sheet → spinning "Confirming your purchase" card → "Premium is unlocked!" with confetti; the purchase shows as acknowledged in Play Console; premium categories unlock in setup.
- [ ] A slow test card (Play's "slow test card, approves after a few minutes"): "Waiting for your payment"; Premium unlocks once it approves.
- [ ] Kill the app right after paying; on relaunch Premium turns on without paying again.
- [ ] Airplane mode for days: Premium stays on.
- [ ] Restore purchases on a second phone signed in to the same account unlocks Premium.
- [ ] Refund in Play Console: Premium turns off at the next app launch.
- [ ] Leave the app in the background for over an hour, reopen: Premium and Account still load (the sign-in refreshes itself).
- [ ] Delete account (type DELETE): signed out, Premium off; signing in again creates a fresh free account.
- [ ] Website: sign in to the same account shows "Premium unlock via Google Play … Yours to keep".
- [ ] Website `/play` signed in with Premium: premium categories can be ticked and played; signed out they're locked.
- [ ] Website (Dodo test mode): "Unlock Premium for $2.99" → Dodo checkout → back on Account: "Confirming your payment" → "Premium is unlocked!"; a declined test card shows "Your payment didn't go through"; buying again is refused with "You already have Premium"; a refund in the Dodo dashboard turns Premium off.

## My questions

- [ ] Settings → My questions: add a Would You Rather and a This or That question; edit one; delete one and undo.
- [ ] Rude words, identical options, duplicates and over-long options are refused with a clear message.
- [ ] In setup, "My questions" appears but isn't ticked; tick only it and play: only your questions appear.
- [ ] Quick play never shows your questions. Kill the app mid-game: Resume still shows them.

## Usage stats (builds with `POSTHOG_KEY`)

- [ ] Settings shows "Share anonymous usage stats", switched off on a fresh install.
- [ ] With it off, PostHog's live events show nothing from the phone.
- [ ] Turned on: play a game; `app_opened`, `game_started` and `game_completed` arrive with mode and rounds, and no names or questions.
- [ ] Turned off again: events stop.
- [ ] On a fresh install, after the first finished game the results screen asks once; either answer hides it for good.

## Website

- [ ] Home, Games, every game guide, How to play, FAQ, Guides, Contact, Premium, Account, Account deletion, Privacy and Terms load on a phone and a desktop.
- [ ] The landing-page demo works and "Another one" shows a different question.
- [ ] Privacy and Terms clearly say they are drafts awaiting legal review.
