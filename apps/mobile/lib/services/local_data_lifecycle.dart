import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../data/local/app_database.dart';
import 'medical_box_export_service.dart';
import 'reminder_scheduler.dart';

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
    await rescheduleReminders();
  }

  Future<void> deleteAllLocalData() async {
    await _reminderScheduler.cancelAll();
    await _database.deleteAllLocalData();
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
    await _reminderScheduler.schedule(
      reminder,
      notificationPrivacy: settings.notificationPrivacy,
    );
    return reminder;
  }

  Future<void> schedule(Reminder reminder) async {
    final settings = await _database.getSettings();
    await _reminderScheduler.schedule(
      reminder,
      notificationPrivacy: settings.notificationPrivacy,
    );
  }

  Future<void> cancel(String id) => _reminderScheduler.cancel(id);
}
