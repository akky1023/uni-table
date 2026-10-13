import 'dart:io';
import 'package:flutter/material.dart';
import '../data/database.dart';
import 'appearance.dart';
import '../domain/schedule.dart';

class AppToggle extends StatelessWidget {
  final bool value, marks, still;
  final ValueChanged<bool>? onChanged;
  const AppToggle(
      {super.key,
      required this.value,
      required this.onChanged,
      this.marks = false,
      this.still = false});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = still ? Duration.zero : const Duration(milliseconds: 160);
    return Semantics(
        toggled: value,
        enabled: onChanged != null,
        child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: SizedBox(
                width: 52,
                height: 48,
                child: Center(
                    child: Opacity(
                        opacity: onChanged == null ? .4 : 1,
                        child: AnimatedContainer(
                            duration: duration,
                            width: 52,
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                                color: value
                                    ? scheme.primary
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16)),
                            child:
                                Stack(alignment: Alignment.center, children: [
                              if (marks)
                                Align(
                                    alignment: value
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            left: value ? 4 : 0,
                                            right: value ? 0 : 4),
                                        child: Icon(
                                            value ? Icons.check : Icons.close,
                                            size: 16,
                                            color: value
                                                ? scheme.onPrimary
                                                : scheme.onSurfaceVariant))),
                              AnimatedAlign(
                                  duration: duration,
                                  alignment: value
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(left: value ? 0 : 4),
                                      child: Container(
                                          width: value ? 24 : 16,
                                          height: value ? 24 : 16,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: value
                                                  ? scheme.onPrimary
                                                  : scheme.onSurfaceVariant)))),
                            ])))))));
  }
}

class AccessibilityScope extends StatelessWidget {
  final Storage storage;
  final Widget child;
  final bool? desktop;
  const AccessibilityScope(
      {super.key, required this.storage, required this.child, this.desktop});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: storage,
      builder: (context, _) => storage.hasDatabase
          ? AnimatedBuilder(
              animation: storage.database,
              builder: (context, _) {
                final data = storage.database.data;
                var base = Theme.of(context);
                final mode = data.setting('theme_mode', 'system');
                final night = mode == 'dark' ||
                    mode == 'system' &&
                        MediaQuery.platformBrightnessOf(context) ==
                            Brightness.dark;
                if (night) {
                  base = darkAppearance(base,
                      oled: data.setting('oled_black', '0') == '1');
                }
                base = paletteAppearance(base, data,
                    dark: night, oled: data.setting('oled_black', '0') == '1');
                final dark = data.setting('dark_text', '0') == '1';
                final still = data.setting('reduce_motion', '0') == '1';
                final textTheme = dark
                    ? outlinedText(base.textTheme, night: night)
                    : base.textTheme;
                final pc = desktop ?? (!Platform.isAndroid && !Platform.isIOS);
                final theme = base.copyWith(
                  colorScheme: dark
                      ? base.colorScheme.copyWith(
                          onSurface:
                              night ? Colors.white : const Color(0xff101510),
                          onSurfaceVariant: night
                              ? const Color(0xffe0e9e2)
                              : const Color(0xff182018))
                      : null,
                  textTheme: textTheme,
                  expansionTileTheme: base.expansionTileTheme.copyWith(
                      expansionAnimationStyle:
                          still ? AnimationStyle.noAnimation : null,
                      shape: const Border(),
                      collapsedShape: const Border()),
                  filledButtonTheme: FilledButtonThemeData(
                      style: (base.filledButtonTheme.style ??
                              const ButtonStyle())
                          .copyWith(
                              animationDuration: still ? Duration.zero : null,
                              textStyle: dark
                                  ? WidgetStatePropertyAll(base
                                      .textTheme.labelLarge
                                      ?.copyWith(shadows: [
                                      Shadow(
                                          color: base.colorScheme.onPrimary
                                                      .computeLuminance() >
                                                  .5
                                              ? const Color(0xff101510)
                                              : Colors.white,
                                          offset: const Offset(-.65, 0)),
                                      Shadow(
                                          color: base.colorScheme.onPrimary
                                                      .computeLuminance() >
                                                  .5
                                              ? const Color(0xff101510)
                                              : Colors.white,
                                          offset: const Offset(.65, 0)),
                                      Shadow(
                                          color: base.colorScheme.onPrimary
                                                      .computeLuminance() >
                                                  .5
                                              ? const Color(0xff101510)
                                              : Colors.white,
                                          offset: const Offset(0, -.65)),
                                      Shadow(
                                          color: base.colorScheme.onPrimary
                                                      .computeLuminance() >
                                                  .5
                                              ? const Color(0xff101510)
                                              : Colors.white,
                                          offset: const Offset(0, .65)),
                                    ]))
                                  : null)),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                      style: base.outlinedButtonTheme.style?.copyWith(
                              animationDuration:
                                  still ? Duration.zero : null) ??
                          ButtonStyle(
                              animationDuration: still ? Duration.zero : null)),
                  textButtonTheme: TextButtonThemeData(
                      style: base.textButtonTheme.style?.copyWith(
                              animationDuration:
                                  still ? Duration.zero : null) ??
                          ButtonStyle(
                              animationDuration: still ? Duration.zero : null)),
                  iconButtonTheme: IconButtonThemeData(
                      style: base.iconButtonTheme.style?.copyWith(
                              animationDuration:
                                  still ? Duration.zero : null) ??
                          ButtonStyle(
                              animationDuration: still ? Duration.zero : null)),
                  splashFactory: pc || still ? NoSplash.splashFactory : null,
                  highlightColor: pc ? Colors.transparent : null,
                  tooltipTheme: pc
                      ? const TooltipThemeData(
                          triggerMode: TooltipTriggerMode.manual)
                      : base.tooltipTheme,
                  pageTransitionsTheme:
                      data.setting('reduce_motion', '0') == '1'
                          ? const PageTransitionsTheme(builders: {
                              TargetPlatform.android: StillTransition(),
                              TargetPlatform.windows: StillTransition(),
                              TargetPlatform.iOS: StillTransition()
                            })
                          : base.pageTransitionsTheme,
                );
                return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        disableAnimations:
                            data.setting('reduce_motion', '0') == '1' ||
                                MediaQuery.of(context).disableAnimations,
                        accessibleNavigation:
                            data.setting('reduce_motion', '0') == '1' ||
                                MediaQuery.of(context).accessibleNavigation),
                    child: themedSurface(theme, child));
              })
          : initialAppearance(context, storage, child));
}

