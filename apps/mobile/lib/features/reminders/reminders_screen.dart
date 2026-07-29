import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../providers.dart';
import '../../services/local_data_lifecycle.dart';
import '../../services/reminder_scheduler.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';

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
    if (time == null || !context.mounted) return;
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재보다 이후 시간을 선택해 주세요.')));
      return;
    }
    final id = const Uuid().v4();
    try {
      await ref
          .read(localDataLifecycleProvider)
          .addReminder(
            id: id,
            kind: 'inventory_check',
            scheduledAt: scheduled,
            privateLabel: '보관함 확인',
          );
    } on InvalidReminderTime {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재보다 이후 시간을 선택해 주세요.')));
      }
    } on ReminderSchedulingFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 알림을 예약하지 못했어요. 알림 권한을 확인해 주세요.')),
        );
      }
    } on ReminderNotificationPermissionDenied {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 꺼져 있어요. 기기 설정에서 허용해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: reminders.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(
            MedicalBoxSpacing.screen,
            MedicalBoxSpacing.x2,
            MedicalBoxSpacing.screen,
            96,
          ),
          children: [
            const CabinetSectionLabel('알림 기본값'),
            const CabinetSectionList(
              showDividers: false,
              children: [
                ListTile(
                  minTileHeight: 64,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  leading: PhosphorIcon(
                    PhosphorIconsRegular.eyeSlash,
                    color: MedicalBoxColors.official,
                    size: 22,
                  ),
                  title: Text('잠금화면에서 의약품명 숨기기'),
                  subtitle: Text('일반적인 확인 문구만 표시해요.'),
                  trailing: PhosphorIcon(
                    PhosphorIconsRegular.checkCircle,
                    color: MedicalBoxColors.official,
                    size: 20,
                  ),
                ),
              ],
            ),
            const CabinetSectionLabel('예정된 알림'),
            if (items.isEmpty)
              const _EmptyReminders()
            else
              CabinetSectionList(
                children: [
                  for (final reminder in items)
                    Dismissible(
                      key: ValueKey(reminder.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final confirmed = await showDialog<bool>(
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
                        );
                        if (confirmed != true) return false;
                        try {
                          await ref
                              .read(localDataLifecycleProvider)
                              .deleteReminder(reminder.id);
                          return true;
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('알림 삭제를 마치지 못했어요. 다시 시도해 주세요.'),
                              ),
                            );
                          }
                          return false;
                        }
                      },
                      background: const ColoredBox(
                        color: MedicalBoxColors.accent,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: SwitchListTile(
                        value: reminder.enabled,
                        minTileHeight: 72,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: Text(
                          '보관함 확인',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          DateFormat(
                            'yyyy년 M월 d일 a h:mm',
                            'ko',
                          ).format(reminder.scheduledAt),
                        ),
                        secondary: const PhosphorIcon(
                          PhosphorIconsRegular.bellRinging,
                          size: 22,
                        ),
                        onChanged: (enabled) async {
                          try {
                            await ref
                                .read(localDataLifecycleProvider)
                                .setReminderEnabled(reminder.id, enabled);
                          } on ReminderNotificationPermissionDenied {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '알림 권한이 꺼져 있어요. 기기 설정에서 허용해 주세요.',
                                  ),
                                ),
                              );
                            }
                          } on InvalidReminderTime {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '지난 알림은 다시 켤 수 없어요. 새 알림을 추가해 주세요.',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '알림 변경을 마치지 못했어요. 기존 상태를 유지해요.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context, ref),
        icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
        label: const Text('알림 추가'),
      ),
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedicalBoxSpacing.x10),
      child: Column(
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.bell,
            size: 40,
            color: MedicalBoxColors.faint,
          ),
          const SizedBox(height: MedicalBoxSpacing.x3),
          Text('예정된 알림이 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: MedicalBoxSpacing.x1),
          const Text(
            '필요한 날짜에 보관함을 확인하도록 알려드릴게요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MedicalBoxColors.muted),
          ),
        ],
      ),
    );
  }
}
