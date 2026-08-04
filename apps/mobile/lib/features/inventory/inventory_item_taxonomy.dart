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
  static const coldAndCough = 'cold_and_cough';
  static const allergyCare = 'allergy_care';
  static const digestion = 'digestion';
  static const diarrheaAndHydration = 'diarrhea_and_hydration';
  static const nauseaAndMotion = 'nausea_and_motion';
  static const eyeAndNoseCare = 'eye_and_nose_care';
  static const mouthAndThroatCare = 'mouth_and_throat_care';
  static const skinAndBites = 'skin_and_bites';
  static const topicalPainRelief = 'topical_pain_relief';
  static const woundCare = 'wound_care';
  static const cleaningAndDisinfection = 'cleaning_and_disinfection';
  static const temperatureAndColdCare = 'temperature_and_cold_care';
  static const protectionAndTools = 'protection_and_tools';
  static const other = 'other';

  static const values = <String>[
    painAndFever,
    coldAndCough,
    allergyCare,
    digestion,
    diarrheaAndHydration,
    nauseaAndMotion,
    eyeAndNoseCare,
    mouthAndThroatCare,
    skinAndBites,
    topicalPainRelief,
    woundCare,
    cleaningAndDisinfection,
    temperatureAndColdCare,
    protectionAndTools,
    other,
  ];

  static const householdMedicineGuide = <String>[
    painAndFever,
    coldAndCough,
    allergyCare,
    digestion,
    diarrheaAndHydration,
    nauseaAndMotion,
    eyeAndNoseCare,
    mouthAndThroatCare,
    skinAndBites,
    topicalPainRelief,
  ];

  static const householdFirstAidGuide = <String>[
    woundCare,
    cleaningAndDisinfection,
    temperatureAndColdCare,
    protectionAndTools,
  ];

  static const householdReadinessGuide = <String>[
    ...householdMedicineGuide,
    ...householdFirstAidGuide,
  ];

  static String label(String value) {
    return switch (value) {
      painAndFever => '열·통증',
      coldAndCough => '감기·기침',
      allergyCare => '알레르기',
      digestion => '소화·제산',
      diarrheaAndHydration => '설사·수분',
      nauseaAndMotion => '멀미·구토',
      eyeAndNoseCare => '눈·코 관리',
      mouthAndThroatCare => '구강·인후',
      skinAndBites => '피부·벌레',
      topicalPainRelief => '근육·관절',
      woundCare => '상처 관리',
      cleaningAndDisinfection => '소독·세정',
      temperatureAndColdCare => '체온·냉찜질',
      protectionAndTools => '보호·도구',
      _ => '기타',
    };
  }
}

String suggestCabinetSection({
  required String itemKind,
  required Iterable<String?> officialText,
}) {
  if (itemKind == InventoryItemKinds.firstAidSupply) {
    final source = officialText.whereType<String>().join(' ').toLowerCase();
    if (_containsAny(source, const ['소독', '세정', '식염수', '알코올'])) {
      return CabinetSections.cleaningAndDisinfection;
    }
    if (_containsAny(source, const ['체온계', '냉찜질', '아이스팩', '냉팩'])) {
      return CabinetSections.temperatureAndColdCare;
    }
    if (_containsAny(source, const ['장갑', '가위', '핀셋', '마스크'])) {
      return CabinetSections.protectionAndTools;
    }
    return CabinetSections.woundCare;
  }

  final source = officialText.whereType<String>().join(' ').toLowerCase();
  if (_containsAny(source, const ['알레르기', '항히스타민', '두드러기', '비염'])) {
    return CabinetSections.allergyCare;
  }
  if (_containsAny(source, const ['피부', '벌레', '모기', '가려움', '화상', '습진'])) {
    return CabinetSections.skinAndBites;
  }
  if (_containsAny(source, const ['파스', '파프', '플라스타', '첩부제'])) {
    return CabinetSections.topicalPainRelief;
  }
  if (_containsAny(source, const ['설사', '탈수', '수분 보충', '경구수액'])) {
    return CabinetSections.diarrheaAndHydration;
  }
  if (_containsAny(source, const ['멀미', '구토', '구역', '메스꺼움'])) {
    return CabinetSections.nauseaAndMotion;
  }
  if (_containsAny(source, const ['인공눈물', '안약', '점안', '비강', '코세척'])) {
    return CabinetSections.eyeAndNoseCare;
  }
  if (_containsAny(source, const ['감기', '기침', '콧물', '코막힘'])) {
    return CabinetSections.coldAndCough;
  }
  if (_containsAny(source, const ['구내염', '잇몸', '구강', '인후', '목 통증'])) {
    return CabinetSections.mouthAndThroatCare;
  }
  if (_containsAny(source, const ['소화', '위장', '위산', '제산', '정장', '변비'])) {
    return CabinetSections.digestion;
  }
  if (_containsAny(source, const ['상처', '연고'])) {
    return CabinetSections.woundCare;
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
