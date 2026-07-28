import 'dart:convert';

import 'package:http/http.dart' as http;

const productionApiBaseUrl = String.fromEnvironment(
  'MEDICAL_BOX_API_BASE_URL',
  defaultValue: 'https://medicalbox.outoftokens.ai/api',
);

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = productionApiBaseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Map<String, String> _headers({String? accessToken}) {
    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
    };
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?> body = const {},
    String? accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken: accessToken),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: _headers(accessToken: accessToken),
    );
    return _decode(response);
  }

  Future<void> deleteJson(
    String path, {
    Map<String, Object?> body = const {},
    required String accessToken,
  }) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken: accessToken),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
    if (response.bodyBytes.isEmpty) return {};
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded.cast<String, dynamic>();
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      // Fall through to the generic message without logging the body.
    }
    return 'The server rejected the request.';
  }
}

class DrugSummary {
  const DrugSummary({
    required this.itemSeq,
    required this.itemName,
    this.manufacturer,
    this.status,
  });

  factory DrugSummary.fromJson(Map<String, dynamic> json) {
    return DrugSummary(
      itemSeq: json['itemSeq'] as String,
      itemName: json['itemName'] as String,
      manufacturer: json['manufacturer'] as String?,
      status: json['status'] as String?,
    );
  }

  final String itemSeq;
  final String itemName;
  final String? manufacturer;
  final String? status;
}

class DrugSourceAttribution {
  const DrugSourceAttribution({
    required this.source,
    required this.sourceUrl,
    this.licenseName,
    this.attribution,
  });

  factory DrugSourceAttribution.fromJson(Map<String, dynamic> json) {
    return DrugSourceAttribution(
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String,
      licenseName: json['licenseName'] as String?,
      attribution: json['attribution'] as String?,
    );
  }

  final String source;
  final String sourceUrl;
  final String? licenseName;
  final String? attribution;
}

class DrugAppearanceInfo {
  const DrugAppearanceInfo({
    this.variantKey,
    this.shape,
    this.color,
    this.imprintFront,
    this.imprintBack,
    this.imageUrl,
  });

