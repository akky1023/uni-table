import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('表示バージョンをソースへ直書きせずアプリの情報から取得する', () async {
    PackageInfo.setMockInitialValues(
        appName: 'うに時間割',
        packageName: 'net.neomenia.unitable',
        version: '2.4.6',
        buildNumber: '18',
        buildSignature: '');
    expect(await loadAppVersion(), '2.4.6');
  });
  test('配布版の番号はpubspecだけで管理しMSIXの手動指定を残さない', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([^+\s]+)\+\d+', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);
    expect(version, matches(r'^\d+\.\d+\.\d+$'));
    expect(pubspec, isNot(contains('msix_version:')));
  });
}
