import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'data/local/app_database.dart';
import 'data/local/database_key_store.dart';
import 'providers.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const kakaoKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  if (kakaoKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
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
