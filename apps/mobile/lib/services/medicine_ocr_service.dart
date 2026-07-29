import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MedicineOcrLine {
  const MedicineOcrLine({required this.text, this.confidence = 1});

  factory MedicineOcrLine.fromPlatform(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid OCR line.');
    }
    final text = value['text'];
    if (text is! String) {
      throw const FormatException('OCR line text is missing.');
    }
    final confidence = value['confidence'];
    return MedicineOcrLine(
      text: text,
      confidence: confidence is num
          ? confidence.toDouble().clamp(0, 1).toDouble()
          : 1,
    );
  }

  final String text;
  final double confidence;
}

class MedicineScanResult {
  const MedicineScanResult({required this.lines});

  final List<MedicineOcrLine> lines;
}

enum MedicineScanFailure {
  cameraDenied,
  cameraUnavailable,
  recognitionUnavailable,
  recognitionFailed,
}

class MedicineScanException implements Exception {
  const MedicineScanException(this.failure);

  final MedicineScanFailure failure;
}

abstract interface class MedicineScanner {
  Future<MedicineScanResult?> scan();
}

class DeviceMedicineScanner implements MedicineScanner {
  DeviceMedicineScanner({
    ImagePicker? picker,
    MethodChannel channel = const MethodChannel('medical_box/medicine_ocr'),
  }) : _picker = picker ?? ImagePicker(),
       _channel = channel;

  final ImagePicker _picker;
  final MethodChannel _channel;

  @override
  Future<MedicineScanResult?> scan() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2200,
        maxHeight: 2200,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (photo == null) return null;
      final rawLines = await _channel.invokeMethod<List<Object?>>(
        'recognizeMedicineText',
        {'path': photo.path},
      );
      return MedicineScanResult(
        lines: (rawLines ?? const [])
            .map(MedicineOcrLine.fromPlatform)
            .where((line) => line.text.trim().isNotEmpty)
            .toList(growable: false),
      );
    } on PlatformException catch (error) {
      if (error.code == 'camera_access_denied' ||
          error.code == 'camera_access_restricted') {
        throw const MedicineScanException(MedicineScanFailure.cameraDenied);
      }
      if (error.code == 'camera_unavailable') {
        throw const MedicineScanException(
          MedicineScanFailure.cameraUnavailable,
        );
      }
      if (error.code == 'OCR_UNAVAILABLE' ||
          error.code == 'OCR_LANGUAGE_UNAVAILABLE') {
        throw const MedicineScanException(
          MedicineScanFailure.recognitionUnavailable,
        );
      }
      throw const MedicineScanException(MedicineScanFailure.recognitionFailed);
    } on MissingPluginException {
      throw const MedicineScanException(
        MedicineScanFailure.recognitionUnavailable,
      );
    } finally {
      final path = photo?.path;
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // The picker cache may already have removed the temporary capture.
        }
      }
    }
  }
}

class MedicineSearchTermExtractor {
  const MedicineSearchTermExtractor();

  static final _allowedCharacters = RegExp(r'[^0-9A-Za-z가-힣().,%+·\-\s]');
  static final _spaces = RegExp(r'\s+');
  static final _strength = RegExp(
    r'\s*\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|ml|mL|IU|밀리그램|밀리그람|마이크로그램|그램|밀리리터|%)(?=\s|$).*$',
    caseSensitive: false,
  );
  static final _dosageForm = RegExp(
    r'(?:연질캡슐|경질캡슐|캡슐|현탁액|점안액|점이액|스프레이|패취|패치|크림|연고|로션|겔|시럽|과립|트로키|좌제|정|산|액|주)(?=\s|[0-9(]|$)',
  );
  static final _genericOnly = RegExp(
    r'^(?:일반의약품|전문의약품|의약품|제품명|품목명|성분|효능|효과|용법|용량|주의사항|제조원|제조업자|판매원|유효기간|사용기한|보관방법|대한민국)$',
  );
  static final _manufacturerOnly = RegExp(
    r'(?:제약|약품|바이오|파마|팜|제약회사|주식회사|\(주\))$',
  );
  static const _genericPrefixes = <String>['일반의약품 ', '전문의약품 ', '제품명 ', '품목명 '];

  List<String> extract(List<MedicineOcrLine> lines, {int limit = 4}) {
    final scored = <String, double>{};

    for (final line in lines) {
      final normalized = _normalize(line.text);
      if (!_isUseful(normalized)) continue;

      _add(scored, normalized, _score(normalized, line.confidence));

      final withoutStrength = normalized.replaceFirst(_strength, '').trim();
      if (withoutStrength != normalized && _isUseful(withoutStrength)) {
        _add(
          scored,
          withoutStrength,
          _score(withoutStrength, line.confidence) + 18,
        );
      }

      for (final token in normalized.split(' ')) {
        if (_dosageForm.hasMatch(token) &&
            !_isDosageFormOnly(token) &&
            _isUseful(token)) {
          _add(scored, token, _score(token, line.confidence) + 28);
        }
      }
    }

    final ranked = scored.entries.toList()
      ..sort((left, right) {
        final byScore = right.value.compareTo(left.value);
        if (byScore != 0) return byScore;
        final byLength = left.key.length.compareTo(right.key.length);
        if (byLength != 0) return byLength;
        return left.key.compareTo(right.key);
      });
    return ranked.take(limit).map((entry) => entry.key).toList(growable: false);
  }

  String _normalize(String value) {
    var normalized = value
        .replaceAll(_allowedCharacters, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
    for (final prefix in _genericPrefixes) {
      if (normalized.startsWith(prefix)) {
        normalized = normalized.substring(prefix.length).trim();
      }
    }
    return normalized;
  }

  bool _isUseful(String value) {
    if (value.length < 2 || value.length > 60 || _genericOnly.hasMatch(value)) {
      return false;
    }
    return RegExp(r'[A-Za-z가-힣]{2}').hasMatch(value);
  }

  bool _isDosageFormOnly(String value) {
    return _dosageForm.firstMatch(value)?.group(0) == value;
  }

  double _score(String value, double confidence) {
    var score = confidence * 20;
    if (RegExp(r'[가-힣]').hasMatch(value)) score += 22;
    if (_dosageForm.hasMatch(value)) score += 65;
    if (value.length <= 28) score += 12;
    if (_manufacturerOnly.hasMatch(value)) score -= 24;
    return score;
  }

  void _add(Map<String, double> target, String term, double score) {
    final previous = target[term];
    if (previous == null || score > previous) target[term] = score;
  }
}
