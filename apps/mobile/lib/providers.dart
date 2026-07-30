import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/api/api_client.dart';
import 'data/auth/auth_repository.dart';
import 'data/local/app_database.dart';
import 'data/local/database_key_store.dart';
import 'services/account_deletion_coordinator.dart';
import 'services/inventory_photo_service.dart';
import 'services/local_data_lifecycle.dart';
import 'services/medical_box_export_service.dart';
import 'services/medicine_ocr_service.dart';
import 'services/monetization_service.dart';
import 'services/reminder_scheduler.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('AppDatabase must be overridden at startup.'),
);

final databaseKeyStoreProvider = Provider<DatabaseKeyStore>(
  (ref) => throw StateError('DatabaseKeyStore must be overridden at startup.'),
);

final reminderSchedulerProvider = Provider<ReminderScheduling>(
  (ref) => throw StateError('ReminderScheduler must be overridden at startup.'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final medicineScannerProvider = Provider<MedicineScanner>(
  (ref) => DeviceMedicineScanner(),
);

final inventoryPhotoCaptureProvider = Provider<InventoryPhotoCapture>(
  (ref) => DeviceInventoryPhotoCapture(),
);

final monetizationStateProvider = Provider<MonetizationState>(
  (ref) => const MonetizationState.free(),
);

final bannerAdAdapterProvider = Provider<BannerAdAdapter>(
  (ref) => const DisabledBannerAdAdapter(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(databaseKeyStoreProvider),
  ),
);

final authSessionProvider = FutureProvider<AccountProfile?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.restore();
  return repository.account;
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return CatalogRepository(
    ref.watch(apiClientProvider),
    accessTokenProvider: auth.accessToken,
    refreshAccessTokenProvider: auth.refreshAccessToken,
  );
});

final exportServiceProvider = Provider<MedicalBoxExportService>(
  (ref) => MedicalBoxExportService(ref.watch(databaseProvider)),
);

final localDataLifecycleProvider = Provider<LocalDataLifecycle>(
  (ref) => LocalDataLifecycle(
    ref.watch(databaseProvider),
    ref.watch(reminderSchedulerProvider),
    exportService: ref.watch(exportServiceProvider),
  ),
);

final accountDeletionCoordinatorProvider = Provider<AccountDeletionCoordinator>(
  (ref) => AccountDeletionCoordinator(ref.watch(localDataLifecycleProvider)),
);

final inventoryProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(databaseProvider).watchInventory(),
);

final inventoryItemProvider = StreamProvider.autoDispose
    .family<InventoryItem?, String>(
      (ref, id) => ref.watch(databaseProvider).watchInventoryItem(id),
    );

final sharedInventoryProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(databaseProvider).watchInventoryByContainerKind('shared'),
);

final inventoryForContainerProvider =
    StreamProvider.family<List<InventoryItem>, String>(
      (ref, containerId) =>
          ref.watch(databaseProvider).watchInventoryForContainer(containerId),
    );

final containersProvider = StreamProvider<List<InventoryContainer>>(
  (ref) => ref.watch(databaseProvider).watchContainers(),
);

final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(databaseProvider).watchReminders(),
);

final renewalReadinessProvider = StreamProvider<List<RenewalReadinessData>>(
  (ref) => ref.watch(databaseProvider).watchRenewalReadiness(),
);

final catalogDetailProvider = FutureProvider.autoDispose
    .family<DrugDetail, String>(
      (ref, itemSeq) => ref.watch(catalogRepositoryProvider).detail(itemSeq),
    );

final concomitantSafetyRulesProvider = FutureProvider.autoDispose
    .family<List<DrugSafetyRule>, String>(
      (ref, itemSeq) =>
          ref.watch(catalogRepositoryProvider).concomitantRules(itemSeq),
    );

final appSettingsProvider = FutureProvider<AppSetting>(
  (ref) => ref.watch(databaseProvider).getSettings(),
);
