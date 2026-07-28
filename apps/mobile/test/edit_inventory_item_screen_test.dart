import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/features/inventory/edit_inventory_item_screen.dart';
import 'package:medical_box/providers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a stale autocomplete response cannot replace current results', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final catalog = _ControlledCatalogRepository();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: EditInventoryItemScreen()),
      ),
    );

    final productName = find.widgetWithText(TextFormField, '제품명');
    await tester.enterText(productName, 'first');
    await tester.pump(const Duration(milliseconds: 351));
    expect(catalog.queries, ['first']);

    await tester.enterText(productName, 'second');
    await tester.pump(const Duration(milliseconds: 351));
    expect(catalog.queries, ['first', 'second']);

    catalog.complete('second', const [
      DrugSummary(itemSeq: '2', itemName: 'Current result'),
    ]);
    await tester.pump();
    expect(find.text('Current result'), findsOneWidget);

    catalog.complete('first', const [
      DrugSummary(itemSeq: '1', itemName: 'Stale result'),
    ]);
    await tester.pump();
    expect(find.text('Current result'), findsOneWidget);
    expect(find.text('Stale result'), findsNothing);
  });

  testWidgets('manual product edits clear every official catalog binding', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final catalog = _ControlledCatalogRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Inventory')),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) =>
              const EditInventoryItemScreen(itemId: 'item-1'),
        ),
      ],
    );
    addTearDown(database.close);
    addTearDown(router.dispose);
    await _insertOfficialInventoryItem(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '제품명'),
      '직접 입력한 제품',
    );
    await tester.scrollUntilVisible(
      find.text('보관함에 저장'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('보관함에 저장'));
    await tester.pumpAndSettle();

    final item = await (database.select(
      database.inventoryItems,
    )..where((row) => row.id.equals('item-1'))).getSingle();
    expect(item.productName, '직접 입력한 제품');
    expect(item.itemSeq, isNull);
    expect(item.ingredientSummary, isNull);
    expect(item.identificationVariantKey, isNull);
    expect(item.officialImageUrl, isNull);
    expect(item.appearanceSummary, isNull);
  });
}

Future<void> _insertOfficialInventoryItem(AppDatabase database) async {
  await database
      .into(database.households)
      .insert(HouseholdsCompanion.insert(id: 'household-1', name: 'Test'));
  await database
      .into(database.inventoryContainers)
      .insert(
        InventoryContainersCompanion.insert(
          id: 'container-1',
          householdId: 'household-1',
          name: 'Shared tray',
          kind: 'shared',
        ),
      );
  await database
      .into(database.inventoryItems)
      .insert(
        InventoryItemsCompanion.insert(
          id: 'item-1',
          containerId: 'container-1',
          productName: 'Official medicine',
          itemSeq: const Value('200000001'),
          ingredientSummary: const Value('Old ingredient'),
          identificationVariantKey: const Value('variant-1'),
          officialImageUrl: const Value('https://example.test/pill.png'),
          appearanceSummary: const Value('Round, white'),
        ),
      );
}

class _ControlledCatalogRepository extends CatalogRepository {
  _ControlledCatalogRepository()
    : super(
        ApiClient(baseUrl: 'https://medicalbox.example/api'),
        accessTokenProvider: () async => 'access',
        refreshAccessTokenProvider: () async => null,
      );

  final List<String> queries = [];
  final Map<String, Completer<List<DrugSummary>>> _pending = {};

  @override
  Future<List<DrugSummary>> search(String query) {
    queries.add(query);
    return (_pending[query] ??= Completer<List<DrugSummary>>()).future;
  }

  void complete(String query, List<DrugSummary> results) {
    _pending[query]!.complete(results);
  }
}
