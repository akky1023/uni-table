// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get databaseTooLarge => 'データベースが上限（32 MiB・合計100,000件）を超えています。';

  @override
  String get unsafeDatabaseSchema => '安全でないデータベース構造のため開けません。';

  @override
  String get storageFileTooLarge => 'ファイルがサイズ上限（32 MiB）を超えています。';

  @override
  String get appName => 'うに時間割';

  @override
  String get invalidDatabase => 'うに時間割のデータベースではありません。元のファイルは変更していません。';

  @override
  String get unsupportedDatabaseVersion => '対応していないデータベースのバージョンです。';

  @override
  String get databaseIntegrityFailed => 'データベースの整合性チェックに失敗しました。';

  @override
  String termNumber(Object arg0) {
    return '$arg0学期';
  }

  @override
  String get selectMultiplePeriods => '2つ以上の期間を選んでください';

  @override
  String get selectSamePeriodKind => '同じ種類の期間を選んでください';

  @override
  String get fileAlreadyExists => '保存先にファイルが存在します。';

  @override
  String get selectDatabaseFirst => '先に.unitableファイルを指定してください';

  @override
  String workingCopyFile(Object arg0) {
    return '指定ファイルを読み込めないため、作業用コピーを開きました: $arg0';
  }

  @override
  String get recoveredChanges => '指定フォルダーに未保存の変更を、端末内の作業用DBから復元しました。再試行してください。';

  @override
  String workingCopyFolder(Object arg0) {
    return '指定フォルダーを読み込めないため、端末内の作業用コピーを開きました: $arg0';
  }

  @override
  String get databaseNotFound => '指定した.unitableが見つかりません。ファイルを選び直してください。';

  @override
  String get noOverwrite => '既存のファイルは上書きしません';

  @override
  String get selectUnitableFile => '.unitableファイルを選んでください';

  @override
  String get emptyFile => '空のファイルは開けません';

  @override
  String externalSaveFailed(Object arg0) {
    return '端末内には保存済みですが、指定フォルダーへの保存に失敗しました: $arg0';
  }

  @override
  String get unspecified => '未指定';

  @override
  String get closurePeriod => '休業期間';

  @override
  String get teachingPeriod => '講義期間';

  @override
  String get firstSemester => '前期';

  @override
  String get secondSemester => '後期';

  @override
  String quarterNumber(Object arg0) {
    return '第$arg0クオータ';
  }

  @override
  String get monday => '月';

  @override
  String get tuesday => '火';

  @override
  String get wednesday => '水';

  @override
  String get thursday => '木';

  @override
  String get friday => '金';

  @override
  String get saturday => '土';

  @override
  String get sunday => '日';

  @override
  String classNoticeBody(Object arg0, Object arg1) {
    return '$arg0から・教室 $arg1';
  }

  @override
  String get checkAssignments => '課題を確認';

  @override
  String checkAssignmentsBody(Object arg0) {
    return '$arg0の課題はありましたか？';
  }

  @override
  String deadlineNoticeBody(Object arg0, Object arg1, Object arg2) {
    return '期限 $arg0 $arg1・$arg2';
  }

  @override
  String get notificationsOff => '通知はオフです';

  @override
  String get notificationChannel => '講義・課題';

  @override
  String get notificationChannelDescription => '講義の教室と課題の期限';

  @override
  String get addAssignment => '課題を追加';

  @override
  String get testApkOnly => '通知テストはテストAPKで利用できます。';

  @override
  String get testNoticeTitle => '課題を確認（通知テスト）';

  @override
  String get windowsNotificationsRequireMsix =>
      'Windowsの通知はMSIX版で有効にできます。MSIXとしてビルド・インストールしてください。';

  @override
  String scheduledNotices(Object arg0, Object arg1, Object arg2, Object arg3) {
    return '$arg0件を予約済み$arg1$arg2$arg3';
  }

  @override
  String notificationSetupFailed(Object arg0) {
    return '通知の設定に失敗しました: $arg0';
  }

  @override
  String get hidePast => '過去を隠す';

  @override
  String get showPast => '過去を表示';

  @override
  String get basic => '基本';

  @override
  String get background => '背景';

  @override
  String get text => '文字';

  @override
  String get mutedText => '薄い文字';

  @override
  String get accent => 'アクセント';

  @override
  String get onAccent => 'アクセント上の文字';

  @override
  String get menuBackground => 'メニューの背景';

  @override
  String get inputField => '入力欄';

  @override
  String get popup => 'ポップアップ';

  @override
  String get selection => '選択部分';

  @override
  String get selectionText => '選択部分の文字';

  @override
  String get divider => '区切り線';

  @override
  String get holidayText => '祝日・休業日の文字';

  @override
  String get timetable => '時間割';

  @override
  String get freeTime => '空き時間';

  @override
  String get course => '講義';

  @override
  String get exam => '試験';

  @override
  String get oneOffClass => '単発講義';

  @override
  String get replacementClass => '代替日の講義';

  @override
  String get closure => '休業日';

  @override
  String get pastDates => '過去の日付';

  @override
  String get assignments => '課題';

  @override
  String get selectedAssignment => '選択中の課題';

  @override
  String get annualCalendar => '年間予定';

  @override
  String get examDay => '試験がある日';

  @override
  String get replacementActive => '代替日・講義あり';

  @override
  String get activeDay => '講義がある日';

  @override
  String get nationalHoliday => '祝日';

  @override
  String get holiday => '休日';

  @override
  String get examPeriod => '試験期間';

  @override
  String get replacementDay => '代替日';

  @override
  String get definedHoliday => '休日の定義に当てはまる日';

  @override
  String colorNumber(Object arg0) {
    return '色 $arg0';
  }

  @override
  String get opacity => '透明度';

  @override
  String get requiredField => '入力してください';

  @override
  String get integerRange => '-1～2147483647の整数を入力してください';

  @override
  String get selectDate => '日付を選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '決定';

  @override
  String get pickDate => '日付を選ぶ';

  @override
  String get pickTime => '時刻を選ぶ';

  @override
  String get dateTimeFormat => 'YYYY-MM-DD HH:mmで入力してください';

  @override
  String get dateRequired => '日付を選んでください';

  @override
  String get saveChanges => '変更を保存しますか？';

  @override
  String get discardChanges => '編集を破棄';

  @override
  String get save => '保存';

  @override
  String get confirmDelete => '削除しますか？';

  @override
  String get back => '戻る';

  @override
  String get delete => '削除';

  @override
  String get saving => '保存中…';

  @override
  String hoursBefore(num arg0) {
    return '$arg0時間前';
  }

  @override
  String daysBefore(num arg0) {
    return '$arg0日前';
  }

  @override
  String weeksBefore(num arg0) {
    return '$arg0週間前';
  }

  @override
  String weeksBeforeAt(num arg0, Object arg1) {
    return '$arg0週間前の $arg1';
  }

  @override
  String daysBeforeAt(num arg0, Object arg1) {
    return '$arg0日前の $arg1';
  }

  @override
  String previousSundayAt(Object arg0) {
    return '直前の日曜日の $arg0';
  }

  @override
  String previousHolidayAt(Object arg0) {
    return '直前の休日の $arg0';
  }

  @override
  String holidaysBefore(num arg0) {
    return '$arg0回前の休日';
  }

  @override
  String fixedNoticeTime(Object arg0) {
    return '指定日時 $arg0';
  }

  @override
  String get unknownNotification => '不明な通知';

  @override
  String get notificationTiming => '通知タイミング';

  @override
  String get hoursBeforeUnit => '時間前';

  @override
  String get daysBeforeUnit => '日前';

  @override
  String get weeksBeforeUnit => '週間前';

  @override
  String get holidaysBeforeUnit => '回前の休日';

  @override
  String get atTime => 'の';

  @override
  String get deadlineTimeHint => '省略すると期限と同じ時刻';

  @override
  String get pickNotificationTime => '通知時刻を選ぶ';

  @override
  String get holidaysBeforeHelp =>
      '期限の日より前の休日を数え、期限と同じ時刻に通知します。休日に含める日は設定で変更できます。';

  @override
  String get notificationOffsetRange => '休日は1以上、それ以外は0以上を指定してください';

  @override
  String get timeFormat => '00:00～23:59で入力してください';

  @override
  String get testNeedsCourse => '通知テストには講義を1件以上登録してください。';

  @override
  String get notificationPermissionRequired => '通知の許可が必要です。';

  @override
  String get testNotificationSent => 'テスト通知を送信しました。';

  @override
  String testNotificationScheduled(Object arg0) {
    return '$arg0秒後のテスト通知を予約しました。画面を閉じて確認できます。';
  }

  @override
  String testNotificationFailed(Object arg0) {
    return '通知テストに失敗しました: $arg0';
  }

  @override
  String get notificationCourseMissing => '通知の講義が見つかりません。';

  @override
  String get finishEditingToAddAssignment => '編集中の変更を保存または破棄すると、課題追加画面を開きます。';

  @override
  String get saveInProgress => '保存中です。少し待ってからお試しください。';

  @override
  String get retrySaveInSettings => '指定フォルダーに保存できませんでした。設定画面から再試行できます。';

  @override
  String get settings => '設定';

  @override
  String get edit => '編集';

  @override
  String get addPeriod => '期間を追加';

  @override
  String get mergePeriods => '期間をまとめる';

  @override
  String get importHolidays => '祝日を休日にする';

  @override
  String get close => '閉じる';

  @override
  String get calendarActions => '年間予定の操作';

  @override
  String get add => '追加';

  @override
  String get switchToView => '閲覧モードに切り替え';

  @override
  String get switchToEdit => '編集モードに切り替え';

  @override
  String get registerCourse => '講義を登録';

  @override
  String get registerOneOffClass => '単発講義を登録';

  @override
  String get previousWeek => '前の週';

  @override
  String get nextWeek => '次の週';

  @override
  String get thisWeek => '今週';

  @override
  String get previousYear => '前の年度';

  @override
  String get nextYear => '次の年度';

  @override
  String get createDatabase => '新しい.unitableを作成';

  @override
  String get exportCopy => 'コピーを書き出す';

  @override
  String get openDatabase => 'データベースを開く';

  @override
  String get addTimeSlot => 'コマを追加';

  @override
  String get changeRoomNoticeTiming => '教室の通知タイミングを変更';

  @override
  String get toggleRoomNotices => '教室通知をオン／オフ';

  @override
  String get assignmentNotificationSettings => '課題の通知設定';

  @override
  String get universityTimezoneSettings => '大学のタイムゾーン設定';

  @override
  String get turnNotificationsOff => '通知をオフにする';

  @override
  String get turnNotificationsOn => '通知をオンにする';

  @override
  String get exitEditing => '編集から戻る';

  @override
  String get unsavedFolderChanges => '指定フォルダーに未保存の変更があります。';

  @override
  String get retry => '再試行';

  @override
  String deleteNamed(Object arg0) {
    return '$arg0を削除しますか？';
  }

  @override
  String get deleteThisClass => 'この時間の授業を削除しますか？';

  @override
  String get classLabel => '授業';

  @override
  String get choosePeriodToEdit => '編集する期間';

  @override
  String get teachingPeriodRequired => '講義期間を登録してください';

  @override
  String get teachingPeriodHelp => '年間予定で講義期間を登録すると、時間割を編集できます。';

  @override
  String get goToCalendar => '年間予定へ';

  @override
  String get addOneOffClass => '単発講義を追加';

  @override
  String weekdayName(Object arg0) {
    return '$arg0曜日';
  }

  @override
  String get addExam => '試験を登録';

  @override
  String get editExam => '試験を編集';

  @override
  String get deleteExam => '試験を削除';

  @override
  String dayAndSlot(Object arg0, Object arg1) {
    return '$arg0・$arg1限';
  }

  @override
  String get courseName => '科目名';

  @override
  String get roomName => '教室名';

  @override
  String get instructorName => '教員名';

  @override
  String get examSlotOccupied => 'この時限には試験が登録されています';

  @override
  String get addCourse => '講義を追加';

  @override
  String get editClass => '授業を編集';

  @override
  String get deleteClass => '授業を削除';

  @override
  String get editClassDate => '実施日を編集';

  @override
  String get editCourse => '講義を編集';

  @override
  String get deleteAll => 'まとめて削除';

  @override
  String get deleteAllClassDates => 'この講義の実施日をまとめて削除しますか？';

  @override
  String get classDate => '実施日';

  @override
  String get addClassDate => '実施日を追加';

  @override
  String get configureClassTimes => '設定で授業時間を登録してください';

  @override
  String timeSlotNumber(Object arg0) {
    return '$arg0限';
  }

  @override
  String get timeSlotRequired => '時限を選んでください';

  @override
  String get classDateConflict => '同じ実施日・時限に授業があります';

  @override
  String get datesAndSlots => '実施日と時限';

  @override
  String get courseDetails => '講義の詳細・メモ';

  @override
  String get addItem => '追加する';

  @override
  String get dayChanges => 'この日の変更';

  @override
  String get assignmentsDue => '提出する課題';

  @override
  String get noVisibleWeekdays => '表示する曜日がありません';

  @override
  String get chooseVisibleWeekdays => '設定で表示する曜日を選んでください。';

  @override
  String get goToSettings => '設定へ';

  @override
  String get daySchedule => 'この日の予定';

  @override
  String get changeDayAndTime => '曜日と時間を変更';

  @override
  String courseNameValue(Object arg0) {
    return '講義名: $arg0';
  }

  @override
  String destinationValue(Object arg0) {
    return '提出先: $arg0';
  }

  @override
  String relatedCourseValue(Object arg0) {
    return '該当の講義: $arg0';
  }

  @override
  String submissionTimeValue(Object arg0) {
    return '提出時間: $arg0';
  }

  @override
  String get noAssignmentsDue => 'この日が提出期限の課題はありません';

  @override
  String imageAlt(Object arg0) {
    return '[画像: $arg0]';
  }

  @override
  String roomAndInstructor(Object arg0, Object arg1) {
    return '教室  $arg0\n教員  $arg1';
  }

  @override
  String get noNotes => 'メモはまだありません。';

  @override
  String get courseTitle => '講義名';

  @override
  String get courseReminderLead => '開始何分前に通知（空欄: 全体設定、-1: オフ）';

  @override
  String get extraDateConditions => '実施期間の追加条件';

  @override
  String get optionalStartDate => '開始日（任意）';

  @override
  String get optionalEndDate => '終了日（任意）';

  @override
  String get checkAssignmentsAfterClass => '終了後に課題の確認を通知';

  @override
  String get markdownNotes => 'メモ（Markdown）';

  @override
  String get endDateBeforeStart => '終了日は開始日以降にしてください';

  @override
  String get configureTimeSlots => '設定で時限を登録してください';

  @override
  String get configureTeachingPeriod => '年間予定で講義期間を登録してください';

  @override
  String meetingSummary(Object arg0, Object arg1, Object arg2) {
    return '$arg0$arg1$arg2限';
  }

  @override
  String get deleteClassDate => 'この実施日を削除';

  @override
  String get classDateRequired => '実施日を追加してください';

  @override
  String get chooseSlotForEachDate => '実施日ごとに時限を選んでください';

  @override
  String get meetingConflict => '同じ曜日・実施日・時限に授業があります。別の時限を選んでください。';

  @override
  String sessionDetails(
    Object arg0,
    Object arg1,
    Object arg2,
    Object arg3,
    Object arg4,
    Object arg5,
  ) {
    return '$arg0  $arg1限\n$arg2–$arg3\n教室 $arg4\n教員 $arg5';
  }

  @override
  String get cancelledOnThisDay => 'この日は休講です';

  @override
  String replacementFor(Object arg0) {
    return '$arg0の振替';
  }

  @override
  String get recurringSettings => '定期設定';

  @override
  String classOnDate(Object arg0) {
    return '$arg0の授業';
  }

  @override
  String get cancelled => '休講';

  @override
  String get optionalReplacementDate => '振替日（任意）';

  @override
  String get replacementTimeSlot => '振替先のコマ';

  @override
  String get roomOverride => 'この日の教室（空欄: 元の設定）';

  @override
  String get reminderOverride => '開始何分前に通知（空欄: 元の設定、-1: オフ）';

  @override
  String get replacementDateMustDiffer => '振替日は元の日と異なる日を選んでください';

  @override
  String assignmentsDeleted(num arg0) {
    return '$arg0件の課題を削除しました';
  }

  @override
  String get undo => '元に戻す';

  @override
  String itemsSelected(Object arg0) {
    return '$arg0件選択中';
  }

  @override
  String get clearSelection => '選択を解除';

  @override
  String get done => '完了';

  @override
  String get showCompleted => '完了した課題も表示';

  @override
  String get defaultNotifications => '通知の初期設定';

  @override
  String get noAssignments => '課題はありません';

  @override
  String get addAssignmentHelp => '右下の＋から課題を登録できます。';

  @override
  String get viewAssignment => '課題を表示';

  @override
  String get editAssignment => '課題を編集';

  @override
  String get markIncomplete => '未完了に戻す';

  @override
  String get markComplete => '完了にする';

  @override
  String get deleteAssignment => '課題を削除';

  @override
  String weeksLater(num arg0) {
    return '$arg0週間後';
  }

  @override
  String deadlineHint(Object arg0, Object arg1, Object arg2, Object arg3) {
    return '$arg0の$arg1$arg2限目$arg3に提出';
  }

  @override
  String get registerAssignment => '課題を登録';

  @override
  String get assignmentName => '課題名';

  @override
  String get deadline => '提出期限';

  @override
  String get chooseDeadlineFromTimetable => '時間割から選択';

  @override
  String get destination => '提出先';

  @override
  String get notes => 'メモ';

  @override
  String get notifications => '通知';

  @override
  String get addNotification => '通知を追加';

  @override
  String get deadlineMinuteRequired => '提出期限を分まで入力してください';

  @override
  String get notificationAfterDeadline => '通知日時は期限以前にしてください';

  @override
  String get selectDeadline => '提出日時を選択';

  @override
  String get assignmentNotificationDefaults => '課題の通知・全体設定';

  @override
  String get assignmentNotificationDefaultsHelp =>
      '新しい課題へ初期値として入れます。空にすると初期値の通知はありません。';

  @override
  String get choosePeriodDates => '開始日、終了日の順にカレンダーを選択してください。';

  @override
  String get cancelPeriodSelection => '期間選択をやめる';

  @override
  String get desktopCalendarHelp =>
      'クリックで日ごとの変更・ダブルクリックで期間編集・ドラッグで期間追加。右クリックで操作一覧。';

  @override
  String get mobileCalendarHelp => 'タップで日ごとの変更・長押しで期間編集・長押ししてなぞると期間追加。';

  @override
  String get deleteDayChanges => 'この日の変更を削除';

  @override
  String get dailyChanges => '日ごとの変更';

  @override
  String get viewDayClasses => 'この日の講義を確認';

  @override
  String get editDayPeriod => 'この日の期間を編集';

  @override
  String editNamed(Object arg0) {
    return '$arg0を編集';
  }

  @override
  String deleteNamedAction(Object arg0) {
    return '$arg0を削除';
  }

  @override
  String get period => '期間';

  @override
  String get mergedPeriodName => 'まとめた期間の名前（任意）';

  @override
  String get registerPeriod => '期間を登録';

  @override
  String get editPeriod => '期間を編集';

  @override
  String get type => '種類';

  @override
  String get universityClosure => '全学休業日・長期休暇';

  @override
  String get optionalName => '名前（任意）';

  @override
  String get startDate => '開始日';

  @override
  String get endDate => '終了日';

  @override
  String get deleteDateRange => 'この日程を削除';

  @override
  String get addDateRange => '日程を追加';

  @override
  String universityDaySettings(Object arg0) {
    return '$arg0の全学設定';
  }

  @override
  String get universityClosed => '全学休業';

  @override
  String get optionalUniversityReplacement => 'この日の代替日（任意）';

  @override
  String get replacementTimetable => '代わりの時間割';

  @override
  String get universityReplacementHelp => '全学代替日は、その日に本来ある曜日の講義を置き換えます。';

  @override
  String get universityReplacementMustDiffer => '代替日は別の日を指定してください';

  @override
  String get universityReplacementConflict => '代替先には既に全学設定があります。別の日を選んでください';

  @override
  String holidayDataRange(Object arg0, Object arg1) {
    return '同梱の祝日データは$arg0～$arg1年です。この年度の全祝日を登録するにはデータの更新が必要です。';
  }

  @override
  String importHolidaysForYear(Object arg0) {
    return '$arg0年度の祝日を休業日に';
  }

  @override
  String importHolidaysConfirmation(Object arg0, Object arg1, Object arg2) {
    return '$arg0日の祝日・振替休日等を登録します。同じIDで登録済みの祝日は重複しません。\n出典: 内閣府（$arg1～$arg2年、オフラインデータ）';
  }

  @override
  String get register => '登録';

  @override
  String holidaysImported(num arg0) {
    return '$arg0日の祝日を登録しました';
  }

  @override
  String get general => '一般';

  @override
  String get displaySettings => '表示設定';

  @override
  String get operationSettings => '操作設定';

  @override
  String get accessibility => 'アクセシビリティ';

  @override
  String get about => 'このアプリについて';

  @override
  String version(Object arg0) {
    return 'バージョン: $arg0';
  }

  @override
  String get author => '制作者';

  @override
  String get name => '名前';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get license => 'ライセンス';

  @override
  String get files => 'ファイル';

  @override
  String get openUnitable => '.unitableを開く';

  @override
  String monthNumber(String arg0) {
    return '$arg0月';
  }

  @override
  String get weekStartsOn => '週の開始曜日';

  @override
  String get appearance => '配色';

  @override
  String get theme => 'テーマ';

  @override
  String get followSystem => '端末に合わせる';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get oledBackground => '有機EL用の黒い背景';

  @override
  String get timetableDisplay => '時間割の表示';

  @override
  String get continuousDisplay => '連続表示';

  @override
  String get timeSlotWidth => 'コマ幅';

  @override
  String get courseFontSize => '科目名の文字サイズ';

  @override
  String get roomFontSize => '教室名の文字サイズ';

  @override
  String get hiddenWeekdays => '時間割に表示しない曜日';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get colorPalette => 'カラーパレット';

  @override
  String get calendarPriority => '年間予定の表示優先順位';

  @override
  String get longPressDuration => '長押しの判定時間';

  @override
  String get enableNotifications => '通知を使う';

  @override
  String get notificationsUnavailable => 'この版では通知を利用できません。';

  @override
  String get notificationTest => '通知テスト（テストAPK限定）';

  @override
  String get notificationTestHelp => '課題確認通知と「課題を追加」を確認できます。予約は最新の1件です。';

  @override
  String get testCourse => 'テストする科目';

  @override
  String get testNow => '今すぐ通知をテスト';

  @override
  String get testInThirtySeconds => '30秒後に通知をテスト';

  @override
  String get testInFiveMinutes => '5分後に通知をテスト';

  @override
  String get allowExactAlarms => '正確な時刻の通知を許可';

  @override
  String get exactAlarmHelp => '端末の「アラームとリマインダー」を許可すると通知の遅れを軽減できます。';

  @override
  String get batterySettings => '省電力設定を確認';

  @override
  String get batterySettingsHelp => '通知が遅れる場合は、アプリ情報からバッテリーの制限を見直してください。';

  @override
  String get notifyRoom => '教室を通知する';

  @override
  String minutesBeforeClass(num arg0) {
    return '講義開始$arg0分前';
  }

  @override
  String get newAssignmentNotifications => '新しい課題の通知タイミング';

  @override
  String get holidayDefinition => '休日の定義';

  @override
  String get universityTimezone => '大学のタイムゾーン';

  @override
  String get msixSchedulingHelp => 'Windowsで予約の取消・再設定を確実に行うにはMSIX版を使用してください。';

  @override
  String get schedulingLimit => '予約は今後1年分のうち直近480件までです。起動・画面復帰時に補充します。';

  @override
  String get reduceMotion => '動きを減らす';

  @override
  String get colorVisionSupport => '色覚に配慮した表示';

  @override
  String get strongerText => '文字色を濃くする';

  @override
  String get backToSettings => '設定一覧に戻る';

  @override
  String get durationMilliseconds => '時間（ミリ秒）';

  @override
  String get positiveMilliseconds => '1以上のミリ秒を入力してください';

  @override
  String get widthPixels => '幅（px）';

  @override
  String get slotWidthRange => '40〜600の数値を入力してください';

  @override
  String get paletteToEdit => '編集する配色';

  @override
  String get teachingPeriodColors => '講義期間の9色';

  @override
  String get examPeriodColors => '試験期間の9色';

  @override
  String colorIndex(Object arg0) {
    return '$arg0番目';
  }

  @override
  String get resetPalette => 'この配色を初期値に戻す';

  @override
  String get resetDefaults => '初期値に戻す';

  @override
  String get specifyRgba => 'RGBAで指定';

  @override
  String get rgbaRange => '0〜255の整数を入力してください';

  @override
  String get fontSize => '文字サイズ';

  @override
  String get fontSizeRange => '8〜36の数値を入力してください';

  @override
  String get closuresAndHolidays => '休業日・祝日';

  @override
  String get noClassDays => '講義がない日';

  @override
  String get onlyDaysWithoutClasses => '講義がない日に限定する';

  @override
  String get roomNotifications => '教室の通知';

  @override
  String get minutesBeforeStart => '開始何分前';

  @override
  String get nonNegativeMinutes => '0以上の分数を入力してください';

  @override
  String get searchRegion => '地域を検索';

  @override
  String get notificationPermissionHelp => '通知の許可が必要です。端末の設定を確認してください。';

  @override
  String get start => '開始';

  @override
  String get end => '終了';

  @override
  String get changeStartTime => '開始時刻を変更';

  @override
  String get changeEndTime => '終了時刻を変更';

  @override
  String get deleteTimeSlot => 'コマを削除';

  @override
  String minutesValue(Object arg0) {
    return '$arg0分';
  }

  @override
  String deleteSlotNumber(Object arg0) {
    return '$arg0限を削除';
  }

  @override
  String slotTimeTitle(Object arg0) {
    return '$arg0限の時間';
  }

  @override
  String startTimeValue(Object arg0) {
    return '開始 $arg0';
  }

  @override
  String endTimeValue(Object arg0) {
    return '終了 $arg0';
  }

  @override
  String get endTimeAfterStart => '終了時刻は開始時刻より後にしてください';

  @override
  String slotTimeHelp(Object arg0, Object arg1) {
    return '$arg0限の$arg1時刻';
  }

  @override
  String get timeSlotInUse => 'このコマを使う講義があります。先に授業を変更してください。';

  @override
  String get exportFolderOccupied =>
      '書き出し先にuniversity.unitableがあります。空のフォルダーを選んでください。';

  @override
  String get chooseAnotherFilename => '既存のファイルは上書きしません。別の名前を選んでください。';

  @override
  String get databaseExported => 'データベースのコピーを書き出しました';

  @override
  String get chooseDatabase => '使う.unitableファイルを指定してください。';

  @override
  String get notRegistered => '未登録';

  @override
  String scheduledThrough(Object arg0) {
    return '・$arg0まで';
  }

  @override
  String get scheduleRefillHelp => '（起動・画面復帰時に予約を補充）';

  @override
  String get inexactAlarmWarning => '・正確な時刻の通知が未許可のため遅れる場合があります';

  @override
  String get cancelledSuffix => '・休講';

  @override
  String get replacement => '振替';

  @override
  String get versionUnavailable => '取得できません';

  @override
  String get language => '言語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String namedExamPeriod(String name) {
    return '$name試験期間';
  }

  @override
  String get storagePickerBusy => 'ファイル・フォルダーを選択中です。';

  @override
  String get storageEmptyFile => 'ファイルが空です。';

  @override
  String get storageVerificationFailed => '書き込んだデータを検証できません。';

  @override
  String get storageFolderPermission => 'フォルダーへの読み書き権限がありません。再度選択してください。';

  @override
  String get storageRecoveryFailed => '前回の保存ファイルを復元できません。';

  @override
  String get storageMissingDatabase => 'university.unitableがありません。';

  @override
  String get storageEmptyDatabase => 'データベースが空です。';

  @override
  String get storageNoData => '保存するデータがありません。';

  @override
  String get storageCleanupFailed => '以前のコピーを整理できません。';

  @override
  String get storageRenameUnsupported =>
      'このフォルダーは安全な更新に必要なファイル名変更に対応していません。別のローカルフォルダーを選んでください。';

  @override
  String get storageSaveFailed => 'データベースの保存を完了できません。';

  @override
  String get storageSelectFile => '.unitableファイルを指定してください。';

  @override
  String get storageFilePermission => '読み書きできるファイルを指定してください。';

  @override
  String fullWeekdayName(String arg0) {
    return '$arg0曜日';
  }

  @override
  String get examName => '科目名';

  @override
  String get academicYearStartsIn => '年度の開始月';

  @override
  String academicYearSingle(int year) {
    return '$year年度';
  }

  @override
  String academicYearRange(int startYear, int endYear) {
    return '$startYear年度';
  }

  @override
  String get universitySettings => '年度・授業時間';

  @override
  String get editSession => '休講・補講の設定';

  @override
  String get addMakeup => '補講を追加';

  @override
  String get editMakeup => '補講を編集';

  @override
  String get sessionNotes => 'この回のメモ';

  @override
  String get courseNotes => '講義全体のメモ';

  @override
  String get makeupCourseRequired => '先に講義を登録してください';

  @override
  String get sameSessionDestination => '補講先には休講と別の日付またはコマを指定してください';

  @override
  String get makeupLabel => '補講';

  @override
  String get makeupSlot => '補講のコマ';

  @override
  String get clearMakeupSlot => '補講先を解除';

  @override
  String get chooseMakeupFromTimetable => '時間割から補講のコマを選ぶ';

  @override
  String get selectMakeupSlot => '補講のコマを選択';

  @override
  String get sessionAddAssignment => '課題';

  @override
  String get sessionAddMakeup => '補講';

  @override
  String get cancelSessionQuestion => 'この回を休講にしますか？';

  @override
  String get chooseSessionMakeup => '補講を選択';

  @override
  String get cancelMakeupQuestion => '補講を取り消しますか？';

  @override
  String get cancelMakeup => '補講を取り消す';

  @override
  String get selectMakeupCourse => '補講の講義を選択';

  @override
  String get replaceLectureWithMakeupQuestion => 'もとの講義を休講にして登録しますか？';

  @override
  String get replaceOneOffWithMakeupQuestion => '単発講義を取り消して登録しますか？';
}
