import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitable/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ビルド時のバージョンを優先し未指定なら端末のアプリ情報から取得する', () async {
    const buildVersion = String.fromEnvironment('FLUTTER_BUILD_NAME');
    PackageInfo.setMockInitialValues(
      appName: 'うに時間割',
      packageName: 'net.neomenia.unitable',
      version: '2.4.6',
      buildNumber: '18',
      buildSignature: '',
    );
    expect(
      await loadAppVersion(),
      '${const bool.fromEnvironment('UNITABLE_LOCAL_BUILD') ? 'test+' : ''}'
      '${buildVersion.isEmpty ? '2.4.6' : buildVersion}',
    );
  });
  test('配布版の番号はpubspecだけで管理しMSIXの手動指定を残さない', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^+\s]+)\+\d+',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(version, matches(r'^\d+\.\d+\.\d+$'));
    final manifest =
        jsonDecode(File('.release-please-manifest.json').readAsStringSync())
            as Map;
    expect(version, manifest['.'], reason: 'Release Pleaseとアプリのバージョンを一致させる');
    expect(pubspec, isNot(contains('msix_version:')));
  });
}
