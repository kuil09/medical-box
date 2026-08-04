import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/theme.dart';
import 'package:medical_box/widgets/cabinet_shell.dart';

void main() {
  testWidgets('cabinet reveals selectable medicine only after opening', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 30);
    final item = InventoryItem(
      id: 'item-1',
      containerId: 'shared',
      productName: '타이레놀정500밀리그람',
      itemKind: 'medicine',
      cabinetSection: 'pain_and_fever',
      quantity: 1,
      unit: '개',
      expiresOn: DateTime(2026, 8, 10),
      storageNote: '해열·진통',
      createdAt: now,
      updatedAt: now,
    );
    InventoryItem? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildMedicalBoxTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: CabinetShell(
              name: '공용 구급상자',
              items: [item],
              reviewCount: 1,
              onItemTap: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('타이레놀정500밀리그람'), findsNothing);
    expect(find.text('열기'), findsOneWidget);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('타이레놀정500밀리그람'), findsOneWidget);
    expect(find.text('열·통증'), findsOneWidget);
    expect(find.text('확인 필요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);

    await tester.tap(find.text('타이레놀정500밀리그람'));
    await tester.pump();
    expect(selected?.id, item.id);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('타이레놀정500밀리그람'), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });

  testWidgets('shared chest shows broad readiness spaces and prefills add', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 31);
    final item = InventoryItem(
      id: 'item-1',
      containerId: 'shared',
      productName: '해열진통제',
      itemKind: 'medicine',
      cabinetSection: 'pain_and_fever',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );
    CabinetReadinessTarget? selectedTarget;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildMedicalBoxTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: CabinetShell(
              name: '공용 구급상자',
              items: [item],
              showReadinessGuide: true,
              onItemTap: (_) {},
              onAddToSection: (target) => selectedTarget = target,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('가정용 준비 지도'), findsOneWidget);
    expect(find.text('1/14 등록'), findsOneWidget);
    expect(find.text('상비약'), findsOneWidget);
    expect(find.text('구급용품'), findsOneWidget);
    expect(find.text('알레르기'), findsOneWidget);
    expect(find.text('눈·코 관리'), findsOneWidget);
    expect(find.text('구강·인후'), findsOneWidget);
    expect(find.text('보호·도구'), findsOneWidget);

    await tester.tap(find.text('알레르기'));
    await tester.pump();
    expect(selectedTarget?.section, 'allergy_care');
    expect(selectedTarget?.itemKind, 'medicine');
  });
}
