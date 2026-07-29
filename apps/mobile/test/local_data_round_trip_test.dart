import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
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
    final envelope = jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
    final kdf = envelope['kdf'] as Map<String, dynamic>;
    final cipher = envelope['cipher'] as Map<String, dynamic>;
    expect(envelope['version'], 2);
    expect(kdf['name'], 'argon2id');
    expect(cipher['name'], 'aes-256-gcm');
    expect(base64Url.decode(cipher['nonce'] as String), hasLength(12));
    expect(base64Url.decode(cipher['mac'] as String), hasLength(16));

    final secondEncrypted = await service.createExportBytes(
      'strong-passphrase',
    );
    final secondEnvelope =
        jsonDecode(utf8.decode(secondEncrypted)) as Map<String, dynamic>;
    final secondKdf = secondEnvelope['kdf'] as Map<String, dynamic>;
    final secondCipher = secondEnvelope['cipher'] as Map<String, dynamic>;
    expect(secondKdf['salt'], isNot(kdf['salt']));
    expect(secondCipher['nonce'], isNot(cipher['nonce']));

    await expectLater(
      service.importExport(encrypted, 'different-passphrase'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    expect((await database.watchInventory().first).single.id, 'item');

    final tamperedCiphertext = base64Url.decode(cipher['ciphertext'] as String);
    tamperedCiphertext[0] ^= 1;
    cipher['ciphertext'] = base64UrlEncode(tamperedCiphertext);
    final tampered = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    await expectLater(
      service.importExport(tampered, 'strong-passphrase'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    expect((await database.watchInventory().first).single.id, 'item');

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
