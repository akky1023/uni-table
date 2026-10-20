import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'app_palette.dart';
import 'calendar_style.dart';

class ColorPalette extends StatelessWidget {
  final int color;
  final ValueChanged<int> onChanged;
  const ColorPalette({super.key, required this.color, required this.onChanged});
  static final colors = <int>{
    ...teachingPalette,
    ...examPalette,
    ...paletteDefaults(true).values,
    ...defaultCalendarColors.values,
    0xffd45459,
    0xffc98b40,
    0xffccbd5d,
    0xff398b72,
    0xff5797c5,
    0xff8864b2,
    0xffffffff,
    0xffcccccc,
    0xff777777,
    0xff222222,
  }.toList();
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                  color: Color(color),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant))),
          const SizedBox(width: 12),
          Text(
              '#${(color & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}')
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final value in colors)
            Semantics(
                button: true,
                selected: color == value,
                label: strings.colorNumber(value.toRadixString(16)),
                child: InkWell(
                    key: ValueKey('palette-$value'),
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => onChanged(value),
                    child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: Color(value),
                            borderRadius: BorderRadius.circular(4),
                            border: color == value
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : null),
                        child: color == value
                            ? Icon(Icons.check,
                                size: 18,
                                color: Color(value).computeLuminance() > .5
                                    ? Colors.black
                                    : Colors.white)
                            : null)))
        ]),
        Row(children: [
          Text(strings.opacity),
          Expanded(
              child: Slider(
                  value: ((color >> 24) & 255).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (v) =>
                      onChanged((v.round() << 24) | (color & 0xffffff))),
          ),
      ],
      ),
    ],
  );
}
