/// All user-facing copy (US English) in one place. Voice: direct, friendly, jobsite-plain — short verbs, no jargon.
abstract final class S {
  // Brand
  static const appName = 'PinPunch';
  static const tagline = 'Punch in where the work is.';

  // Common
  static const retry = 'Try again';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const close = 'Close';
  static const refresh = 'Refresh';
  static const signOut = 'Sign out';
  static const signOutQuestion = 'Sign out?';
  static const moreOptions = 'More options';
  static const couldNotLoad = "Couldn't load";
  static const noConnection = "Can't reach the server.";
  static const serverSlow = 'The server is not responding. Check your connection.';
  static const sessionExpired = 'Your session expired. Please sign in again.';
  static const noPermission = "You don't have permission to do that.";
  static const notFound = 'Not found.';
  static const tooManyAttempts = 'Too many attempts. Wait a few minutes.';
  static const serverError = 'Server error. Please try again later.';
  static String rejected(int status) => 'Request rejected ($status).';

  // Login
  static const idLabel = 'Employee ID or username';
  static const idRequired = 'Enter your employee ID or username';
  static const passwordLabel = 'Password';
  static const passwordRequired = 'Enter your password';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const signIn = 'Sign in';
  static const crewUsePhone = 'Crew members punch in from the PinPunch app on their phone.';

  // Location disclosure (Google Play prominent disclosure + US state notice laws)
  static const disclosureTitle = 'PinPunch uses your location';
  static const disclosureBody =
      'To confirm you are at your job site, PinPunch reads your phone\'s location while this app is open and when '
      'you tap Punch in or Punch out.';
  static const disclosurePoint1 = 'Only while the app is open — never in the background.';
  static const disclosurePoint2 = 'Your employer sees where each punch was made, not your movements.';
  static const disclosurePoint3 = 'Fake-GPS apps are detected and the punch is rejected.';
  static const disclosureAccept = 'Continue';
  static const disclosureLater = 'Not now';
  static const disclosureDeclined = 'PinPunch needs your location to record punches. You can continue whenever you are ready.';

  // Worker
  static String hello(String firstName) => 'Hi, $firstName';
  static const punchIn = 'Punch in';
  static const punchOut = 'Punch out';
  static const gettingLocation = 'Getting your location…';
  static const punchingSemantics = 'Punching, getting your location';
  static const offlineShowingSaved = "You're offline — showing the last saved data.";
  static String pending(int n) => n == 1 ? '1 punch waiting to send' : '$n punches waiting to send';
  static const sendNow = 'Send now';
  static const jobSite = 'Job site';
  static const loading = 'Loading…';
  static const noJobSite = 'No job site assigned';
  static String shiftToday(String start, String end, int grace) => 'Today $start – $end · $grace min grace';
  static String noShiftToday(String days) => 'No shift today ($days)';
  static const noSchedule = 'No schedule assigned';
  static const gpsOff = 'Location is off';
  static const gpsOffHelp = "Turn on your phone's location.";
  static const noLocationPermission = 'Location permission needed';
  static const noLocationPermissionForever = 'Allow location for PinPunch in Settings.';
  static const noLocationPermissionHelp = 'PinPunch needs your location to punch in.';
  static const turnOnGps = 'Turn on location';
  static const allowLocation = 'Allow location';
  static const searchingGps = 'Finding your location…';
  static String siteRadius(String r) => 'Job site radius: $r';
  static const onSite = "You're on site";
  static const offSite = "You're off site";
  static String fromCenter(String d, String r) => '$d from the center · $r radius';
  static const weakGps = 'Weak GPS signal';
  static String weakGpsHelp(String acc) => 'Accuracy ± $acc. Move to an open area.';
  static const todaysPunches = "Today's punches";
  static const noPunchesYet = "You haven't punched today.";
  static const sentOffline = 'Sent after offline';
  static String signOutPending(int n) =>
      'You have $n punch(es) not sent yet. They will be sent the next time you sign in on this phone.';
  static const signOutBody = "You'll need your password to sign back in.";

  // Worker outcomes
  static const locationUnavailable = 'Location unavailable';
  static const locationUnavailableHelp = 'Turn on location and allow PinPunch to use it.';
  static const noGpsFix = 'No GPS signal';
  static const noGpsFixHelp = 'Move to an open area, wait a few seconds and try again.';
  static const couldNotSave = "Couldn't save the punch";
  static const queueFull = 'Too many punches waiting to send. Connect to the internet to send them.';
  static const notAccepted = 'Punch not accepted';
  static String savedOffline(bool isIn) => '${isIn ? 'Punch-in' : 'Punch-out'} saved offline';
  static const savedOfflineHelp = 'It will be sent automatically when you have signal. The punch time is kept.';
  static String recorded(bool isIn) => isIn ? "You're punched in" : "You're punched out";
  static String notRecorded(bool isIn) => isIn ? 'Punch-in not recorded' : 'Punch-out not recorded';
  static const recordedLate = 'Recorded as late.';
  static const recordedEarly = 'Recorded before the end of your shift.';
  static const recordedUnscheduled = 'Recorded outside your shift.';
  static const recordedOnTime = 'On time. Nice work!';

