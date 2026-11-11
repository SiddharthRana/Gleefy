# Google Play store listing (draft)

Copy for Play Console → Grow → Store presence → Main store listing. Check lengths in the console; Play counts characters, not bytes.

## App details

| Field                    | Value                                                                       |
| ------------------------ | --------------------------------------------------------------------------- |
| App name (≤ 30)          | Gleefy: Party Games                                                         |
| Short description (≤ 80) | Party games for one phone: Would You Rather, trivia, This or That and more. |
| Category                 | Games → Casual (alternative: Trivia)                                        |
| Tags                     | Party, Trivia, Casual, Offline, Family (pick the closest Play offers)       |
| Contact email            | hello@gleefy.party                                                          |
| Website                  | https://gleefy.party                                                        |
| Privacy policy URL       | https://gleefy.party/privacy (still a draft: needs legal review first)      |
| Account deletion URL     | https://gleefy.party/account-deletion (Play's Data safety form asks for it) |

The name was checked on Play and against trademarks on 2026-11-08 (see `docs/DECISIONS.md`).

## Full description (≤ 4000)

> **Party games for the people in the room.** Gleefy turns one phone into a game night: pick a game, read it out, and let everyone answer. Nobody else needs to install anything, and you never need an account to play.
>
> **Five ways to play**
> • **Would You Rather**: two choices, everyone votes, and the reveal shows how the room split. See the most divisive and most unanimous questions at the end.
> • **This or That**: rapid-fire picks with big buttons. Add a 5-second timer, or pass the phone so everyone answers on their own and find out who agrees most.
> • **Trivia Blitz**: four choices against the clock, in teams. Speed bonuses, a pausable timer and a short explanation after every answer.
> • **Guess the Answer**: one reader, three clues, fewer points for every clue you need.
> • **Custom party packs**: line up several games and play them back to back.
>
> **Made for groups**
> • 580 original questions across 31 categories, from pop culture to space
> • Add player or team names for turns and scores; they stay on your phone
> • 5, 10, 15 or 20 rounds; skip anything that doesn't suit your group
> • Big text, dark mode, reduced motion and screen-reader support
> • Works offline. A game survives a phone call or the app closing
> • Share a game link: friends get the same questions in the app or their browser
>
> **Free to play, with optional Premium.** Every game and every free category is free, with no ads. Gleefy Premium adds premium categories in every game, for one small payment. No subscription: pay once and keep it.
>
> **Private by design.** No account needed to play, no ads, no tracking. Anonymous usage statistics are off unless you turn them on.
>
> Gleefy is made for ages 13 and up. Accounts and purchases are for people aged 18 or over.

Keep these claims true when the app changes: counts on the store must not exceed what ships (BUILD_PROMPT §6).

## Graphics

| Asset                 | Spec                              | Status                                                                                           |
| --------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------ |
| App icon              | 512 × 512 PNG                     | `docs/brand/play-store-icon-512.png`                                                             |
| Feature graphic       | 1024 × 500 PNG/JPG                | `docs/brand/feature-graphic.png` (made by `scripts/brand-icons.mjs`)                             |
| Phone screenshots     | 2–8, 16:9 or 9:16, ≥ 1080 px side | `docs/brand/play-screenshots/` (5 at 1344 × 2688: onboarding, home, WYR reveal, trivia, results) |
| 7" / 10" tablet shots | Optional                          | Skip until tablets are tested                                                                    |

Screenshots: run a release build on an emulator or phone and use `adb exec-out screencap -p > shot.png`, in light theme, with real content. Don't add text that promises features the app lacks.

## Other Play Console declarations

- **Target audience and content:** ages 13–15, 16–17 and 18+. Do **not** select under-13 groups, and don't join the Families programme (BUILD_PROMPT §0).
- **Ads:** No ads.
- **Data safety:** see [`data-safety.md`](data-safety.md).
- **Content rating:** see [`content-rating.md`](content-rating.md).
- **Government apps / financial features / health:** No.
- **News app:** No.
- **App access:** All features are available without signing in; Premium needs a license-tester account for review. Give reviewers a test account that has bought the test Premium unlock if Play asks.
