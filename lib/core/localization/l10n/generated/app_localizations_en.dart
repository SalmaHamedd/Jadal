// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get startCall => 'Start Call';

  @override
  String get waitingForRemoteVideo => 'Waiting for Remote Video';

  @override
  String get yourVideo => 'Your Video Preview';

  @override
  String get welcome => 'Welcome';

  @override
  String get email => 'Email';

  @override
  String get enterValidEmail => 'Enter valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordValidationMessage =>
      'Password must contain both letters and numbers and be at least 6 characters long';

  @override
  String get forgetPassword => 'Forget your password?';

  @override
  String get signin => 'Sign in';

  @override
  String get random => 'Random';

  @override
  String get excellent => 'Excellent';

  @override
  String get good => 'Good';

  @override
  String get poor => 'Poor';

  @override
  String get unknown => 'No Connection';

  @override
  String get next => 'Next';

  @override
  String get apply => 'Apply';

  @override
  String get submit => 'Submit';

  @override
  String get assign_debate_sides => 'Assign Debate Sides';

  @override
  String get select_debate_motion => 'Select Debate Motion';

  @override
  String get search_motion => 'Search Motion';

  @override
  String get motion => 'Debate Motion';

  @override
  String get select_new_motion => 'Select New Motion';

  @override
  String get select_topics => 'Select the motion topics (2 maximum)';

  @override
  String get motion_topics => 'Motion Topics: ';

  @override
  String get filter_motion => 'Filter Motions';

  @override
  String get protected => 'PROTECTED';

  @override
  String get open => 'POI ALLOWED';

  @override
  String get time_over => 'TIME OVER';

  @override
  String get available_rooms => 'Available Rooms';

  @override
  String get no_available_rooms => 'No available rooms';

  @override
  String get join => 'Join';

  @override
  String get cancel => 'Cancel';

  @override
  String get appName => 'Jadal';

  @override
  String get appSlogan => 'Where word meets technology';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginButton => 'Log In';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get forgotPasswordButton => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get emailEmpty => 'Please enter your email';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get ok => 'OK';

  @override
  String get permissionsRequiredTitle => 'Permissions required';

  @override
  String get permissionsRequiredBody =>
      'Jadal needs camera, microphone, and Bluetooth access to work properly during live debates.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get loading => 'Loading…';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionBluetooth => 'Bluetooth';

  @override
  String get lobbyTitle => 'Debate Rooms';

  @override
  String get proposition => 'Proposition';

  @override
  String get opposition => 'Opposition';

  @override
  String get liveDebateRoom => 'Live Debate';

  @override
  String get resultRoomTitle => 'Result';

  @override
  String get statusOpen => 'Open';

  @override
  String get onlyTeamMembers => 'Team members only';

  @override
  String get prepClosed => 'Preparation closed';

  @override
  String get orderNotSet => 'Speaker order not set';

  @override
  String get orderSet => 'Speaker order set';

  @override
  String get resultsNotReady => 'Results not ready yet';

  @override
  String get resultsNotReadyBody =>
      'The result room opens once the chair marks the debate as finished.';

  @override
  String get results => 'Results';

  @override
  String get needOrderTitle => 'Set the speaker order first';

  @override
  String get needOrderBody =>
      'Go to your team\'s preparation room and select the speaker order before joining the live debate.';

  @override
  String get goToPrep => 'Go to prep room';

  @override
  String get joiningAsAudience => 'Joining as audience';

  @override
  String get prepRoomTitle => 'Preparation';

  @override
  String get prepEndsIn => 'Prep ends in';

  @override
  String get selectSpeakerOrder => 'Select speaker order';

  @override
  String get updateSpeakerOrder => 'Update speaker order';

  @override
  String get leaderHint =>
      'You are the current leader — set the speaking order.';

  @override
  String get notLeaderHint => 'Speaking order is set by';

  @override
  String get speakerOrderTitle => 'Speaker Order';

  @override
  String get dragToReorder => 'Drag to reorder the speakers (1st, 2nd, 3rd).';

  @override
  String get replySpeaker => 'Reply speaker (1st or 2nd only)';

  @override
  String get saveOrder => 'Save order';

  @override
  String get tapNextToStart => 'Tap Next to start the debate.';

  @override
  String get extraTime => 'EXTRA TIME';

  @override
  String get nowSpeaking => 'Now speaking';

  @override
  String get debateFinished => 'The debate has finished.';

  @override
  String get backToDebate => 'Back to debate';

  @override
  String get newsPoisOpen => 'POIs are now open.';

  @override
  String get newsLastChance =>
      'One minute until POIs close — last chance to ask.';

  @override
  String get newsPoisClosed => 'Protected period — POIs are now closed.';

  @override
  String get newsMainEnded =>
      'Main speaking time has ended — extra time begins.';

  @override
  String get newsExtraEnded => 'Time off — nothing is being recorded now.';

  @override
  String get newEventHappened => 'New event happened';

  @override
  String get audience => 'Audience';

  @override
  String get searchHint => 'Search…';

  @override
  String get noMatches => 'No matches';

  @override
  String get categories => 'Categories';

  @override
  String get tags => 'Tags';

  @override
  String get poiTitle => 'Point of Information';

  @override
  String get poiPrompt => 'A debater is requesting a POI. Accept or refuse?';

  @override
  String get accept => 'Accept';

  @override
  String get refuse => 'Refuse';

  @override
  String get poiYourTurn => 'Your POI was accepted';

  @override
  String get poiSpeakNow => 'Open your mic and make your point, then tap Done.';

  @override
  String get poiDone => 'Done';

  @override
  String get forceMute => 'Force mute';

  @override
  String get forceCameraOff => 'Force camera off';

  @override
  String get goToProfile => 'Go to profile';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get confirm => 'Confirm';

  @override
  String get leaveToProfileWarning => 'This will leave the debate.';

  @override
  String get muteAll => 'Mute all';

  @override
  String get openLobbyMode => 'Open-lobby mode';

  @override
  String get teamChat => 'Team chat';

  @override
  String get leaveDebate => 'Leave debate';

  @override
  String get leaveDebateBody => 'Are you sure you want to leave the debate?';

  @override
  String get themeToggleTest => 'Toggle theme (test only)';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get messageHint => 'Message your team…';
}