TextTheme outlinedText(TextTheme source, {bool night = false}) {
  final ink = night ? Colors.white : const Color(0xff101510);
  final edge = night ? Colors.black : Colors.white;
  TextStyle? outline(TextStyle? style) => style?.copyWith(color: ink, shadows: [
        Shadow(color: edge, offset: const Offset(-.65, 0)),
        Shadow(color: edge, offset: const Offset(.65, 0)),
        Shadow(color: edge, offset: const Offset(0, -.65)),
        Shadow(color: edge, offset: const Offset(0, .65)),
        Shadow(color: edge, offset: const Offset(-.5, -.5)),
        Shadow(color: edge, offset: const Offset(.5, .5)),
        Shadow(color: edge, offset: const Offset(-.5, .5)),
        Shadow(color: edge, offset: const Offset(.5, -.5)),
      ]);
  return TextTheme(
      displayLarge: outline(source.displayLarge),
      displayMedium: outline(source.displayMedium),
      displaySmall: outline(source.displaySmall),
      headlineLarge: outline(source.headlineLarge),
      headlineMedium: outline(source.headlineMedium),
      headlineSmall: outline(source.headlineSmall),
      titleLarge: outline(source.titleLarge),
      titleMedium: outline(source.titleMedium),
      titleSmall: outline(source.titleSmall),
      bodyLarge: outline(source.bodyLarge),
      bodyMedium: outline(source.bodyMedium),
      bodySmall: outline(source.bodySmall),
      labelLarge: outline(source.labelLarge),
      labelMedium: outline(source.labelMedium),
      labelSmall: outline(source.labelSmall));
}

class StillTransition extends PageTransitionsBuilder {
  const StillTransition();
  @override
  Widget buildTransitions<T>(
          PageRoute<T> route,
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) =>
      child;
}

ChipAnimationStyle? chipMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
        ? ChipAnimationStyle(
            enableAnimation: AnimationStyle.noAnimation,
            selectAnimation: AnimationStyle.noAnimation,
            avatarDrawerAnimation: AnimationStyle.noAnimation,
            deleteDrawerAnimation: AnimationStyle.noAnimation)
        : null;

Widget initialAppearance(BuildContext context, Storage storage, Widget child) {
  final mode = storage.localSettings['theme_mode'] ?? 'system';
  final night = mode == 'dark' ||
      mode == 'system' &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  final data = SchoolData({
    'settings': [
      for (final entry in storage.localSettings.entries)
        {'id': entry.key, 'value': entry.value}
    ]
  });
  return themedSurface(
      paletteAppearance(
          night
              ? darkAppearance(Theme.of(context),
                  oled: storage.localSettings['oled_black'] == '1')
              : Theme.of(context),
          data,
          dark: night,
          oled: storage.localSettings['oled_black'] == '1'),
      child);
}
