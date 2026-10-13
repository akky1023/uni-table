import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/domain/schedule.dart';
import 'fixtures.dart';

void main() {
  test('通知の休日は休業日・選択曜日・全休を独立して選べる', () {
    final data = sampleData();
    final setting = {
      'id': 'notification_holidays',
      'value': '{"closures":false,"weekdays":[5],"no_classes":false}'
    };
    data.rows('settings').add(setting);
    data
        .rows('day_changes')
        .add({'date': '2026-04-08', 'cancelled': 1, 'is_national': 1});
    final engine = ScheduleEngine(data);
    expect(engine.isHoliday(DateTime(2026, 4, 10)), isTrue);
    expect(engine.isHoliday(DateTime(2026, 4, 12)), isFalse);
    expect(engine.isHoliday(DateTime(2026, 4, 8)), isFalse);
    setting['value'] = '{"closures":true,"weekdays":[],"no_classes":false}';
    expect(engine.isHoliday(DateTime(2026, 4, 8)), isTrue);
    expect(engine.isHoliday(DateTime(2026, 4, 12)), isFalse);
    setting['value'] = '{"closures":false,"weekdays":[],"no_classes":true}';
    expect(engine.isHoliday(DateTime(2026, 4, 6)), isFalse);
    expect(engine.isHoliday(DateTime(2026, 4, 7)), isTrue);
    setting['value'] = '{"closures":false,"weekdays":[],"no_classes":false}';
    expect(
        engine.reminderTime({'kind': 'previous_holiday', 'amount': 1},
            DateTime(2026, 4, 13, 12)),
        isNull);
  });
  test('日前・週間前の任意時刻と複数回前の休日を期限から計算する', () {
    final data = sampleData();
    data.rows('events').add({
      'kind': 'holiday',
      'start_date': '2026-10-07',
      'end_date': '2026-10-07'
    });
    final engine = ScheduleEngine(data);
    final due = DateTime(2026, 10, 12, 18, 30);
    expect(engine.reminderTime({'kind': 'days', 'amount': 3}, due),
        DateTime(2026, 10, 9, 18, 30));
    expect(engine.reminderTime({'kind': 'weeks', 'amount': 2}, due),
        DateTime(2026, 9, 28, 18, 30));
    expect(
        engine.reminderTime(
            {'kind': 'day_clock', 'amount': 1, 'minute': 420}, due),
        DateTime(2026, 10, 11, 7));
    expect(
        engine.reminderTime(
            {'kind': 'week_clock', 'amount': 1, 'minute': 420}, due),
        DateTime(2026, 10, 5, 7));
    expect(engine.reminderTime({'kind': 'previous_holiday', 'amount': 2}, due),
        DateTime(2026, 10, 7, 18, 30));
    expect(engine.reminderTime({'kind': 'previous_holiday', 'amount': 3}, due),
        DateTime(2026, 10, 4, 18, 30));
  });
  test('全学の休講日の代替は期間外でも元の時間割と課題期限を移す', () {
    final data = sampleData();
    data.rows('day_changes').addAll([
      {'date': '2026-04-06', 'cancelled': 1, 'replacement_date': '2026-08-15'},
      {'date': '2026-08-15', 'cancelled': 0, 'source_weekday': 1},
    ]);
    final engine = ScheduleEngine(data);
    expect(engine.onDay(DateTime(2026, 4, 6)), isEmpty);
    final moved = engine.onDay(DateTime(2026, 8, 15)).single;
    expect(dayKey(moved.sourceDate), '2026-04-06');
    expect(moved.replacement, isTrue);
    expect(
        engine.taskDeadline({
          'due_at': '2026-04-06T08:50:00',
          'due_meeting_id': 'm1',
          'due_source_date': '2026-04-06'
        }),
        DateTime(2026, 8, 15, 8, 50));
  });
  test('複数の講義期間・講義自身の期間・学期を適用する', () {
    final data = sampleData(), engine = ScheduleEngine(sampleData());
    expect(engine.onDay(DateTime(2026, 4, 6)).single.room, 'A-201');
    expect(engine.onDay(DateTime(2026, 8, 3)), isEmpty);
    data.rows('events').add({
      'kind': 'teaching',
      'term_id': 't1',
      'start_date': '2026-09-01',
      'end_date': '2026-12-31'
    });
    expect(ScheduleEngine(data).onDay(DateTime(2026, 9, 7)), hasLength(1));
    data.rows('courses').first['start_date'] = '2026-05-01';
    expect(ScheduleEngine(data).onDay(DateTime(2026, 4, 6)), isEmpty);
  });
  test('全学休業日と全学代替曜日、単発講義', () {
    final data = sampleData(), date = DateTime(2026, 4, 7);
    data.rows('events').add({
      'kind': 'holiday',
      'start_date': '2026-04-07',
      'end_date': '2026-04-07'
    });
    expect(ScheduleEngine(data).onDay(date), isEmpty);
    data
        .rows('day_changes')
        .add({'date': '2026-04-07', 'source_weekday': 1, 'cancelled': 0});
    expect(ScheduleEngine(data).onDay(date), hasLength(1));
    data.rows('meetings').add({
      'id': 'single',
      'course_id': 'c1',
      'slot_id': 's2',
      'weekday': null,
      'term_id': null,
      'once_date': '2026-08-15'
    });
    expect(ScheduleEngine(data).onDay(DateTime(2026, 8, 15)), hasLength(1));
  });
  test('休講・振替先のコマ・教室・期限の追従', () {
    final data = sampleData();
    data.rows('session_changes').add({
      'id': 'change',
      'meeting_id': 'm1',
      'date': '2026-04-06',
      'cancelled': 1,
      'replacement_date': '2026-08-15',
      'replacement_slot_id': 's2',
      'room': 'B-302',
      'lead_minutes': 25
    });
    final engine = ScheduleEngine(data);
    expect(engine.onDay(DateTime(2026, 4, 6)).single.cancelled, isTrue);
    expect(
        engine.onDay(DateTime(2026, 4, 6), includeCancelled: false), isEmpty);
    final moved = engine.onDay(DateTime(2026, 8, 15)).single;
    expect(moved.room, 'B-302');
    expect(moved.lead(data), 25);
    expect(moved.start, DateTime(2026, 8, 15, 10, 30));
    final task = {
      'due_at': '2026-04-06T08:50:00',
      'due_meeting_id': 'm1',
      'due_source_date': '2026-04-06'
    };
    expect(engine.taskDeadline(task), moved.start);
    data.rows('session_changes').first['replacement_date'] = null;
    expect(engine.taskDeadline(task), isNull);
  });
  test('通知の継承: 全体→講義→講義コマ→日ごとの変更', () {
    final data = sampleData();
    var session = ScheduleEngine(data).onDay(DateTime(2026, 4, 6)).single;
    expect(session.lead(data), 10);
    data.rows('courses').first['lead_minutes'] = 20;
    expect(session.lead(data), 20);
    data.rows('meetings').first['lead_minutes'] = 30;
    expect(session.lead(data), 30);
    data
        .rows('session_changes')
        .add({'meeting_id': 'm1', 'date': '2026-04-06', 'lead_minutes': -1});
    session = ScheduleEngine(data).onDay(DateTime(2026, 4, 6)).single;
    expect(session.lead(data), -1);
    final planned = planNotifications(data, DateTime(2026, 4, 6, 7), days: 0);
    expect(planned.where((n) => n.key.startsWith('class:')), isEmpty);
    expect(planned.where((n) => n.key.startsWith('check:')), hasLength(1));
  });
  test('相対時間・日付の時刻・直前の日曜・休日・絶対日時', () {
    final data = sampleData(),
        due = DateTime(2026, 4, 8, 12),
        engine = ScheduleEngine(sampleData());
    expect(engine.reminderTime({'kind': 'hours', 'amount': 72}, due),
        DateTime(2026, 4, 5, 12));
    expect(
        engine.reminderTime(
            {'kind': 'day_clock', 'amount': 1, 'minute': 420}, due),
        DateTime(2026, 4, 7, 7));
    expect(engine.reminderTime({'kind': 'previous_sunday', 'minute': 420}, due),
        DateTime(2026, 4, 5, 7));
    expect(
        engine.reminderTime({'kind': 'previous_sunday', 'minute': 420},
            DateTime(2026, 4, 5, 12)),
        DateTime(2026, 4, 5, 7));
    expect(
        engine.reminderTime({'kind': 'previous_sunday', 'minute': 420},
            DateTime(2026, 4, 5, 6)),
        DateTime(2026, 3, 29, 7));
    data.rows('events').add({
      'kind': 'holiday',
      'start_date': '2026-04-06',
      'end_date': '2026-04-06'
    });
    expect(
        ScheduleEngine(data)
            .reminderTime({'kind': 'previous_holiday', 'minute': 420}, due),
        DateTime(2026, 4, 6, 7));
    expect(
        engine.reminderTime(
            {'kind': 'absolute', 'at': '2026-04-01T07:00:00'}, due),
        DateTime(2026, 4, 1, 7));
  });
  test('完了課題と期限後の通知は予約しない', () {
    final data = sampleData();
    data.rows('tasks').addAll([
      {
        'id': 'done',
        'title': '済',
        'done': 1,
        'due_at': '2026-04-08T12:00:00',
        'destination': 'LMS',
        'rules': '[{"kind":"hours","amount":24}]'
      },
      {
        'id': 'future',
        'title': '課題',
        'done': 0,
        'due_at': '2026-04-08T12:00:00',
        'destination': 'LMS',
        'rules':
            '[{"kind":"hours","amount":24},{"kind":"absolute","at":"2026-04-09T07:00:00"}]'
      },
    ]);
    final planned = planNotifications(data, DateTime(2026, 4, 6, 12), days: 0);
    expect(planned.where((n) => n.key.startsWith('task:')).map((n) => n.key),
        ['task:future:0']);
    data.rows('tasks').last['done'] = 1;
    expect(
        planNotifications(data, DateTime(2026, 4, 6, 12), days: 0)
            .where((n) => n.key.startsWith('task:')),
        isEmpty);
    data.rows('tasks').last['done'] = 0;
    expect(
        planNotifications(data, DateTime(2026, 4, 6, 12), days: 0)
            .where((n) => n.key.startsWith('task:'))
            .map((n) => n.key),
        ['task:future:0']);
  });
}
