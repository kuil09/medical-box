import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/local/app_database.dart';

class CatalogCacheService {
  CatalogCacheService(
    this._database, {
    DateTime Function()? clock,
    this.maxEntryBytes = 768 * 1024,
    this.maxTotalBytes = 8 * 1024 * 1024,
    this.maxEntries = 256,
  }) : _clock = clock ?? DateTime.now;

  static const formatVersion = 1;

  final AppDatabase _database;
  final DateTime Function() _clock;
  final int maxEntryBytes;
  final int maxTotalBytes;
  final int maxEntries;

  Future<Map<String, dynamic>?> read({
    required String accountId,
    required String cacheNamespace,
    required String cacheKey,
  }) async {
    final entry =
        await (_database.select(_database.catalogCacheEntries)..where(
              (row) =>
                  row.accountId.equals(accountId) &
                  row.cacheNamespace.equals(cacheNamespace) &
                  row.cacheKey.equals(cacheKey),
            ))
            .getSingleOrNull();
    if (entry == null) return null;

    final now = _clock().toUtc();
    if (entry.formatVersion != formatVersion ||
        !entry.expiresAt.toUtc().isAfter(now)) {
      await _deleteEntry(
        accountId: accountId,
        cacheNamespace: cacheNamespace,
        cacheKey: cacheKey,
      );
      return null;
    }

    try {
      final decoded = jsonDecode(entry.payloadJson);
      if (decoded is! Map) throw const FormatException();
      await (_database.update(_database.catalogCacheEntries)..where(
            (row) =>
                row.accountId.equals(accountId) &
                row.cacheNamespace.equals(cacheNamespace) &
                row.cacheKey.equals(cacheKey),
          ))
          .write(CatalogCacheEntriesCompanion(lastAccessedAt: Value(now)));
      return decoded.cast<String, dynamic>();
    } on FormatException {
      await _deleteEntry(
        accountId: accountId,
        cacheNamespace: cacheNamespace,
        cacheKey: cacheKey,
      );
      return null;
    }
  }

  Future<void> write({
    required String accountId,
    required String cacheNamespace,
    required String cacheKey,
    required Map<String, dynamic> payload,
    required Duration timeToLive,
  }) async {
    final encoded = jsonEncode(payload);
    final byteSize = utf8.encode(encoded).length;
    if (byteSize > maxEntryBytes) return;

    final now = _clock().toUtc();
    await _database.transaction(() async {
      await _database
          .into(_database.catalogCacheEntries)
          .insertOnConflictUpdate(
            CatalogCacheEntriesCompanion.insert(
              accountId: accountId,
              cacheNamespace: cacheNamespace,
              cacheKey: cacheKey,
              formatVersion: formatVersion,
              payloadJson: encoded,
              byteSize: byteSize,
              cachedAt: now,
              expiresAt: now.add(timeToLive),
              lastAccessedAt: now,
            ),
          );
      await _prune(now);
    });
  }

  Future<void> _deleteEntry({
    required String accountId,
    required String cacheNamespace,
    required String cacheKey,
  }) {
    return (_database.delete(_database.catalogCacheEntries)..where(
          (row) =>
              row.accountId.equals(accountId) &
              row.cacheNamespace.equals(cacheNamespace) &
              row.cacheKey.equals(cacheKey),
        ))
        .go();
  }

  Future<void> _prune(DateTime now) async {
    await (_database.delete(
      _database.catalogCacheEntries,
    )..where((row) => row.expiresAt.isSmallerOrEqualValue(now))).go();

    final entries =
        await (_database.select(_database.catalogCacheEntries)..orderBy([
              (row) => OrderingTerm.desc(row.lastAccessedAt),
              (row) => OrderingTerm.desc(row.cachedAt),
            ]))
            .get();
    var retainedBytes = 0;
    var retainedEntries = 0;
    for (final entry in entries) {
      final canRetain =
          retainedEntries < maxEntries &&
          retainedBytes + entry.byteSize <= maxTotalBytes;
      if (canRetain) {
        retainedEntries += 1;
        retainedBytes += entry.byteSize;
        continue;
      }
      await _deleteEntry(
        accountId: entry.accountId,
        cacheNamespace: entry.cacheNamespace,
        cacheKey: entry.cacheKey,
      );
    }
  }
}

class OfficialImageCacheService {
  OfficialImageCacheService(
    this._database, {
    required String? Function() accountIdProvider,
    http.Client? client,
    DateTime Function()? clock,
    this.maxEntryBytes = 3 * 1024 * 1024,
    this.maxTotalBytes = 24 * 1024 * 1024,
    this.maxEntries = 96,
    this.timeToLive = const Duration(days: 30),
  }) : _accountIdProvider = accountIdProvider,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final String? Function() _accountIdProvider;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;
  final int maxEntryBytes;
  final int maxTotalBytes;
  final int maxEntries;
  final Duration timeToLive;
  final Map<String, Future<Uint8List?>> _inFlight = {};

