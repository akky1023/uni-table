import 'schedule.dart';

List<DbRow> timetablePeriods(SchoolData data) => data
    .rows('events')
    .where((e) => e['kind'] == 'teaching' || e['kind'] == 'exam')
    .toList()
  ..sort((a, b) {
    final kind = (a['kind'] == 'teaching' ? 0 : 1)
        .compareTo(b['kind'] == 'teaching' ? 0 : 1);
    return kind != 0
        ? kind
        : '${a['start_date']}:${a['id']}'
            .compareTo('${b['start_date']}:${b['id']}');
  });

String periodLabel(SchoolData data, DbRow period) {
  if ((period['name'] as String? ?? '').isNotEmpty) {
    return period['name'] as String;
  }
  if (period['kind'] == 'holiday') return '休業期間';
  final start = DateTime.parse(period['start_date'] as String);
  final month = int.tryParse(data.setting('year_start', '4')) ?? 4;
  final year = start.year - (start.month < month ? 1 : 0);
  final first = DateTime(year, month), last = DateTime(year + 1, month);
  final peers = data
      .rows('events')
      .where((e) =>
          e['kind'] == period['kind'] &&
          (e['start_date'] as String).compareTo(dayKey(last)) < 0 &&
          (e['end_date'] as String).compareTo(dayKey(first)) >= 0)
      .toList()
    ..sort((a, b) => '${a['start_date']}:${a['id']}'
        .compareTo('${b['start_date']}:${b['id']}'));
  final number = peers.indexWhere((e) => e['id'] == period['id']) + 1;
  final label = switch (peers.length) {
    1 => period['kind'] == 'exam' ? '' : '講義期間',
    2 => number == 1 ? '前期' : '後期',
    4 => '第$numberクオータ',
    _ => '$number学期',
  };
  return '$label${period['kind'] == 'exam' ? '試験期間' : ''}';
}
