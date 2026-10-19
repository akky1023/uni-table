import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide ContextAction;
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import '../app_info.dart';
import '../data/database.dart';
import '../domain/schedule.dart';
import '../domain/periods.dart';
import '../domain/course_groups.dart';
import '../domain/deadline_choice.dart';
import 'app_palette.dart';
import 'appearance.dart';
import 'selection_check.dart';
import 'accessibility.dart';
import 'status_marks.dart';
import 'color_palette.dart';
import 'timed_long_press.dart';
import '../services/notifications.dart';
import 'editors.dart';
import 'dialogs.dart';
import 'annual_calendar.dart';
import 'calendar_style.dart';
import 'timetable_scrolling.dart';
import 'context_actions.dart';

class Home extends StatefulWidget {
  final Storage storage;
  final bool enableNativeNotifications;
  final bool? desktop;
  final NotificationService? notificationService;
  const Home(
      {super.key,
      required this.storage,
      this.enableNativeNotifications = true,
      this.notificationService,
      this.desktop});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final notices = widget.notificationService ?? NotificationService();
  late final Future<String> applicationVersion = loadAppVersion();
  int page = 0;
  DateTime week = shiftDay(DateTime.now(), 1 - DateTime.now().weekday);
  late int year;
  bool timetableEditing = false,
      calendarEditing = false,
      showDone = false,
      saving = false;
  bool get desktop =>
      widget.desktop ?? (!Platform.isAndroid && !Platform.isIOS);
  int get weekStart => int.parse(data.setting('week_start', '1'));
  DateTime beginningOfWeek(DateTime date) =>
      shiftDay(dateOnly(date), -((date.weekday - weekStart + 7) % 7));
  List<int> get orderedWeekdays =>
      List.generate(7, (i) => (weekStart - 1 + i) % 7 + 1);
  Set<int> get hiddenWeekdays =>
      stringList(data.setting('hidden_weekdays', '["7"]'))
          .map(int.parse)
          .toSet();
  List<int> get visibleWeekdays =>
      orderedWeekdays.where((day) => !hiddenWeekdays.contains(day)).toList();
  double get timetableGutter => desktop ? 36 : 30;
  double get cellMargin => desktop ? 3 : 1;
  String selectedTerm = '';
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final selectedTasks = <String>{}, dismissedTasks = <String>{};
  bool askingBack = false;
  String? selectedExam;
  DateTime? examDate;
  bool calendarMenuOpen = false,
      selectingPeriod = false,
      returningToday = false;
  String? settingsCategory;
  final calendarScroll = ScrollController();
  final selectedPeriods = <String>{};
  bool calendarPositioned = false;
  double calendarOffset = 0;
  ScrollPosition? calendarPosition;
  bool animateCalendar = false;
  final calendarTodayKey = GlobalKey();
  bool get canNotify => widget.enableNativeNotifications && notices.available;
  Future<void> notificationQueue = Future.value();
  bool notificationRefreshPending = false;
  String? pendingNotificationCourse;
  bool notificationTaskOpen = false;
  String? notificationTestCourse;
  bool sendingTestNotification = false;
  UnitDatabase? editDraft;
  bool get editingPage => timetableEditing || calendarEditing;
  bool get hideNavigation => editingPage;
  UnitDatabase get db => editDraft ?? widget.storage.database;

  void beginDraft() {
    if (editDraft != null) return;
    editDraft = UnitDatabase.draftOf(widget.storage.database);
    editDraft!.addListener(changed);
  }

  Future<void> finishEditing({required bool save}) async {
    final draft = editDraft;
    if (draft == null || saving) return;
    saving = true;
    try {
      if (save) {
        await widget.storage.beforeWrite();
        final original = widget.storage.database;
        original.transaction(() {
          original.replaceContent(draft.data);
          original.appSettings
            ..clear()
            ..addAll(draft.appSettings);
        });
        await widget.storage.synchronize();
      }
      draft.removeListener(changed);
      editDraft = null;
      draft.dispose();
      timetableEditing = false;
      setCalendarEditing(false);
      if (save) refreshNotifications();
    } finally {
      saving = false;
      changed();
      final pending = pendingNotificationCourse;
      if (!editingPage && pending != null) {
        pendingNotificationCourse = null;
        openTaskFromNotification(pending);
      }
    }
  }

  SchoolData get data => db.data;
  ScheduleEngine get engine => ScheduleEngine(data);
  @override
  void initState() {
    super.initState();
    week = beginningOfWeek(DateTime.now());
    final start = int.parse(data.setting('year_start', '4'));
    year = DateTime.now().year - (DateTime.now().month < start ? 1 : 0);
    WidgetsBinding.instance.addObserver(this);
    db.addListener(changed);
    calendarScroll.addListener(() {
      if (calendarScroll.hasClients && calendarPositioned) {
        calendarOffset = calendarScroll.offset;
      }
    });
    if (canNotify) {
      notices.onAddTask = openTaskFromNotification;
      initializeNotifications();
    }
  }

  Future<void> initializeNotifications() async {
    try {
      await notices.initialize();
      if (mounted && data.setting('notifications', '0') == '1') {
        refreshNotifications();
      }
    } catch (_) {/* Display status in settings. */}
  }

  Future<void> testNotification(Duration delay) async {
    if (sendingTestNotification) return;
    final course = data.find('courses', notificationTestCourse) ??
        data.rows('courses').firstOrNull;
    if (course == null) {
      message('通知テストには講義を1件以上登録してください。');
      return;
    }
    setState(() => sendingTestNotification = true);
    try {
      if (data.setting('notifications', '0') != '1') {
        if (!await notices.requestPermission()) {
          message('通知の許可が必要です。');
          return;
        }
        await setting('notifications', '1');
      }
      await notificationQueue;
      if (!mounted) return;
      final sent = await notices.sendTestNotification(data, course, delay: delay);
      message(!sent ? '通知の許可が必要です。' : delay == Duration.zero
          ? 'テスト通知を送信しました。'
          : '${delay.inSeconds}秒後のテスト通知を予約しました。画面を閉じて確認できます。');
    } catch (e) {
      message('通知テストに失敗しました: $e');
    } finally {
      if (mounted) setState(() => sendingTestNotification = false);
    }
  }

  void openTaskFromNotification(String courseId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (data.find('courses', courseId) == null) {
        message('通知の講義が見つかりません。');
        return;
      }
      if (editingPage) {
        pendingNotificationCourse = courseId;
        message('編集中の変更を保存または破棄すると、課題追加画面を開きます。');
        return;
      }
      if (notificationTaskOpen) return;
      notificationTaskOpen = true;
      setState(() => page = 1);
      try {
        await editTask(courseId: courseId);
      } finally {
        notificationTaskOpen = false;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    notices.onAddTask = null;
    WidgetsBinding.instance.removeObserver(this);
    widget.storage.database.removeListener(changed);
    editDraft?.removeListener(changed);
    editDraft?.dispose();
    calendarScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        data.setting('notifications', '0') == '1') {
      refreshNotifications();
    }
  }

