import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/api/api_client.dart';
import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../services/inventory_share_service.dart';
import '../../theme.dart';
import '../../widgets/official_medicine_thumbnail.dart';
import 'drug_catalog_projection_sections.dart';
import 'inventory_item_taxonomy.dart';
import 'local_contraindication_section.dart';

class InventoryItemDetailScreen extends ConsumerWidget {
  const InventoryItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  Future<void> _openEditor(BuildContext context, InventoryItem item) async {
    final deleted = await context.push<bool>(
      '/inventory/${Uri.encodeComponent(item.id)}/edit',
    );
    if (deleted == true && context.mounted) {
      context.pop();
    }
  }

  Future<void> _shareItem(BuildContext context, InventoryItem item) async {
    final text = buildInventoryShareText(
      containerName: '선택한 의약품',
      items: [item],
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공유 미리보기'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('공유'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '우리집 구급키트 · ${item.productName}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemState = ref.watch(inventoryItemProvider(itemId));
    final item = itemState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item?.itemKind == InventoryItemKinds.firstAidSupply
              ? '구급용품 상세'
              : '의약품 상세',
        ),
        actions: [
          if (item != null) ...[
            IconButton(
              onPressed: () => _shareItem(context, item),
              icon: Icon(PhosphorIconsRegular.shareNetwork, size: 20),
              tooltip: '공유',
            ),
            TextButton(
              onPressed: () => _openEditor(context, item),
              child: const Text('수정'),
            ),
          ],
          const SizedBox(width: MedicalBoxSpacing.x2),
        ],
      ),
      body: itemState.when(
        data: (item) => item == null
            ? const _MissingInventoryItem()
            : _InventoryItemDetailBody(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _InventoryItemLoadError(),
      ),
    );
  }
}

class _InventoryItemDetailBody extends ConsumerWidget {
  const _InventoryItemDetailBody({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(containersProvider).valueOrNull ?? const [];
    String? containerName;
    for (final container in containers) {
      if (container.id == item.containerId) {
        containerName = container.name;
        break;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        MedicalBoxSpacing.screen,
        MedicalBoxSpacing.x2,
        MedicalBoxSpacing.screen,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InventoryIdentitySection(item: item),
          const SizedBox(height: MedicalBoxSpacing.x7),
          Text('내 보관 정보', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: MedicalBoxSpacing.x3),
          _LocalInventoryDetails(item: item, containerName: containerName),
          if (item.itemSeq != null) ...[
            LocalContraindicationSection(
              selectedItemSeq: item.itemSeq!,
              excludeInventoryItemId: item.id,
            ),
            const SizedBox(height: 28),
            _OfficialCatalogDetails(
              itemSeq: item.itemSeq!,
              storedImageUrl: item.officialImageUrl,
              storedAppearance: item.appearanceSummary,
            ),
          ] else ...[
            const SizedBox(height: 24),
            const _UnlinkedCatalogNotice(),
          ],
        ],
      ),
    );
  }
}

