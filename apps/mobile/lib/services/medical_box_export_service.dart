import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/local/app_database.dart';

class MedicalBoxExportService {
  MedicalBoxExportService(
    this._database, {
    Random? random,
    Future<Directory> Function()? temporaryDirectory,
  }) : _random = random ?? Random.secure(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static const format = 'com.medicalbox.export';
  static const version = 1;
  static const _aad = 'medicalbox:v1';
  static const _argonMemoryKiB = 19456;
  static const _argonIterations = 2;
  static const _argonParallelism = 1;

  final AppDatabase _database;
  final Random _random;
  final Future<Directory> Function() _temporaryDirectory;

  Future<File> createExport(String password) async {
    final bytes = await createExportBytes(password);
    final temp = await _temporaryDirectory();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final file = File(
      path.join(temp.path, 'medical-box-$timestamp.medicalbox'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> deleteTemporaryExports() async {
    final temp = await _temporaryDirectory();
    if (!await temp.exists()) return;

    await for (final entity in temp.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = path.basename(entity.path);
      if (name.startsWith('medical-box-') && name.endsWith('.medicalbox')) {
        await entity.delete();
      }
    }
  }

  Future<Uint8List> createExportBytes(String password) async {
    _validatePassword(password);
    final salt = _randomBytes(16);
    final cipher = Xchacha20.poly1305Aead();
    final nonce = cipher.newNonce();
    final key = await _deriveKey(password, salt);
    final payload = utf8.encode(
      jsonEncode({
        'format': format,
        'version': version,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'data': await _database.exportSnapshot(),
      }),
    );
    final secretBox = await cipher.encrypt(
      payload,
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(_aad),
    );
    final envelope = {
      'format': format,
      'version': version,
      'kdf': {
        'name': 'argon2id',
        'memoryKiB': _argonMemoryKiB,
        'iterations': _argonIterations,
        'parallelism': _argonParallelism,
        'salt': base64UrlEncode(salt),
      },
      'cipher': {
        'name': 'xchacha20-poly1305',
        'nonce': base64UrlEncode(secretBox.nonce),
        'ciphertext': base64UrlEncode(secretBox.cipherText),
        'mac': base64UrlEncode(secretBox.mac.bytes),
      },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<void> importExport(Uint8List bytes, String password) async {
    _validatePassword(password);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('Invalid export file.');
    final envelope = decoded.cast<String, dynamic>();
    if (envelope['format'] != format || envelope['version'] != version) {
      throw const FormatException('Unsupported export format or version.');
    }
    final kdf = (envelope['kdf'] as Map).cast<String, dynamic>();
    final cipherData = (envelope['cipher'] as Map).cast<String, dynamic>();
    if (kdf['name'] != 'argon2id' ||
        cipherData['name'] != 'xchacha20-poly1305') {
      throw const FormatException('Unsupported cryptography suite.');
    }
    final memory = kdf['memoryKiB'];
    final iterations = kdf['iterations'];
    final parallelism = kdf['parallelism'];
    if (memory != _argonMemoryKiB ||
        iterations != _argonIterations ||
        parallelism != _argonParallelism) {
      throw const FormatException('Unsupported key derivation parameters.');
    }
    final salt = base64Url.decode(kdf['salt'] as String);
    final nonce = base64Url.decode(cipherData['nonce'] as String);
    final cipherText = base64Url.decode(cipherData['ciphertext'] as String);
    final mac = Mac(base64Url.decode(cipherData['mac'] as String));
    final key = await _deriveKey(password, salt);
    final clearText = await Xchacha20.poly1305Aead().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
      aad: utf8.encode(_aad),
    );
    final payload = jsonDecode(utf8.decode(clearText));
    if (payload is! Map ||
        payload['format'] != format ||
        payload['version'] != version ||
        payload['data'] is! Map) {
      throw const FormatException('Invalid decrypted payload.');
    }
    await _database.importSnapshot(
      (payload['data'] as Map).cast<String, Object?>(),
    );
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return Argon2id(
      parallelism: _argonParallelism,
      memory: _argonMemoryKiB,
      iterations: _argonIterations,
      hashLength: 32,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  Uint8List _randomBytes(int count) {
    return Uint8List.fromList(
      List<int>.generate(count, (_) => _random.nextInt(256)),
    );
  }

  void _validatePassword(String password) {
    if (password.length < 10) {
      throw ArgumentError(
        'Export password must contain at least 10 characters.',
      );
    }
  }
}
