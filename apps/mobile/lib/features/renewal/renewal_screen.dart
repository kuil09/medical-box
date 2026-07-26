import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';

class RenewalScreen extends ConsumerWidget {
  const RenewalScreen({super.key});

  Future<void> _addPlan(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItem> items,
  ) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 보유약을 등록해 주세요.')));
      return;
    }
    final selected = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('준비할 처방약 선택'),
        children: items
            .map(
              (item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Text(item.productName),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    if (!context.mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: '다음 방문 예정일',
    );
    if (date == null) return;
    final database = ref.read(databaseProvider);
    final existing =
        await (database.select(database.renewalReadiness)
              ..where((row) => row.inventoryItemId.equals(selected.id)))
            .getSingleOrNull();
    await database
        .into(database.renewalReadiness)
        .insertOnConflictUpdate(
          RenewalReadinessCompanion.insert(
            id: existing?.id ?? const Uuid().v4(),
            inventoryItemId: selected.id,
            nextVisitOn: Value(date),
          ),
        );
  }

  Future<void> _setCheck(
    WidgetRef ref,
    RenewalReadinessData readiness, {
    bool? quantity,
    bool? prescription,
    bool? questions,
  }) async {
    final database = ref.read(databaseProvider);
    await (database.update(
      database.renewalReadiness,
    )..where((row) => row.id.equals(readiness.id))).write(
      RenewalReadinessCompanion(
        remainingQuantityChecked: Value(
          quantity ?? readiness.remainingQuantityChecked,
        ),
        prescriptionPhotoChecked: Value(
          prescription ?? readiness.prescriptionPhotoChecked,
        ),
        questionsPrepared: Value(questions ?? readiness.questionsPrepared),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider).valueOrNull ?? const [];
    final readiness = ref.watch(renewalReadinessProvider);
    final names = {for (final item in inventory) item.id: item.productName};
    return Scaffold(
      appBar: AppBar(title: const Text('진료·갱신 준비')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD8C8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PhosphorIconsFill.warningCircle,
                  color: MedicalBoxColors.orange,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '이 기능은 진료 준비를 돕는 체크리스트예요. 진단, 복용량 계산, 대체약이나 치료 추천은 제공하지 않아요.',
                    style: TextStyle(fontWeight: FontWeight.w800, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('방문 전 확인', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          readiness.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '아직 준비 중인 방문이 없어요.\n처방약과 방문 예정일을 선택해 시작하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MedicalBoxColors.muted),
                    ),
                  ),
                );
              }
              return Column(
                children: plans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                names[plan.inventoryItemId] ?? '삭제된 보유약',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (plan.nextVisitOn != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  3,
                                  12,
                                  5,
                                ),
                                child: Text(
                                  '${DateFormat('yyyy년 M월 d일').format(plan.nextVisitOn!)} 방문 예정',
                                  style: const TextStyle(
                                    color: MedicalBoxColors.muted,
                                  ),
                                ),
                              ),
                            CheckboxListTile(
                              value: plan.remainingQuantityChecked,
                              title: const Text('남은 수량을 직접 확인했어요'),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) => _setCheck(
                                ref,
                                plan,
                                quantity: value ?? false,
                              ),
                            ),
                            CheckboxListTile(
                              value: plan.prescriptionPhotoChecked,
                              title: const Text('처방전·약 봉투를 준비했어요'),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) => _setCheck(
                                ref,
                                plan,
                                prescription: value ?? false,
                              ),
                            ),
                            CheckboxListTile(
                              value: plan.questionsPrepared,
                              title: const Text('진료 때 물어볼 내용을 적었어요'),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) => _setCheck(
                                ref,
                                plan,
                                questions: value ?? false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _addPlan(context, ref, inventory),
            icon: Icon(PhosphorIconsBold.plus),
            label: const Text('방문 준비 추가'),
          ),
        ],
      ),
    );
  }
}
