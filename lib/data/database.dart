import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../domain/schedule.dart';
import '../l10n/strings.dart';
import 'database_security.dart';

const applicationId = 0x554E4954;
const tableNames = [
  'settings',
  'slots',
  'terms',
  'events',
  'event_ranges',
  'courses',
  'meetings',
  'day_changes',
  'session_changes',
  'tasks',
  'destinations'
];

class UnitDatabase extends ChangeNotifier {
  final Database db;
  final String path;
  Map<String, String> appSettings;
  void Function(Map<String, String>)? persistSettings;
  SchoolData data = SchoolData({});
  UnitDatabase._(this.db, this.path, this.appSettings) {
    reload();
  }

  static UnitDatabase open(String path,
      {void Function(Map<String, String>)? onLegacySettings}) {
    checkDatabaseFileSize(path);
    final exists = File(path).existsSync() && File(path).lengthSync() > 0;
    final db = sqlite3.open(path);
    final localSettings = <String, String>{};
    try {
      // Configure the connection before parsing any untrusted schema or rows.
      db.config.setIntConfig(1010, 1); // SQLITE_DBCONFIG_DEFENSIVE
      db.config.setIntConfig(1003, 0); // SQLITE_DBCONFIG_ENABLE_TRIGGER
      db.config.setIntConfig(1015, 0); // SQLITE_DBCONFIG_ENABLE_VIEW
      db.config.setIntConfig(1017, 0); // SQLITE_DBCONFIG_TRUSTED_SCHEMA
      if (exists) {
        if (db.select('PRAGMA application_id').first.values.first !=
            applicationId) {
          throw FormatException(strings.invalidDatabase);
        }
        if (![1, 2, 3, 4, 5, 6]
            .contains(db.select('PRAGMA user_version').first.values.first)) {
          throw FormatException(strings.unsupportedDatabaseVersion);
        }
        validateDatabaseSchema(db, schema, db.userVersion);
        _checkRowCount(db);
        if (db.select('PRAGMA quick_check').first.values.first != 'ok') {
          throw FormatException(strings.databaseIntegrityFailed);
        }
      }
      db.execute('PRAGMA foreign_keys = ON');
      db.execute('PRAGMA journal_mode = DELETE');
      db.execute('PRAGMA synchronous = FULL');
      db.execute('PRAGMA busy_timeout = 5000');
      final pageSize = db.select('PRAGMA page_size').single.values.single as int;
      db.execute('PRAGMA max_page_count = ${maxDatabaseBytes ~/ pageSize}');
      if (!exists) {
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute(schema);
          db.execute('PRAGMA application_id = $applicationId');
          db.execute('PRAGMA user_version = 3');
          for (var n = 1; n <= 6; n++) {
            final start = 530 + (n - 1) * 100 + (n > 2 ? 40 : 0);
            db.execute('INSERT INTO slots VALUES (?, ?, ?, ?)',
                ['slot-$n', n, start, start + 90]);
          }

          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      if (exists && db.select('PRAGMA user_version').first.values.first == 1) {
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute('ALTER TABLE day_changes ADD COLUMN holiday_name TEXT');
          db.execute(
              'ALTER TABLE day_changes ADD COLUMN is_national INTEGER NOT NULL DEFAULT 0');
          for (final event in db.select(
              "SELECT * FROM events WHERE id LIKE 'jp-holiday-%' AND kind = 'holiday'")) {
            db.execute(
                'INSERT INTO day_changes (id,date,cancelled,holiday_name,is_national) VALUES (?,?,1,?,1) ON CONFLICT(date) DO UPDATE SET cancelled=1,holiday_name=excluded.holiday_name,is_national=1',
                [event['id'], event['start_date'], event['name']]);
          }
          db.execute(
              "DELETE FROM events WHERE id LIKE 'jp-holiday-%' AND kind = 'holiday'");
          db.execute('PRAGMA user_version = 2');
          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      if ((db.select('PRAGMA user_version').first.values.first as int) < 3) {
        db.execute('BEGIN IMMEDIATE');
        try {
          if (db
              .select("SELECT name FROM sqlite_master WHERE name='settings'")
              .isNotEmpty) {
            for (final row in db.select('SELECT * FROM settings')) {
              localSettings[row['id'] as String] = row['value'] as String;
            }
            onLegacySettings?.call(localSettings);
            db.execute('DROP TABLE settings');
          }
          if (!db
              .select('PRAGMA table_info(events)')
              .any((r) => r['name'] == 'color')) {
            db.execute('ALTER TABLE events ADD COLUMN color INTEGER');
          }
          if (!db
              .select('PRAGMA table_info(day_changes)')
              .any((r) => r['name'] == 'exam_day')) {
            db.execute(
                'ALTER TABLE day_changes ADD COLUMN exam_day INTEGER NOT NULL DEFAULT 0');
          }
          db.execute('PRAGMA user_version = 3');
          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      if ((db.select('PRAGMA user_version').first.values.first as int) < 4) {
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute(
              'ALTER TABLE meetings ADD COLUMN exam_period_id TEXT REFERENCES events(id) ON DELETE CASCADE');
          // Previously ungrouped teaching periods become independent semesters.
          for (final event in db.select(
              "SELECT * FROM events WHERE kind='teaching' AND term_id IS NULL")) {
            final id = 'semester-${event['id']}';
            var number = 1;
            while (db.select(
                'SELECT 1 FROM terms WHERE name=?', ['$number学期']).isNotEmpty) {
              number++;
            }
            db.execute('INSERT INTO terms VALUES (?,?,?)', [
              id,
              (event['name'] as String).isEmpty ? '$number学期' : event['name'],
              event['color'] ?? 0xff419c79
            ]);
            db.execute(
                'UPDATE events SET term_id=? WHERE id=?', [id, event['id']]);
          }
          db.execute('PRAGMA user_version = 4');
          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      if ((db.select('PRAGMA user_version').first.values.first as int) < 5) {
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute(
              'ALTER TABLE meetings ADD COLUMN period_id TEXT REFERENCES events(id) ON DELETE CASCADE');
          db.execute('ALTER TABLE meetings ADD COLUMN legacy_origin_id TEXT');
          db.execute(
              'ALTER TABLE tasks ADD COLUMN context_meeting_id TEXT REFERENCES meetings(id) ON DELETE SET NULL');
          db.execute('ALTER TABLE tasks ADD COLUMN context_source_date TEXT');
          final periods =
              db.select("SELECT * FROM events WHERE kind='teaching'");
          for (final m
              in db.select('SELECT * FROM meetings WHERE once_date IS NULL')) {
            final course = db.select(
                'SELECT * FROM courses WHERE id=?', [m['course_id']]).single;
            final courseTerms = stringList(course['term_ids']);
            final matching = periods
                .where((e) => m['term_id'] != null
                    ? e['term_id'] == m['term_id']
                    : courseTerms.isEmpty || courseTerms.contains(e['term_id']))
                .toList();
            for (var i = 0; i < matching.length; i++) {
              final event = matching[i],
                  id = i == 0 ? m['id'] as String : newId();
              if (i == 0) {
                db.execute(
                    'UPDATE meetings SET period_id=?, legacy_origin_id=? WHERE id=?',
                    [event['id'], m['id'], id]);
              } else {
                final copy = Map<String, dynamic>.from(m)
                  ..['id'] = id
                  ..['period_id'] = event['id']
                  ..['legacy_origin_id'] = m['id'];
                db.execute(
                    'INSERT INTO meetings (${copy.keys.join(',')}) VALUES (${List.filled(copy.length, '?').join(',')})',
                    copy.values.toList());
                for (final change in db.select(
                    'SELECT * FROM session_changes WHERE meeting_id=? AND date>=? AND date<=?',
                    [m['id'], event['start_date'], event['end_date']])) {
                  final copied = Map<String, dynamic>.from(change)
                    ..['id'] = newId()
                    ..['meeting_id'] = id;
                  db.execute(
                      'INSERT INTO session_changes (${copied.keys.join(',')}) VALUES (${List.filled(copied.length, '?').join(',')})',
                      copied.values.toList());
                }
                db.execute(
                    'UPDATE tasks SET due_meeting_id=? WHERE due_meeting_id=? AND due_source_date>=? AND due_source_date<=?',
                    [id, m['id'], event['start_date'], event['end_date']]);
              }
            }
          }
          db.execute('PRAGMA user_version = 5');
          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      if ((db.select('PRAGMA user_version').first.values.first as int) < 6) {
        db.execute('BEGIN IMMEDIATE');
        try {
          db.execute(
              'CREATE TABLE event_ranges (id TEXT PRIMARY KEY, event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE, start_date TEXT NOT NULL, end_date TEXT NOT NULL CHECK(end_date>=start_date))');
          db.execute('PRAGMA user_version = 6');
          _checkRowCount(db);
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
      return UnitDatabase._(db, path, localSettings);
    } catch (_) {
      db.dispose();
      rethrow;
    }
  }

  static void _checkRowCount(Database db) => checkDatabaseRowCount(db,
      db.select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((row) => row['name'] as String).where(tableNames.contains));

  static UnitDatabase draftOf(UnitDatabase source) {
    final draft = UnitDatabase.open(':memory:');
    draft.appSettings = Map.of(source.appSettings);
    draft.transaction(() => draft.replaceContent(source.data));
    return draft;
  }

  void replaceContent(SchoolData source) {
    final tables = tableNames.where((t) => t != 'settings').toList();
    for (final table in tables.reversed) {
      db.execute('DELETE FROM $table');
    }
    for (final table in tables) {
      for (final row in source.rows(table)) {
        put(table, row);
      }
    }
  }

  void mergePeriods(List<String> ids, String name) {
    if (ids.length < 2) throw FormatException(strings.selectMultiplePeriods);
    final periods = ids.map((id) => data.find('events', id)!).toList()
      ..sort((a, b) =>
          (a['start_date'] as String).compareTo(b['start_date'] as String));
    if (periods.any((p) => p['kind'] != periods.first['kind'])) {
      throw FormatException(strings.selectSamePeriodKind);
    }
    final target = periods.first['id'] as String;
    final ranges = <DbRow>[];
    for (final period in periods) {
      final parts = data
          .rows('event_ranges')
          .where((r) => r['event_id'] == period['id'])
          .toList();
      for (final part in parts.isEmpty ? [period] : parts) {
        ranges.add({
          'id': newId(),
          'event_id': target,
          'start_date': part['start_date'],
          'end_date': part['end_date']
        });
      }
    }
    ranges.sort((a, b) =>
        (a['start_date'] as String).compareTo(b['start_date'] as String));
    final last = ranges
        .map((r) => r['end_date'] as String)
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    put('events', {
      ...periods.first,
      'name': name,
      'start_date': ranges.first['start_date'],
      'end_date': last,
      'color': null
    });
    for (final id in ids) {
      db.execute('DELETE FROM event_ranges WHERE event_id=?', [id]);
      if (id == target) continue;
      db.execute(
          'UPDATE meetings SET period_id=? WHERE period_id=?', [target, id]);
      db.execute('UPDATE meetings SET exam_period_id=? WHERE exam_period_id=?',
          [target, id]);
      remove('events', id);
    }
    for (final range in ranges) {
      put('event_ranges', range);
    }
  }

  void reload() {
    _checkRowCount(db);
    data = SchoolData({
      'settings': [
        for (final entry in appSettings.entries)
          {'id': entry.key, 'value': entry.value}
      ],
      for (final table in tableNames.where((t) => t != 'settings'))
        table: db
            .select('SELECT * FROM $table')
            .map((r) => Map<String, dynamic>.from(r))
            .toList()
    });
    notifyListeners();
  }

  void transaction(void Function() action) {
    final previous = Map<String, String>.from(appSettings);
    db.execute('BEGIN IMMEDIATE');
    try {
      action();
      _checkRowCount(db);
      persistSettings?.call(appSettings);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      appSettings
        ..clear()
        ..addAll(previous);
      persistSettings?.call(appSettings);
      rethrow;
    }
    reload();
  }

  void put(String table, DbRow row) {
    if (table == 'settings') {
      appSettings[row['id'] as String] = row['value'] as String;
      return;
    }
    if (!tableNames.contains(table)) throw ArgumentError('Unknown table');
    final columns = db
        .select('PRAGMA table_info($table)')
        .map((r) => r['name'] as String)
        .toSet();
    if (!row.keys.every(columns.contains) || row['id'] == null) {
      throw ArgumentError('Invalid columns');
    }
    final keys = row.keys.toList();
    if (db
        .select('SELECT 1 FROM $table WHERE id = ?', [row['id']]).isNotEmpty) {
      final updates = keys.where((k) => k != 'id').toList();
      if (updates.isNotEmpty) {
        db.execute(
            'UPDATE $table SET ${updates.map((k) => '$k = ?').join(',')} WHERE id = ?',
            [...updates.map((k) => row[k]), row['id']]);
      }
      return;
    }
    final update =
        keys.where((k) => k != 'id').map((k) => '$k = excluded.$k').join(',');
    db.execute(
        'INSERT INTO $table (${keys.join(',')}) VALUES (${List.filled(keys.length, '?').join(',')}) ON CONFLICT(id) DO UPDATE SET $update',
        keys.map((k) => row[k]).toList());
  }

  void remove(String table, String id) {
    if (!tableNames.contains(table)) throw ArgumentError('Unknown table');
    if (table == 'settings') {
      appSettings.remove(id);
      return;
    }
    db.execute('DELETE FROM $table WHERE id = ?', [id]);
  }

  void snapshot(String target) {
    checkDatabaseFileSize(path);
    if (File(target).existsSync()) {
      throw FileSystemException(strings.fileAlreadyExists);
    }
    db.execute('VACUUM INTO ?', [target]);
  }

  @override
  void dispose() {
    db.dispose();
    super.dispose();
  }
}

const schema = '''
CREATE TABLE slots (id TEXT PRIMARY KEY, position INTEGER NOT NULL UNIQUE CHECK(position>0), start_minute INTEGER NOT NULL CHECK(start_minute>=0 AND start_minute<1440), end_minute INTEGER NOT NULL CHECK(end_minute>start_minute AND end_minute<=1440));
CREATE TABLE terms (id TEXT PRIMARY KEY, name TEXT NOT NULL, color INTEGER NOT NULL);
CREATE TABLE events (id TEXT PRIMARY KEY, kind TEXT NOT NULL CHECK(kind IN ('teaching','exam','holiday')), term_id TEXT REFERENCES terms(id) ON DELETE SET NULL, name TEXT NOT NULL DEFAULT '', start_date TEXT NOT NULL, end_date TEXT NOT NULL CHECK(end_date>=start_date), color INTEGER);
CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL, room TEXT NOT NULL DEFAULT '', teacher TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', term_ids TEXT NOT NULL DEFAULT '[]', start_date TEXT, end_date TEXT, lead_minutes INTEGER CHECK(lead_minutes>=-1), check_tasks INTEGER NOT NULL DEFAULT 1);
CREATE TABLE meetings (id TEXT PRIMARY KEY, course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE, slot_id TEXT NOT NULL REFERENCES slots(id) ON DELETE RESTRICT, weekday INTEGER CHECK(weekday BETWEEN 1 AND 7), term_id TEXT REFERENCES terms(id) ON DELETE CASCADE, once_date TEXT, room TEXT, lead_minutes INTEGER CHECK(lead_minutes>=-1), CHECK((weekday IS NOT NULL AND once_date IS NULL) OR (weekday IS NULL AND once_date IS NOT NULL)));
CREATE TABLE day_changes (id TEXT PRIMARY KEY, date TEXT NOT NULL UNIQUE, cancelled INTEGER NOT NULL DEFAULT 0, source_weekday INTEGER CHECK(source_weekday BETWEEN 1 AND 7), replacement_date TEXT, holiday_name TEXT, is_national INTEGER NOT NULL DEFAULT 0, exam_day INTEGER NOT NULL DEFAULT 0);
CREATE TABLE session_changes (id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE, date TEXT NOT NULL, cancelled INTEGER NOT NULL DEFAULT 0, replacement_date TEXT, replacement_slot_id TEXT REFERENCES slots(id) ON DELETE RESTRICT, room TEXT, lead_minutes INTEGER CHECK(lead_minutes>=-1), UNIQUE(meeting_id,date));
CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, course_id TEXT REFERENCES courses(id) ON DELETE SET NULL, due_at TEXT NOT NULL, due_meeting_id TEXT REFERENCES meetings(id) ON DELETE SET NULL, due_source_date TEXT, destination TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', rules TEXT, done INTEGER NOT NULL DEFAULT 0);
CREATE TABLE destinations (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE INDEX meeting_course ON meetings(course_id);
CREATE INDEX task_due ON tasks(due_at);
CREATE INDEX event_dates ON events(start_date,end_date);
''';

/// Android's SAF grants refer to document URIs, not paths usable by SQLite.
/// The working DB is private; a consistent SQLite snapshot is written to SAF
/// after each commit. A failed write retains the working DB and exposes retry.
class Storage extends ChangeNotifier {
  static const channel = MethodChannel('unitable/storage');
  late Directory support;
  late File preferences;
  String? tree;
  String? externalPath;
  String? pendingSyncError;
  UnitDatabase? _database;
  final localSettings = <String, String>{};
  String? document;
  bool userSelected = false;
  bool get hasDatabase => _database != null;
  UnitDatabase get database =>
      _database ?? (throw StateError(strings.selectDatabaseFirst));
  set database(UnitDatabase value) {
    for (final entry in value.appSettings.entries) {
      localSettings.putIfAbsent(entry.key, () => entry.value);
    }
    if (!localSettings.containsKey('hidden_weekdays') &&
        localSettings.containsKey('hide_holiday_weekdays')) {
      final options = jsonDecode(
          localSettings['notification_holidays'] ?? '{"weekdays":[7]}') as Map;
      final days = localSettings['hide_holiday_weekdays'] == '1'
          ? options['weekdays'] as List? ?? [7]
          : <int>[];
      localSettings['hidden_weekdays'] =
          jsonEncode(days.map((d) => d.toString()).toList());
      savePreferences();
    }
    value.appSettings = localSettings;
    value.persistSettings = (_) => savePreferences();
    _database = value;
    value.reload();
    notifyListeners();
  }

  void setLanguage(String language) {
    if (!['system', 'ja', 'en'].contains(language)) return;
    localSettings['language'] = language;
    savePreferences();
    notifyListeners();
  }

  void savePreferences() {
    final temporary = File('${preferences.path}.pending');
    temporary.writeAsStringSync(
        jsonEncode({
          'tree': tree,
          'path': externalPath,
          'document': document,
          'selected': userSelected,
          'settings': localSettings,
        }),
        flush: true);
    temporary.renameSync(preferences.path);
  }

  UnitDatabase openWorkingDatabase(String path) =>
      UnitDatabase.open(path, onLegacySettings: (values) {
        for (final entry in values.entries) {
          localSettings.putIfAbsent(entry.key, () => entry.value);
        }
        savePreferences();
      });
  File get dirtyMarker => File(p.join(support.path, 'pending-folder-save'));
  Future<void> beforeWrite() async {
    if (tree != null || document != null) {
      await dirtyMarker.writeAsString('pending', flush: true);
    }
  }

  Future<void> initialize({Directory? applicationDirectory}) async {
    support = applicationDirectory ?? await getApplicationSupportDirectory();
    // Keep the original Windows data location when the display name changes.
    if (Platform.isWindows && applicationDirectory == null) {
      const debugBuild = bool.fromEnvironment('UNITABLE_NOTIFICATION_TEST');
      support = Directory(p.join(p.dirname(support.path),
          debugBuild ? 'UniTable.debug' : 'UniTable'));
    }
    await support.create(recursive: true);
    preferences = File(p.join(support.path, 'storage-location.json'));
    if (await preferences.exists()) {
      final state = jsonDecode(await preferences.readAsString()) as Map;
      tree = state['tree'] as String?;
      externalPath = state['path'] as String?;
      document = state['document'] as String?;
      userSelected = state['selected'] == true;
      localSettings.addAll((state['settings'] as Map? ?? {})
          .map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    setAppLocale(
      resolveAppLocale(
        localSettings['language'] ?? 'system',
        PlatformDispatcher.instance.locale,
      ),
    );
    if (!userSelected) return;
    final local = p.join(support.path, 'university.unitable');
    if (document != null) {
      if (!await dirtyMarker.exists()) {
        final target = p.join(support.path, 'working-${newId()}.unitable');
        try {
          await invokeStorage('readDocument', {'uri': document, 'path': target});
          final next = openWorkingDatabase(target);
          database = next;
          externalPath = target;
        } catch (e) {
          if (externalPath == null || !File(externalPath!).existsSync()) {
            rethrow;
          }
          pendingSyncError = strings.workingCopyFile(e);
          await beforeWrite();
        }
      }
      if (!hasDatabase) database = openWorkingDatabase(externalPath!);
      await remember();
      return;
    }
    if (Platform.isAndroid && tree != null) {
      if (await dirtyMarker.exists()) {
        pendingSyncError = strings.recoveredChanges;
      } else {
        final incoming = p.join(support.path, 'working-${newId()}.unitable');
        try {
          await invokeStorage('readDatabase', {'tree': tree, 'path': incoming});
          final checked = openWorkingDatabase(incoming);
          checked.dispose();
          externalPath = incoming;
          await remember();
        } catch (e) {
          if (!File(externalPath ?? local).existsSync()) rethrow;
          pendingSyncError = strings.workingCopyFolder(e);
          await beforeWrite();
        }
      }
    }
    final selectedPath = externalPath ?? local;
    if (!File(selectedPath).existsSync() ||
        File(selectedPath).lengthSync() == 0) {
      throw FileSystemException(strings.databaseNotFound);
    }
    database = openWorkingDatabase(selectedPath);
  }

  String get location => document ?? tree ?? database.path;
  Future<void> remember() async => savePreferences();

  Future<bool> selectDatabase({bool create = false}) async {
    if (Platform.isAndroid) {
      final uri = await invokeStorage<String>(create ? 'createDocument' : 'pickDocument');
      if (uri == null) return false;
      final candidate = p.join(support.path, 'working-${newId()}.unitable');
      if (!create) {
        await invokeStorage('readDocument', {'uri': uri, 'path': candidate});
      }
      final next = openWorkingDatabase(candidate);
      if (create) {
        try {
          await invokeStorage('writeDocument', {'uri': uri, 'path': candidate});
        } catch (_) {
          next.dispose();
          rethrow;
        }
      }
      await adopt(next, uri: uri);
    } else {
      String? path;
      if (create) {
        path = (await getSaveLocation(
                suggestedName: 'university.unitable',
                acceptedTypeGroups: [
              XTypeGroup(label: strings.appName, extensions: ['unitable'])
            ]))
            ?.path;
        if (path != null && !path.toLowerCase().endsWith('.unitable')) {
          path = '$path.unitable';
        }
        if (path != null && File(path).existsSync()) {
          throw FileSystemException(strings.noOverwrite);
        }
      } else {
        path = (await openFile(acceptedTypeGroups: [
          XTypeGroup(label: strings.appName, extensions: ['unitable'])
        ]))
            ?.path;
        if (path != null && !path.toLowerCase().endsWith('.unitable')) {
          throw FormatException(strings.selectUnitableFile);
        }
        if (path != null &&
            (!File(path).existsSync() || File(path).lengthSync() == 0)) {
          throw FormatException(strings.emptyFile);
        }
      }
      if (path == null) return false;
      await adopt(openWorkingDatabase(path));
    }
    return true;
  }

  Future<void> adopt(UnitDatabase next, {String? uri}) async {
    final old = _database;
    final previousPath = externalPath,
        previousDocument = document,
        previousTree = tree;
    final selected = userSelected;
    externalPath = next.path;
    document = uri;
    tree = null;
    userSelected = true;
    try {
      database = next;
      await remember();
    } catch (_) {
      _database = old;
      externalPath = previousPath;
      document = previousDocument;
      tree = previousTree;
      userSelected = selected;
      next.dispose();
      rethrow;
    }
    pendingSyncError = null;
    if (await dirtyMarker.exists()) await dirtyMarker.delete();
    old?.dispose();
    if (document != null) {
      await beforeWrite();
      try {
        await synchronize();
      } catch (_) {/* Keep the working copy and expose the retry banner. */}
    }
  }

  Future<String?> chooseFolder() => invokeStorage<String>('pickDirectory');
  Future<bool> treeHasDatabase(String uri) async =>
      await invokeStorage<bool>('hasDatabase', {'tree': uri}) ?? false;
  Future<void> useFolder(String folder, {required bool openExisting}) async {
    final old = database;
    userSelected = true;
    document = null;
    if (Platform.isAndroid) {
      final candidate = p.join(support.path, 'candidate-${newId()}.unitable');
      if (openExisting) {
        await invokeStorage('readDatabase', {'tree': folder, 'path': candidate});
      } else {
        old.snapshot(candidate);
        await invokeStorage('writeDatabase', {'tree': folder, 'path': candidate});
      }
      final next = openWorkingDatabase(candidate); // Validate before switching.
      final previousTree = tree;
      tree = folder;
      externalPath = null;
      try {
        // Persist working-copy path too, so unsynced changes survive restart.
        externalPath = candidate;
        await remember();
      } catch (_) {
        tree = previousTree;
        externalPath = old.path;
        next.dispose();
        rethrow;
      }
      database = next;
    } else {
      final target = p.join(folder, 'university.unitable');
      if (!openExisting) old.snapshot(target);
      final next = openWorkingDatabase(target);
      final previousPath = externalPath;
      externalPath = target;
      try {
        await remember();
      } catch (_) {
        externalPath = previousPath;
        next.dispose();
        rethrow;
      }
      database = next;
    }
    pendingSyncError = null;
    if (await dirtyMarker.exists()) await dirtyMarker.delete();
    old.dispose();
  }

  Future<void> synchronize() async {
    if (tree == null && document == null) return;
    final snapshot = p.join(support.path, 'snapshot-${newId()}.unitable');
    try {
      database.snapshot(snapshot);
      await invokeStorage(
          document != null ? 'writeDocument' : 'writeDatabase',
          {'tree': tree, 'uri': document, 'path': snapshot});
      pendingSyncError = null;
      if (await dirtyMarker.exists()) await dirtyMarker.delete();
    } catch (e) {
      pendingSyncError = strings.externalSaveFailed(e);
      rethrow;
    } finally {
      if (File(snapshot).existsSync()) await File(snapshot).delete();
    }
  }
}

// Native storage returns stable codes; translate at the Dart boundary so the
// app's language override also applies to Android file errors.
Future<T?> invokeStorage<T>(
  String method, [
  Map<String, Object?>? arguments,
]) async {
  try {
    return await Storage.channel.invokeMethod<T>(method, arguments);
  } on PlatformException catch (error) {
    final message = switch (error.code) {
      'storagePickerBusy' => strings.storagePickerBusy,
      'storageEmptyFile' => strings.storageEmptyFile,
      'storageFileTooLarge' => strings.storageFileTooLarge,
      'storageVerificationFailed' => strings.storageVerificationFailed,
      'storageFolderPermission' => strings.storageFolderPermission,
      'storageRecoveryFailed' => strings.storageRecoveryFailed,
      'storageMissingDatabase' => strings.storageMissingDatabase,
      'storageEmptyDatabase' => strings.storageEmptyDatabase,
      'storageNoData' => strings.storageNoData,
      'storageCleanupFailed' => strings.storageCleanupFailed,
      'storageRenameUnsupported' => strings.storageRenameUnsupported,
      'storageSaveFailed' => strings.storageSaveFailed,
      'storageSelectFile' => strings.storageSelectFile,
      'storageFilePermission' => strings.storageFilePermission,
      _ => null,
    };
    if (message == null) rethrow;
    throw PlatformException(
      code: error.code,
      message: message,
      details: error.details,
    );
  }
}