  void changed() {
    if (mounted) setState(() {});
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          content: Text(value)));
    }
  }

  void refreshNotifications() {
    if (!widget.enableNativeNotifications) return;
    if (notificationRefreshPending) return;
    notificationRefreshPending = true;
    notificationQueue = notificationQueue.then((_) async {
      notificationRefreshPending = false;
      if (!mounted) return;
      try {
        await notices.rebuild(data);
      } catch (_) {/* Display status in settings. */}
      changed();
    });
  }

  Future<void> commit(void Function() change) async {
    if (saving) throw StateError('保存中です。少し待ってからお試しください。');
    saving = true;
    try {
      if (editDraft != null) {
        db.transaction(change);
        return;
      }
      await widget.storage.beforeWrite();
      db.transaction(change);
      try {
        await widget.storage.synchronize();
      } catch (_) {
        message('指定フォルダーに保存できませんでした。設定画面から再試行できます。');
      }
      refreshNotifications();
    } finally {
      saving = false;
      changed();
    }
  }

  Future<void> put(String table, DbRow row) => commit(() => db.put(table, row));
  Future<void> remove(String table, DbRow row) => commit(() {
        if (table == 'day_changes' && row['replacement_date'] != null) {
          final linked = engine
              .dayChange(DateTime.parse(row['replacement_date'] as String));
          if (linked != null) db.remove('day_changes', linked['id'] as String);
        }
        db.remove(table, row['id'] as String);
        if (table == 'events') selectedPeriods.remove(row['id']);
      });
  Future<void> setting(String id, String value) =>
      put('settings', {'id': id, 'value': value});
  static const titles = ['時間割', '課題', '年間予定', '設定'];
  static const icons = [
    Icons.view_week_outlined,
    Icons.check_circle_outline,
    Icons.calendar_month_outlined,
    Icons.settings_outlined
  ];

  Widget modeControl(bool value, ValueChanged<bool> change) =>
      FilledButton.icon(
          onPressed: saving ? null : () => change(!value),
          icon: Icon(value ? Icons.check : Icons.edit_outlined, size: 18),
          label: Text(value ? '保存' : '編集'));

  Widget calendarFab() {
    final duration = data.setting('reduce_motion', '0') == '1'
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
              duration: duration,
              alignment: Alignment.bottomRight,
              child: AnimatedSwitcher(
                  duration: duration,
                  child: !calendarMenuOpen
                      ? const SizedBox.shrink(key: ValueKey('closed'))
                      : Column(
                          key: const ValueKey('open'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                              for (final action
                                  in <(String, IconData, VoidCallback)>[
                                ('期間を追加', Icons.date_range, selectPeriod),
                                (
                                  '期間をまとめる',
                                  Icons.merge_outlined,
                                  () => mergePeriods()
                                ),
                                (
                                  '祝日を休日にする',
                                  Icons.event_available_outlined,
                                  () => importHolidays()
                                ),
                              ])
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: FloatingActionButton.extended(
                                        heroTag: action.$1,
                                        onPressed: () {
                                          setState(
                                              () => calendarMenuOpen = false);
                                          action.$3();
                                        },
                                        icon: Icon(action.$2),
                                        label: Text(action.$1))),
                            ]))),
          FloatingActionButton(
              heroTag: 'annual-actions',
              tooltip: calendarMenuOpen ? '閉じる' : '年間予定の操作',
              onPressed: () =>
                  setState(() => calendarMenuOpen = !calendarMenuOpen),
              child: AnimatedRotation(
                  turns: calendarMenuOpen ? .125 : 0,
                  duration: duration,
                  child: StatusMark(
                      shape: 10,
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      label: calendarMenuOpen ? '閉じる' : '追加'))),
        ]);
  }

  List<ContextAction> get pageActions => [
        if (page == 0) ...[
          ContextAction(timetableEditing ? '閲覧モードに切り替え' : '編集モードに切り替え',
              () => startTimetableEditing(!timetableEditing)),
          ContextAction('講義を登録', () => editMeeting()),
          ContextAction('単発講義を登録', () => editMeeting(single: true)),
          ContextAction('前の週', () => setState(() => week = shiftDay(week, -7))),
          ContextAction('次の週', () => setState(() => week = shiftDay(week, 7))),
          ContextAction(
              '今週',
              week == beginningOfWeek(DateTime.now())
                  ? null
                  : () =>
                      setState(() => week = beginningOfWeek(DateTime.now()))),
        ],
        if (page == 1) ContextAction('課題を追加', () => editTask()),
        if (page == 2) ...[
          ContextAction(calendarEditing ? '閲覧モードに切り替え' : '編集モードに切り替え',
              () => setCalendarEditing(!calendarEditing)),
          ContextAction('期間を追加', selectPeriod),
          ContextAction('祝日を休日にする', importHolidays),
          ContextAction('前の年度', () => setState(() => year--)),
          ContextAction('次の年度', () => setState(() => year++)),
        ],
        if (page == 3) ...[
          ContextAction('新しい.unitableを作成', () => openDatabase(create: true)),
          ContextAction('コピーを書き出す', exportDatabase),
          ContextAction('データベースを開く', openDatabase),
          ContextAction('コマを追加', () => editSlot()),
          ContextAction('教室の通知タイミングを変更', canNotify ? editLeadTiming : null),
          ContextAction(
              '教室通知をオン／オフ',
              canNotify
                  ? () => setting(
                      'lead_minutes',
                      data.leadMinutes < 0
                          ? data.setting('last_lead_minutes', '10')
                          : '-1')
                  : null),
          ContextAction('課題の通知設定', editGlobalRules),
          ContextAction('大学のタイムゾーン設定', editTimezone),
          ContextAction(
              data.setting('notifications', '0') == '1'
                  ? '通知をオフにする'
                  : '通知をオンにする',
              canNotify
                  ? () => toggleNotifications(
                      data.setting('notifications', '0') != '1')
                  : null),
        ],
      ];

  void selectPage(int index) {
    scaffoldKey.currentState?.closeDrawer();
    if (page == index && index == 2) {
      returnToToday();
    } else if (page == index && index == 0) {
      setState(() => week = beginningOfWeek(DateTime.now()));
    } else if (page == index && index == 3) {
      setState(() => settingsCategory = null);
    } else {
      setState(() {
        page = index;
        selectedTasks.clear();
      });
    }
  }

  void startTimetableEditing(bool editing) {
    if (!editing && editDraft != null) {
      finishEditing(save: true).catchError((Object e) => message(e.toString()));
      return;
    }
    if (editing && !timetableEditing) {
      beginDraft();
      final end = shiftDay(
          week, data.setting('timetable_scroll', 'week') == 'smooth' ? 13 : 6);
      final relevant = timetablePeriods(data)
          .where((e) =>
              (e['start_date'] as String).compareTo(dayKey(end)) <= 0 &&
              (e['end_date'] as String).compareTo(dayKey(week)) >= 0)
          .toList()
        ..sort((a, b) =>
            (a['start_date'] as String).compareTo(b['start_date'] as String));
      final initial =
          relevant.firstOrNull ?? timetablePeriods(data).firstOrNull;
      if (initial != null) {
        selectedExam =
            initial['kind'] == 'exam' ? initial['id'] as String : null;
        selectedTerm = initial['id'] as String;
      }
    }
    setState(() => timetableEditing = editing);
  }

  void setCalendarEditing(bool editing) {
    if (!editing && editDraft != null) {
      finishEditing(save: true).catchError((Object e) => message(e.toString()));
      return;
    }
    if (editing) beginDraft();
    final box = calendarTodayKey.currentContext?.findRenderObject();
    final before = box is RenderBox ? box.localToGlobal(Offset.zero).dy : null;
    setState(() {
      calendarEditing = editing;
      selectingPeriod = false;
      calendarMenuOpen = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final after = calendarTodayKey.currentContext?.findRenderObject();
      if (mounted &&
          before != null &&
          after is RenderBox &&
          calendarScroll.hasClients) {
        calendarOffset = (calendarScroll.offset +
                after.localToGlobal(Offset.zero).dy -
                before)
            .clamp(0.0, calendarScroll.position.maxScrollExtent);
        calendarScroll.jumpTo(calendarOffset);
      }
    });
  }

  Future<void> leaveEditing() async {
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      scaffoldKey.currentState!.closeDrawer();
      return;
    }
    if (askingBack || saving) return;
    askingBack = true;
    final result = await showAppDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: const Text('変更を保存しますか？'), actions: [
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('編集を破棄')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('保存')),
            ]));
    askingBack = false;
    if (result != null && mounted) {
      try {
        await finishEditing(save: result);
      } catch (e) {
        message(e.toString());
      }
    }
  }

  Future<bool?> editForm(
      BuildContext ctx,
      String title,
      Widget Function(BuildContext, StateSetter) body,
      Future<bool> Function() save,
      {Future<void> Function()? delete,
      bool fullScreen = false,
      bool topAligned = false,
      bool bottomSheet = false}) async {
    return await editor(ctx, title, body, save,
        delete: delete,
        fullScreen: fullScreen,
        topAligned: topAligned,
        bottomSheet: bottomSheet, onBackSaved: () async {
      if (editDraft != null) await finishEditing(save: true);
    });
  }

  Widget preferenceSwitch(
          {EdgeInsetsGeometry? contentPadding,
          required Widget title,
          Widget? subtitle,
          required bool value,
          required ValueChanged<bool>? onChanged}) =>
      ListTile(
          contentPadding: contentPadding,
          title: title,
          subtitle: subtitle,
          onTap: onChanged == null ? null : () => onChanged(!value),
          trailing: AppToggle(
              value: value,
              onChanged: onChanged,
              marks: data.setting('accessibility_marks', '0') == '1',
              still: data.setting('reduce_motion', '0') == '1'));

  Widget navigation() =>
      ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('うに時間割', style: TextStyle(fontSize: 20))),
        for (var i = 0; i < titles.length; i++)
          ListTile(
              selected: page == i,
              leading: Icon(icons[i]),
              title: Text(titles[i]),
              onTap: () => selectPage(i)),
      ]);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final openMenu = desktop && size.maxWidth >= 1000 && !hideNavigation;
        final header = Row(children: [
          if (editingPage)
            IconButton(
                tooltip: '編集から戻る',
                onPressed: leaveEditing,
                icon: const Icon(Icons.arrow_back)),
          if (desktop && !openMenu && !hideNavigation)
            IconButton(
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu)),
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(titles[page],
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w600)))),
          if (saving)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
          if (page == 0) modeControl(timetableEditing, startTimetableEditing),
          if (page == 2) modeControl(calendarEditing, setCalendarEditing),
        ]);
        return PopScope(
            canPop: !(page == 0 && timetableEditing ||
                page == 2 && calendarEditing),
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop &&
                  (page == 0 && timetableEditing ||
                      page == 2 && calendarEditing)) {
                leaveEditing();
              }
            },
            child: Scaffold(
              key: scaffoldKey,
              drawerEnableOpenDragGesture: false,
              floatingActionButtonAnimator:
                  data.setting('reduce_motion', '0') == '1'
                      ? FloatingActionButtonAnimator.noAnimation
                      : FloatingActionButtonAnimator.scaling,
              drawer: desktop && !openMenu && !hideNavigation
                  ? Drawer(child: SafeArea(child: navigation()))
                  : null,
              floatingActionButton: page == 1
                  ? FloatingActionButton(
                      tooltip: '課題を追加',
                      onPressed: () => editTask(),
                      child: const Icon(Icons.add))
                  : page == 2 && calendarEditing
                      ? calendarFab()
                      : null,
              body: Stack(children: [
                SafeArea(
                    child: Row(children: [
                  if (openMenu)
                    SizedBox(
                        width: 220,
                        child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            child: navigation())),
                  Expanded(
                      child: ContextActions(
                          desktop: desktop,
                          actions: pageActions,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 18, 16, 12),
                                    child: KeyedSubtree(
                                        key: ValueKey(
                                            'header-$page-$editingPage'),
                                        child: header)),
                                if (widget.storage.pendingSyncError != null)
                                  MaterialBanner(
                                      content:
                                          const Text('指定フォルダーに未保存の変更があります。'),
                                      actions: [
                                        TextButton(
                                            onPressed: () async {
                                              try {
                                                await widget.storage
                                                    .synchronize();
                                                changed();
                                              } catch (e) {
                                                message(e.toString());
                                              }
                                            },
                                            child: const Text('再試行'))
                                      ]),
                                Expanded(
                                    child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                !desktop && page == 0 ? 0 : 16),
                                        child: switch (page) {
                                          0 => timetableEditing
                                              ? timetableEditor()
                                              : timetable(),
                                          1 => tasks(),
                                          2 => calendar(),
                                          _ => settings(),
                                        })),
                              ]))),
                ])),
                if (calendarMenuOpen)
                  Positioned.fill(
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => calendarMenuOpen = false),
                          child: const ColoredBox(color: Colors.transparent))),
              ]),
              bottomNavigationBar: desktop || hideNavigation
                  ? null
                  : NavigationBar(
                      selectedIndex: page,
                      onDestinationSelected: selectPage,
                      destinations: [
                          for (var i = 0; i < titles.length; i++)
                            NavigationDestination(
                                icon: Icon(icons[i]),
                                label: titles[i],
                                tooltip: ''),
                        ]),
            ));
      });

  Future<void> confirmRemove(String table, DbRow row, String name) async {
    final confirmed = await showAppDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(title: Text('$nameを削除しますか？'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('削除'))
            ]));
    if (confirmed == true) await remove(table, row);
  }

  String get editingTerm => data.find('events', selectedTerm)?['kind'] ==
          'teaching'
      ? selectedTerm
      : timetablePeriods(data)
              .where((e) => e['kind'] == 'teaching')
              .firstOrNull?['id'] as String? ??
          '';
  String meetingTerm(DbRow meeting) =>
      meeting['period_id'] as String? ??
      data
          .rows('events')
          .where((e) =>
              e['kind'] == 'teaching' && e['term_id'] == meeting['term_id'])
          .firstOrNull?['id'] as String? ??
      '';

  List<DbRow> cellMeetings(DbRow slot, int day) => data
      .rows('meetings')
      .where((m) =>
          m['once_date'] == null &&
          m['weekday'] == day &&
          m['slot_id'] == slot['id'] &&
          meetingTerm(m) == editingTerm)
      .toList();
  Future<void> deleteCellMeetings(List<DbRow> meetings,
      {String title = 'この時間の授業を削除しますか？'}) async {
    if (meetings.length == 1) {
      await confirmRemove('meetings', meetings.first, '授業');
      return;
    }
    final approved = await showAppDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(title: Text(title), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('削除'))
            ]));
    if (approved == true) {
      await commit(() {
        for (final m in meetings) {
          db.remove('meetings', m['id'] as String);
        }
      });
    }
  }

  Widget timetableEditor() {
    if (selectedExam != null &&
        data.find('events', selectedExam)?['kind'] != 'exam') {
      selectedExam = null;
    }
    final periods = timetablePeriods(data);
    if (periods.isNotEmpty &&
        !periods.any((e) => e['id'] == (selectedExam ?? editingTerm))) {
      selectedTerm = periods.first['id'] as String;
      selectedExam = periods.first['kind'] == 'exam' ? selectedTerm : null;
    }
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          if (timetablePeriods(data).isNotEmpty)
            choice(
                '編集する期間',
                selectedExam ?? editingTerm,
                {
                  for (final period in timetablePeriods(data))
                    period['id'] as String: timetablePeriods(data)
                                .where((e) =>
                                    periodLabel(data, e) ==
                                    periodLabel(data, period))
                                .length >
                            1
                        ? '${periodLabel(data, period)} (${period['start_date']}–${period['end_date']})'
                        : periodLabel(data, period),
                },
                (id) => setState(() {
                      selectedTerm = id;
                      selectedExam = data.find('events', id)?['kind'] == 'exam'
                          ? id
                          : null;
                    })),
          const SizedBox(height: 12),
          if (selectedExam != null)
            examEditor()
          else if (editingTerm.isEmpty)
            empty('講義期間を登録してください', '年間予定で講義期間を登録すると、時間割を編集できます。',
                label: '年間予定へ', action: () => setState(() => page = 2))
          else
            lectureEditorGrid(),
          const SizedBox(height: 18),
          section('単発講義', [
            for (final group in intensiveGroups) intensiveEntry(group),
            TextButton.icon(
                onPressed: () => editMeeting(single: true),
                icon: const Icon(Icons.add),
                label: const Text('単発講義を追加'))
          ])
        ]);
  }

  Widget lectureEditorGrid() {
    final height = timetableRowHeight;
    return LayoutBuilder(builder: (context, size) {
      final width = data.setting('timetable_scroll', 'week') == 'smooth'
          ? continuousColumnWidth
          : (size.maxWidth - timetableGutter) / max(1, visibleWeekdays.length);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: timetableGutter,
            child: Column(children: [
              const SizedBox(height: 64),
              for (final slot in data.slots)
                SizedBox(height: height, child: slotLabel(slot))
            ])),
        Expanded(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: data.setting('timetable_scroll', 'week') == 'smooth'
                    ? null
                    : const NeverScrollableScrollPhysics(),
                child: SizedBox(
                    width: width * visibleWeekdays.length,
                    child: Column(children: [
                      SizedBox(
                          height: 64,
                          child: Row(children: [
                            for (final day in visibleWeekdays)
                              Expanded(
                                  child: Center(
                                      child: Text('${weekdays[day - 1]}曜日')))
                          ])),
                      for (final slot in data.slots)
                        SizedBox(
                            height: height,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final day in visibleWeekdays)
                                    Expanded(child: editorCell(slot, day))
                                ])),
                    ])))),
      ]);
    });
  }

  double get continuousColumnWidth =>
      double.tryParse(
          data.setting('timetable_column_width', desktop ? '120' : '80')) ??
      (desktop ? 120 : 80);
  Widget examEditor() {
    final period = data.find('events', selectedExam)!;
    final start = DateTime.parse(period['start_date'] as String),
        end = DateTime.parse(period['end_date'] as String);
    final dates = [
      for (var d = start; !d.isAfter(end); d = shiftDay(d, 1))
        if (engine.contains(period, d)) d
    ];
    final height = 64 + timetableRowHeight * data.slots.length;
    return SizedBox(
        height: height,
        child: LayoutBuilder(builder: (context, size) {
          final width = data.setting('timetable_scroll', 'week') == 'smooth'
              ? continuousColumnWidth
              : ((size.maxWidth - timetableGutter) /
                      max(1, visibleWeekdays.length))
                  .clamp(24, double.infinity);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: timetableGutter,
                child: Column(children: [
                  const SizedBox(height: 64),
                  for (final slot in data.slots)
                    SizedBox(height: timetableRowHeight, child: slotLabel(slot))
                ])),
            Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemExtent: width.toDouble(),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                                height: 64,
                                child: Center(
                                    child: Text(
                                        '${weekdays[date.weekday - 1]}\n${date.month}/${date.day}',
                                        textAlign: TextAlign.center))),
                            for (final slot in data.slots)
                              SizedBox(
                                  height: timetableRowHeight,
                                  child: Builder(builder: (context) {
                                    final meeting = data
                                        .rows('meetings')
                                        .where((m) =>
                                            m['exam_period_id'] ==
                                                selectedExam &&
                                            m['once_date'] == dayKey(date) &&
                                            m['slot_id'] == slot['id'])
                                        .firstOrNull;
                                    void edit() => editExam(selectedExam!, date,
                                        slot['id'] as String,
                                        row: meeting);
                                    return Padding(
                                        padding: EdgeInsets.all(cellMargin),
                                        child: ContextActions(
                                            desktop: desktop,
                                            actions: [
                                              ContextAction(
                                                  meeting == null
                                                      ? '試験を登録'
                                                      : '試験を編集',
                                                  edit),
                                              if (meeting != null)
                                                ContextAction(
                                                    '試験を削除',
                                                    () => confirmRemove(
                                                        'meetings',
                                                        meeting,
                                                        '試験'))
                                            ],
                                            child: timetableEditTile(
                                                color: appColor(
                                                    context, data, 'exam'),
                                                onTap: edit,
                                                name: meeting == null
                                                    ? null
                                                    : data.find(
                                                                'courses',
                                                                meeting['course_id']
                                                                    as String)?['name']
                                                            as String? ??
                                                        '',
                                                room: meeting?['room']
                                                        as String? ??
                                                    '')));
                                  })),
                          ]);
                    })),
          ]);
        }));
  }

  Future<void> editExam(String periodId, DateTime date, String slotId,
      {DbRow? row}) async {
    final course = data.find('courses', row?['course_id'] as String?);
    final name = text(course?['name']),
        room = text(row?['room'] ?? course?['room']),
        teacher = text(course?['teacher']);
    await editForm(
        context,
        row == null ? '試験を登録' : '試験を編集',
        (_, set) => Column(children: [
              Text(
                  '${dayKey(date)}・${data.find('slots', slotId)?['position']}限'),
              HistoryField(
                  controller: name,
                  label: '科目名',
                  history: history('name'),
                  required: true),
              HistoryField(
                  controller: room, label: '教室名', history: history('room')),
              HistoryField(
                  controller: teacher,
                  label: '教員名',
                  history: history('teacher')),
            ]), () async {
      if (data.rows('meetings').any((m) =>
          m['id'] != row?['id'] &&
          m['exam_period_id'] == periodId &&
          m['once_date'] == dayKey(date) &&
          m['slot_id'] == slotId)) {
        throw const FormatException('この時限には試験が登録されています');
      }
      final courseId = course?['id'] as String? ?? newId();
      await commit(() {
        db.put('courses', {
          'id': courseId,
          'name': name.text,
          'room': room.text,
          'teacher': teacher.text
        });
        db.put('meetings', {
          'id': row?['id'] ?? newId(),
          'course_id': courseId,
          'slot_id': slotId,
          'once_date': dayKey(date),
          'exam_period_id': periodId,
          'room': room.text
        });
        remember('name', name.text);
        remember('room', room.text);
        remember('teacher', teacher.text);
      });
      return true;
    },
        bottomSheet: true,
        delete: row == null ? null : () => remove('meetings', row));
    name.dispose();
    room.dispose();
    teacher.dispose();
  }

  Widget editorCell(DbRow slot, int day) {
    final meetings = cellMeetings(slot, day);
    void add() => editMeeting(slotId: slot['id'] as String, weekdayValue: day);
    return ContextActions(
        desktop: desktop,
        actions: meetings.isEmpty
            ? [ContextAction('講義を追加', add)]
            : [
                for (final m in meetings)
                  ContextAction('授業を編集', () => editMeeting(row: m)),
                ContextAction('授業を削除', () => deleteCellMeetings(meetings))
              ],
        child: Padding(
            key: ValueKey('editor-${slot['id']}-$day'),
            padding: EdgeInsets.all(cellMargin),
            child: meetings.isEmpty
                ? Tooltip(
                    message: '講義を登録',
                    child: timetableEditTile(
                        color: appColor(context, data, 'lecture'), onTap: add))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        for (final meeting in meetings)
                          Expanded(child: meetingEntry(meeting))
                      ])));
  }

  Widget timetableEditTile(
          {required Color color,
          required VoidCallback onTap,
          String? name,
          String room = ''}) =>
      Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: name == null
                      ? const Center(child: Icon(Icons.add))
                      : Column(children: [
                          Expanded(
                              child: Center(
                                  child: Text(name,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center))),
                          Text(room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                        ]))));

  List<List<DbRow>> get intensiveGroups {
    final groups = <String, List<DbRow>>{};
    for (final meeting in data
        .rows('meetings')
        .where((m) => m['once_date'] != null && m['exam_period_id'] == null)) {
      groups.putIfAbsent(meeting['course_id'] as String, () => []).add(meeting);
    }
    return groups.values.toList();
  }

  String intensiveDates(List<DbRow> group) {
    final dates = <String, List<int>>{};
    for (final meeting in group) {
      dates.putIfAbsent(meeting['once_date'] as String, () => []).add(
          data.find('slots', meeting['slot_id'] as String)!['position'] as int);
    }
    final keys = dates.keys.toList()..sort();
    return keys.map((day) {
      dates[day]!.sort();
      return '$day(${dates[day]!.join(', ')})';
    }).join('\n');
  }

  Widget intensiveEntry(List<DbRow> group) {
    final course = data.find('courses', group.first['course_id'] as String)!;
    return ContextActions(
        desktop: desktop,
        actions: [
          ContextAction('実施日を編集', () => showIntensiveGroup(group)),
          ContextAction('講義を編集', () => editCourse(course)),
          ContextAction('まとめて削除',
              () => deleteCellMeetings(group, title: 'この講義の実施日をまとめて削除しますか？')),
        ],
        child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(course['name'] as String),
            subtitle: Text(intensiveDates(group)),
            onTap: () => showIntensiveGroup(group)));
  }

  Future<void> showIntensiveGroup(List<DbRow> group) async {
    final courseId = group.first['course_id'] as String;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
              final course = data.find('courses', courseId)!;
              final meetings = data
                  .rows('meetings')
                  .where((m) =>
                      m['course_id'] == courseId && m['once_date'] != null)
                  .toList();
              final dates = meetings
                  .map((m) => m['once_date'] as String)
                  .toSet()
                  .toList()
                ..sort();
              return Scaffold(
                appBar: AppBar(title: const Text('実施日')),
                body: ListView(padding: const EdgeInsets.all(16), children: [
                  ListTile(
                      title: Text(course['name'] as String),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () async {
                        await editCourse(course);
                        if (ctx.mounted) {
                          if (data.find('courses', courseId) == null) {
                            Navigator.pop(ctx);
                          } else {
                            set(() {});
                          }
                        }
                      }),
                  for (final date in dates)
                    ListTile(
                        title: Text(intensiveDates(meetings
                            .where((m) => m['once_date'] == date)
                            .toList())),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await editSingleDate(courseId, oldDate: date);
                          if (ctx.mounted) set(() {});
                        }),
                ]),
                bottomNavigationBar: SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('実施日を追加'),
                            onPressed: () async {
                              await editSingleDate(courseId);
                              if (ctx.mounted) set(() {});
                            }))),
              );
            })));
  }

  Future<void> editSingleDate(String courseId, {String? oldDate}) async {
    if (data.slots.isEmpty) {
      message('設定で授業時間を登録してください');
      return;
    }
    final previous = data
        .rows('meetings')
        .where((m) => m['course_id'] == courseId && m['once_date'] == oldDate)
        .toList();
    final date = text(oldDate ?? dayKey(DateTime.now()));
    final slots = previous.isEmpty
        ? <String>{data.slots.first['id'] as String}
        : previous.map((m) => m['slot_id'] as String).toSet();
    await editForm(
        context,
        oldDate == null ? '実施日を追加' : '実施日を編集',
        (ctx, set) => Column(children: [
              dateField(ctx, date, '実施日'),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final slot in data.slots)
                  SelectionCheck(
                      label: Text('${slot['position']}限'),
                      selected: slots.contains(slot['id']),
                      onSelected: (selected) => set(() {
                            selected
                                ? slots.add(slot['id'] as String)
                                : slots.remove(slot['id']);
                          })),
              ]),
            ]), () async {
      if (slots.isEmpty) throw const FormatException('時限を選んでください');
      if (data.rows('meetings').any((m) =>
          !previous.any((old) => old['id'] == m['id']) &&
          m['once_date'] == date.text &&
          slots.contains(m['slot_id']))) {
        throw const FormatException('同じ実施日・時限に授業があります');
      }
      await commit(() {
        for (final old
            in previous.where((m) => !slots.contains(m['slot_id']))) {
          db.remove('meetings', old['id'] as String);
        }
        for (final slot in slots) {
          final old = previous.where((m) => m['slot_id'] == slot).firstOrNull;
          db.put('meetings', {
            'id': old?['id'] ?? newId(),
            'course_id': courseId,
            'slot_id': slot,
            'once_date': date.text,
            'weekday': null,
            'term_id': null
          });
        }
      });
      return true;
    },
        delete: oldDate == null
            ? null
            : () => commit(() {
                  for (final old in previous) {
                    db.remove('meetings', old['id'] as String);
                  }
                }));
    date.dispose();
  }

  Future<Map<String, dynamic>?> pickSingleEntry(BuildContext context,
      {String? date, Set<String>? selected}) async {
    final value = text(date ?? dayKey(DateTime.now()));
    final slots = {...?selected};
    if (selected == null) slots.add(data.slots.first['id'] as String);
    Map<String, dynamic>? result;
    await editForm(
        context,
        '実施日と時限',
        (ctx, set) => Column(children: [
              dateField(ctx, value, '実施日'),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final slot in data.slots)
                  SelectionCheck(
                      label: Text('${slot['position']}限'),
                      selected: slots.contains(slot['id']),
                      onSelected: (v) => set(() {
                            v
                                ? slots.add(slot['id'] as String)
                                : slots.remove(slot['id']);
                          })),
              ]),
            ]), () async {
      if (slots.isEmpty) throw const FormatException('時限を選んでください');
      result = {'date': value.text, 'slots': slots};
      return true;
    });
    value.dispose();
    return result;
  }

  Widget meetingEntry(DbRow meeting) {
    final course = data.find('courses', meeting['course_id'] as String?)!;
    return ContextActions(
        desktop: desktop,
        actions: [
          ContextAction('授業を編集', () => editMeeting(row: meeting)),
          ContextAction('講義を編集', () => editCourse(course)),
          ContextAction('講義の詳細・メモ', () => showCourse(course)),
          ContextAction(
              '授業を削除', () => confirmRemove('meetings', meeting, '授業')),
        ],
        child: timetableEditTile(
            color: appColor(context, data, 'lecture'),
            onTap: () => editMeeting(row: meeting),
            name: course['name'] as String,
            room: meeting['room'] as String? ?? course['room'] as String));
  }

  Widget empty(String title, String detail,
          {VoidCallback? action, String label = '追加する'}) =>
      Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.edit_calendar_outlined,
                    size: 36, color: Color(0xff69746a)),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(detail, textAlign: TextAlign.center),
                if (action != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child:
                          OutlinedButton(onPressed: action, child: Text(label)))
              ])));
  Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...children
      ]));
  List<DbRow> tasksOn(DateTime date) => data.rows('tasks').where((t) {
        final due = engine.taskDeadline(t);
        return due != null && dayKey(due) == dayKey(date);
      }).toList();
  bool replacementDay(DateTime date) => isReplacementDate(data, date);
  Color timetableColor(DateTime date, DbRow slot) {
    final sessions =
        engine.onDay(date).where((s) => s.slot['id'] == slot['id']).toList();
    if (sessions.isEmpty) return appColor(context, data, 'empty');
    if (date.isBefore(dateOnly(DateTime.now()))) {
      return appColor(context, data, 'past');
    }
    if (sessions.any((s) => s.meeting['exam_period_id'] != null)) {
      return appColor(context, data, 'exam');
    }
    if (sessions.any((s) => s.meeting['once_date'] != null)) {
      return appColor(context, data, 'single');
    }
    if (replacementDay(date)) {
      return appColor(context, data, 'replacement');
    }
    if (engine.isClosed(date)) {
      return appColor(context, data, 'closure');
    }
    return appColor(context, data, 'lecture');
  }

  Widget weekControls(DateTime value, ValueChanged<DateTime> change) => Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
                tooltip: '前の週',
                onPressed: () => change(shiftDay(value, -7)),
                icon: const Icon(Icons.chevron_left)),
            Text(MediaQuery.sizeOf(context).width < 650
                ? '${value.year} ${value.month}/${value.day}–${shiftDay(value, 6).month}/${shiftDay(value, 6).day}'
                : '${dayKey(value)} ～ ${dayKey(shiftDay(value, 6))}'),
            IconButton(
                tooltip: '次の週',
                onPressed: () => change(shiftDay(value, 7)),
                icon: const Icon(Icons.chevron_right)),
            TextButton(
                onPressed: value == beginningOfWeek(DateTime.now())
                    ? null
                    : () => change(beginningOfWeek(DateTime.now())),
                child: const Text('今週'))
          ]);
  Widget slotLabel(DbRow slot, {bool times = true}) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${slot['position']}',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          if (times) ...[
            const SizedBox(height: 3),
            Text(clock(slot['start_minute'] as int),
                style: const TextStyle(fontSize: 9.5, height: 1.1)),
            const Text('│', style: TextStyle(fontSize: 10, height: 1)),
            Text(clock(slot['end_minute'] as int),
                style: const TextStyle(fontSize: 9.5, height: 1.1)),
          ],
        ],
      ));

  Widget dayHeading(DateTime date, {bool picking = false}) => ContextActions(
      desktop: desktop,
      actions: picking
          ? []
          : [
              ContextAction('この日の変更', () => editDay(date)),
              ContextAction('提出する課題', () => showDay(date, tasksOnly: true))
            ],
      child: SizedBox(
          width: double.infinity,
          child: TextButton(
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: picking ? null : () => showDay(date, tasksOnly: true),
              child: LayoutBuilder(
                  builder: (context, size) => Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                                width: double.infinity,
                                child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                        '${weekdays[date.weekday - 1]}\n${date.month}/${date.day}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: date.isBefore(
                                                    dateOnly(DateTime.now()))
                                                ? mutedText(context,
                                                    stronger: data.setting(
                                                            'dark_text', '0') ==
                                                        '1')
                                                : null)))),
                            if (!picking && tasksOn(date).isNotEmpty)
                              Positioned(
                                  right:
                                      max(2.0, (size.maxWidth - 12) / 2 - 12),
                                  top: 13,
                                  child: const Icon(Icons.circle,
                                      size: 6, color: Colors.red)),
                          ])))));

  Widget timetable() => Column(children: [
        weekControls(week, (v) => setState(() => week = v)),
        SizedBox(height: desktop ? 12 : 4),
        Expanded(
            child: visibleWeekdays.isEmpty
                ? empty('表示する曜日がありません', '設定で表示する曜日を選んでください。',
                    label: '設定へ', action: () => setState(() => page = 3))
                : data.setting('timetable_scroll', 'week') == 'smooth'
                    ? smoothTimetable()
                    : weeklyTimetable()),
      ]);

  double labelHeight(String value, TextStyle style) {
    final painter = TextPainter(
        text: TextSpan(
            text: value,
            style: Theme.of(context).textTheme.bodyMedium!.merge(style)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context))
      ..layout(maxWidth: timetableGutter);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  double get timetableRowHeight => max(
      data.slots
          .map((slot) =>
              labelHeight('${slot['position']}',
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)) +
              labelHeight(clock(slot['start_minute'] as int),
                  const TextStyle(fontSize: 9.5, height: 1.1)) +
              labelHeight('│', const TextStyle(fontSize: 10, height: 1)) +
              labelHeight(clock(slot['end_minute'] as int),
                  const TextStyle(fontSize: 9.5, height: 1.1)) +
              11)
          .fold<double>(0, max),
      MediaQuery.textScalerOf(context).scale(
                  double.tryParse(data.setting('course_font_size', '18')) ??
                      18) *
              1.3 *
              3 +
          MediaQuery.textScalerOf(context).scale(
                  double.tryParse(data.setting('room_font_size', '12')) ?? 12) *
              1.3 +
          24 +
          cellMargin * 2);

  Widget weeklyTimetable() => SingleChildScrollView(
      child: SizedBox(
          height: 54 + timetableRowHeight * data.slots.length,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: timetableGutter,
                child: Column(children: [
                  const SizedBox(height: 54),
                  for (final slot in data.slots)
                    SizedBox(
                        height: timetableRowHeight, child: slotLabel(slot)),
                ])),
            Expanded(
                child: WeeklyPager(
                    week: week,
                    swipeEnabled: !desktop,
                    onChanged: (v) => setState(() => week = v),
                    builder: (first) {
                      final dates = [
                        for (var i = 0; i < 7; i++)
                          if (!hiddenWeekdays
                              .contains(shiftDay(first, i).weekday))
                            shiftDay(first, i)
                      ];
                      return Column(children: [
                        SizedBox(
                            height: 54,
                            child: Row(children: [
                              for (final date in dates)
                                Expanded(child: dayHeading(date))
                            ])),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final date in dates)
                                Expanded(
                                    child: dayColumn(date, timetableRowHeight))
                            ]),
                      ]);
                    })),
          ])));

  Widget smoothTimetable() {
    final rowHeight = timetableRowHeight;
    final offsets = [
      for (var i = 0; i < 7; i++)
        if (!hiddenWeekdays.contains(shiftDay(week, i).weekday)) i
    ];
    final height = 64 + rowHeight * data.slots.length;
    return SingleChildScrollView(
        child: SizedBox(
            height: height,
            child: Row(children: [
              SizedBox(
                  width: timetableGutter,
                  child: Column(children: [
                    const SizedBox(height: 64),
                    for (final slot in data.slots)
                      SizedBox(height: rowHeight, child: slotLabel(slot)),
                  ])),
              Expanded(
                  child: DayStrip(
                      key: ValueKey('day-strip-${offsets.join('-')}'),
                      week: week,
                      offsets: offsets,
                      columnWidth: double.tryParse(data.setting(
                              'timetable_column_width',
                              desktop ? '120' : '80')) ??
                          (desktop ? 120 : 80),
                      onChanged: (v) => setState(() => week = v),
                      builder: (date) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 64, child: dayHeading(date)),
                                dayColumn(date, rowHeight)
                              ]))),
            ])));
  }

  Widget weekGrid(DateTime first,
      {ValueChanged<DeadlineChoice>? pick, String? courseId}) {
    final dates = [
      for (var i = 0; i < 7; i++)
        if (pick != null ||
            !hiddenWeekdays.contains(shiftDay(first, i).weekday))
          shiftDay(first, i)
    ];
    final rowHeight = timetableRowHeight;
    return Column(children: [
      Row(children: [
        SizedBox(width: timetableGutter),
        for (final date in dates)
          Expanded(child: dayHeading(date, picking: pick != null))
      ]),
      Expanded(
          child: ListView(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: timetableGutter,
              child: Column(children: [
                for (final slot in data.slots)
                  SizedBox(
                      height: rowHeight,
                      child: slotLabel(slot, times: pick == null))
              ])),
          for (final date in dates)
            Expanded(
                child:
                    dayColumn(date, rowHeight, pick: pick, courseId: courseId)),
        ])
      ])),
    ]);
  }

  String holidayName(DateTime date) {
    final change = engine.dayChange(date);
    if ((change?['holiday_name'] as String? ?? '').isNotEmpty) {
      return change!['holiday_name'] as String;
    }
    final event = data
        .rows('events')
        .where((e) => e['kind'] == 'holiday' && engine.contains(e, date))
        .firstOrNull;
    return (event?['name'] as String? ?? '').isEmpty
        ? '休業日'
        : event!['name'] as String;
  }

  Widget dayColumn(DateTime date, double rowHeight,
      {ValueChanged<DeadlineChoice>? pick, String? courseId}) {
    final sessions =
        engine.onDay(date, includeCancelled: pick == null).toList();
    final noClasses = engine.onDay(date, includeCancelled: false).isEmpty;
    final past = date.isBefore(dateOnly(DateTime.now()));
    if (pick == null && engine.isClosed(date) && noClasses) {
      return ContextActions(
          desktop: desktop,
          actions: [
            ContextAction('この日の変更', () => editDay(date)),
            ContextAction('この日の予定', () => showDay(date))
          ],
          child: InkWell(
              onTap: () => showDay(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                  key: ValueKey('holiday-${dayKey(date)}'),
                  height: rowHeight * data.slots.length - cellMargin * 2,
                  margin: EdgeInsets.all(cellMargin),
                  decoration: BoxDecoration(
                      color: past
                          ? appColor(context, data, 'past')
                          : appColor(context, data, 'closure'),
                      borderRadius: BorderRadius.circular(desktop ? 6 : 2)),
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  holidayName(date).characters.join('\n'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: past
                                          ? mutedText(context,
                                              stronger: data.setting(
                                                      'dark_text', '0') ==
                                                  '1')
                                          : isDark(context)
                                              ? appColor(
                                                  context, data, 'holiday_text')
                                              : appColor(context, data,
                                                  'holiday_text'),
                                      fontFeatures: [
                                        FontFeature('vert'),
                                        FontFeature('vrt2')
                                      ]))))))));
    }
    return Column(children: [
      for (final slot in data.slots)
        Container(
            key: ValueKey('timetable-${slot['id']}-${dayKey(date)}'),
            width: double.infinity,
            height: rowHeight - cellMargin * 2,
            margin: EdgeInsets.all(cellMargin),
            decoration: BoxDecoration(
                color: pick != null &&
                        !sessions.any((s) => s.slot['id'] == slot['id'])
                    ? appColor(context, data, 'empty')
                    : timetableColor(date, slot),
                borderRadius: BorderRadius.circular(desktop ? 6 : 2)),
            child: ContextActions(
                desktop: desktop,
                actions: pick == null
                    ? [
                        ContextAction('この日の変更', () => editDay(date)),
                        ContextAction(
                            '講義を追加',
                            () => editMeeting(
                                day: date, slotId: slot['id'] as String))
                      ]
                    : [],
                child: Column(children: [
                  if (pick != null &&
                      !sessions.any((s) => s.slot['id'] == slot['id']))
                    Expanded(
                        child: InkWell(
                            key: ValueKey(
                                'deadline-empty-${dayKey(date)}-${slot['id']}'),
                            onTap: () => pick(DeadlineChoice(date, slot)),
                            child: const SizedBox.expand())),
                  for (final session
                      in sessions.where((s) => s.slot['id'] == slot['id']))
                    Expanded(
                        child: pick == null
                            ? sessionCard(session,
                                past: date.isBefore(dateOnly(DateTime.now())))
                            : InkWell(
                                onTap: () =>
                                    pick(DeadlineChoice.fromSession(session)),
                                child: Center(
                                    child: Container(
                                        key: ValueKey(
                                            'deadline-lecture-${session.key}'),
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: courseId != null && matchesTaskCourse(data, courseId, session.course['id'] as String)
                                                ? Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    width: 2)
                                                : null),
                                        child: Text(session.course['name'] as String,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center)))))
                ])))
    ]);
  }

  Widget sessionCard(Session session, {bool past = false}) => ContextActions(
      desktop: desktop,
      actions: [
        ContextAction('講義の詳細・メモ', () => showSession(session)),
        ContextAction('この日の変更', () => editSession(session)),
        ContextAction('曜日と時間を変更', () => editMeeting(row: session.meeting)),
        ContextAction('講義を編集', () => editCourse(session.course)),
        ContextAction('課題を追加', () => editTask(session: session)),
        ContextAction(
            '授業を削除', () => confirmRemove('meetings', session.meeting, '授業'))
      ],
      child: InkWell(
          onTap: () => showSession(session),
          child: Stack(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: Center(
                              child: Text(session.course['name'] as String,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: double.tryParse(data.setting(
                                              'course_font_size', '18')) ??
                                          18,
                                      height: 1.3,
                                      color: past
                                          ? mutedText(context,
                                              stronger: data.setting(
                                                      'dark_text', '0') ==
                                                  '1')
                                          : null,
                                      decoration: session.cancelled
                                          ? TextDecoration.lineThrough
                                          : null)))),
                      Text('${session.room}${session.cancelled ? '・休講' : ''}',
                          textAlign: TextAlign.center,
                          softWrap: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: double.tryParse(
                                      data.setting('room_font_size', '12')) ??
                                  12,
                              height: 1.3,
                              color: past
                                  ? mutedText(context,
                                      stronger:
                                          data.setting('dark_text', '0') == '1')
                                  : null)),
                    ])),
            if (data.setting('accessibility_marks', '0') == '1')
              Positioned(
                  top: 2,
                  right: 2,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (session.replacement || replacementDay(session.date))
                      StatusMark(
                          shape: 6,
                          filled: false,
                          color: Theme.of(context).colorScheme.onSurface,
                          label: '代替日'),
                    if (session.meeting['once_date'] != null &&
                        session.meeting['exam_period_id'] == null)
                      StatusMark(
                          color: Theme.of(context).colorScheme.onSurface,
                          label: '単発講義'),
                  ])),
          ])));

  List<String> taskDetails(DbRow task, {bool timeOnly = false}) {
    final due = engine.taskDeadline(task),
        course = data.find('courses', task['course_id'] as String?);
    final contextId = task['context_meeting_id'] as String? ??
        task['due_meeting_id'] as String?;
    final related = due == null
        ? null
        : engine
            .onDay(due)
            .where((s) => contextId != null
                ? s.meeting['id'] == contextId
                : s.start == due &&
                    course != null &&
                    s.course['id'] == course['id'])
            .firstOrNull;
    return [
      if ((course?['name'] as String? ?? '').isNotEmpty)
        '講義名: ${course!['name']}',
      if ((task['destination'] as String? ?? '').isNotEmpty)
        '提出先: ${task['destination']}',
      if (related != null)
        '該当の講義: ${deadlineHint(DeadlineChoice.fromSession(related))}',
      if (due != null)
        '提出時間: ${timeOnly ? clock(due.hour * 60 + due.minute) : dateTimeLabel(due)}',
    ];
  }

  Future<void> showTask(DbRow task) => showAppDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: Text(task['title'] as String),
              content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        for (final line in taskDetails(task))
                          Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(line)),
                        if ((task['notes'] as String? ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          markdown(task['notes'] as String)
                        ],
                      ]))),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      editTask(row: task);
                    },
                    child: const Text('編集')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('閉じる')),
              ]));

  Future<void> showDay(DateTime day, {bool tasksOnly = false}) =>
      showAppDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(dayKey(day)),
                  content: SizedBox(
                      width: 500,
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            if (!tasksOnly) ...[
                              if (engine.dayChange(day)?['is_national'] == 1)
                                Text(holidayName(day)),
                              if (replacementDay(day)) const Text('代替日'),
                              for (final period in data
                                  .rows('events')
                                  .where((e) => engine.contains(e, day)))
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(periodLabel(data, period))),
                              for (final session in engine.onDay(day))
                                sessionTile(session),
                            ],
                            if (tasksOn(day).isEmpty && tasksOnly)
                              const Text('この日が提出期限の課題はありません'),
                            for (final task in tasksOn(day))
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(task['title'] as String),
                                  subtitle: Text(
                                      taskDetails(task, timeOnly: true)
                                          .join('\n')),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    showTask(task);
                                  }),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('閉じる'))
                  ]));

  Widget sessionTile(Session s) => ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => showSession(s),
      leading: Text('${s.slot['position']}限',
          style: const TextStyle(fontWeight: FontWeight.w500)),
      title: Text(s.course['name'] as String,
          style: TextStyle(
              decoration: s.cancelled ? TextDecoration.lineThrough : null)),
      subtitle: Text(
          '${clock(s.slot['start_minute'] as int)}–${clock(s.slot['end_minute'] as int)}  ${s.room}  ${s.cancelled ? '休講' : s.replacement ? '振替' : ''}'),
      trailing: const Icon(Icons.chevron_right));
  Widget markdown(String value) => MarkdownBody(
      data: value,
      selectable: true,
      sizedImageBuilder: (config) =>
          Text('[画像: ${config.alt ?? config.title ?? config.uri.toString()}]'),
      onTapLink: (_, href, title) {
        if (href != null) message(href);
      });
  Future<void> showCourse(DbRow c) async {
    await showAppDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
                title: Text(c['name'] as String),
                content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text('教室  ${c['room']}\n教員  ${c['teacher']}'),
                          const SizedBox(height: 18),
                          markdown((c['notes'] as String).isEmpty
                              ? 'メモはまだありません。'
                              : c['notes'] as String)
                        ]))),
                actions: [
                  if (timetableEditing)
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          editCourse(c);
                        },
                        child: const Text('編集')),
                  if (timetableEditing)
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          editMeeting(courseId: c['id'] as String);
                        },
                        child: const Text('コマを追加')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('閉じる'))
                ]));
  }

  Future<void> editCourse([DbRow? row]) async {
    final name = text(row?['name']),
        room = text(row?['room']),
        teacher = text(row?['teacher']),
        notes = text(row?['notes']),
        lead = text(row?['lead_minutes']);
    final start = text(row?['start_date']), end = text(row?['end_date']);
    final terms = stringList(row?['term_ids']).toSet();
    var check = row?['check_tasks'] != 0;
    await editForm(
        context,
        row == null ? '講義を登録' : '講義を編集',
        (ctx, set) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HistoryField(
                  controller: name,
                  label: '講義名',
                  history: history('name'),
                  required: true),
              HistoryField(
                  controller: room, label: '教室名', history: history('room')),
              HistoryField(
                  controller: teacher,
                  label: '教員名',
                  history: history('teacher')),
              field(lead, '開始何分前に通知（空欄: 全体設定、-1: オフ）', number: true),
              if (start.text.isNotEmpty || end.text.isNotEmpty)
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('実施期間の追加条件'),
                    children: [
                      dateField(ctx, start, '開始日（任意）', optional: true),
                      dateField(ctx, end, '終了日（任意）', optional: true)
                    ]),
              preferenceSwitch(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('終了後に課題の確認を通知'),
                  value: check,
                  onChanged: canNotify ? (v) => set(() => check = v) : null),
              field(notes, 'メモ（Markdown）', lines: 5)
            ]), () async {
      if (start.text.isNotEmpty &&
          end.text.isNotEmpty &&
          start.text.compareTo(end.text) > 0) {
        throw const FormatException('終了日は開始日以降にしてください');
      }
      await commit(() {
        db.put('courses', {
          'id': row?['id'] ?? newId(),
          'name': name.text,
          'room': room.text,
          'teacher': teacher.text,
          'notes': notes.text,
          'term_ids': jsonEncode(terms.toList()),
          'start_date': start.text.isEmpty ? null : start.text,
          'end_date': end.text.isEmpty ? null : end.text,
          'lead_minutes': lead.text.isEmpty ? null : int.parse(lead.text),
          'check_tasks': check ? 1 : 0
        });
        remember('name', name.text);
        remember('room', room.text);
        remember('teacher', teacher.text);
      });
      return true;
    },
        delete: row == null ? null : () => remove('courses', row),
        bottomSheet: true);
    for (final c in [name, room, teacher, notes, lead, start, end]) {
      c.dispose();
    }
  }

  List<String> history(String key) {
    final stored = stringList(data.setting('history_$key', '[]'));
    final fallback = data
        .rows('courses')
        .reversed
        .map((c) => c[key] as String)
        .where((v) => v.isNotEmpty);
    return {...stored, ...fallback}.toList();
  }

  void remember(String key, String value) {
    if (value.isEmpty) return;
    final values = history(key)..remove(value);
    values.insert(0, value);
    db.put('settings', {'id': 'history_$key', 'value': jsonEncode(values)});
  }

  Future<void> editMeeting(
      {DbRow? row,
      String? courseId,
      String? slotId,
      DateTime? day,
      int? weekdayValue,
      bool? single}) async {
    if (row?['exam_period_id'] != null) {
      await editExam(row!['exam_period_id'] as String,
          DateTime.parse(row['once_date'] as String), row['slot_id'] as String,
          row: row);
      return;
    }
    if (row?['once_date'] != null) {
      await editSingleDate(row!['course_id'] as String,
          oldDate: row['once_date'] as String);
      return;
    }
    if (data.slots.isEmpty) {
      message('設定で時限を登録してください');
      return;
    }
    final oldCourse =
        data.find('courses', row?['course_id'] as String? ?? courseId);
    final name = text(oldCourse?['name']),
        room = text(row?['room'] ?? oldCourse?['room']),
        teacher = text(oldCourse?['teacher']);
    final once = single ?? (row?['once_date'] != null);
    if (!once && editingTerm.isEmpty) {
      message('年間予定で講義期間を登録してください');
      setState(() => page = 2);
      return;
    }
    var term = row == null ? editingTerm : meetingTerm(row);
    final entries = <Map<String, dynamic>>[
      {
        'date': text(row?['once_date'] ?? dayKey(day ?? DateTime.now())),
        'weekday': row?['weekday'] as int? ??
            weekdayValue ??
            day?.weekday ??
            weekStart,
        'slots': <String>{
          row?['slot_id'] as String? ??
              slotId ??
              data.slots.first['id'] as String
        }
      }
    ];
    final controllers = <TextEditingController>[
      entries.first['date'] as TextEditingController
    ];
    if (once) entries.clear();
    await editForm(
        context,
        row == null
            ? once
                ? '単発講義を登録'
                : '講義を登録'
            : '授業を編集',
        (ctx, set) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!once)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                        '${periodLabel(data, data.find('events', term)!)}${weekdays[(entries.first['weekday'] as int) - 1]}曜日${data.find('slots', (entries.first['slots'] as Set<String>).first)?['position']}限')),
              HistoryField(
                  controller: name,
                  label: '講義名',
                  history: history('name'),
                  required: true),
              HistoryField(
                  controller: room, label: '教室名', history: history('room')),
              HistoryField(
                  controller: teacher,
                  label: '教員名',
                  history: history('teacher')),
              if (once) ...[
                for (var i = 0; i < entries.length; i++)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          '${(entries[i]['date'] as TextEditingController).text} (${(entries[i]['slots'] as Set<String>).map((id) => data.find('slots', id)!['position']).join(', ')})'),
                      trailing: IconButton(
                          tooltip: 'この実施日を削除',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => set(() => entries.removeAt(i))),
                      onTap: () async {
                        final picked = await pickSingleEntry(ctx,
                            date: (entries[i]['date'] as TextEditingController)
                                .text,
                            selected: entries[i]['slots'] as Set<String>);
                        if (picked != null) {
                          set(() {
                            (entries[i]['date'] as TextEditingController).text =
                                picked['date'] as String;
                            entries[i]['slots'] = picked['slots'];
                          });
                        }
                      }),
                TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('実施日を追加'),
                    onPressed: () async {
                      final picked = await pickSingleEntry(ctx);
                      if (picked != null) {
                        set(() {
                          final controller = text(picked['date']);
                          controllers.add(controller);
                          entries.add({
                            'date': controller,
                            'slots': picked['slots'],
                            'weekday': weekStart
                          });
                        });
                      }
                    }),
              ],
            ]), () async {
      if (entries.isEmpty) throw const FormatException('実施日を追加してください');
      final candidates = <DbRow>[];
      for (final entry in entries) {
        final slots = entry['slots'] as Set<String>;
        if (slots.isEmpty) throw const FormatException('実施日ごとに時限を選んでください');
        for (final slot in slots) {
          candidates.add({
            'id': candidates.isEmpty && row != null ? row['id'] : newId(),
            'slot_id': slot,
            'weekday': once ? null : entry['weekday'],
            'once_date':
                once ? (entry['date'] as TextEditingController).text : null,
            'term_id': null,
            'period_id': once || term.isEmpty ? null : term,
            'legacy_origin_id': null,
          });
        }
      }
      final positions = <String>{};
      for (final candidate in candidates) {
        final key =
            '${candidate['slot_id']}:${candidate['weekday']}:${candidate['once_date']}:${candidate['period_id']}';
        if (!positions.add(key) ||
            data.rows('meetings').any((m) =>
                m['id'] != row?['id'] &&
                m['slot_id'] == candidate['slot_id'] &&
                m['weekday'] == candidate['weekday'] &&
                m['once_date'] == candidate['once_date'] &&
                (once ? m['period_id'] : meetingTerm(m)) ==
                    candidate['period_id'])) {
          throw const FormatException('同じ曜日・実施日・時限に授業があります。別の時限を選んでください。');
        }
      }
      await commit(() {
        final matching = data
            .rows('courses')
            .where((c) =>
                c['name'] == name.text &&
                c['room'] == room.text &&
                c['teacher'] == teacher.text)
            .firstOrNull;
        final id = matching?['id'] as String? ?? newId();
        if (matching == null) {
          db.put('courses', {
            'id': id,
            'name': name.text,
            'room': room.text,
            'teacher': teacher.text,
            'notes': oldCourse?['notes'] ?? '',
            'term_ids': oldCourse?['term_ids'] ?? '[]',
            'start_date': oldCourse?['start_date'],
            'end_date': oldCourse?['end_date'],
            'lead_minutes': oldCourse?['lead_minutes'],
            'check_tasks': oldCourse?['check_tasks'] ?? 1
          });
        }
        for (final candidate in candidates) {
          db.put('meetings', {
            ...candidate,
            'course_id': id,
            'room': null,
            'lead_minutes': row?['lead_minutes']
          });
        }
        remember('name', name.text);
        remember('room', room.text);
        remember('teacher', teacher.text);
      });
      return true;
    },
        delete: row == null ? null : () => remove('meetings', row),
        bottomSheet: true);
    for (final controller in [name, room, teacher, ...controllers]) {
      controller.dispose();
    }
  }

  Future<void> showSession(Session s) async {
    await showAppDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
                title: Text(s.course['name'] as String),
                content: SizedBox(
                    width: 480,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(
                              '${dayKey(s.date)}  ${s.slot['position']}限\n${clock(s.slot['start_minute'] as int)}–${clock(s.slot['end_minute'] as int)}\n教室 ${s.room}\n教員 ${s.course['teacher']}'),
                          if (s.cancelled)
                            const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('この日は休講です')),
                          if (s.replacement) Text('${dayKey(s.sourceDate)}の振替'),
                          const SizedBox(height: 18),
                          markdown(s.course['notes'] as String)
                        ]))),
                actions: [
                  if (timetableEditing)
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          editSession(s);
                        },
                        child: const Text('この日の変更')),
                  if (timetableEditing)
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          editMeeting(row: s.meeting);
                        },
                        child: const Text('定期設定')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        editTask(session: s);
                      },
                      child: const Text('課題を追加')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('閉じる'))
                ]));
  }

  Future<void> editSession(Session s) async {
    final old = engine.sessionChange(s.meeting['id'] as String, s.sourceDate);
    var cancelled = old?['cancelled'] == 1;
    final replacement = text(old?['replacement_date']),
        room = text(old?['room']),
        lead = text(old?['lead_minutes']);
    var slot = old?['replacement_slot_id'] as String? ?? s.slot['id'] as String;
    await editForm(
        context,
        '${dayKey(s.sourceDate)}の授業',
        (ctx, set) => Column(children: [
              preferenceSwitch(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('休講'),
                  value: cancelled,
                  onChanged: (v) => set(() => cancelled = v)),
              dateField(ctx, replacement, '振替日（任意）',
                  optional: true, onChanged: () => set(() {})),
              if (replacement.text.isNotEmpty)
                choice(
                    '振替先のコマ',
                    slot,
                    {
                      for (final p in data.slots)
                        p['id'] as String: '${p['position']}限'
                    },
                    (v) => set(() => slot = v)),
              field(room, 'この日の教室（空欄: 元の設定）'),
              field(lead, '開始何分前に通知（空欄: 元の設定、-1: オフ）', number: true)
            ]), () async {
      if (replacement.text == dayKey(s.sourceDate)) {
        throw const FormatException('振替日は元の日と異なる日を選んでください');
      }
      await put('session_changes', {
        'id': old?['id'] ?? newId(),
        'meeting_id': s.meeting['id'],
        'date': dayKey(s.sourceDate),
        'cancelled': cancelled || replacement.text.isNotEmpty ? 1 : 0,
        'replacement_date': replacement.text.isEmpty ? null : replacement.text,
        'replacement_slot_id': replacement.text.isEmpty ? null : slot,
        'room': room.text.isEmpty ? null : room.text,
        'lead_minutes': lead.text.isEmpty ? null : int.parse(lead.text)
      });
      return true;
    }, delete: old == null ? null : () => remove('session_changes', old));
    replacement.dispose();
    room.dispose();
    lead.dispose();
  }

  Future<void> removeTasks(List<DbRow> rows) async {
    final copies = [for (final row in rows) Map<String, dynamic>.from(row)];
    setState(() {
      dismissedTasks.addAll(rows.map((t) => t['id'] as String));
      selectedTasks.removeAll(rows.map((t) => t['id'] as String));
    });
    try {
      await commit(() {
        for (final t in rows) {
          db.remove('tasks', t['id'] as String);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          duration: const Duration(seconds: 3),
          content: Text('${rows.length}件の課題を削除しました'),
          action: SnackBarAction(
              label: '元に戻す',
              onPressed: () async {
                try {
                  await commit(() {
                    for (final t in copies) {
                      if (data.find('courses', t['course_id'] as String?) ==
                          null) {
                        t['course_id'] = null;
                      }
                      for (final column in [
                        'due_meeting_id',
                        'context_meeting_id'
                      ]) {
                        if (data.find('meetings', t[column] as String?) ==
                            null) {
                          t[column] = null;
                        }
                      }
                      db.put('tasks', t);
                    }
                  });
                  if (mounted) {
                    setState(() => dismissedTasks
                        .removeAll(copies.map((t) => t['id'] as String)));
                  }
                } catch (e) {
                  message(e.toString());
                }
              })));
    } catch (e) {
      if (mounted) {
        setState(
            () => dismissedTasks.removeAll(rows.map((t) => t['id'] as String)));
      }
      message(e.toString());
    }
  }

  Widget tasks() {
    final rows = data
        .rows('tasks')
        .where((t) =>
            (showDone || t['done'] == 0) && !dismissedTasks.contains(t['id']))
        .toList()
      ..sort((a, b) => (engine.taskDeadline(a) ?? DateTime(9999))
          .compareTo(engine.taskDeadline(b) ?? DateTime(9999)));
    final chosen = data
        .rows('tasks')
        .where((t) => selectedTasks.contains(t['id']))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (selectedTasks.isNotEmpty)
        Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${selectedTasks.length}件選択中'),
              IconButton(
                  tooltip: '選択を解除',
                  onPressed: () => setState(selectedTasks.clear),
                  icon: const Icon(Icons.close)),
              TextButton(
                  onPressed: () async {
                    await commit(() {
                      for (final t in chosen) {
                        db.put('tasks', {'id': t['id'], 'done': 1});
                      }
                    });
                    if (mounted) setState(selectedTasks.clear);
                  },
                  child: const Text('完了')),
              TextButton(
                  onPressed: () => removeTasks(chosen),
                  child: const Text('削除')),
              TextButton(
                  onPressed: chosen.length == 1
                      ? () => editTask(row: chosen.single)
                      : null,
                  child: const Text('編集')),
            ])
      else
        Wrap(alignment: WrapAlignment.spaceBetween, children: [
          FilterChip(
              chipAnimationStyle: chipMotion(context),
              label: const Text('完了した課題も表示'),
              selected: showDone,
              onSelected: (v) => setState(() => showDone = v)),
          TextButton.icon(
              onPressed: editGlobalRules,
              icon: const Icon(Icons.notifications_none, size: 18),
              label: const Text('通知の初期設定')),
        ]),
      const SizedBox(height: 12),
      Expanded(
          child: rows.isEmpty
              ? empty('課題はありません', '右下の＋から課題を登録できます。')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: rows.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = rows[i], due = engine.taskDeadline(t);
                    final overdue = t['done'] == 0 &&
                        due != null &&
                        due.isBefore(DateTime.now());
                    final radius = BorderRadius.circular(8),
                        selected = selectedTasks.contains(t['id']);
                    final color = selected
                        ? appColor(context, data, 'task_selected')
                        : appColor(context, data, 'task');
                    void toggleSelection() => setState(() {
                          if (!selectedTasks.add(t['id'] as String)) {
                            selectedTasks.remove(t['id']);
                          }
                        });
                    final card = ContextActions(
                        desktop: desktop,
                        actions: [
                          ContextAction('課題を表示', () => showTask(t)),
                          ContextAction('課題を編集', () => editTask(row: t)),
                          ContextAction(
                              t['done'] == 1 ? '未完了に戻す' : '完了にする',
                              () => put('tasks', {
                                    'id': t['id'],
                                    'done': t['done'] == 1 ? 0 : 1
                                  })),
                          ContextAction('課題を削除', () => removeTasks([t])),
                        ],
                        child: Material(
                            color: color,
                            borderRadius: radius,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                                borderRadius: radius,
                                splashColor: const Color(0x22398b72),
                                highlightColor: desktop
                                    ? Colors.transparent
                                    : const Color(0x18398b72),
                                onLongPress: null,
                                onTap: selectedTasks.isNotEmpty
                                    ? toggleSelection
                                    : () => showTask(t),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 16),
                                    child: Row(children: [
                                      if (selectedTasks.isNotEmpty)
                                        Checkbox(
                                            value: selected,
                                            onChanged: (_) =>
                                                toggleSelection()),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(t['title'] as String,
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    decoration: t['done'] == 1
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null)),
                                            for (final line in taskDetails(t))
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(line,
                                                      style: TextStyle(
                                                          color: overdue
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .error
                                                              : null))),
                                            if ((t['notes'] as String? ?? '')
                                                .isNotEmpty)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                      t['notes'] as String,
                                                      maxLines: 3,
                                                      overflow: TextOverflow
                                                          .ellipsis)),
                                          ])),
                                      const SizedBox(width: 8),
                                      Transform.scale(
                                          scale: 1.25,
                                          child: Checkbox(
                                              shape: const CircleBorder(),
                                              value: t['done'] == 1,
                                              onChanged: (v) => put('tasks', {
                                                    'id': t['id'],
                                                    'done': v == true ? 1 : 0
                                                  }))),
                                    ])))));
                    return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: desktop
                                ? card
                                : Dismissible(
                                    key: ValueKey('task-${t['id']}'),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (_) =>
                                        Future.value(!saving),
                                    onDismissed: (_) => removeTasks([t]),
                                    background: Container(
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .errorContainer,
                                            borderRadius: radius),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 24),
                                        child:
                                            const Icon(Icons.delete_outline)),
                                    child: TimedLongPress(
                                        milliseconds: int.tryParse(data.setting(
                                                'calendar_long_press_ms',
                                                '500')) ??
                                            500,
                                        onLongPress: toggleSelection,
                                        child: card))));
                  })),
    ]);
  }

  Session? nextCourseSession(String? courseId) {
    for (var n = 0; n <= 366; n++) {
      final match = engine
          .onDay(shiftDay(DateTime.now(), n), includeCancelled: false)
          .where((s) =>
              matchesTaskCourse(data, courseId, s.course['id'] as String))
          .firstOrNull;
      if (match != null) return match;
    }
    return null;
  }

  String deadlineHint(DeadlineChoice chosen) {
    final weeks = (beginningOfWeek(chosen.date)
                .difference(beginningOfWeek(DateTime.now()))
                .inDays /
            7)
        .round();
    final label = weeks == 0
        ? '今週'
        : weeks > 0
            ? '$weeks週間後'
            : '${-weeks}週間前';
    final subject =
        chosen.session == null ? '' : '（${chosen.session!.course['name']}）';
    return '$labelの${weekdays[chosen.date.weekday - 1]}曜日${chosen.slot['position']}限目$subjectに提出';
  }

  Future<void> editTask({DbRow? row, Session? session, String? courseId}) async {
    final initial = (row == null ? session?.start : engine.taskDeadline(row)) ??
        DateTime.now().add(const Duration(days: 7));
    final title = text(row?['title']),
        due = text(dateTimeLabel(initial)),
        destination = text(row?['destination']),
        notes = text(row?['notes']);
    var course = row?['course_id'] as String? ??
        session?.course['id'] as String? ?? courseId ?? '';
    DeadlineChoice? chosen =
        session == null ? null : DeadlineChoice.fromSession(session);
    final options = engine.onDay(initial, includeCancelled: false);
    final existing = options
        .where((s) =>
            s.start == initial &&
            (row?['context_meeting_id'] != null
                ? s.meeting['id'] == row!['context_meeting_id']
                : matchesTaskCourse(data, course, s.course['id'] as String)))
        .firstOrNull;
    if (chosen == null && existing != null) {
      chosen = DeadlineChoice.fromSession(existing);
    }
    final rules = ruleList(row?['rules'] ??
        data.setting('task_rules',
            '[{"kind":"hours","amount":72},{"kind":"day_clock","amount":1,"minute":420}]'));
    await editForm(
        context,
        row == null ? '課題を登録' : '課題を編集',
        (ctx, set) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              field(title, '課題名', required: true),
              choice(
                  '講義',
                  course,
                  taskCourseChoices(data, course),
                  (v) => set(() {
                        course = v;
                        chosen = null;
                      })),
              dateField(ctx, due, '提出期限',
                  time: true, onChanged: () => set(() => chosen = null)),
              if (chosen != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(deadlineHint(chosen!))),
              OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await chooseDeadline(
                        ctx, course.isEmpty ? null : course);
                    if (selected != null) {
                      set(() {
                        chosen = selected;
                        if (course.isNotEmpty &&
                            selected.session != null &&
                            matchesTaskCourse(data, course,
                                selected.session!.course['id'] as String)) {
                          course = selected.session!.course['id'] as String;
                        }
                        due.text = dateTimeLabel(selected.start);
                      });
                    }
                  },
                  icon: const Icon(Icons.view_week_outlined),
                  label: const Text('時間割から提出日時を選ぶ')),
              const SizedBox(height: 12),
              HistoryField(
                  controller: destination,
                  label: '提出先',
                  history: data
                      .rows('destinations')
                      .reversed
                      .map((d) => d['name'] as String)
                      .toList()),
              field(notes, 'メモ', lines: 3),
              const Text('通知'),
              for (var i = 0; i < rules.length; i++)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ruleLabel(rules[i])),
                    trailing: IconButton(
                        onPressed: () => set(() => rules.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18))),
              TextButton.icon(
                  onPressed: () async {
                    final rule = await addRule(ctx);
                    if (rule != null) set(() => rules.add(rule));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('通知を追加'))
            ]), () async {
      final resolved = parseDeadline(due.text);
      if (resolved == null) throw const FormatException('提出期限を分まで入力してください');
      for (final rule in rules) {
        final at = engine.reminderTime(rule, resolved);
        if (at != null && at.isAfter(resolved)) {
          throw const FormatException('通知日時は期限以前にしてください');
        }
      }
      await commit(() {
        db.put('tasks', {
          'id': row?['id'] ?? newId(),
          'title': title.text,
          'course_id': course.isEmpty ? null : course,
          'due_at': resolved.toIso8601String(),
          'due_meeting_id': null,
          'due_source_date': null,
          'context_meeting_id': chosen?.session?.meeting['id'],
          'context_source_date': chosen?.session == null
              ? null
              : dayKey(chosen!.session!.sourceDate),
          'destination': destination.text,
          'notes': notes.text,
          'rules': jsonEncode(rules),
          'done': row?['done'] ?? 0
        });
        if (destination.text.isNotEmpty) {
          final old = data
              .rows('destinations')
              .where((d) => d['name'] == destination.text)
              .firstOrNull;
          if (old != null) db.remove('destinations', old['id'] as String);
          db.put('destinations', {'id': newId(), 'name': destination.text});
        }
      });
      return true;
    },
        delete: row == null ? null : () => remove('tasks', row),
        fullScreen: true);
    for (final c in [title, due, destination, notes]) {
      c.dispose();
    }
  }

  Future<DeadlineChoice?> chooseDeadline(
      BuildContext context, String? courseId) {
    final next = nextCourseSession(courseId);
    var selectedWeek = beginningOfWeek(next?.date ?? DateTime.now());
    return showAppDialog<DeadlineChoice>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    insetPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    titlePadding: const EdgeInsets.all(12),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    actionsPadding: const EdgeInsets.all(12),
                    title: const Text('提出日時を選択'),
                    content: SizedBox(
                        width: 1000,
                        height: 520,
                        child: Column(children: [
                          weekControls(
                              selectedWeek, (v) => set(() => selectedWeek = v)),
                          Text(
                              '${(selectedWeek.difference(beginningOfWeek(DateTime.now())).inDays / 7).round()}週間後'),
                          const SizedBox(height: 8),
                          Expanded(
                              child: weekGrid(selectedWeek,
                                  courseId: courseId,
                                  pick: (s) => Navigator.pop(ctx, s)))
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('キャンセル'))
                    ])));
  }

  Future<void> editGlobalRules() async {
    final rules = ruleList(data.setting('task_rules',
        '[{"kind":"hours","amount":72},{"kind":"day_clock","amount":1,"minute":420}]'));
    await editForm(
        context,
        '課題の通知・全体設定',
        (ctx, set) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('新しい課題へ初期値として入れます。空にすると初期値の通知はありません。'),
              const SizedBox(height: 12),
              for (var i = 0; i < rules.length; i++)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ruleLabel(rules[i])),
                    trailing: IconButton(
                        onPressed: () => set(() => rules.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18))),
              TextButton.icon(
                  onPressed: () async {
                    final r = await addRule(ctx, allowAbsolute: false);
                    if (r != null) set(() => rules.add(r));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('通知を追加'))
            ]), () async {
      await setting('task_rules', jsonEncode(rules));
      return true;
    });
  }

  DateTime get fiscalStart =>
      DateTime(year, int.parse(data.setting('year_start', '4')));
  DateTime get fiscalEnd =>
      DateTime(year + 1, int.parse(data.setting('year_start', '4')), 0);
  void returnToToday() {
    if (returningToday) return;
    returningToday = true;
    final start = int.parse(data.setting('year_start', '4'));
    setState(() {
      year = DateTime.now().year - (DateTime.now().month < start ? 1 : 0);
      calendarPositioned = false;
      animateCalendar = true;
    });
  }

  void positionCalendar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !calendarScroll.hasClients) return;
      final position = calendarScroll.position;
      if (calendarPositioned && identical(calendarPosition, position)) {
        return;
      }
      calendarPosition = position;
      if (calendarPositioned) {
        calendarScroll.jumpTo(
            calendarOffset.clamp(0.0, calendarScroll.position.maxScrollExtent));
      } else {
        final box = calendarTodayKey.currentContext?.findRenderObject();
        if (box is RenderBox) {
          final viewport = box.localToGlobal(Offset.zero,
              ancestor: calendarScroll.position.context.storageContext
                  .findRenderObject());
          final target = calendarScroll.offset +
              viewport.dy -
              calendarScroll.position.viewportDimension / 2 +
              box.size.height / 2;
          final destination =
              target.clamp(0.0, calendarScroll.position.maxScrollExtent);
          if (animateCalendar && data.setting('reduce_motion', '0') != '1') {
            animateCalendar = false;
            calendarScroll
                .animateTo(destination,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOutCubic)
                .whenComplete(() => returningToday = false);
          } else {
            animateCalendar = false;
            returningToday = false;
            calendarScroll.jumpTo(destination);
          }
        }
        if (!animateCalendar && box is! RenderBox) returningToday = false;
        calendarPositioned = true;
        calendarOffset = calendarScroll.offset;
      }
    });
  }

  Widget calendar() {
    positionCalendar();
    final calendar = ListView(controller: calendarScroll, children: [
      if (selectingPeriod)
        Row(children: [
          Expanded(child: Text('開始日、終了日の順にカレンダーを選択してください。')),
          IconButton(
              tooltip: '期間選択をやめる',
              onPressed: () => setState(() => selectingPeriod = false),
              icon: const Icon(Icons.close))
        ]),
      Visibility(
          visible: calendarEditing,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  desktop
                      ? 'クリックで日ごとの変更・ダブルクリックで期間編集・ドラッグで期間追加。右クリックで操作一覧。'
                      : 'タップで日ごとの変更・長押しで期間編集・長押ししてなぞると期間追加。',
                  style: const TextStyle(fontSize: 12)))),
      AnnualCalendar(
          todayKey: calendarTodayKey,
          start: fiscalStart,
          data: data,
          scrollController: calendarScroll,
          weekStart: weekStart,
          editing: calendarEditing,
          selecting: selectingPeriod,
          longPressMilliseconds:
              int.tryParse(data.setting('calendar_long_press_ms', '500')) ??
                  500,
          desktop: desktop,
          onSelected: (range) {
            setState(() => selectingPeriod = false);
            editEvent(null, range);
          },
          onDaySettings: calendarEditing ? editDay : showDay,
          onPeriodEdit: editPeriodAt,
          dateActions: calendarDateActions),
    ]);
    final content = !desktop && calendarEditing
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(
                gestureSettings: const DeviceGestureSettings(touchSlop: 27)),
            child: calendar)
        : calendar;
    return Column(children: [
      Row(children: [
        IconButton(
            tooltip: '前の年度',
            onPressed: () => setState(() => year--),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Text('$year年度',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500))),
        IconButton(
            tooltip: '次の年度',
            onPressed: () => setState(() => year++),
            icon: const Icon(Icons.chevron_right)),
      ]),
      Expanded(child: content),
    ]);
  }

  List<ContextAction> calendarDateActions(DateTime date) => [
        ContextAction('この日の変更', () => editDay(date)),
        if (engine.dayChange(date) != null)
          ContextAction(
              'この日の変更を削除',
              () => confirmRemove(
                  'day_changes', engine.dayChange(date)!, '日ごとの変更')),
        ContextAction('この日の講義を確認', () => showDay(date)),
        ContextAction('この日の期間を編集', () => editPeriodAt(date)),
        for (final event
            in data.rows('events').where((e) => engine.contains(e, date))) ...[
          ContextAction(
              '${periodLabel(data, event)}を編集', () => editEvent(event)),
          ContextAction('${periodLabel(data, event)}を削除',
              () => confirmRemove('events', event, '期間')),
        ],
        ContextAction('期間を追加',
            () => editEvent(null, DateTimeRange(start: date, end: date))),
        ContextAction('単発講義を追加', () => editMeeting(day: date, single: true)),
        ContextAction('祝日を休日にする', importHolidays),
      ];

  Future<void> editPeriodAt(DateTime date) async {
    final periods =
        data.rows('events').where((e) => engine.contains(e, date)).toList();
    if (periods.isEmpty) {
      await editEvent(null, DateTimeRange(start: date, end: date));
      return;
    }
    if (periods.length == 1) {
      await editEvent(periods.single);
      return;
    }
    final selected = await showAppDialog<DbRow>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => SimpleDialog(title: const Text('編集する期間'), children: [
              for (final e in periods)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, e),
                    child: Text(
                        '${periodLabel(data, e)}  ${e['start_date']} ～ ${e['end_date']}'))
            ]));
    if (selected != null) await editEvent(selected);
  }

  void selectPeriod() {
    beginDraft();
    setState(() {
      calendarEditing = true;
      selectingPeriod = true;
      calendarMenuOpen = false;
    });
  }

  Future<void> mergePeriods() async {
    final ids = <String>{};
    final name = text('');
    final periods = [...data.rows('events')]..sort((a, b) =>
        '${a['kind']}:${a['start_date']}'
            .compareTo('${b['kind']}:${b['start_date']}'));
    await editForm(
        context,
        '期間をまとめる',
        (_, set) => Column(children: [
              for (final period in periods)
                SelectionCheck(
                    label: Text(
                        '${periodLabel(data, period)} (${period['start_date']}～${period['end_date']})'),
                    selected: ids.contains(period['id']),
                    onSelected: (v) => set(() {
                          if (v) {
                            ids.add(period['id'] as String);
                          } else {
                            ids.remove(period['id']);
                          }
                        })),
              field(name, 'まとめた期間の名前（任意）'),
            ]), () async {
      await commit(() => db.mergePeriods(ids.toList(), name.text));
      return true;
    });
    name.dispose();
  }

  Future<void> editEvent([DbRow? row, DateTimeRange? range]) async {
    final name = text(row?['name']);
    final saved = data
        .rows('event_ranges')
        .where((r) => r['event_id'] == row?['id'])
        .toList();
    final ranges = <(TextEditingController, TextEditingController)>[
      if (saved.isNotEmpty)
        for (final r in saved) (text(r['start_date']), text(r['end_date']))
      else
        (
          text(row?['start_date'] ?? dayKey(range?.start ?? DateTime.now())),
          text(row?['end_date'] ?? dayKey(range?.end ?? DateTime.now()))
        )
    ];
    var kind = row?['kind'] as String? ?? 'teaching';
    await editForm(
        context,
        row == null ? '期間を登録' : '期間を編集',
        (ctx, set) => Column(children: [
              choice(
                  '種類',
                  kind,
                  {'teaching': '講義期間', 'exam': '試験期間', 'holiday': '全学休業日・長期休暇'},
                  (v) => set(() => kind = v)),
              field(name, '名前（任意）'),
              for (final part in ranges)
                Column(children: [
                  dateField(ctx, part.$1, '開始日'),
                  dateField(ctx, part.$2, '終了日'),
                  if (ranges.length > 1)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            onPressed: () => set(() => ranges.remove(part)),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('この日程を削除'))),
                ]),
              TextButton.icon(
                  onPressed: () => set(() => ranges.add((
                        text(dayKey(DateTime.now())),
                        text(dayKey(DateTime.now()))
                      ))),
                  icon: const Icon(Icons.add),
                  label: const Text('日程を追加')),
            ]), () async {
      for (final part in ranges) {
        if (DateTime.tryParse(part.$1.text) == null ||
            DateTime.tryParse(part.$2.text) == null ||
            part.$1.text.compareTo(part.$2.text) > 0) {
          throw const FormatException('終了日は開始日以降にしてください');
        }
      }
      final starts = ranges.map((r) => r.$1.text).toList()..sort();
      final ends = ranges.map((r) => r.$2.text).toList()..sort();
      final id = row?['id'] as String? ?? newId();
      await commit(() {
        db.put('events', {
          'id': id,
          'kind': kind,
          'term_id': row?['term_id'],
          'name': name.text,
          'start_date': starts.first,
          'end_date': ends.last,
          'color': null
        });
        db.db.execute('DELETE FROM event_ranges WHERE event_id=?', [id]);
        for (final part in ranges) {
          db.put('event_ranges', {
            'id': newId(),
            'event_id': id,
            'start_date': part.$1.text,
            'end_date': part.$2.text
          });
        }
      });
      return true;
    }, delete: row == null ? null : () => remove('events', row));
    name.dispose();
    for (final part in ranges) {
      part.$1.dispose();
      part.$2.dispose();
    }
  }

  Future<void> editDay(DateTime date) async {
    final old = engine.dayChange(date),
        replacement = text(engine.dayChange(date)?['replacement_date']);
    var cancelled = old == null || old['cancelled'] == 1,
        weekday = old?['source_weekday'] as int? ?? date.weekday;
    var substitute = !cancelled;
    await editForm(
        context,
        '${dayKey(date)}の全学設定',
        (ctx, set) => Column(children: [
              SegmentedButton<bool>(
                  style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Theme.of(ctx).colorScheme.onSecondaryContainer
                              : Theme.of(ctx)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .55))),
                  segments: const [
                    ButtonSegment(value: true, label: Text('全学休業')),
                    ButtonSegment(value: false, label: Text('代替日')),
                  ],
                  showSelectedIcon: false,
                  selected: {cancelled},
                  onSelectionChanged: (v) => set(() {
                        cancelled = v.first;
                        substitute = !cancelled;
                      })),
              const SizedBox(height: 20),
              if (cancelled)
                dateField(ctx, replacement, 'この日の代替日（任意）', optional: true),
              if (substitute)
                choice(
                    '代わりの時間割',
                    weekday,
                    {for (var i = 1; i <= 7; i++) i: '${weekdays[i - 1]}曜日'},
                    (v) => set(() => weekday = v)),
              const Text('全学代替日は、その日に本来ある曜日の講義を置き換えます。')
            ]), () async {
      if (cancelled && replacement.text == dayKey(date)) {
        throw const FormatException('代替日は別の日を指定してください');
      }
      if (cancelled &&
          replacement.text.isNotEmpty &&
          engine.dayChange(DateTime.parse(replacement.text)) != null &&
          replacement.text != old?['replacement_date']) {
        throw const FormatException('代替先には既に全学設定があります。別の日を選んでください');
      }
      await commit(() {
        if (old?['replacement_date'] != null) {
          final linked = engine
              .dayChange(DateTime.parse(old!['replacement_date'] as String));
          if (linked != null) db.remove('day_changes', linked['id'] as String);
        }
        db.put('day_changes', {
          'id': old?['id'] ?? newId(),
          'date': dayKey(date),
          'cancelled': cancelled ? 1 : 0,
          'is_national': old?['is_national'] ?? 0,
          'holiday_name': old?['holiday_name'],
          'source_weekday': cancelled
              ? (old?['source_weekday'] ?? date.weekday)
              : (substitute ? weekday : null),
          'exam_day': old?['exam_day'] ?? 0,
          'replacement_date':
              cancelled && replacement.text.isNotEmpty ? replacement.text : null
        });
        if (cancelled && replacement.text.isNotEmpty) {
          db.put('day_changes', {
            'id': newId(),
            'date': replacement.text,
            'cancelled': 0,
            'source_weekday': old?['source_weekday'] ?? date.weekday,
            'replacement_date': null
          });
        }
      });
      return true;
    },
        delete: old == null
            ? null
            : () async {
                await commit(() {
                  if (old['replacement_date'] != null) {
                    final linked = engine.dayChange(
                        DateTime.parse(old['replacement_date'] as String));
                    if (linked != null) {
                      db.remove('day_changes', linked['id'] as String);
                    }
                  }
                  db.remove('day_changes', old['id'] as String);
                });
              });
    replacement.dispose();
  }

  Future<void> importHolidays() async {
    try {
      final dataset =
          jsonDecode(await rootBundle.loadString('assets/holidays.json'))
              as Map;
      if (!mounted) return;
      final first = dataset['first_year'] as int,
          last = dataset['last_year'] as int;
      if (fiscalStart.year < first || fiscalEnd.year > last) {
        message('同梱の祝日データは$first～$last年です。この年度の全祝日を登録するにはデータの更新が必要です。');
        return;
      }
      final dates = (dataset['dates'] as Map)
          .entries
          .where((e) =>
              (e.key as String).compareTo(dayKey(fiscalStart)) >= 0 &&
              (e.key as String).compareTo(dayKey(fiscalEnd)) <= 0)
          .toList();
      final confirmed = await showAppDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
                  title: Text('$year年度の祝日を休業日に'),
                  content: Text(
                      '${dates.length}日の祝日・振替休日等を登録します。同じIDで登録済みの祝日は重複しません。\n出典: 内閣府（$first～$last年、オフラインデータ）'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('登録'))
                  ]));
      if (confirmed != true) return;
      await commit(() {
        for (final e in dates) {
          db.put('day_changes', {
            'id': engine.dayChange(DateTime.parse(e.key as String))?['id'] ??
                'jp-holiday-${e.key}',
            'date': e.key,
            'cancelled': 1,
            'holiday_name': e.value,
            'is_national': 1
          });
        }
      });
      message('${dates.length}日の祝日を登録しました');
    } catch (e) {
      message(e.toString());
    }
  }

  Widget settings() {
    final groups = {
      'general': '一般',
      'academic': '年度・授業時間',
      'display': '表示設定',
      if (!desktop) 'operations': '操作設定',
      'notifications': '通知',
      'accessibility': 'アクセシビリティ',
      'about': 'このアプリについて',
    };
    final contents = <Widget>[];
    switch (settingsCategory) {
      case 'about':
        contents.addAll([
          section('うに時間割', [
            FutureBuilder<String>(
                future: applicationVersion,
                builder: (context, snapshot) => SelectableText(
                    'バージョン: ${snapshot.data ?? (snapshot.hasError ? '取得できません' : '…')}')),
          ]),
          section('制作者', [
            const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('名前'),
                subtitle: SelectableText(appAuthorName)),
            const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('HP'),
                subtitle: SelectableText(appAuthorWebsite)),
            const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('GitHub'),
                subtitle: SelectableText(appAuthorGitHub)),
          ]),
          section('ソースコード', [
            const SelectableText(appRepository),
          ]),
          section('ライセンス', [const SelectableText('MIT License')]),
        ]);
        break;
      case 'general':
        contents.add(section('ファイル', [
          SelectableText(widget.storage.location,
              style: const TextStyle(fontSize: 12)),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
                onPressed: openDatabase,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('.unitableを開く')),
            OutlinedButton.icon(
                onPressed: () => openDatabase(create: true),
                icon: const Icon(Icons.add),
                label: const Text('新しい.unitableを作成')),
            OutlinedButton.icon(
                onPressed: exportDatabase,
                icon: const Icon(Icons.save_alt),
                label: const Text('コピーを書き出す')),
          ]),
          if (widget.storage.pendingSyncError != null)
            Text(widget.storage.pendingSyncError!),
        ]));
        break;
      case 'academic':
        contents.add(section('年度・授業時間', [
          LayoutBuilder(builder: (ctx, size) {
            final width =
                size.maxWidth < 480 ? size.maxWidth : (size.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 8, children: [
              SizedBox(
                  width: width,
                  child: settingsChoice(
                      '年度の開始月',
                      int.parse(data.setting('year_start', '4')),
                      {for (var m = 1; m <= 12; m++) m: '$m月'},
                      (v) => setting('year_start', v.toString()))),
              SizedBox(
                  width: width,
                  child: settingsChoice('週の開始曜日', weekStart, {
                    for (var i = 1; i <= 7; i++) i: '${weekdays[i - 1]}曜日'
                  }, (v) async {
                    await setting('week_start', v.toString());
                    setState(() => week = beginningOfWeek(week));
                  })),
            ]);
          }),
          slotTableHeader(),
          for (final slot in data.slots) slotSettings(slot),
          TextButton.icon(
              onPressed: () => editSlot(),
              icon: const Icon(Icons.add),
              label: const Text('コマを追加')),
        ]));
        break;
      case 'display':
        contents.addAll([
          section('配色', [
            settingsChoice(
                'テーマ',
                data.setting('theme_mode', 'system'),
                {'system': '端末に合わせる', 'light': 'ライト', 'dark': 'ダーク'},
                (v) => setting('theme_mode', v)),
            preferenceSwitch(
                contentPadding: EdgeInsets.zero,
                title: const Text('有機EL用の黒い背景'),
                value: data.setting('oled_black', '0') == '1',
                onChanged: isDark(context)
                    ? (v) => setting('oled_black', v ? '1' : '0')
                    : null),
          ]),
          section('時間割の表示', [
            preferenceSwitch(
                contentPadding: EdgeInsets.zero,
                title: const Text('連続表示'),
                value: data.setting('timetable_scroll', 'week') == 'smooth',
                onChanged: (v) =>
                    setting('timetable_scroll', v ? 'smooth' : 'week')),
            if (data.setting('timetable_scroll', 'week') == 'smooth')
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('コマ幅'),
                  trailing: Text(
                      '${data.setting('timetable_column_width', desktop ? '120' : '80')}px'),
                  onTap: editTimetableWidth),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('科目名の文字サイズ'),
                trailing: Text(data.setting('course_font_size', '18')),
                onTap: () =>
                    editTimetableFont('course_font_size', '科目名の文字サイズ', '18')),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('教室名の文字サイズ'),
                trailing: Text(data.setting('room_font_size', '12')),
                onTap: () =>
                    editTimetableFont('room_font_size', '教室名の文字サイズ', '12')),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('時間割に表示しない曜日'),
                trailing: const Icon(Icons.chevron_right),
                onTap: editHiddenWeekdays),
          ]),
          ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text('詳細設定'),
              tilePadding: EdgeInsets.zero,
              children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('カラーパレット'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: editAppPalette),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('年間予定の表示優先順位'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: editCalendarStyle),
              ]),
        ]);
        break;
      case 'operations':
        if (!desktop) {
          contents.add(ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('長押しの判定時間'),
              trailing:
                  Text('${data.setting('calendar_long_press_ms', '500')}ms'),
              onTap: editLongPressDuration));
        }
        break;
      case 'notifications':
        contents.addAll([
          section('通知', [
            preferenceSwitch(
                contentPadding: EdgeInsets.zero,
                title: const Text('通知を使う'),
                value: canNotify && data.setting('notifications', '0') == '1',
                onChanged: canNotify ? toggleNotifications : null),
            Text(canNotify ? notices.status : 'この版では通知を利用できません。',
                style: const TextStyle(fontSize: 12)),
            if (NotificationService.testingEnabled) ...[
              const SizedBox(height: 16),
              const Text('通知テスト（テストAPK限定）'),
              const Text('課題確認通知と「課題を追加」を確認できます。予約は最新の1件です。'),
              if (data.rows('courses').isNotEmpty)
                choice('テストする科目',
                    data.find('courses', notificationTestCourse)?['id'] as String? ??
                        data.rows('courses').first['id'] as String,
                    {for (final c in data.rows('courses'))
                      c['id'] as String: c['name'] as String},
                    (v) => setState(() => notificationTestCourse = v)),
              for (final option in const <(String, Duration)>[
                ('今すぐ通知をテスト', Duration.zero),
                ('30秒後に通知をテスト', Duration(seconds: 30)),
                ('5分後に通知をテスト', Duration(minutes: 5)),
              ])
                OutlinedButton.icon(
                    onPressed: canNotify && !sendingTestNotification &&
                            data.rows('courses').isNotEmpty
                        ? () => testNotification(option.$2) : null,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(option.$1)),
              const SizedBox(height: 16),
            ],
            if (Platform.isAndroid && canNotify)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('正確な時刻の通知を許可'),
                  subtitle: const Text('端末の「アラームとリマインダー」を許可すると通知の遅れを軽減できます。'),
                  onTap: () async {
                    try {
                      await notices.requestExactAlarms();
                      if (mounted) refreshNotifications();
                    } catch (e) {
                      message(e.toString());
                    }
                  }),
            if (Platform.isAndroid && canNotify)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('省電力設定を確認'),
                  subtitle: const Text('通知が遅れる場合は、アプリ情報からバッテリーの制限を見直してください。'),
                  onTap: () async {
                    try {
                      await notices.openBatterySettings();
                    } catch (e) {
                      message(e.toString());
                    }
                  }),
            preferenceSwitch(
                contentPadding: EdgeInsets.zero,
                title: const Text('教室を通知する'),
                value: data.leadMinutes >= 0,
                onChanged: canNotify
                    ? (v) => setting('lead_minutes',
                        v ? data.setting('last_lead_minutes', '10') : '-1')
                    : null),
            if (data.leadMinutes >= 0)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('講義開始${data.leadMinutes}分前'),
                  enabled: canNotify,
                  onTap: canNotify ? editLeadTiming : null,
                  trailing: const Icon(Icons.edit_outlined, size: 18)),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('新しい課題の通知タイミング'),
                onTap: editGlobalRules,
                trailing: const Icon(Icons.chevron_right)),
          ]),
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('休日の定義'),
              trailing: const Icon(Icons.chevron_right),
              onTap: editHolidayDefinition),
          ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text('詳細設定'),
              tilePadding: EdgeInsets.zero,
              children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('大学のタイムゾーン'),
                    subtitle: Text(data.setting('timezone', 'Asia/Tokyo')),
                    onTap: editTimezone),
                if (Platform.isWindows)
                  const Text('Windowsで予約の取消・再設定を確実に行うにはMSIX版を使用してください。',
                      style: TextStyle(fontSize: 12)),
                const Text('予約は今後1年分のうち直近480件までです。起動・画面復帰時に補充します。',
                    style: TextStyle(fontSize: 12)),
              ]),
        ]);
        break;
      case 'accessibility':
        contents.addAll([
          preferenceSwitch(
              contentPadding: EdgeInsets.zero,
              title: const Text('動きを減らす'),
              value: data.setting('reduce_motion', '0') == '1',
              onChanged: (v) => setting('reduce_motion', v ? '1' : '0')),
          preferenceSwitch(
              contentPadding: EdgeInsets.zero,
              title: const Text('色覚に配慮した表示'),
              value: data.setting('accessibility_marks', '0') == '1',
              onChanged: (v) => setting('accessibility_marks', v ? '1' : '0')),
          preferenceSwitch(
              contentPadding: EdgeInsets.zero,
              title: const Text('文字色を濃くする'),
              value: data.setting('dark_text', '0') == '1',
              onChanged: (v) => setting('dark_text', v ? '1' : '0')),
        ]);
        break;
    }
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: settingsCategory == null
                ? ListView(children: [
                    for (final entry in groups.entries)
                      ListTile(
                          title: Text(entry.value),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              setState(() => settingsCategory = entry.key)),
                  ])
                : PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (!didPop) setState(() => settingsCategory = null);
                    },
                    child: Column(children: [
                      Row(children: [
                        IconButton(
                            tooltip: '設定一覧に戻る',
                            onPressed: () =>
                                setState(() => settingsCategory = null),
                            icon: const Icon(Icons.arrow_back)),
                        Expanded(
                            child: Text(groups[settingsCategory] ?? '',
                                style: const TextStyle(fontSize: 20)))
                      ]),
                      Expanded(child: ListView(children: contents)),
                    ]))));
  }

  Future<void> editLongPressDuration() async {
    final value = text(data.setting('calendar_long_press_ms', '500'));
    await editForm(context, '長押しの判定時間',
        (_, set) => field(value, '時間（ミリ秒）', number: true, required: true),
        () async {
      final ms = int.parse(value.text);
      if (ms <= 0 || ms > 2147483647) {
        throw const FormatException('1以上のミリ秒を入力してください');
      }
      await setting('calendar_long_press_ms', ms.toString());
      return true;
    });
    value.dispose();
  }

  Future<void> editTimetableWidth() async {
    final value =
        text(data.setting('timetable_column_width', desktop ? '120' : '80'));
    await editForm(context, 'コマ幅',
        (_, set) => field(value, '幅（px）', number: true, required: true),
        () async {
      final width = int.parse(value.text);
      if (width < 40 || width > 600) {
        throw const FormatException('40〜600の数値を入力してください');
      }
      await setting('timetable_column_width', width.toString());
      return true;
    });
    value.dispose();
  }

  Future<void> editAppPalette() async {
    var dark = isDark(context);
    final light = Map<String, int>.from(appPalette(data, false));
    final night = Map<String, int>.from(appPalette(data, true));
    await editForm(context, 'カラーパレット', (ctx, set) {
      final colors = dark ? night : light;
      Widget entry(String key, String label) => ListTile(
          key: ValueKey('palette-role-$key'),
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Color(colors[key]!),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Theme.of(ctx).colorScheme.outlineVariant))),
          onTap: () async {
            final result = await editRgba(ctx, label, colors[key]!);
            if (result != null && ctx.mounted) set(() => colors[key] = result);
          });
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        choice('編集する配色', dark, {false: 'ライト', true: 'ダーク'},
            (v) => set(() => dark = v)),
        for (final group in paletteGroups.entries)
          ExpansionTile(
              title: Text(group.key),
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: EdgeInsets.zero,
              children: [
                for (final e in group.value.entries) entry(e.key, e.value)
              ]),
        for (final kind in ['teaching', 'exam'])
          ExpansionTile(
              title: Text(kind == 'teaching' ? '講義期間の9色' : '試験期間の9色'),
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < 9; i++) entry('${kind}_$i', '${i + 1}番目')
              ]),
        TextButton(
            onPressed: () => set(() {
                  colors
                    ..clear()
                    ..addAll(paletteDefaults(dark));
                }),
            child: const Text('この配色を初期値に戻す')),
      ]);
    }, () async {
      await commit(() {
        db.put(
            'settings', {'id': 'ui_palette_light', 'value': jsonEncode(light)});
        db.put(
            'settings', {'id': 'ui_palette_dark', 'value': jsonEncode(night)});
      });
      return true;
    }, fullScreen: true, topAligned: true);
  }

  Future<void> editCalendarStyle() async {
    final order = calendarOrder(data);
    await editForm(
        context,
        '年間予定の表示優先順位',
        (_, set) => Column(children: [
              ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) => set(
                      () => order.insert(newIndex, order.removeAt(oldIndex))),
                  children: [
                    for (var i = 0; i < order.length; i++)
                      ListTile(
                          key: ValueKey(order[i]),
                          title: Text(calendarRuleLabels[order[i]]!),
                          trailing: ReorderableDragStartListener(
                              index: i, child: const Icon(Icons.drag_handle)))
                  ]),
              TextButton(
                  onPressed: () => set(() {
                        order
                          ..clear()
                          ..addAll(calendarRuleLabels.keys);
                      }),
                  child: const Text('初期値に戻す')),
            ]), () async {
      await setting('calendar_order', jsonEncode(order));
      return true;
    }, fullScreen: true);
  }

  Future<int?> editRgba(BuildContext ctx, String label, int color) async {
    final channels = [
      text((color >> 16) & 255),
      text((color >> 8) & 255),
      text(color & 255),
      text((color >> 24) & 255)
    ];
    int? result;
    await editForm(
        ctx,
        label,
        (_, set) => Column(children: [
              AnimatedBuilder(
                  animation: Listenable.merge(channels),
                  builder: (context, _) {
                    final values = [
                      for (final channel in channels)
                        (int.tryParse(channel.text) ?? 0).clamp(0, 255)
                    ];
                    return ColorPalette(
                        color: (values[3] << 24) |
                            (values[0] << 16) |
                            (values[1] << 8) |
                            values[2],
                        onChanged: (v) {
                          for (var i = 0; i < 4; i++) {
                            channels[i].text =
                                ((v >> [16, 8, 0, 24][i]) & 255).toString();
                          }
                        });
                  }),
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('RGBAで指定'),
                  children: [
                    for (var i = 0; i < 4; i++)
                      field(channels[i], ['R', 'G', 'B', 'A'][i],
                          number: true, required: true)
                  ]),
            ]), () async {
      final values = channels.map((c) => int.parse(c.text)).toList();
      if (values.any((v) => v < 0 || v > 255)) {
        throw const FormatException('0〜255の整数を入力してください');
      }
      result =
          (values[3] << 24) | (values[0] << 16) | (values[1] << 8) | values[2];
      return true;
    });
    for (final c in channels) {
      c.dispose();
    }
    return result;
  }

  Future<void> editTimetableFont(
      String key, String label, String fallback) async {
    final value = text(data.setting(key, fallback));
    await editForm(context, label,
        (_, set) => field(value, '文字サイズ', number: true, required: true),
        () async {
      final size = double.tryParse(value.text);
      if (size == null || !size.isFinite || size < 8 || size > 36) {
        throw const FormatException('8〜36の数値を入力してください');
      }
      await setting(key, size.toString());
      return true;
    });
    value.dispose();
  }

  Future<void> editHiddenWeekdays() async {
    final days = {...hiddenWeekdays};
    await editForm(
        context,
        '時間割に表示しない曜日',
        (_, set) => Column(children: [
              for (var day = 1; day <= 7; day++)
                SelectionCheck(
                    key: ValueKey('hidden-weekday-$day'),
                    label: Text('${weekdays[day - 1]}曜日'),
                    selected: days.contains(day),
                    onSelected: (v) => set(() {
                          if (v) {
                            days.add(day);
                          } else {
                            days.remove(day);
                          }
                        })),
            ]), () async {
      await setting(
          'hidden_weekdays',
          jsonEncode(
              (days.toList()..sort()).map((d) => d.toString()).toList()));
      return true;
    });
  }

  Future<void> editHolidayDefinition() async {
    final options = Map<String, dynamic>.from(holidayOptions);
    final days = (options['weekdays'] as List? ?? []).cast<int>().toSet();
    final onlyEmpty =
        (options['only_no_classes'] as List? ?? []).cast<int>().toSet();
    await editForm(
        context,
        '休日の定義',
        (_, set) => Column(children: [
              SelectionCheck(
                  label: const Text('休業日・祝日'),
                  selected: options['closures'] == true,
                  onSelected: (v) => set(() => options['closures'] = v)),
              SelectionCheck(
                  label: const Text('講義がない日'),
                  selected: options['no_classes'] == true,
                  onSelected: (v) => set(() => options['no_classes'] = v)),
              for (var day = 1; day <= 7; day++)
                Column(children: [
                  SelectionCheck(
                      key: ValueKey('holiday-weekday-$day'),
                      label: Text('${weekdays[day - 1]}曜日'),
                      selected: days.contains(day),
                      onSelected: (v) => set(() {
                            if (v) {
                              days.add(day);
                            } else {
                              days.remove(day);
                            }
                          })),
                  Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 8),
                      child: preferenceSwitch(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('講義がない日に限定する'),
                          value: onlyEmpty.contains(day),
                          onChanged: !days.contains(day)
                              ? null
                              : (v) => set(() {
                                    if (v) {
                                      onlyEmpty.add(day);
                                    } else {
                                      onlyEmpty.remove(day);
                                    }
                                  }))),
                ]),
            ]), () async {
      options['weekdays'] = days.toList()..sort();
      options['only_no_classes'] = onlyEmpty.toList()..sort();
      await setting('notification_holidays', jsonEncode(options));
      return true;
    });
  }

  Map<String, dynamic> get holidayOptions => jsonDecode(data.setting(
          'notification_holidays',
          '{"closures":true,"weekdays":[7],"no_classes":false}'))
      as Map<String, dynamic>;
  Future<void> updateHolidayOptions(String key, dynamic value) => setting(
      'notification_holidays', jsonEncode({...holidayOptions, key: value}));

  Future<void> editLeadTiming() async {
    final lead = text(data.leadMinutes < 0
        ? data.setting('last_lead_minutes', '10')
        : data.leadMinutes);
    await editForm(context, '教室の通知',
        (_, set) => field(lead, '開始何分前', number: true, required: true),
        () async {
      if (int.parse(lead.text) < 0) {
        throw const FormatException('0以上の分数を入力してください');
      }
      await commit(() {
        db.put('settings', {'id': 'lead_minutes', 'value': lead.text});
        db.put('settings', {'id': 'last_lead_minutes', 'value': lead.text});
      });
      return true;
    });
    lead.dispose();
  }

  Future<void> editTimezone() async {
    zones.initializeTimeZones();
    var zone = data.setting('timezone', 'Asia/Tokyo');
    final filter = text('');
    final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
    await editForm(
        context,
        '大学のタイムゾーン',
        (ctx, set) => Column(children: [
              TextField(
                  controller: filter,
                  decoration: const InputDecoration(
                      labelText: '地域を検索', prefixIcon: Icon(Icons.search)),
                  onChanged: (_) => set(() {})),
              const SizedBox(height: 8),
              Text(zone),
              SizedBox(
                  height: 280,
                  child: ListView(children: [
                    for (final name in names.where((n) =>
                        n.toLowerCase().contains(filter.text.toLowerCase())))
                      ListTile(
                          title: Text(name),
                          trailing:
                              zone == name ? const Icon(Icons.check) : null,
                          onTap: () => set(() => zone = name))
                  ]))
            ]), () async {
      notices.validateTimezone(zone);
      await setting('timezone', zone);
      return true;
    });
    filter.dispose();
  }

  Future<void> toggleNotifications(bool enabled) async {
    try {
      if (enabled && !await notices.requestPermission()) {
        message('通知の許可が必要です。端末の設定を確認してください。');
        return;
      }
      await setting('notifications', enabled ? '1' : '0');
    } catch (e) {
      message(e.toString());
    }
  }

  Widget settingsChoice<T>(String label, T value, Map<T, String> values,
          Future<void> Function(T) change) =>
      ContextActions(
          desktop: desktop,
          actions: [
            for (final entry in values.entries)
              ContextAction('$label: ${entry.value}', () => change(entry.key))
          ],
          child: choice(label, value, values, change));

  Widget slotTableHeader() => LayoutBuilder(builder: (ctx, size) {
        final large = size.maxWidth >= 650;
        return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(children: [
              SizedBox(width: large ? 76 : 36),
              const Expanded(
                  child: Center(
                      child: Text('開始', style: TextStyle(fontSize: 16)))),
              SizedBox(width: large ? 120 : 52),
              const Expanded(
                  child: Center(
                      child: Text('終了', style: TextStyle(fontSize: 16)))),
              SizedBox(width: large ? 92 : 44)
            ]));
      });
  Widget slotSettings(DbRow slot) => ContextActions(
      desktop: desktop,
      actions: [
        ContextAction('開始時刻を変更', () => editSlotTime(slot, true)),
        ContextAction('終了時刻を変更', () => editSlotTime(slot, false)),
        ContextAction(
            'コマを削除', data.slots.length <= 1 ? null : () => deleteSlot(slot))
      ],
      child: LayoutBuilder(builder: (ctx, size) {
        final large = size.maxWidth >= 650;
        Widget button(bool start) => Expanded(
            child: Center(
                child: SizedBox(
                    width: large ? 112 : 76,
                    height: large ? 48 : 40,
                    child: TextButton(
                        key: ValueKey(
                            'slot-${slot['id']}-${start ? 'start' : 'end'}'),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .06)),
                        onPressed: () => editSlotTime(slot, start),
                        child: Text(
                            clock(slot[start ? 'start_minute' : 'end_minute']
                                as int),
                            style: TextStyle(fontSize: large ? 22 : 16))))));
        return Padding(
            padding: EdgeInsets.symmetric(vertical: large ? 12 : 8),
            child: Row(children: [
              SizedBox(
                  width: large ? 76 : 36,
                  child: Center(
                      child: Text('${slot['position']}限',
                          style: TextStyle(fontSize: large ? 22 : 15)))),
              button(true),
              SizedBox(
                  width: large ? 120 : 52,
                  child: Center(
                      child: Text(
                          '${(slot['end_minute'] as int) - (slot['start_minute'] as int)}分',
                          style: TextStyle(fontSize: large ? 20 : 13)))),
              button(false),
              SizedBox(width: large ? 28 : 4),
              SizedBox(
                  width: large ? 64 : 40,
                  height: large ? 64 : 52,
                  child: IconButton(
                      tooltip: '${slot['position']}限を削除',
                      onPressed: data.slots.length <= 1
                          ? null
                          : () => deleteSlot(slot),
                      icon: Icon(Icons.delete_outline, size: large ? 28 : 22)))
            ]));
      }));
  Future<void> editSlot([DbRow? row]) async {
    var start = row?['start_minute'] as int? ??
            min(1348, (data.slots.last['end_minute'] as int) + 10),
        end = row?['end_minute'] as int? ??
            min(1439, (data.slots.last['end_minute'] as int) + 100);
    final position = row?['position'] as int? ?? data.slots.length + 1;
    await editForm(
        context,
        '$position限の時間',
        (ctx, set) => Column(children: [
              ListTile(
                  title: Text('開始 ${clock(start)}'),
                  onTap: () async {
                    final t = await pickTime(
                        ctx, TimeOfDay(hour: start ~/ 60, minute: start % 60));
                    if (t != null) set(() => start = t.hour * 60 + t.minute);
                  }),
              ListTile(
                  title: Text('終了 ${clock(end)}'),
                  onTap: () async {
                    final t = await pickTime(
                        ctx, TimeOfDay(hour: end ~/ 60, minute: end % 60));
                    if (t != null) set(() => end = t.hour * 60 + t.minute);
                  })
            ]), () async {
      if (end <= start) throw const FormatException('終了時刻は開始時刻より後にしてください');
      await put('slots', {
        'id': row?['id'] ?? newId(),
        'position': position,
        'start_minute': start,
        'end_minute': end
      });
      return true;
    });
  }

  Future<void> editSlotTime(DbRow slot, bool start) async {
    final column = start ? 'start_minute' : 'end_minute';
    final value = slot[column] as int;
    final result = await pickTime(
        context, TimeOfDay(hour: value ~/ 60, minute: value % 60),
        helpText: '${slot['position']}限の${start ? '開始' : '終了'}時刻');
    if (result == null) return;
    final minute = result.hour * 60 + result.minute;
    final begin = start ? minute : slot['start_minute'] as int;
    final end = start ? slot['end_minute'] as int : minute;
    if (end <= begin) {
      message('終了時刻は開始時刻より後にしてください');
      return;
    }
    await put('slots', {'id': slot['id'], column: minute});
  }

  Future<void> deleteSlot(DbRow slot) async {
    if (data.rows('meetings').any((m) => m['slot_id'] == slot['id']) ||
        data
            .rows('session_changes')
            .any((m) => m['replacement_slot_id'] == slot['id'])) {
      message('このコマを使う講義があります。先に授業を変更してください。');
      return;
    }
    await commit(() {
      db.remove('slots', slot['id'] as String);
      for (final remaining in data.slots
          .where((s) => (s['position'] as int) > (slot['position'] as int))) {
        db.put('slots', {
          'id': remaining['id'],
          'position': (remaining['position'] as int) - 1
        });
      }
    });
  }

  Future<void> exportDatabase() async {
    try {
      if (Platform.isAndroid) {
        final folder = await widget.storage.chooseFolder();
        if (folder == null) return;
        if (await widget.storage.treeHasDatabase(folder)) {
          message('書き出し先にuniversity.unitableがあります。空のフォルダーを選んでください。');
          return;
        }
        final temp =
            p.join(widget.storage.support.path, 'export-${newId()}.unitable');
        try {
          db.snapshot(temp);
          await Storage.channel
              .invokeMethod('writeDatabase', {'tree': folder, 'path': temp});
        } finally {
          if (File(temp).existsSync()) await File(temp).delete();
        }
      } else {
        final target = await getSaveLocation(
            suggestedName: 'university-copy.unitable',
            acceptedTypeGroups: [
              const XTypeGroup(label: 'UniTable', extensions: ['unitable'])
            ]);
        if (target == null) return;
        final path = target.path.toLowerCase().endsWith('.unitable')
            ? target.path
            : '${target.path}.unitable';
        if (File(path).existsSync()) {
          message('既存のファイルは上書きしません。別の名前を選んでください。');
          return;
        }
        db.snapshot(path);
      }
      message('データベースのコピーを書き出しました');
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> openDatabase({bool create = false}) async {
    try {
      await notificationQueue;
      final old = db;
      old.removeListener(changed);
      bool selected;
      try {
        selected = await widget.storage.selectDatabase(create: create);
      } finally {
        db.addListener(changed);
      }
      if (!selected) return;
      selectedTerm = '';
      refreshNotifications();
      changed();
    } catch (e) {
      message(e.toString());
    }
  }
}
