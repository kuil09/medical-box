import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../services/monetization_service.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';
import '../../widgets/cabinet_shell.dart';
import '../../widgets/privacy_safe_banner_slot.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedContainerId = 'shared';

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(inventoryProvider).valueOrNull ?? const [];
    final sharedItems =
        ref.watch(sharedInventoryProvider).valueOrNull ?? const [];
    final containers = ref.watch(containersProvider).valueOrNull ?? const [];
    final pouches = containers
        .where((container) => container.kind == 'personal')
        .toList();
    InventoryContainer? sharedContainer;
    for (final container in containers) {
      if (container.kind == 'shared') {
        sharedContainer = container;
        break;
      }
    }

    InventoryContainer? selectedPouch;
    for (final pouch in pouches) {
      if (pouch.id == _selectedContainerId) {
        selectedPouch = pouch;
        break;
      }
    }
    final activeId = selectedPouch?.id ?? 'shared';
    final activeItems = selectedPouch == null
        ? sharedItems
        : allItems
              .where((item) => item.containerId == selectedPouch!.id)
              .toList();
    final activeName = selectedPouch == null ? '공용 약장' : selectedPouch.name;
    final reviewCount = _reviewCount(activeItems);

    return SafeArea(
      child: Column(
        children: [
          _HomeHeader(onSettings: () => context.go('/settings')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MedicalBoxSpacing.screen,
                0,
                MedicalBoxSpacing.screen,
                28,
              ),
              children: [
                FamilyScopeRail(
                  pouches: pouches,
                  selectedId: activeId,
                  onSelected: (id) {
                    setState(() => _selectedContainerId = id);
                  },
                  onManage: () => context.push('/pouch'),
                ),
                const SizedBox(height: 16),
                if (reviewCount > 0) ...[
                  CabinetReviewRow(
                    title: '확인이 필요한 약 $reviewCount개',
                    subtitle: '사용기한이 가깝거나 지났어요',
                    onTap: () => context.go('/reminders'),
                  ),
                  const SizedBox(height: 12),
                ],
                const PrivacySafeBannerSlot(
                  placement: BannerAdPlacement.homeAfterSummary,
                ),
                if (reviewCount > 0) const SizedBox(height: 16),
                CabinetShell(
                  name: activeName,
                  items: activeItems,
                  reviewCount: reviewCount,
                  onItemTap: (item) => context.push(
                    '/inventory/${Uri.encodeComponent(item.id)}',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    final targetContainerId =
                        selectedPouch?.id ?? sharedContainer?.id;
                    final containerQuery = targetContainerId == null
                        ? ''
                        : '?containerId=${Uri.encodeQueryComponent(targetContainerId)}';
                    context.push('/inventory/new$containerQuery');
                  },
                  icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                  label: const Text('약 추가'),
                ),
                const SizedBox(height: 8),
                _FullListAction(
                  onTap: () {
                    if (selectedPouch == null) {
                      context.go('/inventory');
                    } else {
                      context.push(
                        '/pouch/${Uri.encodeComponent(selectedPouch.id)}',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                '우리집 약장',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: onSettings,
              icon: const PhosphorIcon(PhosphorIconsRegular.gear),
              tooltip: '설정',
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyScopeRail extends StatelessWidget {
  const FamilyScopeRail({
    required this.pouches,
    required this.selectedId,
    required this.onSelected,
    required this.onManage,
    super.key,
  });

  final List<InventoryContainer> pouches;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ScopeTab(
                  label: '공용',
                  selected: selectedId == 'shared',
                  onTap: () => onSelected('shared'),
                ),
                for (final pouch in pouches)
                  _ScopeTab(
                    label: _pouchDisplayName(pouch.name),
                    selected: selectedId == pouch.id,
                    onTap: () => onSelected(pouch.id),
                  ),
              ],
            ),
          ),
          const VerticalDivider(indent: 10, endIndent: 10),
          IconButton(
            onPressed: onManage,
            icon: const PhosphorIcon(PhosphorIconsRegular.userPlus, size: 20),
            tooltip: '가족 관리',
          ),
        ],
      ),
    );
  }
}

class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label 약장',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: selected
                  ? const Border(
                      bottom: BorderSide(
                        color: MedicalBoxColors.accent,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? MedicalBoxColors.ink : MedicalBoxColors.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullListAction extends StatelessWidget {
  const _FullListAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '전체 목록',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                PhosphorIcon(PhosphorIconsRegular.caretRight, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _reviewCount(List<InventoryItem> items) {
  final cutoff = DateTime.now().add(const Duration(days: 60));
  return items
      .where(
        (item) => item.expiresOn != null && item.expiresOn!.isBefore(cutoff),
      )
      .length;
}

String _pouchDisplayName(String name) {
  return name.endsWith(' 파우치') ? name.substring(0, name.length - 4) : name;
}