  Future<Uint8List?> load(String imageUrl) {
    final accountId = _accountIdProvider();
    final uri = Uri.tryParse(imageUrl);
    if (accountId == null ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      return Future.value();
    }

    final operationKey = '$accountId\n$imageUrl';
    final existing = _inFlight[operationKey];
    if (existing != null) return existing;

    late final Future<Uint8List?> operation;
    operation = _load(accountId, uri).whenComplete(() {
      if (identical(_inFlight[operationKey], operation)) {
        _inFlight.remove(operationKey);
      }
    });
    _inFlight[operationKey] = operation;
    return operation;
  }

  Future<Uint8List?> _load(String accountId, Uri uri) async {
    final imageUrl = uri.toString();
    final cached =
        await (_database.select(_database.officialImageCacheEntries)..where(
              (row) =>
                  row.accountId.equals(accountId) &
                  row.imageUrl.equals(imageUrl),
            ))
            .getSingleOrNull();
    final now = _clock().toUtc();
    if (cached != null && cached.expiresAt.toUtc().isAfter(now)) {
      await (_database.update(_database.officialImageCacheEntries)..where(
            (row) =>
                row.accountId.equals(accountId) & row.imageUrl.equals(imageUrl),
          ))
          .write(
            OfficialImageCacheEntriesCompanion(lastAccessedAt: Value(now)),
          );
      return Uint8List.fromList(cached.imageBytes);
    }
    if (cached != null) {
      await _deleteEntry(accountId: accountId, imageUrl: imageUrl);
    }

    final downloaded = await _download(uri);
    if (downloaded == null) return null;

    await _database.transaction(() async {
      await _database
          .into(_database.officialImageCacheEntries)
          .insertOnConflictUpdate(
            OfficialImageCacheEntriesCompanion.insert(
              accountId: accountId,
              imageUrl: imageUrl,
              imageBytes: downloaded.bytes,
              contentType: Value(downloaded.contentType),
              byteSize: downloaded.bytes.lengthInBytes,
              cachedAt: now,
              expiresAt: now.add(timeToLive),
              lastAccessedAt: now,
            ),
          );
      await _prune(now);
    });
    return downloaded.bytes;
  }

  Future<_DownloadedImage?> _download(Uri uri) async {
    try {
      final request = http.Request('GET', uri)
        ..headers['accept'] = 'image/avif,image/webp,image/*';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final declaredLength = response.contentLength;
      if (declaredLength != null && declaredLength > maxEntryBytes) return null;

      final builder = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > maxEntryBytes) return null;
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) return null;

      final contentType = response.headers['content-type']?.split(';').first;
      if (!_looksLikeSupportedImage(bytes)) return null;
      return _DownloadedImage(bytes, contentType);
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeSupportedImage(Uint8List bytes) {
    if (bytes.lengthInBytes >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return true;
    }
    if (bytes.lengthInBytes >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes.lengthInBytes >= 12) {
      final prefix = ascii.decode(bytes.sublist(0, 4), allowInvalid: true);
      final format = ascii.decode(bytes.sublist(8, 12), allowInvalid: true);
      if (prefix == 'RIFF' && format == 'WEBP') return true;
    }
    if (bytes.lengthInBytes >= 6) {
      final signature = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') return true;
    }
    return false;
  }

  Future<void> _deleteEntry({
    required String accountId,
    required String imageUrl,
  }) {
    return (_database.delete(_database.officialImageCacheEntries)..where(
          (row) =>
              row.accountId.equals(accountId) & row.imageUrl.equals(imageUrl),
        ))
        .go();
  }

  Future<void> _prune(DateTime now) async {
    await (_database.delete(
      _database.officialImageCacheEntries,
    )..where((row) => row.expiresAt.isSmallerOrEqualValue(now))).go();

    final entries =
        await (_database.select(_database.officialImageCacheEntries)..orderBy([
              (row) => OrderingTerm.desc(row.lastAccessedAt),
              (row) => OrderingTerm.desc(row.cachedAt),
            ]))
            .get();
    var retainedBytes = 0;
    var retainedEntries = 0;
    for (final entry in entries) {
      final canRetain =
          retainedEntries < maxEntries &&
          retainedBytes + entry.byteSize <= maxTotalBytes;
      if (canRetain) {
        retainedEntries += 1;
        retainedBytes += entry.byteSize;
        continue;
      }
      await _deleteEntry(accountId: entry.accountId, imageUrl: entry.imageUrl);
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class _DownloadedImage {
  const _DownloadedImage(this.bytes, this.contentType);

  final Uint8List bytes;
  final String? contentType;
}
