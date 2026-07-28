import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/features/inventory/drug_catalog_projection_sections.dart';

void main() {
  const mfdsSource = DrugSourceAttribution(
    source: 'MFDS recall and sale suspension',
    sourceUrl: 'https://example.test/recalls',
    licenseName: 'Public data',
    attribution: 'Source: MFDS',
  );
  const hiraSource = DrugSourceAttribution(
    source: 'HIRA medicine data',
    sourceUrl: 'https://example.test/hira',
    licenseName: 'Korea Open Government License Type 1',
    attribution: 'Source: HIRA',
  );

  testWidgets('shows official status, price, code, source, and update dates', (
    tester,
  ) async {
    const detail = DrugDetail(
      itemSeq: '123',
      itemName: '테스트 의약품',
      ingredients: [],
      sources: [],
      statusEvents: [
        DrugStatusEventInfo(
          eventType: 'recall',
          reason: '품질 기준 확인을 위한 공식 회수',
          startedOn: '2026-07-25',
          sourceCode: 'mfds_recall',
          sourceUpdatedAt: '20260726',
          catalogUpdatedAt: '2026-07-26T03:10:00Z',
          source: mfdsSource,
        ),
      ],
      prices: [
        DrugPriceInfo(
          insuranceCode: '645700010',
          amount: '1234.00',
          effectiveDate: '2026-07-01',
          sourceCode: 'hira_price',
          catalogUpdatedAt: '2026-07-26T03:10:00Z',
          source: hiraSource,
        ),
      ],
      codes: [
        DrugCodeInfo(
          codeType: 'standard',
          code: '8801234567890',
          validFrom: '2026-01-01',
          sourceCode: 'hira_standard_code',
          sourceUpdatedAt: '20260703',
          catalogUpdatedAt: '2026-07-26T03:10:00Z',
          source: hiraSource,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DrugCatalogProjectionSections(detail: detail),
          ),
        ),
      ),
    );

    expect(find.text('공식 회수·공급 상태 이력'), findsOneWidget);
    expect(find.text('회수·판매중지'), findsOneWidget);
    expect(find.text('품질 기준 확인을 위한 공식 회수'), findsOneWidget);
    expect(find.textContaining('출처 식품의약품안전처'), findsOneWidget);
    expect(find.textContaining('자료 갱신 2026.07.26'), findsOneWidget);
    expect(find.text('1,234원'), findsOneWidget);
    expect(find.textContaining('보험코드 645700010'), findsOneWidget);

    await tester.tap(find.text('의약품 표준코드 1건'));
    await tester.pumpAndSettle();

    expect(find.text('8801234567890'), findsOneWidget);
    expect(find.textContaining('공공누리 제1유형'), findsWidgets);
    expect(find.text('Source: MFDS'), findsOneWidget);
    expect(find.text('Source: HIRA'), findsWidgets);
    expect(find.text('공식 출처 열기'), findsWidgets);
    expect(find.textContaining('현재 보유 제품의 해당 여부를 자동 판단하지 않아요'), findsOneWidget);
    expect(find.textContaining('실제 구매가나 본인부담금과 다를 수 있어요'), findsOneWidget);
  });

  test('only absolute HTTPS source links are interactive', () {
    expect(
      safeCatalogSourceUri('https://example.test/source')?.host,
      'example.test',
    );
    expect(safeCatalogSourceUri('http://example.test/source'), isNull);
    expect(safeCatalogSourceUri('javascript:alert(1)'), isNull);
    expect(safeCatalogSourceUri('https://user@example.test/source'), isNull);
    expect(safeCatalogSourceUri('/relative/source'), isNull);
  });

  testWidgets('renders no status claim when projection data is absent', (
    tester,
  ) async {
    const detail = DrugDetail(
      itemSeq: '123',
      itemName: '테스트 의약품',
      ingredients: [],
      sources: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DrugCatalogProjectionSections(detail: detail)),
      ),
    );

    expect(find.text('공식 회수·공급 상태 이력'), findsNothing);
    expect(find.text('보험 적용 기준·표준코드'), findsNothing);
  });

  testWidgets('keeps older status events behind an explicit expansion', (
    tester,
  ) async {
    const events = [
      DrugStatusEventInfo(
        eventType: 'recall',
        reason: '첫 번째 이력',
        sourceCode: 'mfds_recall',
        catalogUpdatedAt: '2026-07-26T03:10:00Z',
        source: mfdsSource,
      ),
      DrugStatusEventInfo(
        eventType: 'suspension',
        reason: '두 번째 이력',
        sourceCode: 'mfds_recall',
        catalogUpdatedAt: '2026-07-26T03:10:00Z',
        source: mfdsSource,
      ),
      DrugStatusEventInfo(
        eventType: 'shortage',
        reason: '세 번째 이력',
        sourceCode: 'mfds_shortage',
        catalogUpdatedAt: '2026-07-26T03:10:00Z',
        source: mfdsSource,
      ),
      DrugStatusEventInfo(
        eventType: 'recall',
        reason: '네 번째 이력',
        sourceCode: 'mfds_recall',
        catalogUpdatedAt: '2026-07-26T03:10:00Z',
        source: mfdsSource,
      ),
    ];
    const detail = DrugDetail(
      itemSeq: '123',
      itemName: '테스트 의약품',
      ingredients: [],
      sources: [],
      statusEvents: events,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DrugCatalogProjectionSections(detail: detail),
          ),
        ),
      ),
    );

    expect(find.text('이전 이력 1건'), findsOneWidget);
    expect(find.text('네 번째 이력'), findsNothing);

    await tester.tap(find.text('이전 이력 1건'));
    await tester.pumpAndSettle();

    expect(find.text('네 번째 이력'), findsOneWidget);
  });
}
