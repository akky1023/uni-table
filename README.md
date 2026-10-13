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

変更の提出方法・コミット形式・自動バージョン管理の仕様は[コントリビュータ向けガイド](CONTRIBUTING.md)を参照してください。Release Pleaseによる自動化は導入予定で、現在はまだ動作しません。

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

### ディレクトリ

| 場所 | 内容 |
| --- | --- |
| `lib/data/` | SQLiteとファイル管理 |
| `lib/domain/` | 時間割・期間・期限の計算 |
| `lib/services/` | 通知 |
| `lib/ui/` | 画面・テーマ・操作 |
| `test/` | 自動テスト |
| `assets/` | フォント・祝日データ |
| `scripts/`, `packaging/` | 開発・配布用スクリプト |

## 現時点の補足

- Windowsの通知にはMSIX版が必要です。現行のインストーラー / ポータブル版では利用できません。
- 同梱の祝日データは1955〜2027年です。更新用スクリプトは`scripts/update_holidays.py`です。
- Android実機での通知配信など、実機確認を継続中です。

## ライセンス・クレジット

制作者: [akky_1023](https://github.com/akky1023) / [HP](https://neomenia.net/)

アプリ内の制作者情報・URL・表示バージョンは`lib/app_info.dart`で変更できます。

アプリ本体は[MIT License](LICENSE)で公開します。著作権表記はGitHubリポジトリのライセンスに合わせています。

同梱のNoto Sans JPはSIL Open Font License 1.1です。[ライセンス全文](assets/fonts/OFL.txt)を同梱しています。依存ライブラリ・データのクレジットは今後整理します。
