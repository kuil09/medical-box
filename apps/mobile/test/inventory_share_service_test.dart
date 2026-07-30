import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/services/inventory_share_service.dart';

void main() {
  final item = InventoryItem(
    id: 'item-1',
    containerId: 'shared',
    itemSeq: '200000001',
    productName: '테스트 의약품',
    manufacturer: null,
    ingredientSummary: null,
    identificationVariantKey: 'variant-a',
    officialImageUrl: 'https://example.test/pill.png',
    appearanceSummary: '원형 · 흰색 · 앞 A1',
    itemKind: 'medicine',
    cabinetSection: 'other',
    quantity: 2,
    unit: '정',
    expiresOn: DateTime(2027, 3, 5),
    storageNote: null,
    privateNote: '민감한 메모',
    assignedMemberId: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('default share text excludes private notes', () {
    final text = buildInventoryShareText(
      containerName: '공용 트레이',
      items: [item],
    );

    expect(text, isNot(contains('수량:')));
    expect(text, contains('사용기한: 2027-03-05'));
    expect(
      text,
      contains(
        'https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetail'
        '?itemSeq=200000001',
      ),
    );
    expect(text, isNot(contains('medicalbox.outoftokens.ai/api')));
    expect(text, isNot(contains('공식 외형:')));
    expect(text, isNot(contains('민감한 메모')));
  });

  test('official detail URL safely encodes an item sequence', () {
    final url = officialMfdsDrugDetailUrl(' item / 1 ');

    expect(
      url,
      'https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetail'
      '?itemSeq=item+%2F+1',
    );
  });

  test('share text follows explicit field choices', () {
    final text = buildInventoryShareText(
      containerName: '하준 파우치',
      items: [item],
      options: const InventoryShareOptions(
        includeExpiry: false,
        includeOfficialLinks: false,
        includeOfficialAppearance: true,
        includePrivateNotes: true,
      ),
    );

    expect(text, contains('개인 메모: 민감한 메모'));
    expect(text, contains('공식 외형: 원형 · 흰색 · 앞 A1'));
    expect(text, isNot(contains('수량:')));
    expect(text, isNot(contains('사용기한:')));
    expect(text, isNot(contains('https://')));
  });
}
