import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../services/inventory_share_service.dart';
import '../../theme.dart';
import '../../widgets/official_medicine_thumbnail.dart';
import '../../widgets/privacy_safe_banner_slot.dart';
import '../../services/monetization_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedContainerId = 'shared';

  Future<void> _showSharePreview({
    required String containerName,
    required List<InventoryItem> items,
  }) async {
    var options = const InventoryShareOptions();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final preview = buildInventoryShareText(
            containerName: containerName,
            items: items,
            options: options,
          );
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '문자로 공유할 정보 고르기',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '선택한 내용만 문자와 공유 앱으로 전달하며 서버에는 저장하지 않아요.',
                      style: TextStyle(color: MedicalBoxColors.muted),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('수량'),
                      value: options.includeQuantity,
                      onChanged: (value) => setSheetState(
                        () => options = options.copyWith(
                          includeQuantity: value ?? false,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('사용기한'),
                      value: options.includeExpiry,
                      onChanged: (value) => setSheetState(
                        () => options = options.copyWith(
                          includeExpiry: value ?? false,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('공식 제품 정보 링크'),
                      value: options.includeOfficialLinks,
                      onChanged: (value) => setSheetState(
                        () => options = options.copyWith(
                          includeOfficialLinks: value ?? false,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('선택한 공식 외형'),
                      subtitle: const Text('모양·색상·각인만 포함해요.'),
                      value: options.includeOfficialAppearance,
                      onChanged: (value) => setSheetState(
                        () => options = options.copyWith(
                          includeOfficialAppearance: value ?? false,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('개인 메모'),
                      subtitle: const Text('민감할 수 있어 기본적으로 제외해요.'),
                      value: options.includePrivateNotes,
                      onChanged: (value) => setSheetState(
                        () => options = options.copyWith(
                          includePrivateNotes: value ?? false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '미리보기',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MedicalBoxColors.ivory,
                        border: Border.all(color: MedicalBoxColors.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          preview,
                          style: const TextStyle(fontSize: 12, height: 1.45),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final renderBox =
                              context.findRenderObject() as RenderBox?;
                          Navigator.pop(sheetContext);
                          await SharePlus.instance.share(
                            ShareParams(
                              text: preview,
                              subject: '우리집 구급키트 · $containerName',
                              sharePositionOrigin: renderBox == null
                                  ? null
                                  : renderBox.localToGlobal(Offset.zero) &
                                        renderBox.size,
                            ),
                          );
                        },
                        icon: Icon(PhosphorIconsBold.shareNetwork),
                        label: const Text('문자·공유 앱 열기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final items = inventory.valueOrNull ?? const [];
    final sharedItems =
        ref.watch(sharedInventoryProvider).valueOrNull ?? const [];
    final containers = ref.watch(containersProvider).valueOrNull ?? const [];
    final pouches = containers
        .where((container) => container.kind == 'personal')
        .toList();
    InventoryContainer? selectedPouch;
    for (final pouch in pouches) {
      if (pouch.id == _selectedContainerId) {
        selectedPouch = pouch;
        break;
      }
    }
    final selectedId = selectedPouch?.id ?? 'shared';
    final selectedItems = selectedPouch == null
        ? const <InventoryItem>[]
        : items.where((item) => item.containerId == selectedPouch!.id).toList();
    final selectedPouchIndex = selectedPouch == null
        ? 0
        : pouches.indexOf(selectedPouch);
    final activeItems = selectedPouch == null ? sharedItems : selectedItems;
    final activeContainerName = selectedPouch == null
        ? '공용 트레이'
        : selectedPouch.name;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '우리집 구급키트',
                      style: TextStyle(
                        color: MedicalBoxColors.orange,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '오늘도, 꺼내기 전에\n한번만 확인해요.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _showSharePreview(
                      containerName: activeContainerName,
                      items: activeItems,
                    ),
                    icon: Icon(PhosphorIconsRegular.shareNetwork),
                    tooltip: '현재 보관함 공유',
                  ),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(
                    onPressed: () => context.go('/settings'),
                    icon: Icon(PhosphorIconsRegular.gear),
                    tooltip: '설정',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StorageTabs(
            pouches: pouches,
            inventory: items,
            selectedId: selectedId,
            onSelected: (id) => setState(() => _selectedContainerId = id),
            onManage: () => context.push('/pouch'),
          ),
          const SizedBox(height: 18),
          if (selectedPouch == null)
            _InteractiveMedicineTray(
              items: sharedItems,
              onOpen: () => context.go('/inventory'),
              onAdd: () => context.push('/inventory/new'),
              onEditItem: (item) => context.push('/inventory/${item.id}/edit'),
            )
          else
            _InteractivePersonalPouch(
              pouch: selectedPouch,
              items: selectedItems,
              index: selectedPouchIndex,
              onOpen: () => context.push(
                '/pouch/${Uri.encodeComponent(selectedPouch!.id)}',
              ),
              onAdd: () => context.push(
                '/inventory/new?containerId=${Uri.encodeQueryComponent(selectedPouch!.id)}',
              ),
              onManage: () => context.push('/pouch'),
              onEditItem: (item) => context.push('/inventory/${item.id}/edit'),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  color: MedicalBoxColors.sky,
                  icon: PhosphorIconsDuotone.firstAidKit,
                  title: '공용 트레이',
                  subtitle: '수량과 사용기한 확인',
                  onTap: () => context.go('/inventory'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  color: const Color(0xFFFFD8C8),
                  icon: PhosphorIconsDuotone.bell,
                  title: '알림',
                  subtitle: '기기 안에서만 예약',
                  onTap: () => context.go('/reminders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WideActionCard(
            icon: PhosphorIconsDuotone.calendarCheck,
            title: '진료·갱신 준비',
            subtitle: '남은 수량과 방문 준비사항만 정리해요',
            onTap: () => context.push('/renewal'),
          ),
          const SizedBox(height: 20),
          const PrivacySafeBannerSlot(
            placement: BannerAdPlacement.homeAfterSummary,
          ),
          const _PrivacyStrip(),
        ],
      ),
    );
  }
}

class _StorageTabs extends StatelessWidget {
  const _StorageTabs({
    required this.pouches,
    required this.inventory,
    required this.selectedId,
    required this.onSelected,
    required this.onManage,
  });

  final List<InventoryContainer> pouches;
  final List<InventoryItem> inventory;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pouches.length + 2,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StorageTab(
              label: '공용',
              count: inventory
                  .where(
                    (item) =>
                        !pouches.any((pouch) => pouch.id == item.containerId),
                  )
                  .length,
              icon: PhosphorIconsDuotone.firstAidKit,
              selected: selectedId == 'shared',
              onTap: () => onSelected('shared'),
            );
          }
          if (index == pouches.length + 1) {
            return _StorageTab(
              label: '추가',
              subtitle: '파우치',
              icon: PhosphorIconsBold.plus,
              selected: false,
              dashed: true,
              onTap: onManage,
            );
          }
          final pouch = pouches[index - 1];
          final count = inventory
              .where((item) => item.containerId == pouch.id)
              .length;
          return _StorageTab(
            label: _pouchDisplayName(pouch.name),
            count: count,
            icon: PhosphorIconsDuotone.user,
            selected: selectedId == pouch.id,
            tone: index - 1,
            onTap: () => onSelected(pouch.id),
          );
        },
      ),
    );
  }
}

class _StorageTab extends StatelessWidget {
  const _StorageTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
    this.subtitle,
    this.tone,
    this.dashed = false,
  });

  final String label;
  final Object icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final String? subtitle;
  final int? tone;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final tones = [
      const Color(0xFFCFE4D8),
      const Color(0xFFFFD8C8),
      MedicalBoxColors.sky,
    ];
    final baseColor = tone == null ? Colors.white : tones[tone! % tones.length];
    return Semantics(
      selected: selected,
      button: true,
      label: '$label 보관함 탭',
      child: Material(
        color: baseColor.withValues(alpha: selected ? 1 : 0.62),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? MedicalBoxColors.orange : MedicalBoxColors.line,
            width: selected ? 1.5 : 1,
            style: dashed ? BorderStyle.none : BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: selected
                  ? const Border(
                      bottom: BorderSide(
                        color: MedicalBoxColors.orange,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  icon,
                  size: 21,
                  color: selected ? MedicalBoxColors.orange : null,
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle ?? '${count ?? 0}개',
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePersonalPouch extends StatelessWidget {
  const _InteractivePersonalPouch({
    required this.pouch,
    required this.items,
    required this.index,
    required this.onOpen,
    required this.onAdd,
    required this.onManage,
    required this.onEditItem,
  });

  final InventoryContainer pouch;
  final List<InventoryItem> items;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onManage;
  final ValueChanged<InventoryItem> onEditItem;

  @override
  Widget build(BuildContext context) {
    final tones = [
      const Color(0xFFCFE4D8),
      const Color(0xFFFFD8C8),
      MedicalBoxColors.sky,
    ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tones[index % tones.length],
        border: Border.all(color: MedicalBoxColors.line),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: PhosphorIcon(PhosphorIconsDuotone.user, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기기 안에서만',
                      style: TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${_pouchDisplayName(pouch.name)}의 개인 파우치',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onManage,
                icon: Icon(PhosphorIconsRegular.pencilSimple),
                tooltip: '가족 구성원 관리',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '첫 의약품을 추가해 주세요',
                  style: TextStyle(
                    color: MedicalBoxColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            for (final item in items.take(3)) ...[
              Material(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: () => onEditItem(item),
                  borderRadius: BorderRadius.circular(17),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
                    child: Row(
                      children: [
                        OfficialMedicineThumbnail(
                          imageUrl: item.officialImageUrl,
                          fallbackIcon: PhosphorIconsDuotone.pill,
                          size: 38,
                          borderRadius: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                item.expiresOn == null
                                    ? '사용기한 미입력'
                                    : '${item.expiresOn!.toIso8601String().split('T').first}까지',
                                style: const TextStyle(
                                  color: MedicalBoxColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.quantity}개',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 6),
                        Icon(PhosphorIconsRegular.caretRight, size: 15),
                      ],
                    ),
                  ),
                ),
              ),
              if (item != items.take(3).last) const SizedBox(height: 7),
            ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: Icon(PhosphorIconsBold.plus),
                  label: const Text('의약품 추가'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: Icon(PhosphorIconsRegular.caretRight),
                  label: const Text('전체 파우치'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _pouchDisplayName(String name) {
  return name.endsWith(' 파우치') ? name.substring(0, name.length - 4) : name;
}

class _InteractiveMedicineTray extends StatefulWidget {
  const _InteractiveMedicineTray({
    required this.items,
    required this.onOpen,
    required this.onAdd,
    required this.onEditItem,
  });

  final List<InventoryItem> items;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final ValueChanged<InventoryItem> onEditItem;

  @override
  State<_InteractiveMedicineTray> createState() =>
      _InteractiveMedicineTrayState();
}

class _InteractiveMedicineTrayState extends State<_InteractiveMedicineTray> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final digestive = widget.items
        .where((item) => item.productName.isNotEmpty && _isDigestive(item))
        .toList();
    final wound = widget.items.where(_isWoundCare).toList();
    final other = widget.items
        .where((item) => !digestive.contains(item) && !wound.contains(item))
        .toList();

    return Semantics(
      expanded: _isOpen,
      label: _isOpen
          ? '열린 공용 의약품 구급상자, 의약품 ${widget.items.length}개가 보임'
          : '닫힌 공용 의약품 구급상자',
      child: Column(
        children: [
          _MedicineBoxShell(
            isOpen: _isOpen,
            items: widget.items,
            onToggle: () => setState(() => _isOpen = !_isOpen),
            onItemTap: widget.onEditItem,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 360),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            crossFadeState: _isOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E7DB),
                border: Border.all(color: MedicalBoxColors.line),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '상자 안 ${widget.items.length}개 · 보이는 의약품을 선택하세요',
                          style: const TextStyle(
                            color: MedicalBoxColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: widget.onAdd,
                        icon: Icon(PhosphorIconsBold.plus),
                        tooltip: '공용 트레이에 의약품 추가',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _TrayCompartment(
                          label: '소화',
                          items: digestive,
                          color: const Color(0xFFF9F4EC),
                          icon: PhosphorIconsDuotone.pill,
                          onTap: widget.onOpen,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _TrayCompartment(
                          label: '상처 관리',
                          items: wound,
                          color: const Color(0xFFFFD8C8),
                          icon: PhosphorIconsDuotone.firstAidKit,
                          onTap: widget.onOpen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _TrayCompartment(
                    label: '기타',
                    items: other,
                    color: Colors.white.withValues(alpha: 0.74),
                    icon: PhosphorIconsDuotone.archive,
                    onTap: widget.onOpen,
                    compact: true,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  static bool _isDigestive(InventoryItem item) {
    final text = '${item.productName} ${item.privateNote ?? ''}';
    return text.contains('소화') || text.contains('효소');
  }

  static bool _isWoundCare(InventoryItem item) {
    final text = '${item.productName} ${item.privateNote ?? ''}';
    return text.contains('밴드') ||
        text.contains('거즈') ||
        text.contains('소독') ||
        text.contains('상처');
  }
}

class _MedicineBoxShell extends StatelessWidget {
  const _MedicineBoxShell({
    required this.isOpen,
    required this.items,
    required this.onToggle,
    required this.onItemTap,
  });

  final bool isOpen;
  final List<InventoryItem> items;
  final VoidCallback onToggle;
  final ValueChanged<InventoryItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isOpen ? 236 : 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: 0,
            height: isOpen ? 166 : 108,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8F1E7), Color(0xFFD6C5B0)],
                ),
                border: Border.all(color: const Color(0xFFAA9075), width: 1.4),
                borderRadius: BorderRadius.circular(isOpen ? 24 : 30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Positioned(
              left: 18,
              right: 18,
              bottom: 28,
              height: 124,
              child: _MedicineObjectsDeck(items: items, onItemTap: onItemTap),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            top: isOpen ? 1 : 26,
            left: 8,
            right: 8,
            height: isOpen ? 76 : 92,
            child: Semantics(
              button: true,
              label: isOpen ? '공용 구급상자 닫기' : '공용 구급상자 열기, 의약품 ${items.length}개',
              child: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  transformAlignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(isOpen ? -0.92 : 0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFBF4), Color(0xFFE4D5C1)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFAA9075),
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: MedicalBoxColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsBold.firstAid,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        isOpen ? '열림 · 눌러서 닫기' : '${items.length}개 · 눌러서 열기',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 58,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF9C8065),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineObjectsDeck extends StatelessWidget {
  const _MedicineObjectsDeck({required this.items, required this.onItemTap});

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(4).toList();
    if (visibleItems.isEmpty) {
      return const Center(
        child: Text(
          '상자가 비어 있어요',
          style: TextStyle(
            color: MedicalBoxColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleItems
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  height: 58,
                  child: _MedicineObject(
                    item: item,
                    onTap: () => onItemTap(item),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MedicineObject extends StatelessWidget {
  const _MedicineObject({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final woundCare = _InteractiveMedicineTrayState._isWoundCare(item);
    final digestive = _InteractiveMedicineTrayState._isDigestive(item);
    final color = woundCare
        ? const Color(0xFFF1C6B8)
        : digestive
        ? const Color(0xFFF7F0E4)
        : const Color(0xFFC7DCEB);
    final icon = item.productName.contains('거즈')
        ? PhosphorIconsDuotone.bandaids
        : woundCare
        ? PhosphorIconsDuotone.firstAidKit
        : PhosphorIconsDuotone.pill;

    return Semantics(
      button: true,
      label: '${item.productName}, ${item.quantity}개, 편집',
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-0.08),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: 0.95), color],
                ),
                border: Border.all(color: MedicalBoxColors.line),
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OfficialMedicineThumbnail(
                    imageUrl: item.officialImageUrl,
                    fallbackIcon: icon,
                    size: 31,
                    borderRadius: 9,
                    backgroundColor: color,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantity}개',
                    style: const TextStyle(
                      color: MedicalBoxColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrayCompartment extends StatelessWidget {
  const _TrayCompartment({
    required this.label,
    required this.items,
    required this.color,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final List<InventoryItem> items;
  final Color color;
  final Object icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final summary = items.isEmpty
        ? '비어 있음'
        : items.map((item) => item.productName).take(2).join(' · ');
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: compact ? 70 : 94,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: MedicalBoxColors.line),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, size: compact ? 25 : 29),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label · ${items.length}개',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final Object icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 156,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(icon, size: 30),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WideActionCard extends StatelessWidget {
  const _WideActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Object icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5D8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: PhosphorIcon(icon, color: MedicalBoxColors.orange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: Icon(PhosphorIconsRegular.caretRight),
        onTap: onTap,
      ),
    );
  }
}

class _PrivacyStrip extends StatelessWidget {
  const _PrivacyStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          PhosphorIconsFill.shieldCheck,
          color: MedicalBoxColors.skyDeep,
          size: 20,
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            '가족 이름·수량·메모·방문일은 이 기기 밖으로 전송하지 않아요.',
            style: TextStyle(color: MedicalBoxColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
