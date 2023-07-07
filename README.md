# github-author-report
定期的に `config.json` で指定したユーザーの PR/Issue 情報を集計してサマリーを作成する。

サマリーの例）https://github.com/mmikami-lifull/github-author-report/actions/runs/5473225350d
| Author | Title | URL | CreatedAt |
| ------ | ----- | --- | --------- |
| mmikami-lifull | test2 | https://github.com/mmikami-lifull/github-author-report/issues/2 | 2023-07-06T07:55:58Z |
| mmikami-lifull | test1 | https://github.com/mmikami-lifull/github-author-report/issues/1 | 2023-07-06T07:55:49Z |
| mmikami-lifull | feat(workflows): add author issue report workflow | https://github.com/mmikami-lifull/github-author-report/pull/3 | 2023-07-06T07:58:43Z |

## 目的
特定のユーザーの PR や Issue を購読し、自身の実装に役立てる。
利用している [Github の Slack インテグレーション](https://github.com/integrations/slack#readme)において、特定のユーザーの PR や Issue を購読する術がない。なので作る。

## 利用方法
### (共通) config.json の作成
設定例）
```json
[
  {
    "author": "mmikami-lifull",
    "date_from": "1 week ago",
    "owner": "mmikami-lifull",
    "repo": "github-author-report"
  }
]
```
json はリスト形式で下記のオブジェクトを要素に持つ

| フィールド | タイプ | 概要 |
| ------ | ------ | ------ |
| `author` | string | ユーザー（[参考](https://docs.github.com/ja/search-github/searching-on-github/searching-issues-and-pull-requests#search-by-author)）
| `date_from` | string | PR/Issue のフィルタリングに使用される日付に関するパラメーター。ここで指定した日付より後に作成された PR/Issue が検索対象となる。このパラメーターは date コマンド の [--date (linux)](https://linuxjm.osdn.jp/html/GNU_coreutils/man1/date.1.html) もしくは [-v (mac)](https://www.unix.com/man-page/osx/1/date/) パラメーターに相当する|
| `owner` |  string | レポジトリのオーナー。個人だったり組織だったり。|
| `repo` | string | レポジトリ名 |


### github actions を利用する場合
- `.github/workflows/author_issue_report.yaml` の `on.schedule` をコメントインする
https://github.com/mmikami-lifull/github-author-report/blob/f399325fc71729bc957ac61fe75cb0eb903f78d5/.github/workflows/author_issue_report.yaml#L5-L9

**<注意事項>**
- ワークフローによって自動作成される `GITHUB_TOKEN` では、Organization 内の Private Repository の PR/Issue は取得できない。権限的エラーになる。

### ローカルで利用する場合
- [こちらのAPI](https://docs.github.com/ja/rest/search/search?apiVersion=2022-11-28#search-issues-and-pull-requests)を実行できるように `GITHUB_TOKEN` を設定
- `make-report.sh` の環境変数をコメントインする
https://github.com/mmikami-lifull/github-author-report/blob/f399325fc71729bc957ac61fe75cb0eb903f78d5/make-report.sh#L3-L5

- `GITHUB_STEP_SUMMARY` にアウトプットしたいマークダウンファイルを指定する。

  ```sh
  # summary.md に書き込む場合
  touch summary.md
  ```

- 実行すると、summary.md にサマリーが書き込まれている

  ```sh
  bash make-report.sh
  ```

**<注意事項>**
- date 関数は linux と Mac で使用が異なる。
https://github.com/mmikami-lifull/github-author-report/blob/f399325fc71729bc957ac61fe75cb0eb903f78d5/make-report.sh#L11-L12
