import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/domain/course_groups.dart';

void main() {
  final data = SchoolData({
    'courses': [
      {'id': 'old', 'name': '数学'},
      {'id': 'other', 'name': '英語'},
      {'id': 'new', 'name': '数学'},
    ]
  });
  test('同名科目を一つにまとめても既存課題の参照IDは維持する', () {
    expect(taskCourseChoices(data, 'old'),
        {'': '未指定', 'old': '数学', 'other': '英語'});
    expect(taskCourseChoices(data, '').values.where((s) => s == '数学'),
        hasLength(1));
    expect(data.rows('courses'), hasLength(3));
  });
  test('同名科目の別レコードも期限ピッカーに含め別名は含めない', () {
    expect(matchesTaskCourse(data, 'new', 'old'), isTrue);
    expect(matchesTaskCourse(data, 'new', 'other'), isFalse);
    expect(matchesTaskCourse(data, null, 'other'), isTrue);
  });
}
