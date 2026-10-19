# うに時間割

大学生向けの、Android / Windowsで動作する時間割・課題・年間予定管理アプリです。Flutterで開発しています。アカウントやサーバーを使わず、端末内で動作します。

> READMEは公開準備中の骨子です。スクリーンショット・配布先・操作説明は今後追加します。

リポジトリ: [akky1023/uni-table](https://github.com/akky1023/uni-table)

## 主な機能

- 時間割: 講義期間別の時間割、日付別の試験時間割、単発講義、休講・代替日・教室変更
- 課題: 提出日時・提出先・メモ、時間割からの期限選択、完了管理、通知
- 年間予定: 講義・試験・休業期間、祝日、日ごとの変更、離れた複数の日程を持つ期間
- 表示設定: ライト / ダーク / 有機EL用の黒い背景、配色変更、文字サイズ、アクセシビリティ

## 対応環境・配布

- Android: Android 8.0（API 26）以上
- Windows: Windows 10 / 11、x64
- バージョン: [pubspec.yaml](pubspec.yaml)を参照
- 配布形式: APK、Windowsインストーラー、ポータブルZIP

配布先・インストール手順: **後日追加**。

## データの保存

初回起動時に、`.unitable`ファイルを選択または新規作成します。次回からは選択したファイルを開きます。

`.unitable`は暗号化しないSQLiteファイルです。時間割・課題・年間予定を保存します。設定と選択したファイルの場所は各端末に保存します。クラウド同期機能はありません。

バックアップは`.unitable`ファイルのコピーで行えます。旧形式のファイルは読み込み時に移行されるため、更新前のバックアップを推奨します。

## 開発

変更の提出方法・コミット形式・自動バージョン管理の仕様は[コントリビュータ向けガイド](CONTRIBUTING.md)を参照してください。Release Pleaseがコミット内容から次の版を決め、リリースPRのマージ後に検証・ビルド・配布を行います。

### 必要なもの

- Flutter SDK（動作確認: 3.47.7）
- Windows版: Visual StudioのC++ビルドツール
- Android版: Android SDK、JDK
- Windowsインストーラーの作成: Inno Setup

### 起動・検証

```powershell
flutter pub get
flutter run -d windows
# Androidは接続した端末を指定
flutter run -d <device-id>

flutter analyze
flutter test
```

### リリースビルド（Windows / PowerShell）

```powershell
# 必要に応じてビルド環境を準備
.\scripts\setup-windows.ps1
.\scripts\setup-android.ps1 -AcceptLicenses

# 両プラットフォームをビルド
.\scripts\build-release.ps1 -Target all
# 個別指定: -Target windows / -Target android
```

ビルドスクリプトは`.tools/flutter`のSDKを優先し、なければPATH上のFlutterを使用します。成果物とSHA-256チェックサムは`dist/`に出力します。

確認用の未署名MSIXは次のコマンドで作成できます。Windows SDKのMakeAppxを使用し、証明書のインストールは行いません。配布・通常のインストール用には署名の準備が必要です。

```powershell
.\scripts\build-msix.ps1
# Windowsリリースをビルド済みの場合: -SkipBuild
```

Androidの署名情報は`android/key.properties`または`.tools/signing/android-key.properties`から読み込みます。[設定例](android/key.properties.example)を参照してください。ビルドスクリプトは未設定の開発環境では署名鍵を生成します。公式配布の更新には同じ鍵が必要なため、既存の署名鍵は別途保管し、Gitには登録しません。

署名証明書の制作者名は`akky_1023`、組織名は`Neomenia`、国は`JP`、ドメインはSANの`DNS:neomenia.net`です。公式配布用の公開証明書は`android/release-signing-certificate.pem`に保存し、CIでは秘密鍵を復元した後に適用します。証明書の適用処理は公開鍵の一致を確認し、変更前のキーストアを同じディレクトリにバックアップします。旧証明書のAPKからは通常の上書き更新ができないため、入れ替えが必要です。

### ディレクトリ

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

## 現時点の補足

- 通知テスト用APKは `flutter build apk --release --dart-define=UNITABLE_NOTIFICATION_TEST=true` で作成できます。設定の「通知」で科目を選び、即時・30秒後・5分後の課題確認通知を試せます。通常ビルドにはテストボタンを表示しません。
- Androidの通知遅延を軽減するには、設定の「通知」から「正確な時刻の通知を許可」でアラームとリマインダーを許可してください。遅れる場合は「省電力設定を確認」からバッテリーの制限も見直せます。
- 講義終了後の課題確認通知にある「課題を追加」を押すと、その科目を選択済みの課題登録画面が開きます。
- Windowsの通知にはMSIX版が必要です。現行のインストーラー / ポータブル版では利用できません。
- 同梱の祝日データは1955〜2027年です。更新用スクリプトは`scripts/update_holidays.py`です。
- Android実機での通知配信など、実機確認を継続中です。

## ライセンス・クレジット

制作者: [akky_1023](https://github.com/akky1023) / [HP](https://neomenia.net/)

アプリ内の制作者情報・URLは`lib/app_info.dart`で変更できます。バージョンはRelease Pleaseが`pubspec.yaml`を更新し、アプリ内表示もそのビルド情報から取得します。

アプリ本体は[MIT License](LICENSE)で公開します。著作権表記はGitHubリポジトリのライセンスに合わせています。

同梱のNoto Sans JPはSIL Open Font License 1.1です。[ライセンス全文](assets/fonts/OFL.txt)を同梱しています。依存ライブラリ・データのクレジットは今後整理します。
