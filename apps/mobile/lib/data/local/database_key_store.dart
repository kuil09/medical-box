import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyStore {
  DatabaseKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          ),
      _random = random ?? Random.secure();

  static const _databaseKeyName = 'medical_box_database_key_v1';
  static const _tokenPrefix = 'medical_box_auth_';

  final FlutterSecureStorage _storage;
  final Random _random;

  Future<List<int>> readOrCreateDatabaseKey() async {
    final encoded = await _storage.read(key: _databaseKeyName);
    if (encoded != null) {
      final decoded = base64Url.decode(encoded);
      if (decoded.length != 32) {
        throw const FormatException('Invalid database key length.');
      }
      return decoded;
    }

    final key = List<int>.generate(32, (_) => _random.nextInt(256));
    await _storage.write(key: _databaseKeyName, value: base64UrlEncode(key));
    return key;
  }

  Future<void> writeToken(String name, String value) {
    return _storage.write(key: '$_tokenPrefix$name', value: value);
  }

  Future<String?> readToken(String name) {
    return _storage.read(key: '$_tokenPrefix$name');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: '${_tokenPrefix}access');
    await _storage.delete(key: '${_tokenPrefix}refresh');
  }

  Future<void> deleteDatabaseKey() {
    return _storage.delete(key: _databaseKeyName);
  }
}
