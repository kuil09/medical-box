import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/local/app_database.dart';

abstract interface class ReminderScheduling {
  Future<void> initialize();

  Future<void> rescheduleAll(
    List<Reminder> reminders, {
    required bool notificationPrivacy,
  });

  Future<void> schedule(Reminder reminder, {required bool notificationPrivacy});

  Future<void> cancel(String id);

  Future<void> cancelAll();
}

class ReminderNotificationContent {
  const ReminderNotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

ReminderNotificationContent reminderNotificationContent(
  Reminder reminder, {
  required bool notificationPrivacy,
}) {
  const fallback = '확인할 일정이 있어요.';
  final label = reminder.privateLabel?.trim();
  return ReminderNotificationContent(
    title: '우리집 구급키트',
    body: notificationPrivacy || label == null || label.isEmpty
        ? fallback
        : label,
  );
}

class ReminderScheduler implements ReminderScheduling {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> rescheduleAll(
    List<Reminder> reminders, {
    required bool notificationPrivacy,
  }) async {
    await cancelAll();
    for (final reminder in reminders.where((entry) => entry.enabled)) {
      await schedule(reminder, notificationPrivacy: notificationPrivacy);
    }
  }

  @override
  Future<void> schedule(
    Reminder reminder, {
    required bool notificationPrivacy,
  }) async {
    if (!reminder.scheduledAt.isAfter(DateTime.now())) return;
    final content = reminderNotificationContent(
      reminder,
      notificationPrivacy: notificationPrivacy,
    );
    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id),
      title: content.title,
      body: content.body,
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medical_box_private_reminders',
          '구급키트 알림',
          channelDescription: 'Private local reminders for the medicine kit.',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'reminder',
    );
  }

  @override
  Future<void> cancel(String id) => _plugin.cancel(id: _notificationId(id));

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  int _notificationId(String value) {
    return value.codeUnits.fold<int>(
      17,
      (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
    );
  }
}
