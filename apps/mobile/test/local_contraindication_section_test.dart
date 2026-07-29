import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/features/inventory/local_contraindication_section.dart';

void main() {
  test('matches only exact official counterpart item sequence values', () {
    final now = DateTime(2026, 7, 30);
    final exactMatch = InventoryItem(
      id: 'exact',
      containerId: 'shared',
      itemSeq: '200000002',
      productName: '정확히 일치하는 약',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );
    final sameNameWithoutOfficialId = InventoryItem(
      id: 'manual',
      containerId: 'shared',
      productName: '정확히 일치하는 약',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );
    final unrelated = InventoryItem(
      id: 'unrelated',
      containerId: 'shared',
      itemSeq: '999999999',
      productName: '관련 없는 약',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );

    final matches = matchLocalContraindications(
      inventory: [exactMatch, sameNameWithoutOfficialId, unrelated],
      rules: const [
        DrugSafetyRule(
          ruleType: 'concomitant_contraindication',
          sourceCode: 'mfds_dur_product_concomitant',
          counterpartItemSeq: '200000002',
          prohibitionContent: '함께 사용하지 않음',
        ),
        DrugSafetyRule(
          ruleType: 'pregnancy_contraindication',
          sourceCode: 'mfds_dur_product_pregnancy',
          counterpartItemSeq: '200000002',
        ),
      ],
    );

    expect(matches, hasLength(1));
    expect(matches.single.inventoryItem.id, 'exact');
    expect(matches.single.rules, hasLength(1));
  });

  test('excludes the currently selected inventory record', () {
    final now = DateTime(2026, 7, 30);
    final item = InventoryItem(
      id: 'current',
      containerId: 'shared',
      itemSeq: '200000002',
      productName: '현재 약',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );

    final matches = matchLocalContraindications(
      inventory: [item],
      rules: const [
        DrugSafetyRule(
          ruleType: 'concomitant_contraindication',
          sourceCode: 'mfds_dur_product_concomitant',
          counterpartItemSeq: '200000002',
        ),
      ],
      excludeInventoryItemId: 'current',
    );

    expect(matches, isEmpty);
  });
}
