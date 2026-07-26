import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    var selected = DateTime.now().add(const Duration(days: 1));
    selected = DateTime(selected.year, selected.month, selected.day, 9);
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '확인할 날짜',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: '알림 시간',
    );
    if (time == null) return;
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final id = const Uuid().v4();
    final database = ref.read(databaseProvider);
    await database
        .into(database.reminders)
        .insert(
          RemindersCompanion.insert(
            id: id,
            kind: 'inventory_check',
            scheduledAt: scheduled,
            hidesMedicineName: const Value(true),
          ),
        );
    final reminder = await (database.select(
      database.reminders,
    )..where((row) => row.id.equals(id))).getSingle();
    await ref.read(reminderSchedulerProvider).schedule(reminder);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: reminders.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MedicalBoxColors.sky.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsFill.eyeSlash,
                    color: MedicalBoxColors.skyDeep,
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      '잠금화면에는 기본적으로 의약품 이름을 표시하지 않아요.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 52),
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsDuotone.bell, size: 62),
                    SizedBox(height: 14),
                    Text(
                      '예정된 알림이 없어요',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            for (final reminder in items)
              Dismissible(
                key: ValueKey(reminder.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('알림을 삭제할까요?'),
                    content: const Text('예약된 기기 알림도 함께 취소해요.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) async {
                  await ref.read(reminderSchedulerProvider).cancel(reminder.id);
                  final database = ref.read(databaseProvider);
                  await (database.delete(
                    database.reminders,
                  )..where((row) => row.id.equals(reminder.id))).go();
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.only(right: 22),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                child: Card(
                  child: SwitchListTile(
                    value: reminder.enabled,
                    title: const Text(
                      '보관함 확인',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'yyyy년 M월 d일 a h:mm',
                        'ko',
                      ).format(reminder.scheduledAt),
                    ),
                    secondary: PhosphorIcon(PhosphorIconsDuotone.bellRinging),
                    onChanged: (enabled) async {
                      final database = ref.read(databaseProvider);
                      await (database.update(
                        database.reminders,
                      )..where((row) => row.id.equals(reminder.id))).write(
                        RemindersCompanion(
                          enabled: Value(enabled),
                          updatedAt: Value(DateTime.now()),
                        ),
                      );
                      if (enabled) {
                        await ref
                            .read(reminderSchedulerProvider)
                            .schedule(reminder.copyWith(enabled: true));
                      } else {
                        await ref
                            .read(reminderSchedulerProvider)
                            .cancel(reminder.id);
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context, ref),
        backgroundColor: MedicalBoxColors.orange,
        foregroundColor: Colors.white,
        icon: Icon(PhosphorIconsBold.plus),
        label: const Text('알림 추가'),
      ),
    );
  }
}
