import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/services/notifications.dart';
import 'package:unitable/ui/accessibility.dart';
import 'package:unitable/ui/home.dart';
import 'fixtures.dart';

class LaunchNotices extends NotificationService {
  LaunchNotices(this.coldStart);
  final bool coldStart;
  @override
  bool get available => true;
  void pressAddTask(String courseId) => handleResponse(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: NotificationService.addTaskAction,
      payload: NotificationService.taskPayload(courseId)));
  @override
  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    if (coldStart) pressAddTask('c1');
  }
}

void main() {
  useTestSqlite();
  late Directory folder;
  late Storage storage;
  setUp(() {
    PackageInfo.setMockInitialValues(appName: 'うに時間割',
        packageName: 'net.neomenia.unitable', version: '1.0.1',
        buildNumber: '18', buildSignature: '');
    folder = Directory.systemTemp.createTempSync('unitable-notification-ui-');
    storage = Storage()
      ..support = folder
      ..preferences = File('${folder.path}/location.json')
      ..database = UnitDatabase.open('${folder.path}/test.unitable');
    storage.database.transaction(() => storage.database.replaceContent(sampleData()));
  });
  tearDown(() {
    storage.database.dispose();
    folder.deleteSync(recursive: true);
  });

  Widget app(NotificationService notices) => MaterialApp(
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => AccessibilityScope(storage: storage, child: child!),
      home: Home(storage: storage, notificationService: notices));

  for (final cold in [true, false]) {
    testWidgets('通知の課題追加で講義を自動入力して保存できる（終了中=$cold）', (tester) async {
      final notices = LaunchNotices(cold);
      await tester.pumpWidget(app(notices));
      await tester.pumpAndSettle();
      if (!cold) {
        notices.pressAddTask('c1');
        await tester.pumpAndSettle();
      }
      expect(find.text('課題を登録'), findsOneWidget);
      final courseField = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>));
      expect(courseField.initialValue, 'c1');
      final title = find.byWidgetPredicate((w) => w is TextField &&
          w.decoration?.labelText == '課題名');
      await tester.enterText(title, '通知から追加した課題');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final saved = storage.database.data.rows('tasks').single;
      expect(saved['title'], '通知から追加した課題');
      expect(saved['course_id'], 'c1');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('削除済みの講義の通知は案内を表示して追加画面を開かない', (tester) async {
    final notices = LaunchNotices(false);
    await tester.pumpWidget(app(notices));
    await tester.pumpAndSettle();
    notices.pressAddTask('deleted');
    await tester.pumpAndSettle();
    expect(find.text('通知の講義が見つかりません。'), findsOneWidget);
    expect(find.text('課題を登録'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('時間割の編集中に押した通知は編集終了後に科目付きで開く', (tester) async {
    final notices = LaunchNotices(false);
    await tester.pumpWidget(app(notices));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    notices.pressAddTask('c1');
    await tester.pumpAndSettle();
    expect(find.text('課題を登録'), findsNothing);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('課題を登録'), findsOneWidget);
    final courseField = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>));
    expect(courseField.initialValue, 'c1');
    await tester.pumpWidget(const SizedBox());
  });
}
