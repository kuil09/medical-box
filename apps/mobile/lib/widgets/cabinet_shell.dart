import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../data/local/app_database.dart';
import '../theme.dart';
import 'official_medicine_thumbnail.dart';

class CabinetShell extends StatefulWidget {
  const CabinetShell({
    required this.name,
    required this.items,
    required this.onItemTap,
    this.reviewCount = 0,
    super.key,
  });

  final String name;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final int reviewCount;

  @override
  State<CabinetShell> createState() => _CabinetShellState();
}

class _CabinetShellState extends State<CabinetShell> {
  bool _isOpen = false;

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: _isOpen ? 260 : 220);

    return Semantics(
      container: true,
      expanded: _isOpen,
      label: _isOpen
          ? '${widget.name} 열림, 의약품 ${widget.items.length}개'
          : '${widget.name} 닫힘, 의약품 ${widget.items.length}개',
      child: AnimatedSize(
        duration: duration,
        curve: _isOpen ? Curves.easeOut : Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MedicalBoxColors.surface,
            borderRadius: BorderRadius.circular(MedicalBoxRadius.cabinet),
            border: Border.all(color: MedicalBoxColors.railStrong, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A17191C),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MedicalBoxRadius.cabinet - 1),
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: AlignmentDirectional.topStart,
                  child: child,
                ),
              ),
              child: _isOpen
                  ? _OpenCabinet(
                      key: const ValueKey('open'),
                      items: widget.items,
                      onItemTap: widget.onItemTap,
                      onClose: _toggle,
                    )
                  : _ClosedCabinetDoor(
                      key: const ValueKey('closed'),
                      name: widget.name,
                      itemCount: widget.items.length,
                      reviewCount: widget.reviewCount,
                      onOpen: _toggle,
                    ),
            ),
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
    super.key,
  });

  final String name;
  final int itemCount;
  final int reviewCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final summary = reviewCount > 0 ? '확인할 약 $reviewCount개' : '보관약 $itemCount개';
    return SizedBox(
      width: double.infinity,
      height: 212,
      child: Stack(
        children: [
          Positioned.fill(
            left: 34,
            child: Material(
              color: MedicalBoxColors.surfaceRaised,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: MedicalBoxColors.surface,
                            border: Border.all(color: MedicalBoxColors.rail),
                            borderRadius: BorderRadius.circular(
                              MedicalBoxRadius.marker,
                            ),
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsRegular.firstAid,
                            color: MedicalBoxColors.accent,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '필요할 때 열어 의약품을 확인하세요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MedicalBoxColors.muted,
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.info,
                          size: 18,
                          color: MedicalBoxColors.muted,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            summary,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: MedicalBoxColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: onOpen,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(92, 52),
                            backgroundColor: MedicalBoxColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: const PhosphorIcon(
                            PhosphorIconsRegular.caretUp,
                            size: 15,
                          ),
                          label: const Text('열기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 34,
            child: _CabinetHingeRail(),
          ),
        ],
      ),
    );
  }
}

class _CabinetHingeRail extends StatelessWidget {
  const _CabinetHingeRail();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MedicalBoxColors.surface,
        border: Border(right: BorderSide(color: MedicalBoxColors.railStrong)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < 2; index++)
            Container(
              width: 10,
              height: 46,
              decoration: BoxDecoration(
                color: MedicalBoxColors.surfaceContainer,
                border: Border.all(color: MedicalBoxColors.railStrong),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenCabinet extends StatelessWidget {
  const _OpenCabinet({
    required this.items,
    required this.onItemTap,
    required this.onClose,
    super.key,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CabinetInterior(items: items, onItemTap: onItemTap),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: MedicalBoxColors.surfaceRaised,
            border: Border(top: BorderSide(color: MedicalBoxColors.rail)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton.icon(
              onPressed: onClose,
              icon: const PhosphorIcon(PhosphorIconsRegular.caretUp, size: 15),
              label: const Text('닫기'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CabinetInterior extends StatelessWidget {
  const _CabinetInterior({required this.items, required this.onItemTap});

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
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
      );
    }

    final groups = <String, List<InventoryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(_categoryFor(item), () => []).add(item);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: const BoxDecoration(
        color: MedicalBoxColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x1417191C),
            blurRadius: 5,
            offset: Offset(0, 2),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabinetCompartment(
            label: groups.entries.first.key,
            items: groups.entries.first.value,
            onItemTap: onItemTap,
          ),
          if (groups.length > 1) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final secondaryGroups = groups.entries.skip(1).toList();
                final compartmentWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    for (final entry in secondaryGroups)
                      SizedBox(
                        width: compartmentWidth,
                        child: _CabinetCompartment(
                          label: entry.key,
                          items: entry.value,
                          onItemTap: onItemTap,
                          singleColumn: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CabinetCompartment extends StatelessWidget {
  const _CabinetCompartment({
    required this.label,
    required this.items,
    required this.onItemTap,
    this.singleColumn = false,
  });

  final String label;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;
  final bool singleColumn;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label 칸, 의약품 ${items.length}개',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 8),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = singleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tileWidth,
                      child: _CabinetMedicineTile(
                        item: item,
                        onTap: () => onItemTap(item),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CabinetMedicineTile extends StatelessWidget {
  const _CabinetMedicineTile({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsReview =
        item.expiresOn != null &&
        item.expiresOn!.isBefore(DateTime.now().add(const Duration(days: 60)));
    return Semantics(
      button: true,
      label: '${item.productName}, 상세 보기',
      child: Material(
        color: needsReview
            ? MedicalBoxColors.accentSoft
            : MedicalBoxColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
          side: BorderSide(
            color: needsReview
                ? MedicalBoxColors.accent
                : MedicalBoxColors.rail,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  OfficialMedicineThumbnail(
                    imageUrl: item.officialImageUrl,
                    fallbackIcon: PhosphorIconsRegular.pill,
                    size: 36,
                    borderRadius: MedicalBoxRadius.marker,
                    backgroundColor: MedicalBoxColors.surface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (needsReview) ...[
                          const SizedBox(height: 3),
                          const Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsRegular.warning,
                                color: MedicalBoxColors.accent,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '확인 필요',
                                style: TextStyle(
                                  color: MedicalBoxColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

String _categoryFor(InventoryItem item) {
  final source = [
    item.productName,
    item.storageNote ?? '',
    item.privateNote ?? '',
  ].join(' ').toLowerCase();
  if (source.contains('밴드') ||
      source.contains('거즈') ||
      source.contains('소독') ||
      source.contains('상처') ||
      source.contains('연고')) {
    return '상처';
  }
  if (source.contains('소화') ||
      source.contains('위장') ||
      source.contains('제산') ||
      source.contains('정장')) {
    return '소화';
  }
  if (source.contains('해열') ||
      source.contains('진통') ||
      source.contains('타이레놀') ||
      source.contains('아세트아미노펜') ||
      source.contains('이부프로펜')) {
    return '해열·진통';
  }
  return '기타';
}
