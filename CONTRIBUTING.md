# コントリビュータ向けガイド

うに時間割の開発手順と、自動バージョン管理の仕様をまとめます。環境構築・起動・ビルド手順は[README](README.md)を参照してください。

## 現在の導入状況

自動採番には **Release Please + GitHub Actions** を使用します。設定は`release-please-config.json`、基準版の記録は`.release-please-manifest.json`、ワークフローは`.github/workflows/release-please.yml`です。

現在の基準バージョンは`1.0.0`、Androidのビルド番号は`17`です。通常の変更PRではバージョンを変更せず、変更内容をコミットメッセージで表してください。Release PleaseがリリースPRで更新します。

## 変更を提出する流れ

1. `main`から作業ブランチを作ります。外部の方はforkからPRを作成してください。
2. 関連する変更をまとめ、必要な検証を行います。
3. 下記の形式でPRタイトルを付け、目的・変更後の動作・検証結果を書きます。UI変更には必要に応じて画像を添えてください。
4. メンテナーがレビューし、原則としてSquash mergeで`main`へ取り込みます。

Squash merge後のコミットが自動採番の対象になります。メンテナーはマージ時のコミットタイトル・本文にも変更の種類と互換性情報が残っていることを確認してください。本文・説明は日本語で構いません。

## コミットとPRタイトル

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)の形式を使います。

```text
種類(任意の対象): 変更内容
```

`:`は半角とし、直後に半角スペースを1つ入れます。対象には`timetable`、`tasks`、`calendar`、`settings`、`storage`などを使えます。

| 種類 | 用途 | 次のリリースへの影響 |
| --- | --- | --- |
| `fix` | 不具合の修正 | パッチ番号を上げる |
| `feat` | 機能追加・利用者向けの機能拡張 | マイナー番号を上げる |
| 種類の末尾に`!` | 互換性を壊す変更 | メジャー番号を上げる |
| `docs` | ドキュメント | 単独ではリリースしない |
| `test` | テストのみの変更 | 単独ではリリースしない |
| `refactor` | 挙動を変えない内部整理 | 単独ではリリースしない |
| `build` / `ci` / `chore` / `style` | ビルド・CI・保守・整形 | 単独ではリリースしない |

```text
fix(timetable): 過去の休業日の背景をグレーにする
feat(settings): このアプリについてを追加する
docs: コントリビュータ向けガイドを追加する
```

挙動が変わる修正を`chore`や`refactor`に分類しないでください。内部変更でも互換性を壊す場合は`!`を付けます。

互換性を壊す変更は、本文で影響と移行方法を説明します。`!`に加えて`BREAKING CHANGE:`を使っても構いません。

```text
feat(storage)!: 保存形式の互換性を変更する

BREAKING CHANGE: 旧形式を直接開けなくなります。影響する版と移行手順を記載します。
```

移行処理によって既存データをそのまま使えるスキーマ更新や、通常のUI変更を、機械的に破壊的変更とは扱いません。既存データ・操作・対応OSへの実際の影響で判断してください。

## 自動採番の仕様

表示バージョンは`MAJOR.MINOR.PATCH`です。前回のリリース以降に`main`へ入った変更のうち、最も大きい更新を採用します。コミットごとに公開する方式ではありません。

| `1.0.0`以降の変更 | 次のバージョン |
| --- | --- |
| `fix`のみ | `1.0.1` |
| `feat`を含む | `1.1.0` |
| 破壊的変更を含む | `2.0.0` |
| ドキュメント・テスト・内部整理のみ | リリースPRを作らない |

例: `fix`が3件あっても次は`1.0.1`です。`fix`と`feat`が混在すれば`1.1.0`です。新しいメジャーではマイナーとパッチ、新しいマイナーではパッチを`0`に戻します。

### リリースまでの流れ

