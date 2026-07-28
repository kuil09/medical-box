import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/services/account_deletion_coordinator.dart';
import 'package:medical_box/services/local_data_lifecycle.dart';
import 'package:medical_box/services/medical_box_export_service.dart';
import 'package:medical_box/services/reminder_scheduler.dart';

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
    'device-data deletion cancels notifications before deleting rows',
    () async {
      final events = <String>[];
      final database = RecordingDatabase(events);
      final scheduler = RecordingReminderScheduler(events);
      addTearDown(database.close);
      await _insertReminder(database, id: 'private-reminder');
      events.clear();

      await LocalDataLifecycle(database, scheduler).deleteAllLocalData();

      expect(events, ['cancelAll', 'databaseDelete']);
      expect(await database.select(database.reminders).get(), isEmpty);
    },
  );

  test('combined account and device deletion cancels notifications', () async {
    final events = <String>[];
    final database = RecordingDatabase(events);
    final scheduler = RecordingReminderScheduler(events);
    final localData = LocalDataLifecycle(database, scheduler);
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
}

Future<void> _insertReminder(
  AppDatabase database, {
  required String id,
  String? privateLabel,
  bool hidesMedicineName = true,
}) {
  return database
      .into(database.reminders)
      .insert(
        RemindersCompanion.insert(
          id: id,
          kind: 'inventory_check',
          scheduledAt: DateTime.now().add(const Duration(days: 3)),
          privateLabel: Value(privateLabel),
          hidesMedicineName: Value(hidesMedicineName),
        ),
      );
}

class RecordingDatabase extends AppDatabase {
  RecordingDatabase(this.events) : super(NativeDatabase.memory());

  final List<String> events;

  @override
  Future<void> deleteAllLocalData() async {
    events.add('databaseDelete');
    await super.deleteAllLocalData();
  }
}

class ScheduledReminder {
  const ScheduledReminder(this.reminder, this.notificationPrivacy);

  final Reminder reminder;
  final bool notificationPrivacy;
}

class RecordingReminderScheduler implements ReminderScheduling {
  RecordingReminderScheduler(this.events);

  final List<String> events;
  final List<ScheduledReminder> scheduled = [];
  List<Reminder> rescheduled = [];
  bool? reschedulePrivacy;

  @override
  Future<void> initialize() async {
    events.add('initialize');
  }

  @override
  Future<void> rescheduleAll(
    List<Reminder> reminders, {
    required bool notificationPrivacy,
  }) async {
    events.add('rescheduleAll');
    rescheduled = List.of(reminders);
    reschedulePrivacy = notificationPrivacy;
  }

  @override
  Future<void> schedule(
    Reminder reminder, {
    required bool notificationPrivacy,
  }) async {
    events.add('schedule');
    scheduled.add(ScheduledReminder(reminder, notificationPrivacy));
  }

  @override
  Future<void> cancel(String id) async {
    events.add('cancel:$id');
  }

  @override
  Future<void> cancelAll() async {
    events.add('cancelAll');
  }
}
