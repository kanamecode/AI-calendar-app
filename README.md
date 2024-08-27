# AI Calendar App

**AIカレンダーアプリ** は、AIを活用した高度なスケジュール管理アプリです。  
簡単で効率的なスケジューリング機能を備えています。   

## 📱 開発環境

- **OS:**
  - 開発: Windows 11 Pro (23H2), macOS Sonoma (14.4)
  - デバッグ: Android 8.1, iOS 18 beta 4
- **使用ソフトウェア:**
  - Visual Studio Code, Xcode

## 🛠️ 開発プラットフォーム

- **フレームワーク:** Flutter
- **プログラミング言語:** Dart
- **Flutter バージョン:** 3.22.2
  - フレームワークリビジョン: `761747bfc5`
  - エンジンリビジョン: `edd8546116`
- **Dart バージョン:** 3.4.3
- **DevTools バージョン:** 2.34.3

## 🔌 使用API

- **Google Maps API:**  
  
- **ChatGPT API (GPT-4 Turbo):**  

---
## 📥 アプリのインストール

アプリのインストーラーは以下のURLからダウンロードできます。  
Androidで動作するインストーラーです。  
  [こちらのリンク](https://github.com/kanamecode/AI-calendar-app/blob/main/apk/AI%20Calendar%20App.apk)  
このURLは本プロジェクトのapkフォルダ内のapkファイルです。  

iosにビルドする場合、ios14以降のバージョンを指定してください。

## ‼️《重要》‼️
セキュリティ上の理由でAPI KEYは埋め込んでいないため、APIKEYを取得する必要があります。

## 🌍 API KEYの取得
このアプリは**Google Maps API** と **ChatGPT API** の 2 つのAPIを使用しています。
以下の手順でそれぞれの API KEYを取得し、アプリの設定画面でAPI KEYを入力してください。

### Google Maps API キーの取得と設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセスし、Google アカウントでログインします。
2. 新しいプロジェクトを作成するか、既存のプロジェクトを選択します。
3. ナビゲーションメニューから「API とサービス」 > 「ライブラリ」に移動します。
4. 「Maps JavaScript API」,「Maps SDK for iOS」,「Maps SDK for Android」を検索し、有効にします。
6. 「API とサービス」 > 「認証情報」に移動し、「認証情報を作成」ボタンをクリックして「API キー」を選択します。
7. 生成された API キーをコピーします。

### ChatGPT API キーの取得と設定

1. [OpenAI API](https://platform.openai.com/) にアクセスし、OpenAI アカウントでログインします。
2. ダッシュボードから「API Keys」セクションに移動します。
3. 「Create API Key」ボタンをクリックして、新しい API キーを生成します。
4. 生成された API キーをコピーします。

