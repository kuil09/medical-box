import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/features/home/home_screen.dart';
import 'package:medical_box/providers.dart';
import 'package:medical_box/theme.dart';
import 'package:medical_box/widgets/app_shell.dart';

void main() {
  setUpAll(() async {
    final notoLoader = FontLoader('Noto Sans KR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR-Variable.ttf'));
    final iconLoader =
        FontLoader('packages/phosphoricons_flutter/PhosphorRegular')..addFont(
          rootBundle.load(
            'packages/phosphoricons_flutter/lib/fonts/Phosphor.ttf',
          ),
        );
    await Future.wait([notoLoader.load(), iconLoader.load()]);
  });

  testWidgets('cabinet home matches the closed and open design states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 884));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime(2026, 7, 30);
    final sharedItems = [
      InventoryItem(
        id: 'pain',
        containerId: 'shared',
        productName: '타이레놀정500밀리그람',
        manufacturer: '한국얀센',
        quantity: 1,
        unit: '개',
        expiresOn: DateTime(2026, 8, 20),
        storageNote: '해열·진통',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItem(
        id: 'digestive',
        containerId: 'shared',
        productName: '베아제정',
        manufacturer: '대웅제약',
        quantity: 1,
        unit: '개',
        storageNote: '소화',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItem(
        id: 'pain-2',
        containerId: 'shared',
        productName: '이지엔6 이브',
        manufacturer: '대웅제약',
        quantity: 1,
        unit: '개',
        expiresOn: DateTime(2026, 8, 25),
        storageNote: '해열·진통',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItem(
        id: 'wound',
        containerId: 'shared',
        productName: '후시딘연고',
        manufacturer: '동화약품',
        quantity: 1,
        unit: '개',
        storageNote: '상처',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final pouches = [
      InventoryContainer(
        id: 'self',
        householdId: 'household',
        ownerMemberId: 'member-self',
        name: '나 파우치',
        kind: 'personal',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      ),
      InventoryContainer(
        id: 'mother',
        householdId: 'household',
        ownerMemberId: 'member-mother',
        name: '엄마 파우치',
        kind: 'personal',
        sortOrder: 20,
        createdAt: now,
        updatedAt: now,
      ),
      InventoryContainer(
        id: 'child',
        householdId: 'household',
        ownerMemberId: 'member-child',
        name: '아이 파우치',
        kind: 'personal',
        sortOrder: 30,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => Stream.value(sharedItems)),
          sharedInventoryProvider.overrideWith(
            (ref) => Stream.value(sharedItems),
          ),
          containersProvider.overrideWith((ref) => Stream.value(pouches)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMedicalBoxTheme(),
          home: const AppShell(location: '/', child: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/cabinet_home_closed.png'),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/cabinet_home_open.png'),
    );
  });
}
