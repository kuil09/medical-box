import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/services/medicine_ocr_service.dart';

void main() {
  const extractor = MedicineSearchTermExtractor();

  test('ranks a product name above generic package copy and strength', () {
    final terms = extractor.extract(const [
      MedicineOcrLine(text: '일반의약품'),
      MedicineOcrLine(text: '타이레놀정 500밀리그람', confidence: 0.94),
      MedicineOcrLine(text: '한국얀센', confidence: 0.88),
      MedicineOcrLine(text: '용법·용량'),
    ]);

    expect(terms.first, '타이레놀정');
    expect(terms, contains('한국얀센'));
    expect(terms, isNot(contains('일반의약품')));
    expect(terms, isNot(contains('용법 용량')));
  });

  test('keeps useful Korean dosage forms and limits server queries', () {
    final terms = extractor.extract(const [
      MedicineOcrLine(text: '어린이 타이레놀 현탁액'),
      MedicineOcrLine(text: '후시딘연고'),
      MedicineOcrLine(text: '인공눈물 점안액'),
      MedicineOcrLine(text: '테스트캡슐'),
      MedicineOcrLine(text: '추가제품정'),
    ], limit: 4);

    expect(terms, hasLength(4));
    expect(terms, contains('후시딘연고'));
    expect(terms, contains('테스트캡슐'));
  });

  test('returns no terms when OCR finds only regulatory labels', () {
    final terms = extractor.extract(const [
      MedicineOcrLine(text: '전문의약품'),
      MedicineOcrLine(text: '제품명'),
      MedicineOcrLine(text: '사용기한'),
    ]);

    expect(terms, isEmpty);
  });
}
