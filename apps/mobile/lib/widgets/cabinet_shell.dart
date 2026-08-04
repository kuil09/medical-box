import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../data/local/app_database.dart';
import '../features/inventory/inventory_item_taxonomy.dart';
import '../theme.dart';
import 'official_medicine_thumbnail.dart';

@immutable
class CabinetReadinessTarget {
  const CabinetReadinessTarget({required this.section, required this.itemKind});

  final String section;
  final String itemKind;
}

class CabinetShell extends StatefulWidget {
  const CabinetShell({
    required this.name,
    required this.items,
    required this.onItemTap,
    this.onAdd,
    this.onAddToSection,
    this.onOpenChanged,
    this.reviewCount = 0,
    this.showReadinessGuide = false,
    this.scopeSelector,
    super.key,
  });

  final String name;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final VoidCallback? onAdd;
  final ValueChanged<CabinetReadinessTarget>? onAddToSection;
  final ValueChanged<bool>? onOpenChanged;
  final int reviewCount;
  final bool showReadinessGuide;
  final Widget? scopeSelector;

  @override
  State<CabinetShell> createState() => _CabinetShellState();
}

class _CabinetShellState extends State<CabinetShell> {
  bool _isOpen = false;

  void _toggle() {
    final nextOpen = !_isOpen;
    setState(() => _isOpen = nextOpen);
    widget.onOpenChanged?.call(nextOpen);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return Semantics(
      container: true,
      expanded: _isOpen,
      label: _isOpen
          ? '${widget.name} 열림, 의약품 ${widget.items.length}개'
          : '${widget.name} 닫힘, 의약품 ${widget.items.length}개',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isOpen ? -0.035 : 0),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, angle, child) => Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(angle),
              child: child,
            ),
            child: _CabinetLid(
              child:
                  widget.scopeSelector ??
                  _CabinetLidLabel(
                    name: widget.name,
                    itemCount: widget.items.length,
                  ),
            ),
          ),
          const _CabinetHinges(),
          _CabinetBase(
            key: ValueKey(_isOpen),
            child: _isOpen
                ? _OpenCabinet(
                    items: widget.items,
                    onItemTap: widget.onItemTap,
                    onAdd: widget.onAdd,
                    onAddToSection: widget.onAddToSection,
                    onClose: _toggle,
                    showReadinessGuide: widget.showReadinessGuide,
                  )
                : _ClosedCabinetDoor(
                    name: widget.name,
                    itemCount: widget.items.length,
                    reviewCount: widget.reviewCount,
                    onOpen: _toggle,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CabinetLid extends StatelessWidget {
  const _CabinetLid({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedicalBoxColors.surfaceContainer,
        border: Border.all(color: MedicalBoxColors.railStrong),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F17191C),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 1,
            offset: Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MedicalBoxColors.surface,
            border: Border.all(color: MedicalBoxColors.rail),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1217191C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(height: 70, child: child),
        ),
      ),
    );
  }
}

class _CabinetLidLabel extends StatelessWidget {
  const _CabinetLidLabel({required this.name, required this.itemCount});

