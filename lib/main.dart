import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'app_info.dart';
import 'data/database.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/strings.dart';
import 'ui/accessibility.dart';
import 'ui/storage_gate.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.contains('--verify-installation')) {
    final temporary =
        await Directory.systemTemp.createTemp('unitable-install-check-');
    UnitDatabase? check;
    try {
      // Exercise packaged native SQLite and path-provider through the real runner.
      final support = await getApplicationSupportDirectory();
      final version = await loadAppVersion();
      check = UnitDatabase.open('${temporary.path}/check.unitable');
      check.transaction(
          () => check!.put('courses', {'id': 'check', 'name': '動作確認'}));
      if (check.data.rows('courses').single['name'] != '動作確認') {
        throw StateError('SQLite round-trip failed');
      }
      final output =
          arguments.where((a) => a.startsWith('--report=')).firstOrNull;
      if (output != null) {
        await File(output.substring(9)).writeAsString(jsonEncode({
          'ok': true,
          'sqlite': true,
          'supportDirectory': support.path,
          'appVersion': version,
          'debugFeatures': const bool.fromEnvironment('UNITABLE_NOTIFICATION_TEST'),
        }));
      }
      check.dispose();
      check = null;
      await temporary.delete(recursive: true);
      exit(0);
    } catch (e) {
      check?.dispose();
      final output =
          arguments.where((a) => a.startsWith('--report=')).firstOrNull;
      if (output != null) {
        await File(output.substring(9))
            .writeAsString(jsonEncode({'ok': false, 'error': e.toString()}));
      }
      exit(1);
    }
  }
  setAppLocale(
    resolveAppLocale(
      'system',
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
  );
  final storage = Storage();
  Object? error;
  try {
    await storage.initialize();
  } catch (e) {
    error = e;
  }
  runApp(UniTableApp(storage: storage, startupError: error));
}

class UniTableApp extends StatefulWidget {
  final Storage storage;
  final Object? startupError;
  const UniTableApp({super.key, required this.storage, this.startupError});
  @override
  State<UniTableApp> createState() => _UniTableAppState();
}

class _UniTableAppState extends State<UniTableApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.storage.addListener(changed);
    updateLanguage();
  }

  void updateLanguage() => setAppLocale(
    resolveAppLocale(
      widget.storage.localSettings['language'] ?? 'system',
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
  );

  void changed() {
    updateLanguage();
    setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) => changed();

  @override
  void didUpdateWidget(UniTableApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storage != widget.storage) {
      oldWidget.storage.removeListener(changed);
      widget.storage.addListener(changed);
      updateLanguage();
    }
  }

  @override
  void dispose() {
    widget.storage.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: strings.appName,
        builder: (context, child) =>
            AccessibilityScope(storage: widget.storage, child: child!),
        debugShowCheckedModeBanner: false,
        scrollBehavior:
            const MaterialScrollBehavior().copyWith(scrollbars: false),
        locale: Locale(strings.localeName),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Noto Sans JP',
          colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xff398b72),
                  surface: const Color(0xfffcfdfb))
              .copyWith(
                  primary: const Color(0xff398b72),
                  secondary: const Color(0xff398b72),
                  secondaryContainer: const Color(0xffd9f0e5)),
          scaffoldBackgroundColor: const Color(0xfffcfdfb),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xfffcfdfb),
              elevation: 0,
              scrolledUnderElevation: 0),
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0),
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xffeef5f0),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          dividerTheme:
              const DividerThemeData(color: Color(0xffe3e5df), thickness: 1),
          dialogTheme: const DialogThemeData(elevation: 0),
        ),
        home: StorageGate(storage: widget.storage, error: widget.startupError),
      );
}
