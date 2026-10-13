# アプリアイコン

`app_icon.svg` が原本です。ユーザー提供の `sea_urchin.svg`（SVG Repo由来）を使い、背景を `#E0EEE4`、黒いウニ本体を中央で80%に縮小しています。

## 再利用用画像

- `webp/app_icon_<サイズ>.webp`: 16、20、24、32、40、48、64、72、96、128、144、192、256、384、512、768、1024px。可逆圧縮、正方形。
- `app_icon_512.png`: ストア掲載などPNGが必要な用途。
- `app_icon_1024.png`: MSIXのロゴ生成元。

SVGとWebPはFlutterのアセットにも登録済みです。WebPは `Image.asset('assets/icons/webp/app_icon_128.webp')` などで利用できます。SVGの描画には別途SVG対応の描画処理が必要です。

## プラットフォームへの反映

- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` は48〜192px。Android 8以降は `mipmap-anydpi-v26/ic_launcher.xml` のアダプティブアイコンを使います。背景色とベクターの前景を分離し、ウニが各ランチャーの形状で欠けないよう安全領域に収めています。Android 13以降はモノクロのテーマアイコンにも対応します。
- Windows: `windows/runner/resources/app_icon.ico` に16、20、24、32、40、48、64、128、256pxを収録。実行ファイル、ショートカット、インストーラーが使用します。MSIXは `pubspec.yaml` の `logo_path` を使用します。

## 再生成

Node.jsとnpmを用意し、リポジトリのルートで実行します。

```powershell
npm install --prefix scripts/icons
npm run generate --prefix scripts/icons
```

生成済みファイルはGit管理するため、通常のアプリビルドにはNode.jsや再生成は不要です。SVGは512×512のviewBox、背景rect、translate/scaleで中央配置した単一のpathを持つ形式です。構造を変更した場合は生成スクリプトも合わせて更新してください。

Androidの配置基準: [Adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)。
