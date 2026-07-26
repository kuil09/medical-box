import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/services/medical_box_export_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('local inventory CRUD remains inside the database boundary', () async {
    await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(id: 'home', name: 'Household'));
    await database
        .into(database.inventoryContainers)
        .insert(
          InventoryContainersCompanion.insert(
            id: 'tray',
            householdId: 'home',
            name: 'Shared tray',
            kind: 'shared',
          ),
        );
    await database.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        id: 'item',
        containerId: 'tray',
        productName: 'Test medicine',
        quantity: const Value(2),
      ),
    );

    await database.setQuantity('item', 3);
    expect((await database.watchInventory().first).single.quantity, 3);

    await database.deleteInventoryItem('item');
    expect(await database.watchInventory().first, isEmpty);
  });

  test(
    'family pouch inventory stays scoped and cascades on member removal',
    () async {
      await database
          .into(database.households)
          .insert(HouseholdsCompanion.insert(id: 'home', name: 'Household'));
      await database
          .into(database.memberProfiles)
          .insert(
            MemberProfilesCompanion.insert(
              id: 'member',
              householdId: 'home',
              displayName: 'Family member',
            ),
          );
      await database
          .into(database.inventoryContainers)
          .insert(
            InventoryContainersCompanion.insert(
              id: 'tray',
              householdId: 'home',
              name: 'Shared tray',
              kind: 'shared',
            ),
          );
      await database
          .into(database.inventoryContainers)
          .insert(
            InventoryContainersCompanion.insert(
              id: 'pouch',
              householdId: 'home',
              ownerMemberId: const Value('member'),
              name: 'Family member pouch',
              kind: 'personal',
            ),
          );
      await database.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          id: 'shared-item',
          containerId: 'tray',
          productName: 'Shared medicine',
        ),
      );
      await database.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          id: 'pouch-item',
          containerId: 'pouch',
          productName: 'Pouch medicine',
        ),
      );

      expect(
        (await database.watchInventoryByContainerKind('shared').first)
            .single
            .id,
        'shared-item',
      );
      expect(
        (await database.watchInventoryForContainer('pouch').first).single.id,
        'pouch-item',
      );

      await database.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          id: 'pouch-item',
          containerId: 'pouch',
          productName: 'Edited pouch medicine',
          quantity: const Value(3),
        ),
      );
      final edited =
          (await database.watchInventoryForContainer('pouch').first).single;
      expect(edited.productName, 'Edited pouch medicine');
      expect(edited.quantity, 3);

      await database.transaction(() async {
        await (database.delete(
          database.inventoryContainers,
        )..where((row) => row.id.equals('pouch'))).go();
        await (database.delete(
          database.memberProfiles,
        )..where((row) => row.id.equals('member'))).go();
      });

      expect(await database.watchInventoryForContainer('pouch').first, isEmpty);
      expect(await database.select(database.memberProfiles).get(), isEmpty);
      expect(
        (await database.watchInventoryByContainerKind('shared').first)
            .single
            .id,
        'shared-item',
      );
    },
  );

  test('medicalbox export decrypts and restores the local snapshot', () async {
    await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(id: 'home', name: 'Household'));
    await database
        .into(database.inventoryContainers)
        .insert(
          InventoryContainersCompanion.insert(
            id: 'tray',
            householdId: 'home',
            name: 'Shared tray',
            kind: 'shared',
          ),
        );
    await database.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        id: 'item',
        containerId: 'tray',
        productName: 'Private medicine',
        itemSeq: const Value('200000001'),
        identificationVariantKey: const Value('variant-a'),
        officialImageUrl: const Value('https://example.test/pill.png'),
        appearanceSummary: const Value('Round · White · Front A1'),
        privateNote: const Value('Device-only note'),
      ),
    );
    final service = MedicalBoxExportService(database);
    final encrypted = await service.createExportBytes('strong-passphrase');

    expect(
      String.fromCharCodes(encrypted),
      isNot(contains('Private medicine')),
    );
    await database.deleteAllLocalData();
    expect(await database.watchInventory().first, isEmpty);

    await service.importExport(encrypted, 'strong-passphrase');
    final restored = await database.watchInventory().first;
    expect(restored.single.productName, 'Private medicine');
    expect(restored.single.privateNote, 'Device-only note');
    expect(restored.single.identificationVariantKey, 'variant-a');
    expect(restored.single.appearanceSummary, 'Round · White · Front A1');
  });

  test('SQLite3MultipleCiphers survives a keyed restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'medical-box-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/encrypted.sqlite');
    final key = List<int>.generate(32, (index) => index + 1);

    final first = AppDatabase(createEncryptedExecutor(file, key));
    await first
        .into(first.households)
        .insert(
          HouseholdsCompanion.insert(id: 'home', name: 'Encrypted household'),
        );
    await first.close();

    final header = await file
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    expect(String.fromCharCodes(header), isNot(startsWith('SQLite format 3')));

    final reopened = AppDatabase(createEncryptedExecutor(file, key));
    expect(
      (await reopened.select(reopened.households).get()).single.name,
      'Encrypted household',
    );
    await reopened.close();
  });
}
