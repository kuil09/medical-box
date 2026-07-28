import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/api/api_client.dart';
import '../../theme.dart';

class DrugCatalogProjectionSections extends StatelessWidget {
  const DrugCatalogProjectionSections({required this.detail, super.key});

  final DrugDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.statusEvents.isEmpty &&
        detail.prices.isEmpty &&
        detail.codes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (detail.statusEvents.isNotEmpty) ...[
          const SizedBox(height: 18),
          _StatusEventsCard(events: detail.statusEvents),
        ],
        if (detail.prices.isNotEmpty || detail.codes.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ReferenceDataCard(prices: detail.prices, codes: detail.codes),
        ],
      ],
    );
  }
}

class _StatusEventsCard extends StatelessWidget {
  const _StatusEventsCard({required this.events});

  final List<DrugStatusEventInfo> events;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '공식 회수 및 공급 상태 이력 ${events.length}건',
      child: Material(
        color: const Color(0xFFFFF0EC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: MedicalBoxColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.warningCircle,
                    color: MedicalBoxColors.orange,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '공식 회수·공급 상태 이력',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${events.length}건 · 공식 제공 이력',
                          style: const TextStyle(
                            color: MedicalBoxColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (
              var index = 0;
              index < events.length && index < 3;
              index++
            ) ...[
              if (index > 0)
                const Divider(height: 1, indent: 14, endIndent: 14),
              _StatusEventRow(event: events[index]),
            ],
            if (events.length > 3)
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  '이전 이력 ${events.length - 3}건',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  for (var index = 3; index < events.length; index++) ...[
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _StatusEventRow(event: events[index]),
                  ],
                ],
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Text(
                '공식 상태 이력이며 현재 보유 제품의 해당 여부를 자동 판단하지 않아요. '
                '품목기준코드와 공지 원문을 함께 확인하세요.',
                style: TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusEventRow extends StatelessWidget {
  const _StatusEventRow({required this.event});

  final DrugStatusEventInfo event;

  @override
  Widget build(BuildContext context) {
    final period = [
      if (event.startedOn?.isNotEmpty ?? false)
        '시작 ${formatCatalogDate(event.startedOn!)}',
      if (event.endedOn?.isNotEmpty ?? false)
        '종료 ${formatCatalogDate(event.endedOn!)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusEventLabel(event.eventType),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (period.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              period,
              style: const TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (event.reason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(event.reason!, style: const TextStyle(height: 1.45)),
          ],
          const SizedBox(height: 6),
          _SourceLine(
            sourceCode: event.sourceCode,
            source: event.source,
            sourceUpdatedAt: event.sourceUpdatedAt,
            catalogUpdatedAt: event.catalogUpdatedAt,
          ),
        ],
      ),
    );
  }
}

class _ReferenceDataCard extends StatelessWidget {
  const _ReferenceDataCard({required this.prices, required this.codes});

  final List<DrugPriceInfo> prices;
  final List<DrugCodeInfo> codes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '보험 적용 기준 및 의약품 표준코드',
      child: Material(
        color: MedicalBoxColors.sky.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: MedicalBoxColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.identificationCard,
                    color: MedicalBoxColors.skyDeep,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      '보험 적용 기준·표준코드',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            if (prices.isNotEmpty)
              ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  '보험 상한금액 ${prices.length}건',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  for (var index = 0; index < prices.length; index++) ...[
                    if (index > 0) const Divider(height: 14),
                    _PriceRow(price: prices[index]),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    '고시된 보험 상한금액이며 실제 구매가나 본인부담금과 다를 수 있어요.',
                    style: TextStyle(
                      color: MedicalBoxColors.muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            if (codes.isNotEmpty)
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  '의약품 표준코드 ${codes.length}건',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  for (var index = 0; index < codes.length; index++) ...[
                    if (index > 0) const Divider(height: 14),
                    _CodeRow(code: codes[index]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price});

  final DrugPriceInfo price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatWon(price.amount),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          [
            if (price.insuranceCode?.isNotEmpty ?? false)
              '보험코드 ${price.insuranceCode}',
            if (price.effectiveDate?.isNotEmpty ?? false)
              '적용 ${formatCatalogDate(price.effectiveDate!)}',
          ].join(' · '),
          style: const TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 5),
        _SourceLine(
          sourceCode: price.sourceCode,
          source: price.source,
          sourceUpdatedAt: price.sourceUpdatedAt,
          catalogUpdatedAt: price.catalogUpdatedAt,
        ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final DrugCodeInfo code;

  @override
  Widget build(BuildContext context) {
    final validity = [
      if (code.validFrom?.isNotEmpty ?? false)
        '시작 ${formatCatalogDate(code.validFrom!)}',
      if (code.validTo?.isNotEmpty ?? false)
        '종료 ${formatCatalogDate(code.validTo!)}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          code.code,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          [
            codeTypeLabel(code.codeType),
            if (validity.isNotEmpty) validity,
          ].join(' · '),
          style: const TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 5),
        _SourceLine(
          sourceCode: code.sourceCode,
          source: code.source,
          sourceUpdatedAt: code.sourceUpdatedAt,
          catalogUpdatedAt: code.catalogUpdatedAt,
        ),
      ],
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({
    required this.sourceCode,
    required this.source,
    required this.catalogUpdatedAt,
    this.sourceUpdatedAt,
  });

  final String sourceCode;
  final DrugSourceAttribution source;
  final String? sourceUpdatedAt;
  final String catalogUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final sourceDate = sourceUpdatedAt?.trim();
    final dateLabel = sourceDate?.isNotEmpty == true
        ? '자료 갱신 ${formatCatalogDate(sourceDate!)}'
        : '카탈로그 확인 ${formatCatalogDate(catalogUpdatedAt)}';
    return Text(
      [
        '출처 ${catalogSourceLabel(sourceCode, source.source)}',
        dateLabel,
        if (source.licenseName?.isNotEmpty ?? false)
          catalogLicenseLabel(source.licenseName!),
      ].join(' · '),
      style: const TextStyle(
        color: MedicalBoxColors.muted,
        fontSize: 11,
        height: 1.4,
      ),
    );
  }
}

String statusEventLabel(String eventType) {
  return switch (eventType) {
    'recall' => '회수·판매중지',
    'suspension' => '판매중지',
    'shortage' => '생산·수입·공급 중단',
    _ => '공식 상태 변경',
  };
}

String codeTypeLabel(String codeType) {
  return switch (codeType) {
    'standard' => '표준코드',
    'insurance' => '보험코드',
    _ => '공식 코드',
  };
}

String catalogSourceLabel(String sourceCode, String fallback) {
  return switch (sourceCode) {
    'mfds_recall' || 'mfds_shortage' => '식품의약품안전처',
    'hira_price' || 'hira_standard_code' => '건강보험심사평가원',
    _ => fallback,
  };
}

String catalogLicenseLabel(String licenseName) {
  if (licenseName.startsWith('Korea Open Government License Type 1')) {
    return '공공누리 제1유형';
  }
  if (licenseName.toLowerCase().contains('public data')) {
    return '공공데이터';
  }
  return licenseName;
}

String formatCatalogDate(String value) {
  final compact = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (compact.length >= 8) {
    return '${compact.substring(0, 4)}.${compact.substring(4, 6)}.'
        '${compact.substring(6, 8)}';
  }
  return value;
}

String formatWon(String? amount) {
  final parsed = num.tryParse(amount ?? '');
  if (parsed == null) return '금액 정보 없음';
  return '${NumberFormat('#,##0.##').format(parsed)}원';
}
