import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _working = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final settings = await ref.read(databaseProvider).getSettings();
      if (settings.onboardingCompleted && mounted) context.go('/');
    });
  }

  Future<void> _continueAnonymously() async {
    setState(() => _working = true);
    final database = ref.read(databaseProvider);
    if ((await database.select(database.households).get()).isEmpty) {
      const uuid = Uuid();
      final householdId = uuid.v4();
      await database.transaction(() async {
        await database
            .into(database.households)
            .insert(HouseholdsCompanion.insert(id: householdId, name: '우리 집'));
        await database
            .into(database.inventoryContainers)
            .insert(
              InventoryContainersCompanion.insert(
                id: uuid.v4(),
                householdId: householdId,
                name: '공용 트레이',
                kind: 'shared',
                sortOrder: const Value(0),
              ),
            );
      });
    }
    await database.setOnboardingCompleted();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: MedicalBoxColors.sky,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '기기 안에서만',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '우리 집 약을,\n꺼내 보기 쉽게.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 14),
              const Text(
                '가족과 보유약 정보는 이 기기의 암호화된 보관함에만 저장돼요. 보관함은 로그인 없이 쓸 수 있고, 공식 의약품 검색은 승인된 로그인이 필요해요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: MedicalBoxColors.muted,
                ),
              ),
              const SizedBox(height: 28),
              const Expanded(child: _InteractiveTrayPreview()),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _working ? null : _continueAnonymously,
                child: Text(_working ? '보관함 여는 중…' : '로그인 없이 시작'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('의약품 검색을 위해 로그인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveTrayPreview extends StatefulWidget {
  const _InteractiveTrayPreview();

  @override
  State<_InteractiveTrayPreview> createState() =>
      _InteractiveTrayPreviewState();
}

class _InteractiveTrayPreviewState extends State<_InteractiveTrayPreview> {
  String _selected = '상처 관리';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E7DB),
        border: Border.all(color: MedicalBoxColors.line),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '의약품 트레이 미리보기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Icon(
                PhosphorIconsRegular.handTap,
                color: MedicalBoxColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _PreviewCompartment(
                  label: '소화',
                  count: 1,
                  icon: PhosphorIconsDuotone.pill,
                  color: const Color(0xFFF9F4EC),
                  selected: _selected == '소화',
                  onTap: () => setState(() => _selected = '소화'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _PreviewCompartment(
                  label: '상처 관리',
                  count: 3,
                  icon: PhosphorIconsDuotone.firstAidKit,
                  color: const Color(0xFFFFD8C8),
                  selected: _selected == '상처 관리',
                  onTap: () => setState(() => _selected = '상처 관리'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _PreviewCompartment(
            label: '기타',
            count: 0,
            icon: PhosphorIconsDuotone.archive,
            color: Colors.white.withValues(alpha: 0.74),
            selected: _selected == '기타',
            onTap: () => setState(() => _selected = '기타'),
            compact: true,
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Container(
              key: ValueKey(_selected),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.shieldCheck,
                    color: MedicalBoxColors.skyDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_selected 수납칸을 선택했어요. 개인 보관 정보는 기기 밖으로 전송하지 않아요.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCompartment extends StatelessWidget {
  const _PreviewCompartment({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final int count;
  final Object icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: compact ? 68 : 102,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? MedicalBoxColors.orange : MedicalBoxColors.line,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, size: compact ? 25 : 30),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '$count개 항목',
                      style: const TextStyle(
                        color: MedicalBoxColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  PhosphorIconsFill.checkCircle,
                  size: 18,
                  color: MedicalBoxColors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
