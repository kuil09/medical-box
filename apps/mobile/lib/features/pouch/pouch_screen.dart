import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';

class PouchScreen extends ConsumerWidget {
  const PouchScreen({super.key});

  Future<void> _addPouch(BuildContext context, WidgetRef ref) async {
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
    final database = ref.read(databaseProvider);
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final database = ref.read(databaseProvider);
    await database.transaction(() async {
      await (database.delete(
        database.inventoryContainers,
      )..where((table) => table.id.equals(pouch.id))).go();
      final memberId = pouch.ownerMemberId;
      if (memberId != null) {
        await (database.delete(
          database.memberProfiles,
        )..where((table) => table.id.equals(memberId))).go();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containers = ref.watch(containersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('가족과 개인 파우치')),
      body: containers.when(
        data: (all) {
          final pouches = all
              .where((entry) => entry.kind == 'personal')
              .toList();
          if (pouches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsDuotone.handbagSimple,
                      size: 68,
                      color: MedicalBoxColors.orange,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '가족 구성원을 추가해 보세요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '가족 이름과 파우치 내용은 암호화된\n기기 보관함에만 저장돼요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MedicalBoxColors.muted),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () => _addPouch(context, ref),
                      child: const Text('가족 추가'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: pouches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pouch = pouches[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: index.isEven
                        ? MedicalBoxColors.sky
                        : const Color(0xFFFFD8C8),
                    child: Icon(PhosphorIconsFill.handbagSimple),
                  ),
                  title: Text(
                    pouch.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text('이 기기에서만 보임'),
                  onTap: () =>
                      context.push('/pouch/${Uri.encodeComponent(pouch.id)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'rename') {
                        _renamePouch(context, ref, pouch);
                      } else if (action == 'delete') {
                        _deletePouch(context, ref, pouch);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('이름 바꾸기')),
                      PopupMenuItem(value: 'delete', child: Text('구성원·파우치 삭제')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPouch(context, ref),
        icon: Icon(PhosphorIconsBold.plus),
        label: const Text('가족 추가'),
      ),
    );
  }
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
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MedicalBoxColors.sky.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsDuotone.handbagSimple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '개인 파우치',
                          style: TextStyle(
                            color: MedicalBoxColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${items.length}개 항목',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/inventory/new?containerId=${Uri.encodeQueryComponent(containerId)}',
                    ),
                    icon: Icon(PhosphorIconsBold.plus),
                    label: const Text('추가'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const _EmptyPouch()
            else
              for (var index = 0; index < items.length; index++) ...[
                _PouchInventoryCard(item: items[index], index: index),
                if (index != items.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('파우치를 열 수 없어요: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/inventory/new?containerId=${Uri.encodeQueryComponent(containerId)}',
        ),
        icon: Icon(PhosphorIconsBold.plus),
        label: const Text('의약품 추가'),
      ),
    );
  }
}

class _PouchInventoryCard extends ConsumerWidget {
  const _PouchInventoryCard({required this.item, required this.index});

  final InventoryItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: index.isEven
                    ? const Color(0xFFFFD8C8)
                    : MedicalBoxColors.sky,
                borderRadius: BorderRadius.circular(14),
              ),
              child: PhosphorIcon(PhosphorIconsDuotone.pill),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/inventory/${item.id}/edit'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (item.manufacturer != null) item.manufacturer!,
                          if (item.expiresOn != null)
                            '${DateFormat('yyyy.MM.dd').format(item.expiresOn!)}까지',
                        ].join(' · '),
                        style: const TextStyle(
                          color: MedicalBoxColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
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
              tooltip: '수량 줄이기',
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: () => ref
                  .read(databaseProvider)
                  .setQuantity(item.id, item.quantity + 1),
              icon: Icon(PhosphorIconsRegular.plus),
              tooltip: '수량 늘리기',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPouch extends StatelessWidget {
  const _EmptyPouch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: MedicalBoxColors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text(
            '파우치가 비어 있어요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            '아래 버튼으로 첫 의약품을 추가해 주세요.',
            style: TextStyle(color: MedicalBoxColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
