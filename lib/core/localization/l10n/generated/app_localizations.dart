import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start Call'**
  String get startCall;

  /// No description provided for @waitingForRemoteVideo.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Remote Video'**
  String get waitingForRemoteVideo;

  /// No description provided for @yourVideo.
  ///
  /// In en, this message translates to:
  /// **'Your Video Preview'**
  String get yourVideo;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter valid email'**
  String get enterValidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Password must contain both letters and numbers and be at least 6 characters long'**
  String get passwordValidationMessage;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget your password?'**
  String get forgetPassword;

  /// No description provided for @signin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signin;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get unknown;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @assign_debate_sides.
  ///
  /// In en, this message translates to:
  /// **'Assign Debate Sides'**
  String get assign_debate_sides;

  /// No description provided for @select_debate_motion.
  ///
  /// In en, this message translates to:
  /// **'Select Debate Motion'**
  String get select_debate_motion;

  /// No description provided for @search_motion.
  ///
  /// In en, this message translates to:
  /// **'Search Motion'**
  String get search_motion;

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Debate Motion'**
  String get motion;

  /// No description provided for @select_new_motion.
  ///
  /// In en, this message translates to:
  /// **'Select New Motion'**
  String get select_new_motion;

  /// No description provided for @select_topics.
  ///
  /// In en, this message translates to:
  /// **'Select the motion topics (2 maximum)'**
  String get select_topics;

  /// No description provided for @motion_topics.
  ///
  /// In en, this message translates to:
  /// **'Motion Topics: '**
  String get motion_topics;

  /// No description provided for @filter_motion.
  ///
  /// In en, this message translates to:
  /// **'Filter Motions'**
  String get filter_motion;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED'**
  String get protected;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'POI ALLOWED'**
  String get open;

  /// No description provided for @time_over.
  ///
  /// In en, this message translates to:
  /// **'TIME OVER'**
  String get time_over;

  /// No description provided for @available_rooms.
  ///
  /// In en, this message translates to:
  /// **'Available Rooms'**
  String get available_rooms;

  /// No description provided for @no_available_rooms.
  ///
  /// In en, this message translates to:
  /// **'No available rooms'**
  String get no_available_rooms;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jadal'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Where word meets technology'**
  String get appSlogan;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordButton;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @emailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailEmpty;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @permissionsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions required'**
  String get permissionsRequiredTitle;

  /// No description provided for @permissionsRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Jadal needs camera, microphone, and Bluetooth access to work properly during live debates.'**
  String get permissionsRequiredBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionMicrophone;

  /// No description provided for @permissionBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get permissionBluetooth;

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Debate Rooms'**
  String get lobbyTitle;

  /// No description provided for @proposition.
  ///
  /// In en, this message translates to:
  /// **'Proposition'**
  String get proposition;

  /// No description provided for @opposition.
  ///
  /// In en, this message translates to:
  /// **'Opposition'**
  String get opposition;

  /// No description provided for @liveDebateRoom.
  ///
  /// In en, this message translates to:
  /// **'Live Debate'**
  String get liveDebateRoom;

  /// No description provided for @resultRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultRoomTitle;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @onlyTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team members only'**
  String get onlyTeamMembers;

  /// No description provided for @prepClosed.
  ///
  /// In en, this message translates to:
  /// **'Preparation closed'**
  String get prepClosed;

  /// No description provided for @orderNotSet.
  ///
  /// In en, this message translates to:
  /// **'Speaker order not set'**
  String get orderNotSet;

  /// No description provided for @orderSet.
  ///
  /// In en, this message translates to:
  /// **'Speaker order set'**
  String get orderSet;

  /// No description provided for @resultsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Results not ready yet'**
  String get resultsNotReady;

  /// No description provided for @resultsNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'The result room opens once the chair marks the debate as finished.'**
  String get resultsNotReadyBody;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @needOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the speaker order first'**
  String get needOrderTitle;

  /// No description provided for @needOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Go to your team\'s preparation room and select the speaker order before joining the live debate.'**
  String get needOrderBody;

  /// No description provided for @goToPrep.
  ///
  /// In en, this message translates to:
  /// **'Go to prep room'**
  String get goToPrep;

  /// No description provided for @joiningAsAudience.
  ///
  /// In en, this message translates to:
  /// **'Joining as audience'**
  String get joiningAsAudience;

  /// No description provided for @prepRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get prepRoomTitle;

  /// No description provided for @prepEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Prep ends in'**
  String get prepEndsIn;

  /// No description provided for @selectSpeakerOrder.
  ///
  /// In en, this message translates to:
  /// **'Select speaker order'**
  String get selectSpeakerOrder;

  /// No description provided for @updateSpeakerOrder.
  ///
  /// In en, this message translates to:
  /// **'Update speaker order'**
  String get updateSpeakerOrder;

  /// No description provided for @leaderHint.
  ///
  /// In en, this message translates to:
  /// **'You are the current leader — set the speaking order.'**
  String get leaderHint;

  /// No description provided for @notLeaderHint.
  ///
  /// In en, this message translates to:
  /// **'Speaking order is set by'**
  String get notLeaderHint;

  /// No description provided for @speakerOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaker Order'**
  String get speakerOrderTitle;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder the speakers (1st, 2nd, 3rd).'**
  String get dragToReorder;

  /// No description provided for @replySpeaker.
  ///
  /// In en, this message translates to:
  /// **'Reply speaker (1st or 2nd only)'**
  String get replySpeaker;

  /// No description provided for @saveOrder.
  ///
  /// In en, this message translates to:
  /// **'Save order'**
  String get saveOrder;

  /// No description provided for @tapNextToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Next to start the debate.'**
  String get tapNextToStart;

  /// No description provided for @extraTime.
  ///
  /// In en, this message translates to:
  /// **'EXTRA TIME'**
  String get extraTime;

  /// No description provided for @nowSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Now speaking'**
  String get nowSpeaking;

  /// No description provided for @debateFinished.
  ///
  /// In en, this message translates to:
  /// **'The debate has finished.'**
  String get debateFinished;

  /// No description provided for @backToDebate.
  ///
  /// In en, this message translates to:
  /// **'Back to debate'**
  String get backToDebate;

  /// No description provided for @newsPoisOpen.
  ///
  /// In en, this message translates to:
  /// **'POIs are now open.'**
  String get newsPoisOpen;

  /// No description provided for @newsLastChance.
  ///
  /// In en, this message translates to:
  /// **'One minute until POIs close — last chance to ask.'**
  String get newsLastChance;

  /// No description provided for @newsPoisClosed.
  ///
  /// In en, this message translates to:
  /// **'Protected period — POIs are now closed.'**
  String get newsPoisClosed;

  /// No description provided for @newsMainEnded.
  ///
  /// In en, this message translates to:
  /// **'Main speaking time has ended — extra time begins.'**
  String get newsMainEnded;

  /// No description provided for @newsExtraEnded.
  ///
  /// In en, this message translates to:
  /// **'Time off — nothing is being recorded now.'**
  String get newsExtraEnded;

  /// No description provided for @newEventHappened.
  ///
  /// In en, this message translates to:
  /// **'New event happened'**
  String get newEventHappened;

  /// No description provided for @debateNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The debate hasn\'t started yet.'**
  String get debateNotStarted;

  /// No description provided for @youJoinedLiveSession.
  ///
  /// In en, this message translates to:
  /// **'You\'ve joined the live session.'**
  String get youJoinedLiveSession;

  /// No description provided for @goLiveSession.
  ///
  /// In en, this message translates to:
  /// **'Go to live session'**
  String get goLiveSession;

  /// No description provided for @introductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Introductions'**
  String get introductionsLabel;

  /// No description provided for @poiAcceptedNews.
  ///
  /// In en, this message translates to:
  /// **'Your POI was accepted'**
  String get poiAcceptedNews;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @poiTitle.
  ///
  /// In en, this message translates to:
  /// **'Point of Information'**
  String get poiTitle;

  /// No description provided for @poiPrompt.
  ///
  /// In en, this message translates to:
  /// **'A debater is requesting a POI. Accept or refuse?'**
  String get poiPrompt;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @poiYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your POI was accepted'**
  String get poiYourTurn;

  /// No description provided for @poiSpeakNow.
  ///
  /// In en, this message translates to:
  /// **'Open your mic and make your point, then tap Done.'**
  String get poiSpeakNow;

  /// No description provided for @poiDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get poiDone;

  /// No description provided for @forceMute.
  ///
  /// In en, this message translates to:
  /// **'Force mute'**
  String get forceMute;

  /// No description provided for @forceCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Force camera off'**
  String get forceCameraOff;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get allowCamera;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to profile'**
  String get goToProfile;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @leaveToProfileWarning.
  ///
  /// In en, this message translates to:
  /// **'This will leave the debate.'**
  String get leaveToProfileWarning;

  /// No description provided for @muteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute all'**
  String get muteAll;

  /// No description provided for @openLobbyMode.
  ///
  /// In en, this message translates to:
  /// **'Open-lobby mode'**
  String get openLobbyMode;

  /// No description provided for @teamChat.
  ///
  /// In en, this message translates to:
  /// **'Team chat'**
  String get teamChat;

  /// No description provided for @leaveDebate.
  ///
  /// In en, this message translates to:
  /// **'Leave debate'**
  String get leaveDebate;

  /// No description provided for @leaveDebateBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the debate?'**
  String get leaveDebateBody;

  /// No description provided for @themeToggleTest.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme (test only)'**
  String get themeToggleTest;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message your team…'**
  String get messageHint;

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get newMessages;

  /// No description provided for @micMutedWhileSpeaking.
  ///
  /// In en, this message translates to:
  /// **'You\'re on — but your mic is off. Unmute to be heard.'**
  String get micMutedWhileSpeaking;

  /// No description provided for @submitResult.
  ///
  /// In en, this message translates to:
  /// **'Submit result'**
  String get submitResult;

  /// No description provided for @submitResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Result'**
  String get submitResultTitle;

  /// No description provided for @submitResultPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter each speaker\'s score, pick the winning side, then submit.'**
  String get submitResultPrompt;

  /// No description provided for @revealResult.
  ///
  /// In en, this message translates to:
  /// **'Reveal result'**
  String get revealResult;

  /// No description provided for @closeMainRoom.
  ///
  /// In en, this message translates to:
  /// **'Close main room'**
  String get closeMainRoom;

  /// No description provided for @closeWithoutResult.
  ///
  /// In en, this message translates to:
  /// **'Close without a result'**
  String get closeWithoutResult;

  /// No description provided for @winningSideLabel.
  ///
  /// In en, this message translates to:
  /// **'Winning side'**
  String get winningSideLabel;

  /// No description provided for @summaryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary notes'**
  String get summaryNotesLabel;

  /// No description provided for @summaryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes about the result (optional)'**
  String get summaryNotesHint;

  /// No description provided for @selectWinningSideFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select the winning side first.'**
  String get selectWinningSideFirst;

  /// No description provided for @resultSubmittedMsg.
  ///
  /// In en, this message translates to:
  /// **'Result submitted'**
  String get resultSubmittedMsg;

  /// No description provided for @resultRevealedMsg.
  ///
  /// In en, this message translates to:
  /// **'Result revealed!'**
  String get resultRevealedMsg;

  /// No description provided for @mainRoomClosedMsg.
  ///
  /// In en, this message translates to:
  /// **'Main room closed'**
  String get mainRoomClosedMsg;

  /// No description provided for @awaitingReveal.
  ///
  /// In en, this message translates to:
  /// **'The result is in — awaiting the chair\'s reveal.'**
  String get awaitingReveal;

  /// No description provided for @resultsPending.
  ///
  /// In en, this message translates to:
  /// **'The chair is finalizing the result…'**
  String get resultsPending;

  /// No description provided for @noResultYet.
  ///
  /// In en, this message translates to:
  /// **'No result submitted yet'**
  String get noResultYet;

  /// No description provided for @winnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winnerLabel;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @bestSpeakerLabel.
  ///
  /// In en, this message translates to:
  /// **'Best speaker'**
  String get bestSpeakerLabel;

  /// No description provided for @perSpeechScores.
  ///
  /// In en, this message translates to:
  /// **'Per-speech scores'**
  String get perSpeechScores;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @debateCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Debate cancelled'**
  String get debateCancelledTitle;

  /// No description provided for @debateCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'The main room was closed without submitting a result.'**
  String get debateCancelledBody;

  /// No description provided for @rateDebate.
  ///
  /// In en, this message translates to:
  /// **'Rate this debate'**
  String get rateDebate;

  /// No description provided for @ratingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get ratingThanks;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about your rating (optional)'**
  String get ratingCommentHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @updateRating.
  ///
  /// In en, this message translates to:
  /// **'Update rating'**
  String get updateRating;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDebates.
  ///
  /// In en, this message translates to:
  /// **'Debates'**
  String get navDebates;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navBlog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get navBlog;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @drawerAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Your analysis'**
  String get drawerAnalysis;

  /// No description provided for @drawerFrameworks.
  ///
  /// In en, this message translates to:
  /// **'Frameworks in the system'**
  String get drawerFrameworks;

  /// No description provided for @drawerSurveys.
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get drawerSurveys;

  /// No description provided for @drawerMyComplaints.
  ///
  /// In en, this message translates to:
  /// **'My Complaints'**
  String get drawerMyComplaints;

  /// No description provided for @drawerTrainerSurveys.
  ///
  /// In en, this message translates to:
  /// **'Trainer Surveys'**
  String get drawerTrainerSurveys;

  /// No description provided for @drawerMyTeams.
  ///
  /// In en, this message translates to:
  /// **'My Teams'**
  String get drawerMyTeams;

  /// No description provided for @drawerJoinTeam.
  ///
  /// In en, this message translates to:
  /// **'Join a Team'**
  String get drawerJoinTeam;

  /// No description provided for @drawerContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get drawerContactUs;

  /// No description provided for @profileStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatistics;

  /// No description provided for @profileTeamAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Team analysis'**
  String get profileTeamAnalysis;

  /// No description provided for @achievementRankGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get achievementRankGold;

  /// No description provided for @achievementRankSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get achievementRankSilver;

  /// No description provided for @achievementRankBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get achievementRankBronze;

  /// No description provided for @achievementRankHonorable.
  ///
  /// In en, this message translates to:
  /// **'Honorable'**
  String get achievementRankHonorable;

  /// No description provided for @achievementRankParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get achievementRankParticipation;

  /// No description provided for @achievementsSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get achievementsSortDate;

  /// No description provided for @achievementsSortRank.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get achievementsSortRank;

  /// No description provided for @editProfileChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose source'**
  String get editProfileChooseSource;

  /// No description provided for @editProfileCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get editProfileCamera;

  /// No description provided for @editProfileGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get editProfileGallery;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhone;

  /// No description provided for @fieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// No description provided for @fieldBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get fieldBirthDate;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @userAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — Achievements'**
  String userAchievementsTitle(String name);

  /// No description provided for @noAchievementsYet.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get noAchievementsYet;

  /// No description provided for @userDebatesTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — Debates'**
  String userDebatesTitle(String name);

  /// No description provided for @latestDebates.
  ///
  /// In en, this message translates to:
  /// **'Latest debates'**
  String get latestDebates;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @noDebatesYet.
  ///
  /// In en, this message translates to:
  /// **'No debates yet'**
  String get noDebatesYet;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @privateDetails.
  ///
  /// In en, this message translates to:
  /// **'Private details'**
  String get privateDetails;

  /// No description provided for @fieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get fieldAge;

  /// No description provided for @fieldJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get fieldJoined;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsLabel;

  /// No description provided for @tenureNew.
  ///
  /// In en, this message translates to:
  /// **'New to debate'**
  String get tenureNew;

  /// No description provided for @tenureYears.
  ///
  /// In en, this message translates to:
  /// **'{count} yr in debate'**
  String tenureYears(int count);

  /// No description provided for @tenureMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} mo in debate'**
  String tenureMonths(int count);

  /// No description provided for @surveyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get surveyDetailsTitle;

  /// No description provided for @surveyNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No surveys currently available'**
  String get surveyNoneAvailable;

  /// No description provided for @surveyAnswerAllQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions before submitting'**
  String get surveyAnswerAllQuestions;

  /// No description provided for @surveySubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your answers were submitted successfully'**
  String get surveySubmittedSuccess;

  /// No description provided for @surveySubmitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get surveySubmitAnswers;

  /// No description provided for @surveyAlreadyAnsweredMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already answered this survey'**
  String get surveyAlreadyAnsweredMessage;

  /// No description provided for @surveyClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'This survey is closed and no longer accepts answers'**
  String get surveyClosedMessage;

  /// No description provided for @trainerSurveysTitle.
  ///
  /// In en, this message translates to:
  /// **'My Team\'s Surveys'**
  String get trainerSurveysTitle;

  /// No description provided for @surveyNewSurvey.
  ///
  /// In en, this message translates to:
  /// **'New survey'**
  String get surveyNewSurvey;

  /// No description provided for @trainerSurveyNoneYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any surveys for your team yet'**
  String get trainerSurveyNoneYet;

  /// No description provided for @surveyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete survey'**
  String get surveyDeleteTitle;

  /// No description provided for @surveyDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this survey? This can\'t be undone, and all its responses will be lost.'**
  String get surveyDeleteConfirmBody;

  /// No description provided for @surveyDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Survey deleted'**
  String get surveyDeletedMsg;

  /// No description provided for @surveyDetailsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey Details'**
  String get surveyDetailsHeaderTitle;

  /// No description provided for @surveyStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get surveyStatusOpen;

  /// No description provided for @surveyStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get surveyStatusClosed;

  /// No description provided for @surveyClosesOnDate.
  ///
  /// In en, this message translates to:
  /// **'Closes on {date}'**
  String surveyClosesOnDate(String date);

  /// No description provided for @surveyQuestionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get surveyQuestionsHeader;

  /// No description provided for @surveyNoQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions for this survey yet'**
  String get surveyNoQuestionsYet;

  /// No description provided for @surveyTypeRating.
  ///
  /// In en, this message translates to:
  /// **'Numeric rating'**
  String get surveyTypeRating;

  /// No description provided for @surveyTypeMcq.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get surveyTypeMcq;

  /// No description provided for @surveyTypeOpenText.
  ///
  /// In en, this message translates to:
  /// **'Open answer'**
  String get surveyTypeOpenText;

  /// No description provided for @surveyResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey Results'**
  String get surveyResultsTitle;

  /// No description provided for @surveyNoResponsesYet.
  ///
  /// In en, this message translates to:
  /// **'No responses to this survey yet'**
  String get surveyNoResponsesYet;

  /// No description provided for @surveyTotalResponsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total responses: {count}'**
  String surveyTotalResponsesLabel(int count);

  /// No description provided for @surveyAnswersSummary.
  ///
  /// In en, this message translates to:
  /// **'Answers summary'**
  String get surveyAnswersSummary;

  /// No description provided for @surveyResponsesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Responses ({count})'**
  String surveyResponsesCountLabel(int count);

  /// No description provided for @surveyNoAnswersYet.
  ///
  /// In en, this message translates to:
  /// **'No answers to this question yet'**
  String get surveyNoAnswersYet;

  /// No description provided for @surveyAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average: {avg} / {max} ({count} responses)'**
  String surveyAverageLabel(String avg, String max, String count);

  /// No description provided for @surveyTextAnswersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} text answers (see below)'**
  String surveyTextAnswersCount(int count);

  /// No description provided for @surveyTargetTeams.
  ///
  /// In en, this message translates to:
  /// **'Target teams'**
  String get surveyTargetTeams;

  /// No description provided for @surveyChooseAtLeastOneTeam.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one team'**
  String get surveyChooseAtLeastOneTeam;

  /// No description provided for @surveyCloseDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Closing date (optional)'**
  String get surveyCloseDateOptional;

  /// No description provided for @surveyNoCloseDate.
  ///
  /// In en, this message translates to:
  /// **'No closing date'**
  String get surveyNoCloseDate;

  /// No description provided for @surveyQuestionsRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Questions *'**
  String get surveyQuestionsRequiredLabel;

  /// No description provided for @surveyQuestionsHint.
  ///
  /// In en, this message translates to:
  /// **'At least one question required. The survey can\'t be edited after it\'s created, so review your questions before submitting.'**
  String get surveyQuestionsHint;

  /// No description provided for @surveyCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create survey'**
  String get surveyCreateButton;

  /// No description provided for @surveyTitleField.
  ///
  /// In en, this message translates to:
  /// **'Survey title'**
  String get surveyTitleField;

  /// No description provided for @surveyTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get surveyTitleRequired;

  /// No description provided for @surveyDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get surveyDescriptionOptional;

  /// No description provided for @surveyAddAtLeastOneTeam.
  ///
  /// In en, this message translates to:
  /// **'Add at least one team'**
  String get surveyAddAtLeastOneTeam;

  /// No description provided for @surveyAddAtLeastOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question — participants can\'t answer a survey with no questions'**
  String get surveyAddAtLeastOneQuestion;

  /// No description provided for @surveyCompleteAllQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Complete the text of every question before saving'**
  String get surveyCompleteAllQuestionText;

  /// No description provided for @surveyMcqNeedsTwoOptions.
  ///
  /// In en, this message translates to:
  /// **'Multiple-choice questions need at least two options'**
  String get surveyMcqNeedsTwoOptions;

  /// No description provided for @surveyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Survey created successfully'**
  String get surveyCreatedSuccess;

  /// No description provided for @surveyPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'The survey was created, but its questions couldn\'t be saved: {message}. Surveys can\'t be edited after creation, so it will stay without questions — you may prefer to create a new one instead.'**
  String surveyPartialSuccess(String message);

  /// No description provided for @surveyClosesInDays.
  ///
  /// In en, this message translates to:
  /// **'Closes in {days} days'**
  String surveyClosesInDays(int days);

  /// No description provided for @surveyClosesInHours.
  ///
  /// In en, this message translates to:
  /// **'Closes in {hours} hours'**
  String surveyClosesInHours(int hours);

  /// No description provided for @surveyClosesSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get surveyClosesSoon;

  /// No description provided for @surveyAnsweredChip.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get surveyAnsweredChip;

  /// No description provided for @surveyWriteAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer here...'**
  String get surveyWriteAnswerHint;

  /// No description provided for @surveyAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get surveyAddQuestion;

  /// No description provided for @surveyQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String surveyQuestionNumber(int number);

  /// No description provided for @surveyQuestionTextHint.
  ///
  /// In en, this message translates to:
  /// **'Question text'**
  String get surveyQuestionTextHint;

  /// No description provided for @surveyQuestionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get surveyQuestionTypeLabel;

  /// No description provided for @surveyMinValue.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get surveyMinValue;

  /// No description provided for @surveyMaxValue.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get surveyMaxValue;

  /// No description provided for @surveyStepValue.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get surveyStepValue;

  /// No description provided for @surveyOptionsMinTwo.
  ///
  /// In en, this message translates to:
  /// **'Options (at least two)'**
  String get surveyOptionsMinTwo;

  /// No description provided for @surveyOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String surveyOptionHint(int number);

  /// No description provided for @surveyAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get surveyAddOption;

  /// No description provided for @complaintNewComplaint.
  ///
  /// In en, this message translates to:
  /// **'New complaint'**
  String get complaintNewComplaint;

  /// No description provided for @complaintNoneYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t filed any complaints yet'**
  String get complaintNoneYet;

  /// No description provided for @complaintStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get complaintStatusOpen;

  /// No description provided for @complaintStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get complaintStatusResolved;

  /// No description provided for @complaintStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get complaintStatusRejected;

  /// No description provided for @complaintStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get complaintStatusClosed;

  /// No description provided for @complaintDebateFallback.
  ///
  /// In en, this message translates to:
  /// **'Debate #{id}'**
  String complaintDebateFallback(int id);

  /// No description provided for @complaintAdminResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin response'**
  String get complaintAdminResponseLabel;

  /// No description provided for @complaintChooseDebate.
  ///
  /// In en, this message translates to:
  /// **'Choose the debate this complaint is about'**
  String get complaintChooseDebate;

  /// No description provided for @complaintDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Complaint description'**
  String get complaintDescriptionLabel;

  /// No description provided for @complaintDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Complaint description is required'**
  String get complaintDescriptionRequired;

  /// No description provided for @complaintDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the issue in detail...'**
  String get complaintDescriptionHint;

  /// No description provided for @complaintSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit complaint'**
  String get complaintSubmitButton;

  /// No description provided for @complaintSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted successfully'**
  String get complaintSubmittedSuccess;

  /// No description provided for @complaintDebateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Debate'**
  String get complaintDebateFieldLabel;

  /// No description provided for @debateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a debate by title...'**
  String get debateSearchHint;

  /// No description provided for @debateSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String debateSearchFailed(String error);

  /// No description provided for @teamSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a team by name...'**
  String get teamSearchHint;

  /// No description provided for @teamNoneAvailableToJoin.
  ///
  /// In en, this message translates to:
  /// **'No teams currently available to join'**
  String get teamNoneAvailableToJoin;

  /// No description provided for @teamLeaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave team'**
  String get teamLeaveDialogTitle;

  /// No description provided for @teamLeaveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'A leave request will be sent to the team\'s trainer for approval. Continue?'**
  String get teamLeaveDialogBody;

  /// No description provided for @teamReasonOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get teamReasonOptionalHint;

  /// No description provided for @teamSendRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get teamSendRequestButton;

  /// No description provided for @teamJoinDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the team'**
  String get teamJoinDialogTitle;

  /// No description provided for @teamJoinDialogBody.
  ///
  /// In en, this message translates to:
  /// **'A join request will be sent to the team\'s trainer for approval. Continue?'**
  String get teamJoinDialogBody;

  /// No description provided for @teamRoleLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get teamRoleLeader;

  /// No description provided for @teamRoleTrainer.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get teamRoleTrainer;

  /// No description provided for @teamRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamRoleMember;

  /// No description provided for @teamJoinedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined on'**
  String get teamJoinedDateLabel;

  /// No description provided for @teamLeftDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Left on'**
  String get teamLeftDateLabel;

  /// No description provided for @teamTrainerLabel.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get teamTrainerLabel;

  /// No description provided for @teamMembersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamMembersCountLabel;

  /// No description provided for @teamInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Info'**
  String get teamInfoTitle;

  /// No description provided for @teamLeaveRequestPendingMsg.
  ///
  /// In en, this message translates to:
  /// **'Leave request sent. Awaiting the trainer\'s approval'**
  String get teamLeaveRequestPendingMsg;

  /// No description provided for @teamLeaveRequestSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Leave request sent'**
  String get teamLeaveRequestSentMsg;

  /// No description provided for @teamJoinRequestPendingMsg.
  ///
  /// In en, this message translates to:
  /// **'Join request sent. Awaiting the trainer\'s approval'**
  String get teamJoinRequestPendingMsg;

  /// No description provided for @teamJoinRequestSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Join request sent'**
  String get teamJoinRequestSentMsg;

  /// No description provided for @teamMembersHeader.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamMembersHeader;

  /// No description provided for @teamNoMembersYet.
  ///
  /// In en, this message translates to:
  /// **'This team has no members yet'**
  String get teamNoMembersYet;

  /// No description provided for @teamLeaveTeamAction.
  ///
  /// In en, this message translates to:
  /// **'Leave team'**
  String get teamLeaveTeamAction;

  /// No description provided for @teamJoinTeamAction.
  ///
  /// In en, this message translates to:
  /// **'Join the team'**
  String get teamJoinTeamAction;

  /// No description provided for @teamChipLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the team'**
  String get teamChipLeft;

  /// No description provided for @teamChipCurrentMember.
  ///
  /// In en, this message translates to:
  /// **'Current member'**
  String get teamChipCurrentMember;

  /// No description provided for @teamChipActive.
  ///
  /// In en, this message translates to:
  /// **'Team active'**
  String get teamChipActive;

  /// No description provided for @teamChipInactive.
  ///
  /// In en, this message translates to:
  /// **'Team inactive'**
  String get teamChipInactive;

  /// No description provided for @teamForbiddenMsg.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to view this team\'s details'**
  String get teamForbiddenMsg;

  /// No description provided for @teamNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'This team doesn\'t exist'**
  String get teamNotFoundMsg;

  /// No description provided for @teamAuthRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view this team\'s details'**
  String get teamAuthRequiredMsg;

  /// No description provided for @teamLoadFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this team\'s details right now'**
  String get teamLoadFailedMsg;

  /// No description provided for @teamDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate team'**
  String get teamDeactivateTitle;

  /// No description provided for @teamDeactivateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this team?'**
  String get teamDeactivateConfirmBody;

  /// No description provided for @teamCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get teamCancelButton;

  /// No description provided for @teamDeactivateConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get teamDeactivateConfirmButton;

  /// No description provided for @teamRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get teamRemoveMemberTitle;

  /// No description provided for @teamRemoveMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the team?'**
  String teamRemoveMemberBody(String name);

  /// No description provided for @teamRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamRemoveButton;

  /// No description provided for @teamAcceptLeaveRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept leave request'**
  String get teamAcceptLeaveRequestTitle;

  /// No description provided for @teamRejectLeaveRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject leave request'**
  String get teamRejectLeaveRequestTitle;

  /// No description provided for @teamLeaveRequestAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will leave the team immediately. Continue?'**
  String teamLeaveRequestAcceptBody(String name);

  /// No description provided for @teamLeaveRequestRejectBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will remain a member of the team. Reject this request?'**
  String teamLeaveRequestRejectBody(String name);

  /// No description provided for @teamAcceptJoinRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept join request'**
  String get teamAcceptJoinRequestTitle;

  /// No description provided for @teamRejectJoinRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject join request'**
  String get teamRejectJoinRequestTitle;

  /// No description provided for @teamJoinRequestAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will join the team immediately. Continue?'**
  String teamJoinRequestAcceptBody(String name);

  /// No description provided for @teamJoinRequestRejectBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will not join the team. Reject this request?'**
  String teamJoinRequestRejectBody(String name);

  /// No description provided for @teamAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get teamAcceptButton;

  /// No description provided for @teamRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get teamRejectButton;

  /// No description provided for @teamAddMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get teamAddMembers;

  /// No description provided for @teamAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String teamAddCount(int count);

  /// No description provided for @teamDeactivatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Team deactivated'**
  String get teamDeactivatedMsg;

  /// No description provided for @teamStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teamStatusActive;

  /// No description provided for @teamStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get teamStatusInactive;

  /// No description provided for @teamLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Leader: {name}'**
  String teamLeaderLabel(String name);

  /// No description provided for @teamJoinRequestsHeader.
  ///
  /// In en, this message translates to:
  /// **'Join requests ({count})'**
  String teamJoinRequestsHeader(int count);

  /// No description provided for @teamLeaveRequestsHeader.
  ///
  /// In en, this message translates to:
  /// **'Leave requests ({count})'**
  String teamLeaveRequestsHeader(int count);

  /// No description provided for @teamMembersHeaderCount.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String teamMembersHeaderCount(int count);

  /// No description provided for @teamDragToReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to change priority'**
  String get teamDragToReorderHint;

  /// No description provided for @teamRequestedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Requested on {date}'**
  String teamRequestedOnDate(String date);

  /// No description provided for @teamNewTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'New team'**
  String get teamNewTeamTitle;

  /// No description provided for @teamAddAtLeastTwoMembers.
  ///
  /// In en, this message translates to:
  /// **'Add at least two members'**
  String get teamAddAtLeastTwoMembers;

  /// No description provided for @teamChooseLeader.
  ///
  /// In en, this message translates to:
  /// **'Choose a team leader'**
  String get teamChooseLeader;

  /// No description provided for @teamCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Team created successfully'**
  String get teamCreatedSuccess;

  /// No description provided for @teamNameField.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamNameField;

  /// No description provided for @teamNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Team name is required'**
  String get teamNameRequired;

  /// No description provided for @teamAddMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least two members, then choose the team\'s leader among them'**
  String get teamAddMembersHint;

  /// No description provided for @teamLeaderSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (leader)'**
  String teamLeaderSuffix(String name);

  /// No description provided for @teamCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get teamCreateButton;

  /// No description provided for @teamNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get teamNoneYet;

  /// No description provided for @teamMembersCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String teamMembersCountShort(int count);

  /// No description provided for @userSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get userSearchHint;

  /// No description provided for @teamLoadListFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load teams: {message}'**
  String teamLoadListFailed(String message);

  /// No description provided for @teamNoneAvailableForYou.
  ///
  /// In en, this message translates to:
  /// **'No teams available to you yet'**
  String get teamNoneAvailableForYou;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsTitleWithName.
  ///
  /// In en, this message translates to:
  /// **'{name} · Statistics'**
  String statsTitleWithName(String name);

  /// No description provided for @statsNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet'**
  String get statsNothingToExport;

  /// No description provided for @statsShareText.
  ///
  /// In en, this message translates to:
  /// **'Jadal debate analysis sheet'**
  String get statsShareText;

  /// No description provided for @statsShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Jadal debate analysis'**
  String get statsShareSubject;

  /// No description provided for @statsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String statsExportFailed(String error);

  /// No description provided for @statsExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export sheet'**
  String get statsExportTooltip;

  /// No description provided for @statsKindWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get statsKindWinRate;

  /// No description provided for @statsKindAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get statsKindAvgScore;

  /// No description provided for @statsKindBestSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Best speaker'**
  String get statsKindBestSpeaker;

  /// No description provided for @statsKindRanking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get statsKindRanking;

  /// No description provided for @statsKindImprovement.
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get statsKindImprovement;

  /// No description provided for @statsKindActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get statsKindActivity;

  /// No description provided for @statsSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get statsSomethingWrong;

  /// No description provided for @statsWinRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get statsWinRateTitle;

  /// No description provided for @statsAvgScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get statsAvgScoreTitle;

  /// No description provided for @statsBestSpeakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Best-speaker rate'**
  String get statsBestSpeakerTitle;

  /// No description provided for @statsDebatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} debates'**
  String statsDebatesCount(int count);

  /// No description provided for @statsCouldNotUpdateFilters.
  ///
  /// In en, this message translates to:
  /// **'Could not update with these filters'**
  String get statsCouldNotUpdateFilters;

  /// No description provided for @statsTopOfJadal.
  ///
  /// In en, this message translates to:
  /// **'Top of Jadal'**
  String get statsTopOfJadal;

  /// No description provided for @statsFilterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get statsFilterBy;

  /// No description provided for @statsFilterDimPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get statsFilterDimPosition;

  /// No description provided for @statsFilterDimFramework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get statsFilterDimFramework;

  /// No description provided for @statsFilterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get statsFilterPeriod;

  /// No description provided for @statsFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get statsFilterReset;

  /// No description provided for @statsPickMonthHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a month (day is ignored)'**
  String get statsPickMonthHelp;

  /// No description provided for @statsScopeDebaters.
  ///
  /// In en, this message translates to:
  /// **'Debaters'**
  String get statsScopeDebaters;

  /// No description provided for @statsScopeTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get statsScopeTeams;

  /// No description provided for @statsMetricPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get statsMetricPoints;

  /// No description provided for @statsNoEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get statsNoEntriesYet;

  /// No description provided for @statsTeamAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Team analysis'**
  String get statsTeamAnalysisTitle;

  /// No description provided for @statsTeamAnalysisTitleWithName.
  ///
  /// In en, this message translates to:
  /// **'{name} · Team analysis'**
  String statsTeamAnalysisTitleWithName(String name);

  /// No description provided for @statsAveragedAcrossTeams.
  ///
  /// In en, this message translates to:
  /// **'Averaged across your teams'**
  String get statsAveragedAcrossTeams;

  /// No description provided for @statsTeamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} teams'**
  String statsTeamsCount(int count);

  /// No description provided for @statsAvgImprovement.
  ///
  /// In en, this message translates to:
  /// **'Avg improvement'**
  String get statsAvgImprovement;

  /// No description provided for @statsAvgWinRate.
  ///
  /// In en, this message translates to:
  /// **'Avg win rate'**
  String get statsAvgWinRate;

  /// No description provided for @statsAvgMemberActivity.
  ///
  /// In en, this message translates to:
  /// **'Avg member activity'**
  String get statsAvgMemberActivity;

  /// No description provided for @statsOverallPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% overall'**
  String statsOverallPercent(int percent);

  /// No description provided for @statsAttendedCount.
  ///
  /// In en, this message translates to:
  /// **'{attended}/{selected} attended'**
  String statsAttendedCount(int attended, int selected);

  /// No description provided for @statsRegisteredNotHeldAgainst.
  ///
  /// In en, this message translates to:
  /// **'Registered {count} times — selection is the admin\'s call, not held against you.'**
  String statsRegisteredNotHeldAgainst(int count);

  /// No description provided for @statsFrameworksTitle.
  ///
  /// In en, this message translates to:
  /// **'Frameworks'**
  String get statsFrameworksTitle;

  /// No description provided for @filterStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get filterStatusScheduled;

  /// No description provided for @filterStatusAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get filterStatusAnnounced;

  /// No description provided for @filterStatusSidesSelected.
  ///
  /// In en, this message translates to:
  /// **'Sides selected'**
  String get filterStatusSidesSelected;

  /// No description provided for @filterStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get filterStatusLive;

  /// No description provided for @filterStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterStatusCompleted;

  /// No description provided for @filterStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterStatusCancelled;

  /// No description provided for @filterFormatFallback.
  ///
  /// In en, this message translates to:
  /// **'Format {id}'**
  String filterFormatFallback(String id);

  /// No description provided for @filterDebatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter debates'**
  String get filterDebatesTitle;

  /// No description provided for @filterLabelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterLabelStatus;

  /// No description provided for @filterLabelFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get filterLabelFormat;

  /// No description provided for @filterLabelMotionFramework.
  ///
  /// In en, this message translates to:
  /// **'Motion framework'**
  String get filterLabelMotionFramework;

  /// No description provided for @filterLabelDebateTag.
  ///
  /// In en, this message translates to:
  /// **'Debate tag'**
  String get filterLabelDebateTag;

  /// No description provided for @filterLabelJudge.
  ///
  /// In en, this message translates to:
  /// **'Judge'**
  String get filterLabelJudge;

  /// No description provided for @filterLabelTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get filterLabelTeam;

  /// No description provided for @filterLabelUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get filterLabelUser;

  /// No description provided for @filterSearchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search users…'**
  String get filterSearchUsersHint;

  /// No description provided for @filterClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClearButton;

  /// No description provided for @filterApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApplyButton;

  /// No description provided for @filterArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter articles'**
  String get filterArticlesTitle;

  /// No description provided for @filterLabelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterLabelCategory;

  /// No description provided for @filterLabelTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterLabelTag;

  /// No description provided for @filterLabelPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get filterLabelPublisher;

  /// No description provided for @filterSearchAuthorsHint.
  ///
  /// In en, this message translates to:
  /// **'Search authors…'**
  String get filterSearchAuthorsHint;

  /// No description provided for @filterLikedByMe.
  ///
  /// In en, this message translates to:
  /// **'Liked by me'**
  String get filterLikedByMe;

  /// No description provided for @filterNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'None available'**
  String get filterNoneAvailable;

  /// No description provided for @filterDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRangeLabel;

  /// No description provided for @filterFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get filterFromLabel;

  /// No description provided for @filterToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get filterToLabel;

  /// No description provided for @mutedSpeakingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mic is off'**
  String get mutedSpeakingTitle;

  /// No description provided for @mutedSpeakingBody.
  ///
  /// In en, this message translates to:
  /// **'You seem to be talking, but no one can hear you.'**
  String get mutedSpeakingBody;

  /// No description provided for @unmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteAction;

  /// No description provided for @debatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Debates'**
  String get debatesTitle;

  /// No description provided for @tabRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get tabRegistration;

  /// No description provided for @tabAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get tabAnnounced;

  /// No description provided for @tabSidesSelected.
  ///
  /// In en, this message translates to:
  /// **'Sides selected'**
  String get tabSidesSelected;

  /// No description provided for @tabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tabDone;

  /// No description provided for @tabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tabCancelled;

  /// No description provided for @noDebatesHere.
  ///
  /// In en, this message translates to:
  /// **'No debates here yet'**
  String get noDebatesHere;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join now'**
  String get joinNow;

  /// No description provided for @viewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get viewResults;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register for this debate'**
  String get registerTitle;

  /// No description provided for @registerAsTeam.
  ///
  /// In en, this message translates to:
  /// **'Register as a team'**
  String get registerAsTeam;

  /// No description provided for @registerAsSolo.
  ///
  /// In en, this message translates to:
  /// **'Register solo'**
  String get registerAsSolo;

  /// No description provided for @registerAsJudge.
  ///
  /// In en, this message translates to:
  /// **'Register as a judge'**
  String get registerAsJudge;

  /// No description provided for @judgesLabel.
  ///
  /// In en, this message translates to:
  /// **'Judges'**
  String get judgesLabel;

  /// No description provided for @judgeRole.
  ///
  /// In en, this message translates to:
  /// **'Judge'**
  String get judgeRole;

  /// No description provided for @youTag.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTag;

  /// No description provided for @stagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stagesLabel;

  /// No description provided for @formatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @chairLabel.
  ///
  /// In en, this message translates to:
  /// **'Chair'**
  String get chairLabel;

  /// No description provided for @replyTag.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyTag;

  /// No description provided for @scheduledLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledLabel;

  /// No description provided for @speakersPerSideLabel.
  ///
  /// In en, this message translates to:
  /// **'Speakers per side'**
  String get speakersPerSideLabel;

  /// No description provided for @cancellationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get cancellationReasonLabel;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email and choose a new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @firstTeam.
  ///
  /// In en, this message translates to:
  /// **'First team'**
  String get firstTeam;

  /// No description provided for @secondTeam.
  ///
  /// In en, this message translates to:
  /// **'Second team'**
  String get secondTeam;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get speaking;

  /// No description provided for @muteUser.
  ///
  /// In en, this message translates to:
  /// **'Block mic'**
  String get muteUser;

  /// No description provided for @unmuteUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock mic'**
  String get unmuteUser;

  /// No description provided for @unmuteAll.
  ///
  /// In en, this message translates to:
  /// **'Unmute all'**
  String get unmuteAll;

  /// No description provided for @cameraOffAll.
  ///
  /// In en, this message translates to:
  /// **'Camera off — all'**
  String get cameraOffAll;

  /// No description provided for @allowCameraAll.
  ///
  /// In en, this message translates to:
  /// **'Allow camera — all'**
  String get allowCameraAll;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// No description provided for @shareResultPrompt.
  ///
  /// In en, this message translates to:
  /// **'The room is closed. Share the result to finish the debate.'**
  String get shareResultPrompt;

  /// No description provided for @resultSharedMsg.
  ///
  /// In en, this message translates to:
  /// **'Result shared successfully.'**
  String get resultSharedMsg;

  /// No description provided for @closeRoom.
  ///
  /// In en, this message translates to:
  /// **'Close room'**
  String get closeRoom;

  /// No description provided for @closeRoomBody.
  ///
  /// In en, this message translates to:
  /// **'This removes everyone from the room and closes it. Continue?'**
  String get closeRoomBody;

  /// No description provided for @leaveSession.
  ///
  /// In en, this message translates to:
  /// **'Leave session'**
  String get leaveSession;

  /// No description provided for @roomClosedMsg.
  ///
  /// In en, this message translates to:
  /// **'The chair closed the room.'**
  String get roomClosedMsg;

  /// No description provided for @roomClosedStatus.
  ///
  /// In en, this message translates to:
  /// **'Room closed'**
  String get roomClosedStatus;

  /// No description provided for @teamIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Team ID'**
  String get teamIdLabel;

  /// No description provided for @teamRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your team\'s ID to register the whole team. You must be the team\'s leader or coach.'**
  String get teamRegisterPrompt;

  /// No description provided for @connectingToRoom.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the debate room…'**
  String get connectingToRoom;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the room. Please try again.'**
  String get connectionFailed;

  /// No description provided for @notJoinedYet.
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t joined yet'**
  String get notJoinedYet;

  /// No description provided for @waitingToJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting to join'**
  String get waitingToJoin;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String greetingWithName(String name);

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get greeting;

  /// No description provided for @topDebaters.
  ///
  /// In en, this message translates to:
  /// **'Top debaters'**
  String get topDebaters;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @latestArticles.
  ///
  /// In en, this message translates to:
  /// **'Latest articles'**
  String get latestArticles;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noArticles.
  ///
  /// In en, this message translates to:
  /// **'No articles'**
  String get noArticles;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @searchUsersTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for users or teams…'**
  String get searchUsersTeamsHint;

  /// No description provided for @searchUsersTeamsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for users or teams'**
  String get searchUsersTeamsPrompt;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @usersSection.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersSection;

  /// No description provided for @teamsSection.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsSection;

  /// No description provided for @roleDebater.
  ///
  /// In en, this message translates to:
  /// **'Debater'**
  String get roleDebater;

  /// No description provided for @roleTrainer.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get roleTrainer;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @membersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCountLabel(int count);

  /// No description provided for @coachNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach: {name}'**
  String coachNameLabel(String name);

  /// No description provided for @searchArticlesHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles…'**
  String get searchArticlesHint;

  /// No description provided for @allArticles.
  ///
  /// In en, this message translates to:
  /// **'All articles'**
  String get allArticles;

  /// No description provided for @newArticle.
  ///
  /// In en, this message translates to:
  /// **'New article'**
  String get newArticle;

  /// No description provided for @createArticle.
  ///
  /// In en, this message translates to:
  /// **'Create article'**
  String get createArticle;

  /// No description provided for @deleteArticle.
  ///
  /// In en, this message translates to:
  /// **'Delete article'**
  String get deleteArticle;

  /// No description provided for @deleteArticleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteArticleConfirm(String title);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @articleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Article deleted successfully'**
  String get articleDeleted;

  /// No description provided for @articleDetails.
  ///
  /// In en, this message translates to:
  /// **'Article details'**
  String get articleDetails;

  /// No description provided for @createNewArticle.
  ///
  /// In en, this message translates to:
  /// **'Create a new article'**
  String get createNewArticle;

  /// No description provided for @addYourNewArticle.
  ///
  /// In en, this message translates to:
  /// **'Add your new article'**
  String get addYourNewArticle;

  /// No description provided for @articleReviewNote.
  ///
  /// In en, this message translates to:
  /// **'The article will be sent for review before publishing'**
  String get articleReviewNote;

  /// No description provided for @articleTitleRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Article title *'**
  String get articleTitleRequiredLabel;

  /// No description provided for @contentRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Content *'**
  String get contentRequiredLabel;

  /// No description provided for @imageUrlOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Image link (optional)'**
  String get imageUrlOptionalLabel;

  /// No description provided for @categoriesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories (optional)'**
  String get categoriesOptionalLabel;

  /// No description provided for @chooseCategories.
  ///
  /// In en, this message translates to:
  /// **'Choose categories'**
  String get chooseCategories;

  /// No description provided for @tagsOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get tagsOptionalLabel;

  /// No description provided for @chooseTags.
  ///
  /// In en, this message translates to:
  /// **'Choose tags'**
  String get chooseTags;

  /// No description provided for @publishArticle.
  ///
  /// In en, this message translates to:
  /// **'Publish article'**
  String get publishArticle;

  /// No description provided for @titleContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and content are required'**
  String get titleContentRequired;

  /// No description provided for @optionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load options: {error}'**
  String optionsLoadError(String error);

  /// No description provided for @submitComplaintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Submit a complaint'**
  String get submitComplaintTooltip;

  /// No description provided for @registrantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Registrants'**
  String get registrantsTitle;

  /// No description provided for @registrantsTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get registrantsTeamsLabel;

  /// No description provided for @registrantsJudgesLabel.
  ///
  /// In en, this message translates to:
  /// **'Judges'**
  String get registrantsJudgesLabel;

  /// No description provided for @registrantsSoloLabel.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get registrantsSoloLabel;

  /// No description provided for @registeredTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered teams'**
  String get registeredTeamsTitle;

  /// No description provided for @registeredJudgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered judges'**
  String get registeredJudgesTitle;

  /// No description provided for @soloApplicantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Solo applicants'**
  String get soloApplicantsTitle;

  /// No description provided for @noneYetLabel.
  ///
  /// In en, this message translates to:
  /// **'None yet.'**
  String get noneYetLabel;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @currentPill.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPill;

  /// No description provided for @noPastTeams.
  ///
  /// In en, this message translates to:
  /// **'No past teams'**
  String get noPastTeams;

  /// No description provided for @showPastTeams.
  ///
  /// In en, this message translates to:
  /// **'Show past teams'**
  String get showPastTeams;

  /// No description provided for @hidePastTeams.
  ///
  /// In en, this message translates to:
  /// **'Hide past teams'**
  String get hidePastTeams;

  /// No description provided for @elapsedDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String elapsedDaysShort(int count);

  /// No description provided for @elapsedMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'{count}mo'**
  String elapsedMonthsShort(int count);

  /// No description provided for @elapsedYearsShort.
  ///
  /// In en, this message translates to:
  /// **'{count}y'**
  String elapsedYearsShort(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
