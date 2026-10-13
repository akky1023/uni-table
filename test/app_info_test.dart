import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/app_info.dart';

void main() {
  test('表示バージョンとAndroid・Windows配布バージョンを一致させる', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([^+\s]+)\+\d+', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);
    final msix = RegExp(r'^\s+msix_version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);
    expect(appVersion, version);
    expect(msix, '$appVersion.0');
  });
}
