import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/features/inventory/inventory_item_taxonomy.dart';

void main() {
  test('official efficacy suggests a physical cabinet section', () {
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['두통과 발열 및 통증 완화'],
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

  test('common household categories remain distinct', () {
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['알레르기 비염 증상 완화'],
      ),
      CabinetSections.allergyCare,
    );
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['설사로 인한 수분 보충'],
      ),
      CabinetSections.diarrheaAndHydration,
    );
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.firstAidSupply,
        officialText: const ['비접촉 체온계'],
      ),
      CabinetSections.temperatureAndColdCare,
    );
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['멀미와 구토 증상 완화'],
      ),
      CabinetSections.nauseaAndMotion,
    );
    expect(
      suggestCabinetSection(
        itemKind: InventoryItemKinds.medicine,
        officialText: const ['점안용 인공눈물'],
      ),
      CabinetSections.eyeAndNoseCare,
    );
  });
}
