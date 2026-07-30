abstract final class InventoryItemKinds {
  static const medicine = 'medicine';
  static const firstAidSupply = 'first_aid_supply';

  static const values = <String>[medicine, firstAidSupply];

  static String label(String value) {
    return switch (value) {
      firstAidSupply => '구급용품',
      _ => '의약품',
    };
  }
}

abstract final class CabinetSections {
  static const painAndFever = 'pain_and_fever';
  static const digestion = 'digestion';
  static const woundCare = 'wound_care';
  static const other = 'other';

  static const values = <String>[painAndFever, digestion, woundCare, other];

  static String label(String value) {
    return switch (value) {
      painAndFever => '해열·통증',
      digestion => '소화·위장',
      woundCare => '상처 관리',
      _ => '기타',
    };
  }
}

String suggestCabinetSection({
  required String itemKind,
  required Iterable<String?> officialText,
}) {
  if (itemKind == InventoryItemKinds.firstAidSupply) {
    return CabinetSections.woundCare;
  }

  final source = officialText.whereType<String>().join(' ').toLowerCase();
  if (_containsAny(source, const ['상처', '소독', '피부', '화상', '습진', '연고'])) {
    return CabinetSections.woundCare;
  }
  if (_containsAny(source, const ['소화', '위장', '위산', '제산', '정장', '설사', '변비'])) {
    return CabinetSections.digestion;
  }
  if (_containsAny(source, const [
    '해열',
    '진통',
    '두통',
    '발열',
    '통증',
    '아세트아미노펜',
    '이부프로펜',
  ])) {
    return CabinetSections.painAndFever;
  }
  return CabinetSections.other;
}

bool _containsAny(String source, Iterable<String> candidates) {
  return candidates.any(source.contains);
}
