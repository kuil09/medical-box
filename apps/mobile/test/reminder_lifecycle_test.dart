import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/app.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/providers.dart';
import 'package:medical_box/services/account_deletion_coordinator.dart';
import 'package:medical_box/services/local_data_lifecycle.dart';
import 'package:medical_box/services/medical_box_export_service.dart';
import 'package:medical_box/services/reminder_scheduler.dart';
import 'package:path/path.dart' as path;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'startup initializes notifications before rescheduling local reminders',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(events);
      addTearDown(database.close);
      await _insertReminder(database, id: 'startup');
      events.clear();

      await LocalDataLifecycle(database, scheduler).initialize();

      expect(events, ['initialize', 'rescheduleAll']);
      expect(scheduler.rescheduled.single.id, 'startup');
      expect(scheduler.reschedulePrivacy, isTrue);
    },
  );

  test(
    'app resume refreshes permission before reconciling reminders',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(
        events,
        notificationsExplicitlyDenied: true,
        notificationsDeniedAfterRefresh: false,
      );
      addTearDown(database.close);
      await _insertReminder(database, id: 'resume');
      events.clear();

      await LocalDataLifecycle(database, scheduler).handleAppResumed();

      expect(events, ['refreshPermissionStatus', 'rescheduleAll']);
      expect(scheduler.notificationsExplicitlyDenied, isFalse);
      expect(scheduler.rescheduled.single.id, 'resume');
    },
  );

  testWidgets('the app lifecycle forwards resume reconciliation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final events = <String>[];
    final database = RecordingDatabase(events);
    final scheduler = RecordingReminderScheduler(events);
    final lifecycle = LocalDataLifecycle(database, scheduler);
    addTearDown(database.close);
    await _insertReminder(database, id: 'widget-resume');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          localDataLifecycleProvider.overrideWithValue(lifecycle),
        ],
        child: const MedicalBoxApp(),
      ),
    );
    await tester.pumpAndSettle();
    events.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(events, ['refreshPermissionStatus', 'rescheduleAll']);
  });

  test('imported local data replaces scheduled OS reminders', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final target = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(events);
    addTearDown(source.close);
    addTearDown(target.close);

    await source.setNotificationPrivacy(false);
    await _insertReminder(
      source,
      id: 'imported',
      privateLabel: 'Imported medicine',
      hidesMedicineName: false,
    );
    final encrypted = await MedicalBoxExportService(
      source,
    ).createExportBytes('strong-passphrase');
    await _insertReminder(target, id: 'stale');

    await LocalDataLifecycle(
      target,
      scheduler,
    ).importExport(encrypted, 'strong-passphrase');

    expect(events, ['rescheduleAll']);
    expect(scheduler.rescheduled.map((reminder) => reminder.id), ['imported']);
    expect(scheduler.reschedulePrivacy, isFalse);
    expect((await target.select(target.reminders).get()).single.id, 'imported');
  });

  test(
    'import reports a typed partial failure after data was committed',
    () async {
      final source = AppDatabase(NativeDatabase.memory());
      final target = AppDatabase(NativeDatabase.memory());
      final scheduler = RecordingReminderScheduler(
        <String>[],
        failReschedule: true,
      );
      addTearDown(source.close);
      addTearDown(target.close);
      await _insertReminder(source, id: 'imported');
      await _insertReminder(target, id: 'stale');
      final encrypted = await MedicalBoxExportService(
        source,
      ).createExportBytes('strong-passphrase');

      await expectLater(
        LocalDataLifecycle(
          target,
          scheduler,
        ).importExport(encrypted, 'strong-passphrase'),
        throwsA(isA<LocalDataImportPartialFailure>()),
      );

      expect(
        (await target.select(target.reminders).get()).single.id,
        'imported',
      );
    },
  );

  test(
    'device-data deletion cancels notifications before deleting rows',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(events);
      final appTemp = await _createTestDirectory('medical-box-app-temp-');
      final external = await _createTestDirectory(
        'medical-box-external-backup-',
      );
      final exportService = MedicalBoxExportService(
        database,
        temporaryDirectory: () async => appTemp,
      );
      final generated = await exportService.createExport('strong-passphrase');
      final unrelated = File(path.join(appTemp.path, 'unrelated.medicalbox'));
      final externalCopy = File(
        path.join(external.path, 'medical-box-shared.medicalbox'),
      );
      await unrelated.writeAsString('unrelated file');
      await generated.copy(externalCopy.path);
      addTearDown(database.close);
      await _insertReminder(database, id: 'private-reminder');
      events.clear();

      await LocalDataLifecycle(
        database,
        scheduler,
        exportService: exportService,
      ).deleteAllLocalData();

      expect(events, ['cancelAll', 'databaseDelete']);
      expect(await database.select(database.reminders).get(), isEmpty);
      expect(await generated.exists(), isFalse);
      expect(await unrelated.exists(), isTrue);
      expect(await externalCopy.exists(), isTrue);
    },
  );

  test('combined account and device deletion cancels notifications', () async {
    final events = <String>[];
    final database = RecordingDatabase(events);
    final scheduler = RecordingReminderScheduler(events);
    final appTemp = await _createTestDirectory('medical-box-combined-temp-');
    final localData = LocalDataLifecycle(
      database,
      scheduler,
      exportService: MedicalBoxExportService(
        database,
        temporaryDirectory: () async => appTemp,
      ),
    );
    final coordinator = AccountDeletionCoordinator(localData);
    addTearDown(database.close);
    await _insertReminder(database, id: 'combined');
    events.clear();

    await coordinator.delete(
      deleteAccount: () async => events.add('accountDelete'),
      deleteDeviceData: true,
    );

    expect(events, ['accountDelete', 'cancelAll', 'databaseDelete']);
    expect(await database.select(database.reminders).get(), isEmpty);
  });

  test(
    'account-only deletion preserves local reminders and notifications',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(events);
      final coordinator = AccountDeletionCoordinator(
        LocalDataLifecycle(database, scheduler),
      );
      addTearDown(database.close);
      await _insertReminder(database, id: 'local-only');
      events.clear();

      await coordinator.delete(
        deleteAccount: () async => events.add('accountDelete'),
        deleteDeviceData: false,
      );

      expect(events, ['accountDelete']);
      expect(
        (await database.select(database.reminders).get()).single.id,
        'local-only',
      );
    },
  );

  test(
    'privacy setting controls content for newly scheduled reminders',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(events);
      final lifecycle = LocalDataLifecycle(database, scheduler);
      addTearDown(database.close);

      final privateReminder = await lifecycle.addReminder(
        id: 'private',
        kind: 'inventory_check',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        privateLabel: 'Sensitive medicine',
      );
      final privateSchedule = scheduler.scheduled.single;
      expect(privateReminder.hidesMedicineName, isTrue);
      expect(privateSchedule.notificationPrivacy, isTrue);
      final privateContent = reminderNotificationContent(
        privateReminder,
        notificationPrivacy: privateSchedule.notificationPrivacy,
      );
      expect(privateContent.title, '우리집 구급키트');
      expect(privateContent.body, '확인할 일정이 있어요.');

      await lifecycle.setNotificationPrivacy(false);
      final visibleReminder = await lifecycle.addReminder(
        id: 'visible',
        kind: 'inventory_check',
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
        privateLabel: 'Visible medicine',
      );
      final visibleSchedule = scheduler.scheduled.last;
      expect(visibleReminder.hidesMedicineName, isFalse);
      expect(visibleSchedule.notificationPrivacy, isFalse);
      final visibleContent = reminderNotificationContent(
        visibleReminder,
        notificationPrivacy: visibleSchedule.notificationPrivacy,
      );
      expect(visibleContent.title, '우리집 구급키트');
      expect(visibleContent.body, 'Visible medicine');
    },
  );

  test('past reminders are rejected before database mutation', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(events);
    addTearDown(database.close);

    await expectLater(
      LocalDataLifecycle(database, scheduler).addReminder(
        id: 'past',
        kind: 'inventory_check',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      throwsA(isA<InvalidReminderTime>()),
    );

    expect(await database.select(database.reminders).get(), isEmpty);
    expect(events, isEmpty);
  });

  test('failed platform scheduling rolls back the reminder row', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(events, failSchedule: true);
    addTearDown(database.close);

    await expectLater(
      LocalDataLifecycle(database, scheduler).addReminder(
        id: 'failed',
        kind: 'inventory_check',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      throwsA(isA<ReminderSchedulingFailure>()),
    );

    expect(await database.select(database.reminders).get(), isEmpty);
    expect(events, [
      'refreshPermissionStatus',
      'schedule',
      'cancel:failed',
      'rescheduleAll',
    ]);
  });

  test(
    'explicitly denied notification permission rejects before insert',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final events = <String>[];
      final scheduler = RecordingReminderScheduler(
        events,
        notificationsExplicitlyDenied: true,
      );
      addTearDown(database.close);

      await expectLater(
        LocalDataLifecycle(database, scheduler).addReminder(
          id: 'denied',
          kind: 'inventory_check',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        throwsA(isA<ReminderNotificationPermissionDenied>()),
      );

      expect(await database.select(database.reminders).get(), isEmpty);
      expect(events, ['refreshPermissionStatus']);
    },
  );

  test('reenabling refreshes permission before scheduling', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(
      events,
      notificationsExplicitlyDenied: true,
      notificationsDeniedAfterRefresh: false,
    );
    addTearDown(database.close);
    await _insertReminder(database, id: 'reenable', enabled: false);

    await LocalDataLifecycle(
      database,
      scheduler,
    ).setReminderEnabled('reenable', true);

    expect(events, ['refreshPermissionStatus', 'schedule']);
    expect(
      (await database.select(database.reminders).get()).single.enabled,
      isTrue,
    );
  });

  test('failed reenable restores the disabled database state', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(events, failSchedule: true);
    addTearDown(database.close);
    await _insertReminder(database, id: 'reenable-failure', enabled: false);

    await expectLater(
      LocalDataLifecycle(
        database,
        scheduler,
      ).setReminderEnabled('reenable-failure', true),
      throwsStateError,
    );

    expect(
      (await database.select(database.reminders).get()).single.enabled,
      isFalse,
    );
    expect(events, ['refreshPermissionStatus', 'schedule', 'rescheduleAll']);
  });

  test('rollback failure does not mask the original scheduler error', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(
      events,
      failSchedule: true,
      onSchedule: database.close,
    );
    await _insertReminder(database, id: 'rollback-failure', enabled: false);

    await expectLater(
      LocalDataLifecycle(
        database,
        scheduler,
      ).setReminderEnabled('rollback-failure', true),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Scheduling failed.',
        ),
      ),
    );

    expect(events, ['refreshPermissionStatus', 'schedule']);
  });

  test('failed disable restores the enabled database state', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = <String>[];
    final scheduler = RecordingReminderScheduler(events, failCancel: true);
    addTearDown(database.close);
    await _insertReminder(database, id: 'disable-failure');

    await expectLater(
      LocalDataLifecycle(
        database,
        scheduler,
      ).setReminderEnabled('disable-failure', false),
      throwsStateError,
    );

    expect(
      (await database.select(database.reminders).get()).single.enabled,
      isTrue,
    );
    expect(events, ['cancel:disable-failure', 'rescheduleAll']);
  });

  test(
    'failed reminder deletion keeps the row and reconciles schedules',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final events = <String>[];
      final scheduler = RecordingReminderScheduler(events, failCancel: true);
      addTearDown(database.close);
      await _insertReminder(database, id: 'delete-failure');

      await expectLater(
        LocalDataLifecycle(
          database,
          scheduler,
        ).deleteReminder('delete-failure'),
        throwsStateError,
      );

      expect(
        (await database.select(database.reminders).get()).single.id,
        'delete-failure',
      );
      expect(events, ['cancel:delete-failure', 'rescheduleAll']);
    },
  );

  test(
    'inventory deletion cancels linked reminders before cascading rows',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final events = <String>[];
      final scheduler = RecordingReminderScheduler(events);
      addTearDown(database.close);
      await _insertInventoryFixture(database);
      await _insertReminder(
        database,
        id: 'linked-item-reminder',
        inventoryItemId: 'item-1',
      );

      await LocalDataLifecycle(
        database,
        scheduler,
      ).deleteInventoryItem('item-1');

      expect(events, ['cancel:linked-item-reminder']);
      expect(await database.select(database.inventoryItems).get(), isEmpty);
      expect(await database.select(database.reminders).get(), isEmpty);
    },
  );

  test(
    'member pouch deletion cancels linked reminders and removes the profile',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final events = <String>[];
      final scheduler = RecordingReminderScheduler(events);
      addTearDown(database.close);
      await _insertInventoryFixture(database);
      await _insertReminder(
        database,
        id: 'linked-pouch-reminder',
        inventoryItemId: 'item-1',
      );

      await LocalDataLifecycle(
        database,
        scheduler,
      ).deleteMemberPouch('container-1');

      expect(events, ['cancel:linked-pouch-reminder']);
      expect(
        await database.select(database.inventoryContainers).get(),
        isEmpty,
      );
      expect(await database.select(database.inventoryItems).get(), isEmpty);
      expect(await database.select(database.memberProfiles).get(), isEmpty);
      expect(await database.select(database.reminders).get(), isEmpty);
    },
  );

  test(
    'failed full deletion reschedules reminders that remain in the database',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events, failDelete: true);
      final scheduler = RecordingReminderScheduler(events);
      final appTemp = await _createTestDirectory('medical-box-failed-delete-');
      addTearDown(database.close);
      await _insertReminder(database, id: 'preserved-after-failure');
      events.clear();

      await expectLater(
        LocalDataLifecycle(
          database,
          scheduler,
          exportService: MedicalBoxExportService(
            database,
            temporaryDirectory: () async => appTemp,
          ),
        ).deleteAllLocalData(),
        throwsStateError,
      );

      expect(events, ['cancelAll', 'databaseDelete', 'rescheduleAll']);
      expect(
        (await database.select(database.reminders).get()).single.id,
        'preserved-after-failure',
      );
      expect(scheduler.rescheduled.single.id, 'preserved-after-failure');
    },
  );
}

