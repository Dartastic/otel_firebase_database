// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_database/firebase_database.dart';

import 'firebase_database_suppression.dart';

const _tracerName = 'otel_firebase_database';
const _dbSystem = 'firebase_realtime_database';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

Attributes _attrs({required String operation, required String path}) =>
    OTel.attributesFromMap(<String, Object>{
      Database.dbSystem.key: _dbSystem,
      Database.dbSystemName.key: _dbSystem,
      Database.dbOperation.key: operation,
      Database.dbOperationName.key: operation,
      Database.dbNamespace.key: path,
    });

/// Generic helper that opens a CLIENT span named
/// `realtime_db <operation> <path>`.
Future<R> tracedRealtimeDbCall<R>({
  required String operation,
  required String path,
  required Future<R> Function() invoke,
}) async {
  if (firebaseDatabaseInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'realtime_db $operation $path',
    kind: SpanKind.client,
    attributes: _attrs(operation: operation, path: path),
  );
  try {
    return await invoke();
  } on FirebaseException catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(ErrorResource.errorType.key, e.code),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.message ?? e.code);
    rethrow;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced operations on [DatabaseReference].
extension OTelDatabaseReference on DatabaseReference {
  /// Traced `get`.
  Future<DataSnapshot> tracedGet() {
    return tracedRealtimeDbCall<DataSnapshot>(
      operation: 'get',
      path: path,
      invoke: get,
    );
  }

  /// Traced `set`.
  Future<void> tracedSet(Object? value) {
    return tracedRealtimeDbCall<void>(
      operation: 'set',
      path: path,
      invoke: () => set(value),
    );
  }

  /// Traced `update`.
  Future<void> tracedUpdate(Map<String, Object?> value) {
    return tracedRealtimeDbCall<void>(
      operation: 'update',
      path: path,
      invoke: () => update(value),
    );
  }

  /// Traced `remove`.
  Future<void> tracedRemove() {
    return tracedRealtimeDbCall<void>(
      operation: 'remove',
      path: path,
      invoke: remove,
    );
  }

  /// Traced `runTransaction`.
  Future<TransactionResult> tracedRunTransaction(
    TransactionHandler transactionHandler, {
    bool applyLocally = true,
  }) {
    return tracedRealtimeDbCall<TransactionResult>(
      operation: 'transaction',
      path: path,
      invoke: () => runTransaction(
        transactionHandler,
        applyLocally: applyLocally,
      ),
    );
  }
}
