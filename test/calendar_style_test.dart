import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/ui/calendar_style.dart';
import 'package:unitable/ui/status_marks.dart';

void main() {
  final date = DateTime.now().add(const Duration(days: 8));
  SchoolData data(
      {bool examDay = false,
      bool active = false,
      bool national = false,
      bool replacement = false,
      bool holiday = false,
      bool past = false,
      String? order,
      String? colors}) {
    final day = past ? DateTime.now().subtract(const Duration(days: 1)) : date;
    return SchoolData({
      'slots': [
        {'id': 's', 'position': 1, 'start_minute': 530, 'end_minute': 620}
      ],
      'courses': [
        {'id': 'c', 'name': '講義', 'term_ids': '[]'}
      ],
      'meetings': active
          ? [
              {
                'id': 'm',
                'course_id': 'c',
                'slot_id': 's',
                'once_date': dayKey(day)
              }
            ]
          : [],
      'events': [
        {
          'id': 'teaching',
          'kind': 'teaching',
          'start_date': dayKey(day),
          'end_date': dayKey(shiftDay(day, 5))
        },
        {
          'id': 'exam',
          'kind': 'exam',
          'start_date': dayKey(day),
          'end_date': dayKey(shiftDay(day, 5))
        },
      ],
      'day_changes': [
        {
          'id': 'd',
          'date': dayKey(day),
          'is_national': national ? 1 : 0,
          'exam_day': examDay ? 1 : 0,
          'source_weekday': replacement ? day.weekday : null
        }
      ],
      'settings': [
        {
          'id': 'notification_holidays',
          'value':
              '{"closures":false,"weekdays":${holiday ? '[${day.weekday}]' : '[]'},"no_classes":false}'
        },
        if (order != null) {'id': 'calendar_order', 'value': order},
        if (colors != null) {'id': 'calendar_colors', 'value': colors},
      ],
    });
  }

  test('閲覧は過去・試験日・代替講義・講義・祝日・休日・各期間の順に判定する', () {
    expect(
        calendarPaint(data(past: true, examDay: true, national: true),
                shiftDay(DateTime.now(), -1),
                editing: false)
            .rule,
        'past');
    expect(
        calendarPaint(data(examDay: true, active: true, national: true), date,
                editing: false)
            .rule,
        'exam_day');
    expect(
        calendarPaint(
                data(active: true, replacement: true, national: true), date,
                editing: false)
            .rule,
        'replacement_active');
    expect(
        calendarPaint(data(active: true, national: true), date, editing: false)
            .rule,
        'active');
    expect(
        calendarPaint(data(national: true, holiday: true), date, editing: false)
            .rule,
        'national');
    expect(calendarPaint(data(holiday: true), date, editing: false).rule,
        'holiday');
    expect(calendarPaint(data(), date, editing: false).rule, 'exam_period');
  });
  for (final standalone in [true, false]) {
    test('${standalone ? '単独補講' : '休講に伴う補講'}だけでは年間予定を代替日の色や記号にしない', () {
      final school = data(active: true);
      school.rows('settings').add({'id': 'accessibility_marks', 'value': '1'});
      if (standalone) {
        school.rows('meetings').single['is_makeup'] = 1;
      } else {
        final source = shiftDay(date, -1);
        school.rows('meetings').single['once_date'] = dayKey(source);
        school.tables['session_changes'] = [{
          'meeting_id': 'm', 'date': dayKey(source), 'cancelled': 1,
          'replacement_date': dayKey(date), 'replacement_slot_id': 's',
        }];
      }
      expect(ScheduleEngine(school).onDay(date).single.makeup, isTrue);
      expect(isReplacementDate(school, date), isFalse);
      final paint = calendarPaint(school, date, editing: false);
      expect(paint.rule, 'active');
      expect(paint.colors.single, Color(calendarColors(school)['active']!));
      expect(calendarPaint(school, date, editing: true).colors,
          isNot(contains(Color(calendarColors(school)['replacement_active']!))));
      final mark = calendarMarks(school, date, editing: false).single as StatusMark;
      expect(mark.shape, isNot(6));
      school.rows('day_changes').single['source_weekday'] = date.weekday;
      expect(isReplacementDate(school, date), isTrue);
      expect(calendarPaint(school, date, editing: false).rule, 'replacement_active');
    });
  }

  test('優先順位とRGBAを変更でき編集は重なる全期間を横帯で表示する', () {
    final custom = data(
        active: true,
        order: '["exam_period","active"]',
        colors: '{"exam_period":2131829299}');
    final paint = calendarPaint(custom, date, editing: false);
    expect(paint.rule, 'exam_period');
    expect(paint.colors.single, const Color(0x7f112233));
    final edited = calendarPaint(data(national: true), date, editing: true);
    expect(edited.colors,
        [Color(teachingPalette.first), Color(examPalette.first)]);
    expect(edited.textColor, const Color(0xffb93642));
    expect(teachingPalette.toSet().length, 9);
    expect(examPalette.toSet().length, 9);
  });
  test('期間の色と記号は登録順や保存色ではなく早い順で対応する', () {
    final school = data();
    school.rows('events').clear();
    for (final kind in ['teaching', 'exam']) {
      for (var i = 9; i >= 0; i--) {
        school.rows('events').add({
          'id': '$kind-$i',
          'kind': kind,
          'start_date': dayKey(shiftDay(date, i)),
          'end_date': dayKey(shiftDay(date, 12)),
          'color': 0xff123456
        });
      }
    }
    school.rows('settings').add({'id': 'accessibility_marks', 'value': '1'});
    expect(eventColor(school, school.find('events', 'teaching-0')!),
        Color(teachingPalette.first));
    expect(eventColor(school, school.find('events', 'exam-9')!),
        Color(examPalette.first));
    final marks = calendarMarks(school, shiftDay(date, 12), editing: true)
        .cast<StatusMark>()
        .toList();
    expect(marks, hasLength(20));
    expect(marks.where((m) => m.filled), hasLength(10));
    expect(marks.where((m) => !m.filled), hasLength(10));
    expect(marks.map((m) => m.shape).toSet().length, 9);
  });
  test('閲覧の代替講義は星と中心の丸、試験は中空の丸で識別する', () {
    final school = data(active: true, replacement: true);
    school.rows('settings').add({'id': 'accessibility_marks', 'value': '1'});
    final mark =
        calendarMarks(school, date, editing: false).single as StatusMark;
    expect(mark.shape, 6);
    expect(mark.centerDot, isTrue);
    expect(mark.filled, isFalse);
    school.rows('meetings').single['exam_period_id'] = 'exam';
    final exam =
        calendarMarks(school, date, editing: false).single as StatusMark;
    expect(exam.shape, 0);
    expect(exam.filled, isFalse);
    expect(calendarMarks(data(active: true), date, editing: false), isEmpty);
  });
}