Future<Directory> _createTestDirectory(String prefix) async {
  final directory = await Directory.systemTemp.createTemp(prefix);
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

Future<void> _insertReminder(
  AppDatabase database, {
  required String id,
  String? inventoryItemId,
  String? privateLabel,
  bool hidesMedicineName = true,
  bool enabled = true,
}) {
  return database
      .into(database.reminders)
      .insert(
        RemindersCompanion.insert(
          id: id,
          inventoryItemId: Value(inventoryItemId),
          kind: 'inventory_check',
          scheduledAt: DateTime.now().add(const Duration(days: 3)),
          enabled: Value(enabled),
          privateLabel: Value(privateLabel),
          hidesMedicineName: Value(hidesMedicineName),
        ),
      );
}

Future<void> _insertInventoryFixture(AppDatabase database) async {
  await database
      .into(database.households)
      .insert(HouseholdsCompanion.insert(id: 'household-1', name: 'Test'));
  await database
      .into(database.memberProfiles)
      .insert(
        MemberProfilesCompanion.insert(
          id: 'member-1',
          householdId: 'household-1',
          displayName: 'Member',
        ),
      );
  await database
      .into(database.inventoryContainers)
      .insert(
        InventoryContainersCompanion.insert(
          id: 'container-1',
          householdId: 'household-1',
          ownerMemberId: const Value('member-1'),
          name: 'Member pouch',
          kind: 'personal',
        ),
      );
  await database
      .into(database.inventoryItems)
      .insert(
        InventoryItemsCompanion.insert(
          id: 'item-1',
          containerId: 'container-1',
          productName: 'Test medicine',
        ),
      );
}

class RecordingDatabase extends AppDatabase {
  RecordingDatabase(this.events, {this.failDelete = false})
    : super(NativeDatabase.memory());

  final List<String> events;
  final bool failDelete;

  @override
  Future<void> deleteAllLocalData() async {
    events.add('databaseDelete');
    if (failDelete) {
      throw StateError('Database deletion failed.');
    }
    await super.deleteAllLocalData();
  }
}

class ScheduledReminder {
  const ScheduledReminder(this.reminder, this.notificationPrivacy);

  final Reminder reminder;
  final bool notificationPrivacy;
}

class RecordingReminderScheduler implements ReminderScheduling {
  RecordingReminderScheduler(
    this.events, {
    this.failReschedule = false,
    this.failSchedule = false,
    this.failCancel = false,
    bool notificationsExplicitlyDenied = false,
    this.notificationsDeniedAfterRefresh,
    this.onSchedule,
  }) : _notificationsExplicitlyDenied = notificationsExplicitlyDenied;

  final List<String> events;
  final bool failReschedule;
  final bool failSchedule;
  final bool failCancel;
  final bool? notificationsDeniedAfterRefresh;
  final Future<void> Function()? onSchedule;
  bool _notificationsExplicitlyDenied;
  @override
  bool get notificationsExplicitlyDenied => _notificationsExplicitlyDenied;
  final List<ScheduledReminder> scheduled = [];
  List<Reminder> rescheduled = [];
  bool? reschedulePrivacy;

  @override
  Future<void> initialize() async {
    events.add('initialize');
  }

  @override
  Future<void> refreshPermissionStatus() async {
    events.add('refreshPermissionStatus');
    final refreshed = notificationsDeniedAfterRefresh;
    if (refreshed != null) {
      _notificationsExplicitlyDenied = refreshed;
    }
  }

  @override
  Future<void> rescheduleAll(
    List<Reminder> reminders, {
    required bool notificationPrivacy,
  }) async {
    events.add('rescheduleAll');
    if (failReschedule) {
      throw StateError('Rescheduling failed.');
    }
    rescheduled = List.of(reminders);
    reschedulePrivacy = notificationPrivacy;
  }

  @override
  Future<void> schedule(
    Reminder reminder, {
    required bool notificationPrivacy,
  }) async {
    events.add('schedule');
    await onSchedule?.call();
    if (failSchedule) {
      throw StateError('Scheduling failed.');
    }
    scheduled.add(ScheduledReminder(reminder, notificationPrivacy));
  }

  @override
  Future<void> cancel(String id) async {
    events.add('cancel:$id');
    if (failCancel) {
      throw StateError('Cancellation failed.');
    }
  }

  @override
  Future<void> cancelAll() async {
    events.add('cancelAll');
  }
}
