import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unitable/data/database.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  late Directory folder;
  setUp(
      () => folder = Directory.systemTemp.createTempSync('unitable-storage-'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('初回は旧既定ファイルがあってもユーザーが指定するまで開かない', () async {
    final legacy = UnitDatabase.open('${folder.path}/university.unitable');
    legacy.transaction(
        () => legacy.put('courses', {'id': 'old', 'name': '前の講義'}));
    legacy.dispose();
    final bytes = File('${folder.path}/university.unitable').readAsBytesSync();
    final storage = Storage();
    await storage.initialize(applicationDirectory: folder);
    expect(storage.hasDatabase, isFalse);
    expect(File('${folder.path}/university.unitable').readAsBytesSync(), bytes);
  });
  test('設定と指定先を端末側に保存し同じunitableでも別端末のUI設定に影響しない', () async {
    final appA = Directory('${folder.path}/a')..createSync();
    final appB = Directory('${folder.path}/b')..createSync();
    final file = '${folder.path}/student.unitable';
    final a = Storage();
    await a.initialize(applicationDirectory: appA);
    await a.adopt(UnitDatabase.open(file));
    a.database.transaction(() {
      a.database.put('courses', {'id': 'c', 'name': '共有される講義'});
      a.database.put('settings', {'id': 'course_font_size', 'value': '24'});
      a.database
          .put('settings', {'id': 'timetable_column_width', 'value': '96'});
    });
    expect(
        a.database.db
            .select("SELECT name FROM sqlite_master WHERE name='settings'"),
        isEmpty);
    a.database.snapshot('${folder.path}/copy.unitable');
    final copy = UnitDatabase.open('${folder.path}/copy.unitable');
    expect(copy.data.setting('course_font_size', '18'), '18');
    expect(copy.data.rows('courses').single['name'], '共有される講義');
    copy.dispose();
    final preferences = jsonDecode(a.preferences.readAsStringSync()) as Map;
    expect(preferences['path'], file);
    expect(preferences['selected'], true);
    expect(preferences['settings']['course_font_size'], '24');
    a.database.dispose();
    final reopened = Storage();
    await reopened.initialize(applicationDirectory: appA);
    expect(reopened.database.data.setting('course_font_size', '18'), '24');
    reopened.database.dispose();
    final b = Storage();
    await b.initialize(applicationDirectory: appB);
    expect(b.hasDatabase, false);
    await b.adopt(UnitDatabase.open(file));
    expect(b.database.data.setting('course_font_size', '18'), '18');
    expect(b.database.data.rows('courses').single['name'], '共有される講義');
    b.database.dispose();
  });
  test('記憶したファイルが消えても空のunitableを自動作成しない', () async {
    File('${folder.path}/storage-location.json').writeAsStringSync(jsonEncode({
      'selected': true,
      'path': '${folder.path}/missing.unitable',
      'settings': {},
    }));
    final storage = Storage();
    await expectLater(storage.initialize(applicationDirectory: folder),
        throwsA(isA<FileSystemException>()));
    expect(storage.hasDatabase, false);
    expect(File('${folder.path}/missing.unitable').existsSync(), false);
  });
  test('旧設定を退避できないときは旧ファイルの設定と版番号を維持する', () {
    final file = '${folder.path}/v2.unitable';
    final legacy = sqlite3.open(file);
    legacy.execute(schema
        .replaceFirst(', color INTEGER', '')
        .replaceFirst(', exam_day INTEGER NOT NULL DEFAULT 0', ''));
    legacy.execute(
        'CREATE TABLE settings (id TEXT PRIMARY KEY, value TEXT NOT NULL)');
    legacy.execute("INSERT INTO settings VALUES ('course_font_size','23')");
    legacy.execute('PRAGMA application_id=$applicationId');
    legacy.execute('PRAGMA user_version=2');
    legacy.dispose();
    expect(
        () => UnitDatabase.open(file,
            onLegacySettings: (_) => throw const FileSystemException('保存できない')),
        throwsA(isA<FileSystemException>()));
    final check = sqlite3.open(file);
    expect(check.select('PRAGMA user_version').first.values.first, 2);
    expect(check.select('SELECT value FROM settings').single['value'], '23');
    check.dispose();
    final settings = <String, String>{};
    final migrated = UnitDatabase.open(file, onLegacySettings: settings.addAll);
    expect(settings['course_font_size'], '23');
    expect(
        migrated.db
            .select("SELECT name FROM sqlite_master WHERE name='settings'"),
        isEmpty);
    expect(migrated.db.select('PRAGMA user_version').first.values.first, 6);
    migrated.dispose();
  });
}
