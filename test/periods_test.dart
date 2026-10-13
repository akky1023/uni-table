import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/domain/periods.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/ui/calendar_style.dart';

void main() {
  for (final count in [1, 2, 3, 4, 5]) {
    test('空欄の$count期間を保存せず日付順に命名する', () {
      final rows = [
        for (var i = count; i >= 1; i--)
          {
            'id': '$i',
            'kind': 'teaching',
            'name': '',
            'start_date': '2026-${(i + 4).toString().padLeft(2, '0')}-01',
            'end_date': '2026-${(i + 4).toString().padLeft(2, '0')}-28'
          }
      ];
      final data = SchoolData({'events': rows});
      final sorted = timetablePeriods(data);
      final expected = count == 1
          ? ['講義期間']
          : count == 2
              ? ['前期', '後期']
              : [
                  for (var i = 1; i <= count; i++)
                    count == 4 ? '第$iクオータ' : '$i学期'
                ];
      expect(sorted.map((p) => periodLabel(data, p)), expected);
      expect(rows.every((r) => r['name'] == ''), isTrue);
      for (final row in rows) {
        row['kind'] = 'exam';
      }
      expect(timetablePeriods(data).map((p) => periodLabel(data, p)),
          count == 1 ? ['試験期間'] : expected.map((e) => '$e試験期間'));
    });
  }
  test('休業期間の判定は祝日の下に入り初期色を祝日と揃える', () {
    final date = shiftDay(dateOnly(DateTime.now()), 30);
    final data = SchoolData({
      'settings': [
        {'id': 'calendar_order', 'value': '["past","national","holiday"]'}
      ],
      'events': [
        {
          'id': 'h',
          'kind': 'holiday',
          'name': '休暇',
          'start_date': dayKey(date),
          'end_date': dayKey(date)
        }
      ]
    });
    final order = calendarOrder(data);
    expect(order.indexOf('closure_period'), order.indexOf('national') + 1);
    expect(defaultCalendarColors['closure_period'],
        defaultCalendarColors['national']);
    expect(calendarPaint(data, date, editing: false).rule, 'closure_period');
  });
}