  final String name;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            '$itemCount개',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MedicalBoxColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CabinetHinges extends StatelessWidget {
  const _CabinetHinges();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 58),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < 2; index++)
              Container(
                width: 42,
                height: 13,
                decoration: BoxDecoration(
                  color: MedicalBoxColors.surfaceContainer,
                  border: Border.all(color: MedicalBoxColors.railStrong),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A17191C),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CabinetBase extends StatelessWidget {
  const _CabinetBase({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MedicalBoxColors.surfaceContainer,
          border: Border.all(color: MedicalBoxColors.railStrong),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2417191C),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0xFFFFFFFF),
              blurRadius: 1,
              offset: Offset(0, 1),
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ClosedCabinetDoor extends StatelessWidget {
  const _ClosedCabinetDoor({
    required this.name,
    required this.itemCount,
    required this.reviewCount,
    required this.onOpen,
  });

  final String name;
  final int itemCount;
  final int reviewCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final summary = reviewCount > 0 ? '확인할 약 $reviewCount개' : '보관약 확인';
    return Material(
      color: MedicalBoxColors.surface,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 248),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: MedicalBoxColors.rail),
                    borderRadius: BorderRadius.circular(
                      MedicalBoxRadius.control,
                    ),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.firstAidKit,
                    color: MedicalBoxColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MedicalBoxColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Text(
                  '열기',
                  style: TextStyle(
                    color: MedicalBoxColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenCabinet extends StatelessWidget {
  const _OpenCabinet({
    required this.items,
    required this.onItemTap,
    required this.onAdd,
    required this.onAddToSection,
    required this.onClose,
    required this.showReadinessGuide,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final VoidCallback? onAdd;
  final ValueChanged<CabinetReadinessTarget>? onAddToSection;
  final VoidCallback onClose;
  final bool showReadinessGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CabinetInterior(
          items: items,
          onItemTap: onItemTap,
          onAddToSection: onAddToSection,
          showReadinessGuide: showReadinessGuide,
        ),
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MedicalBoxColors.accent,
                  side: const BorderSide(color: MedicalBoxColors.rail),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MedicalBoxRadius.control,
                    ),
                  ),
                ),
                icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                label: const Text('물품 추가'),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton.icon(
            onPressed: onClose,
            iconAlignment: IconAlignment.end,
            icon: const PhosphorIcon(PhosphorIconsRegular.caretUp, size: 15),
            label: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}

class _CabinetInterior extends StatelessWidget {
  const _CabinetInterior({
    required this.items,
    required this.onItemTap,
    required this.onAddToSection,
    required this.showReadinessGuide,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final ValueChanged<CabinetReadinessTarget>? onAddToSection;
  final bool showReadinessGuide;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !showReadinessGuide) {
      return const SizedBox(
        height: 248,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.tray,
                color: MedicalBoxColors.faint,
                size: 30,
              ),
              SizedBox(height: 10),
              Text(
                '아직 보관한 약이 없어요',
                style: TextStyle(
                  color: MedicalBoxColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = <String, List<InventoryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.cabinetSection, () => []).add(item);
    }
    final sections = <String>[
      for (final section in CabinetSections.values)
        if (groups[section]?.isNotEmpty == true) section,
      for (final section in groups.keys)
        if (!CabinetSections.values.contains(section)) section,
    ];
    final readyCount = CabinetSections.householdReadinessGuide
        .where((section) => _isReadinessRegistered(section, items))
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: MedicalBoxColors.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Color(0x1417191C),
            blurRadius: 8,
            offset: Offset(0, 3),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Column(
        children: [
          if (showReadinessGuide) ...[
            _ReadinessGuideMap(
              items: items,
              readyCount: readyCount,
              onAddToSection: onAddToSection,
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '보관 중인 물품',
                    style: TextStyle(
                      color: MedicalBoxColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
          for (var index = 0; index < sections.length; index++) ...[
            const SizedBox(height: 8),
            _CabinetCompartmentRow(
              label: CabinetSections.label(sections[index]),
              items: groups[sections[index]]!,
              onItemTap: onItemTap,
            ),
          ],
          if (showReadinessGuide) ...[
            const SizedBox(height: 8),
            const _ReadinessGuideFootnote(),
          ],
        ],
      ),
    );
  }
}

class _ReadinessGuideMap extends StatelessWidget {
  const _ReadinessGuideMap({
    required this.items,
    required this.readyCount,
    required this.onAddToSection,
  });

  final List<InventoryItem> items;
  final int readyCount;
  final ValueChanged<CabinetReadinessTarget>? onAddToSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '가정용 준비 지도',
                  style: TextStyle(
                    color: MedicalBoxColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$readyCount/${CabinetSections.householdReadinessGuide.length} 등록',
                style: const TextStyle(
                  color: MedicalBoxColors.official,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _ReadinessGuideSection(
          title: '상비약',
          sections: CabinetSections.householdMedicineGuide,
          itemKind: InventoryItemKinds.medicine,
          items: items,
          onAddToSection: onAddToSection,
        ),
        const SizedBox(height: 10),
        _ReadinessGuideSection(
          title: '구급용품',
          sections: CabinetSections.householdFirstAidGuide,
          itemKind: InventoryItemKinds.firstAidSupply,
          items: items,
          onAddToSection: onAddToSection,
        ),
      ],
    );
  }
}

class _ReadinessGuideSection extends StatelessWidget {
  const _ReadinessGuideSection({
    required this.title,
    required this.sections,
    required this.itemKind,
    required this.items,
    required this.onAddToSection,
  });

  final String title;
  final List<String> sections;
  final String itemKind;
  final List<InventoryItem> items;
  final ValueChanged<CabinetReadinessTarget>? onAddToSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: MedicalBoxColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 6.0;
            final width = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final section in sections)
                  SizedBox(
                    width: width,
                    child: _ReadinessGuideTile(
                      label: CabinetSections.label(section),
                      isRegistered: items.any(
                        (item) =>
                            item.cabinetSection == section &&
                            item.itemKind == itemKind,
                      ),
                      onAdd: onAddToSection == null
                          ? null
                          : () => onAddToSection!(
                              CabinetReadinessTarget(
                                section: section,
                                itemKind: itemKind,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

bool _isReadinessRegistered(String section, List<InventoryItem> items) {
  final itemKind = CabinetSections.householdMedicineGuide.contains(section)
      ? InventoryItemKinds.medicine
      : InventoryItemKinds.firstAidSupply;
  return items.any(
    (item) => item.cabinetSection == section && item.itemKind == itemKind,
  );
}

class _ReadinessGuideTile extends StatelessWidget {
  const _ReadinessGuideTile({
    required this.label,
    required this.isRegistered,
    required this.onAdd,
  });

  final String label;
  final bool isRegistered;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !isRegistered && onAdd != null,
      label: '$label, ${isRegistered ? '등록됨' : '아직 등록 없음'}',
      child: Material(
        color: isRegistered
            ? MedicalBoxColors.surface
            : MedicalBoxColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isRegistered
                ? MedicalBoxColors.official
                : MedicalBoxColors.rail,
          ),
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
        child: InkWell(
          onTap: isRegistered ? null : onAdd,
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        isRegistered
                            ? PhosphorIconsRegular.checkCircle
                            : PhosphorIconsRegular.plusCircle,
                        color: isRegistered
                            ? MedicalBoxColors.official
                            : MedicalBoxColors.faint,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isRegistered ? '등록됨' : '비어 있음',
                          style: TextStyle(
                            color: isRegistered
                                ? MedicalBoxColors.official
                                : MedicalBoxColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MedicalBoxColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _ReadinessGuideFootnote extends StatelessWidget {
  const _ReadinessGuideFootnote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Text(
        '보건복지부와 공공 보건기관의 가정용 준비 항목 참고 · 필수 목록이 아니며 가족 상황에 맞게 약사와 확인하세요.',
        style: TextStyle(
          color: MedicalBoxColors.muted,
          fontSize: 10,
          height: 1.45,
        ),
      ),
    );
  }
}

class _CabinetCompartmentRow extends StatelessWidget {
  const _CabinetCompartmentRow({
    required this.label,
    required this.items,
    required this.onItemTap,
  });

  final String label;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final hasReview = items.any(_needsReview);
    final markerColor = hasReview
        ? MedicalBoxColors.accent
        : MedicalBoxColors.official;

    return Semantics(
      container: true,
      label: '$label 칸, 의약품 ${items.length}개',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MedicalBoxColors.surface,
          border: Border.all(color: MedicalBoxColors.rail),
          borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1217191C),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MedicalBoxRadius.group - 1),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: markerColor),
                SizedBox(
                  width: 78,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: MedicalBoxColors.rail),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MedicalBoxColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PhosphorIcon(
                            _sectionIcon(label),
                            color: markerColor,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _CabinetMedicineRow(
                          item: items[index],
                          onTap: () => onItemTap(items[index]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CabinetMedicineRow extends StatelessWidget {
  const _CabinetMedicineRow({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsReview = _needsReview(item);
    return Semantics(
      button: true,
      label: '${item.productName}, 상세 보기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  OfficialMedicineThumbnail(
                    imageUrl: item.officialImageUrl,
                    imageBytes: item.capturedImageBytes,
                    fallbackIcon:
                        item.itemKind == InventoryItemKinds.firstAidSupply
                        ? PhosphorIconsRegular.firstAidKit
                        : PhosphorIconsRegular.pill,
                    size: 40,
                    borderRadius: MedicalBoxRadius.marker,
                    backgroundColor: MedicalBoxColors.surfaceRaised,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          needsReview ? '확인 필요' : '상태 양호',
                          style: TextStyle(
                            color: needsReview
                                ? MedicalBoxColors.accent
                                : MedicalBoxColors.official,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PhosphorIcon(
                    PhosphorIconsRegular.caretRight,
                    color: MedicalBoxColors.muted,
                    size: 16,
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

bool _needsReview(InventoryItem item) {
  return item.expiresOn != null &&
      item.expiresOn!.isBefore(DateTime.now().add(const Duration(days: 60)));
}

IconData _sectionIcon(String label) {
  if (label.contains('해열') || label.contains('통증')) {
    return PhosphorIconsRegular.warning;
  }
  if (label.contains('소화')) {
    return PhosphorIconsRegular.pill;
  }
  if (label.contains('상처')) {
    return PhosphorIconsRegular.firstAidKit;
  }
  return PhosphorIconsRegular.tray;
}
