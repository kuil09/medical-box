import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../product_limits.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';
import '../../widgets/official_medicine_thumbnail.dart';
import '../inventory/inventory_item_taxonomy.dart';

class PouchScreen extends ConsumerWidget {
  const PouchScreen({super.key});

  Future<void> _addPouch(BuildContext context, WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final members = await database.select(database.memberProfiles).get();
    if (members.length >= maximumManagedMemberProfiles) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가족 프로필은 최대 10명까지 관리할 수 있어요.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    var input = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 구성원 추가'),
        content: TextFormField(
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            labelText: '가족 이름',
            hintText: '예: 엄마',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final household = await database.select(database.households).getSingle();
    final memberId = const Uuid().v4();
    await database.transaction(() async {
      await database
          .into(database.memberProfiles)
          .insert(
            MemberProfilesCompanion.insert(
              id: memberId,
              householdId: household.id,
              displayName: name,
            ),
          );
      await database
          .into(database.inventoryContainers)
          .insert(
            InventoryContainersCompanion.insert(
              id: const Uuid().v4(),
              householdId: household.id,
              ownerMemberId: Value(memberId),
              name: '$name 파우치',
              kind: 'personal',
              sortOrder: const Value(10),
            ),
          );
    });
  }

  Future<void> _renamePouch(
    BuildContext context,
    WidgetRef ref,
    InventoryContainer pouch,
  ) async {
    final currentName = pouch.name.endsWith(' 파우치')
        ? pouch.name.substring(0, pouch.name.length - 4)
        : pouch.name;
    var input = currentName;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 이름 바꾸기'),
        content: TextFormField(
          initialValue: currentName,
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(labelText: '가족 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final database = ref.read(databaseProvider);
    await database.transaction(() async {
      await (database.update(database.inventoryContainers)
            ..where((table) => table.id.equals(pouch.id)))
          .write(InventoryContainersCompanion(name: Value('$name 파우치')));
      final memberId = pouch.ownerMemberId;
      if (memberId != null) {
        await (database.update(database.memberProfiles)
              ..where((table) => table.id.equals(memberId)))
            .write(MemberProfilesCompanion(displayName: Value(name)));
      }
    });
  }

  Future<void> _deletePouch(
    BuildContext context,
    WidgetRef ref,
    InventoryContainer pouch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 구성원을 삭제할까요?'),
        content: Text('${pouch.name}와 안에 든 의약품을 이 기기에서 함께 삭제해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 18),
            label: const Text('삭제'),
            style: TextButton.styleFrom(
              foregroundColor: MedicalBoxColors.accent,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(localDataLifecycleProvider).deleteMemberPouch(pouch.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구성원과 파우치 삭제를 마치지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(containersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('가족 프로필')),
      body: containers.when(
        data: (all) {
          final pouches = all
              .where((entry) => entry.kind == 'personal')
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              MedicalBoxSpacing.screen,
              MedicalBoxSpacing.x2,
              MedicalBoxSpacing.screen,
              MedicalBoxSpacing.x6,
            ),
            children: [
              const CabinetSectionLabel('관리 프로필'),
              CabinetSectionList(
                children: [
                  if (pouches.isEmpty)
                    const _EmptyProfileRow()
                  else
                    for (final pouch in pouches)
                      _ManagedProfileRow(
                        pouch: pouch,
                        onOpen: () => context.push(
                          '/pouch/${Uri.encodeComponent(pouch.id)}',
                        ),
                        onRename: () => _renamePouch(context, ref, pouch),
                        onDelete: () => _deletePouch(context, ref, pouch),
                      ),
                ],
              ),
              const SizedBox(height: MedicalBoxSpacing.x3),
              Text(
                '프로필 이름과 개인 파우치는 이 기기에만 저장돼요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: MedicalBoxColors.muted),
              ),
              const SizedBox(height: MedicalBoxSpacing.x6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _addPouch(context, ref),
                  icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                  label: const Text('가족 프로필 추가'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class _ManagedProfileRow extends StatelessWidget {
  const _ManagedProfileRow({
    required this.pouch,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final InventoryContainer pouch;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MedicalBoxSpacing.touchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MedicalBoxSpacing.x4,
            MedicalBoxSpacing.x3,
            MedicalBoxSpacing.x2,
            MedicalBoxSpacing.x3,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 40,
                child: PhosphorIcon(
                  PhosphorIconsRegular.user,
                  size: 24,
                  color: MedicalBoxColors.ink,
                ),
              ),
              const SizedBox(width: MedicalBoxSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileName(pouch.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: MedicalBoxSpacing.x1),
                    Text(
                      '가족 프로필 · 개인 파우치',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MedicalBoxColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: MedicalBoxColors.muted,
              ),
              PopupMenuButton<String>(
                tooltip: '프로필 작업',
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  size: 20,
                ),
                onSelected: (action) {
                  if (action == 'rename') {
                    onRename();
                  } else if (action == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: _ProfileMenuItem(
                      icon: PhosphorIconsRegular.pencilSimple,
                      label: '이름 바꾸기',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: const _ProfileMenuItem(
                      icon: PhosphorIconsRegular.trash,
                      label: '구성원·파우치 삭제',
                      color: MedicalBoxColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.color = MedicalBoxColors.ink,
  });

  final Object icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: color),
        const SizedBox(width: MedicalBoxSpacing.x3),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _EmptyProfileRow extends StatelessWidget {
  const _EmptyProfileRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedicalBoxSpacing.x4,
        vertical: MedicalBoxSpacing.x6,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: PhosphorIcon(
              PhosphorIconsRegular.users,
              size: 24,
              color: MedicalBoxColors.muted,
            ),
          ),
          const SizedBox(width: MedicalBoxSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '등록된 가족 프로필이 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MedicalBoxSpacing.x1),
                Text(
                  '가족별 개인 파우치를 만들 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MedicalBoxColors.muted,
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

String _profileName(String pouchName) {
  return pouchName.endsWith(' 파우치')
      ? pouchName.substring(0, pouchName.length - 4)
      : pouchName;
}

class PouchDetailScreen extends ConsumerWidget {
  const PouchDetailScreen({required this.containerId, super.key});

  final String containerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(containersProvider).valueOrNull ?? const [];
    InventoryContainer? pouch;
    for (final container in containers) {
      if (container.id == containerId) {
        pouch = container;
        break;
      }
    }
    final inventory = ref.watch(inventoryForContainerProvider(containerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(pouch?.name ?? '개인 파우치'),
        actions: [
          IconButton(
            onPressed: () => context.push('/pouch'),
            icon: Icon(PhosphorIconsRegular.usersThree),
            tooltip: '가족 구성원 관리',
          ),
        ],
      ),
      body: inventory.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(
            MedicalBoxSpacing.screen,
            MedicalBoxSpacing.x2,
            MedicalBoxSpacing.screen,
            MedicalBoxSpacing.x6,
          ),
          children: [
            const CabinetSectionLabel('보관 의약품'),
            CabinetSectionList(
              showDividers: items.isNotEmpty,
              children: [
                if (items.isEmpty)
                  const _EmptyPouchRow()
                else
                  for (final item in items) _PouchInventoryRow(item: item),
              ],
            ),
            const SizedBox(height: MedicalBoxSpacing.x6),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/inventory/new?containerId=${Uri.encodeQueryComponent(containerId)}',
                ),
                icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                label: const Text('의약품 추가'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('파우치를 열 수 없어요: $error')),
      ),
    );
  }
}

class _PouchInventoryRow extends StatelessWidget {
  const _PouchInventoryRow({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (item.manufacturer?.isNotEmpty ?? false) item.manufacturer!,
      if (item.expiresOn != null)
        '${DateFormat('yyyy.MM.dd').format(item.expiresOn!)}까지',
    ].join(' · ');

    return InkWell(
      onTap: () => context.push('/inventory/${item.id}'),
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
                imageBytes: item.capturedImageBytes,
                fallbackIcon: item.itemKind == InventoryItemKinds.firstAidSupply
                    ? PhosphorIconsRegular.firstAidKit
                    : PhosphorIconsRegular.pill,
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

class _EmptyPouchRow extends StatelessWidget {
  const _EmptyPouchRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedicalBoxSpacing.x4,
        vertical: MedicalBoxSpacing.x8,
      ),
      child: Column(
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.handbagSimple,
            size: 32,
            color: MedicalBoxColors.ink,
          ),
          const SizedBox(height: MedicalBoxSpacing.x3),
          Text('파우치가 비어 있어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: MedicalBoxSpacing.x1),
          Text(
            '아래 버튼으로 첫 의약품을 추가해 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MedicalBoxColors.muted),
          ),
        ],
      ),
    );
  }
}