class _InventoryIdentitySection extends StatelessWidget {
  const _InventoryIdentitySection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${item.productName} 보관품 상세',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MedicalBoxSpacing.x4,
          vertical: MedicalBoxSpacing.x5,
        ),
        decoration: BoxDecoration(
          color: MedicalBoxColors.surface,
          borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
          border: Border.all(color: MedicalBoxColors.rail),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfficialMedicineThumbnail(
              imageUrl: item.officialImageUrl,
              imageBytes: item.capturedImageBytes,
              fallbackIcon: item.itemKind == InventoryItemKinds.firstAidSupply
                  ? PhosphorIconsRegular.firstAidKit
                  : PhosphorIconsRegular.pill,
              size: 72,
              borderRadius: MedicalBoxRadius.control,
              backgroundColor: MedicalBoxColors.surfaceRaised,
            ),
            const SizedBox(width: MedicalBoxSpacing.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (item.manufacturer?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.manufacturer!,
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.itemSeq != null) ...[
                    const SizedBox(height: 10),
                    _OfficialSourceLabel(category: item.officialCategory),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialSourceLabel extends StatelessWidget {
  const _OfficialSourceLabel({this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: MedicalBoxColors.officialSoft,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.marker),
        border: Border.all(color: MedicalBoxColors.official),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.sealCheck,
            size: 16,
            color: MedicalBoxColors.official,
          ),
          const SizedBox(width: 5),
          Text(
            category?.isNotEmpty == true ? '공식 정보 · $category' : '공식 정보',
            style: const TextStyle(
              color: MedicalBoxColors.official,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalInventoryDetails extends StatelessWidget {
  const _LocalInventoryDetails({
    required this.item,
    required this.containerName,
  });

  final InventoryItem item;
  final String? containerName;

  @override
  Widget build(BuildContext context) {
    final details = <_LocalDetailValue>[
      _LocalDetailValue(
        icon: item.itemKind == InventoryItemKinds.firstAidSupply
            ? PhosphorIconsRegular.firstAidKit
            : PhosphorIconsRegular.pill,
        label: '제품 유형',
        value: InventoryItemKinds.label(item.itemKind),
      ),
      if (containerName != null)
        _LocalDetailValue(
          icon: PhosphorIconsRegular.users,
          label: '보관 대상',
          value: containerName!,
        ),
      _LocalDetailValue(
        icon: PhosphorIconsRegular.squaresFour,
        label: '약장 칸',
        value: CabinetSections.label(item.cabinetSection),
      ),
      if (item.expiresOn != null)
        _LocalDetailValue(
          icon: PhosphorIconsRegular.calendarBlank,
          label: '사용기한',
          value: DateFormat('yyyy년 M월 d일').format(item.expiresOn!),
        ),
      if (item.storageNote?.trim().isNotEmpty == true)
        _LocalDetailValue(
          icon: PhosphorIconsRegular.firstAidKit,
          label: '보관 위치·방법',
          value: item.storageNote!,
        ),
      if (item.privateNote?.trim().isNotEmpty == true)
        _LocalDetailValue(
          icon: PhosphorIconsRegular.note,
          label: '개인 메모',
          value: item.privateNote!,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(color: MedicalBoxColors.rail),
      ),
      child: details.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                '등록된 사용기한, 보관 위치 또는 메모가 없어요.',
                style: TextStyle(color: MedicalBoxColors.muted),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < details.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _LocalDetailRow(detail: details[index]),
                ],
              ],
            ),
    );
  }
}

class _LocalDetailValue {
  const _LocalDetailValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Object icon;
  final String label;
  final String value;
}

class _LocalDetailRow extends StatelessWidget {
  const _LocalDetailRow({required this.detail});

  final _LocalDetailValue detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(detail.icon, size: 22, color: MedicalBoxColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: const TextStyle(
                    color: MedicalBoxColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail.value,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialCatalogDetails extends ConsumerWidget {
  const _OfficialCatalogDetails({
    required this.itemSeq,
    this.storedImageUrl,
    this.storedAppearance,
  });

  final String itemSeq;
  final String? storedImageUrl;
  final String? storedAppearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(catalogDetailProvider(itemSeq));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '공식 의약품 정보',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const _OfficialSourceLabel(),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          '식품의약품안전처·건강보험심사평가원 자료를 확인하세요.',
          style: TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        detailState.when(
          data: (detail) => _OfficialDrugDetailContent(
            detail: detail,
            storedImageUrl: storedImageUrl,
            storedAppearance: storedAppearance,
          ),
          loading: () => const _CatalogLoadingCard(),
          error: (error, _) => _CatalogErrorCard(
            accessError: _isCatalogAccessError(error),
            onRetry: () => ref.invalidate(catalogDetailProvider(itemSeq)),
          ),
        ),
      ],
    );
  }
}

class _OfficialDrugDetailContent extends StatelessWidget {
  const _OfficialDrugDetailContent({
    required this.detail,
    this.storedImageUrl,
    this.storedAppearance,
  });

  final DrugDetail detail;
  final String? storedImageUrl;
  final String? storedAppearance;

  @override
  Widget build(BuildContext context) {
    final appearance =
        detail.identification ??
        (detail.identificationVariants.isEmpty
            ? null
            : detail.identificationVariants.first);
    final imageUrl = appearance?.imageUrl ?? detail.imageUrl ?? storedImageUrl;
    final appearanceText = storedAppearance?.trim().isNotEmpty == true
        ? storedAppearance
        : detail.appearance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasAppearance(detail, imageUrl, appearanceText))
          _OfficialAppearanceCard(
            imageUrl: imageUrl,
            appearance: appearanceText,
            identification: appearance,
          ),
        _ReadOnlySection(
          title: '성분',
          body: detail.ingredients.isEmpty
              ? null
              : detail.ingredients.join(', '),
        ),
        if (detail.safetyOverview.totalCount > 0)
          _SafetySummaryCard(overview: detail.safetyOverview),
        DrugCatalogProjectionSections(detail: detail),
        _ReadOnlySection(title: '보관 방법', body: detail.storageMethod),
        _ReadOnlySection(title: '효능·효과', body: detail.efficacy),
        _ReadOnlySection(title: '사용 방법', body: detail.useMethod),
        _ReadOnlySection(title: '주의사항', body: detail.warning),
        _ReadOnlySection(title: '기타 주의', body: detail.precautions),
        _ReadOnlySection(title: '상호작용', body: detail.interactions),
        _ReadOnlySection(title: '이상반응', body: detail.sideEffects),
        const SizedBox(height: 18),
        const _MedicalInformationNotice(),
        if (detail.sources.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('출처', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          for (final source in detail.sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                [
                  source.source,
                  if (source.licenseName?.trim().isNotEmpty == true)
                    source.licenseName!,
                ].join(' · '),
                style: const TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 12,
                ),
              ),
            ),
          if (detail.sourceUpdatedAt?.trim().isNotEmpty == true)
            Text(
              '자료 갱신: ${detail.sourceUpdatedAt}',
              style: const TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 12,
              ),
            ),
        ],
      ],
    );
  }
}

