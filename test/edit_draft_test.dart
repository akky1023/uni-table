import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/domain/schedule.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  late Directory folder;
  late UnitDatabase original;
  setUp(() {
    folder = Directory.systemTemp.createTempSync('unitable-draft-');
    original = UnitDatabase.open('${folder.path}/test.unitable');
    original.transaction(() {
      for (final (id, start, end) in [
        ('oct', '2026-10-01', '2026-10-31'),
        ('dec', '2026-12-01', '2026-12-31')
      ]) {
        original.put('events', {
          'id': id,
          'kind': 'teaching',
          'name': id,
          'start_date': start,
          'end_date': end
        });
      }
      original.put('courses', {'id': 'c', 'name': '講義'});
      original.put('meetings', {
        'id': 'm',
        'course_id': 'c',
        'slot_id': 'slot-1',
        'weekday': 1,
        'period_id': 'oct'
      });
      original.put('tasks', {
        'id': 't',
        'title': '課題',
        'due_at': '2026-10-19T08:50:00',
        'due_meeting_id': 'm',
        'context_meeting_id': 'm'
      });
    });
  });
  tearDown(() {
    original.dispose();
    folder.deleteSync(recursive: true);
  });

  test('編集と削除は保存前のファイルや通知対象を変更せず破棄できる', () {
    final draft = UnitDatabase.draftOf(original);
    draft.transaction(() {
      draft.put('courses', {'id': 'c', 'name': '変更'});
      draft.remove('meetings', 'm');
    });
    final reopened = UnitDatabase.open(original.path);
    expect(reopened.data.rows('courses').single['name'], '講義');
    expect(reopened.data.rows('meetings'), hasLength(1));
    expect(reopened.data.rows('tasks').single['due_meeting_id'], 'm');
    reopened.dispose();
    draft.dispose();
    expect(original.data.rows('meetings'), hasLength(1));
  });

  test('保存時に編集内容と参照を一度に置き換え再度開ける', () {
    final draft = UnitDatabase.draftOf(original);
    draft
        .transaction(() => draft.put('courses', {'id': 'c', 'name': '保存した変更'}));
    original.transaction(() => original.replaceContent(draft.data));
    draft.dispose();
    final reopened = UnitDatabase.open(original.path);
    expect(reopened.data.rows('courses').single['name'], '保存した変更');
    expect(reopened.data.rows('tasks').single['context_meeting_id'], 'm');
    expect(reopened.db.select('PRAGMA foreign_key_check'), isEmpty);
    reopened.dispose();
  });

  test('期間をまとめても11月に講義は発生せず課題と講義の参照を保持する', () {
    original.transaction(() => original.mergePeriods(['dec', 'oct'], '統合'));
    expect(original.data.rows('events'), hasLength(1));
    expect(original.data.rows('event_ranges'), hasLength(2));
    final engine = ScheduleEngine(original.data);
    expect(engine.onDay(DateTime(2026, 10, 19)), hasLength(1));
    expect(engine.onDay(DateTime(2026, 11, 16)), isEmpty);
    expect(engine.onDay(DateTime(2026, 12, 14)), hasLength(1));
    expect(original.data.rows('tasks').single['due_meeting_id'], 'm');
    final reopened = UnitDatabase.open(original.path);
    expect(
        ScheduleEngine(reopened.data).onDay(DateTime(2026, 11, 16)), isEmpty);
    reopened.dispose();
  });

  test('異なる種類の期間の統合は変更せず拒否する', () {
    original.transaction(
        () => original.put('events', {'id': 'dec', 'kind': 'exam'}));
    expect(
        () => original
            .transaction(() => original.mergePeriods(['oct', 'dec'], '')),
        throwsFormatException);
    expect(original.data.rows('events'), hasLength(2));
  });

  test('曜日の休日判定を講義がない日に限定する条件は通知にも適用する', () {
    original.transaction(() => original.put('settings', {
          'id': 'notification_holidays',
          'value':
              '{"closures":false,"weekdays":[1],"only_no_classes":[1],"no_classes":false}'
        }));
    final engine = ScheduleEngine(original.data);
    expect(engine.isHoliday(DateTime(2026, 10, 19)), isFalse);
    expect(engine.isHoliday(DateTime(2026, 11, 16)), isTrue);
    expect(
        engine.reminderTime({'kind': 'previous_holiday', 'amount': 1},
            DateTime(2026, 12, 1, 10)),
        DateTime(2026, 11, 30, 10));
  });
}
