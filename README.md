# auto_ticket_add

## 参考

- リポジトリのファイル一覧
  - app/views\repositories/_dir_list_content.html.erb
  - app/controllers/repositories_controller.rb

## 役割

最新コミットログにチケットナンバー( #1 とか)が入っている場合、該当するチケットの注記にコミットログを差し込んで更新するプラグイン。

※ 履歴にコミットログを出し `Export csv with journals` と組み合わせて使いたい(「関係しているリビジョン」でも見れるけど、csvには出してくれないので)

## 対応リポジトリ

- Subversion

## 必須

- [Nokogiri](http://nokogiri.org/)
- cURL

## 動作環境

```
Environment:
  Redmine version                          2.3.1.stable
  Ruby version                             1.9.3 (i386-mingw32)
  Rails version                            3.2.13
  Environment                              development
  Database adapter                         Mysql2
```

## 手順

### プラグインインストール

```
$ cd REDMINE_HOME/plugin # Redmineのバージョンによってpluginディレクトリの場所は違う
$ git clone http://github.com/gosyujin/auto_ticket_add.git
```

### Redmine設定

- これはやらなくてもいいかも？
  - `管理 => ロールと権限` から `Auto ticket add` にチェックを入れる
  - `プロジェクト => 設定 => モジュール` から `Auto ticket add` にチェックを入れる
- `管理 => 設定 => 認証` から `RESTによるWebサービスを有効にする` にチェックを入れる
- `個人設定` から `APIアクセスキー` を表示し、メモる`

### Subversion設定

- プロジェクトに設定しているリポジトリのフックスクリプトを編集

```
$ cd REPOSITORY_HOME/hooks
$ cp post-commit.tmpl post-commit.bat # Windowsの場合
# post-commit.batを編集
set http_proxy=
curl -O -s -X GET -H "X-Redmine-API-Key: =82d33ec92eb0bf72390998a875d614a37fce29ec" http://localhost:3000/projects/testproject/auto_ticket/add?revision=%2
```
