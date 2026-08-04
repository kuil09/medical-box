import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/cabinet_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedContainerId = 'shared';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _keepCabinetHeaderVisible(bool open) {
    if (!open) return;
    void resetScroll() {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => resetScroll());
    Future<void>.delayed(const Duration(milliseconds: 320), resetScroll);
  }

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
    final activeName = selectedPouch == null ? '공용 구급상자' : selectedPouch.name;
    final reviewCount = _reviewCount(activeItems);

    return SafeArea(
      child: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                MedicalBoxSpacing.screen,
                0,
                MedicalBoxSpacing.screen,
                28,
              ),
              children: [
                CabinetShell(
                  name: activeName,
                  items: activeItems,
                  reviewCount: reviewCount,
                  showReadinessGuide: selectedPouch == null,
                  onOpenChanged: _keepCabinetHeaderVisible,
                  scopeSelector: FamilyScopeRail(
                    pouches: pouches,
                    selectedId: activeId,
                    onSelected: (id) {
                      setState(() => _selectedContainerId = id);
                    },
                    onManage: () => context.push('/pouch'),
                  ),
                  onItemTap: (item) => context.push(
                    '/inventory/${Uri.encodeComponent(item.id)}',
                  ),
                  onAdd: () {
                    final targetContainerId =
                        selectedPouch?.id ?? sharedContainer?.id;
                    context.push(
                      Uri(
                        path: '/inventory/new',
                        queryParameters: targetContainerId == null
                            ? null
                            : {'containerId': targetContainerId},
                      ).toString(),
                    );
                  },
                  onAddToSection: (target) {
                    final targetContainerId =
                        selectedPouch?.id ?? sharedContainer?.id;
                    context.push(
                      Uri(
                        path: '/inventory/new',
                        queryParameters: {
                          'containerId': ?targetContainerId,
                          'section': target.section,
                          'kind': target.itemKind,
                        },
                      ).toString(),
                    );
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
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Center(
        child: Text(
          '우리집 구급상자',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
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
    return Semantics(
      container: true,
      label: '보관함 선택',
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
      label: '$label 보관함',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
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
