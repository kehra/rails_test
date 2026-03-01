# Rails Main 追従手順

## 目的
- このアプリを継続的に `rails/rails` の `main` に追従させる。
- 初回はリリース版から `main` へ移行し、2回目以降は lock 済みの `main` を最新の `main` へ更新する。
- その時点の upstream `main` に対してテストスイート全体を実行する。
- テストが失敗した場合は、その時点で止めるが、失敗内容は原因を調査したうえで報告する。
- テストが通った場合は、upstream 側の差分を確認し、新規追加または変更された framework 機能をこのアプリと `docs/RAILS_FULL_FEATURES.md` へ反映する。

## 現在の前提
- 初回実行時点では `Gemfile` が `gem "rails", "~> 8.1.2"` の可能性がある。
- 2回目以降は `Gemfile` がすでに `gem "rails", github: "rails/rails", branch: "main"` になっている前提で扱う。
- Rails 機能の広範な棚卸しは `docs/RAILS_FULL_FEATURES.md` にまとまっている。
- `vendor/bundle` と `.cocoindex_code` は ignore 済みで、再度コミットしてはいけない。

## 実行前の条件
- `rails/rails` を GitHub から取得するため、ネットワークアクセスが必要。
- 作業ツリーは dirty の可能性があるため、ユーザーの無関係な変更は巻き戻さない。
- `vendor/bundle`、ローカル cache、秘匿情報はコミットしない。
- `config/master.key` は untracked のまま維持する。

## 実行手順
1. 現在の基準状態を記録する。
   - `Gemfile` と `Gemfile.lock` を確認する。
   - 現在 lock されている Rails の参照先（リリース版か GitHub `main` か）と、現時点のテスト状態を把握する。
2. アプリの Rails 参照先を `main` 追従にそろえる。
   - まだリリース版を参照している場合のみ、gem 定義を以下に置き換える。
     - `gem "rails", github: "rails/rails", branch: "main"`
   - すでに `main` を参照している場合は、gem 定義自体は変更しない。
   - 依存解決のために必要にならない限り、他の gem は変更しない。
3. 依存関係を更新する。
   - `bundle update rails` か、`Gemfile.lock` 更新に必要な最小限の bundle 操作を行う。
   - 初回は「8.1.2 -> GitHub `main`」への切り替えになる。
   - 2回目以降は「現在 lock されている GitHub `main` の revision -> 最新の `main` revision」への更新になる。
   - bundler によって他の Rails 関連コンポーネント gem も更新された場合は、報告対象に含める。
4. 検証を実行する。
   - `bin/rails test` を実行する。
   - テスト実行前の boot 失敗や依存解決エラーが起きた場合も、失敗として報告する。
5. 失敗時の扱い。
   - テストが失敗したら、機能差分の反映には進まない。
   - ただし、失敗ログをそのまま返すのではなく、まず原因を切り分ける。
   - 必要に応じて以下を行う。
     - 失敗したテストだけを再実行する
     - 最初の例外発生箇所を特定する
     - 依存解決、boot、API 変更、非互換、既存テストの脆さのどれかを分類する
   - 以下を報告する。
     - 失敗したコマンド
     - 最初に出た意味のあるエラー
     - 影響を受けたファイルまたはテスト
     - 失敗種別（依存解決、boot、framework API 変更、テスト回帰）
     - 可能なら、根本原因の推定と最小の修正方針
6. 成功時の扱い。
   - `Gemfile.lock` に lock された Rails の revision を特定する。
   - 更新前の lock 状態と、新しい upstream revision を比較する。
   - このアプリに関係する公開機能の追加・変更を確認する。
   - 必要な反映先は以下。
     - `docs/RAILS_FULL_FEATURES.md`
     - app 側の demo / probe コード（本当に意味のある新機能のみ）
   - まずドキュメント更新を優先し、実装追加は必要性が高い差分だけに絞る。

## 成功時に確認すべき内容
- `Gemfile.lock`
  - GitHub 由来の `rails` revision が lock されていることを確認する。
  - 前回 lock されていた revision からどこまで進んだかを確認する。
- Rails upstream の変更
  - 初回は、リリース版 8.1.2 相当から現在の `main` までの差分を意識する。
  - 2回目以降は、前回 lock されていた `main` revision から現在の `main` までの差分を確認する。
  - このアプリが使っている framework API に関係する変更を優先して確認する。
  - 特に、このプロジェクトが明示的に追っている領域を優先する。
    - Railties
    - Active Support
    - Active Model
    - Active Record
    - Action Pack / Action View
    - Active Job
    - Active Storage / Action Text
    - Action Mailer / Action Mailbox / Action Cable
    - Hotwire 連携
- ローカルへの影響
  - メソッドシグネチャ変更、API 名変更、deprecation、新しく使える機能がないか確認する。

## 報告ルール
- エラーが起きたら、それ以上コード変更を進める前に、原因を調査したうえで報告する。
- エラーが起きなかった場合は、以下をまとめて報告する。
  - 更新後の Rails の参照元と revision
  - 更新前の revision（または初回なら旧リリース版）
  - `Gemfile.lock` が `rails` 以外にも変化したか
  - 見つかった新機能・変更機能
  - それを反映するためにローカルで更新したファイル

## 安全上の注意
- `git status` を確認する前に push しない。
- ユーザーの無関係な変更を削除・上書きしない。
- framework 更新でテスト挙動が変わる場合は、test 専用 adapter やローカル override の影響を慎重に扱う。
