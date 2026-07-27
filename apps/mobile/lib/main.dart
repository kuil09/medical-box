import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'build_config.dart';
import 'data/local/app_database.dart';
import 'data/local/database_key_store.dart';
import 'providers.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }

  final keyStore = DatabaseKeyStore();
  final database = await openEncryptedDatabase(keyStore);
  final reminderScheduler = ReminderScheduler();
  await reminderScheduler.initialize();
  await reminderScheduler.rescheduleAll(
    await database.select(database.reminders).get(),
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        databaseKeyStoreProvider.overrideWithValue(keyStore),
        reminderSchedulerProvider.overrideWithValue(reminderScheduler),
      ],
      child: const MedicalBoxApp(),
    ),
  );
}
