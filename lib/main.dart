import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Coerenza con lo storage (DateTime come testo ISO, build.yaml): senza
  // questo, toJson/fromJson generati da Drift serializzano i DateTime come
  // millisecondi Unix, illeggibili nei file di export.
  driftRuntimeOptions.defaultSerializer = const ValueSerializer.defaults(
    serializeDateTimeValuesAsString: true,
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NipayApp(),
    ),
  );
}
