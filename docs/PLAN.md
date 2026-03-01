# Rails全機能サンプルアプリ計画 (TeamHub)

## 1. 目的
Ruby on Railsの全機能を、1つのサンプルアプリで横断的に確認できる状態にする。

注記:
- 「全機能」はRails本体機能を指す
- 外部プロバイダーのバリエーション (例: S3, 外部キュー, 外部メール配信) は対象外

## 2. 確定方針
- Rails: 8.1.2 (2026-02-27時点で採用)
- DB: SQLite
- フロント: Hotwire (Turbo + Stimulus)
- 認証: Rails標準 (`has_secure_password`)
- テスト: Minitest
- Active Job: SolidQueue 固定
- Ruby: 4.0.0 (miseでプロジェクト固定)
- Active Storage: Localのみ
- 外部プロバイダー連携: 対象外

## 3. ドメイン
- アプリ名: TeamHub
- 概要: チーム運営管理プラットフォーム
- 主な機能: プロジェクト管理、タスク管理、コメント、掲示板、通知、添付ファイル、受信メール起票

## 4. 実装スコープ
- 全機能の洗い出し台帳は `docs/RAILS_FULL_FEATURES.md` を正とする
- 実装進捗・証跡管理は `docs/RAILS_FULL_FEATURES.md` を正とする
- UI導線またはテスト導線のどちらかで必ず確認可能にする

## 5. マイルストーン
1. M1: プロジェクト作成、認証、基本CRUD、テスト基盤
2. M2: Storage/Text、Job、Mailer、Cable、Turbo Stream
3. M3: Mailbox、Cache、Rake Task、監査ログ、Railties拡張
4. M4: 全機能マトリクス照合、未実装解消、最終検証

## 6. 完了条件
- Rails全機能マトリクスの全項目が「実装済み」または「明示的に対象外」に分類されている
- Minitestが一通り通る
- `docs` に機能対応表、実行手順、確認手順がある
