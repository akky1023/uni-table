import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/schedule.dart';
import 'app_palette.dart';

Widget themedSurface(ThemeData theme, Widget child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(
        value: (theme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false),
        child: Theme(data: theme, child: child));

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color surfaceTint(BuildContext context, Color light) {
  if (!isDark(context)) return light;
  if (light.a == 0) return Colors.transparent;
  // Retain the hue that conveys meaning while reducing the lightness.
  final hsl = HSLColor.fromColor(light);
  return hsl
      .withSaturation((hsl.saturation * .7).clamp(0.0, .55))
      .withLightness((.14 + hsl.lightness * .09).clamp(.14, .24))
      .toColor();
}

Color mutedText(BuildContext context,
        {bool stronger = false}) =>
    isDark(context)
        ? (stronger
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .8)
            : Theme.of(context).disabledColor)
        : (stronger
            ? const Color(0xff515651)
            : Theme.of(context).disabledColor);

ThemeData darkAppearance(ThemeData base, {required bool oled}) {
  final background = oled ? Colors.black : const Color(0xff141b17);
  final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xff398b72),
          brightness: Brightness.dark,
          surface: background)
      .copyWith(
          primary: const Color(0xff91d2b7),
          secondary: const Color(0xff91d2b7),
          onPrimary: const Color(0xff12382b),
          secondaryContainer: const Color(0xff28473b),
          onSecondaryContainer: const Color(0xffc5ecd9),
          surfaceContainerLowest: oled ? Colors.black : const Color(0xff101713),
          surfaceContainerLow: oled ? Colors.black : const Color(0xff19221c),
          onSurface: const Color(0xffe0e9e2),
          onSurfaceVariant: const Color(0xffb9c8bf));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Noto Sans JP',
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0),
    canvasColor: background,
    navigationBarTheme: NavigationBarThemeData(backgroundColor: background),
    drawerTheme: DrawerThemeData(backgroundColor: background),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    floatingActionButtonTheme: base.floatingActionButtonTheme,
    inputDecorationTheme:
        base.inputDecorationTheme.copyWith(fillColor: const Color(0xff25312a)),
    dividerTheme:
        const DividerThemeData(color: Color(0xff354139), thickness: 1),
    dialogTheme:
        const DialogThemeData(elevation: 0, backgroundColor: Color(0xff1c2620)),
    bottomSheetTheme:
        const BottomSheetThemeData(backgroundColor: Color(0xff1c2620)),
  );
}

ThemeData paletteAppearance(ThemeData base, SchoolData data,
    {required bool dark, required bool oled}) {
  final colors = appPalette(data, dark);
  Color c(String key) => Color(colors[key]!);
  final background = dark && oled ? Colors.black : c('background');
  final scheme = base.colorScheme.copyWith(
      primary: c('primary'),
      secondary: c('primary'),
      onPrimary: c('on_primary'),
      onSecondary: c('on_primary'),
      onSurface: c('text'),
      onSurfaceVariant: c('text').withValues(alpha: .85),
      surface: background,
      surfaceContainerLow: dark && oled ? Colors.black : c('panel'),
      secondaryContainer: c('accent_container'),
      onSecondaryContainer: c('accent_text'),
      primaryContainer: c('accent_container'),
      onPrimaryContainer: c('accent_text'),
      outlineVariant: c('outline'));
  return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      disabledColor: c('muted'),
      textTheme:
          base.textTheme.apply(bodyColor: c('text'), displayColor: c('text')),
      appBarTheme: base.appBarTheme
          .copyWith(backgroundColor: background, foregroundColor: c('text')),
      navigationBarTheme:
          base.navigationBarTheme.copyWith(backgroundColor: background),
      drawerTheme: base.drawerTheme
          .copyWith(backgroundColor: dark && oled ? Colors.black : c('panel')),
      inputDecorationTheme:
          base.inputDecorationTheme.copyWith(fillColor: c('input')),
      dividerTheme: base.dividerTheme.copyWith(color: c('outline')),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: c('dialog')),
      bottomSheetTheme:
          base.bottomSheetTheme.copyWith(backgroundColor: c('dialog')));
}
