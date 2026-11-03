// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MirthMix';

  @override
  String get tagline => 'Party games for one phone';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s play';

  @override
  String get onboarding1Title => 'Party games for one phone';

  @override
  String get onboarding1Body =>
      'Quick games for friends, couples and families sitting together. No setup, no app for everyone.';

  @override
  String get onboarding2Title => 'Read it out. Vote together.';

  @override
  String get onboarding2Body => 'One person reads, everyone answers. Pass the phone around or let a host keep score.';

  @override
  String get onboarding3Title => 'No sign-up. Just play.';

  @override
  String get onboarding3Body => 'Start a game in seconds. Nothing you play leaves your phone.';

  @override
  String get onboardingAge => 'MirthMix is made for ages 13 and up.';

  @override
  String get homeGreeting => 'Ready to play?';

  @override
  String get homeQuickPlay => 'Quick play';

  @override
  String get homeQuickPlayBody => '10 rounds of Would You Rather, mixed free categories.';

  @override
  String get homeResumeTitle => 'Game in progress';

  @override
  String homeResumeBody(String mode, int round, int total) {
    return '$mode · round $round of $total';
  }

  @override
  String get homeResume => 'Resume';

  @override
  String get homeDiscard => 'Discard';

  @override
  String get homeAllGames => 'All games';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get settings => 'Settings';

  @override
  String get libraryTitle => 'Games';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get modeWyrName => 'Would You Rather';

  @override
  String get modeWyrBlurb => 'Two choices. Everyone picks a side.';

  @override
  String get modeWyrRules =>
      'Read both options aloud. Everyone raises a hand for their pick, then tap each side once per vote. Reveal to see how the room split.';

  @override
  String get modeTotName => 'This or That';

  @override
  String get modeTotBlurb => 'Rapid-fire picks with big buttons.';

  @override
  String get modeTriviaName => 'Trivia Blitz';

  @override
  String get modeTriviaBlurb => 'Beat the timer, top the table.';

  @override
  String get modeGuessName => 'Guess the Answer';

  @override
  String get modeGuessBlurb => 'Fewer clues, more points.';

  @override
  String get modeCustomName => 'Custom Party Pack';

  @override
  String get modeCustomBlurb => 'Mix modes into one session.';

  @override
  String get setupTitle => 'Set up the game';

  @override
  String get setupHowToPlay => 'How to play';

  @override
  String get setupCategories => 'Categories';

  @override
  String get setupCategoriesHint => 'Pick at least one.';

  @override
  String get setupRounds => 'Rounds';

  @override
  String get setupGroupSize => 'Group size';

  @override
  String get setupGroupSizeHint => 'Optional. Limits votes per round to the number of players.';

  @override
  String get setupGroupSizeAny => 'Any';

  @override
  String setupGroupSizeValue(int count) {
    return '$count players';
  }

  @override
  String get setupPlayersDecrease => 'Fewer players';

  @override
  String get setupPlayersIncrease => 'More players';

  @override
  String get setupStart => 'Start game';

  @override
  String setupQuestionsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count questions', one: '1 question');
    return '$_temp0';
  }

  @override
  String setupFewerQuestions(int count) {
    return 'Only $count questions in these categories, so you\'ll play $count rounds.';
  }

  @override
  String get premiumLabel => 'Premium';

  @override
  String get premiumLocked => 'Unlock with Premium.';

  @override
  String get regionIndia => 'India';

  @override
  String get ageTeen => '13+';

  @override
  String playRound(int round, int total) {
    return 'Round $round of $total';
  }

  @override
  String get playPrompt => 'Would you rather…';

  @override
  String get playOr => 'or';

  @override
  String get playHint => 'Raise hands, then tap a side once for each vote.';

  @override
  String playVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
      zero: 'No votes',
    );
    return '$_temp0';
  }

  @override
  String playVotesOfPlayers(int count, int players) {
    return '$count of $players votes';
  }

  @override
  String playVoteFor(String option) {
    return 'Add a vote for: $option';
  }

  @override
  String get playUndo => 'Undo';

  @override
  String get playSkip => 'Skip';

  @override
  String get playSkipTooltip => 'Skip this question';

  @override
  String get playReveal => 'Reveal';

  @override
  String get playNext => 'Next round';

  @override
  String get playFinish => 'See results';

  @override
  String get playQuit => 'Quit game';

  @override
  String get playQuitTitle => 'Quit this game?';

  @override
  String get playQuitBody => 'Your progress in this game will be lost.';

  @override
  String get playQuitConfirm => 'Quit';

  @override
  String get playKeepPlaying => 'Keep playing';

  @override
  String playSplit(int percent) {
    return '$percent%';
  }

  @override
  String get playTie => 'Perfect split!';

  @override
  String get playUnanimous => 'Everyone agrees!';

  @override
  String get playNoVotes => 'No votes this round.';

  @override
  String get resultsTitle => 'Results';

  @override
  String resultsSummary(int rounds, int votes) {
    String _temp0 = intl.Intl.pluralLogic(rounds, locale: localeName, other: '$rounds rounds', one: '1 round');
    String _temp1 = intl.Intl.pluralLogic(votes, locale: localeName, other: '$votes votes', one: '1 vote');
    return '$_temp0 · $_temp1';
  }

  @override
  String get resultsDivisive => 'Most divisive';

  @override
  String get resultsUnanimous => 'Most unanimous';

  @override
  String get resultsAllRounds => 'Every round';

  @override
  String get resultsSkipped => 'Skipped';

  @override
  String get resultsPlayAgain => 'Play again';

  @override
  String get resultsChangeSetup => 'Change setup';

  @override
  String get resultsHome => 'Home';

  @override
  String resultsSplit(int a, int b) {
    return '$a – $b';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPlay => 'Play';

  @override
  String get settingsBigText => 'Big text';

  @override
  String get settingsBigTextBody => 'Larger questions for reading across the room.';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionBody => 'Turn off animations. Your system setting is always respected.';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsBody => 'A small buzz when you tap a vote.';

  @override
  String get settingsShowOnboarding => 'Show the introduction again';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'You can play without an account. An account is only for buying Premium: it stores your email and subscription status on the MirthMix server. Games, settings and players are stored only on this phone.';

  @override
  String get settingsAge => 'Age guidance';

  @override
  String get settingsAgeBody =>
      'MirthMix is made for ages 13 and up. Categories marked 13+ include more mature themes, never explicit content.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get errorContentTitle => 'Games couldn\'t load';

  @override
  String get errorContentBody =>
      'The game content on this phone looks damaged. Reinstalling the app usually fixes this.';

  @override
  String get errorEmptyCategories => 'No questions are available for the selected categories.';

  @override
  String get errorNotFound => 'That page doesn\'t exist.';

  @override
  String get goHome => 'Go home';

  @override
  String get modeTotRules =>
      'Two quick options. Tap the room\'s pick, or pass the phone so everyone picks in turn. Add the timer for real rapid fire.';

  @override
  String get modeTriviaRules =>
      'Teams take turns answering. Faster correct answers score bonus points. Every question has a short explanation.';

  @override
  String get modeGuessRules =>
      'Only the reader looks at the screen. Read clue 1 aloud; if nobody gets it, read the next. Fewer clues, more points.';

  @override
  String get modeCustomRules => 'Pick the games to play in order. When one ends, the next starts with a tap.';

  @override
  String get setupPlayers => 'Players and teams';

  @override
  String get setupPlayersNone => 'Playing as one group';

  @override
  String get setupPlayersEdit => 'Edit';

  @override
  String get setupPassPhone => 'Pass the phone';

  @override
  String get setupPassPhoneBody => 'Each player picks in turn. Needs at least 2 players.';

  @override
  String get setupTimer => '5-second timer';

  @override
  String get setupTimerBody => 'Pick before time runs out.';

  @override
  String get setupTriviaTimer => 'Time per question';

  @override
  String get setupTimerOff => 'Off';

  @override
  String setupSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get setupSaveFavourite => 'Save as favourite';

  @override
  String get favouriteName => 'Name';

  @override
  String get favouriteSaved => 'Saved to favourites';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get playersTitle => 'Players and teams';

  @override
  String get playersBody =>
      'Add names to take turns and keep score. Names stay on this phone. Leave it empty to play as one group.';

  @override
  String get playersAdd => 'Add';

  @override
  String get playersName => 'Player or team name';

  @override
  String playersRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get playersClear => 'Clear all';

  @override
  String playersFull(int max) {
    return 'That\'s the maximum of $max.';
  }

  @override
  String get totPrompt => 'This or that?';

  @override
  String totPickFor(String name) {
    return '$name\'s pick';
  }

  @override
  String get totGroupPick => 'Tap the room\'s pick';

  @override
  String get totTimeUp => 'Time\'s up!';

  @override
  String get totDiscuss1 => 'Defend your pick in 10 seconds.';

  @override
  String get totDiscuss2 => 'Anyone want to switch sides?';

  @override
  String get totDiscuss3 => 'Who surprised you?';

  @override
  String totInSync(String a, String b) {
    return 'Most in sync: $a & $b';
  }

  @override
  String totInSyncBody(int matches, int rounds) {
    return 'Same pick $matches of $rounds times';
  }

  @override
  String secondsLeft(int seconds) {
    return '$seconds seconds left';
  }

  @override
  String turnOf(String name) {
    return '$name\'s turn';
  }

  @override
  String get everyone => 'Everyone';

  @override
  String questionOf(int round, int total) {
    return 'Question $round of $total';
  }

  @override
  String triviaCorrect(int points) {
    return 'Correct! +$points';
  }

  @override
  String get triviaWrong => 'Not quite.';

  @override
  String get triviaTimeUp => 'Time\'s up!';

  @override
  String triviaAnswerWas(String answer) {
    return 'Answer: $answer';
  }

  @override
  String triviaChoice(String letter, String text) {
    return 'Answer $letter: $text';
  }

  @override
  String get guessReaderOnly => 'Reader only — the answer is';

  @override
  String guessClue(int n) {
    return 'Clue $n';
  }

  @override
  String get guessNextClue => 'Next clue';

  @override
  String get guessGotIt => 'Got it!';

  @override
  String get guessGiveUp => 'Give up';

  @override
  String guessWorth(int points) {
    return 'Worth $points points';
  }

  @override
  String guessGuessing(String name) {
    return '$name guesses';
  }

  @override
  String guessScored(int points, String name) {
    return '+$points for $name';
  }

  @override
  String get guessNoPoints => 'No points this time.';

  @override
  String cardOf(int round, int total) {
    return 'Card $round of $total';
  }

  @override
  String resultsWinner(String name) {
    return '$name wins!';
  }

  @override
  String resultsTie(String names) {
    return 'It\'s a tie: $names';
  }

  @override
  String get resultsNoWinner => 'No points this time';

  @override
  String resultsPoints(int points) {
    return '$points pts';
  }

  @override
  String resultsCorrectOf(int correct, int answered) {
    return '$correct of $answered correct';
  }

  @override
  String resultsSolvedOf(int solved, int played) {
    return '$solved of $played guessed';
  }

  @override
  String get partyTitle => 'Custom Party Pack';

  @override
  String get partyGames => 'Games';

  @override
  String get partyRounds => 'Rounds per game';

  @override
  String get partyStart => 'Start party';

  @override
  String partyNext(String mode) {
    return 'Next: $mode';
  }

  @override
  String get partyFinish => 'Finish party';

  @override
  String partyProgress(int n, int total) {
    return 'Party game $n of $total';
  }

  @override
  String get partyNeedTwo => 'Pick at least two games.';

  @override
  String partyLabel(int count) {
    return 'Party pack · $count games';
  }

  @override
  String get homeFavourites => 'Favourites';

  @override
  String get homeRecent => 'Play again';

  @override
  String homeRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get homeAllModes => 'Choose a game';

  @override
  String get shareBroken => 'This game link is broken or out of date.';

  @override
  String get premiumTitle => 'MirthMix Premium';

  @override
  String get premiumPitch => 'Unlock every premium category in every game. Free play never needs a subscription.';

  @override
  String get premiumIncludes => 'Premium categories';

  @override
  String get premiumActive => 'Premium is on';

  @override
  String premiumPaidThrough(String date) {
    return 'Paid through $date.';
  }

  @override
  String premiumEndsOn(String date) {
    return 'Ends on $date. You won’t be charged again.';
  }

  @override
  String premiumOffline(String date) {
    return 'You’re offline. Premium stays on until $date.';
  }

  @override
  String get premiumUnavailableBuild => 'Premium isn’t available in this version of the app yet.';

  @override
  String get premiumUnavailableNow => 'Premium purchases aren’t available right now. Please try again later.';

  @override
  String get premiumSignInPrompt =>
      'Sign in with your email to buy Premium or restore it on this phone. Guests never need an account.';

  @override
  String get premiumSignIn => 'Sign in to continue';

  @override
  String premiumPerMonth(String price) {
    return '$price per month';
  }

  @override
  String premiumPerYear(String price) {
    return '$price per year';
  }

  @override
  String get premiumRestore => 'Restore purchases';

  @override
  String get premiumManagePlay => 'Manage in Google Play';

  @override
  String get premiumManageWeb => 'You subscribed on the website. Manage your subscription there.';

  @override
  String get premiumPending => 'Waiting for Google Play to confirm the payment…';

  @override
  String get premiumVerifying => 'Confirming your purchase…';

  @override
  String get premiumSuccess => 'Premium is unlocked. Enjoy!';

  @override
  String get premiumDuplicate => 'You also have a subscription on the website. Cancel one so you aren’t charged twice.';

  @override
  String get premiumErrorStore => 'Google Play billing isn’t available on this device.';

  @override
  String get premiumErrorPurchase => 'The purchase didn’t go through. You haven’t been charged.';

  @override
  String get premiumErrorMismatch =>
      'This purchase belongs to a different MirthMix account. Sign in with that account to use it.';

  @override
  String get premiumErrorVerify =>
      'We couldn’t confirm the purchase yet. We’ll try again the next time you open the app.';

  @override
  String get premiumErrorNetwork => 'We couldn’t reach the server. Check your connection and try again.';

  @override
  String get premiumSee => 'See Premium';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInBody => 'We’ll email you a 6-digit code. No password needed.';

  @override
  String get signInEmail => 'Email';

  @override
  String get signInSendCode => 'Send code';

  @override
  String get signInCode => '6-digit code';

  @override
  String get signInVerify => 'Sign in';

  @override
  String signInCodeSent(String email) {
    return 'We sent a code to $email.';
  }

  @override
  String get signInChangeEmail => 'Use a different email';

  @override
  String get signInBadEmail => 'Enter a valid email address.';

  @override
  String get signInErrorCode => 'That code is wrong or has expired.';

  @override
  String get signInErrorRate => 'Too many attempts. Please wait a few minutes.';

  @override
  String get signInErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get accountTitle => 'Account';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteBody =>
      'This permanently deletes your MirthMix account. It doesn’t cancel a Google Play subscription, so cancel that in Google Play first. Type DELETE to confirm.';

  @override
  String get accountDeleteConfirm => 'Delete';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get accountDeleteFailed => 'We couldn’t delete your account. Please try again.';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get signInAdult => 'I’m 18 or older';

  @override
  String get signInAdultRequired =>
      'Accounts and purchases are for people aged 18 or over. You can keep playing everything free without an account.';

  @override
  String get settingsShareUsage => 'Share anonymous usage stats';

  @override
  String get settingsShareUsageBody =>
      'Which games are played, how far you get, and crash reports, to help improve MirthMix. Never names, questions, answers or your email. Off unless you turn it on.';

  @override
  String get myQuestionsTitle => 'My questions';

  @override
  String get myQuestionsIntro =>
      'Write your own questions for Would You Rather and This or That. They stay on this phone and are never shared.';

  @override
  String get myQuestionsHowTo => 'To play them, tick “My questions” when you set up the game.';

  @override
  String get myQuestionsEmpty => 'No questions yet. Tap “Add question” to write one.';

  @override
  String get myQuestionsAdd => 'Add question';

  @override
  String get myQuestionsEdit => 'Edit question';

  @override
  String get myQuestionsOptionA => 'First option';

  @override
  String get myQuestionsOptionB => 'Second option';

  @override
  String get myQuestionsDelete => 'Delete question';

  @override
  String get myQuestionsDeleted => 'Question deleted';

  @override
  String get myQuestionsErrorEmpty => 'Fill in both options.';

  @override
  String myQuestionsErrorTooLong(int max) {
    return 'Keep each option to $max characters or fewer.';
  }

  @override
  String get myQuestionsErrorSame => 'The two options need to be different.';

  @override
  String get myQuestionsErrorDuplicate => 'You already have this question.';

  @override
  String get myQuestionsErrorNotAllowed => 'That has a word we don’t allow. Keep it friendly for everyone.';

  @override
  String myQuestionsErrorFull(int max) {
    return 'You’ve reached $max questions. Delete some to add more.';
  }

  @override
  String get setupWriteOwn => 'Write your own questions';
}
