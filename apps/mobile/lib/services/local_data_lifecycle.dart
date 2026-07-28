import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../data/local/app_database.dart';
import 'medical_box_export_service.dart';
import 'reminder_scheduler.dart';

class LocalDataImportPartialFailure implements Exception {
  const LocalDataImportPartialFailure(this.cause);

  final Object cause;

  @override
  String toString() =>
      'Local data was imported, but reminder rescheduling failed.';
}

class InvalidReminderTime implements Exception {
  const InvalidReminderTime();

  @override
  String toString() => 'Reminder time must be in the future.';
}

class ReminderSchedulingFailure implements Exception {
  const ReminderSchedulingFailure(this.cause);

  final Object cause;

  @override
  String toString() => 'The reminder could not be scheduled.';
}

class LocalDataLifecycle {
  LocalDataLifecycle(
    this._database,
    this._reminderScheduler, {
    MedicalBoxExportService? exportService,
  }) : _exportService = exportService ?? MedicalBoxExportService(_database);

  final AppDatabase _database;
  final ReminderScheduling _reminderScheduler;
  final MedicalBoxExportService _exportService;

  Future<void> initialize() async {
    await _reminderScheduler.initialize();
    await rescheduleReminders();
  }

  Future<void> handleAppResumed() async {
    await _reminderScheduler.refreshPermissionStatus();
    await rescheduleReminders();
  }

  Future<void> rescheduleReminders() async {
    final settings = await _database.getSettings();
    final reminders = await _database.select(_database.reminders).get();
    await _reminderScheduler.rescheduleAll(
      reminders,
      notificationPrivacy: settings.notificationPrivacy,
    );
  }

  Future<void> importExport(Uint8List bytes, String password) async {
    await _exportService.importExport(bytes, password);
    try {
      await rescheduleReminders();
    } catch (error) {
      throw LocalDataImportPartialFailure(error);
    }
  }

  Future<void> deleteAllLocalData() async {
    try {
      await _exportService.deleteTemporaryExports();
      await _reminderScheduler.cancelAll();
      await _database.deleteAllLocalData();
    } catch (error, stackTrace) {
      await _bestEffortRescheduleReminders();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> setNotificationPrivacy(bool enabled) async {
    await _database.setNotificationPrivacy(enabled);
    await rescheduleReminders();
  }

  Future<Reminder> addReminder({
    required String id,
    required String kind,
    required DateTime scheduledAt,
    String? inventoryItemId,
    String? privateLabel,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) {
      throw const InvalidReminderTime();
    }
    try {
      await _reminderScheduler.refreshPermissionStatus();
    } catch (error) {
      throw ReminderSchedulingFailure(error);
    }
    if (_reminderScheduler.notificationsExplicitlyDenied) {
      throw const ReminderNotificationPermissionDenied();
    }
    final settings = await _database.getSettings();
    await _database
        .into(_database.reminders)
        .insert(
          RemindersCompanion.insert(
            id: id,
            inventoryItemId: Value(inventoryItemId),
            kind: kind,
            scheduledAt: scheduledAt,
            hidesMedicineName: Value(settings.notificationPrivacy),
            privateLabel: Value(privateLabel),
          ),
        );
    final reminder = await (_database.select(
      _database.reminders,
    )..where((row) => row.id.equals(id))).getSingle();
    try {
      await _reminderScheduler.schedule(
        reminder,
        notificationPrivacy: settings.notificationPrivacy,
      );
    } catch (error) {
      try {
        await _reminderScheduler.cancel(id);
      } catch (_) {
        // Continue rollback even if the platform cannot cancel the failed entry.
      }
      try {
        await (_database.delete(
          _database.reminders,
        )..where((row) => row.id.equals(id))).go();
      } catch (_) {
        // Reconciliation below restores platform state from the rows that remain.
      }
      await _bestEffortRescheduleReminders();
      throw ReminderSchedulingFailure(error);
    }
    return reminder;
  }

  Future<void> setReminderEnabled(String id, bool enabled) async {
    final reminder = await (_database.select(
      _database.reminders,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (reminder == null || reminder.enabled == enabled) return;
    if (enabled && !reminder.scheduledAt.isAfter(DateTime.now())) {
      throw const InvalidReminderTime();
    }
    if (enabled) {
      await _reminderScheduler.refreshPermissionStatus();
      if (_reminderScheduler.notificationsExplicitlyDenied) {
        throw const ReminderNotificationPermissionDenied();
      }
    }

    final settings = await _database.getSettings();
    try {
      await (_database.update(
        _database.reminders,
      )..where((row) => row.id.equals(id))).write(
        RemindersCompanion(
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (enabled) {
        await _reminderScheduler.schedule(
          reminder.copyWith(enabled: true),
          notificationPrivacy: settings.notificationPrivacy,
        );
      } else {
        await _reminderScheduler.cancel(id);
      }
    } catch (error, stackTrace) {
      try {
        await (_database.update(
          _database.reminders,
        )..where((row) => row.id.equals(id))).write(
          RemindersCompanion(
            enabled: Value(reminder.enabled),
            updatedAt: Value(reminder.updatedAt),
          ),
        );
      } catch (_) {
        // Always reconcile from whichever database state survived.
      }
      await _bestEffortRescheduleReminders();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteReminder(String id) async {
    final reminder = await (_database.select(
      _database.reminders,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (reminder == null) return;
    await _cancelLinkedRemindersThen(
      [reminder],
      () => (_database.delete(
        _database.reminders,
      )..where((row) => row.id.equals(id))).go(),
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    final reminders = await (_database.select(
      _database.reminders,
    )..where((row) => row.inventoryItemId.equals(id))).get();
    await _cancelLinkedRemindersThen(
      reminders,
      () => _database.deleteInventoryItem(id),
    );
  }

  Future<void> deleteMemberPouch(String containerId) async {
    final container = await (_database.select(
      _database.inventoryContainers,
    )..where((row) => row.id.equals(containerId))).getSingleOrNull();
    if (container == null) return;

    final itemIds =
        await (_database.selectOnly(_database.inventoryItems)
              ..addColumns([_database.inventoryItems.id])
              ..where(_database.inventoryItems.containerId.equals(containerId)))
            .map((row) => row.read(_database.inventoryItems.id)!)
            .get();
    final reminders = itemIds.isEmpty
        ? const <Reminder>[]
        : await (_database.select(
            _database.reminders,
          )..where((row) => row.inventoryItemId.isIn(itemIds))).get();

    await _cancelLinkedRemindersThen(reminders, () async {
      await _database.transaction(() async {
        await (_database.delete(
          _database.inventoryContainers,
        )..where((row) => row.id.equals(containerId))).go();
        final memberId = container.ownerMemberId;
        if (memberId != null) {
          await (_database.delete(
            _database.memberProfiles,
          )..where((row) => row.id.equals(memberId))).go();
        }
      });
    });
  }

  Future<void> _cancelLinkedRemindersThen(
    List<Reminder> reminders,
    Future<void> Function() mutation,
  ) async {
    try {
      for (final reminder in reminders) {
        await _reminderScheduler.cancel(reminder.id);
      }
      await mutation();
    } catch (error, stackTrace) {
      await _bestEffortRescheduleReminders();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _bestEffortRescheduleReminders() async {
    try {
      await rescheduleReminders();
    } catch (_) {
      // The original mutation error remains the actionable failure.
    }
  }
}
