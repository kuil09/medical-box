import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../widgets/cabinet_index_components.dart';

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
    Future<void>.microtask(() async {
      final settings = await ref.read(databaseProvider).getSettings();
      if (settings.onboardingCompleted && mounted) context.go('/gate');
    });
  }

  Future<void> _continueToAccount() async {
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
                name: '공용 구급상자',
                kind: 'shared',
                sortOrder: const Value(0),
              ),
            );
      });
    }
    await database.setOnboardingCompleted();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MedicalBoxSpacing.screen,
            MedicalBoxSpacing.x10,
            MedicalBoxSpacing.screen,
            MedicalBoxSpacing.x6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CabinetMark(),
              const SizedBox(height: MedicalBoxSpacing.x8),
              Text(
                '우리집 구급상자를\n시작해요',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: MedicalBoxSpacing.x3),
              const Text(
                '공식 의약품 정보를 연결하고, 집에 있는 약과 보관 위치를 빠르게 확인하세요.',
                style: TextStyle(
                  color: MedicalBoxColors.muted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: MedicalBoxSpacing.x7),
              const CabinetSectionList(
                children: [
                  _OnboardingValue(
                    icon: PhosphorIconsRegular.firstAidKit,
                    title: '약과 보관 위치를 한눈에',
                  ),
                  _OnboardingValue(
                    icon: PhosphorIconsRegular.users,
                    title: '공용 구급상자와 가족별 파우치',
                  ),
                  _OnboardingValue(
                    icon: PhosphorIconsRegular.lockKey,
                    title: '가족과 보유약 정보는 기기에 암호화 저장',
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working ? null : _continueToAccount,
                  child: Text(_working ? '준비하는 중…' : '계정 만들고 시작'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabinetMark extends StatelessWidget {
  const _CabinetMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '우리집 구급상자',
      child: Container(
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: MedicalBoxColors.surfaceContainer,
          border: Border.all(color: MedicalBoxColors.railStrong),
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
        alignment: Alignment.center,
        child: const PhosphorIcon(
          PhosphorIconsRegular.firstAidKit,
          color: MedicalBoxColors.accent,
          size: 28,
        ),
      ),
    );
  }
}

class _OnboardingValue extends StatelessWidget {
  const _OnboardingValue({required this.icon, required this.title});

  final Object icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: PhosphorIcon(icon, size: 22),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
