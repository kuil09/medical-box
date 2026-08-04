import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/services/catalog_cache_service.dart';

void main() {
  late AppDatabase database;
  late DateTime now;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 7, 31, 3);
  });

  tearDown(() => database.close());

  test('catalog documents are account-scoped and expire', () async {
    final cache = CatalogCacheService(database, clock: () => now);
    await cache.write(
      accountId: 'account-a',
      cacheNamespace: 'catalog-v1:sync-a:10',
      cacheKey: 'detail:123',
      payload: {'itemSeq': '123', 'itemName': 'Test medicine'},
      timeToLive: const Duration(hours: 1),
    );

    expect(
      await cache.read(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'detail:123',
      ),
      containsPair('itemName', 'Test medicine'),
    );
    expect(
      await cache.read(
        accountId: 'account-b',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'detail:123',
      ),
      isNull,
    );

    now = now.add(const Duration(hours: 1));
    expect(
      await cache.read(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'detail:123',
      ),
      isNull,
    );
    expect(await database.select(database.catalogCacheEntries).get(), isEmpty);
  });

  test('catalog documents evict the least recently used entry', () async {
    final cache = CatalogCacheService(
      database,
      clock: () => now,
      maxEntries: 2,
    );

    Future<void> write(String key) async {
      await cache.write(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: key,
        payload: {'key': key},
        timeToLive: const Duration(days: 1),
      );
      now = now.add(const Duration(seconds: 1));
    }

    await write('first');
    await write('second');
    await cache.read(
      accountId: 'account-a',
      cacheNamespace: 'catalog-v1:sync-a:10',
      cacheKey: 'first',
    );
    now = now.add(const Duration(seconds: 1));
    await write('third');

    expect(
      await cache.read(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'first',
      ),
      isNotNull,
    );
    expect(
      await cache.read(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'second',
      ),
      isNull,
    );
    expect(
      await cache.read(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'third',
      ),
      isNotNull,
    );
  });

  test(
    'official images persist per account and honor access removal',
    () async {
      String? accountId = 'account-a';
      var networkRequests = 0;
      final imageBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]);
      final service = OfficialImageCacheService(
        database,
        accountIdProvider: () => accountId,
        client: MockClient((_) async {
          networkRequests += 1;
          return http.Response.bytes(
            imageBytes,
            200,
            headers: {'content-type': 'image/png'},
          );
        }),
        clock: () => now,
      );
      addTearDown(service.close);

      const imageUrl = 'https://example.test/official.png';
      expect(await service.load(imageUrl), imageBytes);
      expect(await service.load(imageUrl), imageBytes);
      expect(networkRequests, 1);

      accountId = 'account-b';
      expect(await service.load(imageUrl), imageBytes);
      expect(networkRequests, 2);

      accountId = null;
      expect(await service.load(imageUrl), isNull);
      expect(networkRequests, 2);

      await database.deleteCachedCatalogForAccount('account-a');
      expect(
        await (database.select(
          database.officialImageCacheEntries,
        )..where((row) => row.accountId.equals('account-a'))).get(),
        isEmpty,
      );
      expect(
        await (database.select(
          database.officialImageCacheEntries,
        )..where((row) => row.accountId.equals('account-b'))).get(),
        hasLength(1),
      );
    },
  );

  test('official images reject oversized responses', () async {
    final service = OfficialImageCacheService(
      database,
      accountIdProvider: () => 'account-a',
      maxEntryBytes: 4,
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('too large'),
          200,
          headers: {'content-type': 'image/png'},
        ),
      ),
    );
    addTearDown(service.close);

    expect(await service.load('https://example.test/oversized.png'), isNull);
    expect(
      await database.select(database.officialImageCacheEntries).get(),
      isEmpty,
    );
  });

  test(
    'device exports exclude caches and device deletion clears them',
    () async {
      final catalogCache = CatalogCacheService(database, clock: () => now);
      await catalogCache.write(
        accountId: 'account-a',
        cacheNamespace: 'catalog-v1:sync-a:10',
        cacheKey: 'detail:123',
        payload: {'itemSeq': '123'},
        timeToLive: const Duration(days: 1),
      );
      final imageCache = OfficialImageCacheService(
        database,
        accountIdProvider: () => 'account-a',
        client: MockClient(
          (_) async => http.Response.bytes(
            [0xff, 0xd8, 0xff, 0xd9],
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
        ),
        clock: () => now,
      );
      addTearDown(imageCache.close);
      await imageCache.load('https://example.test/official.jpg');

      final snapshot = await database.exportSnapshot();
      expect(snapshot, isNot(contains('catalogCacheEntries')));
      expect(snapshot, isNot(contains('officialImageCacheEntries')));

      await database.deleteAllLocalData();
      expect(
        await database.select(database.catalogCacheEntries).get(),
        isEmpty,
      );
      expect(
        await database.select(database.officialImageCacheEntries).get(),
        isEmpty,
      );
    },
  );
}