  // Labels
  static const onTime = 'On time';
  static const late = 'Late';
  static const leftEarly = 'Left early';
  static const offShift = 'Off shift';
  static const rejectedLabel = 'Rejected';
  static const absent = 'Absent';
  static const expected = 'Expected';
  static const dayOff = 'Day off';
  static const inLabel = 'In';
  static const outLabel = 'Out';
  static const punchInLabel = 'Punch-in';
  static const punchOutLabel = 'Punch-out';

  // Supervisor shell
  static const navToday = 'Today';
  static const navSites = 'Job sites';
  static const navCrew = 'Crew';
  static const navReports = 'Reports';

  // Today
  static const todayTitle = "Today's attendance";
  static const attendanceTitle = 'Attendance';
  static String todayDate(String d) => 'Today, $d';
  static const allSites = 'All job sites';
  static const noScheduledCrew = 'No crew members scheduled';
  static const noScheduledCrewHelp = 'Assign a job site and schedule to each crew member in Crew.';
  static const nobodyInFilter = 'Nobody matches this filter';
  static String shiftLine(String site, String start, String end) => '$site · shift $start–$end';
  static const arrivedOffline = 'Punched in offline';
  static String rejectedAttempts(int n) => n == 1 ? '1 rejected attempt' : '$n rejected attempts';

  // Job sites
  static const newSite = 'New job site';
  static const editSite = 'Edit job site';
  static const noSites = 'No job sites yet';
  static const noSitesHelp = 'Create a job site by placing it on the map and setting how far from it crews can punch in.';
  static const createFirstSite = 'Create your first job site';
  static const inactive = 'Inactive';
  static String radius(String r) => 'Radius $r';
  static const siteName = 'Job site name *';
  static const siteNameRequired = 'Enter a name (2 characters or more)';
  static const address = 'Address or landmark';
  static const siteCenter = 'Job site center';
  static const siteCenterHelp = 'Tap the map or type the coordinates.';
  static const latitude = 'Latitude';
  static const longitude = 'Longitude';
  static const useMyLocation = 'Use my current location';
  static const myLocationFailed = "Couldn't get your location.";
  static const locationDenied = 'Location permission denied.';
  static const tapMapFirst = 'Tap the map to set the job site center.';
  static String allowedRadius(String r) => 'Punch-in radius: $r';
  static const radiusHelp = 'Crews can only punch in inside this circle. Recommended: 150–500 ft.';
  static const siteActive = 'Active job site';
  static const siteActiveHelp = "An inactive job site doesn't accept punches.";
  static const mapSemantics = 'Job site map. Tap to set the center.';

  // Crew
  static const newCrewMember = 'New crew member';
  static const searchCrew = 'Search by name or ID';
  static const noCrew = 'No crew members yet';
  static const noCrewHelp = 'Add your crew and assign them a job site and schedule.';
  static const noResults = 'No results';
  static const supervisor = 'Supervisor';
  static const crewMember = 'Crew member';
  static const noScheduleShort = 'No schedule';
  static const inactiveMember = 'Inactive';
  static const details = 'Details';
  static const employeeId = 'Employee ID or username *';
  static const employeeIdHelp = 'Used to sign in. Cannot be changed later.';
  static const employeeIdInvalid = '3 to 32 letters, digits, dots or dashes';
  static const fullName = 'Full name *';
  static const fullNameRequired = 'Enter the full name';
  static const initialPassword = 'Initial password *';
  static const passwordMin = 'At least 6 characters.';
  static const passwordMinError = 'At least 6 characters';
  static const active = 'Active';
  static const activeHelp = "Inactive people can't sign in.";
  static const changePassword = 'Change password';
  static const newPassword = 'New password';
  static const newPasswordLabel = 'Password (6+ characters)';
  static const savePassword = 'Save password';
  static const passwordUpdated = 'Password updated.';
  static const createMember = 'Add crew member';
  static const saveDetails = 'Save details';
  static String memberCreated(bool worker) => 'Crew member added.${worker ? ' Now assign a job site and schedule.' : ''}';
  static const siteAndSchedule = 'Job site & schedule';
  static const jobSiteRequired = 'Job site *';
  static String startAt(String t) => 'Start $t';
  static String endAt(String t) => 'End $t';
  static const overnight = 'Overnight shift: ends the next day';
  static const workDays = 'Work days';
  static String grace(int m) => 'Grace period: $m min';
  static String graceSemantics(int m) => '$m minutes grace period';
  static const graceHelp =
      'Punching in after start + grace counts as late; punching out before end − grace counts as leaving early.';
  static const saveSchedule = 'Save schedule';
  static const scheduleSaved = 'Schedule saved.';
  static const removeSchedule = 'Remove schedule';
  static const removeScheduleQuestion = 'Remove schedule?';
  static const removeScheduleBody = "This person won't be able to punch in until they get a new one.";
  static const remove = 'Remove';
  static const scheduleRemoved = 'Schedule removed.';
  static const selectSite = 'Select a job site.';
  static const selectDay = 'Select at least one day.';
  static const startEndDiffer = 'Start and end times must be different.';

