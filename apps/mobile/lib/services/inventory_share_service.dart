import '../data/local/app_database.dart';

class InventoryShareOptions {
  const InventoryShareOptions({
    this.includeQuantity = true,
    this.includeExpiry = true,
    this.includeOfficialLinks = true,
    this.includeOfficialAppearance = false,
    this.includePrivateNotes = false,
  });

  final bool includeQuantity;
  final bool includeExpiry;
  final bool includeOfficialLinks;
  final bool includeOfficialAppearance;
  final bool includePrivateNotes;

  InventoryShareOptions copyWith({
    bool? includeQuantity,
    bool? includeExpiry,
    bool? includeOfficialLinks,
    bool? includeOfficialAppearance,
    bool? includePrivateNotes,
  }) {
    return InventoryShareOptions(
      includeQuantity: includeQuantity ?? this.includeQuantity,
      includeExpiry: includeExpiry ?? this.includeExpiry,
      includeOfficialLinks: includeOfficialLinks ?? this.includeOfficialLinks,
      includeOfficialAppearance:
          includeOfficialAppearance ?? this.includeOfficialAppearance,
      includePrivateNotes: includePrivateNotes ?? this.includePrivateNotes,
    );
  }
}

String buildInventoryShareText({
  required String containerName,
  required List<InventoryItem> items,
  InventoryShareOptions options = const InventoryShareOptions(),
}) {
  final lines = <String>[
    '우리집 구급키트 · $containerName',
    '공유 전에 선택한 정보만 포함했어요.',
    '',
  ];

  if (items.isEmpty) {
    lines.add('등록된 의약품이 없어요.');
  } else {
    for (final item in items) {
      lines.add('• ${item.productName}');
      if (options.includeQuantity) {
        lines.add('  수량: ${item.quantity}${item.unit}');
      }
      if (options.includeExpiry) {
        lines.add(
          '  사용기한: ${item.expiresOn == null ? '미입력' : _date(item.expiresOn!)}',
        );
      }
      if (options.includeOfficialAppearance &&
          item.appearanceSummary != null &&
          item.appearanceSummary!.trim().isNotEmpty) {
        lines.add('  공식 외형: ${item.appearanceSummary!.trim()}');
      }
      if (options.includePrivateNotes &&
          item.privateNote != null &&
          item.privateNote!.trim().isNotEmpty) {
        lines.add('  개인 메모: ${item.privateNote!.trim()}');
      }
      if (options.includeOfficialLinks &&
          item.itemSeq != null &&
          item.itemSeq!.trim().isNotEmpty) {
        lines.add(
          '  공식 제품 정보: https://medicalbox.outoftokens.ai/api/v1/drugs/${Uri.encodeComponent(item.itemSeq!.trim())}',
        );
      }
    }
  }

  lines
    ..add('')
    ..add('응급 상황이나 의학적 판단이 필요한 경우 의료기관 또는 약사에게 문의하세요.');
  return lines.join('\n');
}

String _date(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
