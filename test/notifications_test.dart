import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
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
  NotificationResponse? launchResponse;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    exact = false;
    revokeOnSchedule = false;
    launchResponse = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
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
      expect(calls.map((c) => c.method), contains('cancelAllPendingNotifications'));
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
}