1. 通常のPRを`main`へマージします。
2. Release Pleaseが変更を集計し、次のバージョンと変更履歴を含むリリースPRを作成・更新します。
3. メンテナーが変更履歴、互換性、検証結果を確認し、リリースPRをマージします。通常、提案されたバージョンを手動で上書きしません。
4. Release Pleaseが`v1.0.1`のようなタグと下書きのGitHub Releaseを作成します。
5. CIがそのリリースのコミットから検証・ビルドを行い、成果物・SHA-256チェックサム・ビルド証明を揃えてからReleaseを公開します。公開後はGitHubのRelease immutabilityにより配布ファイルとタグを変更できません。

番号の決定は自動、公開タイミングはリリースPRのマージで決めます。通常の作業者はリリースタグを手動で付けません。公開済みタグの付け直しや、違うコードで同じ版を上書きすることはしません。ビルド失敗時は同じコミットで再実行します。

### 各プラットフォームでの表記

導入後はRelease Pleaseが更新する`pubspec.yaml`の表示バージョンを基準にします。アプリ内表示、MSIX、成果物名はそこから生成し、別々に手入力しません。

Androidの整数のビルド番号は、Release PleaseのDart戦略がリリースごとに1増やします。表示バージョンと合わせて`pubspec.yaml`の`version`を更新します。例: `1.0.0+17`の次の修正版は`1.0.1+18`です。CIの再実行では番号を変えません。

| 対象 | `pubspec.yaml`が`1.2.3+20`の例 |
| --- | --- |
| アプリ内表示 / Android versionName | `1.2.3` |
| Android versionCode | `20` |
| Windows MSIX | `1.2.3.0` |
| Gitタグ | `v1.2.3` |
| 配布物名 | `UniTable-1.2.3-…` |

アプリ内表示は`package_info_plus`でビルド済みアプリの情報を読み込みます。MSIXの版も`pubspec.yaml`から生成します。`lib/app_info.dart`へ版番号を直書きしたり、`msix_version`を別途設定したりしないでください。Androidの番号はCIで`18〜2,100,000,000`の範囲を検証します。プレリリースは当面、自動配布の対象にしません。

以前記載していたSemVerから整数を計算する方式は採用せず、Dart戦略の標準的な連番更新に統一します。

## 変更時の確認

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

保存形式を変更する場合は既存の`.unitable`の移行・読み書き・変更の破棄を確認してください。UI変更ではAndroidとWindows、狭い幅、ライト・ダーク、文字拡大への影響を確認します。検証に実際の個人データをコミットしないでください。

署名鍵・パスワード・端末固有の設定、`.tools/`、`build/`、`dist/`、`artifacts/`はGitに登録しません。依存関係を変更した場合は`pubspec.lock`も更新します。WindowsとAndroidで操作が異なる箇所は、既存の方針を維持してください。

## メンテナー向けのリリース運用

- `main`の履歴を基準にRelease Pleaseが番号と変更履歴を更新します。基準版は`1.0.0`で、導入前の履歴は`bootstrap-sha`で除外します。
- Release Pleaseの`GITHUB_TOKEN`が作るPRは通常のPRイベントでCIが起動しないため、ワークフロー側でCIを明示的に起動します。PRをマージする前に検証結果を確認してください。
- 公式APKは既存の署名鍵をGitHub Secretsから読み込みます。forkのPR検証には署名鍵を渡しません。CI上で署名鍵を新規生成することもしません。
- 必要なSecretsは`ANDROID_KEYSTORE_BASE64`、`ANDROID_STORE_PASSWORD`、`ANDROID_KEY_PASSWORD`、`ANDROID_KEY_ALIAS`です。既存の公式APKの署名情報を登録済みです。登録が欠けている場合は配布ビルドを停止し、公開しません。
- メンテナーはローカルの署名鍵（`.jks`）とパスワードを含む`android-key.properties`を別途バックアップしてください。現在の保管先は`.tools/signing/`です。このフォルダーはGit管理外なので、リポジトリのcloneだけでは復元できません。別の場所へ復元するときは`storeFile`のパスを合わせます。
- ビルドやアップロードに失敗したReleaseは下書きのまま残します。原因を修正したうえで、GitHub Actionsの「失敗したジョブを再実行」を使います。公開済みのReleaseは上書きしません。
- ビルド環境やワークフローの修正が必要な場合は、`Recover draft release`を`main`から手動実行し、下書きのタグを指定します。タグと下書きのコミットが一致することを検証し、その元のソースを再ビルドします。タグは付け直しません。ビルド証明には復旧ワークフローの情報と実際のアプリのソースを記録します。アプリのコード自体を修正する場合は、新しい版としてリリースしてください。
- 配布対象はAPK、Windowsインストーラー、ポータブルZIPです。MSIXは署名・インストール・通知の検証が済むまで公式配布物に含めません。
- リリース処理は`main`の正規リポジトリだけで実行し、Release Pleaseと使用するActionsをコミットSHAに固定します。更新はDependabotのPRをレビューして取り込みます。

