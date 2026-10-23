import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/domain/schedule.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  test('4月13日の2限だけを休講にし14日の3限へ移動する', () {
    final data = sampleData();
    data.rows('slots').add({
      'id': 's3',
      'position': 3,
      'start_minute': 780,
      'end_minute': 870,
    });
    data.rows('meetings').first['slot_id'] = 's2';
    data.rows('meetings').add({
      ...data.rows('meetings').first,
      'id': 'm2',
      'slot_id': 's1',
    });
    data.rows('session_changes').add({
      'meeting_id': 'm1',
      'date': '2026-04-13',
      'cancelled': 1,
      'replacement_date': '2026-04-14',
      'replacement_slot_id': 's3',
      'notes': '教科書を持参',
    });
    final engine = ScheduleEngine(data);
    final original = engine.onDay(DateTime(2026, 4, 13));
    expect(original.where((s) => s.cancelled).single.slot['id'], 's2');
    expect(
      engine
          .onDay(DateTime(2026, 4, 13), includeCancelled: false)
          .single
          .meeting['id'],
      'm2',
    );
    final moved = engine.onDay(DateTime(2026, 4, 14)).single;
    expect(moved.slot['id'], 's3');
    expect(moved.notes, '教科書を持参');
    expect(moved.makeup, isTrue);
    expect(moved.key, 'm1:2026-04-13');
    expect(
      engine
          .onDay(DateTime(2026, 4, 20))
          .every((s) => !s.cancelled && s.notes.isEmpty),
      isTrue,
    );
    expect(
      engine.taskDeadline({
        'due_meeting_id': 'm1',
        'due_source_date': '2026-04-13',
      }),
      DateTime(2026, 4, 14, 13),
    );
  });
  test('同じ日の別コマへの移動も元と移動先を区別する', () {
    final data = sampleData();
    data.rows('session_changes').add({
      'meeting_id': 'm1',
      'date': '2026-04-13',
      'cancelled': 1,
      'replacement_date': '2026-04-13',
      'replacement_slot_id': 's2',
    });
    final engine = ScheduleEngine(data);
    expect(engine.onDay(DateTime(2026, 4, 13)), hasLength(2));
    expect(
      engine
          .onDay(DateTime(2026, 4, 13), includeCancelled: false)
          .single
          .slot['id'],
      's2',
    );
  });
  test('休講理由を各回のメモで記録し通知は休講設定に従う', () {
    final data = sampleData();
    data.rows('session_changes').add({
      'meeting_id': 'm1',
      'date': '2026-04-13',
      'notes': 'オンデマンドで動画を見る',
    });
    final engine = ScheduleEngine(data);
    expect(engine.onDay(DateTime(2026, 4, 13)).single.notes, 'オンデマンドで動画を見る');
    expect(engine.onDay(DateTime(2026, 4, 20)).single.notes, isEmpty);
    expect(planNotifications(data, DateTime(2026, 4, 13), days: 0), hasLength(2));
    data.rows('session_changes').single['cancelled'] = 1;
    final notices = planNotifications(data, DateTime(2026, 4, 13), days: 0);
    expect(notices, isEmpty);
    expect(
      planNotifications(data, DateTime(2026, 4, 20), days: 0),
      hasLength(2),
    );
    expect(data.rows('courses').single['notes'], '# メモ');
  });
  test('単独補講は期間外・休業日にも登録でき日単位の振替にも埋もれない', () {
    final data = sampleData();
    data.rows('meetings').add({
      'id': 'makeup',
      'course_id': 'c1',
      'slot_id': 's2',
      'once_date': '2026-08-15',
      'is_makeup': 1,
    });
    data.rows('events').add({
      'kind': 'holiday',
      'start_date': '2026-08-15',
      'end_date': '2026-08-15',
    });
    final engine = ScheduleEngine(data);
    expect(engine.onDay(DateTime(2026, 8, 15)).single.makeup, isTrue);
    expect(engine.onDay(DateTime(2026, 8, 16)), isEmpty);
    data.rows('day_changes').add({
      'date': '2026-04-13',
      'cancelled': 1,
      'replacement_date': '2026-08-15',
    });
    expect(engine.onDay(DateTime(2026, 8, 15)), hasLength(2));
  });
  test('バージョン6からメモを移行し再オープンしても保持する', () {
    final folder = Directory.systemTemp.createTempSync('unitable-session-');
    final path = '${folder.path}/test.unitable';
    addTearDown(() => folder.deleteSync(recursive: true));
    final initial = UnitDatabase.open(path);
    initial.transaction(() => initial.replaceContent(sampleData()));
    initial.dispose();
    final raw = sqlite3.open(path);
    raw.execute('ALTER TABLE meetings DROP COLUMN is_makeup');
    raw.execute('ALTER TABLE session_changes DROP COLUMN notes');
    raw.execute('PRAGMA user_version=6');
    raw.dispose();
    final db = UnitDatabase.open(path);
    expect(db.db.userVersion, 7);
    expect(db.data.rows('courses').single['notes'], '# メモ');
    db.transaction(
      () => db.put('session_changes', {
        'id': 'edit',
        'meeting_id': 'm1',
        'date': '2026-04-13',
        'notes': '今回だけ',
        }),
    );
    db.dispose();
    final reopened = UnitDatabase.open(path);
    final session = ScheduleEngine(
      reopened.data,
    ).onDay(DateTime(2026, 4, 13)).single;
    expect(session.notes, '今回だけ');
    reopened.dispose();
  });
}
