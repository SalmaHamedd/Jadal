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
  String get debateNotStarted => 'The debate hasn\'t started yet.';

  @override
  String get youJoinedLiveSession => 'You\'ve joined the live session.';

  @override
  String get goLiveSession => 'Go to live session';

  @override
  String get introductionsLabel => 'Introductions';

  @override
  String get poiAcceptedNews => 'Your POI was accepted';

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
  String get allowCamera => 'Allow camera';

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

  @override
  String get newMessages => 'New messages';

  @override
  String get micMutedWhileSpeaking =>
      'You\'re on — but your mic is off. Unmute to be heard.';

  @override
  String get submitResult => 'Submit result';

  @override
  String get submitResultTitle => 'Submit Result';

  @override
  String get submitResultPrompt =>
      'Enter each speaker\'s score, pick the winning side, then submit.';

  @override
  String get revealResult => 'Reveal result';

  @override
  String get closeMainRoom => 'Close main room';

  @override
  String get closeWithoutResult => 'Close without a result';

  @override
  String get winningSideLabel => 'Winning side';

  @override
  String get summaryNotesLabel => 'Summary notes';

  @override
  String get summaryNotesHint => 'Notes about the result (optional)';

  @override
  String get selectWinningSideFirst => 'Please select the winning side first.';

  @override
  String get resultSubmittedMsg => 'Result submitted';

  @override
  String get resultRevealedMsg => 'Result revealed!';

  @override
  String get mainRoomClosedMsg => 'Main room closed';

  @override
  String get awaitingReveal =>
      'The result is in — awaiting the chair\'s reveal.';

  @override
  String get resultsPending => 'The chair is finalizing the result…';

  @override
  String get noResultYet => 'No result submitted yet';

  @override
  String get winnerLabel => 'Winner';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get bestSpeakerLabel => 'Best speaker';

  @override
  String get perSpeechScores => 'Per-speech scores';

  @override
  String get scoreLabel => 'Score';

  @override
  String get debateCancelledTitle => 'Debate cancelled';

  @override
  String get debateCancelledBody =>
      'The main room was closed without submitting a result.';

  @override
  String get rateDebate => 'Rate this debate';

  @override
  String get ratingThanks => 'Thanks for your feedback!';

  @override
  String get debatesTitle => 'Debates';

  @override
  String get tabRegistration => 'Registration';

  @override
  String get tabAnnounced => 'Announced';

  @override
  String get tabSidesSelected => 'Sides selected';

  @override
  String get tabLive => 'Live';

  @override
  String get tabDone => 'Done';

  @override
  String get tabCancelled => 'Cancelled';

  @override
  String get noDebatesHere => 'No debates here yet';

  @override
  String get retry => 'Retry';

  @override
  String get register => 'Register';

  @override
  String get joinNow => 'Join now';

  @override
  String get viewResults => 'View results';

  @override
  String get registerTitle => 'Register for this debate';

  @override
  String get registerAsTeam => 'Register as a team';

  @override
  String get registerAsSolo => 'Register solo';

  @override
  String get registerAsJudge => 'Register as a judge';

  @override
  String get judgesLabel => 'Judges';

  @override
  String get judgeRole => 'Judge';

  @override
  String get youTag => 'You';

  @override
  String get stagesLabel => 'Stages';

  @override
  String get formatLabel => 'Format';

  @override
  String get chairLabel => 'Chair';

  @override
  String get replyTag => 'Reply';

  @override
  String get scheduledLabel => 'Scheduled';

  @override
  String get speakersPerSideLabel => 'Speakers per side';

  @override
  String get cancellationReasonLabel => 'Cancellation reason';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the code sent to your email and choose a new password.';

  @override
  String get resetCode => 'Reset code';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get firstTeam => 'First team';

  @override
  String get secondTeam => 'Second team';

  @override
  String get speaking => 'Speaking';

  @override
  String get muteUser => 'Block mic';

  @override
  String get unmuteUser => 'Unblock mic';

  @override
  String get unmuteAll => 'Unmute all';

  @override
  String get cameraOffAll => 'Camera off — all';

  @override
  String get allowCameraAll => 'Allow camera — all';

  @override
  String get shareResult => 'Share result';

  @override
  String get shareResultPrompt =>
      'The room is closed. Share the result to finish the debate.';

  @override
  String get resultSharedMsg => 'Result shared successfully.';

  @override
  String get closeRoom => 'Close room';

  @override
  String get closeRoomBody =>
      'This removes everyone from the room and closes it. Continue?';

  @override
  String get leaveSession => 'Leave session';

  @override
  String get roomClosedMsg => 'The chair closed the room.';

  @override
  String get roomClosedStatus => 'Room closed';

  @override
  String get teamIdLabel => 'Team ID';

  @override
  String get teamRegisterPrompt =>
      'Enter your team\'s ID to register the whole team. You must be the team\'s leader or coach.';

  @override
  String get connectingToRoom => 'Connecting to the debate room…';

  @override
  String get connectionFailed =>
      'Couldn\'t connect to the room. Please try again.';

  @override
  String get notJoinedYet => 'Hasn\'t joined yet';

  @override
  String get waitingToJoin => 'Waiting to join';
}