  factory DrugAppearanceInfo.fromJson(Map<String, dynamic> json) {
    return DrugAppearanceInfo(
      variantKey: json['variantKey'] as String?,
      shape: json['shape'] as String?,
      color: json['color'] as String?,
      imprintFront: json['imprintFront'] as String?,
      imprintBack: json['imprintBack'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String? variantKey;
  final String? shape;
  final String? color;
  final String? imprintFront;
  final String? imprintBack;
  final String? imageUrl;
}

class DrugSafetyCategory {
  const DrugSafetyCategory({required this.ruleType, required this.count});

  factory DrugSafetyCategory.fromJson(Map<String, dynamic> json) {
    return DrugSafetyCategory(
      ruleType: json['ruleType'] as String,
      count: json['count'] as int,
    );
  }

  final String ruleType;
  final int count;
}

class DrugSafetyOverview {
  const DrugSafetyOverview({
    required this.totalCount,
    required this.categories,
  });

  factory DrugSafetyOverview.fromJson(Map<String, dynamic> json) {
    return DrugSafetyOverview(
      totalCount: json['totalCount'] as int? ?? 0,
      categories: (json['categories'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (category) =>
                DrugSafetyCategory.fromJson(category.cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  static const empty = DrugSafetyOverview(totalCount: 0, categories: []);

  final int totalCount;
  final List<DrugSafetyCategory> categories;
}

class DrugSafetyRule {
  const DrugSafetyRule({
    required this.ruleType,
    required this.sourceCode,
    this.typeName,
    this.ingredientName,
    this.counterpartItemSeq,
    this.counterpartItemName,
    this.counterpartIngredientName,
    this.prohibitionContent,
    this.remark,
    this.notificationDate,
  });

  factory DrugSafetyRule.fromJson(Map<String, dynamic> json) {
    return DrugSafetyRule(
      ruleType: json['ruleType'] as String,
      sourceCode: json['sourceCode'] as String,
      typeName: json['typeName'] as String?,
      ingredientName: json['ingredientName'] as String?,
      counterpartItemSeq: json['counterpartItemSeq'] as String?,
      counterpartItemName: json['counterpartItemName'] as String?,
      counterpartIngredientName: json['counterpartIngredientName'] as String?,
      prohibitionContent: json['prohibitionContent'] as String?,
      remark: json['remark'] as String?,
      notificationDate: json['notificationDate'] as String?,
    );
  }

  final String ruleType;
  final String sourceCode;
  final String? typeName;
  final String? ingredientName;
  final String? counterpartItemSeq;
  final String? counterpartItemName;
  final String? counterpartIngredientName;
  final String? prohibitionContent;
  final String? remark;
  final String? notificationDate;
}

class DrugSafetyRulePage {
  const DrugSafetyRulePage({required this.items, this.nextCursor});

  factory DrugSafetyRulePage.fromJson(Map<String, dynamic> json) {
    return DrugSafetyRulePage(
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((rule) => DrugSafetyRule.fromJson(rule.cast<String, dynamic>()))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<DrugSafetyRule> items;
  final String? nextCursor;
}

class DrugStatusEventInfo {
  const DrugStatusEventInfo({
    required this.eventType,
    required this.sourceCode,
    required this.catalogUpdatedAt,
    required this.source,
    this.reason,
    this.startedOn,
    this.endedOn,
    this.sourceUpdatedAt,
  });

  factory DrugStatusEventInfo.fromJson(Map<String, dynamic> json) {
    return DrugStatusEventInfo(
      eventType: json['eventType'] as String,
      reason: json['reason'] as String?,
      startedOn: json['startedOn'] as String?,
      endedOn: json['endedOn'] as String?,
      sourceCode: json['sourceCode'] as String,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      catalogUpdatedAt: json['catalogUpdatedAt'] as String,
      source: DrugSourceAttribution.fromJson(
        (json['source'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  final String eventType;
  final String? reason;
  final String? startedOn;
  final String? endedOn;
  final String sourceCode;
  final String? sourceUpdatedAt;
  final String catalogUpdatedAt;
  final DrugSourceAttribution source;
}

class DrugPriceInfo {
  const DrugPriceInfo({
    required this.sourceCode,
    required this.catalogUpdatedAt,
    required this.source,
    this.insuranceCode,
    this.amount,
    this.effectiveDate,
    this.sourceUpdatedAt,
  });

  factory DrugPriceInfo.fromJson(Map<String, dynamic> json) {
    return DrugPriceInfo(
      insuranceCode: json['insuranceCode'] as String?,
      amount: json['amount']?.toString(),
      effectiveDate: json['effectiveDate'] as String?,
      sourceCode: json['sourceCode'] as String,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      catalogUpdatedAt: json['catalogUpdatedAt'] as String,
      source: DrugSourceAttribution.fromJson(
        (json['source'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  final String? insuranceCode;
  final String? amount;
  final String? effectiveDate;
  final String sourceCode;
  final String? sourceUpdatedAt;
  final String catalogUpdatedAt;
  final DrugSourceAttribution source;
}

class DrugCodeInfo {
  const DrugCodeInfo({
    required this.codeType,
    required this.code,
    required this.sourceCode,
    required this.catalogUpdatedAt,
    required this.source,
    this.validFrom,
    this.validTo,
    this.sourceUpdatedAt,
  });

  factory DrugCodeInfo.fromJson(Map<String, dynamic> json) {
    return DrugCodeInfo(
      codeType: json['codeType'] as String,
      code: json['code'] as String,
      validFrom: json['validFrom'] as String?,
      validTo: json['validTo'] as String?,
      sourceCode: json['sourceCode'] as String,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      catalogUpdatedAt: json['catalogUpdatedAt'] as String,
      source: DrugSourceAttribution.fromJson(
        (json['source'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  final String codeType;
  final String code;
  final String? validFrom;
  final String? validTo;
  final String sourceCode;
  final String? sourceUpdatedAt;
  final String catalogUpdatedAt;
  final DrugSourceAttribution source;
}

class DrugDetail extends DrugSummary {
  const DrugDetail({
    required super.itemSeq,
    required super.itemName,
    required this.ingredients,
    required this.sources,
    super.manufacturer,
    super.status,
    this.storageMethod,
    this.appearance,
    this.imageUrl,
    this.identification,
    this.identificationVariants = const [],
    this.safetyOverview = DrugSafetyOverview.empty,
    this.statusEvents = const [],
    this.prices = const [],
    this.codes = const [],
    this.efficacy,
    this.useMethod,
    this.warning,
    this.precautions,
    this.interactions,
    this.sideEffects,
    this.sourceUpdatedAt,
  });

  factory DrugDetail.fromJson(Map<String, dynamic> json) {
    return DrugDetail(
      itemSeq: json['itemSeq'] as String,
      itemName: json['itemName'] as String,
      manufacturer: json['manufacturer'] as String?,
      status: json['status'] as String?,
      storageMethod: json['storageMethod'] as String?,
      appearance: json['appearance'] as String?,
      imageUrl: json['imageUrl'] as String?,
      identification: json['identification'] is Map
          ? DrugAppearanceInfo.fromJson(
              (json['identification'] as Map).cast<String, dynamic>(),
            )
          : null,
      identificationVariants:
          (json['identificationVariants'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (variant) => DrugAppearanceInfo.fromJson(
                  variant.cast<String, dynamic>(),
                ),
              )
              .toList(),
      safetyOverview: json['safetyOverview'] is Map
          ? DrugSafetyOverview.fromJson(
              (json['safetyOverview'] as Map).cast<String, dynamic>(),
            )
          : DrugSafetyOverview.empty,
      ingredients: (json['ingredients'] as List? ?? const []).cast<String>(),
      statusEvents: (json['statusEvents'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (event) =>
                DrugStatusEventInfo.fromJson(event.cast<String, dynamic>()),
          )
          .toList(),
      prices: (json['prices'] as List? ?? const [])
          .whereType<Map>()
          .map((price) => DrugPriceInfo.fromJson(price.cast<String, dynamic>()))
          .toList(),
      codes: (json['codes'] as List? ?? const [])
          .whereType<Map>()
          .map((code) => DrugCodeInfo.fromJson(code.cast<String, dynamic>()))
          .toList(),
      efficacy: json['efficacy'] as String?,
      useMethod: json['useMethod'] as String?,
      warning: json['warning'] as String?,
      precautions: json['precautions'] as String?,
      interactions: json['interactions'] as String?,
      sideEffects: json['sideEffects'] as String?,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      sources: (json['sources'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (source) =>
                DrugSourceAttribution.fromJson(source.cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  final String? storageMethod;
  final String? appearance;
  final String? imageUrl;
  final DrugAppearanceInfo? identification;
  final List<DrugAppearanceInfo> identificationVariants;
  final DrugSafetyOverview safetyOverview;
  final List<String> ingredients;
  final List<DrugStatusEventInfo> statusEvents;
  final List<DrugPriceInfo> prices;
  final List<DrugCodeInfo> codes;
  final String? efficacy;
  final String? useMethod;
  final String? warning;
  final String? precautions;
  final String? interactions;
  final String? sideEffects;
  final String? sourceUpdatedAt;
  final List<DrugSourceAttribution> sources;
}

class CatalogRepository {
  CatalogRepository(
    this._api, {
    required Future<String?> Function() accessTokenProvider,
    required Future<String?> Function() refreshAccessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider,
       _refreshAccessTokenProvider = refreshAccessTokenProvider;

  final ApiClient _api;
  final Future<String?> Function() _accessTokenProvider;
  final Future<String?> Function() _refreshAccessTokenProvider;

  Future<Map<String, dynamic>> _authorizedGet(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final accessToken = await _accessTokenProvider();
    if (accessToken == null) {
      throw const ApiException(401, 'Authentication required.');
    }
    try {
      return await _api.getJson(path, query: query, accessToken: accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      final replacement = await _refreshAccessTokenProvider();
      if (replacement == null) rethrow;
      return _api.getJson(path, query: query, accessToken: replacement);
    }
  }

  Future<List<DrugSummary>> search(String query) async {
    if (query.trim().length < 2) return const [];
    final json = await _authorizedGet(
      '/v1/drugs/search',
      query: {'q': query.trim(), 'limit': '20'},
    );
    final rawItems = json['items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => DrugSummary.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<DrugDetail> detail(String itemSeq) async {
    final json = await _authorizedGet(
      '/v1/drugs/${Uri.encodeComponent(itemSeq)}',
    );
    return DrugDetail.fromJson(json);
  }

  Future<DrugSafetyRulePage> safetyRules(
    String itemSeq, {
    String? ruleType,
    String? cursor,
    int limit = 20,
  }) async {
    final json = await _authorizedGet(
      '/v1/drugs/${Uri.encodeComponent(itemSeq)}/dur-rules',
      query: {'ruleType': ?ruleType, 'cursor': ?cursor, 'limit': '$limit'},
    );
    return DrugSafetyRulePage.fromJson(json);
  }
}
