# TeamHub (Rails Full Feature Sample)

TeamHub is a Ruby on Rails sample application intended to exercise Rails full built-in feature set in a single local app.

Scope policy:
- Includes Rails built-in features
- Excludes external provider variations (S3, Sidekiq, external mail services, external cable backends)

## Stack
- Ruby: 4.0.0 (managed by `mise`)
- Rails: 8.1.2
- DB: SQLite
- Job queue: SolidQueue
- Cable backend: SolidCable
- Cache backend: SolidCache
- Frontend: Hotwire (Turbo + Stimulus + importmap)

## Setup
```bash
mise use ruby@4.0.0
mise exec ruby@4.0.0 -- bundle config set --local path vendor/bundle
mise exec ruby@4.0.0 -- bundle install
mise exec ruby@4.0.0 -- bin/rails db:prepare
```

## Run
```bash
mise exec ruby@4.0.0 -- bin/rails server
mise exec ruby@4.0.0 -- bin/jobs
```

## Test
```bash
mise exec ruby@4.0.0 -- bin/rails test
mise exec ruby@4.0.0 -- bin/rails test:system
```

## Useful Tasks
```bash
mise exec ruby@4.0.0 -- bin/rails teamhub:warm_dashboard_cache
mise exec ruby@4.0.0 -- bin/rails teamhub:queue_stats
```

## Demo Flow
1. Sign up and sign in
2. Create organization, project, and task
3. Upload attachments with direct upload enabled
4. Confirm image variants are rendered in task detail
5. Confirm live notifications (Turbo + Cable)
6. Confirm mail notification and mailbox task creation
7. Switch locale with `?locale=ja`
8. Export tasks CSV from `/tasks/export.csv`

## Feature Mapping
Detailed mapping and progress are maintained in:
- `docs/RAILS_FULL_FEATURES.md` (全機能洗い出し・進捗・証跡の統合台帳)
- `docs/RUNBOOK.md`
- `docs/FINAL_STATUS.md`

## Notes
- Active Job adapter is fixed to SolidQueue.
- If any test-specific Active Job adapter change is needed, it must be approved before applying.
