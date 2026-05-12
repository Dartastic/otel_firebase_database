// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_firebase_database_otel_suppress;

bool firebaseDatabaseInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

T runWithoutFirebaseDatabaseInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

Future<T> runWithoutFirebaseDatabaseInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
