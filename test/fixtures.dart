import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';
import 'package:unitable/domain/schedule.dart';

void useTestSqlite() {
  if (Platform.isWindows) {
    open.overrideFor(
        OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  }
}

SchoolData sampleData() => SchoolData({
      'settings': [
        {'id': 'lead_minutes', 'value': '10'}
      ],
      'slots': [
        {'id': 's1', 'position': 1, 'start_minute': 530, 'end_minute': 620},
        {'id': 's2', 'position': 2, 'start_minute': 630, 'end_minute': 720}
      ],
      'terms': [
        {'id': 't1', 'name': '前期', 'color': 0xff647a69}
      ],
      'events': [
        {
          'id': 'e1',
          'kind': 'teaching',
          'term_id': 't1',
          'name': '授業期間',
          'start_date': '2026-04-01',
          'end_date': '2026-07-31'
        }
      ],
      'courses': [
        {
          'id': 'c1',
          'name': '情報科学',
          'room': 'A-201',
          'teacher': '山田先生',
          'notes': '# メモ',
          'term_ids': '["t1"]',
          'start_date': null,
          'end_date': null,
          'lead_minutes': null,
          'check_tasks': 1
        }
      ],
      'meetings': [
        {
          'id': 'm1',
          'course_id': 'c1',
          'slot_id': 's1',
          'weekday': 1,
          'term_id': 't1',
          'once_date': null,
          'room': null,
          'lead_minutes': null
        }
      ],
      'session_changes': [],
      'day_changes': [],
      'tasks': [],
    });
