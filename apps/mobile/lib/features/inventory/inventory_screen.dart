import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../services/monetization_service.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';
import '../../widgets/official_medicine_thumbnail.dart';
import '../../widgets/privacy_safe_banner_slot.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(sharedInventoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공용 트레이'),
        backgroundColor: Colors.transparent,
      ),
      body: inventory.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyInventory(onAdd: () => context.push('/inventory/new'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              MedicalBoxSpacing.screen,
              MedicalBoxSpacing.x2,
              MedicalBoxSpacing.screen,
              MedicalBoxSpacing.x6,
            ),
            children: [
              const CabinetSectionLabel('공용 약장'),
              CabinetSectionList(
                children: [
                  for (final item in items)
                    _InventoryRow(
                      item: item,
                      onTap: () => context.push('/inventory/${item.id}'),
                    ),
                ],
              ),
              const SizedBox(height: MedicalBoxSpacing.x6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/inventory/new'),
                  icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                  label: const Text('약 등록'),
                ),
              ),
              const SizedBox(height: MedicalBoxSpacing.x6),
              const PrivacySafeBannerSlot(
                placement: BannerAdPlacement.inventoryListEnd,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('보관함을 열 수 없어요: $error')),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (item.manufacturer?.isNotEmpty ?? false) item.manufacturer!,
      if (item.expiresOn != null)
        '${DateFormat('yyyy.MM.dd').format(item.expiresOn!)}까지',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MedicalBoxSpacing.x4,
            MedicalBoxSpacing.x3,
            MedicalBoxSpacing.x3,
            MedicalBoxSpacing.x3,
          ),
          child: Row(
            children: [
              OfficialMedicineThumbnail(
                imageUrl: item.officialImageUrl,
                fallbackIcon: PhosphorIconsRegular.pill,
                size: 48,
                backgroundColor: MedicalBoxColors.surfaceRaised,
                borderRadius: MedicalBoxRadius.control,
              ),
              const SizedBox(width: MedicalBoxSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: MedicalBoxSpacing.x1),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (item.appearanceSummary?.isNotEmpty ?? false) ...[
                      const SizedBox(height: MedicalBoxSpacing.x1),
                      Text(
                        item.appearanceSummary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MedicalBoxColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: MedicalBoxSpacing.x2),
                    OfficialSourceLabel(connected: item.itemSeq != null),
                  ],
                ),
              ),
              const SizedBox(width: MedicalBoxSpacing.x2),
              const PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                color: MedicalBoxColors.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MedicalBoxSpacing.screen,
        MedicalBoxSpacing.x2,
        MedicalBoxSpacing.screen,
        MedicalBoxSpacing.x6,
      ),
      children: [
        const CabinetSectionLabel('공용 약장'),
        CabinetSectionList(
          showDividers: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MedicalBoxSpacing.x5,
                vertical: MedicalBoxSpacing.x8,
              ),
              child: Column(
                children: [
                  const PhosphorIcon(
                    PhosphorIconsRegular.firstAidKit,
                    size: 36,
                    color: MedicalBoxColors.ink,
                  ),
                  const SizedBox(height: MedicalBoxSpacing.x4),
                  Text(
                    '공용 트레이가 비어 있어요',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: MedicalBoxSpacing.x2),
                  Text(
                    '의약품 이름을 검색하거나 직접 입력해\n첫 보유약을 등록해 보세요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MedicalBoxColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: MedicalBoxSpacing.x6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
            label: const Text('첫 약 등록하기'),
          ),
        ),
      ],
    );
  }
}
