import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/ui/home.dart';
import 'package:unitable/ui/annual_calendar.dart';
import 'package:unitable/ui/accessibility.dart';
import 'package:unitable/ui/status_marks.dart';
import 'package:unitable/ui/selection_check.dart';
import 'package:unitable/domain/periods.dart';
import 'package:unitable/ui/color_palette.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  setUpAll(() async {
    final icons = File(
        '.tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    if (await icons.exists()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
            Future.value(ByteData.sublistView(await icons.readAsBytes())));
      await loader.load();
    }
    final font = File('assets/fonts/NotoSansJP.ttf');
    if (await font.exists()) {
      final loader = FontLoader('Noto Sans JP')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
  });
  late Directory folder;
  late Storage storage;
  final appVersion = RegExp(r'^version:\s*([^+\s]+)', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync())!
      .group(1)!;
  setUp(() {
    PackageInfo.setMockInitialValues(
        appName: 'うに時間割',
        packageName: 'net.neomenia.unitable',
        version: appVersion,
        buildNumber: '17',
        buildSignature: '');
    folder = Directory.systemTemp.createTempSync('unitable-ui-');
    storage = Storage()
      ..support = folder
      ..preferences = File('${folder.path}/location.json')
      ..database = UnitDatabase.open('${folder.path}/test.unitable');
  });
  tearDown(() {
    if (storage.hasDatabase) storage.database.dispose();
    folder.deleteSync(recursive: true);
  });
  Widget app({bool desktop = true, TextScaler? textScaler}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: textScaler ?? MediaQuery.textScalerOf(context)),
          child: AccessibilityScope(
              storage: storage, desktop: desktop, child: child!)),
      scrollBehavior:
          const MaterialScrollBehavior().copyWith(scrollbars: false),
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Noto Sans JP',
          colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xff398b72),
                  surface: const Color(0xfffcfdfb))
              .copyWith(
                  primary: const Color(0xff398b72),
                  secondary: const Color(0xff398b72),
                  secondaryContainer: const Color(0xffd9f0e5)),
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xffeef5f0),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0),
          scaffoldBackgroundColor: const Color(0xfffcfdfb)),
      home: Home(storage: storage, enableNativeNotifications: false, desktop: desktop));
  void populate() {
    storage.database.transaction(() {
      storage.database
          .put('terms', {'id': 'term', 'name': '後期', 'color': 0xff419c79});
      storage.database.put('events', {
        'id': 'period',
        'kind': 'teaching',
        'term_id': 'term',
        'name': '後期授業',
        'start_date': '2026-09-01',
        'end_date': '2027-01-31'
      });
      storage.database.put('day_changes', {
        'id': 'jp-holiday-2026-11-03',
        'date': '2026-11-03',
        'cancelled': 1,
        'is_national': 1,
        'holiday_name': '文化の日'
      });
      storage.database.put('events', {
        'id': 'winter-break',
        'kind': 'holiday',
        'name': '冬季休業',
        'start_date': '2026-12-26',
        'end_date': '2027-01-08'
      });
      final courses = [
        ['情報科学', 'A-201', '山田 太郎'],
        ['線形代数', 'B-302', '佐藤 花子'],
        ['英語コミュニケーション', 'C-104', '鈴木 一郎'],
        ['経済学入門', 'A-108', '田中 恵'],
        ['プログラミング演習', '情報演習室', '高橋 健']
      ];
      for (var i = 0; i < courses.length; i++) {
        storage.database.put('courses', {
          'id': 'c$i',
          'name': courses[i][0],
          'room': courses[i][1],
          'teacher': courses[i][2],
          'notes': '## 今週のメモ\n- テキストを持参\n- 次回は演習',
          'term_ids': '["term"]'
        });
        for (var n = 0; n < 2; n++) {
          storage.database.put('meetings', {
            'id': 'm$i-$n',
            'course_id': 'c$i',
            'slot_id': 'slot-${n + 1 + i % 3}',
            'weekday': i + 1,
            'term_id': 'term',
            'period_id': 'period'
          });
        }
      }
      storage.database.put('tasks', {
        'id': 'task',
        'title': '第3回 演習レポート',
        'course_id': 'c0',
        'due_at': '2026-10-16T17:00:00',
        'destination': '大学LMS'
      });
    });
  }

  Finder input(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField));
  Finder cell(DateTime date) =>
      find.byKey(ValueKey('calendar-${dayKey(date)}'));
  Future<void> nav(WidgetTester tester, int index) async {
    if (find.byType(NavigationBar).evaluate().isNotEmpty) {
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(index);
    } else {
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      await tester.tap(find
          .widgetWithText(ListTile, ['時間割', '課題', '年間予定', '設定'][index])
          .last);
    }
    await tester.pumpAndSettle();
  }

  Future<void> size(WidgetTester tester, Size value) async {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> screenshot(
      WidgetTester tester, GlobalKey key, String filename) async {
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(() async {
      final image = await (key.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('artifacts').create(recursive: true);
      await File('artifacts/$filename.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('時間割の編集内容は保存まで変更せず破棄で元に戻りナビを隠す', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    final shot = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: shot, child: app(desktop: false)));
    await tester.pumpAndSettle();
    final count = storage.database.data.rows('meetings').length;
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await screenshot(tester, shot, 'unitable-012-lecture-editor');
    await tester.tap(find.byTooltip('講義を登録').first);
    await tester.pumpAndSettle();
    await tester.enterText(input('講義名'), '保存前の授業');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('meetings').length, count);
    expect(find.text('保存前の授業'), findsWidgets);
    await tester.tap(find.byTooltip('編集から戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集を破棄'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(storage.database.data.rows('meetings').length, count);
    expect(find.text('保存前の授業'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('年間予定の編集はメニューを隠し期間統合を保存まで確定せず破棄できる', (tester) async {
    populate();
    storage.database.transaction(() => storage.database.put('events', {
          'id': 'later',
          'kind': 'teaching',
          'start_date': '2026-12-01',
          'end_date': '2026-12-31',
          'name': '12月'
        }));
    final originalCount = storage.database.data.rows('events').length;
    await size(tester, const Size(1280, 900));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await nav(tester, 2);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.widgetWithText(ListTile, '時間割'), findsNothing);
    await tester.tap(find.byTooltip('年間予定の操作'));
    await tester.pumpAndSettle();
    expect(find.text('期間をまとめる'), findsOneWidget);
    // A click on a day while the menu is open only closes the menu.
    await tester.tapAt(tester.getCenter(cell(DateTime.now())));
    await tester.pumpAndSettle();
    expect(find.text('期間をまとめる'), findsNothing);
    expect(find.textContaining('の全学設定'), findsNothing);
    await tester.tap(find.byTooltip('年間予定の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('期間をまとめる'));
    await tester.pumpAndSettle();
    for (final check in find.byType(SelectionCheck).evaluate().toList()) {
      final label = ((check.widget as SelectionCheck).label as Text).data!;
      if (!label.startsWith('後期授業') && !label.startsWith('12月')) continue;
      await tester.tap(find.byWidget(check.widget));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('events').length, originalCount);
    await tester.tap(find.byTooltip('編集から戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集を破棄'));
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('events').length, originalCount);
    expect(find.widgetWithText(ListTile, '時間割'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('時間割の過去の祝日・休業日を灰色にし今日以降は赤を保つ', (tester) async {
    final today = dateOnly(DateTime.now());
    final past = shiftDay(today, -2), future = shiftDay(today, 1);
    storage.database.transaction(() {
      for (final (date, label) in [(past, '過去の休業'), (future, 'これからの休業')]) {
        storage.database.put('day_changes', {
          'id': dayKey(date),
          'date': dayKey(date),
          'cancelled': 1,
          'is_national': 1,
          'holiday_name': label
        });
      }
      storage.database
          .put('settings', {'id': 'hidden_weekdays', 'value': '[]'});
    });
    await size(tester, const Size(1280, 900));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    var box = find.byKey(ValueKey('holiday-${dayKey(past)}'));
    if (box.evaluate().isEmpty) {
      await tester.tap(find.byTooltip('前の週'));
      await tester.pumpAndSettle();
    }
    expect((tester.widget<Container>(box).decoration as BoxDecoration).color,
        const Color(0xffeeeeee));
    expect(
        tester
            .widget<Text>(find.text('過去の休業'.characters.join('\n')))
            .style!
            .color,
        const Color(0xff929292));
    if (find.byKey(ValueKey('holiday-${dayKey(future)}')).evaluate().isEmpty) {
      await tester.tap(find.byTooltip('次の週'));
      await tester.pumpAndSettle();
    }
    expect(
        (tester
                .widget<Container>(
                    find.byKey(ValueKey('holiday-${dayKey(future)}')))
                .decoration as BoxDecoration)
            .color,
        const Color(0xfff1b5b8));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('課題削除のフローティング復元通知を横スワイプで消せる', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.drag(find.byType(Dismissible).first, const Offset(-400, 0));
    await tester.pumpAndSettle();
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.behavior, SnackBarBehavior.floating);
    expect(snack.duration, const Duration(seconds: 3));
    expect(find.text('元に戻す'), findsOneWidget);
    await tester.drag(find.byType(SnackBar), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(storage.database.data.rows('tasks'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('320pxでも色覚記号・期間選択と年間予定の複数記号を収める', (tester) async {
    populate();
    final today = dateOnly(DateTime.now());
    storage.database.transaction(() {
      for (final key in ['accessibility_marks', 'reduce_motion', 'dark_text']) {
        storage.database.put('settings', {'id': key, 'value': '1'});
      }
      storage.database
          .put('settings', {'id': 'timetable_scroll', 'value': 'smooth'});
      storage.database.put('day_changes',
          {'id': 'substitute', 'date': dayKey(today), 'source_weekday': 1});
      storage.database.put('events', {
        'id': 'overlap',
        'kind': 'teaching',
        'start_date': dayKey(today),
        'end_date': dayKey(shiftDay(today, 10))
      });
      storage.database.put('events', {
        'id': 'exam',
        'kind': 'exam',
        'start_date': dayKey(today),
        'end_date': dayKey(shiftDay(today, 10))
      });
      storage.database.put('meetings', {
        'id': 'single',
        'course_id': 'c0',
        'slot_id': 'slot-5',
        'once_date': dayKey(today)
      });
      storage.database.put('meetings', {
        'id': 'exam-m',
        'course_id': 'c1',
        'slot_id': 'slot-1',
        'once_date': dayKey(shiftDay(today, 1)),
        'exam_period_id': 'exam'
      });
    });
    await size(tester, const Size(320, 900));
    final key = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: key, child: app(desktop: false)));
    await tester.pumpAndSettle();
    expect(find.byType(StatusMark), findsWidgets);
    await screenshot(tester, key, 'unitable-0110-accessible-timetable');
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, 'unitable-0110-period-picker');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    await screenshot(tester, key, 'unitable-0110-accessible-calendar');
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await screenshot(tester, key, 'unitable-0110-accessible-calendar-edit');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('同名の未使用科目を選んでも期限ピッカーは実際の授業を選んで保存できる', (tester) async {
    populate();
    storage.database.transaction(() =>
        storage.database.put('courses', {'id': 'unused', 'name': '情報科学'}));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.tap(find.byTooltip('課題を追加'));
    await tester.pumpAndSettle();
    final selector = tester
        .widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(selector.items!.where((i) => (i.child as Text).data == '情報科学'),
        hasLength(1));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('情報科学').last);
    await tester.pumpAndSettle();
    await tester.enterText(input('課題名'), '科目選択後の提出');
    await tester.tap(find.text('時間割から提出日時を選ぶ'));
    await tester.pumpAndSettle();
    final lecture = find.descendant(
        of: find.byType(AlertDialog), matching: find.text('情報科学'));
    expect(lecture, findsWidgets);
    expect(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('線形代数')),
        findsWidgets);
    await tester.tap(lecture.first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('情報科学）に提出'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    final saved = storage.database.data
        .rows('tasks')
        .firstWhere((t) => t['title'] == '科目選択後の提出');
    expect(saved['course_id'], 'c0');
    expect(saved['context_meeting_id'], isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final oled in [false, true]) {
    testWidgets('ダークモード${oled ? '・有機EL' : ''}で全ページと編集・期限ピッカーを表示する',
        (tester) async {
      populate();
      storage.database.transaction(() {
        storage.database.put('settings', {'id': 'theme_mode', 'value': 'dark'});
        storage.database
            .put('settings', {'id': 'oled_black', 'value': oled ? '1' : '0'});
        storage.database
            .put('settings', {'id': 'accessibility_marks', 'value': '1'});
        storage.database.put('settings', {'id': 'dark_text', 'value': '1'});
      });
      await size(tester, const Size(390, 844));
      final key = GlobalKey();
      await tester
          .pumpWidget(RepaintBoundary(key: key, child: app(desktop: false)));
      await tester.pumpAndSettle();
      var context = tester.element(find.text('時間割').first);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).scaffoldBackgroundColor,
          oled ? Colors.black : const Color(0xff141b17));
      expect(Theme.of(context).colorScheme.onSurface, Colors.white);
      final bars = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
          .value;
      expect(bars.statusBarIconBrightness, Brightness.light);
      expect(bars.systemNavigationBarColor,
          oled ? Colors.black : const Color(0xff141b17));
      await screenshot(
          tester, key, 'unitable-0111-dark${oled ? '-oled' : ''}-timetable');
      await nav(tester, 1);
      await screenshot(
          tester, key, 'unitable-0111-dark${oled ? '-oled' : ''}-tasks');
      await tester.tap(find.byTooltip('課題を追加'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('時間割から提出日時を選ぶ'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(AlertDialog))).brightness,
          Brightness.dark);
      await tester.tap(find.text('キャンセル').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル').last);
      await tester.pumpAndSettle();
      await nav(tester, 2);
      await screenshot(
          tester, key, 'unitable-0111-dark${oled ? '-oled' : ''}-calendar');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await screenshot(tester, key,
          'unitable-0111-dark${oled ? '-oled' : ''}-calendar-edit');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      await nav(tester, 3);
      await tester.tap(find.text('表示設定'));
      await tester.pumpAndSettle();
      expect(find.text('有機EL用の黒い背景'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('テーマの切り替え・黒背景を端末に保存し時間割の保存後も設定を保持する', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 3);
    await tester.tap(find.text('表示設定'));
    await tester.pumpAndSettle();
    var toggle = tester.widget<AppToggle>(find.descendant(
        of: find.widgetWithText(ListTile, '有機EL用の黒い背景'),
        matching: find.byType(AppToggle)));
    expect(toggle.onChanged, isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ダーク').last);
    await tester.pumpAndSettle();
    var context = tester.element(find.text('有機EL用の黒い背景'));
    expect(Theme.of(context).brightness, Brightness.dark);
    await tester.tap(find.text('有機EL用の黒い背景'));
    await tester.pumpAndSettle();
    expect(Theme.of(context).scaffoldBackgroundColor, Colors.black);
    await nav(tester, 0);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
        identical(storage.database.appSettings, storage.localSettings), isTrue);
    await nav(tester, 3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('有機EL用の黒い背景'));
    await tester.pumpAndSettle();
    context = tester.element(find.text('有機EL用の黒い背景'));
    expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xff141b17));
    final stored = jsonDecode(storage.preferences.readAsStringSync()) as Map;
    expect((stored['settings'] as Map)['theme_mode'], 'dark');
    expect((stored['settings'] as Map)['oled_black'], '0');
    expect(
        storage.database.db
            .select("SELECT name FROM sqlite_master WHERE name='settings'"),
        isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('端末に合わせるテーマはOSの明暗変更に追従する', (tester) async {
    await size(tester, const Size(390, 844));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('時間割').first)).brightness,
        Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('時間割').first)).brightness,
        Brightness.light);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('非表示曜日でも授業がある日は提出日時の候補に表示する', (tester) async {
    var day = dateOnly(DateTime.now());
    while (day.weekday != 7) {
      day = shiftDay(day, 1);
    }
    storage.database.transaction(() {
      storage.database.put('courses', {'id': 'sun', 'name': '日曜授業'});
      storage.database.put('meetings', {
        'id': 'sun-meeting',
        'course_id': 'sun',
        'slot_id': 'slot-1',
        'once_date': dayKey(day)
      });
    });
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.tap(find.byTooltip('課題を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日曜授業').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('時間割から提出日時を選ぶ'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('日曜授業')),
        findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('日曜授業')));
    await tester.pumpAndSettle();
    expect(find.textContaining('日曜授業）に提出'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('提出日時は他の科目でも選べ指定した課題の科目を変更しない', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    final shot = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: shot, child: app(desktop: false)));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.tap(find.byTooltip('課題を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('情報科学').last);
    await tester.pumpAndSettle();
    await tester.enterText(input('課題名'), '他科目の開始に提出');
    await tester.tap(find.text('時間割から提出日時を選ぶ'));
    await tester.pumpAndSettle();
    final framed = find.byWidgetPredicate((w) =>
        w is Container &&
        w.key is ValueKey &&
        ((w.key as ValueKey).value as String).startsWith('deadline-lecture-') &&
        (w.decoration as BoxDecoration).border != null);
    expect(framed, findsWidgets);
    await screenshot(tester, shot, 'unitable-012-deadline-picker');
    for (final element in framed.evaluate()) {
      expect(
          find.descendant(
              of: find.byWidget(element.widget), matching: find.text('情報科学')),
          findsOneWidget);
    }
    final other = find.descendant(
        of: find.byType(AlertDialog), matching: find.text('線形代数'));
    await tester.tap(other.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    final task = storage.database.data
        .rows('tasks')
        .firstWhere((t) => t['title'] == '他科目の開始に提出');
    expect(task['course_id'], 'c0');
    expect(
        storage.database.data.find(
            'meetings', task['context_meeting_id'] as String)!['course_id'],
        'c1');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('空きコマを選んだ期限は日時として保存し講義参照は作らない', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.tap(find.byTooltip('課題を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(input('課題名'), '空き時間までに提出');
    await tester.tap(find.text('時間割から提出日時を選ぶ'));
    await tester.pumpAndSettle();
    final empty = find
        .byWidgetPredicate((w) =>
            w is InkWell &&
            w.key is ValueKey &&
            ((w.key as ValueKey).value as String).startsWith('deadline-empty-'))
        .first;
    await tester.tap(empty);
    await tester.pumpAndSettle();
    expect(find.textContaining('限目に提出'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    final task = storage.database.data
        .rows('tasks')
        .firstWhere((t) => t['title'] == '空き時間までに提出');
    expect(task['context_meeting_id'], isNull);
    expect(task['due_at'], isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final desktop in [false, true]) {
    testWidgets('${desktop ? 'PC' : 'スマホ'}の設定一覧の最後にアプリ情報を表示する', (tester) async {
      await size(
          tester, desktop ? const Size(1280, 900) : const Size(320, 844));
      await tester.pumpWidget(app(desktop: desktop));
      await tester.pumpAndSettle();
      await nav(tester, 3);
      final categories = find.descendant(
          of: find.byType(ConstrainedBox),
          matching: find.widgetWithText(ListTile, 'このアプリについて'));
      expect(categories, findsWidgets);
      expect(tester.getTopLeft(find.text('このアプリについて')).dy,
          greaterThan(tester.getTopLeft(find.text('アクセシビリティ')).dy));
      await tester.tap(find.text('このアプリについて'));
      await tester.pumpAndSettle();
      for (final value in [
        'バージョン: $appVersion',
        appAuthorName,
        appAuthorWebsite,
        appAuthorGitHub,
        appRepository
      ]) {
        expect(
            find.byWidgetPredicate(
                (widget) => widget is SelectableText && widget.data == value),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await nav(tester, 3);
      expect(find.byTooltip('設定一覧に戻る'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final desktop in [false, true]) {
    testWidgets('${desktop ? 'PC' : 'スマホ'}でモーダルの背後のナビを維持し設定を再選択すると一覧へ戻る',
        (tester) async {
      await size(
          tester, desktop ? const Size(1280, 900) : const Size(390, 844));
      await tester.pumpWidget(app(desktop: desktop));
      await tester.pumpAndSettle();
      final navigation = desktop
          ? find.widgetWithText(ListTile, '時間割', skipOffstage: false)
          : find.byType(NavigationBar, skipOffstage: false);
      final navigationElement = tester.element(navigation);
      final navigationRect = tester.getRect(navigation);
      await nav(tester, 1);
      await tester.tap(find.byTooltip('課題を追加'));
      await tester.pumpAndSettle();
      expect(tester.element(navigation), same(navigationElement));
      expect(tester.getSize(navigation), navigationRect.size);
      await tester.tap(find.text('キャンセル').last);
      await tester.pump();
      expect(tester.element(navigation), same(navigationElement));
      expect(tester.getSize(navigation), navigationRect.size);
      await tester.pumpAndSettle();
      expect(tester.getRect(navigation), navigationRect);
      await nav(tester, 3);
      await tester.tap(find.text('表示設定'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('時間割に表示しない曜日'));
      await tester.tap(find.text('時間割に表示しない曜日'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.element(navigation), same(navigationElement));
      expect(tester.getRect(navigation), navigationRect);
      await tester.tap(find.text('キャンセル').last);
      await tester.pumpAndSettle();
      await nav(tester, 3);
      expect(find.byTooltip('設定一覧に戻る'), findsNothing);
      expect(find.widgetWithText(ListTile, '表示設定'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('ライトとダークのパレットは全画面で編集し保存するまで反映しない', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    final shot = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: shot, child: app(desktop: false)));
    await tester.pumpAndSettle();
    await nav(tester, 3);
    await tester.tap(find.text('表示設定'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('詳細設定'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('詳細設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('カラーパレット'));
    await tester.tap(find.text('カラーパレット'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await screenshot(tester, shot, 'unitable-012-palette');
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationBar, skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('基本'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-role-background')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar, skipOffstage: false), findsOneWidget);
    const light = 0xffd45459, dark = 0xff222222;
    await tester.ensureVisible(find.byKey(const ValueKey('palette-$light')));
    await tester.tap(find.byKey(const ValueKey('palette-$light')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.setting('ui_palette_light', ''), '');
    await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<bool>), -300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byType(DropdownButtonFormField<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ダーク').last);
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('palette-role-background')));
    await tester.tap(find.byKey(const ValueKey('palette-role-background')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('palette-$dark')));
    await tester.tap(find.byKey(const ValueKey('palette-$dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(
        jsonDecode(storage.database.data.setting('ui_palette_light', '{}'))[
            'background'],
        light);
    expect(
        jsonDecode(storage.database.data.setting('ui_palette_dark', '{}'))[
            'background'],
        dark);
    expect(Theme.of(tester.element(find.text('表示設定'))).scaffoldBackgroundColor,
        const Color(light));
    final settings = (jsonDecode(storage.preferences.readAsStringSync())
        as Map)['settings'] as Map;
    expect(settings['ui_palette_dark'], isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final value in [false, true]) {
    testWidgets('色覚表示の${value ? 'ON' : 'OFF'}の丸を端の丸みの中心へ揃える', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: AppToggle(
                  value: value, marks: true, still: true, onChanged: (_) {}))));
      await tester.pumpAndSettle();
      final track = tester.getRect(find.byType(AnimatedContainer));
      final thumb = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle);
      expect(tester.getCenter(thumb).dx,
          closeTo(value ? track.right - 16 : track.left + 16, .01));
      expect(tester.getCenter(thumb).dy, closeTo(track.center.dy, .01));
      expect(tester.getSize(thumb).width, value ? 24 : 16);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('ライト配色で年間予定の背景を暗くしても日付を読める文字色にする', (tester) async {
    populate();
    storage.database.transaction(() => storage.database.put('settings',
        {'id': 'ui_palette_light', 'value': '{"calendar_active":4279312947}'}));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    var date = shiftDay(dateOnly(DateTime.now()), 1);
    while (ScheduleEngine(storage.database.data)
        .onDay(date, includeCancelled: false)
        .isEmpty) {
      date = shiftDay(date, 1);
    }
    final dateText = tester.widget<Text>(
        find.descendant(of: cell(date), matching: find.byType(Text)));
    expect(dateText.style!.color, Colors.white);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PCは狭い幅でメニューを開き広い幅では常時開いて下部タブを置かない', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await nav(tester, 2);
    expect(find.byType(AnnualCalendar), findsOneWidget);
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.widgetWithText(ListTile, '時間割'), findsOneWidget);
    await tester.longPress(find.widgetWithText(ListTile, '課題'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('PCは右クリックを残し年間の日付にTooltipを置かない', (tester) async {
    populate();
    await size(tester, const Size(1280, 900));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await nav(tester, 2);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    final date = DateTime.now();
    await tester.tapAt(tester.getCenter(cell(date)),
        buttons: kSecondaryMouseButton, kind: ui.PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(find.text('この日の変更'), findsOneWidget);
    await tester.tap(find.text('この日の変更'));
    await tester.pumpAndSettle();
    expect(find.text('${dayKey(date)}の全学設定'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AnnualCalendar), matching: find.byType(Tooltip)),
        findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('講義コマをシートで開き固定の期間曜日時限を表示しOS戻るで保存確認する', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.byTooltip('講義を登録').first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('曜日を追加'), findsNothing);
    expect(find.byType(SelectionCheck), findsNothing);
    expect(find.textContaining('曜日'), findsWidgets);
    await tester.enterText(input('講義名'), '新しい授業');
    await tester.enterText(input('教室名'), 'X-101');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('変更を保存しますか？'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('編集'), findsOneWidget);
    expect(
        storage.database.data.rows('courses').any((c) => c['name'] == '新しい授業'),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('シートの外側は保存せず閉じ仮想キーボード表示中はキーボードだけ閉じる', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('講義を登録').first);
    await tester.pumpAndSettle();
    await tester.enterText(input('講義名'), '保存しない');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 40));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 40));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
        storage.database.data.rows('courses').any((c) => c['name'] == '保存しない'),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('時間割の再選択は今週へ戻り曜日は期限の課題だけを表示する', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('次の週'));
    await tester.pumpAndSettle();
    await nav(tester, 0);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '今週'))
            .onPressed,
        isNull);
    final heading = find.widgetWithText(TextButton, '金\n10/16');
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(find.text('第3回 演習レポート'), findsOneWidget);
    expect(find.textContaining('講義名: 情報科学'), findsOneWidget);
    expect(find.textContaining('提出先: 大学LMS'), findsOneWidget);
    expect(find.textContaining('提出時間: 17:00'), findsOneWidget);
    expect(find.text('講義の予定はありません'), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(tester.getSize(heading).width, greaterThan(40));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('文字サイズから全時限の高さを揃え大きい文字と改行も収める', (tester) async {
    populate();
    storage.database.transaction(() {
      storage.database
          .put('settings', {'id': 'course_font_size', 'value': '36'});
      storage.database.put('settings', {'id': 'room_font_size', 'value': '30'});
      storage.database
          .put('courses', {'id': 'c0', 'name': '情報\n科学\n演習', 'room': '第一教室'});
    });
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    final name = tester.widget<Text>(find.text('情報\n科学\n演習').first);
    expect(name.maxLines, 3);
    expect(tester.widget<Text>(find.text('第一教室').first).maxLines, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('試験の時間割は日付を横に並べシートで登録し週に繰り返さない', (tester) async {
    populate();
    final date = dateOnly(DateTime.now());
    storage.database.transaction(() => storage.database.put('events', {
          'id': 'exam',
          'kind': 'exam',
          'name': '秋試験',
          'start_date': dayKey(date),
          'end_date': dayKey(shiftDay(date, 14))
        }));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('秋試験').last);
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w is ListView && w.scrollDirection == Axis.horizontal),
        findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(input('科目名'), '試験数学');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(
        storage.database.data
            .rows('meetings')
            .any((m) => m['exam_period_id'] == 'exam'),
        isFalse);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final meeting = storage.database.data
        .rows('meetings')
        .firstWhere((m) => m['exam_period_id'] == 'exam');
    expect(meeting['once_date'], dayKey(date));
    expect(meeting['weekday'], isNull);
    expect(
        ScheduleEngine(storage.database.data)
            .onDay(shiftDay(date, 7))
            .any((s) => s.meeting['id'] == meeting['id']),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('編集開始は閲覧した週の早い期間を開き選択肢は講義期間を優先して日付順にする', (tester) async {
    final date = dateOnly(DateTime.now());
    storage.database.transaction(() {
      storage.database.put('events', {
        'id': 'late',
        'kind': 'teaching',
        'name': '後の講義',
        'start_date': dayKey(date),
        'end_date': dayKey(shiftDay(date, 20))
      });
      storage.database.put('events', {
        'id': 'early',
        'kind': 'teaching',
        'name': '先の講義',
        'start_date': dayKey(shiftDay(date, -20)),
        'end_date': dayKey(shiftDay(date, 5))
      });
      storage.database.put('events', {
        'id': 'exam',
        'kind': 'exam',
        'name': '試験',
        'start_date': dayKey(shiftDay(date, -1)),
        'end_date': dayKey(shiftDay(date, 10))
      });
    });
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    final menu = tester
        .widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(menu.value, 'early');
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .items!
            .map((i) => i.value),
        ['early', 'late', 'exam']);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('課題は閲覧ポップアップから全画面編集を開き未指定の空行を作らずメモをプレビューする', (tester) async {
    storage.database.transaction(() => storage.database.put('tasks', {
          'id': 'task',
          'title': '自主課題',
          'due_at': '2026-10-16T17:00:00',
          'notes': '1行\n2行\n3行\n4行'
        }));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    expect(find.textContaining('講義名:'), findsNothing);
    expect(tester.widget<Text>(find.text('1行\n2行\n3行\n4行')).maxLines, 3);
    await tester.tap(find.text('自主課題'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    await tester.enterText(input('課題名'), '編集済み');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('tasks').single['title'], '編集済み');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('APK課題は長押し複数選択して編集・完了・削除しスワイプ削除を復元できる', (tester) async {
    storage.database.transaction(() {
      for (var i = 0; i < 2; i++) {
        storage.database.put('tasks',
            {'id': 't$i', 'title': '課題$i', 'due_at': '2026-10-16T17:00:00'});
      }
    });
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    await tester.longPress(find.text('課題0'));
    await tester.pumpAndSettle();
    expect(find.text('1件選択中'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('課題1'));
    await tester.pumpAndSettle();
    expect(find.text('2件選択中'), findsOneWidget);
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('tasks').every((t) => t['done'] == 1),
        isTrue);
    storage.database.transaction(
        () => storage.database.put('tasks', {'id': 't0', 'done': 0}));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const ValueKey('task-t0')), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(storage.database.data.find('tasks', 't0'), isNull);
    await tester.tap(find.text('元に戻す'));
    await tester.pumpAndSettle();
    expect(storage.database.data.find('tasks', 't0'), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('年間は過去月を折りたたみ年度を固定しクリックで祝日名と代替日を表示する', (tester) async {
    populate();
    final date = dateOnly(DateTime.now());
    storage.database.transaction(() => storage.database.put('day_changes', {
          'id': 'todayholiday',
          'date': dayKey(date),
          'cancelled': 0,
          'source_weekday': date.weekday,
          'is_national': 1,
          'holiday_name': 'テスト祝日'
        }));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    expect(find.text('過去を表示'), findsOneWidget);
    expect(cell(DateTime(date.year, 4, 6)), findsNothing);
    final yearPosition = tester.getCenter(find.textContaining('年度').first);
    final calendar = tester.widget<AnnualCalendar>(find.byType(AnnualCalendar));
    calendar.scrollController
        .jumpTo(calendar.scrollController.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.textContaining('年度').first), yearPosition);
    await nav(tester, 2);
    await tester.tap(cell(date));
    await tester.pumpAndSettle();
    expect(find.text('テスト祝日'), findsOneWidget);
    expect(find.text('代替日'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    calendar.scrollController.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('過去を表示'));
    await tester.pumpAndSettle();
    expect(cell(DateTime(date.year, 4, 6)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('カレンダーから逆順で期間を選び空の名前を保存したまま表示名を計算する', (tester) async {
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('年間予定の操作'));
    await tester.pumpAndSettle();
    expect(find.text('学期をまとめる'), findsNothing);
    await tester.tap(find.text('期間を追加'));
    await tester.pumpAndSettle();
    final today = dateOnly(DateTime.now());
    await tester.tap(cell(shiftDay(today, 2)));
    await tester.pumpAndSettle();
    await tester.tap(cell(today));
    await tester.pumpAndSettle();
    expect(find.text('期間を登録'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.rows('events'), isEmpty);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final event = storage.database.data.rows('events').single;
    expect(event['name'], '');
    expect(event['term_id'], isNull);
    expect(storage.database.data.rows('terms'), isEmpty);
    expect(event['start_date'], dayKey(today));
    expect(periodLabel(storage.database.data, event), '講義期間');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('今日への移動中は連打を無視し閲覧編集の位置を日付で維持する', (tester) async {
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    final today = dateOnly(DateTime.now());
    final y = tester.getCenter(cell(today)).dy;
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect((tester.getCenter(cell(today)).dy - y).abs(), lessThan(3));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((tester.getCenter(cell(today)).dy - y).abs(), lessThan(3));
    final c = tester
        .widget<AnnualCalendar>(find.byType(AnnualCalendar))
        .scrollController;
    c.jumpTo(c.position.maxScrollExtent);
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected!(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 5; i++) {
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(2);
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect((tester.getCenter(cell(today)).dy - y).abs(), lessThan(3));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('APKの長押し時間は操作設定にあり半マス以上移動したらスクロールへ移る', (tester) async {
    populate();
    storage.database.transaction(() => storage.database
        .put('settings', {'id': 'calendar_long_press_ms', 'value': '200'}));
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 2);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    final c = tester
        .widget<AnnualCalendar>(find.byType(AnnualCalendar))
        .scrollController;
    final date = dateOnly(DateTime.now());
    final before = c.offset;
    var gesture = await tester.startGesture(tester.getCenter(cell(date)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -35));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.offset, greaterThan(before));
    expect(find.byType(AlertDialog), findsNothing);
    gesture = await tester.startGesture(tester.getCenter(cell(date)));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('期間を編集'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('設定はチェックボックスで休日と非表示曜日を独立させ連続表示時だけ幅を出す', (tester) async {
    populate();
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 3);
    expect(find.text('表示設定'), findsOneWidget);
    expect(find.text('操作設定'), findsOneWidget);
    expect(find.text('開発者用設定'), findsNothing);
    await tester.tap(find.text('表示設定'));
    await tester.pumpAndSettle();
    expect(find.text('コマ幅'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, '連続表示'));
    await tester.pumpAndSettle();
    expect(find.text('コマ幅'), findsOneWidget);
    await tester.tap(find.text('時間割に表示しない曜日'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('hidden-weekday-1')));
    await tester.tap(find.byKey(const ValueKey('hidden-weekday-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(stringList(storage.database.data.setting('hidden_weekdays', '[]')),
        contains('1'));
    await tester.ensureVisible(find.byTooltip('設定一覧に戻る'));
    await tester.tap(find.byTooltip('設定一覧に戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通知'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('休日の定義'));
    expect(find.text('休日の定義'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(
        ScheduleEngine(storage.database.data).isHoliday(DateTime(2026, 10, 19)),
        isFalse);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('アクセシビリティの印・文字色・動きの設定は端末に保存し画面へ反映する', (tester) async {
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 3);
    await tester.tap(find.text('アクセシビリティ'));
    await tester.pumpAndSettle();
    for (final label in ['動きを減らす', '色覚に配慮した表示', '文字色を濃くする']) {
      await tester.tap(find.widgetWithText(ListTile, label));
      await tester.pumpAndSettle();
    }
    expect(storage.database.data.setting('accessibility_marks', '0'), '1');
    final context = tester.element(find.text('文字色を濃くする'));
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
    expect(Theme.of(context).colorScheme.onSurface, const Color(0xff101510));
    final toggle = tester.widget<AppToggle>(find.descendant(
        of: find.widgetWithText(ListTile, '動きを減らす'),
        matching: find.byType(AppToggle)));
    expect(toggle.marks, isTrue);
    expect(toggle.still, isTrue);
    expect(Theme.of(context).textTheme.bodyMedium!.shadows, isNotEmpty);
    expect(
        storage.database.db
            .select("SELECT name FROM sqlite_master WHERE name='settings'"),
        isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('課題の複数選択にも操作設定の長押し時間を使う', (tester) async {
    storage.database.transaction(() {
      storage.database.put(
          'tasks', {'id': 't', 'title': '課題', 'due_at': '2026-10-20T17:00:00'});
      storage.database
          .put('settings', {'id': 'calendar_long_press_ms', 'value': '200'});
    });
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 1);
    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey('task-t'))));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('1件選択中'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1件選択中'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('左の時限表示が大きい場合は左の高さを全コマへ使う', (tester) async {
    populate();
    storage.database.transaction(() {
      storage.database
          .put('settings', {'id': 'course_font_size', 'value': '8'});
      storage.database.put('settings', {'id': 'room_font_size', 'value': '8'});
    });
    await size(tester, const Size(390, 1000));
    await tester.pumpWidget(
        app(desktop: false, textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();
    final left = find
        .ancestor(
            of: find.text('1').first,
            matching: find
                .byWidgetPredicate((w) => w is SizedBox && w.height != null))
        .first;
    expect(tester.getSize(left).height, greaterThan(120));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('背景色をパレットから選んでRGBA値として保存する', (tester) async {
    await size(tester, const Size(390, 844));
    await tester.pumpWidget(app(desktop: false));
    await tester.pumpAndSettle();
    await nav(tester, 3);
    await tester.tap(find.text('表示設定'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('詳細設定'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('詳細設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('カラーパレット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('カラーパレット'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('年間予定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('palette-role-calendar_past')));
    await tester.tap(find.byKey(const ValueKey('palette-role-calendar_past')));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPalette), findsOneWidget);
    const color = 0xffd45459;
    await tester.ensureVisible(find.byKey(const ValueKey('palette-$color')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-$color')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(storage.database.data.setting('ui_palette_light', ''),
        contains('"calendar_past":$color'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320, 390]) {
    testWidgets('赤ドットは${width}pxの端の曜日でも切れず曜日を動かさない', (tester) async {
      populate();
      storage.database.transaction(() => storage.database.put('tasks',
          {'id': 'edge', 'title': '土曜提出', 'due_at': '2026-10-17T17:00:00'}));
      await size(tester, Size(width.toDouble(), 844));
      await tester.pumpWidget(app(desktop: false));
      await tester.pumpAndSettle();
      final heading = find.widgetWithText(TextButton, '土\n10/17');
      final text = find.text('土\n10/17');
      final before = tester.getCenter(text);
      final dot =
          find.descendant(of: heading, matching: find.byIcon(Icons.circle));
      expect(tester.getRect(dot).right,
          lessThanOrEqualTo(tester.getRect(heading).right));
      storage.database
          .transaction(() => storage.database.remove('tasks', 'edge'));
      await tester.pumpAndSettle();
      expect(tester.getCenter(text), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final desktop in [false, true]) {
    for (final width in desktop ? [320, 390, 640, 1280] : [320, 390]) {
      testWidgets('${desktop ? 'PC' : 'APK'} ${width}pxで全ページと各コマ・課題の登録を検証',
          (tester) async {
        populate();
        await size(tester, Size(width.toDouble(), 900));
        final key = GlobalKey();
        await tester.pumpWidget(
            RepaintBoundary(key: key, child: app(desktop: desktop)));
        await tester.pumpAndSettle();
        for (var page = 0; page < 4; page++) {
          await nav(tester, page);
          expect(tester.takeException(), isNull, reason: 'page $page');
        }
        await nav(tester, 0);
        await tester.tap(find.text('編集').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('講義を登録').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('保存').last);
        await tester.pumpAndSettle();
        await nav(tester, 2);
        await tester.tap(find.text('編集').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('年間予定の操作'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await screenshot(
            tester, key, 'unitable-0110-${desktop ? 'pc' : 'apk'}-$width');
        await tester.tap(find.byTooltip('閉じる'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('保存').last);
        await tester.pumpAndSettle();
        await nav(tester, 1);
        await tester.tap(find.byTooltip('課題を追加'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('時間割から提出日時を選ぶ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(1, 1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('キャンセル').last);
        await tester.pumpAndSettle();
        await nav(tester, 3);
        await tester.tap(find.text('年度・授業時間'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (desktop) expect(find.text('操作設定'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
