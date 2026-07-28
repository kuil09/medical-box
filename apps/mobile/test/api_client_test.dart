import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/api/api_client.dart';

void main() {
  test(
    'catalog requests send only lookup fields and the access token',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/drugs/search')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'itemSeq': '123',
                  'itemName': 'Test medicine',
                  'manufacturer': 'Test maker',
                  'status': 'Active',
                },
              ],
              'nextCursor': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/dur-rules')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'ruleType': 'pregnancy_contraindication',
                  'sourceCode': 'DUR-001',
                  'typeName': '임부금기',
                  'ingredientName': 'Ingredient A',
                  'prohibitionContent': 'Consult a clinician.',
                },
              ],
              'nextCursor': 'next-page',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'itemSeq': '123',
            'itemName': 'Test medicine',
            'manufacturer': 'Test maker',
            'status': 'Active',
            'storageMethod': 'Room temperature',
            'appearance': 'White oblong tablet',
            'imageUrl': 'https://example.com/official-pill.jpg',
            'identification': {
              'variantKey': 'variant-a',
              'shape': 'Oblong',
              'color': 'White',
              'imprintFront': 'TEST 500',
              'imprintBack': null,
              'imageUrl': 'https://example.com/official-pill.jpg',
            },
            'identificationVariants': [
              {
                'variantKey': 'variant-a',
                'shape': 'Oblong',
                'color': 'White',
                'imprintFront': 'TEST 500',
                'imprintBack': null,
                'imageUrl': 'https://example.com/official-pill.jpg',
              },
              {
                'variantKey': 'variant-b',
                'shape': 'Round',
                'color': 'Blue',
                'imprintFront': 'TEST 250',
                'imprintBack': null,
                'imageUrl': 'https://example.com/official-pill-blue.jpg',
              },
            ],
            'safetyOverview': {
              'totalCount': 3,
              'categories': [
                {'ruleType': 'pregnancy_contraindication', 'count': 3},
              ],
            },
            'ingredients': ['Ingredient A'],
            'statusEvents': [
              {
                'eventType': 'recall',
                'reason': 'Official recall reason',
                'startedOn': '2026-07-25',
                'endedOn': null,
                'sourceCode': 'mfds_recall',
                'sourceUpdatedAt': '20260726',
                'catalogUpdatedAt': '2026-07-26T03:10:00Z',
                'source': {
                  'source': 'MFDS recall and sale suspension',
                  'sourceUrl': 'https://example.com/recall',
                  'licenseName': 'Public data',
                  'attribution': 'Source: MFDS',
                },
              },
            ],
            'prices': [
              {
                'insuranceCode': '645700010',
                'amount': '1234.00',
                'effectiveDate': '2026-07-01',
                'sourceCode': 'hira_price',
                'sourceUpdatedAt': null,
                'catalogUpdatedAt': '2026-07-26T03:10:00Z',
                'source': {
                  'source': 'HIRA reimbursement price',
                  'sourceUrl': 'https://example.com/price',
                  'licenseName': 'Korea Open Government License Type 1',
                  'attribution': 'Source: HIRA',
                },
              },
            ],
            'codes': [
              {
                'codeType': 'standard',
                'code': '8801234567890',
                'validFrom': '2026-01-01',
                'validTo': null,
                'sourceCode': 'hira_standard_code',
                'sourceUpdatedAt': '20260703',
                'catalogUpdatedAt': '2026-07-26T03:10:00Z',
                'source': {
                  'source': 'HIRA medicine standard code',
                  'sourceUrl': 'https://example.com/code',
                  'licenseName': 'Korea Open Government License Type 1',
                  'attribution': 'Source: HIRA',
                },
              },
            ],
            'efficacy': 'Consumer information',
            'useMethod': null,
            'warning': null,
            'precautions': null,
            'interactions': null,
            'sideEffects': null,
            'sourceUpdatedAt': '2026-07-25',
            'sources': [
              {
                'source': 'MFDS',
                'sourceUrl': 'https://example.com',
                'licenseName': 'Public data',
                'attribution': 'Source: MFDS',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = CatalogRepository(
        ApiClient(client: client, baseUrl: 'https://medicalbox.example/api'),
        accessTokenProvider: () async => 'access-token',
        refreshAccessTokenProvider: () async => 'replacement-token',
      );

      final search = await repository.search('테스트');
      final detail = await repository.detail(search.single.itemSeq);
      final safety = await repository.safetyRules(
        detail.itemSeq,
        ruleType: detail.safetyOverview.categories.single.ruleType,
      );

      expect(detail.ingredients, ['Ingredient A']);
      expect(detail.appearance, 'White oblong tablet');
      expect(detail.identification?.shape, 'Oblong');
      expect(detail.identification?.imprintFront, 'TEST 500');
      expect(detail.identificationVariants, hasLength(2));
      expect(detail.identificationVariants.last.variantKey, 'variant-b');
      expect(detail.safetyOverview.totalCount, 3);
      expect(detail.statusEvents.single.eventType, 'recall');
      expect(detail.statusEvents.single.reason, 'Official recall reason');
      expect(detail.statusEvents.single.source.sourceUrl, contains('/recall'));
      expect(detail.prices.single.insuranceCode, '645700010');
      expect(detail.prices.single.amount, '1234.00');
      expect(detail.codes.single.code, '8801234567890');
      expect(detail.codes.single.sourceUpdatedAt, '20260703');
      expect(safety.items.single.sourceCode, 'DUR-001');
      expect(safety.nextCursor, 'next-page');
      expect(requests, hasLength(3));
      expect(
        requests.map((request) => request.headers['authorization']).toSet(),
        {'Bearer access-token'},
      );
      expect(requests.first.method, 'GET');
      expect(requests.first.url.queryParameters, {'q': '테스트', 'limit': '20'});
      expect(requests.first.body, isEmpty);
      expect(requests[1].url.path, '/api/v1/drugs/123');
      expect(requests[1].body, isEmpty);
      expect(requests.last.url.path, '/api/v1/drugs/123/dur-rules');
      expect(requests.last.url.queryParameters, {
        'ruleType': 'pregnancy_contraindication',
        'limit': '20',
      });
      expect(requests.last.body, isEmpty);
    },
  );

  test(
    'catalog rejects locally when there is no authenticated session',
    () async {
      final repository = CatalogRepository(
        ApiClient(
          client: MockClient((_) async => fail('Network must not be called.')),
          baseUrl: 'https://medicalbox.example/api',
        ),
        accessTokenProvider: () async => null,
        refreshAccessTokenProvider: () async => null,
      );

      await expectLater(
        repository.search('테스트'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    },
  );

  test('drug detail treats absent optional projections as empty', () {
    final detail = DrugDetail.fromJson({
      'itemSeq': '123',
      'itemName': 'Test medicine',
      'manufacturer': null,
      'status': null,
      'ingredients': <String>[],
      'sources': <Object?>[],
    });

    expect(detail.statusEvents, isEmpty);
    expect(detail.prices, isEmpty);
    expect(detail.codes, isEmpty);
  });

  test('catalog refreshes once after an expired access token', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (requests.length == 1) {
        return http.Response(
          jsonEncode({'detail': 'Invalid authentication token.'}),
          401,
        );
      }
      return http.Response(
        jsonEncode({'items': [], 'nextCursor': null}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = CatalogRepository(
      ApiClient(client: client, baseUrl: 'https://medicalbox.example/api'),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessTokenProvider: () async => 'replacement-token',
    );

    expect(await repository.search('테스트'), isEmpty);
    expect(requests, hasLength(2));
    expect(requests.first.headers['authorization'], 'Bearer expired-token');
    expect(requests.last.headers['authorization'], 'Bearer replacement-token');
  });
}
