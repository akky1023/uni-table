import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unitable/data/database.dart';
import 'package:unitable/data/database_security.dart';
import 'fixtures.dart';

void main() {
  useTestSqlite();
  late Directory folder;
  late String path;
  setUp(() {
    folder = Directory.systemTemp.createTempSync('unitable-security-');
    path = '${folder.path}/input.unitable';
  });
  tearDown(() => folder.deleteSync(recursive: true));

  void makeDatabase() => UnitDatabase.open(path).dispose();
  void rejectUnchanged() {
    final bytes = File(path).readAsBytesSync();
    expect(() => UnitDatabase.open(path), throwsA(isA<FormatException>()));
    expect(File(path).readAsBytesSync(), bytes);
  }

  test('埋め込まれたトリガーを実行せず元ファイルも変更しない', () {
    makeDatabase();
    final raw = sqlite3.open(path);
    raw.execute('''CREATE TRIGGER injected AFTER INSERT ON destinations
      BEGIN INSERT INTO terms VALUES ('injected','injected',0); END''');
    raw.dispose();
    rejectUnchanged();
  });

  test('テーブルの代わりに作られたビューを問い合わせ前に拒否する', () {
    makeDatabase();
    final raw = sqlite3.open(path);
    raw.execute('DROP TABLE destinations');
    raw.execute('''CREATE VIEW destinations AS
      WITH RECURSIVE n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n)
      SELECT x AS id, x AS name FROM n''');
    raw.dispose();
    rejectUnchanged();
  });

  test('テーブル制約と式索引へのSQL埋め込みを拒否する', () {
    for (final injection in [
      'CREATE INDEX injected ON destinations (length(name))',
      'DROP TABLE destinations; CREATE TABLE destinations '
          '(id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE '
          'CHECK(length(zeroblob(1000000000))>0))',
      'DROP TABLE destinations; CREATE TABLE destinations '
          '(id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, '
          'extra TEXT GENERATED ALWAYS AS (hex(zeroblob(1000000))))',
    ]) {
      if (File(path).existsSync()) File(path).deleteSync();
      makeDatabase();
      final raw = sqlite3.open(path);
      raw.execute(injection);
      raw.dispose();
      rejectUnchanged();
    }
  });

  test('引用された識別子を使った正常な旧形式も再オープンできる', () {
    final raw = sqlite3.open(path);
    raw.execute(schema.replaceFirst('CREATE TABLE courses', 'CREATE TABLE "courses"'));
    raw.execute('PRAGMA application_id=$applicationId');
    raw.execute('PRAGMA user_version=3');
    raw.dispose();
    final db = UnitDatabase.open(path);
    expect(db.db.userVersion, 7);
    db.dispose();
    UnitDatabase.open(path).dispose();
  });

  test('32 MiBを超えるファイルはSQLiteを開く前に拒否する', () {
    final file = File(path).openSync(mode: FileMode.write);
    file.truncateSync(maxDatabaseBytes);
    file.closeSync();
    expect(() => checkDatabaseFileSize(path), returnsNormally);
    final oversized = File(path).openSync(mode: FileMode.append);
    oversized.writeByteSync(0);
    oversized.closeSync();
    expect(() => UnitDatabase.open(path), throwsA(isA<FormatException>()));
    expect(File(path).lengthSync(), maxDatabaseBytes + 1);
  });

  test('小さいファイルでも合計行数の上限を超えたDBは読み込まない', () {
    makeDatabase();
    final raw = sqlite3.open(path);
    raw.execute('''WITH RECURSIVE n(x) AS
      (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x<$maxDatabaseRows)
      INSERT INTO destinations SELECT 'd-'||x,'name-'||x FROM n''');
    raw.dispose();
    expect(File(path).lengthSync(), lessThan(maxDatabaseBytes));
    rejectUnchanged();
  });

  test('行数上限を超える編集はロールバックし既存データを保つ', () {
    final db = UnitDatabase.open(path);
    expect(() => db.transaction(() {
      db.db.execute('''WITH RECURSIVE n(x) AS
        (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x<$maxDatabaseRows)
        INSERT INTO destinations SELECT 'd-'||x,'name-'||x FROM n''');
    }), throwsA(isA<FormatException>()));
    expect(db.db.select('SELECT * FROM destinations'), isEmpty);
    db.dispose();
    UnitDatabase.open(path).dispose();
  });

  test('旧形式の移行で行数上限を超えたら移行をロールバックする', () {
    final raw = sqlite3.open(path);
    raw.execute(schema);
    raw.execute('ALTER TABLE meetings ADD COLUMN exam_period_id TEXT REFERENCES events(id) ON DELETE CASCADE');
    raw.execute('PRAGMA application_id=$applicationId');
    raw.execute('PRAGMA user_version=4');
    raw.execute("INSERT INTO slots VALUES ('s',1,530,620)");
    raw.execute("INSERT INTO courses (id,name) VALUES ('c','c')");
    raw.execute("INSERT INTO meetings (id,course_id,slot_id,weekday) VALUES ('m','c','s',1)");
    raw.execute("""INSERT INTO events (id,kind,start_date,end_date) VALUES
      ('a','teaching','2026-04-01','2026-07-31'),
      ('b','teaching','2026-09-01','2026-12-31')""");
    raw.execute('''WITH RECURSIVE n(x) AS
      (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x<${maxDatabaseRows - 5})
      INSERT INTO destinations SELECT 'd-'||x,'name-'||x FROM n''');
    raw.dispose();
    rejectUnchanged();
    final check = sqlite3.open(path);
    expect(check.userVersion, 4);
    expect(check.select('SELECT count(*) AS n FROM meetings').single['n'], 1);
    check.dispose();
  });
}