class _OfficialAppearanceCard extends StatelessWidget {
  const _OfficialAppearanceCard({
    this.imageUrl,
    this.appearance,
    this.identification,
  });

  final String? imageUrl;
  final String? appearance;
  final DrugAppearanceInfo? identification;

  @override
  Widget build(BuildContext context) {
    final imageUri = Uri.tryParse(imageUrl ?? '');
    final canLoadImage =
        imageUri != null &&
        imageUri.scheme == 'https' &&
        imageUri.host.isNotEmpty;
    final labels = <String>[
      if (identification?.shape?.trim().isNotEmpty == true)
        '모양 ${identification!.shape}',
      if (identification?.color?.trim().isNotEmpty == true)
        '색상 ${identification!.color}',
      if (identification?.imprintFront?.trim().isNotEmpty == true)
        '앞면 ${identification!.imprintFront}',
      if (identification?.imprintBack?.trim().isNotEmpty == true)
        '뒷면 ${identification!.imprintBack}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: MedicalBoxSpacing.x5),
      padding: const EdgeInsets.all(MedicalBoxSpacing.x4),
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(color: MedicalBoxColors.rail),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.scan,
                color: MedicalBoxColors.official,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                '공식 외형·낱알 식별 정보',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (canLoadImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: ColoredBox(
                  color: MedicalBoxColors.surfaceRaised,
                  child: Image.network(
                    imageUri.toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: PhosphorIcon(
                        PhosphorIconsRegular.imageBroken,
                        color: MedicalBoxColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (appearance?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(appearance!, style: const TextStyle(height: 1.45)),
          ],
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final label in labels) _MetadataLabel(label: label),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  const _MetadataLabel({
    required this.label,
    this.foregroundColor = MedicalBoxColors.muted,
    this.borderColor = MedicalBoxColors.railStrong,
  });

  final String label;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.marker),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard({required this.overview});

  final DrugSafetyOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: MedicalBoxSpacing.x5),
      padding: const EdgeInsets.all(MedicalBoxSpacing.x4),
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(color: MedicalBoxColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.shieldWarning,
                color: MedicalBoxColors.warning,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'DUR 공식 안전 참고정보 ${overview.totalCount}개',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (overview.categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final category in overview.categories)
                  _MetadataLabel(
                    label:
                        '${_safetyCategoryLabel(category.ruleType)} ${category.count}',
                    foregroundColor: MedicalBoxColors.warning,
                    borderColor: MedicalBoxColors.warning,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 9),
          const Text(
            '현재 사용자에게 해당한다는 자동 판단이 아니에요. 실제 복용 여부는 의사·약사에게 확인하세요.',
            style: TextStyle(
              color: MedicalBoxColors.muted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySection extends StatelessWidget {
  const _ReadOnlySection({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body?.trim().isNotEmpty != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: MedicalBoxSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MedicalBoxColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: MedicalBoxSpacing.x2),
          Text(body!, style: const TextStyle(height: 1.55)),
          const SizedBox(height: MedicalBoxSpacing.x4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _MedicalInformationNotice extends StatelessWidget {
  const _MedicalInformationNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: MedicalBoxSpacing.x2),
      child: Text(
        '이 정보는 제품 확인을 위한 공식 카탈로그 자료이며 진단, 복용량 계산, 대체약 또는 치료 추천이 아닙니다.',
        style: TextStyle(
          color: MedicalBoxColors.muted,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _CatalogLoadingCard extends StatelessWidget {
  const _CatalogLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CatalogErrorCard extends StatelessWidget {
  const _CatalogErrorCard({required this.accessError, required this.onRetry});

  final bool accessError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(color: MedicalBoxColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.warningCircle,
            color: MedicalBoxColors.warning,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accessError ? '공식 정보 조회 권한을 확인해 주세요.' : '공식 정보를 불러오지 못했어요.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlinkedCatalogNotice extends StatelessWidget {
  const _UnlinkedCatalogNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MedicalBoxColors.surface,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        border: Border.all(color: MedicalBoxColors.rail),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.info,
            color: MedicalBoxColors.muted,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              '직접 입력한 항목이라 연결된 공식 의약품 정보가 없어요.',
              style: TextStyle(color: MedicalBoxColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingInventoryItem extends StatelessWidget {
  const _MissingInventoryItem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.firstAidKit,
              size: 56,
              color: MedicalBoxColors.muted,
            ),
            const SizedBox(height: 14),
            const Text(
              '이 의약품은 보관함에 없어요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/inventory'),
              child: const Text('보관함으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemLoadError extends StatelessWidget {
  const _InventoryItemLoadError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('의약품 정보를 열 수 없어요.'));
  }
}

bool _hasAppearance(DrugDetail detail, String? imageUrl, String? appearance) {
  final identification = detail.identification;
  return (imageUrl?.trim().isNotEmpty ?? false) ||
      (appearance?.trim().isNotEmpty ?? false) ||
      (identification?.shape?.trim().isNotEmpty ?? false) ||
      (identification?.color?.trim().isNotEmpty ?? false) ||
      (identification?.imprintFront?.trim().isNotEmpty ?? false) ||
      (identification?.imprintBack?.trim().isNotEmpty ?? false);
}

bool _isCatalogAccessError(Object error) {
  return error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403);
}

String _safetyCategoryLabel(String ruleType) {
  return switch (ruleType) {
    'contraindication' => '병용금기',
    'age' => '연령금기',
    'pregnancy' => '임부금기',
    'duplication' => '효능군중복',
    'dosage' => '용량주의',
    'duration' => '투여기간주의',
    'elderly' => '노인주의',
    _ => '기타 안전규칙',
  };
}
