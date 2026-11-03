import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MirthMix'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Party games for one phone'**
  String get tagline;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Party games for one phone'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Quick games for friends, couples and families sitting together. No setup, no app for everyone.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Read it out. Vote together.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'One person reads, everyone answers. Pass the phone around or let a host keep score.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'No sign-up. Just play.'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Start a game in seconds. Nothing you play leaves your phone.'**
  String get onboarding3Body;

  /// No description provided for @onboardingAge.
  ///
  /// In en, this message translates to:
  /// **'MirthMix is made for ages 13 and up.'**
  String get onboardingAge;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready to play?'**
  String get homeGreeting;

  /// No description provided for @homeQuickPlay.
  ///
  /// In en, this message translates to:
  /// **'Quick play'**
  String get homeQuickPlay;

  /// No description provided for @homeQuickPlayBody.
  ///
  /// In en, this message translates to:
  /// **'10 rounds of Would You Rather, mixed free categories.'**
  String get homeQuickPlayBody;

  /// No description provided for @homeResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Game in progress'**
  String get homeResumeTitle;

  /// No description provided for @homeResumeBody.
  ///
  /// In en, this message translates to:
  /// **'{mode} · round {round} of {total}'**
  String homeResumeBody(String mode, int round, int total);

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// No description provided for @homeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get homeDiscard;

  /// No description provided for @homeAllGames.
  ///
  /// In en, this message translates to:
  /// **'All games'**
  String get homeAllGames;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get libraryTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @modeWyrName.
  ///
  /// In en, this message translates to:
  /// **'Would You Rather'**
  String get modeWyrName;

  /// No description provided for @modeWyrBlurb.
  ///
  /// In en, this message translates to:
  /// **'Two choices. Everyone picks a side.'**
  String get modeWyrBlurb;

  /// No description provided for @modeWyrRules.
  ///
  /// In en, this message translates to:
  /// **'Read both options aloud. Everyone raises a hand for their pick, then tap each side once per vote. Reveal to see how the room split.'**
  String get modeWyrRules;

  /// No description provided for @modeTotName.
  ///
  /// In en, this message translates to:
  /// **'This or That'**
  String get modeTotName;

  /// No description provided for @modeTotBlurb.
  ///
  /// In en, this message translates to:
  /// **'Rapid-fire picks with big buttons.'**
  String get modeTotBlurb;

  /// No description provided for @modeTriviaName.
  ///
  /// In en, this message translates to:
  /// **'Trivia Blitz'**
  String get modeTriviaName;

  /// No description provided for @modeTriviaBlurb.
  ///
  /// In en, this message translates to:
  /// **'Beat the timer, top the table.'**
  String get modeTriviaBlurb;

  /// No description provided for @modeGuessName.
  ///
  /// In en, this message translates to:
  /// **'Guess the Answer'**
  String get modeGuessName;

  /// No description provided for @modeGuessBlurb.
  ///
  /// In en, this message translates to:
  /// **'Fewer clues, more points.'**
  String get modeGuessBlurb;

  /// No description provided for @modeCustomName.
  ///
  /// In en, this message translates to:
  /// **'Custom Party Pack'**
  String get modeCustomName;

  /// No description provided for @modeCustomBlurb.
  ///
  /// In en, this message translates to:
  /// **'Mix modes into one session.'**
  String get modeCustomBlurb;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up the game'**
  String get setupTitle;

  /// No description provided for @setupHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get setupHowToPlay;

  /// No description provided for @setupCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get setupCategories;

  /// No description provided for @setupCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one.'**
  String get setupCategoriesHint;

  /// No description provided for @setupRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get setupRounds;

  /// No description provided for @setupGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Group size'**
  String get setupGroupSize;

  /// No description provided for @setupGroupSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Limits votes per round to the number of players.'**
  String get setupGroupSizeHint;

  /// No description provided for @setupGroupSizeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get setupGroupSizeAny;

  /// No description provided for @setupGroupSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String setupGroupSizeValue(int count);

  /// No description provided for @setupPlayersDecrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer players'**
  String get setupPlayersDecrease;

  /// No description provided for @setupPlayersIncrease.
  ///
  /// In en, this message translates to:
  /// **'More players'**
  String get setupPlayersIncrease;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get setupStart;

  /// No description provided for @setupQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String setupQuestionsAvailable(int count);

  /// No description provided for @setupFewerQuestions.
  ///
  /// In en, this message translates to:
  /// **'Only {count} questions in these categories, so you\'ll play {count} rounds.'**
  String setupFewerQuestions(int count);

  /// No description provided for @premiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumLabel;

  /// No description provided for @premiumLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Premium.'**
  String get premiumLocked;

  /// No description provided for @regionIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get regionIndia;

  /// No description provided for @ageTeen.
  ///
  /// In en, this message translates to:
  /// **'13+'**
  String get ageTeen;

  /// No description provided for @playRound.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of {total}'**
  String playRound(int round, int total);

  /// No description provided for @playPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you rather…'**
  String get playPrompt;

  /// No description provided for @playOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get playOr;

  /// No description provided for @playHint.
  ///
  /// In en, this message translates to:
  /// **'Raise hands, then tap a side once for each vote.'**
  String get playHint;

  /// No description provided for @playVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No votes} =1{1 vote} other{{count} votes}}'**
  String playVotes(int count);

  /// No description provided for @playVotesOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count} of {players} votes'**
  String playVotesOfPlayers(int count, int players);

  /// No description provided for @playVoteFor.
  ///
  /// In en, this message translates to:
  /// **'Add a vote for: {option}'**
  String playVoteFor(String option);

  /// No description provided for @playUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get playUndo;

  /// No description provided for @playSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get playSkip;

  /// No description provided for @playSkipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skip this question'**
  String get playSkipTooltip;

  /// No description provided for @playReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get playReveal;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get playNext;

  /// No description provided for @playFinish.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get playFinish;

  /// No description provided for @playQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit game'**
  String get playQuit;

  /// No description provided for @playQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit this game?'**
  String get playQuitTitle;

  /// No description provided for @playQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this game will be lost.'**
  String get playQuitBody;

  /// No description provided for @playQuitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get playQuitConfirm;

  /// No description provided for @playKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get playKeepPlaying;

  /// No description provided for @playSplit.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String playSplit(int percent);

  /// No description provided for @playTie.
  ///
  /// In en, this message translates to:
  /// **'Perfect split!'**
  String get playTie;

  /// No description provided for @playUnanimous.
  ///
  /// In en, this message translates to:
  /// **'Everyone agrees!'**
  String get playUnanimous;

  /// No description provided for @playNoVotes.
  ///
  /// In en, this message translates to:
  /// **'No votes this round.'**
  String get playNoVotes;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @resultsSummary.
  ///
  /// In en, this message translates to:
  /// **'{rounds, plural, =1{1 round} other{{rounds} rounds}} · {votes, plural, =1{1 vote} other{{votes} votes}}'**
  String resultsSummary(int rounds, int votes);

  /// No description provided for @resultsDivisive.
  ///
  /// In en, this message translates to:
  /// **'Most divisive'**
  String get resultsDivisive;

  /// No description provided for @resultsUnanimous.
  ///
  /// In en, this message translates to:
  /// **'Most unanimous'**
  String get resultsUnanimous;

  /// No description provided for @resultsAllRounds.
  ///
  /// In en, this message translates to:
  /// **'Every round'**
  String get resultsAllRounds;

  /// No description provided for @resultsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get resultsSkipped;

  /// No description provided for @resultsPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get resultsPlayAgain;

  /// No description provided for @resultsChangeSetup.
  ///
  /// In en, this message translates to:
  /// **'Change setup'**
  String get resultsChangeSetup;

  /// No description provided for @resultsHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get resultsHome;

  /// No description provided for @resultsSplit.
  ///
  /// In en, this message translates to:
  /// **'{a} – {b}'**
  String resultsSplit(int a, int b);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get settingsPlay;

  /// No description provided for @settingsBigText.
  ///
  /// In en, this message translates to:
  /// **'Big text'**
  String get settingsBigText;

  /// No description provided for @settingsBigTextBody.
  ///
  /// In en, this message translates to:
  /// **'Larger questions for reading across the room.'**
  String get settingsBigTextBody;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionBody.
  ///
  /// In en, this message translates to:
  /// **'Turn off animations. Your system setting is always respected.'**
  String get settingsReduceMotionBody;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsBody.
  ///
  /// In en, this message translates to:
  /// **'A small buzz when you tap a vote.'**
  String get settingsHapticsBody;

  /// No description provided for @settingsShowOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get settingsShowOnboarding;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'You can play without an account. An account is only for buying Premium: it stores your email and subscription status on the MirthMix server. Games, settings and players are stored only on this phone.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsAge.
  ///
  /// In en, this message translates to:
  /// **'Age guidance'**
  String get settingsAge;

  /// No description provided for @settingsAgeBody.
  ///
  /// In en, this message translates to:
  /// **'MirthMix is made for ages 13 and up. Categories marked 13+ include more mature themes, never explicit content.'**
  String get settingsAgeBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @errorContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Games couldn\'t load'**
  String get errorContentTitle;

  /// No description provided for @errorContentBody.
  ///
  /// In en, this message translates to:
  /// **'The game content on this phone looks damaged. Reinstalling the app usually fixes this.'**
  String get errorContentBody;

  /// No description provided for @errorEmptyCategories.
  ///
  /// In en, this message translates to:
  /// **'No questions are available for the selected categories.'**
  String get errorEmptyCategories;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That page doesn\'t exist.'**
  String get errorNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @modeTotRules.
  ///
  /// In en, this message translates to:
  /// **'Two quick options. Tap the room\'s pick, or pass the phone so everyone picks in turn. Add the timer for real rapid fire.'**
  String get modeTotRules;

  /// No description provided for @modeTriviaRules.
  ///
  /// In en, this message translates to:
  /// **'Teams take turns answering. Faster correct answers score bonus points. Every question has a short explanation.'**
  String get modeTriviaRules;

  /// No description provided for @modeGuessRules.
  ///
  /// In en, this message translates to:
  /// **'Only the reader looks at the screen. Read clue 1 aloud; if nobody gets it, read the next. Fewer clues, more points.'**
  String get modeGuessRules;

  /// No description provided for @modeCustomRules.
  ///
  /// In en, this message translates to:
  /// **'Pick the games to play in order. When one ends, the next starts with a tap.'**
  String get modeCustomRules;

  /// No description provided for @setupPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players and teams'**
  String get setupPlayers;

  /// No description provided for @setupPlayersNone.
  ///
  /// In en, this message translates to:
  /// **'Playing as one group'**
  String get setupPlayersNone;

  /// No description provided for @setupPlayersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get setupPlayersEdit;

  /// No description provided for @setupPassPhone.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone'**
  String get setupPassPhone;

  /// No description provided for @setupPassPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Each player picks in turn. Needs at least 2 players.'**
  String get setupPassPhoneBody;

  /// No description provided for @setupTimer.
  ///
  /// In en, this message translates to:
  /// **'5-second timer'**
  String get setupTimer;

  /// No description provided for @setupTimerBody.
  ///
  /// In en, this message translates to:
  /// **'Pick before time runs out.'**
  String get setupTimerBody;

  /// No description provided for @setupTriviaTimer.
  ///
  /// In en, this message translates to:
  /// **'Time per question'**
  String get setupTriviaTimer;

  /// No description provided for @setupTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get setupTimerOff;

  /// No description provided for @setupSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String setupSeconds(int seconds);

  /// No description provided for @setupSaveFavourite.
  ///
  /// In en, this message translates to:
  /// **'Save as favourite'**
  String get setupSaveFavourite;

  /// No description provided for @favouriteName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get favouriteName;

  /// No description provided for @favouriteSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to favourites'**
  String get favouriteSaved;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @playersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players and teams'**
  String get playersTitle;

  /// No description provided for @playersBody.
  ///
  /// In en, this message translates to:
  /// **'Add names to take turns and keep score. Names stay on this phone. Leave it empty to play as one group.'**
  String get playersBody;

  /// No description provided for @playersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get playersAdd;

  /// No description provided for @playersName.
  ///
  /// In en, this message translates to:
  /// **'Player or team name'**
  String get playersName;

  /// No description provided for @playersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String playersRemove(String name);

  /// No description provided for @playersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get playersClear;

  /// No description provided for @playersFull.
  ///
  /// In en, this message translates to:
  /// **'That\'s the maximum of {max}.'**
  String playersFull(int max);

  /// No description provided for @totPrompt.
  ///
  /// In en, this message translates to:
  /// **'This or that?'**
  String get totPrompt;

  /// No description provided for @totPickFor.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s pick'**
  String totPickFor(String name);

  /// No description provided for @totGroupPick.
  ///
  /// In en, this message translates to:
  /// **'Tap the room\'s pick'**
  String get totGroupPick;

  /// No description provided for @totTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get totTimeUp;

  /// No description provided for @totDiscuss1.
  ///
  /// In en, this message translates to:
  /// **'Defend your pick in 10 seconds.'**
  String get totDiscuss1;

  /// No description provided for @totDiscuss2.
  ///
  /// In en, this message translates to:
  /// **'Anyone want to switch sides?'**
  String get totDiscuss2;

  /// No description provided for @totDiscuss3.
  ///
  /// In en, this message translates to:
  /// **'Who surprised you?'**
  String get totDiscuss3;

  /// No description provided for @totInSync.
  ///
  /// In en, this message translates to:
  /// **'Most in sync: {a} & {b}'**
  String totInSync(String a, String b);

  /// No description provided for @totInSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Same pick {matches} of {rounds} times'**
  String totInSyncBody(int matches, int rounds);

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds left'**
  String secondsLeft(int seconds);

  /// No description provided for @turnOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String turnOf(String name);

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {round} of {total}'**
  String questionOf(int round, int total);

  /// No description provided for @triviaCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points}'**
  String triviaCorrect(int points);

  /// No description provided for @triviaWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite.'**
  String get triviaWrong;

  /// No description provided for @triviaTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get triviaTimeUp;

  /// No description provided for @triviaAnswerWas.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String triviaAnswerWas(String answer);

  /// No description provided for @triviaChoice.
  ///
  /// In en, this message translates to:
  /// **'Answer {letter}: {text}'**
  String triviaChoice(String letter, String text);

  /// No description provided for @guessReaderOnly.
  ///
  /// In en, this message translates to:
  /// **'Reader only — the answer is'**
  String get guessReaderOnly;

  /// No description provided for @guessClue.
  ///
  /// In en, this message translates to:
  /// **'Clue {n}'**
  String guessClue(int n);

  /// No description provided for @guessNextClue.
  ///
  /// In en, this message translates to:
  /// **'Next clue'**
  String get guessNextClue;

  /// No description provided for @guessGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get guessGotIt;

  /// No description provided for @guessGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get guessGiveUp;

  /// No description provided for @guessWorth.
  ///
  /// In en, this message translates to:
  /// **'Worth {points} points'**
  String guessWorth(int points);

  /// No description provided for @guessGuessing.
  ///
  /// In en, this message translates to:
  /// **'{name} guesses'**
  String guessGuessing(String name);

  /// No description provided for @guessScored.
  ///
  /// In en, this message translates to:
  /// **'+{points} for {name}'**
  String guessScored(int points, String name);

  /// No description provided for @guessNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No points this time.'**
  String get guessNoPoints;

  /// No description provided for @cardOf.
  ///
  /// In en, this message translates to:
  /// **'Card {round} of {total}'**
  String cardOf(int round, int total);

  /// No description provided for @resultsWinner.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String resultsWinner(String name);

  /// No description provided for @resultsTie.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie: {names}'**
  String resultsTie(String names);

  /// No description provided for @resultsNoWinner.
  ///
  /// In en, this message translates to:
  /// **'No points this time'**
  String get resultsNoWinner;

  /// No description provided for @resultsPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String resultsPoints(int points);

  /// No description provided for @resultsCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {answered} correct'**
  String resultsCorrectOf(int correct, int answered);

  /// No description provided for @resultsSolvedOf.
  ///
  /// In en, this message translates to:
  /// **'{solved} of {played} guessed'**
  String resultsSolvedOf(int solved, int played);

  /// No description provided for @partyTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Party Pack'**
  String get partyTitle;

  /// No description provided for @partyGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get partyGames;

  /// No description provided for @partyRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds per game'**
  String get partyRounds;

  /// No description provided for @partyStart.
  ///
  /// In en, this message translates to:
  /// **'Start party'**
  String get partyStart;

  /// No description provided for @partyNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {mode}'**
  String partyNext(String mode);

  /// No description provided for @partyFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish party'**
  String get partyFinish;

  /// No description provided for @partyProgress.
  ///
  /// In en, this message translates to:
  /// **'Party game {n} of {total}'**
  String partyProgress(int n, int total);

  /// No description provided for @partyNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Pick at least two games.'**
  String get partyNeedTwo;

  /// No description provided for @partyLabel.
  ///
  /// In en, this message translates to:
  /// **'Party pack · {count} games'**
  String partyLabel(int count);

  /// No description provided for @homeFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get homeFavourites;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get homeRecent;

  /// No description provided for @homeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String homeRemove(String name);

  /// No description provided for @homeAllModes.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get homeAllModes;

  /// No description provided for @shareBroken.
  ///
  /// In en, this message translates to:
  /// **'This game link is broken or out of date.'**
  String get shareBroken;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'MirthMix Premium'**
  String get premiumTitle;

  /// No description provided for @premiumPitch.
  ///
  /// In en, this message translates to:
  /// **'Unlock every premium category in every game. Free play never needs a subscription.'**
  String get premiumPitch;

  /// No description provided for @premiumIncludes.
  ///
  /// In en, this message translates to:
  /// **'Premium categories'**
  String get premiumIncludes;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is on'**
  String get premiumActive;

  /// No description provided for @premiumPaidThrough.
  ///
  /// In en, this message translates to:
  /// **'Paid through {date}.'**
  String premiumPaidThrough(String date);

  /// No description provided for @premiumEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}. You won’t be charged again.'**
  String premiumEndsOn(String date);

  /// No description provided for @premiumOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Premium stays on until {date}.'**
  String premiumOffline(String date);

  /// No description provided for @premiumUnavailableBuild.
  ///
  /// In en, this message translates to:
  /// **'Premium isn’t available in this version of the app yet.'**
  String get premiumUnavailableBuild;

  /// No description provided for @premiumUnavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Premium purchases aren’t available right now. Please try again later.'**
  String get premiumUnavailableNow;

  /// No description provided for @premiumSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email to buy Premium or restore it on this phone. Guests never need an account.'**
  String get premiumSignInPrompt;

  /// No description provided for @premiumSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get premiumSignIn;

  /// No description provided for @premiumPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} per month'**
  String premiumPerMonth(String price);

  /// No description provided for @premiumPerYear.
  ///
  /// In en, this message translates to:
  /// **'{price} per year'**
  String premiumPerYear(String price);

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get premiumRestore;

  /// No description provided for @premiumManagePlay.
  ///
  /// In en, this message translates to:
  /// **'Manage in Google Play'**
  String get premiumManagePlay;

  /// No description provided for @premiumManageWeb.
  ///
  /// In en, this message translates to:
  /// **'You subscribed on the website. Manage your subscription there.'**
  String get premiumManageWeb;

  /// No description provided for @premiumPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Google Play to confirm the payment…'**
  String get premiumPending;

  /// No description provided for @premiumVerifying.
  ///
  /// In en, this message translates to:
  /// **'Confirming your purchase…'**
  String get premiumVerifying;

  /// No description provided for @premiumSuccess.
  ///
  /// In en, this message translates to:
  /// **'Premium is unlocked. Enjoy!'**
  String get premiumSuccess;

  /// No description provided for @premiumDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You also have a subscription on the website. Cancel one so you aren’t charged twice.'**
  String get premiumDuplicate;

  /// No description provided for @premiumErrorStore.
  ///
  /// In en, this message translates to:
  /// **'Google Play billing isn’t available on this device.'**
  String get premiumErrorStore;

  /// No description provided for @premiumErrorPurchase.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn’t go through. You haven’t been charged.'**
  String get premiumErrorPurchase;

  /// No description provided for @premiumErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'This purchase belongs to a different MirthMix account. Sign in with that account to use it.'**
  String get premiumErrorMismatch;

  /// No description provided for @premiumErrorVerify.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm the purchase yet. We’ll try again the next time you open the app.'**
  String get premiumErrorVerify;

  /// No description provided for @premiumErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach the server. Check your connection and try again.'**
  String get premiumErrorNetwork;

  /// No description provided for @premiumSee.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get premiumSee;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll email you a 6-digit code. No password needed.'**
  String get signInBody;

  /// No description provided for @signInEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmail;

  /// No description provided for @signInSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get signInSendCode;

  /// No description provided for @signInCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get signInCode;

  /// No description provided for @signInVerify.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInVerify;

  /// No description provided for @signInCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}.'**
  String signInCodeSent(String email);

  /// No description provided for @signInChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get signInChangeEmail;

  /// No description provided for @signInBadEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get signInBadEmail;

  /// No description provided for @signInErrorCode.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired.'**
  String get signInErrorCode;

  /// No description provided for @signInErrorRate.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes.'**
  String get signInErrorRate;

  /// No description provided for @signInErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get signInErrorUnknown;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your MirthMix account. It doesn’t cancel a Google Play subscription, so cancel that in Google Play first. Type DELETE to confirm.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountDeleteConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t delete your account. Please try again.'**
  String get accountDeleteFailed;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @signInAdult.
  ///
  /// In en, this message translates to:
  /// **'I’m 18 or older'**
  String get signInAdult;

  /// No description provided for @signInAdultRequired.
  ///
  /// In en, this message translates to:
  /// **'Accounts and purchases are for people aged 18 or over. You can keep playing everything free without an account.'**
  String get signInAdultRequired;

  /// No description provided for @settingsShareUsage.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage stats'**
  String get settingsShareUsage;

  /// No description provided for @settingsShareUsageBody.
  ///
  /// In en, this message translates to:
  /// **'Which games are played, how far you get, and crash reports, to help improve MirthMix. Never names, questions, answers or your email. Off unless you turn it on.'**
  String get settingsShareUsageBody;

  /// No description provided for @myQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My questions'**
  String get myQuestionsTitle;

  /// No description provided for @myQuestionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Write your own questions for Would You Rather and This or That. They stay on this phone and are never shared.'**
  String get myQuestionsIntro;

  /// No description provided for @myQuestionsHowTo.
  ///
  /// In en, this message translates to:
  /// **'To play them, tick “My questions” when you set up the game.'**
  String get myQuestionsHowTo;

  /// No description provided for @myQuestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Tap “Add question” to write one.'**
  String get myQuestionsEmpty;

  /// No description provided for @myQuestionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get myQuestionsAdd;

  /// No description provided for @myQuestionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit question'**
  String get myQuestionsEdit;

  /// No description provided for @myQuestionsOptionA.
  ///
  /// In en, this message translates to:
  /// **'First option'**
  String get myQuestionsOptionA;

  /// No description provided for @myQuestionsOptionB.
  ///
  /// In en, this message translates to:
  /// **'Second option'**
  String get myQuestionsOptionB;

  /// No description provided for @myQuestionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete question'**
  String get myQuestionsDelete;

  /// No description provided for @myQuestionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Question deleted'**
  String get myQuestionsDeleted;

  /// No description provided for @myQuestionsErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fill in both options.'**
  String get myQuestionsErrorEmpty;

  /// No description provided for @myQuestionsErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep each option to {max} characters or fewer.'**
  String myQuestionsErrorTooLong(int max);

  /// No description provided for @myQuestionsErrorSame.
  ///
  /// In en, this message translates to:
  /// **'The two options need to be different.'**
  String get myQuestionsErrorSame;

  /// No description provided for @myQuestionsErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have this question.'**
  String get myQuestionsErrorDuplicate;

  /// No description provided for @myQuestionsErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That has a word we don’t allow. Keep it friendly for everyone.'**
  String get myQuestionsErrorNotAllowed;

  /// No description provided for @myQuestionsErrorFull.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached {max} questions. Delete some to add more.'**
  String myQuestionsErrorFull(int max);

  /// No description provided for @setupWriteOwn.
  ///
  /// In en, this message translates to:
  /// **'Write your own questions'**
  String get setupWriteOwn;

  /// No description provided for @usagePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Help make MirthMix better?'**
  String get usagePromptTitle;

  /// No description provided for @usagePromptYes.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous stats'**
  String get usagePromptYes;

  /// No description provided for @usagePromptNo.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get usagePromptNo;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
