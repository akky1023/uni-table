import 'dart:convert';
import 'dart:math';
import '../l10n/strings.dart';

typedef DbRow = Map<String, dynamic>;

String newId() => List.generate(16, (_) => Random.secure().nextInt(256))
    .map((v) => v.toRadixString(16).padLeft(2, '0'))
    .join();
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime shiftDay(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime atMinute(DateTime d, int m) =>
    DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
String clock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
List<String> stringList(dynamic raw) =>
    (jsonDecode(raw as String? ?? '[]') as List).cast<String>();
List<DbRow> ruleList(dynamic raw) =>
    (jsonDecode(raw as String? ?? '[]') as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
List<String> get weekdays => [
  strings.monday,
  strings.tuesday,
  strings.wednesday,
  strings.thursday,
  strings.friday,
  strings.saturday,
  strings.sunday,
];

class SchoolData {
  final Map<String, List<DbRow>> tables;
  SchoolData(this.tables);
  List<DbRow> rows(String table) => tables[table] ?? [];
  DbRow? find(String table, String? id) {
    for (final row in rows(table)) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  String setting(String key, String fallback) {
    for (final row in rows('settings')) {
      if (row['id'] == key) return row['value'] as String;
    }
    return fallback;
  }

  int get leadMinutes => int.parse(setting('lead_minutes', '10'));
  List<DbRow> get slots => [...rows('slots')]
    ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
}

class Session {
  final DbRow meeting, course, slot;
  final DateTime sourceDate, date;
  final DbRow? change;
  final bool cancelled, replacement;
  const Session(
      {required this.meeting,
      required this.course,
      required this.slot,
      required this.sourceDate,
      required this.date,
      this.change,
      this.cancelled = false,
      this.replacement = false});
  String get key => '${meeting['id']}:${dayKey(sourceDate)}';
  String get room =>
      change?['room'] as String? ??
      meeting['room'] as String? ??
      course['room'] as String;
  DateTime get start => atMinute(date, slot['start_minute'] as int);
  DateTime get end => atMinute(date, slot['end_minute'] as int);
  int lead(SchoolData data) =>
      change?['lead_minutes'] as int? ??
      meeting['lead_minutes'] as int? ??
      course['lead_minutes'] as int? ??
      data.leadMinutes;
}

class ScheduleEngine {
  final SchoolData data;
  ScheduleEngine(this.data);
  bool contains(DbRow range, DateTime date) {
    final key = dayKey(date);
    final parts = data
        .rows('event_ranges')
        .where((r) => r['event_id'] == range['id'])
        .toList();
    return (parts.isEmpty ? [range] : parts).any((r) =>
        key.compareTo(r['start_date'] as String) >= 0 &&
        key.compareTo(r['end_date'] as String) <= 0);
  }

  bool isClosed(DateTime date) =>
      dayChange(date)?['cancelled'] == 1 ||
      data
          .rows('events')
          .any((e) => e['kind'] == 'holiday' && contains(e, date));
  bool isHoliday(DateTime date) {
    final config = jsonDecode(data.setting('notification_holidays',
            '{"closures":true,"weekdays":[7],"no_classes":false}'))
        as Map<String, dynamic>;
    return config['closures'] == true && isClosed(date) ||
        (config['weekdays'] as List? ?? []).contains(date.weekday) &&
            (!(config['only_no_classes'] as List? ?? [])
                    .contains(date.weekday) ||
                onDay(date, includeCancelled: false).isEmpty) ||
        config['no_classes'] == true &&
            onDay(date, includeCancelled: false).isEmpty;
  }

  DbRow? dayChange(DateTime date) {
    for (final e in data.rows('day_changes')) {
      if (e['date'] == dayKey(date)) return e;
    }
    return null;
  }

  bool termActive(String id, DateTime date) => data.rows('events').any((e) =>
      e['kind'] == 'teaching' && e['term_id'] == id && contains(e, date));
  Session? baseSession(DbRow meeting, DateTime date,
      {bool ignoreClosure = false}) {
    final course = data.find('courses', meeting['course_id'] as String?);
    final slot = data.find('slots', meeting['slot_id'] as String?);
    if (course == null || slot == null) return null;
    final dc = dayChange(date);
    if (!ignoreClosure &&
        (dc?['cancelled'] == 1 ||
            (isClosed(date) && dc?['source_weekday'] == null))) {
      return null;
    }
    if (meeting['once_date'] != null) {
      if (meeting['once_date'] != dayKey(date)) return null;
      if (meeting['exam_period_id'] != null) {
        final period = data.find('events', meeting['exam_period_id'] as String);
        if (period == null ||
            period['kind'] != 'exam' ||
            !contains(period, date)) {
          return null;
        }
      }
    } else {
      if (meeting['weekday'] != (dc?['source_weekday'] ?? date.weekday)) {
        return null;
      }
      if (meeting['period_id'] != null) {
        final period = data.find('events', meeting['period_id'] as String);
        if (period == null ||
            period['kind'] != 'teaching' ||
            !contains(period, date)) {
          return null;
        }
        if (course['start_date'] != null &&
                dayKey(date).compareTo(course['start_date'] as String) < 0 ||
            course['end_date'] != null &&
                dayKey(date).compareTo(course['end_date'] as String) > 0) {
          return null;
        }
        return Session(
            meeting: meeting,
            course: course,
            slot: slot,
            sourceDate: date,
            date: date);
      }
      if (meeting['term_id'] != null &&
          !termActive(meeting['term_id'] as String, date)) {
        return null;
      }
      final terms = stringList(course['term_ids']);
      if (terms.isNotEmpty && !terms.any((t) => termActive(t, date))) {
        return null;
      }
      if (course['start_date'] != null &&
          dayKey(date).compareTo(course['start_date'] as String) < 0) {
        return null;
      }
      if (course['end_date'] != null &&
          dayKey(date).compareTo(course['end_date'] as String) > 0) {
        return null;
      }
      // Unscoped weekly lectures still require a university teaching period.
      if (terms.isEmpty &&
          meeting['term_id'] == null &&
          course['start_date'] == null &&
          course['end_date'] == null &&
          !data
              .rows('events')
              .any((e) => e['kind'] == 'teaching' && contains(e, date))) {
        return null;
      }
    }
    return Session(
        meeting: meeting,
        course: course,
        slot: slot,
        sourceDate: date,
        date: date);
  }

  DbRow? sessionChange(String meetingId, DateTime sourceDate) {
    for (final e in data.rows('session_changes')) {
      if (e['meeting_id'] == meetingId && e['date'] == dayKey(sourceDate)) {
        return e;
      }
    }
    return null;
  }

  List<Session> onDay(DateTime date, {bool includeCancelled = true}) {
    final result = <Session>[];
    DbRow? movedDay;
    for (final d in data.rows('day_changes')) {
      if (d['cancelled'] == 1 && d['replacement_date'] == dayKey(date)) {
        movedDay = d;
        break;
      }
    }
    final sourceDate =
        movedDay == null ? date : DateTime.parse(movedDay['date'] as String);
    for (final meeting in data.rows('meetings')) {
      if (movedDay != null && dayChange(date)?['cancelled'] == 1) continue;
      final base =
          baseSession(meeting, sourceDate, ignoreClosure: movedDay != null);
      if (base == null) continue;
      final edit = sessionChange(meeting['id'] as String, sourceDate);
      final cancelled =
          edit?['cancelled'] == 1 || edit?['replacement_date'] != null;
      if (cancelled && !includeCancelled) continue;
      result.add(Session(
          meeting: meeting,
          course: base.course,
          slot: base.slot,
          sourceDate: sourceDate,
          date: date,
          change: edit,
          cancelled: cancelled,
          replacement: movedDay != null));
    }
    for (final edit in data.rows('session_changes')) {
      if (edit['replacement_date'] != dayKey(date)) continue;
      final meeting = data.find('meetings', edit['meeting_id'] as String?);
      if (meeting == null) continue;
      final source = DateTime.parse(edit['date'] as String);
      final base = baseSession(meeting, source, ignoreClosure: true);
      if (base == null) continue;
      final slot = data.find('slots', edit['replacement_slot_id'] as String?) ??
          base.slot;
      result.add(Session(
          meeting: meeting,
          course: base.course,
          slot: slot,
          sourceDate: source,
          date: date,
          change: edit,
          replacement: true));
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    final seen = <String>{};
    return result
        .where((s) => seen.add(
            '${s.meeting['legacy_origin_id'] ?? s.meeting['id']}:${dayKey(s.sourceDate)}:${s.slot['id']}'))
        .toList();
  }

  DateTime? taskDeadline(DbRow task) {
    if (task['due_meeting_id'] == null) {
      return DateTime.parse(task['due_at'] as String);
    }
    final source = DateTime.parse(task['due_source_date'] as String);
    final meeting = data.find('meetings', task['due_meeting_id'] as String?);
    if (meeting == null) return null;
    final day = dayChange(source);
    final edit = sessionChange(meeting['id'] as String, source);
    final base = baseSession(meeting, source,
        ignoreClosure: day?['replacement_date'] != null ||
            edit?['replacement_date'] != null);
    if (base == null) return null;
    if (edit?['replacement_date'] != null) {
      final slot =
          data.find('slots', edit?['replacement_slot_id'] as String?) ??
              base.slot;
      return atMinute(DateTime.parse(edit!['replacement_date'] as String),
          slot['start_minute'] as int);
    }
    if (edit?['cancelled'] == 1) return null;
    if (day?['replacement_date'] != null) {
      final destination = DateTime.parse(day!['replacement_date'] as String);
      if (dayChange(destination)?['cancelled'] == 1) return null;
      return atMinute(destination, base.slot['start_minute'] as int);
    }
    return base.start;
  }

  DateTime? reminderTime(DbRow rule, DateTime due) {
    switch (rule['kind']) {
      case 'hours':
        return due.subtract(Duration(hours: rule['amount'] as int));
      case 'days':
        return due.subtract(Duration(days: rule['amount'] as int));
      case 'weeks':
        return due.subtract(Duration(days: 7 * (rule['amount'] as int)));
      case 'week_clock':
        return atMinute(shiftDay(dateOnly(due), -7 * (rule['amount'] as int)),
            rule['minute'] as int);
      case 'day_clock':
        return atMinute(
            shiftDay(
                dateOnly(due
                    .subtract(Duration(hours: 24 * (rule['amount'] as int)))),
                0),
            rule['minute'] as int);
      case 'previous_sunday':
        var d = dateOnly(due);
        while (d.weekday != DateTime.sunday ||
            atMinute(d, rule['minute'] as int).isAfter(due)) {
          d = shiftDay(d, -1);
        }
        return atMinute(d, rule['minute'] as int);
      case 'previous_holiday':
        final config = jsonDecode(data.setting('notification_holidays',
                '{"closures":true,"weekdays":[7],"no_classes":false}'))
            as Map<String, dynamic>;
        if (config['closures'] != true &&
            config['no_classes'] != true &&
            (config['weekdays'] as List? ?? []).isEmpty) {
          return null;
        }
        if (rule['minute'] == null) {
          var d = dateOnly(due);
          var count = rule['amount'] as int? ?? 1;
          if (count <= 0) return null;
          var remainingDays = 36600;
          while (count > 0 && remainingDays-- > 0) {
            d = shiftDay(d, -1);
            if (isHoliday(d)) count--;
          }
          return count > 0 ? null : atMinute(d, due.hour * 60 + due.minute);
        }
        var d = dateOnly(due);
        var remainingDays = 36600;
        while (
            !isHoliday(d) || atMinute(d, rule['minute'] as int).isAfter(due)) {
          if (remainingDays-- <= 0) return null;
          d = shiftDay(d, -1);
        }
        return atMinute(d, rule['minute'] as int);
      case 'absolute':
        return DateTime.parse(rule['at'] as String);
      default:
        return null;
    }
  }
}

class PlannedNotice {
  final String key, title, body;
  final DateTime at;
  final String? courseId;
  PlannedNotice(this.key, this.title, this.body, this.at, {this.courseId});
}

List<PlannedNotice> planNotifications(SchoolData data, DateTime now,
    {int days = 366}) {
  final engine = ScheduleEngine(data);
  final result = <PlannedNotice>[];
  for (var n = 0; n <= days; n++) {
    for (final session
        in engine.onDay(shiftDay(now, n), includeCancelled: false)) {
      final lead = session.lead(data);
      final at = session.start.subtract(Duration(minutes: lead));
      if (lead >= 0 && at.isAfter(now)) {
        result.add(PlannedNotice(
            'class:${session.key}',
            session.course['name'] as String,
            strings.classNoticeBody(
              clock(session.slot['start_minute'] as int),
              session.room.isEmpty ? strings.notRegistered : session.room,
            ),
            at));
      }
      if (session.course['check_tasks'] == 1 && session.end.isAfter(now)) {
        result.add(PlannedNotice('check:${session.key}',
            strings.checkAssignments,
            strings.checkAssignmentsBody(session.course['name']), session.end,
            courseId: session.course['id'] as String));
      }
    }
  }
  for (final task in data.rows('tasks')) {
    if (task['done'] == 1) continue;
    final due = engine.taskDeadline(task);
    if (due == null) continue;
    final rules = ruleList(task['rules'] ??
        data.setting('task_rules',
            '[{"kind":"hours","amount":72},{"kind":"day_clock","amount":1,"minute":420}]'));
    for (var i = 0; i < rules.length; i++) {
      final at = engine.reminderTime(rules[i], due);
      if (at != null && at.isAfter(now) && !at.isAfter(due)) {
        result.add(PlannedNotice(
            'task:${task['id']}:$i',
            task['title'] as String,
            strings.deadlineNoticeBody(
              dayKey(due),
              clock(due.hour * 60 + due.minute),
              task['destination'],
            ),
            at));
      }
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}
