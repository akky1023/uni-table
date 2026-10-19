import 'package:package_info_plus/package_info_plus.dart';

// 「設定 → このアプリについて」に表示する情報です。
// 制作者名・各URLを変更するときは、下の定数を書き換えてください。
const appAuthorName = 'akky_1023';
const appAuthorWebsite = 'https://neomenia.net/';
const appAuthorGitHub = 'https://github.com/akky1023';
const appRepository = 'https://github.com/akky1023/uni-table';

// バージョンをここへ直書きしないでください。
// Release Pleaseが更新するpubspec.yamlのバージョンをFlutterが埋め込みます。
// 埋め込み値のない実行環境では、端末側のアプリ情報を利用します。
Future<String> loadAppVersion() async {
  const version = String.fromEnvironment('FLUTTER_BUILD_NAME');
  final value = version.isNotEmpty
      ? version
      : (await PackageInfo.fromPlatform()).version;
  return const bool.fromEnvironment('UNITABLE_LOCAL_BUILD') &&
          !value.startsWith('test+')
      ? 'test+$value'
      : value;
}
