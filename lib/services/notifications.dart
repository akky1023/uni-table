import 'dart:io';
import 'dart:ffi';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import '../domain/schedule.dart';

class NotificationService {
  static const testingEnabled = bool.fromEnvironment('UNITABLE_NOTIFICATION_TEST');
  static const testNotificationId = 1000001;
  static const addTaskAction = 'add_task';
  void Function(String courseId)? onAddTask;
  bool get isAndroid => Platform.isAndroid;
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  String status = '通知はオフです';
  DateTime? scheduledThrough;
  late final bool available = _available();
  bool _available() {
    if (!Platform.isWindows && !Platform.isAndroid) return false;
    try {
      requireWindowsPackage();
      return true;
    } catch (_) {
      return false;
    }
  }

  void validateTimezone(String name) {
    zones.initializeTimeZones();
    tz.getLocation(name);
  }

  Future<void> initialize() async {
    if (initialized) return;
    requireWindowsPackage();
    zones.initializeTimeZones();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        windows: WindowsInitializationSettings(
          appName: 'うに時間割',
          appUserModelId: 'UniTable.Local',
          guid: '5375b44a-1256-4df7-af18-18bd72c7871b',
        ),
      ),
      onDidReceiveNotificationResponse: handleResponse,
    );
    initialized = true;
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse != null) {
      handleResponse(launch!.notificationResponse!);
    }
  }

  static String taskPayload(String courseId) =>
      jsonEncode({'action': addTaskAction, 'courseId': courseId});

  void handleResponse(NotificationResponse response) {
    // Windows returns the button arguments in both payload and actionId.
    if (response.actionId != addTaskAction &&
        response.actionId != response.payload) {
      return;
    }
    try {
      final payload = jsonDecode(response.payload ?? '');
      if (payload is Map &&
          payload['action'] == addTaskAction &&
          payload['courseId'] is String &&
          (payload['courseId'] as String).isNotEmpty) {
        onAddTask?.call(payload['courseId'] as String);
      }
    } on FormatException {
      // Old notifications carry a plain key, without an action destination.
    }
  }

  Future<void> requestExactAlarms() async {
    await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (isAndroid &&
        await android?.canScheduleExactNotifications() != true) {
      await android?.requestExactAlarmsPermission();
    }
  }

  Future<void> openBatterySettings() async {
    if (isAndroid) {
      await const MethodChannel('unitable/notifications')
          .invokeMethod<void>('openAppSettings');
    }
  }

  NotificationDetails detailsFor(PlannedNotice notice) => NotificationDetails(
      android: AndroidNotificationDetails(
          'unitable_schedule', '講義・課題',
          channelDescription: '講義の教室と課題の期限',
          importance: Importance.high,
          priority: Priority.high,
          actions: notice.courseId == null ? null : const [
            AndroidNotificationAction(addTaskAction, '課題を追加',
                showsUserInterface: true),
          ]),
      windows: WindowsNotificationDetails(
          actions: notice.courseId == null ? const [] : [
            WindowsAction(content: '課題を追加',
                arguments: taskPayload(notice.courseId!)),
          ]));

  Future<bool> sendTestNotification(SchoolData data, DbRow course,
      {Duration delay = Duration.zero}) async {
    if (!testingEnabled) throw StateError('通知テストはテストAPKで利用できます。');
    if (!await requestPermission()) return false;
    final zone = tz.getLocation(data.setting('timezone', 'Asia/Tokyo'));
    final at = tz.TZDateTime.now(zone).add(delay);
    final notice = PlannedNotice('test', '課題を確認（通知テスト）',
        '${course['name']}の課題はありましたか？', at,
        courseId: course['id'] as String);
    final details = detailsFor(notice);
    final payload = taskPayload(notice.courseId!);
    await plugin.cancel(testNotificationId);
    if (delay == Duration.zero) {
      await plugin.show(testNotificationId, notice.title, notice.body,
          details, payload: payload);
    } else {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var exact = isAndroid &&
          await android?.canScheduleExactNotifications() == true;
      Future<void> schedule() => plugin.zonedSchedule(testNotificationId,
          notice.title, notice.body, at, details,
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload);
      try {
        await schedule();
      } on PlatformException catch (e) {
        if (!exact || e.code != 'exact_alarms_not_permitted') rethrow;
        exact = false;
        await schedule();
      }
    }
    return true;
  }

  void requireWindowsPackage() {
    if (Platform.isWindows) {
      final length = calloc<Uint32>();
      try {
        final getPackage = DynamicLibrary.open('kernel32.dll').lookupFunction<
            Int32 Function(Pointer<Uint32>, Pointer<Uint16>),
            int Function(
                Pointer<Uint32>, Pointer<Uint16>)>('GetCurrentPackageFullName');
        if (getPackage(length, nullptr) != 122) {
          throw StateError('Windowsの通知はMSIX版で有効にできます。MSIXとしてビルド・インストールしてください。');
        }
      } finally {
        calloc.free(length);
      }
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      if (granted) await requestExactAlarms();
      return granted;
    }
    return true;
  }

  Future<void> rebuild(SchoolData data) async {
    try {
      if (!initialized && data.setting('notifications', '0') != '1') {
        status = '通知はオフです';
        scheduledThrough = null;
        return;
      }
      await initialize();
      if (data.setting('notifications', '0') != '1') {
        await plugin.cancelAll();
        status = '通知はオフです';
        scheduledThrough = null;
        return;
      }
      final zone = tz.getLocation(data.setting('timezone', 'Asia/Tokyo'));
      final now = tz.TZDateTime.now(zone);
      final notices = planNotifications(
        data,
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
          now.second,
        ),
      );
      final selected = notices.take(480).toList();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var exact = isAndroid
          ? await android?.canScheduleExactNotifications() ?? false
          : false;
      // Keep delivered notifications (and their action buttons) on Android.
      if (isAndroid) {
        if (testingEnabled) {
          // App resume refills the timetable without cancelling a test alarm.
          for (final pending in await plugin.pendingNotificationRequests()) {
            if (pending.id != testNotificationId) await plugin.cancel(pending.id);
          }
        } else {
          await plugin.cancelAllPendingNotifications();
        }
      } else {
        await plugin.cancelAll();
      }
      var scheduled = 0;
      DateTime? lastScheduled;
      for (var i = 0; i < selected.length; i++) {
        final notice = selected[i];
        final at = tz.TZDateTime(
          zone,
          notice.at.year,
          notice.at.month,
          notice.at.day,
          notice.at.hour,
          notice.at.minute,
        );
        if (!at.isAfter(tz.TZDateTime.now(zone))) continue;
        final payload = notice.courseId == null
            ? notice.key
            : taskPayload(notice.courseId!);
        Future<void> schedule() => plugin.zonedSchedule(
              i + 1,
              notice.title,
              notice.body,
              at,
              detailsFor(notice),
              androidScheduleMode: exact
                  ? AndroidScheduleMode.exactAllowWhileIdle
                  : AndroidScheduleMode.inexactAllowWhileIdle,
              payload: payload,
            );
        try {
          await schedule();
        } on PlatformException catch (e) {
          if (!exact || e.code != 'exact_alarms_not_permitted') rethrow;
          exact = false;
          await schedule();
        }
        scheduled++;
        lastScheduled = notice.at;
      }
      scheduledThrough = lastScheduled;
      status =
          '$scheduled件を予約済み${lastScheduled == null ? '' : '・${dayKey(lastScheduled)}まで'}${notices.length > 480 ? '（起動・画面復帰時に予約を補充）' : ''}${isAndroid && !exact ? '・正確な時刻の通知が未許可のため遅れる場合があります' : ''}';
    } catch (e) {
      status = '通知の設定に失敗しました: $e';
      rethrow;
    }
  }
}
