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
