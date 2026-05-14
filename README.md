# otel_firebase_database

OpenTelemetry instrumentation for
[`package:firebase_database`](https://pub.dev/packages/firebase_database)
(Firebase Realtime Database).

```dart
final ref = FirebaseDatabase.instance.ref('users/alice');

await ref.tracedSet({'name': 'Alice'});
final snapshot = await ref.tracedGet();
await ref.tracedUpdate({'name': 'Alicia'});
await ref.tracedRemove();

final result = await FirebaseDatabase.instance
    .ref('counters/c1')
    .tracedRunTransaction((data) {
      final next = (data as int? ?? 0) + 1;
      return Transaction.success(next);
    });
```

Each call opens a CLIENT span:
- name: `realtime_db <op> <path>`
- `db.system = firebase_realtime_database`
- `db.operation = <op>`
- `db.namespace = <path>`

Suppression: `runWithoutFirebaseDatabaseInstrumentationAsync`.

## License

Apache 2.0
