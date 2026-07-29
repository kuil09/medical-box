import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme.dart';

class CabinetSectionLabel extends StatelessWidget {
  const CabinetSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class CabinetSectionList extends StatelessWidget {
  const CabinetSectionList({
    required this.children,
    this.showDividers = true,
    super.key,
  });

  final List<Widget> children;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (showDividers && index > 0) {
        rows.add(const Divider(indent: 16, endIndent: 16));
      }
      rows.add(children[index]);
    }
    return Material(
      color: MedicalBoxColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        side: const BorderSide(color: MedicalBoxColors.rail),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class OfficialSourceLabel extends StatelessWidget {
  const OfficialSourceLabel({this.connected = true, super.key});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: connected ? '공식 정보 연결됨' : '공식 정보',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: connected
              ? MedicalBoxColors.officialSoft
              : MedicalBoxColors.surface,
          border: Border.all(color: MedicalBoxColors.official),
          borderRadius: BorderRadius.circular(MedicalBoxRadius.marker),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                connected
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.info,
                size: 13,
                color: MedicalBoxColors.official,
              ),
              const SizedBox(width: 4),
              Text(
                connected ? '공식 정보' : '공식 정보 없음',
                style: const TextStyle(
                  color: MedicalBoxColors.official,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CabinetReviewRow extends StatelessWidget {
  const CabinetReviewRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MedicalBoxColors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        side: const BorderSide(color: MedicalBoxColors.rail),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 64,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const PhosphorIcon(
          PhosphorIconsRegular.warning,
          color: MedicalBoxColors.accent,
          size: 22,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const PhosphorIcon(PhosphorIconsRegular.caretRight, size: 18),
        onTap: onTap,
      ),
    );
  }
}