同梱の`GITHUB_TOKEN`による書き込みは、リリース処理のジョブだけに限定します。PRの検証ジョブは読み取り権限だけで動かし、秘密鍵を扱いません。署名情報はリリースジョブの終了時に削除します。

### 改ざんへの対策

Release Pleaseは採番・変更履歴・リリースPRを作るツールで、改ざん防止そのものを提供しません。本リポジトリでは公開済みReleaseの変更禁止、タグ・mainの強制更新と削除の禁止、ActionsとFlutter SDKのSHA固定、ロックファイルの強制、APK署名、ビルド証明を組み合わせます。

配布物を検証する例:

```powershell
gh attestation verify .\UniTable-1.0.1-android.apk --repo akky1023/uni-table
Get-FileHash .\UniTable-1.0.1-android.apk -Algorithm SHA256
```

SHA-256だけでは、ファイルとチェックサムが一緒に置き換えられた場合の真正性を確認できません。ビルド証明で作成元を確認し、チェックサムでダウンロードした内容の一致を確認します。アカウントやメンテナー権限が侵害された場合まで完全に防げる仕組みではありません。

## 参考・ライセンス

- [Release Please](https://github.com/googleapis/release-please)
- [Release PleaseのDart戦略・採番設定](https://github.com/googleapis/release-please/blob/main/docs/customizing.md)
- [Release Please Action: 権限・出力・成果物添付](https://github.com/googleapis/release-please-action)
- [Androidのバージョン管理](https://developer.android.com/studio/publish/versioning)

アプリ本体は[MIT License](LICENSE)です。同梱フォントなどのライセンス表記を維持してください。

## 多言語対応

表示文言は `lib/l10n/app_ja.arb` と `app_en.arb` で管理します。Flutter標準の `gen-l10n` を使用し、生成結果は `lib/l10n/generated/` に含めます。

- 文言を変更・追加したら両方のARBを更新し、`flutter gen-l10n` を実行してください。生成されたDartファイルは直接編集しません。
- 可変の科目名・日付・件数などはARBのプレースホルダーで渡し、翻訳文の中で並べ替えられるようにします。
- 言語を追加するときは `app_<言語コード>.arb`、設定画面の選択肢、`Storage.setLanguage` の対応言語を追加し、翻訳テストを更新します。
- 初期設定は端末の言語に従い、未対応言語では日本語を表示します。「設定 → 一般 → 言語」で端末に従う／日本語／Englishを選べます。設定は端末内に保存され、`.unitable` の書き出しには含めません。
- `lib/l10n/strings.dart` は画面・通知・ストレージエラーで同じ言語を使うための窓口です。言語変更時は画面を再描画し、予約済み通知も再構築します。
- 科目名・メモ・登録済みの期間名や祝日名は保存済みデータとして扱い、自動翻訳しません。祝日取り込みは引き続き日本の祝日を対象にします。
- Androidのアプリ名は `res/values/strings.xml` と `res/values-en/strings.xml`、ファイル操作エラーはネイティブ側のコードとDart側の翻訳で管理します。

確認には `flutter analyze` と `flutter test` を使います。`test/localization_test.dart` では翻訳の網羅性、言語設定の永続化、端末言語の変更、画面上の切り替え、通知文面、ユーザーデータの保持を検証します。
