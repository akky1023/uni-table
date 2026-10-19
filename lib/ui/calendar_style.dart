import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/schedule.dart';
import '../l10n/strings.dart';
import 'app_palette.dart';
import 'status_marks.dart';

const teachingPalette = [
  0xffd4ead7,
  0xffb9d9c5,
  0xffdcebc2,
  0xffb9dcd6,
  0xffc6dfb1,
  0xffd4e8d0,
  0xffb6d3bc,
  0xffc1e2ce,
  0xffd8e5b9
];
const examPalette = [
  0xffe4d9f3,
  0xffd0c2e7,
  0xffe7d2ed,
  0xffc8ccec,
  0xffddbee4,
  0xffd8d0ee,
  0xffe9d9e7,
  0xffccc0df,
  0xffdec9f0
];

Map<String, String> get calendarRuleLabels => {
  'past': strings.pastDates,
  'exam_day': strings.examDay,
  'replacement_active': strings.replacementActive,
  'active': strings.activeDay,
  'national': strings.nationalHoliday,
  'closure_period': strings.closurePeriod,
  'holiday': strings.definedHoliday,
  'exam_period': strings.examPeriod,
  'replacement': strings.replacementDay,
  'teaching_period': strings.teachingPeriod,
};
const defaultCalendarColors = {
  'past': 0xffeeeeee,
  'exam_day': 0xffe4d9f3,
  'replacement_active': 0xfff6d3a4,
  'active': 0xffd9eedf,
  'national': 0xfff6d2d4,
  'closure_period': 0xfff6d2d4,
  'holiday': 0x00ffffff,
  'exam_period': 0xfff2edf9,
  'replacement': 0xfffcebd7,
  'teaching_period': 0xfff0f8f2,
};

List<String> calendarOrder(SchoolData data) {
  final saved =
      (jsonDecode(data.setting('calendar_order', '[]')) as List).cast<String>();
  if (saved.isNotEmpty && !saved.contains('closure_period')) {
    saved.insert(saved.indexOf('national') + 1, 'closure_period');
  }
  return {
    ...saved.where(calendarRuleLabels.containsKey),
    ...calendarRuleLabels.keys
  }.toList();
}

Map<String, int> calendarColors(SchoolData data, {bool dark = false}) => {
      for (final key in calendarRuleLabels.keys)
        key: paletteValue(data, 'calendar_$key', dark: dark)
    };

bool isReplacementDate(SchoolData data, DateTime date) {
  final engine = ScheduleEngine(data);
  return (engine.dayChange(date)?['source_weekday'] != null &&
          engine.dayChange(date)?['cancelled'] != 1) ||
      data
          .rows('day_changes')
          .any((d) => d['replacement_date'] == dayKey(date)) ||
      engine.onDay(date).any((s) => s.replacement);
}

Color eventColor(SchoolData data, DbRow event, {bool dark = false}) {
  final kind = event['kind'];
  if (kind == 'holiday') {
    return Color(paletteValue(data, 'calendar_closure_period', dark: dark));
  }
  final index = eventIndex(data, event);
  return Color(paletteValue(data,
      '${kind == 'exam' ? 'exam' : 'teaching'}_${(index < 0 ? 0 : index) % 9}',
      dark: dark));
}

int eventIndex(SchoolData data, DbRow event) {
  final peers = data
      .rows('events')
      .where((e) => e['kind'] == event['kind'])
      .toList()
    ..sort((a, b) => '${a['start_date']}:${a['id']}'
        .compareTo('${b['start_date']}:${b['id']}'));
  return peers.indexWhere((e) => e['id'] == event['id']);
}

