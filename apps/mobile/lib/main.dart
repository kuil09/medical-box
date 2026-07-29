import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'build_config.dart';
import 'data/local/app_database.dart';
import 'data/local/database_key_store.dart';
import 'providers.dart';
import 'services/local_data_lifecycle.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kakaoNativeAppConfigured) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }

  final keyStore = DatabaseKeyStore();
  final database = await openEncryptedDatabase(keyStore);
  final reminderScheduler = ReminderScheduler();
  final localDataLifecycle = LocalDataLifecycle(database, reminderScheduler);
  await localDataLifecycle.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        databaseKeyStoreProvider.overrideWithValue(keyStore),
        reminderSchedulerProvider.overrideWithValue(reminderScheduler),
        localDataLifecycleProvider.overrideWithValue(localDataLifecycle),
      ],
      child: const MedicalBoxApp(),
    ),
  );
}
