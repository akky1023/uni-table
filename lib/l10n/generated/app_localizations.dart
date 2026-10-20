import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @databaseTooLarge.
  ///
  /// In ja, this message translates to:
  /// **'データベースが上限（32 MiB・合計100,000件）を超えています。'**
  String get databaseTooLarge;

  /// No description provided for @unsafeDatabaseSchema.
  ///
  /// In ja, this message translates to:
  /// **'安全でないデータベース構造のため開けません。'**
  String get unsafeDatabaseSchema;

  /// No description provided for @storageFileTooLarge.
  ///
  /// In ja, this message translates to:
  /// **'ファイルがサイズ上限（32 MiB）を超えています。'**
  String get storageFileTooLarge;

  /// UniTable
  ///
  /// In ja, this message translates to:
  /// **'うに時間割'**
  String get appName;

  /// This is not a UniTable database. The original file has not been changed.
  ///
  /// In ja, this message translates to:
  /// **'うに時間割のデータベースではありません。元のファイルは変更していません。'**
  String get invalidDatabase;

  /// This database version is not supported.
  ///
  /// In ja, this message translates to:
  /// **'対応していないデータベースのバージョンです。'**
  String get unsupportedDatabaseVersion;

  /// The database integrity check failed.
  ///
  /// In ja, this message translates to:
  /// **'データベースの整合性チェックに失敗しました。'**
  String get databaseIntegrityFailed;

  /// Term {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}学期'**
  String termNumber(Object arg0);

  /// Select at least two periods.
  ///
  /// In ja, this message translates to:
  /// **'2つ以上の期間を選んでください'**
  String get selectMultiplePeriods;

  /// Select periods of the same type.
  ///
  /// In ja, this message translates to:
  /// **'同じ種類の期間を選んでください'**
  String get selectSamePeriodKind;

  /// A file already exists at this destination.
  ///
  /// In ja, this message translates to:
  /// **'保存先にファイルが存在します。'**
  String get fileAlreadyExists;

  /// Select a .unitable file first.
  ///
  /// In ja, this message translates to:
  /// **'先に.unitableファイルを指定してください'**
  String get selectDatabaseFirst;

  /// Opened the working copy because the selected file could not be read: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'指定ファイルを読み込めないため、作業用コピーを開きました: {arg0}'**
  String workingCopyFile(Object arg0);

  /// Recovered unsaved changes from the local working database. Please retry saving to the selected folder.
  ///
  /// In ja, this message translates to:
  /// **'指定フォルダーに未保存の変更を、端末内の作業用DBから復元しました。再試行してください。'**
  String get recoveredChanges;

  /// Opened the local working copy because the selected folder could not be read: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'指定フォルダーを読み込めないため、端末内の作業用コピーを開きました: {arg0}'**
  String workingCopyFolder(Object arg0);

  /// The selected .unitable file was not found. Please select it again.
  ///
  /// In ja, this message translates to:
  /// **'指定した.unitableが見つかりません。ファイルを選び直してください。'**
  String get databaseNotFound;

  /// Existing files will not be overwritten.
  ///
  /// In ja, this message translates to:
  /// **'既存のファイルは上書きしません'**
  String get noOverwrite;

  /// Select a .unitable file.
  ///
  /// In ja, this message translates to:
  /// **'.unitableファイルを選んでください'**
  String get selectUnitableFile;

  /// Cannot open an empty file.
  ///
  /// In ja, this message translates to:
  /// **'空のファイルは開けません'**
  String get emptyFile;

  /// Saved on this device, but could not save to the selected folder: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'端末内には保存済みですが、指定フォルダーへの保存に失敗しました: {arg0}'**
  String externalSaveFailed(Object arg0);

  /// Not specified
  ///
  /// In ja, this message translates to:
  /// **'未指定'**
  String get unspecified;

  /// Closure period
  ///
  /// In ja, this message translates to:
  /// **'休業期間'**
  String get closurePeriod;

  /// Teaching period
  ///
  /// In ja, this message translates to:
  /// **'講義期間'**
  String get teachingPeriod;

  /// First semester
  ///
  /// In ja, this message translates to:
  /// **'前期'**
  String get firstSemester;

  /// Second semester
  ///
  /// In ja, this message translates to:
  /// **'後期'**
  String get secondSemester;

  /// Quarter {arg0}
  ///
  /// In ja, this message translates to:
  /// **'第{arg0}クオータ'**
  String quarterNumber(Object arg0);

  /// Mon
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get monday;

  /// Tue
  ///
  /// In ja, this message translates to:
  /// **'火'**
  String get tuesday;

  /// Wed
  ///
  /// In ja, this message translates to:
  /// **'水'**
  String get wednesday;

  /// Thu
  ///
  /// In ja, this message translates to:
  /// **'木'**
  String get thursday;

  /// Fri
  ///
  /// In ja, this message translates to:
  /// **'金'**
  String get friday;

  /// Sat
  ///
  /// In ja, this message translates to:
  /// **'土'**
  String get saturday;

  /// Sun
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get sunday;

  /// Starts at {arg0} · Room: {arg1}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}から・教室 {arg1}'**
  String classNoticeBody(Object arg0, Object arg1);

  /// Check assignments
  ///
  /// In ja, this message translates to:
  /// **'課題を確認'**
  String get checkAssignments;

  /// Were there any assignments for {arg0}?
  ///
  /// In ja, this message translates to:
  /// **'{arg0}の課題はありましたか？'**
  String checkAssignmentsBody(Object arg0);

  /// Due {arg0} {arg1} · {arg2}
  ///
  /// In ja, this message translates to:
  /// **'期限 {arg0} {arg1}・{arg2}'**
  String deadlineNoticeBody(Object arg0, Object arg1, Object arg2);

  /// Notifications are off
  ///
  /// In ja, this message translates to:
  /// **'通知はオフです'**
  String get notificationsOff;

  /// Courses and assignments
  ///
  /// In ja, this message translates to:
  /// **'講義・課題'**
  String get notificationChannel;

  /// Classroom reminders and assignment deadlines
  ///
  /// In ja, this message translates to:
  /// **'講義の教室と課題の期限'**
  String get notificationChannelDescription;

  /// Add assignment
  ///
  /// In ja, this message translates to:
  /// **'課題を追加'**
  String get addAssignment;

  /// Notification tests are available in the test APK.
  ///
  /// In ja, this message translates to:
  /// **'通知テストはテストAPKで利用できます。'**
  String get testApkOnly;

  /// Check assignments (notification test)
  ///
  /// In ja, this message translates to:
  /// **'課題を確認（通知テスト）'**
  String get testNoticeTitle;

  /// Windows notifications require the MSIX edition. Build and install it as an MSIX package.
  ///
  /// In ja, this message translates to:
  /// **'Windowsの通知はMSIX版で有効にできます。MSIXとしてビルド・インストールしてください。'**
  String get windowsNotificationsRequireMsix;

  /// {arg0} notifications scheduled{arg1}{arg2}{arg3}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}件を予約済み{arg1}{arg2}{arg3}'**
  String scheduledNotices(Object arg0, Object arg1, Object arg2, Object arg3);

  /// Could not configure notifications: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'通知の設定に失敗しました: {arg0}'**
  String notificationSetupFailed(Object arg0);

  /// Hide past dates
  ///
  /// In ja, this message translates to:
  /// **'過去を隠す'**
  String get hidePast;

  /// Show past dates
  ///
  /// In ja, this message translates to:
  /// **'過去を表示'**
  String get showPast;

  /// Basic
  ///
  /// In ja, this message translates to:
  /// **'基本'**
  String get basic;

  /// Background
  ///
  /// In ja, this message translates to:
  /// **'背景'**
  String get background;

  /// Text
  ///
  /// In ja, this message translates to:
  /// **'文字'**
  String get text;

  /// Muted text
  ///
  /// In ja, this message translates to:
  /// **'薄い文字'**
  String get mutedText;

  /// Accent
  ///
  /// In ja, this message translates to:
  /// **'アクセント'**
  String get accent;

  /// Text on accent
  ///
  /// In ja, this message translates to:
  /// **'アクセント上の文字'**
  String get onAccent;

  /// Menu background
  ///
  /// In ja, this message translates to:
  /// **'メニューの背景'**
  String get menuBackground;

  /// Input field
  ///
  /// In ja, this message translates to:
  /// **'入力欄'**
  String get inputField;

  /// Popup
  ///
  /// In ja, this message translates to:
  /// **'ポップアップ'**
  String get popup;

  /// Selection
  ///
  /// In ja, this message translates to:
  /// **'選択部分'**
  String get selection;

  /// Selection text
  ///
  /// In ja, this message translates to:
  /// **'選択部分の文字'**
  String get selectionText;

  /// Divider
  ///
  /// In ja, this message translates to:
  /// **'区切り線'**
  String get divider;

  /// Holiday and closure text
  ///
  /// In ja, this message translates to:
  /// **'祝日・休業日の文字'**
  String get holidayText;

  /// Timetable
  ///
  /// In ja, this message translates to:
  /// **'時間割'**
  String get timetable;

  /// Free time
  ///
  /// In ja, this message translates to:
  /// **'空き時間'**
  String get freeTime;

  /// Course
  ///
  /// In ja, this message translates to:
  /// **'講義'**
  String get course;

  /// Exam
  ///
  /// In ja, this message translates to:
  /// **'試験'**
  String get exam;

  /// One-off class
  ///
  /// In ja, this message translates to:
  /// **'単発講義'**
  String get oneOffClass;

  /// Replacement class
  ///
  /// In ja, this message translates to:
  /// **'代替日の講義'**
  String get replacementClass;

  /// Closed day
  ///
  /// In ja, this message translates to:
  /// **'休業日'**
  String get closure;

  /// Past dates
  ///
  /// In ja, this message translates to:
  /// **'過去の日付'**
  String get pastDates;

  /// Assignments
  ///
  /// In ja, this message translates to:
  /// **'課題'**
  String get assignments;

  /// Selected assignment
  ///
  /// In ja, this message translates to:
  /// **'選択中の課題'**
  String get selectedAssignment;

  /// Calendar
  ///
  /// In ja, this message translates to:
  /// **'年間予定'**
  String get annualCalendar;

  /// Day with an exam
  ///
  /// In ja, this message translates to:
  /// **'試験がある日'**
  String get examDay;

  /// Replacement day with classes
  ///
  /// In ja, this message translates to:
  /// **'代替日・講義あり'**
  String get replacementActive;

  /// Day with classes
  ///
  /// In ja, this message translates to:
  /// **'講義がある日'**
  String get activeDay;

  /// Japanese public holiday
  ///
  /// In ja, this message translates to:
  /// **'祝日'**
  String get nationalHoliday;

  /// Non-teaching day
  ///
  /// In ja, this message translates to:
  /// **'休日'**
  String get holiday;

  /// Exam period
  ///
  /// In ja, this message translates to:
  /// **'試験期間'**
  String get examPeriod;

  /// Replacement day
  ///
  /// In ja, this message translates to:
  /// **'代替日'**
  String get replacementDay;

  /// Day matching the non-teaching day settings
  ///
  /// In ja, this message translates to:
  /// **'休日の定義に当てはまる日'**
  String get definedHoliday;

  /// Color {arg0}
  ///
  /// In ja, this message translates to:
  /// **'色 {arg0}'**
  String colorNumber(Object arg0);

  /// Opacity
  ///
  /// In ja, this message translates to:
  /// **'透明度'**
  String get opacity;

  /// Enter a value.
  ///
  /// In ja, this message translates to:
  /// **'入力してください'**
  String get requiredField;

  /// Enter an integer from -1 to 2147483647.
  ///
  /// In ja, this message translates to:
  /// **'-1～2147483647の整数を入力してください'**
  String get integerRange;

  /// Select date
  ///
  /// In ja, this message translates to:
  /// **'日付を選択'**
  String get selectDate;

  /// Cancel
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// Confirm
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get confirm;

  /// Choose date
  ///
  /// In ja, this message translates to:
  /// **'日付を選ぶ'**
  String get pickDate;

  /// Choose time
  ///
  /// In ja, this message translates to:
  /// **'時刻を選ぶ'**
  String get pickTime;

  /// Enter a date and time as YYYY-MM-DD HH:mm.
  ///
  /// In ja, this message translates to:
  /// **'YYYY-MM-DD HH:mmで入力してください'**
  String get dateTimeFormat;

  /// Choose a date.
  ///
  /// In ja, this message translates to:
  /// **'日付を選んでください'**
  String get dateRequired;

  /// Save changes?
  ///
  /// In ja, this message translates to:
  /// **'変更を保存しますか？'**
  String get saveChanges;

  /// Discard changes
  ///
  /// In ja, this message translates to:
  /// **'編集を破棄'**
  String get discardChanges;

  /// Save
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// Delete?
  ///
  /// In ja, this message translates to:
  /// **'削除しますか？'**
  String get confirmDelete;

  /// Back
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// Delete
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// Saving…
  ///
  /// In ja, this message translates to:
  /// **'保存中…'**
  String get saving;

  /// {arg0} hour(s) before
  ///
  /// In ja, this message translates to:
  /// **'{arg0}時間前'**
  String hoursBefore(num arg0);

  /// {arg0} day(s) before
  ///
  /// In ja, this message translates to:
  /// **'{arg0}日前'**
  String daysBefore(num arg0);

  /// {arg0} week(s) before
  ///
  /// In ja, this message translates to:
  /// **'{arg0}週間前'**
  String weeksBefore(num arg0);

  /// {arg0} week(s) before at {arg1}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}週間前の {arg1}'**
  String weeksBeforeAt(num arg0, Object arg1);

  /// {arg0} day(s) before at {arg1}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}日前の {arg1}'**
  String daysBeforeAt(num arg0, Object arg1);

  /// Previous Sunday at {arg0}
  ///
  /// In ja, this message translates to:
  /// **'直前の日曜日の {arg0}'**
  String previousSundayAt(Object arg0);

  /// Previous non-teaching day at {arg0}
  ///
  /// In ja, this message translates to:
  /// **'直前の休日の {arg0}'**
  String previousHolidayAt(Object arg0);

  /// {arg0} non-teaching day(s) before
  ///
  /// In ja, this message translates to:
  /// **'{arg0}回前の休日'**
  String holidaysBefore(num arg0);

  /// At {arg0}
  ///
  /// In ja, this message translates to:
  /// **'指定日時 {arg0}'**
  String fixedNoticeTime(Object arg0);

  /// Unknown notification
  ///
  /// In ja, this message translates to:
  /// **'不明な通知'**
  String get unknownNotification;

  /// Notification timing
  ///
  /// In ja, this message translates to:
  /// **'通知タイミング'**
  String get notificationTiming;

  /// hour(s) before
  ///
  /// In ja, this message translates to:
  /// **'時間前'**
  String get hoursBeforeUnit;

  /// day(s) before
  ///
  /// In ja, this message translates to:
  /// **'日前'**
  String get daysBeforeUnit;

  /// week(s) before
  ///
  /// In ja, this message translates to:
  /// **'週間前'**
  String get weeksBeforeUnit;

  /// non-teaching day(s) before
  ///
  /// In ja, this message translates to:
  /// **'回前の休日'**
  String get holidaysBeforeUnit;

  /// at
  ///
  /// In ja, this message translates to:
  /// **'の'**
  String get atTime;

  /// Uses the deadline time if left blank
  ///
  /// In ja, this message translates to:
  /// **'省略すると期限と同じ時刻'**
  String get deadlineTimeHint;

  /// Choose notification time
  ///
  /// In ja, this message translates to:
  /// **'通知時刻を選ぶ'**
  String get pickNotificationTime;

  /// Counts non-teaching days before the due date and notifies at the deadline time. You can choose which days count in Settings.
  ///
  /// In ja, this message translates to:
  /// **'期限の日より前の休日を数え、期限と同じ時刻に通知します。休日に含める日は設定で変更できます。'**
  String get holidaysBeforeHelp;

  /// Enter at least 1 for non-teaching days, or at least 0 for other options.
  ///
  /// In ja, this message translates to:
  /// **'休日は1以上、それ以外は0以上を指定してください'**
  String get notificationOffsetRange;

  /// Enter a time from 00:00 to 23:59.
  ///
  /// In ja, this message translates to:
  /// **'00:00～23:59で入力してください'**
  String get timeFormat;

  /// Add at least one course to test notifications.
  ///
  /// In ja, this message translates to:
  /// **'通知テストには講義を1件以上登録してください。'**
  String get testNeedsCourse;

  /// Notification permission is required.
  ///
  /// In ja, this message translates to:
  /// **'通知の許可が必要です。'**
  String get notificationPermissionRequired;

  /// Test notification sent.
  ///
  /// In ja, this message translates to:
  /// **'テスト通知を送信しました。'**
  String get testNotificationSent;

  /// Test notification scheduled in {arg0} seconds. You can close the app to check it.
  ///
  /// In ja, this message translates to:
  /// **'{arg0}秒後のテスト通知を予約しました。画面を閉じて確認できます。'**
  String testNotificationScheduled(Object arg0);

  /// Notification test failed: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'通知テストに失敗しました: {arg0}'**
  String testNotificationFailed(Object arg0);

  /// The course for this notification was not found.
  ///
  /// In ja, this message translates to:
  /// **'通知の講義が見つかりません。'**
  String get notificationCourseMissing;

  /// Save or discard your changes to open the assignment editor.
  ///
  /// In ja, this message translates to:
  /// **'編集中の変更を保存または破棄すると、課題追加画面を開きます。'**
  String get finishEditingToAddAssignment;

  /// Saving. Please wait and try again.
  ///
  /// In ja, this message translates to:
  /// **'保存中です。少し待ってからお試しください。'**
  String get saveInProgress;

  /// Could not save to the selected folder. You can retry in Settings.
  ///
  /// In ja, this message translates to:
  /// **'指定フォルダーに保存できませんでした。設定画面から再試行できます。'**
  String get retrySaveInSettings;

  /// Settings
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// Edit
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// Add period
  ///
  /// In ja, this message translates to:
  /// **'期間を追加'**
  String get addPeriod;

  /// Merge periods
  ///
  /// In ja, this message translates to:
  /// **'期間をまとめる'**
  String get mergePeriods;

  /// Import Japanese public holidays
  ///
  /// In ja, this message translates to:
  /// **'祝日を休日にする'**
  String get importHolidays;

  /// Close
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// Calendar actions
  ///
  /// In ja, this message translates to:
  /// **'年間予定の操作'**
  String get calendarActions;

  /// Add
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get add;

  /// Switch to view mode
  ///
  /// In ja, this message translates to:
  /// **'閲覧モードに切り替え'**
  String get switchToView;

  /// Switch to edit mode
  ///
  /// In ja, this message translates to:
  /// **'編集モードに切り替え'**
  String get switchToEdit;

  /// Add course
  ///
  /// In ja, this message translates to:
  /// **'講義を登録'**
  String get registerCourse;

  /// Add one-off class
  ///
  /// In ja, this message translates to:
  /// **'単発講義を登録'**
  String get registerOneOffClass;

  /// Previous week
  ///
  /// In ja, this message translates to:
  /// **'前の週'**
  String get previousWeek;

  /// Next week
  ///
  /// In ja, this message translates to:
  /// **'次の週'**
  String get nextWeek;

  /// This week
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get thisWeek;

  /// Previous academic year
  ///
  /// In ja, this message translates to:
  /// **'前の年度'**
  String get previousYear;

  /// Next academic year
  ///
  /// In ja, this message translates to:
  /// **'次の年度'**
  String get nextYear;

  /// Create a .unitable file
  ///
  /// In ja, this message translates to:
  /// **'新しい.unitableを作成'**
  String get createDatabase;

  /// Export a copy
  ///
  /// In ja, this message translates to:
  /// **'コピーを書き出す'**
  String get exportCopy;

  /// Open database
  ///
  /// In ja, this message translates to:
  /// **'データベースを開く'**
  String get openDatabase;

  /// Add time slot
  ///
  /// In ja, this message translates to:
  /// **'コマを追加'**
  String get addTimeSlot;

  /// Change classroom reminder timing
  ///
  /// In ja, this message translates to:
  /// **'教室の通知タイミングを変更'**
  String get changeRoomNoticeTiming;

  /// Toggle classroom reminders
  ///
  /// In ja, this message translates to:
  /// **'教室通知をオン／オフ'**
  String get toggleRoomNotices;

  /// Assignment notification settings
  ///
  /// In ja, this message translates to:
  /// **'課題の通知設定'**
  String get assignmentNotificationSettings;

  /// University time zone settings
  ///
  /// In ja, this message translates to:
  /// **'大学のタイムゾーン設定'**
  String get universityTimezoneSettings;

  /// Turn notifications off
  ///
  /// In ja, this message translates to:
  /// **'通知をオフにする'**
  String get turnNotificationsOff;

  /// Turn notifications on
  ///
  /// In ja, this message translates to:
  /// **'通知をオンにする'**
  String get turnNotificationsOn;

  /// Exit editing
  ///
  /// In ja, this message translates to:
  /// **'編集から戻る'**
  String get exitEditing;

  /// There are unsaved changes for the selected folder.
  ///
  /// In ja, this message translates to:
  /// **'指定フォルダーに未保存の変更があります。'**
  String get unsavedFolderChanges;

  /// Retry
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// Delete {arg0}?
  ///
  /// In ja, this message translates to:
  /// **'{arg0}を削除しますか？'**
  String deleteNamed(Object arg0);

  /// Delete the class in this time slot?
  ///
  /// In ja, this message translates to:
  /// **'この時間の授業を削除しますか？'**
  String get deleteThisClass;

  /// Class
  ///
  /// In ja, this message translates to:
  /// **'授業'**
  String get classLabel;

  /// Choose a period to edit
  ///
  /// In ja, this message translates to:
  /// **'編集する期間'**
  String get choosePeriodToEdit;

  /// Add a teaching period
  ///
  /// In ja, this message translates to:
  /// **'講義期間を登録してください'**
  String get teachingPeriodRequired;

  /// Add a teaching period in the academic calendar to edit the timetable.
  ///
  /// In ja, this message translates to:
  /// **'年間予定で講義期間を登録すると、時間割を編集できます。'**
  String get teachingPeriodHelp;

  /// Open calendar
  ///
  /// In ja, this message translates to:
  /// **'年間予定へ'**
  String get goToCalendar;

  /// Add one-off class
  ///
  /// In ja, this message translates to:
  /// **'単発講義を追加'**
  String get addOneOffClass;

  /// {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}曜日'**
  String weekdayName(Object arg0);

  /// Add exam
  ///
  /// In ja, this message translates to:
  /// **'試験を登録'**
  String get addExam;

  /// Edit exam
  ///
  /// In ja, this message translates to:
  /// **'試験を編集'**
  String get editExam;

  /// Delete exam
  ///
  /// In ja, this message translates to:
  /// **'試験を削除'**
  String get deleteExam;

  /// {arg0} · Period {arg1}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}・{arg1}限'**
  String dayAndSlot(Object arg0, Object arg1);

  /// Course name
  ///
  /// In ja, this message translates to:
  /// **'科目名'**
  String get courseName;

  /// Room
  ///
  /// In ja, this message translates to:
  /// **'教室名'**
  String get roomName;

  /// Instructor
  ///
  /// In ja, this message translates to:
  /// **'教員名'**
  String get instructorName;

  /// An exam is already scheduled in this time slot.
  ///
  /// In ja, this message translates to:
  /// **'この時限には試験が登録されています'**
  String get examSlotOccupied;

  /// Add course
  ///
  /// In ja, this message translates to:
  /// **'講義を追加'**
  String get addCourse;

  /// Edit class
  ///
  /// In ja, this message translates to:
  /// **'授業を編集'**
  String get editClass;

  /// Delete class
  ///
  /// In ja, this message translates to:
  /// **'授業を削除'**
  String get deleteClass;

  /// Edit class date
  ///
  /// In ja, this message translates to:
  /// **'実施日を編集'**
  String get editClassDate;

  /// Edit course
  ///
  /// In ja, this message translates to:
  /// **'講義を編集'**
  String get editCourse;

  /// Delete all
  ///
  /// In ja, this message translates to:
  /// **'まとめて削除'**
  String get deleteAll;

  /// Delete all scheduled dates for this course?
  ///
  /// In ja, this message translates to:
  /// **'この講義の実施日をまとめて削除しますか？'**
  String get deleteAllClassDates;

  /// Class date
  ///
  /// In ja, this message translates to:
  /// **'実施日'**
  String get classDate;

  /// Add class date
  ///
  /// In ja, this message translates to:
  /// **'実施日を追加'**
  String get addClassDate;

  /// Add class times in Settings.
  ///
  /// In ja, this message translates to:
  /// **'設定で授業時間を登録してください'**
  String get configureClassTimes;

  /// Period {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}限'**
  String timeSlotNumber(Object arg0);

  /// Choose a time slot.
  ///
  /// In ja, this message translates to:
  /// **'時限を選んでください'**
  String get timeSlotRequired;

  /// A class is already scheduled for this date and time slot.
  ///
  /// In ja, this message translates to:
  /// **'同じ実施日・時限に授業があります'**
  String get classDateConflict;

  /// Class dates and time slots
  ///
  /// In ja, this message translates to:
  /// **'実施日と時限'**
  String get datesAndSlots;

  /// Course details and notes
  ///
  /// In ja, this message translates to:
  /// **'講義の詳細・メモ'**
  String get courseDetails;

  /// Add
  ///
  /// In ja, this message translates to:
  /// **'追加する'**
  String get addItem;

  /// Changes for this day
  ///
  /// In ja, this message translates to:
  /// **'この日の変更'**
  String get dayChanges;

  /// Assignments due
  ///
  /// In ja, this message translates to:
  /// **'提出する課題'**
  String get assignmentsDue;

  /// No weekdays to display
  ///
  /// In ja, this message translates to:
  /// **'表示する曜日がありません'**
  String get noVisibleWeekdays;

  /// Choose which weekdays to display in Settings.
  ///
  /// In ja, this message translates to:
  /// **'設定で表示する曜日を選んでください。'**
  String get chooseVisibleWeekdays;

  /// Open settings
  ///
  /// In ja, this message translates to:
  /// **'設定へ'**
  String get goToSettings;

  /// Schedule for this day
  ///
  /// In ja, this message translates to:
  /// **'この日の予定'**
  String get daySchedule;

  /// Change day and time
  ///
  /// In ja, this message translates to:
  /// **'曜日と時間を変更'**
  String get changeDayAndTime;

  /// Course: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'講義名: {arg0}'**
  String courseNameValue(Object arg0);

  /// Submit to: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'提出先: {arg0}'**
  String destinationValue(Object arg0);

  /// Related course: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'該当の講義: {arg0}'**
  String relatedCourseValue(Object arg0);

  /// Submission time: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'提出時間: {arg0}'**
  String submissionTimeValue(Object arg0);

  /// No assignments are due on this day.
  ///
  /// In ja, this message translates to:
  /// **'この日が提出期限の課題はありません'**
  String get noAssignmentsDue;

  /// [Image: {arg0}]
  ///
  /// In ja, this message translates to:
  /// **'[画像: {arg0}]'**
  String imageAlt(Object arg0);

  /// Room  {arg0}\nInstructor  {arg1}
  ///
  /// In ja, this message translates to:
  /// **'教室  {arg0}\n教員  {arg1}'**
  String roomAndInstructor(Object arg0, Object arg1);

  /// No notes yet.
  ///
  /// In ja, this message translates to:
  /// **'メモはまだありません。'**
  String get noNotes;

  /// Course name
  ///
  /// In ja, this message translates to:
  /// **'講義名'**
  String get courseTitle;

  /// Reminder minutes before class (blank: default, -1: off)
  ///
  /// In ja, this message translates to:
  /// **'開始何分前に通知（空欄: 全体設定、-1: オフ）'**
  String get courseReminderLead;

  /// Additional date restrictions
  ///
  /// In ja, this message translates to:
  /// **'実施期間の追加条件'**
  String get extraDateConditions;

  /// Start date (optional)
  ///
  /// In ja, this message translates to:
  /// **'開始日（任意）'**
  String get optionalStartDate;

  /// End date (optional)
  ///
  /// In ja, this message translates to:
  /// **'終了日（任意）'**
  String get optionalEndDate;

  /// Remind me to check assignments after class
  ///
  /// In ja, this message translates to:
  /// **'終了後に課題の確認を通知'**
  String get checkAssignmentsAfterClass;

  /// Notes (Markdown)
  ///
  /// In ja, this message translates to:
  /// **'メモ（Markdown）'**
  String get markdownNotes;

  /// The end date must be on or after the start date.
  ///
  /// In ja, this message translates to:
  /// **'終了日は開始日以降にしてください'**
  String get endDateBeforeStart;

  /// Add time slots in Settings.
  ///
  /// In ja, this message translates to:
  /// **'設定で時限を登録してください'**
  String get configureTimeSlots;

  /// Add a teaching period in the academic calendar.
  ///
  /// In ja, this message translates to:
  /// **'年間予定で講義期間を登録してください'**
  String get configureTeachingPeriod;

  /// {arg0}{arg1} · Period {arg2}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}{arg1}{arg2}限'**
  String meetingSummary(Object arg0, Object arg1, Object arg2);

  /// Delete this class date
  ///
  /// In ja, this message translates to:
  /// **'この実施日を削除'**
  String get deleteClassDate;

  /// Add a class date.
  ///
  /// In ja, this message translates to:
  /// **'実施日を追加してください'**
  String get classDateRequired;

  /// Choose a time slot for each class date.
  ///
  /// In ja, this message translates to:
  /// **'実施日ごとに時限を選んでください'**
  String get chooseSlotForEachDate;

  /// A class already uses the same weekday, date and time slot. Choose another time slot.
  ///
  /// In ja, this message translates to:
  /// **'同じ曜日・実施日・時限に授業があります。別の時限を選んでください。'**
  String get meetingConflict;

  /// {arg0}  Period {arg1}\n{arg2}–{arg3}\nRoom {arg4}\nInstructor {arg5}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}  {arg1}限\n{arg2}–{arg3}\n教室 {arg4}\n教員 {arg5}'**
  String sessionDetails(
    Object arg0,
    Object arg1,
    Object arg2,
    Object arg3,
    Object arg4,
    Object arg5,
  );

  /// This class is cancelled on this day.
  ///
  /// In ja, this message translates to:
  /// **'この日は休講です'**
  String get cancelledOnThisDay;

  /// Replacement for {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}の振替'**
  String replacementFor(Object arg0);

  /// Recurring settings
  ///
  /// In ja, this message translates to:
  /// **'定期設定'**
  String get recurringSettings;

  /// Class on {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}の授業'**
  String classOnDate(Object arg0);

  /// Cancelled
  ///
  /// In ja, this message translates to:
  /// **'休講'**
  String get cancelled;

  /// Replacement date (optional)
  ///
  /// In ja, this message translates to:
  /// **'振替日（任意）'**
  String get optionalReplacementDate;

  /// Replacement time slot
  ///
  /// In ja, this message translates to:
  /// **'振替先のコマ'**
  String get replacementTimeSlot;

  /// Room for this day (blank: original)
  ///
  /// In ja, this message translates to:
  /// **'この日の教室（空欄: 元の設定）'**
  String get roomOverride;

  /// Reminder minutes before class (blank: original, -1: off)
  ///
  /// In ja, this message translates to:
  /// **'開始何分前に通知（空欄: 元の設定、-1: オフ）'**
  String get reminderOverride;

  /// Choose a replacement date different from the original date.
  ///
  /// In ja, this message translates to:
  /// **'振替日は元の日と異なる日を選んでください'**
  String get replacementDateMustDiffer;

  /// Deleted {arg0} assignment(s).
  ///
  /// In ja, this message translates to:
  /// **'{arg0}件の課題を削除しました'**
  String assignmentsDeleted(num arg0);

  /// Undo
  ///
  /// In ja, this message translates to:
  /// **'元に戻す'**
  String get undo;

  /// {arg0} selected
  ///
  /// In ja, this message translates to:
  /// **'{arg0}件選択中'**
  String itemsSelected(Object arg0);

  /// Clear selection
  ///
  /// In ja, this message translates to:
  /// **'選択を解除'**
  String get clearSelection;

  /// Done
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get done;

  /// Show completed assignments
  ///
  /// In ja, this message translates to:
  /// **'完了した課題も表示'**
  String get showCompleted;

  /// Default notifications
  ///
  /// In ja, this message translates to:
  /// **'通知の初期設定'**
  String get defaultNotifications;

  /// No assignments
  ///
  /// In ja, this message translates to:
  /// **'課題はありません'**
  String get noAssignments;

  /// Use the + button at the bottom right to add an assignment.
  ///
  /// In ja, this message translates to:
  /// **'右下の＋から課題を登録できます。'**
  String get addAssignmentHelp;

  /// View assignment
  ///
  /// In ja, this message translates to:
  /// **'課題を表示'**
  String get viewAssignment;

  /// Edit assignment
  ///
  /// In ja, this message translates to:
  /// **'課題を編集'**
  String get editAssignment;

  /// Mark as incomplete
  ///
  /// In ja, this message translates to:
  /// **'未完了に戻す'**
  String get markIncomplete;

  /// Mark as complete
  ///
  /// In ja, this message translates to:
  /// **'完了にする'**
  String get markComplete;

  /// Delete assignment
  ///
  /// In ja, this message translates to:
  /// **'課題を削除'**
  String get deleteAssignment;

  /// In {arg0} week(s)
  ///
  /// In ja, this message translates to:
  /// **'{arg0}週間後'**
  String weeksLater(num arg0);

  /// Due {arg0}, {arg1}, period {arg2}{arg3}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}の{arg1}{arg2}限目{arg3}に提出'**
  String deadlineHint(Object arg0, Object arg1, Object arg2, Object arg3);

  /// Add assignment
  ///
  /// In ja, this message translates to:
  /// **'課題を登録'**
  String get registerAssignment;

  /// Assignment name
  ///
  /// In ja, this message translates to:
  /// **'課題名'**
  String get assignmentName;

  /// Due date and time
  ///
  /// In ja, this message translates to:
  /// **'提出期限'**
  String get deadline;

  /// Choose due date from timetable
  ///
  /// In ja, this message translates to:
  /// **'時間割から提出日時を選ぶ'**
  String get chooseDeadlineFromTimetable;

  /// Submit to
  ///
  /// In ja, this message translates to:
  /// **'提出先'**
  String get destination;

  /// Notes
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get notes;

  /// Notifications
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get notifications;

  /// Add notification
  ///
  /// In ja, this message translates to:
  /// **'通知を追加'**
  String get addNotification;

  /// Enter the due date and time, including minutes.
  ///
  /// In ja, this message translates to:
  /// **'提出期限を分まで入力してください'**
  String get deadlineMinuteRequired;

  /// Notifications must be scheduled on or before the deadline.
  ///
  /// In ja, this message translates to:
  /// **'通知日時は期限以前にしてください'**
  String get notificationAfterDeadline;

  /// Select due date and time
  ///
  /// In ja, this message translates to:
  /// **'提出日時を選択'**
  String get selectDeadline;

  /// Default assignment notifications
  ///
  /// In ja, this message translates to:
  /// **'課題の通知・全体設定'**
  String get assignmentNotificationDefaults;

  /// Used as defaults for new assignments. Leave empty for no default notifications.
  ///
  /// In ja, this message translates to:
  /// **'新しい課題へ初期値として入れます。空にすると初期値の通知はありません。'**
  String get assignmentNotificationDefaultsHelp;

  /// Select the start date, then the end date on the calendar.
  ///
  /// In ja, this message translates to:
  /// **'開始日、終了日の順にカレンダーを選択してください。'**
  String get choosePeriodDates;

  /// Cancel period selection
  ///
  /// In ja, this message translates to:
  /// **'期間選択をやめる'**
  String get cancelPeriodSelection;

  /// Click to change a day, double-click to edit a period, or drag to add a period. Right-click for actions.
  ///
  /// In ja, this message translates to:
  /// **'クリックで日ごとの変更・ダブルクリックで期間編集・ドラッグで期間追加。右クリックで操作一覧。'**
  String get desktopCalendarHelp;

  /// Tap to change a day, long-press to edit a period, or long-press and drag to add a period.
  ///
  /// In ja, this message translates to:
  /// **'タップで日ごとの変更・長押しで期間編集・長押ししてなぞると期間追加。'**
  String get mobileCalendarHelp;

  /// Delete changes for this day
  ///
  /// In ja, this message translates to:
  /// **'この日の変更を削除'**
  String get deleteDayChanges;

  /// Daily changes
  ///
  /// In ja, this message translates to:
  /// **'日ごとの変更'**
  String get dailyChanges;

  /// View classes for this day
  ///
  /// In ja, this message translates to:
  /// **'この日の講義を確認'**
  String get viewDayClasses;

  /// Edit period for this day
  ///
  /// In ja, this message translates to:
  /// **'この日の期間を編集'**
  String get editDayPeriod;

  /// Edit {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}を編集'**
  String editNamed(Object arg0);

  /// Delete {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}を削除'**
  String deleteNamedAction(Object arg0);

  /// Period
  ///
  /// In ja, this message translates to:
  /// **'期間'**
  String get period;

  /// Merged period name (optional)
  ///
  /// In ja, this message translates to:
  /// **'まとめた期間の名前（任意）'**
  String get mergedPeriodName;

  /// Add period
  ///
  /// In ja, this message translates to:
  /// **'期間を登録'**
  String get registerPeriod;

  /// Edit period
  ///
  /// In ja, this message translates to:
  /// **'期間を編集'**
  String get editPeriod;

  /// Type
  ///
  /// In ja, this message translates to:
  /// **'種類'**
  String get type;

  /// University closure / vacation
  ///
  /// In ja, this message translates to:
  /// **'全学休業日・長期休暇'**
  String get universityClosure;

  /// Name (optional)
  ///
  /// In ja, this message translates to:
  /// **'名前（任意）'**
  String get optionalName;

  /// Start date
  ///
  /// In ja, this message translates to:
  /// **'開始日'**
  String get startDate;

  /// End date
  ///
  /// In ja, this message translates to:
  /// **'終了日'**
  String get endDate;

  /// Delete this date range
  ///
  /// In ja, this message translates to:
  /// **'この日程を削除'**
  String get deleteDateRange;

  /// Add date range
  ///
  /// In ja, this message translates to:
  /// **'日程を追加'**
  String get addDateRange;

  /// University settings for {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}の全学設定'**
  String universityDaySettings(Object arg0);

  /// University closed
  ///
  /// In ja, this message translates to:
  /// **'全学休業'**
  String get universityClosed;

  /// Replacement date for this day (optional)
  ///
  /// In ja, this message translates to:
  /// **'この日の代替日（任意）'**
  String get optionalUniversityReplacement;

  /// Replacement timetable
  ///
  /// In ja, this message translates to:
  /// **'代わりの時間割'**
  String get replacementTimetable;

  /// A university replacement day replaces the classes normally scheduled for that weekday.
  ///
  /// In ja, this message translates to:
  /// **'全学代替日は、その日に本来ある曜日の講義を置き換えます。'**
  String get universityReplacementHelp;

  /// Choose a different replacement date.
  ///
  /// In ja, this message translates to:
  /// **'代替日は別の日を指定してください'**
  String get universityReplacementMustDiffer;

  /// The replacement date already has university settings. Choose another date.
  ///
  /// In ja, this message translates to:
  /// **'代替先には既に全学設定があります。別の日を選んでください'**
  String get universityReplacementConflict;

  /// Bundled Japanese public holiday data covers {arg0}–{arg1}. Update the data to import all holidays for this academic year.
  ///
  /// In ja, this message translates to:
  /// **'同梱の祝日データは{arg0}～{arg1}年です。この年度の全祝日を登録するにはデータの更新が必要です。'**
  String holidayDataRange(Object arg0, Object arg1);

  /// Import Japanese public holidays for academic year {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}年度の祝日を休業日に'**
  String importHolidaysForYear(Object arg0);

  /// Import {arg0} Japanese public holidays, including substitute holidays. Holidays with existing IDs will not be duplicated.\nSource: Cabinet Office of Japan ({arg1}–{arg2}, offline data)
  ///
  /// In ja, this message translates to:
  /// **'{arg0}日の祝日・振替休日等を登録します。同じIDで登録済みの祝日は重複しません。\n出典: 内閣府（{arg1}～{arg2}年、オフラインデータ）'**
  String importHolidaysConfirmation(Object arg0, Object arg1, Object arg2);

  /// Register
  ///
  /// In ja, this message translates to:
  /// **'登録'**
  String get register;

  /// Imported {arg0} public holiday(s).
  ///
  /// In ja, this message translates to:
  /// **'{arg0}日の祝日を登録しました'**
  String holidaysImported(num arg0);

  /// General
  ///
  /// In ja, this message translates to:
  /// **'一般'**
  String get general;

  /// Display
  ///
  /// In ja, this message translates to:
  /// **'表示設定'**
  String get displaySettings;

  /// Controls
  ///
  /// In ja, this message translates to:
  /// **'操作設定'**
  String get operationSettings;

  /// Accessibility
  ///
  /// In ja, this message translates to:
  /// **'アクセシビリティ'**
  String get accessibility;

  /// About this app
  ///
  /// In ja, this message translates to:
  /// **'このアプリについて'**
  String get about;

  /// Version: {arg0}
  ///
  /// In ja, this message translates to:
  /// **'バージョン: {arg0}'**
  String version(Object arg0);

  /// Creator
  ///
  /// In ja, this message translates to:
  /// **'制作者'**
  String get author;

  /// Name
  ///
  /// In ja, this message translates to:
  /// **'名前'**
  String get name;

  /// Source code
  ///
  /// In ja, this message translates to:
  /// **'ソースコード'**
  String get sourceCode;

  /// License
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get license;

  /// Files
  ///
  /// In ja, this message translates to:
  /// **'ファイル'**
  String get files;

  /// Open a .unitable file
  ///
  /// In ja, this message translates to:
  /// **'.unitableを開く'**
  String get openUnitable;

  /// Month name
  ///
  /// In ja, this message translates to:
  /// **'{arg0}月'**
  String monthNumber(String arg0);

  /// First day of the week
  ///
  /// In ja, this message translates to:
  /// **'週の開始曜日'**
  String get weekStartsOn;

  /// Appearance
  ///
  /// In ja, this message translates to:
  /// **'配色'**
  String get appearance;

  /// Theme
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get theme;

  /// System default
  ///
  /// In ja, this message translates to:
  /// **'端末に合わせる'**
  String get followSystem;

  /// Light
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get light;

  /// Dark
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get dark;

  /// Black background for OLED
  ///
  /// In ja, this message translates to:
  /// **'有機EL用の黒い背景'**
  String get oledBackground;

  /// Timetable display
  ///
  /// In ja, this message translates to:
  /// **'時間割の表示'**
  String get timetableDisplay;

  /// Continuous scrolling
  ///
  /// In ja, this message translates to:
  /// **'連続表示'**
  String get continuousDisplay;

  /// Time slot width
  ///
  /// In ja, this message translates to:
  /// **'コマ幅'**
  String get timeSlotWidth;

  /// Course name font size
  ///
  /// In ja, this message translates to:
  /// **'科目名の文字サイズ'**
  String get courseFontSize;

  /// Room name font size
  ///
  /// In ja, this message translates to:
  /// **'教室名の文字サイズ'**
  String get roomFontSize;

  /// Weekdays hidden in timetable
  ///
  /// In ja, this message translates to:
  /// **'時間割に表示しない曜日'**
  String get hiddenWeekdays;

  /// Advanced settings
  ///
  /// In ja, this message translates to:
  /// **'詳細設定'**
  String get advancedSettings;

  /// Color palette
  ///
  /// In ja, this message translates to:
  /// **'カラーパレット'**
  String get colorPalette;

  /// Calendar display priority
  ///
  /// In ja, this message translates to:
  /// **'年間予定の表示優先順位'**
  String get calendarPriority;

  /// Long-press duration
  ///
  /// In ja, this message translates to:
  /// **'長押しの判定時間'**
  String get longPressDuration;

  /// Enable notifications
  ///
  /// In ja, this message translates to:
  /// **'通知を使う'**
  String get enableNotifications;

  /// Notifications are unavailable in this edition.
  ///
  /// In ja, this message translates to:
  /// **'この版では通知を利用できません。'**
  String get notificationsUnavailable;

  /// Notification test (test APK only)
  ///
  /// In ja, this message translates to:
  /// **'通知テスト（テストAPK限定）'**
  String get notificationTest;

  /// Check assignment reminders and the Add assignment action. Only the latest test is scheduled.
  ///
  /// In ja, this message translates to:
  /// **'課題確認通知と「課題を追加」を確認できます。予約は最新の1件です。'**
  String get notificationTestHelp;

  /// Course to test
  ///
  /// In ja, this message translates to:
  /// **'テストする科目'**
  String get testCourse;

  /// Test notification now
  ///
  /// In ja, this message translates to:
  /// **'今すぐ通知をテスト'**
  String get testNow;

  /// Test notification in 30 seconds
  ///
  /// In ja, this message translates to:
  /// **'30秒後に通知をテスト'**
  String get testInThirtySeconds;

  /// Test notification in 5 minutes
  ///
  /// In ja, this message translates to:
  /// **'5分後に通知をテスト'**
  String get testInFiveMinutes;

  /// Allow exact notifications
  ///
  /// In ja, this message translates to:
  /// **'正確な時刻の通知を許可'**
  String get allowExactAlarms;

  /// Allow Alarms and reminders in device settings to reduce notification delays.
  ///
  /// In ja, this message translates to:
  /// **'端末の「アラームとリマインダー」を許可すると通知の遅れを軽減できます。'**
  String get exactAlarmHelp;

  /// Check battery settings
  ///
  /// In ja, this message translates to:
  /// **'省電力設定を確認'**
  String get batterySettings;

  /// If notifications are delayed, review battery restrictions in the app settings on your device.
  ///
  /// In ja, this message translates to:
  /// **'通知が遅れる場合は、アプリ情報からバッテリーの制限を見直してください。'**
  String get batterySettingsHelp;

  /// Classroom reminders
  ///
  /// In ja, this message translates to:
  /// **'教室を通知する'**
  String get notifyRoom;

  /// {arg0} minutes before class
  ///
  /// In ja, this message translates to:
  /// **'講義開始{arg0}分前'**
  String minutesBeforeClass(num arg0);

  /// Default notification timing for new assignments
  ///
  /// In ja, this message translates to:
  /// **'新しい課題の通知タイミング'**
  String get newAssignmentNotifications;

  /// Non-teaching day settings
  ///
  /// In ja, this message translates to:
  /// **'休日の定義'**
  String get holidayDefinition;

  /// University time zone
  ///
  /// In ja, this message translates to:
  /// **'大学のタイムゾーン'**
  String get universityTimezone;

  /// Use the MSIX edition on Windows for reliable cancellation and rescheduling of notifications.
  ///
  /// In ja, this message translates to:
  /// **'Windowsで予約の取消・再設定を確実に行うにはMSIX版を使用してください。'**
  String get msixSchedulingHelp;

  /// Up to 480 upcoming notifications within the next year are scheduled. The schedule is refreshed when the app starts or resumes.
  ///
  /// In ja, this message translates to:
  /// **'予約は今後1年分のうち直近480件までです。起動・画面復帰時に補充します。'**
  String get schedulingLimit;

  /// Reduce motion
  ///
  /// In ja, this message translates to:
  /// **'動きを減らす'**
  String get reduceMotion;

  /// Color vision support
  ///
  /// In ja, this message translates to:
  /// **'色覚に配慮した表示'**
  String get colorVisionSupport;

  /// Stronger text contrast
  ///
  /// In ja, this message translates to:
  /// **'文字色を濃くする'**
  String get strongerText;

  /// Back to settings list
  ///
  /// In ja, this message translates to:
  /// **'設定一覧に戻る'**
  String get backToSettings;

  /// Duration (milliseconds)
  ///
  /// In ja, this message translates to:
  /// **'時間（ミリ秒）'**
  String get durationMilliseconds;

  /// Enter a duration of at least 1 millisecond.
  ///
  /// In ja, this message translates to:
  /// **'1以上のミリ秒を入力してください'**
  String get positiveMilliseconds;

  /// Width (px)
  ///
  /// In ja, this message translates to:
  /// **'幅（px）'**
  String get widthPixels;

  /// Enter a number from 40 to 600.
  ///
  /// In ja, this message translates to:
  /// **'40〜600の数値を入力してください'**
  String get slotWidthRange;

  /// Palette to edit
  ///
  /// In ja, this message translates to:
  /// **'編集する配色'**
  String get paletteToEdit;

  /// Nine teaching period colors
  ///
  /// In ja, this message translates to:
  /// **'講義期間の9色'**
  String get teachingPeriodColors;

  /// Nine exam period colors
  ///
  /// In ja, this message translates to:
  /// **'試験期間の9色'**
  String get examPeriodColors;

  /// Color {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}番目'**
  String colorIndex(Object arg0);

  /// Reset this palette
  ///
  /// In ja, this message translates to:
  /// **'この配色を初期値に戻す'**
  String get resetPalette;

  /// Reset to defaults
  ///
  /// In ja, this message translates to:
  /// **'初期値に戻す'**
  String get resetDefaults;

  /// Specify RGBA
  ///
  /// In ja, this message translates to:
  /// **'RGBAで指定'**
  String get specifyRgba;

  /// Enter an integer from 0 to 255.
  ///
  /// In ja, this message translates to:
  /// **'0〜255の整数を入力してください'**
  String get rgbaRange;

  /// Font size
  ///
  /// In ja, this message translates to:
  /// **'文字サイズ'**
  String get fontSize;

  /// Enter a number from 8 to 36.
  ///
  /// In ja, this message translates to:
  /// **'8〜36の数値を入力してください'**
  String get fontSizeRange;

  /// Closures and Japanese public holidays
  ///
  /// In ja, this message translates to:
  /// **'休業日・祝日'**
  String get closuresAndHolidays;

  /// Days without classes
  ///
  /// In ja, this message translates to:
  /// **'講義がない日'**
  String get noClassDays;

  /// Only on days without classes
  ///
  /// In ja, this message translates to:
  /// **'講義がない日に限定する'**
  String get onlyDaysWithoutClasses;

  /// Classroom reminders
  ///
  /// In ja, this message translates to:
  /// **'教室の通知'**
  String get roomNotifications;

  /// Minutes before class
  ///
  /// In ja, this message translates to:
  /// **'開始何分前'**
  String get minutesBeforeStart;

  /// Enter 0 or more minutes.
  ///
  /// In ja, this message translates to:
  /// **'0以上の分数を入力してください'**
  String get nonNegativeMinutes;

  /// Search region
  ///
  /// In ja, this message translates to:
  /// **'地域を検索'**
  String get searchRegion;

  /// Notification permission is required. Check your device settings.
  ///
  /// In ja, this message translates to:
  /// **'通知の許可が必要です。端末の設定を確認してください。'**
  String get notificationPermissionHelp;

  /// Start
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get start;

  /// End
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get end;

  /// Change start time
  ///
  /// In ja, this message translates to:
  /// **'開始時刻を変更'**
  String get changeStartTime;

  /// Change end time
  ///
  /// In ja, this message translates to:
  /// **'終了時刻を変更'**
  String get changeEndTime;

  /// Delete time slot
  ///
  /// In ja, this message translates to:
  /// **'コマを削除'**
  String get deleteTimeSlot;

  /// {arg0} min
  ///
  /// In ja, this message translates to:
  /// **'{arg0}分'**
  String minutesValue(Object arg0);

  /// Delete period {arg0}
  ///
  /// In ja, this message translates to:
  /// **'{arg0}限を削除'**
  String deleteSlotNumber(Object arg0);

  /// Period {arg0} times
  ///
  /// In ja, this message translates to:
  /// **'{arg0}限の時間'**
  String slotTimeTitle(Object arg0);

  /// Start {arg0}
  ///
  /// In ja, this message translates to:
  /// **'開始 {arg0}'**
  String startTimeValue(Object arg0);

  /// End {arg0}
  ///
  /// In ja, this message translates to:
  /// **'終了 {arg0}'**
  String endTimeValue(Object arg0);

  /// The end time must be after the start time.
  ///
  /// In ja, this message translates to:
  /// **'終了時刻は開始時刻より後にしてください'**
  String get endTimeAfterStart;

  /// Period {arg0}: {arg1} time
  ///
  /// In ja, this message translates to:
  /// **'{arg0}限の{arg1}時刻'**
  String slotTimeHelp(Object arg0, Object arg1);

  /// A class uses this time slot. Change the class first.
  ///
  /// In ja, this message translates to:
  /// **'このコマを使う講義があります。先に授業を変更してください。'**
  String get timeSlotInUse;

  /// The destination already contains university.unitable. Choose an empty folder.
  ///
  /// In ja, this message translates to:
  /// **'書き出し先にuniversity.unitableがあります。空のフォルダーを選んでください。'**
  String get exportFolderOccupied;

  /// Existing files will not be overwritten. Choose another name.
  ///
  /// In ja, this message translates to:
  /// **'既存のファイルは上書きしません。別の名前を選んでください。'**
  String get chooseAnotherFilename;

  /// Exported a copy of the database.
  ///
  /// In ja, this message translates to:
  /// **'データベースのコピーを書き出しました'**
  String get databaseExported;

  /// Choose the .unitable file to use.
  ///
  /// In ja, this message translates to:
  /// **'使う.unitableファイルを指定してください。'**
  String get chooseDatabase;

  /// Not set
  ///
  /// In ja, this message translates to:
  /// **'未登録'**
  String get notRegistered;

  /// · through {arg0}
  ///
  /// In ja, this message translates to:
  /// **'・{arg0}まで'**
  String scheduledThrough(Object arg0);

  /// (refreshed when the app starts or resumes)
  ///
  /// In ja, this message translates to:
  /// **'（起動・画面復帰時に予約を補充）'**
  String get scheduleRefillHelp;

  /// · notifications may be delayed because exact alarms are not permitted
  ///
  /// In ja, this message translates to:
  /// **'・正確な時刻の通知が未許可のため遅れる場合があります'**
  String get inexactAlarmWarning;

  /// · Cancelled
  ///
  /// In ja, this message translates to:
  /// **'・休講'**
  String get cancelledSuffix;

  /// Replacement
  ///
  /// In ja, this message translates to:
  /// **'振替'**
  String get replacement;

  /// Unavailable
  ///
  /// In ja, this message translates to:
  /// **'取得できません'**
  String get versionUnavailable;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @languageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageEnglish.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @namedExamPeriod.
  ///
  /// In ja, this message translates to:
  /// **'{name}試験期間'**
  String namedExamPeriod(String name);

  /// No description provided for @storagePickerBusy.
  ///
  /// In ja, this message translates to:
  /// **'ファイル・フォルダーを選択中です。'**
  String get storagePickerBusy;

  /// No description provided for @storageEmptyFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイルが空です。'**
  String get storageEmptyFile;

  /// No description provided for @storageVerificationFailed.
  ///
  /// In ja, this message translates to:
  /// **'書き込んだデータを検証できません。'**
  String get storageVerificationFailed;

  /// No description provided for @storageFolderPermission.
  ///
  /// In ja, this message translates to:
  /// **'フォルダーへの読み書き権限がありません。再度選択してください。'**
  String get storageFolderPermission;

  /// No description provided for @storageRecoveryFailed.
  ///
  /// In ja, this message translates to:
  /// **'前回の保存ファイルを復元できません。'**
  String get storageRecoveryFailed;

  /// No description provided for @storageMissingDatabase.
  ///
  /// In ja, this message translates to:
  /// **'university.unitableがありません。'**
  String get storageMissingDatabase;

  /// No description provided for @storageEmptyDatabase.
  ///
  /// In ja, this message translates to:
  /// **'データベースが空です。'**
  String get storageEmptyDatabase;

  /// No description provided for @storageNoData.
  ///
  /// In ja, this message translates to:
  /// **'保存するデータがありません。'**
  String get storageNoData;

  /// No description provided for @storageCleanupFailed.
  ///
  /// In ja, this message translates to:
  /// **'以前のコピーを整理できません。'**
  String get storageCleanupFailed;

  /// No description provided for @storageRenameUnsupported.
  ///
  /// In ja, this message translates to:
  /// **'このフォルダーは安全な更新に必要なファイル名変更に対応していません。別のローカルフォルダーを選んでください。'**
  String get storageRenameUnsupported;

  /// No description provided for @storageSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'データベースの保存を完了できません。'**
  String get storageSaveFailed;

  /// No description provided for @storageSelectFile.
  ///
  /// In ja, this message translates to:
  /// **'.unitableファイルを指定してください。'**
  String get storageSelectFile;

  /// No description provided for @storageFilePermission.
  ///
  /// In ja, this message translates to:
  /// **'読み書きできるファイルを指定してください。'**
  String get storageFilePermission;

  /// Full weekday name for settings and descriptions
  ///
  /// In ja, this message translates to:
  /// **'{arg0}曜日'**
  String fullWeekdayName(String arg0);

  /// Name of the exam in the exam editor
  ///
  /// In ja, this message translates to:
  /// **'科目名'**
  String get examName;

  /// Label for the academic year start month dropdown
  ///
  /// In ja, this message translates to:
  /// **'年度の開始月'**
  String get academicYearStartsIn;

  /// An academic year contained in one calendar year
  ///
  /// In ja, this message translates to:
  /// **'{year}年度'**
  String academicYearSingle(int year);

  /// An academic year spanning two calendar years. Japanese displays only the starting year; English displays both.
  ///
  /// In ja, this message translates to:
  /// **'{startYear}年度'**
  String academicYearRange(int startYear, int endYear);

  /// University settings section for academic year and class times. Keep the existing Japanese heading.
  ///
  /// In ja, this message translates to:
  /// **'年度・授業時間'**
  String get universitySettings;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
