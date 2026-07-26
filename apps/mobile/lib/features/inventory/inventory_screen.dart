import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/official_medicine_thumbnail.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(sharedInventoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공용 트레이'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => context.push('/inventory/new'),
            icon: Icon(PhosphorIconsBold.plus),
            tooltip: '의약품 등록',
          ),
        ],
      ),
      body: inventory.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyInventory(onAdd: () => context.push('/inventory/new'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      OfficialMedicineThumbnail(
                        imageUrl: item.officialImageUrl,
                        fallbackIcon: PhosphorIconsDuotone.pill,
                        backgroundColor: index.isEven
                            ? MedicalBoxColors.sky
                            : const Color(0xFFFFD8C8),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              context.push('/inventory/${item.id}/edit'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (item.manufacturer != null)
                                    item.manufacturer!,
                                  if (item.expiresOn != null)
                                    '${DateFormat('yyyy.MM.dd').format(item.expiresOn!)}까지',
                                ].join(' · '),
                                style: const TextStyle(
                                  color: MedicalBoxColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              if (item.appearanceSummary?.isNotEmpty ?? false)
                                Text(
                                  item.appearanceSummary!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MedicalBoxColors.skyDeep,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: item.quantity <= 0
                            ? null
                            : () => ref
                                  .read(databaseProvider)
                                  .setQuantity(item.id, item.quantity - 1),
                        icon: Icon(PhosphorIconsRegular.minus),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(databaseProvider)
                            .setQuantity(item.id, item.quantity + 1),
                        icon: Icon(PhosphorIconsRegular.plus),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('보관함을 열 수 없어요: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/new'),
        backgroundColor: MedicalBoxColors.orange,
        foregroundColor: Colors.white,
        icon: Icon(PhosphorIconsBold.plus),
        label: const Text('약 등록'),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsDuotone.firstAidKit,
              size: 68,
              color: MedicalBoxColors.skyDeep,
            ),
            const SizedBox(height: 18),
            const Text(
              '공용 트레이가 비어 있어요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '의약품 이름을 검색하거나 직접 입력해\n첫 보유약을 등록해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MedicalBoxColors.muted),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onAdd, child: const Text('첫 약 등록하기')),
          ],
        ),
      ),
    );
  }
}
