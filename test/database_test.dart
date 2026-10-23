import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/domain/schedule.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('unitable-test-'));
  tearDown(() => folder.deleteSync(recursive: true));
  test('.unitableの実体はSQLite・自由記述は長文を保存できる', () {
    final path = '${folder.path}/test.unitable',
        db = UnitDatabase.open('${folder.path}/test.unitable');
    final long = List.filled(100000, '講').join();
    db.transaction(
        () => db.put('courses', {'id': 'c', 'name': long, 'notes': long}));
    db.dispose();
    expect(File(path).readAsBytesSync().take(16), [
      83,
      81,
      76,
      105,
      116,
      101,
      32,
      102,
      111,
      114,
      109,
      97,
      116,
      32,
      51,
      0
    ]);
    final reopened = UnitDatabase.open(path);
    expect(reopened.data.rows('courses').single['notes'], long);
    reopened.dispose();
    expect(folder.listSync().whereType<File>().length, 1);
  });
  test('外部キーの不整合はロールバックし、正常データを保つ', () {
    final db = UnitDatabase.open('${folder.path}/test.unitable');
    expect(
        () => db.transaction(() {
              db.put('courses', {'id': 'c', 'name': '失敗時に残らない'});
              db.put('meetings', {
                'id': 'm',
                'course_id': 'missing',
                'slot_id': 'slot-1',
                'weekday': 1
              });
            }),
        throwsA(isA<SqliteException>()));
    expect(db.data.rows('courses'), isEmpty);
    expect(db.db.select('SELECT * FROM courses'), isEmpty);
    db.dispose();
  });
  test('期間とコマの一部だけを更新しても既存の必須項目を保持する', () {
    final db = UnitDatabase.open('${folder.path}/test.unitable');
    db.transaction(() {
      db.put('events', {
        'id': 'period',
        'kind': 'teaching',
        'name': '授業',
        'start_date': '2026-04-01',
        'end_date': '2026-07-31'
      });
      db.put('terms', {'id': 'term', 'name': '前期', 'color': 0xff419c79});
      db.put('events', {'id': 'period', 'term_id': 'term'});
      db.put('slots', {'id': 'slot-1', 'start_minute': 540});
    });
    expect(db.data.rows('events').single['kind'], 'teaching');
    expect(db.data.rows('events').single['term_id'], 'term');
    expect(db.data.slots.first['position'], 1);
    expect(db.data.slots.first['start_minute'], 540);
    expect(
        () => db.transaction(
            () => db.put('slots', {'id': 'slot-1', 'start_minute': 1000})),
        throwsA(isA<SqliteException>()));
    expect(db.data.slots.first['start_minute'], 540);
    db.dispose();
  });
  test('スナップショット単体で再オープンできる・既存ファイルは上書きしない', () {
    final db = UnitDatabase.open('${folder.path}/test.unitable');
    db.transaction(() => db.put('courses', {'id': 'c', 'name': '情報科学'}));
    final target = '${folder.path}/copy.unitable';
    db.snapshot(target);
    expect(() => db.snapshot(target), throwsA(isA<FileSystemException>()));
    final copy = UnitDatabase.open(target);
    expect(copy.data.rows('courses').single['name'], '情報科学');
    copy.dispose();
    db.dispose();
  });
  test('拡張子だけ変えた別アプリのSQLiteは変更しない', () {
    final path = '${folder.path}/other.unitable';
    final other = sqlite3.open(path);
    other.execute('CREATE TABLE secret (value TEXT)');
    other.dispose();
    final before = File(path).readAsBytesSync();
    expect(() => UnitDatabase.open(path), throwsA(isA<FormatException>()));
    expect(File(path).readAsBytesSync(), before);
  });
  test('v4のまとまった学期を期間へ分け振替・期限を保持し重なる講義を二重にしない', () {
    final path = '${folder.path}/v4.unitable';
    final old = sqlite3.open(path);
    old.execute(schema);
    old.execute(
        'ALTER TABLE meetings ADD COLUMN exam_period_id TEXT REFERENCES events(id) ON DELETE CASCADE');
    old.execute('PRAGMA application_id = $applicationId');
    old.execute('PRAGMA user_version = 4');
    old.execute("INSERT INTO terms VALUES ('t','まとめた学期',4282498169)");
    old.execute(
        "INSERT INTO events (id,kind,term_id,start_date,end_date) VALUES ('a','teaching','t','2026-04-01','2026-07-31'),('b','teaching','t','2026-06-01','2026-12-31')");
    old.execute("INSERT INTO slots VALUES ('s',1,530,620)");
    old.execute(
        "INSERT INTO courses (id,name,term_ids) VALUES ('c','既存授業','[\"t\"]')");
    old.execute(
        "INSERT INTO meetings (id,course_id,slot_id,weekday,term_id) VALUES ('m','c','s',1,'t')");
    old.execute(
        "INSERT INTO session_changes (id,meeting_id,date,replacement_date,room) VALUES ('change','m','2026-09-07','2026-09-08','B202')");
    old.execute(
        "INSERT INTO tasks (id,title,due_at,due_meeting_id,due_source_date) VALUES ('task','課題','2026-09-07T08:50:00','m','2026-09-07')");
    old.dispose();
    final db = UnitDatabase.open(path);
    expect(db.data.rows('meetings').length, 2);
    expect(db.data.rows('meetings').map((m) => m['period_id']), ['a', 'b']);
    expect(db.data.rows('tasks').single['due_meeting_id'], isNot('m'));
    final schedule = ScheduleEngine(db.data);
    expect(schedule.onDay(DateTime(2026, 6, 15)).length, 1);
    expect(schedule.onDay(DateTime(2026, 9, 8)).single.room, 'B202');
    expect(schedule.taskDeadline(db.data.rows('tasks').single),
        DateTime(2026, 9, 8, 8, 50));
    db.dispose();
  });
  test('v3の未所属講義期間を学期に移行し既存学期と授業を維持する', () {
    final path = '${folder.path}/v3.unitable';
    final old = sqlite3.open(path);
    old.execute(schema);
    old.execute('PRAGMA application_id = $applicationId');
    old.execute('PRAGMA user_version = 3');
    old.execute("INSERT INTO terms VALUES ('existing','1学期',4282498169)");
    old.execute(
        "INSERT INTO events (id,kind,term_id,start_date,end_date) VALUES ('attached','teaching','existing','2026-04-01','2026-07-31'),('unattached','teaching',NULL,'2026-09-01','2027-01-31')");
    old.execute("INSERT INTO slots VALUES ('s',1,530,620)");
    old.execute("INSERT INTO courses (id,name) VALUES ('c','既存授業')");
    old.execute(
        "INSERT INTO meetings (id,course_id,slot_id,weekday,term_id) VALUES ('m','c','s',1,'existing')");
    old.dispose();
    final db = UnitDatabase.open(path);
    expect(db.data.rows('terms').length, 2);
    expect(db.data.find('terms', 'semester-unattached')!['name'], '2学期');
    expect(db.data.find('events', 'unattached')!['term_id'],
        'semester-unattached');
    expect(db.data.rows('meetings').single['term_id'], 'existing');
    db.dispose();
    final reopened = UnitDatabase.open(path);
    expect(reopened.data.rows('terms').length, 2);
    reopened.dispose();
  });
  test('v1の祝日を日ごとの変更へ移行し、元の日変更と通常の期間を保持する', () {
    final path = '${folder.path}/legacy.unitable';
    final old = sqlite3.open(path);
    old.execute(schema.replaceFirst(
        ', holiday_name TEXT, is_national INTEGER NOT NULL DEFAULT 0', ''));
    old.execute('PRAGMA application_id = $applicationId');
    old.execute('PRAGMA user_version = 1');
    old.execute(
        "INSERT INTO events (id,kind,name,start_date,end_date) VALUES ('jp-holiday-2026-04-29','holiday','昭和の日','2026-04-29','2026-04-29'),('break','holiday','春休み','2026-03-01','2026-03-31')");
    old.execute(
        "INSERT INTO day_changes (id,date,cancelled,source_weekday,replacement_date) VALUES ('manual','2026-04-29',0,2,'2026-05-01')");
    old.dispose();
    final db = UnitDatabase.open(path);
    final change = db.data.rows('day_changes').single;
    expect(change['id'], 'manual');
    expect(change['replacement_date'], '2026-05-01');
    expect(change['source_weekday'], 2);
    expect(change['cancelled'], 1);
    expect(change['holiday_name'], '昭和の日');
    expect(change['is_national'], 1);
    expect(db.data.rows('events').single['id'], 'break');
    expect(db.db.select('PRAGMA user_version').single.values.single, 7);
    db.dispose();
    final reopened = UnitDatabase.open(path);
    expect(reopened.data.rows('day_changes').length, 1);
    reopened.dispose();
  });
}
