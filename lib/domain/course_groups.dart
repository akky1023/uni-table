import '../l10n/strings.dart';
import 'schedule.dart';

/// Different meetings can retain distinct course records with the same name.
/// Group only the picker; never delete records or rewrite existing references.
Map<String, String> taskCourseChoices(SchoolData data, String selected) {
  final byName = <String, DbRow>{};
  for (final row in data.rows('courses').reversed) {
    byName.putIfAbsent(row['name'] as String, () => row);
  }
  final current = data.find('courses', selected);
  if (current != null) byName[current['name'] as String] = current;
  return {
    '': strings.unspecified,
    for (final row in byName.values) row['id'] as String: row['name'] as String
  };
}

bool matchesTaskCourse(SchoolData data, String? selected, String candidate) {
  if (selected == null || selected.isEmpty) return true;
  if (selected == candidate) return true;
  final course = data.find('courses', selected);
  return course != null &&
      course['name'] == data.find('courses', candidate)?['name'];
}
