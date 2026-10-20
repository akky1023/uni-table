// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get databaseTooLarge =>
      'The database exceeds the limit (32 MiB or 100,000 rows in total).';

  @override
  String get unsafeDatabaseSchema =>
      'This database cannot be opened because its structure is unsafe.';

  @override
  String get storageFileTooLarge => 'The file exceeds the size limit (32 MiB).';

  @override
  String get appName => 'UniTable';

  @override
  String get invalidDatabase =>
      'This is not a UniTable database. The original file has not been changed.';

  @override
  String get unsupportedDatabaseVersion =>
      'This database version is not supported.';

  @override
  String get databaseIntegrityFailed => 'The database integrity check failed.';

  @override
  String termNumber(Object arg0) {
    return 'Term $arg0';
  }

  @override
  String get selectMultiplePeriods => 'Select at least two periods.';

  @override
  String get selectSamePeriodKind => 'Select periods of the same type.';

  @override
  String get fileAlreadyExists => 'A file already exists at this destination.';

  @override
  String get selectDatabaseFirst => 'Select a .unitable file first.';

  @override
  String workingCopyFile(Object arg0) {
    return 'Opened the working copy because the selected file could not be read: $arg0';
  }

  @override
  String get recoveredChanges =>
      'Recovered unsaved changes from the local working database. Please retry saving to the selected folder.';

  @override
  String workingCopyFolder(Object arg0) {
    return 'Opened the local working copy because the selected folder could not be read: $arg0';
  }

  @override
  String get databaseNotFound =>
      'The selected .unitable file was not found. Please select it again.';

  @override
  String get noOverwrite => 'Existing files will not be overwritten.';

  @override
  String get selectUnitableFile => 'Select a .unitable file.';

  @override
  String get emptyFile => 'Cannot open an empty file.';

  @override
  String externalSaveFailed(Object arg0) {
    return 'Saved on this device, but could not save to the selected folder: $arg0';
  }

  @override
  String get unspecified => 'Not specified';

  @override
  String get closurePeriod => 'Closure period';

  @override
  String get teachingPeriod => 'Teaching period';

  @override
  String get firstSemester => 'First semester';

  @override
  String get secondSemester => 'Second semester';

  @override
  String quarterNumber(Object arg0) {
    return 'Quarter $arg0';
  }

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String classNoticeBody(Object arg0, Object arg1) {
    return 'Starts at $arg0 · Room: $arg1';
  }

  @override
  String get checkAssignments => 'Check assignments';

  @override
  String checkAssignmentsBody(Object arg0) {
    return 'Were there any assignments for $arg0?';
  }

  @override
  String deadlineNoticeBody(Object arg0, Object arg1, Object arg2) {
    return 'Due $arg0 $arg1 · $arg2';
  }

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get notificationChannel => 'Courses and assignments';

  @override
  String get notificationChannelDescription =>
      'Classroom reminders and assignment deadlines';

  @override
  String get addAssignment => 'Add assignment';

  @override
  String get testApkOnly => 'Notification tests are available in the test APK.';

  @override
  String get testNoticeTitle => 'Check assignments (notification test)';

  @override
  String get windowsNotificationsRequireMsix =>
      'Windows notifications require the MSIX edition. Build and install it as an MSIX package.';

  @override
  String scheduledNotices(Object arg0, Object arg1, Object arg2, Object arg3) {
    return '$arg0 notifications scheduled$arg1$arg2$arg3';
  }

  @override
  String notificationSetupFailed(Object arg0) {
    return 'Could not configure notifications: $arg0';
  }

  @override
  String get hidePast => 'Hide past dates';

  @override
  String get showPast => 'Show past dates';

  @override
  String get basic => 'Basic';

  @override
  String get background => 'Background';

  @override
  String get text => 'Text';

  @override
  String get mutedText => 'Muted text';

  @override
  String get accent => 'Accent';

  @override
  String get onAccent => 'Text on accent';

  @override
  String get menuBackground => 'Menu background';

  @override
  String get inputField => 'Input field';

  @override
  String get popup => 'Popup';

  @override
  String get selection => 'Selection';

  @override
  String get selectionText => 'Selection text';

  @override
  String get divider => 'Divider';

  @override
  String get holidayText => 'Holiday and closure text';

  @override
  String get timetable => 'Timetable';

  @override
  String get freeTime => 'Free time';

  @override
  String get course => 'Course';

  @override
  String get exam => 'Exam';

  @override
  String get oneOffClass => 'One-off class';

  @override
  String get replacementClass => 'Replacement class';

  @override
  String get closure => 'Closed day';

  @override
  String get pastDates => 'Past dates';

  @override
  String get assignments => 'Assignments';

  @override
  String get selectedAssignment => 'Selected assignment';

  @override
  String get annualCalendar => 'Calendar';

  @override
  String get examDay => 'Day with an exam';

  @override
  String get replacementActive => 'Replacement day with classes';

  @override
  String get activeDay => 'Day with classes';

  @override
  String get nationalHoliday => 'Japanese public holiday';

  @override
  String get holiday => 'Non-teaching day';

  @override
  String get examPeriod => 'Exam period';

  @override
  String get replacementDay => 'Replacement day';

  @override
  String get definedHoliday => 'Day matching the non-teaching day settings';

  @override
  String colorNumber(Object arg0) {
    return 'Color $arg0';
  }

  @override
  String get opacity => 'Opacity';

  @override
  String get requiredField => 'Enter a value.';

  @override
  String get integerRange => 'Enter an integer from -1 to 2147483647.';

  @override
  String get selectDate => 'Select date';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get pickDate => 'Choose date';

  @override
  String get pickTime => 'Choose time';

  @override
  String get dateTimeFormat => 'Enter a date and time as YYYY-MM-DD HH:mm.';

  @override
  String get dateRequired => 'Choose a date.';

  @override
  String get saveChanges => 'Save changes?';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get save => 'Save';

  @override
  String get confirmDelete => 'Delete?';

  @override
  String get back => 'Back';

  @override
  String get delete => 'Delete';

  @override
  String get saving => 'Saving…';

  @override
  String hoursBefore(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String daysBefore(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String weeksBefore(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 weeks before',
      one: '1 week before',
    );
    return '$_temp0';
  }

  @override
  String weeksBeforeAt(num arg0, Object arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 weeks before at $arg1',
      one: '1 week before at $arg1',
    );
    return '$_temp0';
  }

  @override
  String daysBeforeAt(num arg0, Object arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 days before at $arg1',
      one: '1 day before at $arg1',
    );
    return '$_temp0';
  }

  @override
  String previousSundayAt(Object arg0) {
    return 'Previous Sunday at $arg0';
  }

  @override
  String previousHolidayAt(Object arg0) {
    return 'Previous non-teaching day at $arg0';
  }

  @override
  String holidaysBefore(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 non-teaching days before',
      one: '1 non-teaching day before',
    );
    return '$_temp0';
  }

  @override
  String fixedNoticeTime(Object arg0) {
    return 'At $arg0';
  }

  @override
  String get unknownNotification => 'Unknown notification';

  @override
  String get notificationTiming => 'Notification timing';

  @override
  String get hoursBeforeUnit => 'hours before';

  @override
  String get daysBeforeUnit => 'days before';

  @override
  String get weeksBeforeUnit => 'weeks before';

  @override
  String get holidaysBeforeUnit => 'non-teaching days before';

  @override
  String get atTime => 'at';

  @override
  String get deadlineTimeHint => 'Uses the deadline time if left blank';

  @override
  String get pickNotificationTime => 'Choose notification time';

  @override
  String get holidaysBeforeHelp =>
      'Counts non-teaching days before the due date and notifies at the deadline time. You can choose which days count in Settings.';

  @override
  String get notificationOffsetRange =>
      'Enter at least 1 for non-teaching days, or at least 0 for other options.';

  @override
  String get timeFormat => 'Enter a time from 00:00 to 23:59.';

  @override
  String get testNeedsCourse =>
      'Add at least one course to test notifications.';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required.';

  @override
  String get testNotificationSent => 'Test notification sent.';

  @override
  String testNotificationScheduled(Object arg0) {
    return 'Test notification scheduled in $arg0 seconds. You can close the app to check it.';
  }

  @override
  String testNotificationFailed(Object arg0) {
    return 'Notification test failed: $arg0';
  }

  @override
  String get notificationCourseMissing =>
      'The course for this notification was not found.';

  @override
  String get finishEditingToAddAssignment =>
      'Save or discard your changes to open the assignment editor.';

  @override
  String get saveInProgress => 'Saving. Please wait and try again.';

  @override
  String get retrySaveInSettings =>
      'Could not save to the selected folder. You can retry in Settings.';

  @override
  String get settings => 'Settings';

  @override
  String get edit => 'Edit';

  @override
  String get addPeriod => 'Add period';

  @override
  String get mergePeriods => 'Merge periods';

  @override
  String get importHolidays => 'Import Japanese public holidays';

  @override
  String get close => 'Close';

  @override
  String get calendarActions => 'Calendar actions';

  @override
  String get add => 'Add';

  @override
  String get switchToView => 'Switch to view mode';

  @override
  String get switchToEdit => 'Switch to edit mode';

  @override
  String get registerCourse => 'Add course';

  @override
  String get registerOneOffClass => 'Add one-off class';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get thisWeek => 'This week';

  @override
  String get previousYear => 'Previous academic year';

  @override
  String get nextYear => 'Next academic year';

  @override
  String get createDatabase => 'Create a .unitable file';

  @override
  String get exportCopy => 'Export a copy';

  @override
  String get openDatabase => 'Open database';

  @override
  String get addTimeSlot => 'Add time slot';

  @override
  String get changeRoomNoticeTiming => 'Change classroom reminder timing';

  @override
  String get toggleRoomNotices => 'Toggle classroom reminders';

  @override
  String get assignmentNotificationSettings =>
      'Assignment notification settings';

  @override
  String get universityTimezoneSettings => 'University time zone settings';

  @override
  String get turnNotificationsOff => 'Turn notifications off';

  @override
  String get turnNotificationsOn => 'Turn notifications on';

  @override
  String get exitEditing => 'Exit editing';

  @override
  String get unsavedFolderChanges =>
      'There are unsaved changes for the selected folder.';

  @override
  String get retry => 'Retry';

  @override
  String deleteNamed(Object arg0) {
    return 'Delete $arg0?';
  }

  @override
  String get deleteThisClass => 'Delete the class in this time slot?';

  @override
  String get classLabel => 'Class';

  @override
  String get choosePeriodToEdit => 'Choose a period to edit';

  @override
  String get teachingPeriodRequired => 'Add a teaching period';

  @override
  String get teachingPeriodHelp =>
      'Add a teaching period in the academic calendar to edit the timetable.';

  @override
  String get goToCalendar => 'Open calendar';

  @override
  String get addOneOffClass => 'Add one-off class';

  @override
  String weekdayName(Object arg0) {
    return '$arg0';
  }

  @override
  String get addExam => 'Add exam';

  @override
  String get editExam => 'Edit exam';

  @override
  String get deleteExam => 'Delete exam';

  @override
  String dayAndSlot(Object arg0, Object arg1) {
    return '$arg0 · Period $arg1';
  }

  @override
  String get courseName => 'Course name';

  @override
  String get roomName => 'Room';

  @override
  String get instructorName => 'Instructor';

  @override
  String get examSlotOccupied =>
      'An exam is already scheduled in this time slot.';

  @override
  String get addCourse => 'Add course';

  @override
  String get editClass => 'Edit class';

  @override
  String get deleteClass => 'Delete class';

  @override
  String get editClassDate => 'Edit class date';

  @override
  String get editCourse => 'Edit course';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllClassDates =>
      'Delete all scheduled dates for this course?';

  @override
  String get classDate => 'Class date';

  @override
  String get addClassDate => 'Add class date';

  @override
  String get configureClassTimes => 'Add class times in Settings.';

  @override
  String timeSlotNumber(Object arg0) {
    return 'Period $arg0';
  }

  @override
  String get timeSlotRequired => 'Choose a time slot.';

  @override
  String get classDateConflict =>
      'A class is already scheduled for this date and time slot.';

  @override
  String get datesAndSlots => 'Class dates and time slots';

  @override
  String get courseDetails => 'Course details and notes';

  @override
  String get addItem => 'Add';

  @override
  String get dayChanges => 'Changes for this day';

  @override
  String get assignmentsDue => 'Assignments due';

  @override
  String get noVisibleWeekdays => 'No weekdays to display';

  @override
  String get chooseVisibleWeekdays =>
      'Choose which weekdays to display in Settings.';

  @override
  String get goToSettings => 'Open settings';

  @override
  String get daySchedule => 'Schedule for this day';

  @override
  String get changeDayAndTime => 'Change day and time';

  @override
  String courseNameValue(Object arg0) {
    return 'Course: $arg0';
  }

  @override
  String destinationValue(Object arg0) {
    return 'Submit to: $arg0';
  }

  @override
  String relatedCourseValue(Object arg0) {
    return 'Related course: $arg0';
  }

  @override
  String submissionTimeValue(Object arg0) {
    return 'Submission time: $arg0';
  }

  @override
  String get noAssignmentsDue => 'No assignments are due on this day.';

  @override
  String imageAlt(Object arg0) {
    return '[Image: $arg0]';
  }

  @override
  String roomAndInstructor(Object arg0, Object arg1) {
    return 'Room  $arg0\nInstructor  $arg1';
  }

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get courseTitle => 'Course name';

  @override
  String get courseReminderLead =>
      'Reminder minutes before class (blank: default, -1: off)';

  @override
  String get extraDateConditions => 'Additional date restrictions';

  @override
  String get optionalStartDate => 'Start date (optional)';

  @override
  String get optionalEndDate => 'End date (optional)';

  @override
  String get checkAssignmentsAfterClass =>
      'Remind me to check assignments after class';

  @override
  String get markdownNotes => 'Notes (Markdown)';

  @override
  String get endDateBeforeStart =>
      'The end date must be on or after the start date.';

  @override
  String get configureTimeSlots => 'Add time slots in Settings.';

  @override
  String get configureTeachingPeriod =>
      'Add a teaching period in the academic calendar.';

  @override
  String meetingSummary(Object arg0, Object arg1, Object arg2) {
    return '$arg0 · $arg1 · Period $arg2';
  }

  @override
  String get deleteClassDate => 'Delete this class date';

  @override
  String get classDateRequired => 'Add a class date.';

  @override
  String get chooseSlotForEachDate => 'Choose a time slot for each class date.';

  @override
  String get meetingConflict =>
      'A class already uses the same weekday, date and time slot. Choose another time slot.';

  @override
  String sessionDetails(
    Object arg0,
    Object arg1,
    Object arg2,
    Object arg3,
    Object arg4,
    Object arg5,
  ) {
    return '$arg0  Period $arg1\n$arg2–$arg3\nRoom $arg4\nInstructor $arg5';
  }

  @override
  String get cancelledOnThisDay => 'This class is cancelled on this day.';

  @override
  String replacementFor(Object arg0) {
    return 'Replacement for $arg0';
  }

  @override
  String get recurringSettings => 'Recurring settings';

  @override
  String classOnDate(Object arg0) {
    return 'Class on $arg0';
  }

  @override
  String get cancelled => 'Cancelled';

  @override
  String get optionalReplacementDate => 'Replacement date (optional)';

  @override
  String get replacementTimeSlot => 'Replacement time slot';

  @override
  String get roomOverride => 'Room for this day (blank: original)';

  @override
  String get reminderOverride =>
      'Reminder minutes before class (blank: original, -1: off)';

  @override
  String get replacementDateMustDiffer =>
      'Choose a replacement date different from the original date.';

  @override
  String assignmentsDeleted(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: 'Deleted $arg0 assignments.',
      one: 'Deleted 1 assignment.',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String itemsSelected(Object arg0) {
    return '$arg0 selected';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get done => 'Done';

  @override
  String get showCompleted => 'Show completed assignments';

  @override
  String get defaultNotifications => 'Default notifications';

  @override
  String get noAssignments => 'No assignments';

  @override
  String get addAssignmentHelp =>
      'Use the + button at the bottom right to add an assignment.';

  @override
  String get viewAssignment => 'View assignment';

  @override
  String get editAssignment => 'Edit assignment';

  @override
  String get markIncomplete => 'Mark as incomplete';

  @override
  String get markComplete => 'Mark as complete';

  @override
  String get deleteAssignment => 'Delete assignment';

  @override
  String weeksLater(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: 'In $arg0 weeks',
      one: 'In 1 week',
    );
    return '$_temp0';
  }

  @override
  String deadlineHint(Object arg0, Object arg1, Object arg2, Object arg3) {
    return 'Due $arg0, $arg1, period $arg2$arg3';
  }

  @override
  String get registerAssignment => 'Add assignment';

  @override
  String get assignmentName => 'Assignment name';

  @override
  String get deadline => 'Due date and time';

  @override
  String get chooseDeadlineFromTimetable => 'Choose due date from timetable';

  @override
  String get destination => 'Submit to';

  @override
  String get notes => 'Notes';

  @override
  String get notifications => 'Notifications';

  @override
  String get addNotification => 'Add notification';

  @override
  String get deadlineMinuteRequired =>
      'Enter the due date and time, including minutes.';

  @override
  String get notificationAfterDeadline =>
      'Notifications must be scheduled on or before the deadline.';

  @override
  String get selectDeadline => 'Select due date and time';

  @override
  String get assignmentNotificationDefaults =>
      'Default assignment notifications';

  @override
  String get assignmentNotificationDefaultsHelp =>
      'Used as defaults for new assignments. Leave empty for no default notifications.';

  @override
  String get choosePeriodDates =>
      'Select the start date, then the end date on the calendar.';

  @override
  String get cancelPeriodSelection => 'Cancel period selection';

  @override
  String get desktopCalendarHelp =>
      'Click to change a day, double-click to edit a period, or drag to add a period. Right-click for actions.';

  @override
  String get mobileCalendarHelp =>
      'Tap to change a day, long-press to edit a period, or long-press and drag to add a period.';

  @override
  String get deleteDayChanges => 'Delete changes for this day';

  @override
  String get dailyChanges => 'Daily changes';

  @override
  String get viewDayClasses => 'View classes for this day';

  @override
  String get editDayPeriod => 'Edit period for this day';

  @override
  String editNamed(Object arg0) {
    return 'Edit $arg0';
  }

  @override
  String deleteNamedAction(Object arg0) {
    return 'Delete $arg0';
  }

  @override
  String get period => 'Period';

  @override
  String get mergedPeriodName => 'Merged period name (optional)';

  @override
  String get registerPeriod => 'Add period';

  @override
  String get editPeriod => 'Edit period';

  @override
  String get type => 'Type';

  @override
  String get universityClosure => 'University closure / vacation';

  @override
  String get optionalName => 'Name (optional)';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get deleteDateRange => 'Delete this date range';

  @override
  String get addDateRange => 'Add date range';

  @override
  String universityDaySettings(Object arg0) {
    return 'University settings for $arg0';
  }

  @override
  String get universityClosed => 'University closed';

  @override
  String get optionalUniversityReplacement =>
      'Replacement date for this day (optional)';

  @override
  String get replacementTimetable => 'Replacement timetable';

  @override
  String get universityReplacementHelp =>
      'A university replacement day replaces the classes normally scheduled for that weekday.';

  @override
  String get universityReplacementMustDiffer =>
      'Choose a different replacement date.';

  @override
  String get universityReplacementConflict =>
      'The replacement date already has university settings. Choose another date.';

  @override
  String holidayDataRange(Object arg0, Object arg1) {
    return 'Bundled Japanese public holiday data covers $arg0–$arg1. Update the data to import all holidays for this academic year.';
  }

  @override
  String importHolidaysForYear(Object arg0) {
    return 'Import Japanese public holidays for academic year $arg0';
  }

  @override
  String importHolidaysConfirmation(Object arg0, Object arg1, Object arg2) {
    return 'Import $arg0 Japanese public holidays, including substitute holidays. Holidays with existing IDs will not be duplicated.\nSource: Cabinet Office of Japan ($arg1–$arg2, offline data)';
  }

  @override
  String get register => 'Register';

  @override
  String holidaysImported(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: 'Imported $arg0 public holidays.',
      one: 'Imported 1 public holiday.',
    );
    return '$_temp0';
  }

  @override
  String get general => 'General';

  @override
  String get displaySettings => 'Display';

  @override
  String get operationSettings => 'Controls';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get about => 'About this app';

  @override
  String version(Object arg0) {
    return 'Version: $arg0';
  }

  @override
  String get author => 'Creator';

  @override
  String get name => 'Name';

  @override
  String get sourceCode => 'Source code';

  @override
  String get license => 'License';

  @override
  String get files => 'Files';

  @override
  String get openUnitable => 'Open a .unitable file';

  @override
  String monthNumber(String arg0) {
    String _temp0 = intl.Intl.selectLogic(arg0, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '$arg0',
    });
    return '$_temp0';
  }

  @override
  String get weekStartsOn => 'First day of the week';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get followSystem => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get oledBackground => 'Black background for OLED';

  @override
  String get timetableDisplay => 'Timetable display';

  @override
  String get continuousDisplay => 'Continuous scrolling';

  @override
  String get timeSlotWidth => 'Time slot width';

  @override
  String get courseFontSize => 'Course name font size';

  @override
  String get roomFontSize => 'Room name font size';

  @override
  String get hiddenWeekdays => 'Weekdays hidden in timetable';

  @override
  String get advancedSettings => 'Advanced settings';

  @override
  String get colorPalette => 'Color palette';

  @override
  String get calendarPriority => 'Calendar display priority';

  @override
  String get longPressDuration => 'Long-press duration';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notificationsUnavailable =>
      'Notifications are unavailable in this edition.';

  @override
  String get notificationTest => 'Notification test (test APK only)';

  @override
  String get notificationTestHelp =>
      'Check assignment reminders and the Add assignment action. Only the latest test is scheduled.';

  @override
  String get testCourse => 'Course to test';

  @override
  String get testNow => 'Test notification now';

  @override
  String get testInThirtySeconds => 'Test notification in 30 seconds';

  @override
  String get testInFiveMinutes => 'Test notification in 5 minutes';

  @override
  String get allowExactAlarms => 'Allow exact notifications';

  @override
  String get exactAlarmHelp =>
      'Allow Alarms and reminders in device settings to reduce notification delays.';

  @override
  String get batterySettings => 'Check battery settings';

  @override
  String get batterySettingsHelp =>
      'If notifications are delayed, review battery restrictions in the app settings on your device.';

  @override
  String get notifyRoom => 'Classroom reminders';

  @override
  String minutesBeforeClass(num arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '$arg0 minutes before class',
      one: '1 minute before class',
    );
    return '$_temp0';
  }

  @override
  String get newAssignmentNotifications =>
      'Default notification timing for new assignments';

  @override
  String get holidayDefinition => 'Non-teaching day settings';

  @override
  String get universityTimezone => 'University time zone';

  @override
  String get msixSchedulingHelp =>
      'Use the MSIX edition on Windows for reliable cancellation and rescheduling of notifications.';

  @override
  String get schedulingLimit =>
      'Up to 480 upcoming notifications within the next year are scheduled. The schedule is refreshed when the app starts or resumes.';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get colorVisionSupport => 'Color vision support';

  @override
  String get strongerText => 'Stronger text contrast';

  @override
  String get backToSettings => 'Back to settings list';

  @override
  String get durationMilliseconds => 'Duration (milliseconds)';

  @override
  String get positiveMilliseconds =>
      'Enter a duration of at least 1 millisecond.';

  @override
  String get widthPixels => 'Width (px)';

  @override
  String get slotWidthRange => 'Enter a number from 40 to 600.';

  @override
  String get paletteToEdit => 'Palette to edit';

  @override
  String get teachingPeriodColors => 'Nine teaching period colors';

  @override
  String get examPeriodColors => 'Nine exam period colors';

  @override
  String colorIndex(Object arg0) {
    return 'Color $arg0';
  }

  @override
  String get resetPalette => 'Reset this palette';

  @override
  String get resetDefaults => 'Reset to defaults';

  @override
  String get specifyRgba => 'Specify RGBA';

  @override
  String get rgbaRange => 'Enter an integer from 0 to 255.';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontSizeRange => 'Enter a number from 8 to 36.';

  @override
  String get closuresAndHolidays => 'Closures and Japanese public holidays';

  @override
  String get noClassDays => 'Days without classes';

  @override
  String get onlyDaysWithoutClasses => 'Only on days without classes';

  @override
  String get roomNotifications => 'Classroom reminders';

  @override
  String get minutesBeforeStart => 'Minutes before class';

  @override
  String get nonNegativeMinutes => 'Enter 0 or more minutes.';

  @override
  String get searchRegion => 'Search region';

  @override
  String get notificationPermissionHelp =>
      'Notification permission is required. Check your device settings.';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get changeStartTime => 'Change start time';

  @override
  String get changeEndTime => 'Change end time';

  @override
  String get deleteTimeSlot => 'Delete time slot';

  @override
  String minutesValue(Object arg0) {
    return '$arg0 min';
  }

  @override
  String deleteSlotNumber(Object arg0) {
    return 'Delete period $arg0';
  }

  @override
  String slotTimeTitle(Object arg0) {
    return 'Period $arg0 times';
  }

  @override
  String startTimeValue(Object arg0) {
    return 'Start $arg0';
  }

  @override
  String endTimeValue(Object arg0) {
    return 'End $arg0';
  }

  @override
  String get endTimeAfterStart => 'The end time must be after the start time.';

  @override
  String slotTimeHelp(Object arg0, Object arg1) {
    return 'Period $arg0: $arg1 time';
  }

  @override
  String get timeSlotInUse =>
      'A class uses this time slot. Change the class first.';

  @override
  String get exportFolderOccupied =>
      'The destination already contains university.unitable. Choose an empty folder.';

  @override
  String get chooseAnotherFilename =>
      'Existing files will not be overwritten. Choose another name.';

  @override
  String get databaseExported => 'Exported a copy of the database.';

  @override
  String get chooseDatabase => 'Choose the .unitable file to use.';

  @override
  String get notRegistered => 'Not set';

  @override
  String scheduledThrough(Object arg0) {
    return '· through $arg0';
  }

  @override
  String get scheduleRefillHelp => '(refreshed when the app starts or resumes)';

  @override
  String get inexactAlarmWarning =>
      '· notifications may be delayed because exact alarms are not permitted';

  @override
  String get cancelledSuffix => '· Cancelled';

  @override
  String get replacement => 'Replacement';

  @override
  String get versionUnavailable => 'Unavailable';

  @override
  String get language => 'Language';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String namedExamPeriod(String name) {
    return '$name exams';
  }

  @override
  String get storagePickerBusy => 'A file or folder picker is already open.';

  @override
  String get storageEmptyFile => 'The file is empty.';

  @override
  String get storageVerificationFailed => 'Could not verify the saved data.';

  @override
  String get storageFolderPermission =>
      'Cannot read or write to this folder. Select it again.';

  @override
  String get storageRecoveryFailed =>
      'Could not restore the previous saved file.';

  @override
  String get storageMissingDatabase => 'university.unitable was not found.';

  @override
  String get storageEmptyDatabase => 'The database is empty.';

  @override
  String get storageNoData => 'There is no data to save.';

  @override
  String get storageCleanupFailed => 'Could not remove the previous copy.';

  @override
  String get storageRenameUnsupported =>
      'This folder does not support the file renaming needed for safe updates. Choose another local folder.';

  @override
  String get storageSaveFailed => 'Could not finish saving the database.';

  @override
  String get storageSelectFile => 'Select a .unitable file.';

  @override
  String get storageFilePermission =>
      'Select a file that can be read and written.';

  @override
  String fullWeekdayName(String arg0) {
    String _temp0 = intl.Intl.selectLogic(arg0, {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
      'other': '$arg0',
    });
    return '$_temp0';
  }

  @override
  String get examName => 'Exam name';

  @override
  String get academicYearStartsIn => 'Academic year starts in';

  @override
  String academicYearSingle(int year) {
    return 'Academic year $year';
  }

  @override
  String academicYearRange(int startYear, int endYear) {
    return 'Academic year $startYear–$endYear';
  }

  @override
  String get universitySettings => 'University settings';
}
