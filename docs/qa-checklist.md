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
- [ ] Sign-in needs "I'm 18 or older" ticked; an email code arrives, a wrong code is refused, the right one signs in.
- [ ] Monthly and annual prices come from Google Play in local currency.
- [ ] Buying as a license tester: Play sheet → "Confirming your purchase…" → "Premium is on"; the purchase shows as acknowledged in Play Console; premium categories unlock in setup.
- [ ] Kill the app right after paying; on relaunch Premium turns on without paying again.
- [ ] Airplane mode: Premium stays on; after the paid period plus 3 days offline it locks.
- [ ] Restore purchases on a second phone signed in with the same email unlocks Premium.
- [ ] Cancel in Google Play: Premium shows "Ends on …" and stays on until then.
- [ ] Refund in Play Console: Premium turns off at the next app launch.
- [ ] Delete account (type DELETE): signed out, Premium off; signing in again creates a fresh free account.
- [ ] Website: sign in with the same email shows the Play subscription with "Manage in Google Play".
- [ ] Website (sandbox provider): subscribe → provider checkout → Account shows Premium; "Manage subscription" opens the portal; the app shows "manage it on the website" for this account.

## Usage stats (builds with `POSTHOG_KEY`)

- [ ] Settings shows "Share anonymous usage stats", switched off on a fresh install.
- [ ] With it off, PostHog's live events show nothing from the phone.
- [ ] Turned on: play a game; `app_opened`, `game_started` and `game_completed` arrive with mode and rounds, and no names or questions.
- [ ] Turned off again: events stop.

## Website

- [ ] Home, Games, every game guide, How to play, FAQ, Guides, Contact, Premium, Account, Account deletion, Privacy and Terms load on a phone and a desktop.
- [ ] The landing-page demo works and "Another one" shows a different question.
- [ ] Privacy and Terms clearly say they are drafts awaiting legal review.
