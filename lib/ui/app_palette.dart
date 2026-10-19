import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/schedule.dart';
import '../l10n/strings.dart';

Map<String, Map<String, String>> get paletteGroups => {
  strings.basic: {
    'background': strings.background,
    'text': strings.text,
    'muted': strings.mutedText,
    'primary': strings.accent,
    'on_primary': strings.onAccent,
    'panel': strings.menuBackground,
    'input': strings.inputField,
    'dialog': strings.popup,
    'accent_container': strings.selection,
    'accent_text': strings.selectionText,
    'outline': strings.divider,
    'holiday_text': strings.holidayText,
  },
  strings.timetable: {
    'empty': strings.freeTime,
    'lecture': strings.course,
    'exam': strings.exam,
    'single': strings.oneOffClass,
    'replacement': strings.replacementClass,
    'closure': strings.closure,
    'past': strings.pastDates,
  },
  strings.assignments: {'task': strings.assignments, 'task_selected': strings.selectedAssignment,
  },
  strings.annualCalendar: {
    'calendar_past': strings.pastDates,
    'calendar_exam_day': strings.examDay,
    'calendar_replacement_active': strings.replacementActive,
    'calendar_active': strings.activeDay,
    'calendar_national': strings.nationalHoliday,
    'calendar_closure_period': strings.closurePeriod,
    'calendar_holiday': strings.holiday,
    'calendar_exam_period': strings.examPeriod,
    'calendar_replacement': strings.replacementDay,
    'calendar_teaching_period': strings.teachingPeriod,
  },
};
const periodTeachingColors = [
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
const periodExamColors = [
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
const lightPalette = {
  'background': 0xfffcfdfb,
  'text': 0xff202920,
  'muted': 0xff929292,
  'primary': 0xff398b72,
  'on_primary': 0xffffffff,
  'panel': 0xfff0f4ee,
  'input': 0xffe0eae3,
  'dialog': 0xfffcfdfb,
  'accent_container': 0xffd9f0e5,
  'accent_text': 0xff163c2b,
  'outline': 0xffe3e5df,
  'holiday_text': 0xffb93642,
  'empty': 0xffeeeeee,
  'lecture': 0xffe0eee4,
  'exam': 0xffe4d9f3,
  'single': 0xffdbe8f8,
  'replacement': 0xfff6d3a4,
  'closure': 0xfff1b5b8,
  'past': 0xffeeeeee,
  'task': 0xffe2f1e8,
  'task_selected': 0xffc8e7d4,
  'calendar_past': 0xffeeeeee,
  'calendar_exam_day': 0xffe4d9f3,
  'calendar_replacement_active': 0xfff6d3a4,
  'calendar_active': 0xffd9eedf,
  'calendar_national': 0xfff6d2d4,
  'calendar_closure_period': 0xfff6d2d4,
  'calendar_holiday': 0x00ffffff,
  'calendar_exam_period': 0xfff2edf9,
  'calendar_replacement': 0xfffcebd7,
  'calendar_teaching_period': 0xfff0f8f2,
};

Color darkTint(Color light) {
  if (light.a == 0) return Colors.transparent;
  final hsl = HSLColor.fromColor(light);
  return hsl
      .withSaturation((hsl.saturation * .7).clamp(0.0, .55))
      .withLightness((.14 + hsl.lightness * .09).clamp(.14, .24))
      .toColor();
}

Map<String, int> paletteDefaults(bool dark) => {
      for (final entry in lightPalette.entries)
        entry.key: dark ? darkTint(Color(entry.value)).toARGB32() : entry.value,
      for (var i = 0; i < 9; i++) ...{
        'teaching_$i': dark
            ? darkTint(Color(periodTeachingColors[i])).toARGB32()
            : periodTeachingColors[i],
        'exam_$i': dark
            ? darkTint(Color(periodExamColors[i])).toARGB32()
            : periodExamColors[i],
      },
      if (dark) ...{
        'background': 0xff141b17,
        'text': 0xffe0e9e2,
        'muted': 0xff929b95,
        'primary': 0xff91d2b7,
        'on_primary': 0xff12382b,
        'panel': 0xff19221c,
        'input': 0xff25312a,
        'dialog': 0xff1c2620,
        'accent_container': 0xff28473b,
        'accent_text': 0xffc5ecd9,
        'outline': 0xff354139,
        'holiday_text': 0xffffa1a8,
        // Fade periods toward the background while preserving scheduled days.
        for (final key in [
          'calendar_teaching_period',
          'calendar_replacement',
          'calendar_exam_period',
        ])
          key: Color.alphaBlend(
            darkTint(Color(lightPalette[key]!)).withValues(alpha: .2),
            const Color(0xff141b17),
          ).toARGB32(),
      },
    };

final _paletteCache = Expando<Map<bool, (String, Map<String, int>)>>();

Map<String, int> appPalette(SchoolData data, bool dark) {
  final legacyRaw = data.setting('calendar_colors', '{}');
  final savedRaw =
      data.setting(dark ? 'ui_palette_dark' : 'ui_palette_light', '{}');
  final fingerprint = '$legacyRaw/$savedRaw';
  final cache = _paletteCache[data] ??= {};
  final previous = cache[dark];
  if (previous != null && previous.$1 == fingerprint) return previous.$2;
  final defaults = paletteDefaults(dark);
  final legacy = jsonDecode(legacyRaw) as Map;
  for (final entry in legacy.entries) {
    final key = 'calendar_${entry.key}';
    if (defaults.containsKey(key)) {
      defaults[key] = dark
          ? darkTint(Color(entry.value as int)).toARGB32()
          : entry.value as int;
    }
  }
  final saved = jsonDecode(savedRaw) as Map;
  final result = <String, int>{
    ...defaults,
    for (final entry in saved.entries)
      if (defaults.containsKey(entry.key))
        entry.key as String: entry.value as int
  };
  cache[dark] = (fingerprint, Map.unmodifiable(result));
  return cache[dark]!.$2;
}

int paletteValue(SchoolData data, String key, {bool dark = false}) =>
    appPalette(data, dark)[key]!;

Color appColor(BuildContext context, SchoolData data, String key) =>
    Color(paletteValue(data, key,
        dark: Theme.of(context).brightness == Brightness.dark));
