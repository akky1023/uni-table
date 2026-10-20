# ビルド・開発手順

[README](README.md)に戻る。変更の提出方法・コミット形式・自動バージョン管理の仕様は[コントリビュータ向けガイド](CONTRIBUTING.md)を参照してください。

## 必要なもの

- Flutter SDK（動作確認: 3.47.7）
- Windows版: Visual StudioのC++ビルドツール
- Android版: Android SDK、JDK
- Windowsインストーラーの作成: Inno Setup

## 起動・検証

```powershell
flutter pub get
flutter run -d windows
# Androidは接続した端末を指定
flutter run -d <device-id>

flutter analyze
flutter test
```

## リリースビルド（Windows / PowerShell）

```powershell
# 必要に応じてビルド環境を準備
.\scripts\setup-windows.ps1
.\scripts\setup-android.ps1 -AcceptLicenses

# 両プラットフォームをビルド
.\scripts\build-release.ps1 -Target all
# 通常版とデバッグ用機能付きのAPK・Windowsインストーラー・ZIPをビルド
.\scripts\build-release.ps1 -Target all -IncludeDebugBuilds
# 個別指定: -Target windows / -Target android
```

ビルドスクリプトは`.tools/flutter`のSDKを優先し、なければPATH上のFlutterを使用します。成果物とSHA-256チェックサムは`dist/`に出力します。

Androidは`--split-per-abi`でCPU別にビルドし、`UniTable-<version>-android-<abi>.apk`を出力します。端末に合うAPKを1つインストールしてください。64bit ARM端末は`arm64-v8a`、32bit ARM端末は`armeabi-v7a`、x86の64bit端末・エミュレーターは`x86_64`を選びます。CPUを分けてもAndroidのビルド番号は`pubspec.yaml`の値を共通で使用します。

`build-release.ps1`をローカルで実行すると、アプリ内のバージョンと成果物名は`test+1.0.1`の形式になります（番号は`pubspec.yaml`から取得）。Androidのバージョン名にも同じ表記を使用します。GitHub Actions上、または`-OfficialRelease`指定時は通常の番号を使用します。Flutterを直接実行する場合は`--dart-define=UNITABLE_LOCAL_BUILD=true`を指定してください。

GitHubのリリース作成・下書きリリース復旧では、通常版とデバッグ版を両方ビルドして配布します。デバッグ版のファイル名は `UniTable-<version>-android-<abi>-debug.apk`、`UniTable-<version>-windows-x64-debug-setup.exe`、`UniTable-<version>-windows-x64-debug.zip` です。通常版と同じ署名・チェックサム・来歴証明の対象になります。AndroidはアプリID末尾の `.debug`、Windowsはインストール先・ショートカット・端末設定の保存先で通常版と分離します。

確認用の未署名MSIXは次のコマンドで作成できます。Windows SDKのMakeAppxを使用し、証明書のインストールは行いません。配布・通常のインストール用には署名の準備が必要です。

```powershell
.\scripts\build-msix.ps1
# Windowsリリースをビルド済みの場合: -SkipBuild
```

Androidの署名情報は`android/key.properties`または`.tools/signing/android-key.properties`から読み込みます。[設定例](android/key.properties.example)を参照してください。ビルドスクリプトは未設定の開発環境では署名鍵を生成します。公式配布の更新には同じ鍵が必要なため、既存の署名鍵は別途保管し、Gitには登録しません。

署名証明書の制作者名は`akky_1023`、組織名は`Neomenia`、国は`JP`、ドメインはSANの`DNS:neomenia.net`です。公式配布用の公開証明書は`android/release-signing-certificate.pem`に保存し、CIでは秘密鍵を復元した後に適用します。証明書の適用処理は公開鍵の一致を確認し、変更前のキーストアを同じディレクトリにバックアップします。旧証明書のAPKからは通常の上書き更新ができないため、入れ替えが必要です。

## ディレクトリ

| 場所 | 内容 |
| --- | --- |
| `lib/data/` | SQLiteとファイル管理 |
| `lib/domain/` | 時間割・期間・期限の計算 |
| `lib/services/` | 通知 |
| `lib/ui/` | 画面・テーマ・操作 |
| `test/` | 自動テスト |
| `assets/` | フォント・祝日データ |
| `assets/icons/` | アプリアイコンのSVG原本・各解像度のWebP / PNG（[利用・再生成方法](assets/icons/README.md)） |
| `scripts/`, `packaging/` | 開発・配布用スクリプト |

## 通知テスト用APK

通知テスト用APKは `flutter build apk --release --dart-define=UNITABLE_NOTIFICATION_TEST=true` で作成できます。アプリIDは `net.neomenia.unitable.debug`、表示名は「うに時間割（通知テスト）」となり、通常版と別々にインストールできます。設定の「通知」で科目を選び、即時・30秒後・5分後の課題確認通知を試せます。通常ビルドにはテストボタンを表示しません。
