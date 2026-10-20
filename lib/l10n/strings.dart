import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

// Shared with storage errors and scheduled notifications, which have no context.
// Japanese is the fallback for domain code used before the app is initialized.
AppLocalizations strings = lookupAppLocalizations(const Locale('ja'));

Locale resolveAppLocale(String preference, Locale deviceLocale) {
  final language = preference == 'system'
      ? deviceLocale.languageCode
      : preference;
  return AppLocalizations.supportedLocales.firstWhere(
    (locale) => locale.languageCode == language,
    orElse: () => const Locale('ja'),
  );
}

void setAppLocale(Locale locale) {
  strings = lookupAppLocalizations(locale);
}

// Pass actual boundary years to the catalog; each language controls which years
// to display. January-start academic years stay within a single calendar year.
String academicYearLabel(DateTime start, DateTime end) => start.year == end.year
    ? strings.academicYearSingle(start.year)
    : strings.academicYearRange(start.year, end.year);
