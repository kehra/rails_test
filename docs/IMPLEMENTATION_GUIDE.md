# 実装ガイド

## 1. 予定モデル
- User
- Organization
- Membership (role: owner/member)
- Project
- Task (status, priority)
- Comment
- Announcement
- Notification
- AuditLog

## 2. 予定アソシエーション (概要)
- User has_many Memberships / Organizations through Memberships
- Organization has_many Projects, Users through Memberships
- Project has_many Tasks, Announcements
- Task belongs_to Project, belongs_to User(assignee, optional)
- Task has_many Comments

## 3. 主要画面
1. サインアップ / ログイン
2. ダッシュボード (通知、担当タスク)
3. 組織/プロジェクト一覧
4. タスク一覧・詳細・作成編集
5. 掲示板 (Announcement)
6. 添付ファイル・リッチテキスト編集

## 4. 非同期/リアルタイム
- Task作成/更新時に Active Job (SolidQueue) で通知作成
- 通知を Action Cable + Turbo Stream でリアルタイム反映

## 5. メール
- Action Mailer: タスク割当通知
- Action Mailbox: 受信メールをTask化するサンプル導線

## 6. キャッシュ
- ダッシュボード部品を fragment cache
- 件数集計に low-level cache

## 7. テスト方針 (Minitest)
- Model: バリデーション、関連、scope
- Controller/Request: 認可、CRUD、パラメータ
- System: ログインから主要業務フロー
- Job/Mailer/Channel: 非同期通知と送信・配信

## 8. 追加ポリシー
- 外部ストレージや外部ジョブ基盤は使わない
- ローカル開発で再現可能な構成を優先
- test向けにActive Jobアダプタを変更する場合は都度確認する
