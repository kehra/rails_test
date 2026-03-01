# 実行手順 / Runbook

## 1. 初期セットアップ (予定)
```bash
# このリポジトリ直下に作成済み
mise use ruby@4.0.0
mise exec ruby@4.0.0 -- bundle config set --local path vendor/bundle
mise exec ruby@4.0.0 -- bundle install
```

## 2. 開発時基本コマンド
```bash
mise exec ruby@4.0.0 -- bin/rails db:create db:migrate
mise exec ruby@4.0.0 -- bin/rails db:seed
mise exec ruby@4.0.0 -- bin/rails server
mise exec ruby@4.0.0 -- bin/rails test
mise exec ruby@4.0.0 -- bin/rails test:system
mise exec ruby@4.0.0 -- bin/jobs
mise exec ruby@4.0.0 -- bin/rails teamhub:warm_dashboard_cache
mise exec ruby@4.0.0 -- bin/rails teamhub:queue_stats
mise exec ruby@4.0.0 -- bin/rails teamhub:middleware
```

## 2.1 Rails CLI / Tooling 検証済みコマンド
```bash
mise exec ruby@4.0.0 -- bin/rails about
mise exec ruby@4.0.0 -- bin/rails notes
mise exec ruby@4.0.0 -- bin/rails routes
mise exec ruby@4.0.0 -- bin/rails -T db
mise exec ruby@4.0.0 -- bin/rails db:version
mise exec ruby@4.0.0 -- bin/rails db:migrate:status
mise exec ruby@4.0.0 -- bin/rails db:abort_if_pending_migrations
mise exec ruby@4.0.0 -- bin/rails db:prepare
mise exec ruby@4.0.0 -- bin/rails db:schema:dump
mise exec ruby@4.0.0 -- bin/rails db:schema:cache:dump
mise exec ruby@4.0.0 -- bin/rails generate teamhub:feature --help
mise exec ruby@4.0.0 -- bin/rails generate controller ToolingProbe --skip-routes --skip-template-engine --skip-helper --skip-assets --skip-test-framework --pretend
mise exec ruby@4.0.0 -- bundle exec rails new /tmp/teamhub_api_probe --api --skip-bundle --skip-git --pretend
mise exec ruby@4.0.0 -- bin/rails runner 'puts DebugHelperProbe.render_console_debug(teamhub: true, source: "runner")'
```

実行確認メモ:
- `rails about`: Rails 8.1.2 / Ruby 4.0.0 / sqlite3 / schema version `20260227101100`
- `rails notes`: `app/services/tooling_notes_probe.rb` の `TODO(teamhub)` を検出
- `rails routes`: `/engine/status`, `/security_demos/*`, `/cookies/*`, `/docs/feed`, `/api/metal_ping` を確認
- `rails -T db`: multi-db/shard 環境向け `db:create:*`, `db:migrate:*`, `db:migrate:redo:*` 等を確認
- `rails db:migrate:status`: primary は migration 一覧を表示。secondary 側 `schema_migrations` 未作成のため先頭に警告が出るが、一覧確認は可能
- `rails db:abort_if_pending_migrations`: 正常終了 (pending migration なし)
- `rails db:prepare`: 正常終了 (既存DBに対して setup/migrate no-op)
- `rails db:schema:dump`: 正常終了 (`db/schema.rb` を再生成)
- `rails db:schema:cache:dump`: 正常終了 (`db/schema_cache.yml` を生成)
- `rails generate teamhub:feature --help`: custom generator の options (`--skip-*`, `--pretend`, `--force`) を確認
- `rails generate controller ... --skip-* --pretend`: `app/controllers/tooling_probe_controller.rb` の生成予定を表示し、`--skip-*` オプション経由で副生成物を抑制できることを確認
- `bundle exec rails new /tmp/teamhub_api_probe --api --skip-bundle --skip-git --pretend`: `--api` により `--skip-javascript`, `--skip-hotwire`, `--skip-asset-pipeline` が自動有効化され、API mode の生成差分 (`app/views/layouts/application.html.erb` 削除など) を確認
- `rails runner 'puts DebugHelperProbe.render_console_debug(...)'`: console/runner から `debug` helper を呼び出し、`<pre class="debug_dump">` 出力を確認

注記:
- Active Job は `SolidQueue` を使用する
- `test` 向けアダプタ設定の変更は、都度確認してから実施する

## 3. デモシナリオ (完成時確認)
1. ユーザー作成してログイン
2. 組織・プロジェクトを作成
3. タスクを作成し、コメントと添付ファイルを追加
4. リッチテキスト本文を編集
5. 通知がリアルタイムに反映されることを確認
6. メール通知と受信メール起票を確認
7. `?locale=ja` で日本語表示に切り替わることを確認
8. `/tasks/export.csv` でCSVエクスポートを確認

デモ用ログイン:
- `alice@example.com / password123`
- `bob@example.com / password123`

## 4. 進捗チェックリスト
- [x] Rails 8.1.2でアプリ作成 (このディレクトリ直下)
- [x] Ruby 4.0.0をmiseで固定
- [x] bundle install先を `vendor/bundle` に固定
- [x] DBマイグレーション実行 (`bin/rails db:migrate`)
- [x] Hotwire導入 (`importmap/turbo/stimulus`)
- [x] 認証 (`has_secure_password`) 実装
- [x] Organization / Project / Task のCRUD
- [x] Action Text + Active Storage(Local) 連携
- [x] Active Job(SolidQueue) + Action Cable + Turbo Stream
- [x] Action Mailer + Action Mailbox
- [x] キャッシュ導入
- [x] Multiple DB / sharding 導線
- [x] API-only 環境導線 (`config/environments/api_only.rb`)
- [x] Rails::Engine 導線
- [x] Minitest整備
- [x] docs内の全機能マトリクス更新

## 5. 受け入れ基準
- ローカルで起動・操作・テスト実行できる
- Rails全機能 (対象外を除く) がUIまたはテストで確認できる
- 外部プロバイダー依存なし

証跡参照:
- `docs/RAILS_FULL_FEATURES.md`
