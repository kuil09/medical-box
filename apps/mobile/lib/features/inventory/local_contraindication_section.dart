import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/api/api_client.dart';
import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';

class LocalContraindicationMatch {
  const LocalContraindicationMatch({
    required this.inventoryItem,
    required this.rules,
  });

  final InventoryItem inventoryItem;
  final List<DrugSafetyRule> rules;
}

List<LocalContraindicationMatch> matchLocalContraindications({
  required Iterable<InventoryItem> inventory,
  required Iterable<DrugSafetyRule> rules,
  String? excludeInventoryItemId,
}) {
  final itemsBySequence = <String, List<InventoryItem>>{};
  for (final item in inventory) {
    if (item.id == excludeInventoryItemId) continue;
    final itemSeq = item.itemSeq?.trim();
    if (itemSeq == null || itemSeq.isEmpty) continue;
    itemsBySequence.putIfAbsent(itemSeq, () => []).add(item);
  }

  final rulesByInventoryId = <String, List<DrugSafetyRule>>{};
  final inventoryById = <String, InventoryItem>{};
  final deduplicationKeys = <String>{};
  for (final rule in rules) {
    if (rule.ruleType != 'concomitant_contraindication') continue;
    final counterpartItemSeq = rule.counterpartItemSeq?.trim();
    if (counterpartItemSeq == null || counterpartItemSeq.isEmpty) continue;
    for (final item in itemsBySequence[counterpartItemSeq] ?? const []) {
      final key = [
        item.id,
        rule.sourceCode,
        rule.prohibitionContent ?? '',
        rule.counterpartIngredientName ?? '',
      ].join('\u001f');
      if (!deduplicationKeys.add(key)) continue;
      inventoryById[item.id] = item;
      rulesByInventoryId.putIfAbsent(item.id, () => []).add(rule);
    }
  }

  final matches =
      rulesByInventoryId.entries
          .map(
            (entry) => LocalContraindicationMatch(
              inventoryItem: inventoryById[entry.key]!,
              rules: List.unmodifiable(entry.value),
            ),
          )
          .toList()
        ..sort(
          (left, right) => left.inventoryItem.productName.compareTo(
            right.inventoryItem.productName,
          ),
        );
  return List.unmodifiable(matches);
}

class LocalContraindicationSection extends ConsumerWidget {
  const LocalContraindicationSection({
    required this.selectedItemSeq,
    this.excludeInventoryItemId,
    super.key,
  });

  final String selectedItemSeq;
  final String? excludeInventoryItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    return inventoryState.when(
      data: (inventory) {
        final linkedInventory = inventory.where((item) {
          if (item.id == excludeInventoryItemId) return false;
          return item.itemSeq?.trim().isNotEmpty == true;
        }).toList();
        if (linkedInventory.isEmpty) return const SizedBox.shrink();

        final rulesState = ref.watch(
          concomitantSafetyRulesProvider(selectedItemSeq),
        );
        return rulesState.when(
          data: (rules) {
            final matches = matchLocalContraindications(
              inventory: linkedInventory,
              rules: rules,
            );
            if (matches.isEmpty) return const SizedBox.shrink();
            return _ContraindicationWarning(matches: matches);
          },
          loading: () => const _ContraindicationCheckStatus(
            message: '보유약 병용금기 확인 중…',
            loading: true,
          ),
          error: (_, _) => _ContraindicationCheckStatus(
            message: '보유약 병용금기 확인을 완료하지 못했어요.',
            onRetry: () =>
                ref.invalidate(concomitantSafetyRulesProvider(selectedItemSeq)),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const _ContraindicationCheckStatus(
        message: '기기 보유약을 불러오지 못해 병용금기를 확인할 수 없어요.',
      ),
    );
  }
}

class _ContraindicationWarning extends StatelessWidget {
  const _ContraindicationWarning({required this.matches});

  final List<LocalContraindicationMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '보유약 병용금기 경고 ${matches.length}개',
      child: Container(
        margin: const EdgeInsets.only(top: MedicalBoxSpacing.x6),
        decoration: BoxDecoration(
          color: MedicalBoxColors.surface,
          borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
          border: Border.all(color: MedicalBoxColors.warning),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.shieldWarning,
                    color: MedicalBoxColors.warning,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '함께 사용하기 전 확인하세요',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '보유약 중 공식 DUR 병용금기 규칙과 일치하는 약이 있어요.',
                          style: TextStyle(
                            color: MedicalBoxColors.muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < matches.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _ContraindicationRow(match: matches[index]),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 11, 16, 16),
              child: Text(
                '구급상자에 공식 제품으로 등록한 약만 대조합니다. 실제 복용 중인 모든 약을 포함하지 않으며, 사용 전 의사·약사에게 확인하세요.',
                style: TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContraindicationRow extends StatelessWidget {
  const _ContraindicationRow({required this.match});

  final LocalContraindicationMatch match;

  @override
  Widget build(BuildContext context) {
    final item = match.inventoryItem;
    String? reason;
    for (final rule in match.rules) {
      final candidate = rule.prohibitionContent?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        reason = candidate;
        break;
      }
    }

    return InkWell(
      onTap: () => context.push('/inventory/${Uri.encodeComponent(item.id)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.manufacturer?.trim().isNotEmpty == true)
                    Text(
                      item.manufacturer!,
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    reason ?? '공식 DUR 병용금기 ${match.rules.length}건과 일치해요.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  if (item.storageNote?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      '보관 위치: ${item.storageNote}',
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: MedicalBoxColors.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContraindicationCheckStatus extends StatelessWidget {
  const _ContraindicationCheckStatus({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: MedicalBoxSpacing.x6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(
          color: loading ? MedicalBoxColors.rail : MedicalBoxColors.warning,
        ),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PhosphorIcon(
              PhosphorIconsRegular.warningCircle,
              color: MedicalBoxColors.warning,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('다시 확인')),
        ],
      ),
    );
  }
}
