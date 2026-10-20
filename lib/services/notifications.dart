import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import '../domain/schedule.dart';
import '../l10n/strings.dart';

class NotificationService {
  static const testingEnabled = bool.fromEnvironment('UNITABLE_NOTIFICATION_TEST');
  static const testNotificationId = 1000001;
  static const addTaskAction = 'add_task';
  void Function(String courseId)? onAddTask;
  bool get isAndroid => Platform.isAndroid;
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  String status = strings.notificationsOff;
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
      InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        windows: WindowsInitializationSettings(
          appName: strings.appName,
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
          'unitable_schedule',
      strings.notificationChannel,
          channelDescription: strings.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          actions: notice.courseId == null ? null : [
            AndroidNotificationAction(addTaskAction,
                strings.addAssignment,
                showsUserInterface: true),
          ]),
      windows: WindowsNotificationDetails(
          actions: notice.courseId == null ? const [] : [
            WindowsAction(content: strings.addAssignment,
                arguments: taskPayload(notice.courseId!)),
          ]));

  Future<bool> sendTestNotification(SchoolData data, DbRow course,
      {Duration delay = Duration.zero}) async {
    if (!testingEnabled) throw StateError(strings.testApkOnly);
    if (!await requestPermission()) return false;
    final zone = tz.getLocation(data.setting('timezone', 'Asia/Tokyo'));
    final at = tz.TZDateTime.now(zone).add(delay);
    final notice = PlannedNotice('test',
      strings.testNoticeTitle,
      strings.checkAssignmentsBody(course['name']), at,
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
          throw StateError(strings.windowsNotificationsRequireMsix);
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
        status = strings.notificationsOff;
        scheduledThrough = null;
        return;
      }
      await initialize();
      if (data.setting('notifications', '0') != '1') {
        await plugin.cancelAll();
        status = strings.notificationsOff;
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
            if (pending.id != testNotificationId) {
              await plugin.cancel(pending.id);
            }
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
      status = strings.scheduledNotices(
        scheduled,
        lastScheduled == null
            ? ''
            : strings.scheduledThrough(dayKey(lastScheduled)),
        notices.length > 480 ? strings.scheduleRefillHelp : '',
        isAndroid && !exact ? strings.inexactAlarmWarning : '',
      );
    } catch (e) {
      status = strings.notificationSetupFailed(e);
      rethrow;
    }
  }
}
