// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_firebase_database/otel_firebase_database.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tracedRealtimeDbCall', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'firebase-db-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('emits CLIENT span with db.* + path', () async {
      await tracedRealtimeDbCall<void>(
        operation: 'set',
        path: 'users/alice',
        invoke: () async {},
      );

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('realtime_db set users/alice'));
      final attrs = _attrs(span);
      expect(attrs['db.system'], equals('firebase_realtime_database'));
      expect(attrs['db.operation'], equals('set'));
      expect(attrs['db.namespace'], equals('users/alice'));
    });

    test('exception flips span to Error', () async {
      await expectLater(
        tracedRealtimeDbCall<void>(
          operation: 'set',
          path: 'x',
          invoke: () async => throw StateError('offline'),
        ),
        throwsStateError,
      );
      expect(exporter.spans.single.status, equals(SpanStatusCode.Error));
    });

    test('runWithoutFirebaseDatabaseInstrumentationAsync bypasses spans',
        () async {
      await runWithoutFirebaseDatabaseInstrumentationAsync(() async {
        await tracedRealtimeDbCall<void>(
          operation: 'set',
          path: 'x',
          invoke: () async {},
        );
      });
      expect(exporter.spans, isEmpty);
    });
  });
}
