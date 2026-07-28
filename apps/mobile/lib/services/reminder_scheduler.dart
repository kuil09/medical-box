import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/local/app_database.dart';

class ReminderScheduler {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

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

  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await _plugin.cancelAll();
    for (final reminder in reminders.where((entry) => entry.enabled)) {
      await schedule(reminder);
    }
  }

  Future<void> schedule(Reminder reminder) async {
    if (!reminder.scheduledAt.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id),
      title: '우리집 구급키트',
      body: reminder.hidesMedicineName
          ? '확인할 일정이 있어요.'
          : (reminder.privateLabel ?? '확인할 일정이 있어요.'),
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

  Future<void> cancel(String id) => _plugin.cancel(id: _notificationId(id));

  int _notificationId(String value) {
    return value.codeUnits.fold<int>(
      17,
      (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
    );
  }
}
