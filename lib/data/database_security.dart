import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../l10n/strings.dart';

// Keep this byte limit in sync with Android's StorageStreams.maxDatabaseBytes.
const maxDatabaseBytes = 32 * 1024 * 1024;
const maxDatabaseRows = 100000;

void checkDatabaseFileSize(String path) {
  if (path != ':memory:' &&
      File(path).existsSync() &&
      File(path).lengthSync() > maxDatabaseBytes) {
    throw FormatException(strings.databaseTooLarge);
  }
}

/// Only SQL definitions shipped by the app may run during reads or writes.
/// Inspect schema text before integrity checks, migrations, or user data queries.
void validateDatabaseSchema(Database db, String trustedSchema, int version) {
  final definitions = db.select(
    'SELECT type,name,tbl_name,sql FROM sqlite_master LIMIT 129',
  );
  if (definitions.length > 128) {
    throw FormatException(strings.unsafeDatabaseSchema);
  }
  final trusted = <String, List<List<String>>>{};
  final indexes = <String>{};
  for (final statement in trustedSchema.split(';')) {
    final tokens = _tokens(statement);
    if (tokens.isEmpty) continue;
    if (tokens[1] == 'table') {
      trusted[tokens[2]] = _clauses(tokens);
    } else {
      indexes.add(tokens.join('\u0000'));
    }
  }
  // Columns added by the supported migrations. Exact clauses also reject
  // injected CHECK expressions, generated columns, defaults and foreign keys.
  const additions = {
    'meetings': [
      'exam_period_id TEXT REFERENCES events(id) ON DELETE CASCADE',
      'period_id TEXT REFERENCES events(id) ON DELETE CASCADE',
      'legacy_origin_id TEXT',
    ],
    'tasks': [
      'context_meeting_id TEXT REFERENCES meetings(id) ON DELETE SET NULL',
      'context_source_date TEXT',
    ],
    'settings': ['id TEXT PRIMARY KEY', 'value TEXT NOT NULL'],
    'event_ranges': [
      'id TEXT PRIMARY KEY',
      'event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE',
      'start_date TEXT NOT NULL',
      'end_date TEXT NOT NULL CHECK(end_date>=start_date)',
    ],
  };
  for (final entry in additions.entries) {
    trusted.putIfAbsent(entry.key, () => []);
  }
  final seen = <String>{};
  for (final definition in definitions) {
    final type = definition['type'], name = definition['name'] as String;
    final table = definition['tbl_name'] as String;
    final sql = definition['sql'] as String?;
    if (sql == null &&
        type == 'index' &&
        name.startsWith('sqlite_autoindex_') &&
        trusted.containsKey(table)) {
      continue;
    }
    if (sql == null || sql.length > 65536) {
      throw FormatException(strings.unsafeDatabaseSchema);
    }
    final tokens = _tokens(sql);
    if (type == 'index' && indexes.contains(tokens.join('\u0000'))) continue;
    if (type != 'table' ||
        !trusted.containsKey(name) ||
        table != name ||
        (name == 'settings' && version >= 3) ||
        tokens.length < 5 ||
        tokens[0] != 'create' ||
        tokens[1] != 'table' ||
        tokens[2] != name ||
        tokens[3] != '(' ||
        tokens.last != ')') {
      throw FormatException(strings.unsafeDatabaseSchema);
    }
    final allowed = [
      ...trusted[name]!,
      for (final clause in additions[name] ?? <String>[]) _tokens(clause),
    ].map((c) => c.join('\u0000')).toSet();
    final clauses = _clauses(tokens).map((c) => c.join('\u0000')).toList();
    final required = [
      ...trusted[name]!.where((clause) =>
          !(name == 'events' && version < 3 && clause.first == 'color') &&
          !(name == 'day_changes' && version < 3 && clause.first == 'exam_day') &&
          !(name == 'day_changes' && version < 2 &&
              ['holiday_name', 'is_national'].contains(clause.first))),
      if ((name == 'meetings' && version >= 5) ||
          (name == 'tasks' && version >= 5) ||
          name == 'settings' || name == 'event_ranges')
        for (final clause in additions[name] ?? <String>[]) _tokens(clause),
      if (name == 'meetings' && version == 4) _tokens(additions[name]!.first),
    ].map((c) => c.join('\u0000'));
    if (clauses.toSet().length != clauses.length ||
        !clauses.every(allowed.contains) || !required.every(clauses.contains)) {
      throw FormatException(strings.unsafeDatabaseSchema);
    }
    seen.add(name);
  }
  if (!trusted.keys
          .where((t) => t != 'settings' && t != 'event_ranges')
          .every(seen.contains) ||
      (version >= 6 && !seen.contains('event_ranges'))) {
    throw FormatException(strings.unsafeDatabaseSchema);
  }
}

void checkDatabaseRowCount(Database db, Iterable<String> tables) {
  var remaining = maxDatabaseRows;
  for (final table in tables) {
    // Bound each query, including databases with millions of tiny rows.
    remaining -=
        db.select('SELECT count(*) AS n FROM (SELECT 1 FROM $table LIMIT ?)', [
              remaining + 1,
            ]).single['n']
            as int;
    if (remaining < 0) throw FormatException(strings.databaseTooLarge);
  }
}

List<String> _tokens(String sql) {
  final pattern = RegExp(
    r'''\s+|'(?:''|[^'])*'|"(?:""|[^"])*"|`(?:``|[^`])*`|\[[^\]]*\]|[a-zA-Z_][a-zA-Z_0-9]*|[0-9]+|[^\s]''',
  );
  return [
    for (final match in pattern.allMatches(sql))
      if (match[0]!.trim().isNotEmpty) _normalizeToken(match[0]!),
  ];
}

String _normalizeToken(String token) {
  if (token.startsWith("'")) return token; // Preserve literal contents exactly.
  if (token.startsWith('"') || token.startsWith('`') || token.startsWith('[')) {
    token = token.substring(1, token.length - 1);
  }
  return token.toLowerCase();
}

List<List<String>> _clauses(List<String> tokens) {
  if (tokens.length < 5 || tokens[3] != '(' || tokens.last != ')') {
    throw FormatException(strings.unsafeDatabaseSchema);
  }
  final result = <List<String>>[];
  var clause = <String>[], depth = 0;
  for (final token in tokens.sublist(4, tokens.length - 1)) {
    if (token == ',' && depth == 0) {
      if (clause.isEmpty) {
        throw FormatException(strings.unsafeDatabaseSchema);
      }
      result.add(clause);
      clause = [];
    } else {
      clause.add(token);
      if (token == '(') depth++;
      if (token == ')') depth--;
      if (depth < 0) throw FormatException(strings.unsafeDatabaseSchema);
    }
  }
  if (depth != 0 || clause.isEmpty) {
    throw FormatException(strings.unsafeDatabaseSchema);
  }
  result.add(clause);
  return result;
}
