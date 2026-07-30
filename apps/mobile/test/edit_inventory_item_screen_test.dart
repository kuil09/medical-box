import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/auth/auth_repository.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/data/local/database_key_store.dart';
import 'package:medical_box/features/inventory/edit_inventory_item_screen.dart';
import 'package:medical_box/providers.dart';
import 'package:medical_box/services/inventory_photo_service.dart';
import 'package:medical_box/services/medicine_ocr_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('medicine editor omits low-value quantity and privacy notices', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: EditInventoryItemScreen()),
      ),
    );

    expect(find.text('수량'), findsNothing);
    expect(
      find.text('로그인 후 검색어만 공식 카탈로그 조회에 사용하고, 사진·사용기한·메모는 서버로 보내지 않아요.'),
      findsNothing,
    );
    expect(find.text('보관품 등록'), findsOneWidget);
    expect(find.text('제품명 촬영'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('약장에 등록'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('약장에 등록'), findsOneWidget);
    expect(find.text('보관 대상'), findsOneWidget);
    expect(find.text('약장 칸'), findsOneWidget);
    await _disposeWidget(tester);
  });

  testWidgets('existing medicine editor has a distinct focused edit state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await _insertOfficialInventoryItem(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: EditInventoryItemScreen(itemId: 'item-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('보관품 수정'), findsOneWidget);
    expect(find.text('제품명 촬영'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('변경사항 저장'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('변경사항 저장'), findsOneWidget);
    expect(find.text('약장에 등록'), findsNothing);
    await _disposeWidget(tester);
  });

  testWidgets('first-aid supply keeps its selected pouch, section, and photo', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(id: 'household-1', name: 'Test'));
    await database
        .into(database.inventoryContainers)
        .insert(
          InventoryContainersCompanion.insert(
            id: 'shared-1',
            householdId: 'household-1',
            name: '공용 약장',
            kind: 'shared',
          ),
        );
    await database
        .into(database.inventoryContainers)
        .insert(
          InventoryContainersCompanion.insert(
            id: 'pouch-1',
            householdId: 'household-1',
            name: '아이 파우치',
            kind: 'personal',
            sortOrder: const Value(10),
          ),
        );

    final photoBytes = Uint8List.fromList([1, 2, 3, 4]);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Inventory')),
        ),
        GoRoute(
          path: '/new',
          builder: (context, state) =>
              const EditInventoryItemScreen(containerId: 'pouch-1'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          inventoryPhotoCaptureProvider.overrideWithValue(
            _FakeInventoryPhotoCapture(photoBytes),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/new');
    await tester.pumpAndSettle();

    await tester.tap(find.text('구급용품'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '제품명'), '방수 밴드');
    await tester.tap(find.text('직접 촬영'));
    await tester.pumpAndSettle();
    expect(find.text('내 보관 사진'), findsOneWidget);
    expect(find.text('아이 파우치'), findsOneWidget);
    expect(find.text('상처 관리'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('약장에 등록'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('약장에 등록'));
    await tester.pumpAndSettle();

    final item = await database.select(database.inventoryItems).getSingle();
    expect(item.containerId, 'pouch-1');
    expect(item.itemKind, 'first_aid_supply');
    expect(item.cabinetSection, 'wound_care');
    expect(item.capturedImageBytes, photoBytes);
    expect(item.itemSeq, isNull);
    await _disposeWidget(tester);
  });

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
    await _disposeWidget(tester);
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
      find.text('변경사항 저장'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('변경사항 저장'));
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
    await _disposeWidget(tester);
  });

  testWidgets('on-device OCR opens official candidates without auto-saving', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final catalog = _PhotoCatalogRepository();
    final auth = AuthRepository(
      ApiClient(baseUrl: 'https://medicalbox.example/api'),
      DatabaseKeyStore(),
      targetPlatform: TargetPlatform.android,
    );
    addTearDown(database.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          catalogRepositoryProvider.overrideWithValue(catalog),
          authRepositoryProvider.overrideWithValue(auth),
          authSessionProvider.overrideWith(
            (ref) async => const AccountProfile(
              id: 'account-1',
              providers: ['google'],
              permissions: ['catalog:read'],
            ),
          ),
          medicineScannerProvider.overrideWithValue(
            const _FakeMedicineScanner(),
          ),
        ],
        child: const MaterialApp(home: EditInventoryItemScreen()),
      ),
    );

    await tester.tap(find.text('제품명 촬영'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('사진에서 찾은 등록 후보'), findsOneWidget);
    expect(find.text('타이레놀정500밀리그람'), findsOneWidget);
    expect(catalog.queries, contains('타이레놀정'));
    final productField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, '제품명'),
    );
    expect(productField.controller?.text, isEmpty);
    await _disposeWidget(tester);
  });
}

Future<void> _disposeWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
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

class _PhotoCatalogRepository extends CatalogRepository {
  _PhotoCatalogRepository()
    : super(
        ApiClient(baseUrl: 'https://medicalbox.example/api'),
        accessTokenProvider: () async => 'access',
        refreshAccessTokenProvider: () async => null,
      );

  final List<String> queries = [];

  @override
  Future<List<DrugSummary>> search(String query) async {
    queries.add(query);
    if (query == '타이레놀정') {
      return const [
        DrugSummary(
          itemSeq: '200000001',
          itemName: '타이레놀정500밀리그람',
          manufacturer: '한국얀센',
          status: '정상',
        ),
      ];
    }
    return const [];
  }
}

class _FakeMedicineScanner implements MedicineScanner {
  const _FakeMedicineScanner();

  @override
  Future<MedicineScanResult?> scan() async {
    return const MedicineScanResult(
      lines: [
        MedicineOcrLine(text: '일반의약품'),
        MedicineOcrLine(text: '타이레놀정 500밀리그람', confidence: 0.96),
        MedicineOcrLine(text: '한국얀센', confidence: 0.9),
      ],
    );
  }
}

class _FakeInventoryPhotoCapture implements InventoryPhotoCapture {
  const _FakeInventoryPhotoCapture(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> capture() async => bytes;
}
