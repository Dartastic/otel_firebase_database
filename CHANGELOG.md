# Changelog

## [0.1.0-beta.1-wip]

### Added

- Extension methods on `DatabaseReference`: `tracedGet`,
  `tracedSet`, `tracedUpdate`, `tracedRemove`,
  `tracedRunTransaction`. Each opens a CLIENT span named
  `realtime_db <op> <path>` with
  `db.system=firebase_realtime_database`, `db.operation`,
  `db.namespace=<path>`.
- `tracedRealtimeDbCall<R>` — generic helper.
- `FirebaseException`-aware error handling.
- Zone-scoped suppression
  (`runWithoutFirebaseDatabaseInstrumentation` / async variant).
- 3 tests via the generic helper.
