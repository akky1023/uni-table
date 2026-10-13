import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import '../domain/schedule.dart';

class NotificationService {
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
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      windows: WindowsInitializationSettings(
          appName: 'うに時間割',
          appUserModelId: 'UniTable.Local',
          guid: '5375b44a-1256-4df7-af18-18bd72c7871b'),
    ));
    initialized = true;
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
    if (Platform.isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
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
      await plugin.cancelAll();
      if (data.setting('notifications', '0') != '1') {
        status = '通知はオフです';
        scheduledThrough = null;
        return;
      }
      final zone = tz.getLocation(data.setting('timezone', 'Asia/Tokyo'));
      final now = tz.TZDateTime.now(zone);
      final notices = planNotifications(
          data,
          DateTime(
              now.year, now.month, now.day, now.hour, now.minute, now.second));
      final selected = notices.take(480).toList();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = Platform.isAndroid
          ? await android?.canScheduleExactNotifications() ?? false
          : false;
      for (var i = 0; i < selected.length; i++) {
        final notice = selected[i];
        final at = tz.TZDateTime(zone, notice.at.year, notice.at.month,
            notice.at.day, notice.at.hour, notice.at.minute);
        if (!at.isAfter(tz.TZDateTime.now(zone))) continue;
        await plugin.zonedSchedule(
            i + 1,
            notice.title,
            notice.body,
            at,
            const NotificationDetails(
                android: AndroidNotificationDetails(
                    'unitable_schedule', '講義・課題',
                    channelDescription: '講義の教室と課題の期限',
                    importance: Importance.high),
                windows: WindowsNotificationDetails()),
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            payload: notice.key);
      }
      scheduledThrough = selected.isEmpty ? null : selected.last.at;
      status =
          '${selected.length}件を予約済み${selected.isEmpty ? '' : '・${dayKey(selected.last.at)}まで'}${notices.length > 480 ? '（起動・画面復帰時に予約を補充）' : ''}${Platform.isAndroid && !exact ? '・時刻はOSにより前後します' : ''}';
    } catch (e) {
      status = '通知の設定に失敗しました: $e';
      rethrow;
    }
  }
}
