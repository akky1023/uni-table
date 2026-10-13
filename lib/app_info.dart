import 'package:package_info_plus/package_info_plus.dart';

// 「設定 → このアプリについて」に表示する情報です。
// 制作者名・各URLを変更するときは、下の定数を書き換えてください。
const appAuthorName = 'akky_1023';
const appAuthorWebsite = 'https://neomenia.net/';
const appAuthorGitHub = 'https://github.com/akky1023';
const appRepository = 'https://github.com/akky1023/uni-table';

// バージョンをここへ直書きしないでください。
// Release Pleaseがpubspec.yamlを更新し、ビルドされたアプリの情報から取得します。
Future<String> loadAppVersion() async =>
    (await PackageInfo.fromPlatform()).version;
