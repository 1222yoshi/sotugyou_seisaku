# プロジェクト名：『MeTRO NOTE』
<img width="500" src="app/assets/images/metro-logo.png">

# 目次
- [サービス概要](#-サービス概要)
- [サービスURL](#-サービスurl)
- [サービス開発の背景](#-サービス開発の背景)
- [機能紹介](#-機能紹介)
- [技術構成について](#-技術構成について)
  - [使用技術](#使用技術)
  - [ER図](#er図)
  - [画面遷移図](#画面遷移図)<br>
<br>

# サービス概要
バンドメンバーのマッチングアプリです。<br>

ユーザーの音楽的な能力、趣向を可視化します。<br>

メンバー探しや、趣向の近いユーザー同士の交流ツールを目的とします。<br>
<br>

# サービスURL
### https://metronote.jp<br>
<br>


# サービス開発の背景
私は高校生からバンド活動、その後は音楽大学で勉強や練習、音楽活動をしていました。<br>
それらの経験の中で感じたのは、音楽での成功は仲間の存在や仲間の能力一つで大きく変わりうるということでした。<br>
<br>
そのためにバンドメンバーを探すマッチングアプリは存在しても、私の周りで使ってる人はほとんど見かけません。<br>
<br>
私が感じた理由としては、
- バンド練習と言って異性と出会い目的で使う悪質なユーザーがいる。
- 10代20代が少ない。
- それらの理由により活気がない、人数が少ない。<br>
<br>

つまり現状、音楽をする上で必要なメンバー探しを理想的に叶えてくれるツールが実質存在していないように思えます。<br>
よってその問題を解決するために、本気の人間かを把握できる、たくさんの人が集まるバンドメンバーマッチングアプリをつくりたいと考え、開発するに至りました。<br>
<br>

# 機能紹介

| ユーザー登録 / ログイン |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/fb20f2eb11bf0586ec1c7a89f47ba2dc.gif)](https://i.gyazo.com/fb20f2eb11bf0586ec1c7a89f47ba2dc) |
| <p align="left">『名前』『メールアドレス』『パスワード』『確認用パスワード』を入力してユーザー登録を行います。ユーザー登録後は、自動的にログイン処理が行われるようになっており、そのまま直ぐにサービスを利用する事が出来ます。</p> |
<br>

| 『私を構成する9枚』作成 |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/71e20fbcefb48f6e098b3d06c2dcb12b.gif)](https://i.gyazo.com/71e20fbcefb48f6e098b3d06c2dcb12b) |
| <p align="left">好きな9枚のアルバムを登録して、『私を構成する9枚』を作成できます。</p> |
<br>

| 『私を構成する9枚』共有 |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/dbe0b21856dbae3c8d88433696acbcfa.gif)](https://i.gyazo.com/dbe0b21856dbae3c8d88433696acbcfa) |
| <p align="left">『私を構成する9枚』を動的OGPとしてXで共有できます。</p> |
<br>

| 『私を構成する9枚』マッチング |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/fc72e6304b59f75d797ad9f3319d0e8a.gif)](https://i.gyazo.com/fc72e6304b59f75d797ad9f3319d0e8a) |
| <p align="left">自分の『私を構成する9枚』と他のユーザーの『私を構成する9枚』のマッチ度をAIやアルゴリズムが評価、並び替えをします。</p> |
<br>

| 音楽クイズ |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/9a4a6fe40a1961d47aee77be9c308dfe.gif)](https://i.gyazo.com/9a4a6fe40a1961d47aee77be9c308dfe) |
| <p align="left">音楽の問題を出題。正解するとランクが上がってプロフィールに表示されたり、テスト順に並び変えた時に上位に表示されます。</p> |
<br>

| チャット機能 |
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/4df27f50f32d2c99a6787feedbd73446.gif)](https://i.gyazo.com/4df27f50f32d2c99a6787feedbd73446) |
| <p align="left">他のユーザーとメッセージのやり取りができます。</p> |
<br>

| いいね機能・通知機能|
| :---: | 
| [![Image from Gyazo](https://i.gyazo.com/0f312bdd28efd88d31a2ef20b0a46ebe.gif)](https://i.gyazo.com/0f312bdd28efd88d31a2ef20b0a46ebe) |
| <p align="left">お気に入りのユーザーをいいねできます。それらのユーザーの一覧画面もあります。<br>また、チャットといいねは受け取ると、リアルタイムでヘッダーのアイコンが光る仕様です。</p> |
<br>

# 技術構成について

## 使用技術
| カテゴリ | 技術内容 |
| --- | --- | 
| サーバーサイド | Ruby on Rails 7.1.3.4・Ruby 3.1.4 |
| フロントエンド | Ruby on Rails・JavaScript |
| CSSフレームワーク | Tailwindcss|
| Web API | OpenAI API(GPT-4)|
| データベースサーバー | PostgreSQL |
| ファイルサーバー | AWS S3 |
| アプリケーションサーバー | Heroku |
| バージョン管理ツール | GitHub|
<br>

## ER図
<img width="713" alt="image" src="https://i.gyazo.com/53c90bea9ea1d885a090cb8177c0ba3b.png">
<br>

## 画面遷移図
https://www.figma.com/design/mSpr7uukL96Z7vVGmuyinA/%E5%8D%92%E6%A5%AD%E5%88%B6%E4%BD%9CUI?node-id=0-1&t=3C7fo46dZeLdAfAg-1

