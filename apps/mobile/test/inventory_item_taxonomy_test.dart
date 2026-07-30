import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/features/inventory/inventory_item_taxonomy.dart';

void main() {
  test('official efficacy suggests a physical cabinet section', () {
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['감기로 인한 발열 및 통증 완화'],
      ),
      CabinetSections.painAndFever,
    );
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['위산 과다와 속쓰림 완화'],
      ),
      CabinetSections.digestion,
    );
  });

  test(
    'first-aid supplies start in wound care without using private notes',
    () {
      expect(
        suggestCabinetSection(
          itemKind: InventoryItemKinds.firstAidSupply,
          officialText: const ['unrelated'],
        ),
        CabinetSections.woundCare,
      );
    },
  );
}
