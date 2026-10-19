import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/domain/periods.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/l10n/strings.dart';
import 'package:unitable/main.dart';
import 'package:unitable/l10n/generated/app_localizations.dart';
import 'package:unitable/ui/home.dart';
import 'package:unitable/ui/navigation_destination.dart';
import 'package:unitable/ui/accessibility.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTestSqlite();
  setUpAll(() async {
    final fonts = {
      'MaterialIcons':
          '.tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      'Noto Sans JP': 'assets/fonts/NotoSansJP.ttf',
    };
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(await File(entry.value).readAsBytes()),
          ),
        );
      await loader.load();
    }
  });
  late Directory folder;
  late Storage storage;

  setUp(() async {
    setAppLocale(const Locale('ja'));
    folder = Directory.systemTemp.createTempSync('unitable-l10n-');
    storage = Storage();
    await storage.initialize(applicationDirectory: folder);
    PackageInfo.setMockInitialValues(
      appName: 'UniTable',
      packageName: 'net.neomenia.unitable',
      version: '1.0.1',
      buildNumber: '18',
      buildSignature: '',
    );
  });
  tearDown(() {
    if (storage.hasDatabase) storage.database.dispose();
    folder.deleteSync(recursive: true);
    setAppLocale(const Locale('ja'));
  });

  test('locale resolution supports overrides and falls back to Japanese', () {
    expect(
      resolveAppLocale('system', const Locale('en', 'US')),
      const Locale('en'),
    );
    expect(
      resolveAppLocale('system', const Locale('en', 'GB')),
      const Locale('en'),
    );
    expect(resolveAppLocale('system', const Locale('ja')), const Locale('ja'));
    expect(resolveAppLocale('system', const Locale('fr')), const Locale('ja'));
    expect(resolveAppLocale('en', const Locale('ja')), const Locale('en'));
    expect(resolveAppLocale('ja', const Locale('en')), const Locale('ja'));
  });

  test('English catalog has every message and matching placeholders', () {
    Map<String, dynamic> catalog(String locale) =>
        jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ja = catalog('ja'), en = catalog('en');
    final keys = ja.keys.where((key) => !key.startsWith('@')).toSet();
    expect(en.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    for (final key in keys) {
      final metadata = ja['@$key'] as Map<String, dynamic>?;
      final placeholders =
          metadata?['placeholders'] as Map<String, dynamic>? ?? {};
      for (final name in placeholders.keys.where(
        (name) => RegExp(
          '\\{${RegExp.escape(name)}(?:\\}|,)',
        ).hasMatch(ja[key] as String),
      )) {
        expect(
          RegExp(
            '\\{${RegExp.escape(name)}(?:\\}|,)',
          ).hasMatch(en[key] as String),
          isTrue,
          reason: '$key: $name',
        );
      }
      if (key != 'languageJapanese') {
        expect(
          RegExp('[ぁ-んァ-ヶ一-龯]').hasMatch(en[key] as String),
          isFalse,
          reason: key,
        );
      }
    }
  });

  test(
    'language is saved locally and excluded from exported databases',
    () async {
      storage.database = UnitDatabase.open('${folder.path}/test.unitable');
      storage.setLanguage('en');
      final reloaded = Storage();
      await reloaded.initialize(applicationDirectory: folder);
      expect(reloaded.localSettings['language'], 'en');
      storage.database.snapshot('${folder.path}/export.unitable');
      final exported = UnitDatabase.open('${folder.path}/export.unitable');
      expect(exported.data.setting('language', 'system'), 'system');
      exported.dispose();
    },
  );

  test('English labels and notification text preserve user content', () {
    final data = sampleData();
    final original = jsonEncode(data.tables);
    setAppLocale(const Locale('en'));
    expect(weekdays.first, 'Mon');
    expect(strings.annualCalendar, 'Calendar');
    expect(weekdays.map(strings.fullWeekdayName).toList(), [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]);
    expect(List.generate(12, (i) => strings.monthNumber('${i + 1}')), [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ]);
    expect(periodLabel(data, data.rows('events').first), '授業期間');
    final notices = planNotifications(data, DateTime(2026, 4, 6, 7), days: 1);
    expect(notices.any((notice) => notice.body.contains('Starts at')), isTrue);
    expect(
      notices.any(
        (notice) =>
            notice.body.contains('Were there any assignments for 情報科学?'),
      ),
      isTrue,
    );
    expect(jsonEncode(data.tables), original);
    final unnamed = {...data.rows('events').first, 'name': ''};
    expect(periodLabel(data, unnamed), 'Teaching period');
    setAppLocale(const Locale('ja'));
    expect(weekdays.first, '月');
    expect(periodLabel(data, unnamed), '講義期間');
  });

  test('native storage error codes follow the selected app language', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Storage.channel, (_) async {
          throw PlatformException(code: 'storageFolderPermission');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Storage.channel, null),
    );
    setAppLocale(const Locale('en'));
    await expectLater(
      invokeStorage('readDatabase'),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.message,
          'message',
          contains('Cannot read or write'),
        ),
      ),
    );
    setAppLocale(const Locale('ja'));
    await expectLater(
      invokeStorage('readDatabase'),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.message,
          'message',
          contains('フォルダーへの読み書き権限'),
        ),
      ),
    );
  });

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('artifacts').createSync(recursive: true);
      File('artifacts/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('startup follows device locale and reacts to changes', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(UniTableApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('Choose the .unitable file to use.'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
    tester.platformDispatcher.localeTestValue = const Locale('ja');
    await tester.pumpAndSettle();
    expect(find.text('使う.unitableファイルを指定してください。'), findsOneWidget);
    storage.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Choose the .unitable file to use.'), findsOneWidget);
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    await tester.pumpAndSettle();
    expect(find.text('Choose the .unitable file to use.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'English settings allow switching languages without reopening app',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      storage.database = UnitDatabase.open('${folder.path}/test.unitable');
      storage.setLanguage('en');
      final shot = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: shot,
          child: UniTableApp(storage: storage),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'General'));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsWidgets);
      expect(find.text('Open a .unitable file'), findsOneWidget);
      await capture(tester, shot, 'english-settings-mobile');
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('日本語').last);
      await tester.pumpAndSettle();
      expect(find.text('言語'), findsWidgets);
      expect(find.text('.unitableを開く'), findsOneWidget);
      expect(storage.localSettings['language'], 'ja');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('English phone pages and assignment editor fit at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      storage.database = UnitDatabase.open('${folder.path}/test.unitable');
      setAppLocale(const Locale('en'));
      final shot = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: shot,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(useMaterial3: true, fontFamily: 'Noto Sans JP'),
            builder: (context, child) => AccessibilityScope(
              storage: storage,
              desktop: false,
              child: child!,
            ),
            home: Home(
              storage: storage,
              desktop: false,
              enableNativeNotifications: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final page in [1, 2, 3, 0, 1]) {
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .onDestinationSelected!(page);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'page $page at $width');
        if (page == 2) {
          final heading = find.byKey(const ValueKey('calendar-academic-year'));
          final label = tester.widget<Text>(heading);
          final paragraph = tester.renderObject<RenderParagraph>(heading);
          expect(
            paragraph
                .getBoxesForSelection(
                  TextSelection(
                    baseOffset: 0,
                    extentOffset: label.data!.length,
                  ),
                )
                .length,
            1,
          );
          await capture(tester, shot, 'english-calendar-${width.toInt()}');
        }
      }
      await capture(tester, shot, 'english-assignments-${width.toInt()}');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Assignment name'), findsOneWidget);
      expect(find.text('Due date and time'), findsOneWidget);
      expect(find.text('Submit to'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, shot, 'english-assignment-editor-${width.toInt()}');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('wrapped navigation labels keep every line centered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Noto Sans JP'),
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            destinations: const [
              CenteredNavigationDestination(
                icon: Icon(Icons.view_week_outlined),
                label: 'Timetable',
              ),
              CenteredNavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                label: 'Assignments',
              ),
              CenteredNavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Academic Calendar',
              ),
              CenteredNavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Academic Calendar'),
    );
    final boxes = [
      ...paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 8),
      ),
      ...paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 9, extentOffset: 17),
      ),
    ];
    expect(boxes.length, 2);
    for (final box in boxes) {
      expect((box.left + box.right) / 2, closeTo(paragraph.size.width / 2, 1));
    }
    expect(paragraph.textAlign, TextAlign.center);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'English academic settings fit at $width px with text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          storage.database = UnitDatabase.open('${folder.path}/test.unitable');
          setAppLocale(const Locale('en'));
          final shot = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: shot,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: 'Noto Sans JP',
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: AccessibilityScope(
                    storage: storage,
                    desktop: false,
                    child: child!,
                  ),
                ),
                home: Home(
                  storage: storage,
                  desktop: false,
                  enableNativeNotifications: false,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(find.text('Calendar'), findsOneWidget);
          nav.onDestinationSelected!(3);
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(ListTile, 'University settings'),
          );
          await tester.pumpAndSettle();
          expect(find.text('April'), findsOneWidget);
          expect(find.text('Monday'), findsOneWidget);
          final months = find.byType(DropdownButtonFormField<int>).first;
          await tester.tap(months);
          await tester.pumpAndSettle();
          expect(find.text('January'), findsOneWidget);
          expect(find.text('December'), findsOneWidget);
          await tester.ensureVisible(find.text('January'));
          await tester.tap(find.text('January'));
          await tester.pumpAndSettle();
          expect(storage.database.data.setting('year_start', '4'), '1');
          final first = storage.database.data.slots.first;
          final label = find.byKey(ValueKey('slot-${first['id']}-label'));
          await tester.ensureVisible(label);
          await tester.pumpAndSettle();
          final text = tester.widget<Text>(label);
          expect(text.data, anyOf('Period 1', '1'));
          expect(text.semanticsLabel, 'Period 1');
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(
            paragraph
                .getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: text.data!.length),
                )
                .length,
            1,
          );
          final start = find.byKey(ValueKey('slot-${first['id']}-start'));
          final end = find.byKey(ValueKey('slot-${first['id']}-end'));
          expect(
            tester.getCenter(find.text('Start')).dx,
            closeTo(tester.getCenter(start).dx, .5),
          );
          expect(
            tester.getCenter(find.text('End')).dx,
            closeTo(tester.getCenter(end).dx, .5),
          );
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            shot,
            'english-academic-${width.toInt()}-${scale.toInt()}',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  test(
    'academic year labels respect calendar boundaries without changing Japanese',
    () {
      final april = DateTime(2026, 4, 1), march = DateTime(2027, 3, 31);
      final january = DateTime(2026, 1, 1), december = DateTime(2026, 12, 31);
      setAppLocale(const Locale('en'));
      expect(strings.universitySettings, 'University settings');
      expect(strings.academicYearStartsIn, 'Academic year starts in');
      expect(academicYearLabel(april, march), 'Academic year 2026–2027');
      expect(academicYearLabel(january, december), 'Academic year 2026');
      expect(
        academicYearLabel(DateTime(2026, 12, 1), DateTime(2027, 11, 30)),
        'Academic year 2026–2027',
      );
      setAppLocale(const Locale('ja'));
      expect(strings.universitySettings, '年度・授業時間');
      expect(strings.academicYearStartsIn, '年度の開始月');
      expect(academicYearLabel(april, march), '2026年度');
      expect(academicYearLabel(january, december), '2026年度');
    },
  );
}