List<Widget> calendarMarks(SchoolData data, DateTime date,
    {required bool editing, Color? color}) {
  if (data.setting('accessibility_marks', '0') != '1') return [];
  final engine = ScheduleEngine(data);
  final sessions = engine.onDay(date, includeCancelled: false);
  final replacement = isReplacementDate(data, date);
  final ink = color ?? const Color(0xff273b31);
  if (editing) {
    final events = data
        .rows('events')
        .where((e) => engine.contains(e, date))
        .toList()
      ..sort((a, b) => '${a['kind']}:${a['start_date']}:${a['id']}'
          .compareTo('${b['kind']}:${b['start_date']}:${b['id']}'));
    return [
      for (final e in events)
        if (e['kind'] != 'holiday')
          StatusMark(
              size: 8,
              shape: eventIndex(data, e) % 9,
              filled: e['kind'] == 'teaching',
              color: ink,
              label:
                '${e['kind'] == 'exam' ? strings.examPeriod : strings.teachingPeriod} ${eventIndex(data, e) + 1}',
          ),
      if (events.any((e) => e['kind'] == 'holiday') || engine.isClosed(date))
        StatusMark(shape: 9, color: ink, label: strings.closure),
      if (replacement)
        StatusMark(shape: 6, filled: false, color: ink, label: strings.replacementDay,
        )
    ];
  }
  return [
    if (sessions.any((s) => s.meeting['exam_period_id'] != null) ||
        engine.dayChange(date)?['exam_day'] == 1 ||
        data.rows('events').any((e) =>
            e['kind'] == 'exam' &&
            e['start_date'] == e['end_date'] &&
            engine.contains(e, date)))
      StatusMark(filled: false, color: ink, label: strings.examDay)
    else if (replacement)
      StatusMark(
          shape: 6,
          filled: false,
          centerDot: sessions.isNotEmpty,
          color: ink,
          label: sessions.isNotEmpty ? strings.replacementActive
            : strings.replacementDay,
      )
    else if (sessions.isNotEmpty)
      StatusMark(color: ink, label: strings.activeDay)
    else if (engine.isClosed(date) || engine.isHoliday(date))
      StatusMark(shape: 9, color: ink, label: strings.closure)
  ];
}

int nextEventColor(SchoolData data, String kind, {String? excluding}) {
  if (kind == 'holiday') return 0xfff6d2d4;
  final palette = kind == 'exam' ? examPalette : teachingPalette;
  final used = data
      .rows('events')
      .where((e) => e['kind'] == kind && e['id'] != excluding)
      .map((e) => eventColor(data, e).toARGB32())
      .toList();
  var result = palette.first;
  var minimum = used.length + 1;
  for (final color in palette) {
    final count = used.where((v) => v == color).length;
    if (count < minimum) {
      result = color;
      minimum = count;
    }
  }
  return result;
}

class CalendarPaint {
  final List<Color> colors;
  final Color? textColor;
  final String? rule;
  const CalendarPaint(this.colors, this.textColor, this.rule);
}

CalendarPaint calendarPaint(SchoolData data, DateTime date,
    {required bool editing, bool dark = false}) {
  final engine = ScheduleEngine(data), change = engine.dayChange(date);
  final events =
      data.rows('events').where((e) => engine.contains(e, date)).toList();
  final national = change?['is_national'] == 1;
  final past = date.isBefore(dateOnly(DateTime.now()));
  final today = dayKey(date) == dayKey(DateTime.now());
  final replacement = isReplacementDate(data, date);
  final active = engine.onDay(date, includeCancelled: false).isNotEmpty;
  if (editing) {
    final bands = [
      for (final event in events) eventColor(data, event, dark: dark),
      if (replacement)
        Color(paletteValue(data, 'calendar_replacement_active', dark: dark))
    ];
    return CalendarPaint(
        bands.isEmpty
            ? [Color(paletteValue(data, 'background', dark: dark))]
            : bands,
        national ? const Color(0xffb93642) : null,
        bands.isEmpty ? 'empty' : null);
  }
  final matches = {
    'past': past,
    'exam_day': engine
            .onDay(date, includeCancelled: false)
            .any((s) => s.meeting['exam_period_id'] != null) ||
        change?['exam_day'] == 1 ||
        events.any(
            (e) => e['kind'] == 'exam' && e['start_date'] == e['end_date']),
    'replacement_active': replacement && active,
    'active': active,
    'national': national,
    'closure_period': events.any((e) => e['kind'] == 'holiday'),
    'holiday': engine.isHoliday(date),
    'exam_period': events.any((e) => e['kind'] == 'exam'),
    'replacement': replacement,
    'teaching_period': events.any((e) => e['kind'] == 'teaching'),
  };
  final rule =
      calendarOrder(data).where((key) => matches[key] == true).firstOrNull;
  var color = Color(calendarColors(data, dark: dark)[rule] ?? 0x00ffffff);
  if (today) color = Color.alphaBlend(const Color(0x12000000), color);
  return CalendarPaint(
      [color],
      past
          ? const Color(0xffa0a0a0)
          : national
              ? const Color(0xffb93642)
              : null,
      rule);
}

class CalendarCellSurface extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  const CalendarCellSurface(
      {super.key, required this.colors, required this.child});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(children: [
        Positioned.fill(
            child: Column(children: [
          for (final color in colors)
            Expanded(
                child:
                    ColoredBox(color: color, child: const SizedBox.expand())),
        ])),
        child,
      ]));
}