  // Reports
  static const reportsTitle = 'Reports';
  static const copyCsv = 'Copy table for Excel';
  static const reportPeriod = 'Report period (62 days max)';
  static const onlyIssues = 'Issues only';
  static const noPunchesInPeriod = 'No punches in this period';
  static const noSite = 'No job site';
  static const offline = 'Offline';
  static const onSiteBadge = 'On site';
  static String csvCopied(int n) => 'Table copied ($n rows). Paste it into Excel or Google Sheets.';

  // Pay (shared)
  static const hourlyRate = 'Hourly rate';
  static const perHour = '/hr';
  static const hourlyRateHelp = 'Gross pay per hour. Over 40 hours a week is paid at 1.5×.';
  static const hourlyRateInvalid = r'Enter an amount like 18.50 (up to $1,000)';
  static const regular = 'Regular';
  static String overtime(String h) => 'Overtime $h (1.5×)';
  static const overtimeLabel = 'Overtime (1.5×)';
  static const rateLabel = 'Rate';
  static const grossLabel = 'Gross pay';
  static const estGross = 'Estimated gross pay';
  static const noRate = 'No hourly rate';
  static const grossDisclaimer = 'Gross pay before taxes and deductions. Your paycheck may be lower.';
  static String missingPunchOuts(int n) =>
      n == 1 ? '1 shift without punch-out (not counted)' : '$n shifts without punch-out (not counted)';
  static const stillPunchedIn = 'Punched in — time still adding up';
  static String paidOn(String day) => 'Paid $day';
  static String payday(String day) => 'Payday $day';
  static const inProgressWeek = 'Week in progress';

  // My pay (crew)
  static const navPunch = 'Punch';
  static const navMyPay = 'My pay';
  static const myPayTitle = 'My pay';
  static const nextPaycheck = 'Next paycheck';
  static const thisWeekSoFar = 'This week so far';
  static String forWeek(String range, String hours) => 'For $range · $hours worked';
  static const thisWeek = 'This week';
  static const noTimeYet = 'No time this week yet. Punch in at your job site to start.';
  static const rateNotSet = "Your hourly rate isn't set yet. Ask your supervisor.";
  static const missingPunchOutHelp = 'Ask your supervisor to fix shifts without a punch-out so they get paid.';
  static const pastPaychecks = 'Past paychecks';
  static const noPaychecksYet = 'Paid weeks will show up here.';

  // Payroll (supervisor)
  static const navPayroll = 'Payroll';
  static const payrollTitle = 'Payroll';
  static const previousWeek = 'Previous week';
  static const nextWeek = 'Next week';
  static String crewCount(int n) => n == 1 ? '1 crew member' : '$n crew members';
  static String hoursTotal(String h) => '$h worked';
  static const markAsPaid = 'Mark as paid';
  static String markPaidQuestion(String range) => 'Mark $range as paid?';
  static String markPaidBody(String total) =>
      "Total gross: $total. Amounts are frozen and crew members see this week as paid. This can't be undone.";
  static const paidOnLabel = 'Paid on';
  static String markedPaid(String range) => '$range marked as paid.';
  static const weekNotOver = 'You can mark this week as paid after it ends on Sunday.';
  static const noCrewInWeek = 'No crew time this week';
  static const noCrewInWeekHelp = 'Hours appear here as crew members punch in and out.';
  static String withoutRate(int n) => n == 1 ? '1 crew member without hourly rate' : '$n crew members without hourly rate';
  static const setRatesFirst = 'Set the hourly rate in Crew before marking this week as paid.';
}
