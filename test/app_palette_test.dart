import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/domain/schedule.dart';
import 'package:unitable/ui/app_palette.dart';
import 'package:unitable/ui/calendar_style.dart';

void main() {
  test('ライトとダークの変更は独立し保存したRGBAをそのまま使う', () {
    final data = SchoolData({'settings': []});
    final darkBefore = Map.of(appPalette(data, true));
    data.rows('settings').add({
      'id': 'ui_palette_light',
      'value':
          jsonEncode({'lecture': 0x7f123456, 'calendar_active': 0xffabcdef})
    });
    expect(paletteValue(data, 'lecture'), 0x7f123456);
    expect(appPalette(data, true), darkBefore);
    data.rows('settings').add({
      'id': 'ui_palette_dark',
      'value':
          jsonEncode({'lecture': 0xff334455, 'calendar_active': 0xff112233})
    });
    expect(paletteValue(data, 'lecture', dark: true), 0xff334455);
    expect(calendarColors(data, dark: true)['active'], 0xff112233);
    expect(calendarColors(data)['active'], 0xffabcdef);
  });
  test('期間9色はモード別の設定を使い10番目から循環する', () {
    final data = SchoolData({
      'settings': [
        {
          'id': 'ui_palette_dark',
          'value': '{"teaching_0":4279383126,"exam_0":4281558681}'
        }
      ],
      'events': [
        for (var i = 0; i < 10; i++)
          {
            'id': '$i',
            'kind': 'teaching',
            'start_date': '2026-01-${(i + 1).toString().padLeft(2, '0')}',
            'end_date': '2026-12-31'
          }
      ]
    });
    expect(eventColor(data, data.rows('events').first, dark: true),
        const Color(0xff123456));
    expect(eventColor(data, data.rows('events').last, dark: true),
        const Color(0xff123456));
    expect(eventColor(data, data.rows('events').first),
        Color(periodTeachingColors.first));
  });
  test('旧年間背景設定を引き継ぎ新しいパレット設定を優先する', () {
    final data = SchoolData({
      'settings': [
        {'id': 'calendar_colors', 'value': '{"past":4279383126}'},
        {'id': 'ui_palette_light', 'value': '{"calendar_past":4281558681}'}
      ]
    });
    expect(calendarColors(data)['past'], 0xff336699);
  });
}
