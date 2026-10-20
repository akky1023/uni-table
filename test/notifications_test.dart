import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/services/notifications.dart';
import 'fixtures.dart';

class AndroidNotices extends NotificationService {
  @override
  bool get isAndroid => true;
  @override
  void requireWindowsPackage() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late bool exact;
  late bool revokeOnSchedule;
  late List<Map<String, dynamic>> pending;
  NotificationResponse? launchResponse;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    exact = false;
    revokeOnSchedule = false;
    launchResponse = null;
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'pendingNotificationRequests':
          return pending;
        case 'initialize':
        case 'requestNotificationsPermission':
          return true;
        case 'canScheduleExactNotifications':
          return exact;
        case 'requestExactAlarmsPermission':
          exact = true;
          return true;
        case 'getNotificationAppLaunchDetails':
          return {
            'notificationLaunchedApp': launchResponse != null,
            if (launchResponse != null)
              'notificationResponse': {
                'notificationResponseType': 1,
                'actionId': launchResponse!.actionId,
                'payload': launchResponse!.payload,
              },
          };
        case 'zonedSchedule':
          if (revokeOnSchedule) {
            revokeOnSchedule = false;
            throw PlatformException(code: 'exact_alarms_not_permitted');
          }
      }
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  SchoolData futureData() {
    final data = sampleData();
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    data.rows('meetings').single['once_date'] = dayKey(tomorrow);
    data.rows('meetings').single['term_id'] = null;
    data.rows('settings').add({'id': 'notifications', 'value': '1'});
    return data;
  }

  test('通知を有効にすると通知権限と正確なアラーム権限を要求する', () async {
    final service = AndroidNotices();
    expect(await service.requestPermission(), isTrue);
    expect(calls.map((c) => c.method), containsAllInOrder([
      'requestNotificationsPermission',
      'canScheduleExactNotifications',
      'requestExactAlarmsPermission',
    ]));
  });

  test('許可済みの正確なアラーム権限を再要求しない', () async {
    exact = true;
    await AndroidNotices().requestPermission();
    expect(calls.where((c) => c.method == 'requestExactAlarmsPermission'), isEmpty);
  });

  for (final allowed in [true, false]) {
    test('正確な時刻の許可=$allowedで予約し課題確認だけに科目付きボタンを付ける', () async {
      exact = allowed;
      final service = AndroidNotices();
      await service.rebuild(futureData());
      final scheduled = calls.where((c) => c.method == 'zonedSchedule').toList();
      expect(scheduled, hasLength(2));
      expect(calls.map((c) => c.method), contains(NotificationService.testingEnabled
          ? 'pendingNotificationRequests' : 'cancelAllPendingNotifications'));
      expect(calls.map((c) => c.method), isNot(contains('cancelAll')));
      final args = Map<String, dynamic>.from(scheduled.last.arguments as Map);
      final android = args['platformSpecifics'] as Map;
      expect(android['scheduleMode'], allowed ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle');
      final action = (android['actions'] as List).single as Map;
      expect(action['title'], '課題を追加');
      expect(action['showsUserInterface'], isTrue);
      final destinations = <String>[];
      service.onAddTask = destinations.add;
      service.handleResponse(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: action['id'] as String,
          payload: args['payload'] as String));
      expect(destinations, ['c1']);
    });
  }

  test('予約中に正確な時刻の権限を失っても通知の予約を続ける', () async {
    exact = true;
    revokeOnSchedule = true;
    final service = AndroidNotices();
    await service.rebuild(futureData());
    expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(3));
    expect(service.status, contains('未許可'));
  });

  test('終了中のアプリを通知ボタンから起動しても対象の科目を受け取る', () async {
    launchResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: NotificationService.addTaskAction,
        payload: NotificationService.taskPayload('c1'));
    final destinations = <String>[];
    final service = AndroidNotices()..onAddTask = destinations.add;
    await service.initialize();
    expect(destinations, ['c1']);
  });

  test('通知本文・古い通知・不正な通知から課題追加を誤起動しない', () {
    final destinations = <String>[];
    final service = AndroidNotices()..onAddTask = destinations.add;
    for (final payload in ['check:m1:2026-04-06', '[]', '{', '{}']) {
      service.handleResponse(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: NotificationService.addTaskAction, payload: payload));
    }
    service.handleResponse(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: NotificationService.taskPayload('c1')));
    expect(destinations, isEmpty);
  });

  test('振替授業の課題確認でも元の科目IDを保持する', () {
    final data = sampleData();
    data.rows('session_changes').add({
      'meeting_id': 'm1', 'date': '2026-04-06',
      'replacement_date': '2026-08-15',
    });
    final notices = planNotifications(data, DateTime(2026, 8, 15), days: 0);
    expect(notices.singleWhere((n) => n.key.startsWith('check:')).courseId, 'c1');
    expect(notices.singleWhere((n) => n.key.startsWith('class:')).courseId, isNull);
  });

  if (NotificationService.testingEnabled) {
    test('即時テスト通知には選んだ科目の課題追加ボタンが付く', () async {
      final data = futureData();
      final service = AndroidNotices();
      expect(await service.sendTestNotification(data, data.rows('courses').single), isTrue);
      final args = calls.singleWhere((c) => c.method == 'show').arguments as Map;
      expect(args['id'], NotificationService.testNotificationId);
      expect(args['title'], '課題を確認（通知テスト）');
      expect(args['body'], contains('情報科学'));
      final destinations = <String>[];
      service.onAddTask = destinations.add;
      service.handleResponse(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: NotificationService.addTaskAction,
          payload: args['payload'] as String));
      expect(destinations, ['c1']);
    });

    for (final zone in ['Asia/Tokyo', 'UTC', 'America/New_York']) {
      test('30秒後のテスト通知を秒単位で予約する（$zone）', () async {
        final data = futureData();
        data.rows('settings').add({'id': 'timezone', 'value': zone});
        final before = DateTime.now();
        await AndroidNotices().sendTestNotification(data, data.rows('courses').single,
            delay: const Duration(seconds: 30));
        final args = calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
        expect(args['timeZoneName'], zone);
        // The plugin sends the wall-clock time and its timezone separately.
        final wallTime = DateTime.parse(args['scheduledDateTime'] as String);
        final at = tz.TZDateTime(
            tz.getLocation(args['timeZoneName'] as String),
            wallTime.year, wallTime.month, wallTime.day,
            wallTime.hour, wallTime.minute, wallTime.second);
        expect(at.difference(before).inSeconds, inInclusiveRange(29, 32));
        expect(args['id'], NotificationService.testNotificationId);
      });
    }

    test('予約補充時もテスト通知の予約を保持する', () async {
      pending = [
        {'id': 1, 'title': '通常通知', 'body': '', 'payload': ''},
        {'id': NotificationService.testNotificationId,
          'title': 'テスト通知', 'body': '', 'payload': ''},
      ];
      await AndroidNotices().rebuild(futureData());
      final cancelled = calls.where((c) => c.method == 'cancel')
          .map((c) => (c.arguments as Map)['id']).toList();
      expect(cancelled, [1]);
      expect(calls.map((c) => c.method), isNot(contains('cancelAllPendingNotifications')));
    });
  } else {
    test('通常ビルドではテスト通知を送信できない', () async {
      final data = futureData();
      await expectLater(AndroidNotices().sendTestNotification(
          data, data.rows('courses').single), throwsStateError);
      expect(calls, isEmpty);
    });
  }
}
