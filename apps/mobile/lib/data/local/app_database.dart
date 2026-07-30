import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'database_key_store.dart';

part 'app_database.g.dart';

class Households extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemberProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get displayName => text().withLength(min: 1, max: 60)();
  TextColumn get colorHex => text().withDefault(const Constant('#91C8E4'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InventoryContainers extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get ownerMemberId => text().nullable().references(
    MemberProfiles,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get kind => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get containerId => text().references(
    InventoryContainers,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get itemSeq => text().nullable()();
  TextColumn get productName => text().withLength(min: 1, max: 200)();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get ingredientSummary => text().nullable()();
  TextColumn get identificationVariantKey => text().nullable()();
  TextColumn get officialImageUrl => text().nullable()();
  BlobColumn get capturedImageBytes => blob().nullable()();
  TextColumn get appearanceSummary => text().nullable()();
  TextColumn get itemKind => text().withDefault(const Constant('medicine'))();
  TextColumn get officialCategory => text().nullable()();
  TextColumn get cabinetSection =>
      text().withDefault(const Constant('other'))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('개'))();
  DateTimeColumn get expiresOn => dateTime().nullable()();
  TextColumn get storageNote => text().nullable()();
  TextColumn get privateNote => text().nullable()();
  TextColumn get assignedMemberId => text().nullable().references(
    MemberProfiles,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RenewalReadiness extends Table {
  TextColumn get id => text()();
  TextColumn get inventoryItemId =>
      text().references(InventoryItems, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get nextVisitOn => dateTime().nullable()();
  BoolColumn get prescriptionPhotoChecked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get remainingQuantityChecked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get questionsPrepared =>
      boolean().withDefault(const Constant(false))();
  TextColumn get visitNote => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get inventoryItemId => text().nullable().references(
    InventoryItems,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get kind => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get hidesMedicineName =>
      boolean().withDefault(const Constant(true))();
  TextColumn get privateLabel => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationPrivacy =>
      boolean().withDefault(const Constant(true))();
  TextColumn get localeCode => text().withDefault(const Constant('ko'))();
  TextColumn get environment =>
      text().withDefault(const Constant('production'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Households,
    MemberProfiles,
    InventoryContainers,
    InventoryItems,
    RenewalReadiness,
    Reminders,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await migrator.createAll();
      await into(appSettings).insert(const AppSettingsCompanion());
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          inventoryItems,
          inventoryItems.identificationVariantKey,
        );
        await migrator.addColumn(
          inventoryItems,
          inventoryItems.officialImageUrl,
        );
        await migrator.addColumn(
          inventoryItems,
          inventoryItems.appearanceSummary,
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          inventoryItems,
          inventoryItems.capturedImageBytes,
        );
        await migrator.addColumn(inventoryItems, inventoryItems.itemKind);
        await migrator.addColumn(
          inventoryItems,
          inventoryItems.officialCategory,
        );
        await migrator.addColumn(inventoryItems, inventoryItems.cabinetSection);
        await customStatement('''
          UPDATE inventory_items
          SET cabinet_section = CASE
            WHEN lower(product_name) LIKE '%밴드%'
              OR lower(product_name) LIKE '%거즈%'
              OR lower(product_name) LIKE '%소독%'
              OR lower(product_name) LIKE '%상처%'
              OR lower(product_name) LIKE '%연고%'
              THEN 'wound_care'
            WHEN lower(product_name) LIKE '%소화%'
              OR lower(product_name) LIKE '%위장%'
              OR lower(product_name) LIKE '%제산%'
              OR lower(product_name) LIKE '%정장%'
              THEN 'digestion'
            WHEN lower(product_name) LIKE '%해열%'
              OR lower(product_name) LIKE '%진통%'
              OR lower(product_name) LIKE '%타이레놀%'
              OR lower(product_name) LIKE '%아세트아미노펜%'
              OR lower(product_name) LIKE '%이부프로펜%'
              THEN 'pain_and_fever'
            ELSE 'other'
          END
        ''');
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA secure_delete = ON');
    },
  );

  Stream<List<InventoryItem>> watchInventory() {
    return (select(
      inventoryItems,
    )..orderBy([(row) => OrderingTerm.asc(row.productName)])).watch();
  }

  Stream<List<InventoryItem>> watchInventoryForContainer(String containerId) {
    return (select(inventoryItems)
          ..where((row) => row.containerId.equals(containerId))
          ..orderBy([(row) => OrderingTerm.asc(row.productName)]))
        .watch();
  }

  Stream<InventoryItem?> watchInventoryItem(String id) {
    return (select(
      inventoryItems,
    )..where((row) => row.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<InventoryItem>> watchInventoryByContainerKind(String kind) {
    final query =
        select(inventoryItems).join([
            innerJoin(
              inventoryContainers,
              inventoryContainers.id.equalsExp(inventoryItems.containerId),
            ),
          ])
          ..where(inventoryContainers.kind.equals(kind))
          ..orderBy([OrderingTerm.asc(inventoryItems.productName)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(inventoryItems)).toList(),
    );
  }

  Stream<List<InventoryContainer>> watchContainers() {
    return (select(
      inventoryContainers,
    )..orderBy([(row) => OrderingTerm.asc(row.sortOrder)])).watch();
  }

  Stream<List<Reminder>> watchReminders() {
    return (select(
      reminders,
    )..orderBy([(row) => OrderingTerm.asc(row.scheduledAt)])).watch();
  }

  Stream<List<RenewalReadinessData>> watchRenewalReadiness() {
    return (select(
      renewalReadiness,
    )..orderBy([(row) => OrderingTerm.asc(row.nextVisitOn)])).watch();
  }

  Future<void> upsertInventoryItem(InventoryItemsCompanion item) {
    return into(inventoryItems).insertOnConflictUpdate(item);
  }

  Future<void> deleteInventoryItem(String id) {
    return (delete(inventoryItems)..where((row) => row.id.equals(id))).go();
  }

  Future<void> setQuantity(String id, int quantity) {
    return (update(inventoryItems)..where((row) => row.id.equals(id))).write(
      InventoryItemsCompanion(
        quantity: Value(quantity.clamp(0, 9999)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<AppSetting> getSettings() async {
    final found = await (select(
      appSettings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    if (found != null) return found;
    await into(appSettings).insert(const AppSettingsCompanion());
    return (select(appSettings)..where((row) => row.id.equals(1))).getSingle();
  }

  Future<void> setOnboardingCompleted() {
    return (update(appSettings)..where((row) => row.id.equals(1))).write(
      AppSettingsCompanion(
        onboardingCompleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setNotificationPrivacy(bool enabled) {
    return (update(appSettings)..where((row) => row.id.equals(1))).write(
      AppSettingsCompanion(
        notificationPrivacy: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Map<String, Object?>> exportSnapshot() async {
    final inventoryRows = (await select(inventoryItems).get()).map((row) {
      final json = row.toJson();
      json['capturedImageBytes'] = row.capturedImageBytes == null
          ? null
          : base64Encode(row.capturedImageBytes!);
      return json;
    }).toList();
    return {
      'households': (await select(
        households,
      ).get()).map((row) => row.toJson()).toList(),
      'memberProfiles': (await select(
        memberProfiles,
      ).get()).map((row) => row.toJson()).toList(),
      'inventoryContainers': (await select(
        inventoryContainers,
      ).get()).map((row) => row.toJson()).toList(),
      'inventoryItems': inventoryRows,
      'renewalReadiness': (await select(
        renewalReadiness,
      ).get()).map((row) => row.toJson()).toList(),
      'reminders': (await select(
        reminders,
      ).get()).map((row) => row.toJson()).toList(),
      'appSettings': (await select(
        appSettings,
      ).get()).map((row) => row.toJson()).toList(),
    };
  }

  Future<void> importSnapshot(Map<String, Object?> snapshot) async {
    List<Map<String, dynamic>> rows(String key) {
      final value = snapshot[key];
      if (value is! List) {
        throw FormatException('Missing snapshot collection: $key');
      }
      return value.map((entry) {
        if (entry is! Map) {
          throw FormatException('Invalid row in: $key');
        }
        return entry.cast<String, dynamic>();
      }).toList();
    }

    await transaction(() async {
      await batch((batch) {
        batch.deleteAll(reminders);
        batch.deleteAll(renewalReadiness);
        batch.deleteAll(inventoryItems);
        batch.deleteAll(inventoryContainers);
        batch.deleteAll(memberProfiles);
        batch.deleteAll(households);
        batch.deleteAll(appSettings);
      });

      for (final row in rows('households')) {
        await into(households).insert(Household.fromJson(row));
      }
      for (final row in rows('memberProfiles')) {
        await into(memberProfiles).insert(MemberProfile.fromJson(row));
      }
      for (final row in rows('inventoryContainers')) {
        await into(
          inventoryContainers,
        ).insert(InventoryContainer.fromJson(row));
      }
      for (final row in rows('inventoryItems')) {
        final normalized = Map<String, dynamic>.of(row);
        normalized.putIfAbsent('itemKind', () => 'medicine');
        normalized.putIfAbsent('officialCategory', () => null);
        normalized.putIfAbsent('cabinetSection', () => 'other');
        final encodedImage = normalized['capturedImageBytes'];
        normalized['capturedImageBytes'] = switch (encodedImage) {
          String value => base64Decode(value),
          List<int> value => Uint8List.fromList(value),
          _ => null,
        };
        await into(inventoryItems).insert(InventoryItem.fromJson(normalized));
      }
      for (final row in rows('renewalReadiness')) {
        await into(renewalReadiness).insert(RenewalReadinessData.fromJson(row));
      }
      for (final row in rows('reminders')) {
        await into(reminders).insert(Reminder.fromJson(row));
      }
      for (final row in rows('appSettings')) {
        await into(appSettings).insert(AppSetting.fromJson(row));
      }
    });
  }

  Future<void> deleteAllLocalData() async {
    await transaction(() async {
      await batch((batch) {
        batch.deleteAll(reminders);
        batch.deleteAll(renewalReadiness);
        batch.deleteAll(inventoryItems);
        batch.deleteAll(inventoryContainers);
        batch.deleteAll(memberProfiles);
        batch.deleteAll(households);
        batch.deleteAll(appSettings);
      });
      await into(appSettings).insert(const AppSettingsCompanion());
    });
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await customStatement('VACUUM');
  }

  String debugSnapshot() => jsonEncode({'schemaVersion': schemaVersion});
}

Future<AppDatabase> openEncryptedDatabase(DatabaseKeyStore keyStore) async {
  final support = await getApplicationSupportDirectory();
  final databaseFile = File(path.join(support.path, 'medical-box.sqlite'));
  await const MethodChannel(
    'medical_box/platform',
  ).invokeMethod<void>('excludeFromBackup', support.path).catchError((_) {});

  final key = await keyStore.readOrCreateDatabaseKey();
  return AppDatabase(createEncryptedExecutor(databaseFile, key));
}

QueryExecutor createEncryptedExecutor(File databaseFile, List<int> key) {
  if (key.length != 32) {
    throw ArgumentError.value(key.length, 'key', 'Expected a 256-bit key.');
  }
  final keyHex = key
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return NativeDatabase(
    databaseFile,
    setup: (database) {
      database.execute('PRAGMA cipher = "chacha20"');
      final cipher = database.select('PRAGMA cipher');
      if (cipher.isEmpty) {
        throw StateError('SQLite3MultipleCiphers is not active.');
      }
      database.execute("PRAGMA key = \"x'$keyHex'\"");
      database.select('SELECT count(*) FROM sqlite_master');
      database.execute('PRAGMA secure_delete = ON');
      database.execute('PRAGMA journal_mode = WAL');
    },
  );
}
