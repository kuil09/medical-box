import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/features/inventory/inventory_item_detail_screen.dart';
import 'package:medical_box/providers.dart';

void main() {
  testWidgets(
    'inventory item detail is read-only and opens a separate editor',
    (tester) async {
      final now = DateTime(2026, 7, 30);
      final item = InventoryItem(
        id: 'item-1',
        containerId: 'container-1',
        productName: '타이레놀정500밀리그람',
        manufacturer: '한국얀센',
        quantity: 1,
        unit: '개',
        expiresOn: DateTime(2027, 8, 31),
        storageNote: '공용 트레이 오른쪽 칸',
        privateNote: '두통이 심할 때 확인',
        createdAt: now,
        updatedAt: now,
      );
      final router = GoRouter(
        initialLocation: '/inventory/item-1',
        routes: [
          GoRoute(
            path: '/inventory/:id/edit',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Separate editor'))),
          ),
          GoRoute(
            path: '/inventory/:id',
            builder: (context, state) =>
                InventoryItemDetailScreen(itemId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemProvider.overrideWith(
              (ref, id) => Stream.value(id == item.id ? item : null),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('의약품 상세'), findsOneWidget);
      expect(find.text('타이레놀정500밀리그람'), findsOneWidget);
      expect(find.text('2027년 8월 31일'), findsOneWidget);
      expect(find.text('공용 트레이 오른쪽 칸'), findsOneWidget);
      expect(find.text('두통이 심할 때 확인'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('변경사항 저장'), findsNothing);
      expect(find.text('삭제'), findsNothing);

      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      expect(find.text('Separate editor'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('linked item detail presents official information read-only', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 30);
    final item = InventoryItem(
      id: 'item-1',
      containerId: 'container-1',
      itemSeq: '200000001',
      productName: '타이레놀정500밀리그람',
      manufacturer: '한국얀센',
      quantity: 1,
      unit: '개',
      createdAt: now,
      updatedAt: now,
    );
    final contraindicatedItem = InventoryItem(
      id: 'item-2',
      containerId: 'container-1',
      itemSeq: '200000002',
      productName: '병용 확인 약',
      manufacturer: '테스트제약',
      quantity: 1,
      unit: '개',
      storageNote: '공용 트레이 왼쪽 칸',
      createdAt: now,
      updatedAt: now,
    );
    const detail = DrugDetail(
      itemSeq: '200000001',
      itemName: '타이레놀정500밀리그람',
      manufacturer: '한국얀센',
      ingredients: ['아세트아미노펜 500mg'],
      storageMethod: '밀폐용기, 실온 보관',
      efficacy: '감기로 인한 발열 및 동통 완화',
      sources: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemProvider.overrideWith(
            (ref, id) => Stream.value(id == item.id ? item : null),
          ),
          inventoryProvider.overrideWith(
            (ref) => Stream.value([item, contraindicatedItem]),
          ),
          catalogDetailProvider.overrideWith((ref, id) async => detail),
          concomitantSafetyRulesProvider.overrideWith(
            (ref, itemSeq) async => const [
              DrugSafetyRule(
                ruleType: 'concomitant_contraindication',
                sourceCode: 'mfds_dur_product_concomitant',
                counterpartItemSeq: '200000002',
                counterpartItemName: '병용 확인 약',
                prohibitionContent: '두 성분을 함께 사용하지 않도록 확인하세요.',
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: InventoryItemDetailScreen(itemId: 'item-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공식 의약품 정보'), findsOneWidget);
    expect(find.text('아세트아미노펜 500mg'), findsOneWidget);
    expect(find.text('밀폐용기, 실온 보관'), findsOneWidget);
    expect(find.text('감기로 인한 발열 및 동통 완화'), findsOneWidget);
    expect(find.text('함께 사용하기 전 확인하세요'), findsOneWidget);
    expect(find.text('병용 확인 약'), findsOneWidget);
    expect(find.text('두 성분을 함께 사용하지 않도록 확인하세요.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
