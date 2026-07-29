import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../providers.dart';
import '../../theme.dart';

class SessionGateScreen extends ConsumerStatefulWidget {
  const SessionGateScreen({super.key});

  @override
  ConsumerState<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends ConsumerState<SessionGateScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_resolve);
  }

  Future<void> _resolve() async {
    final settings = await ref.read(databaseProvider).getSettings();
    if (!mounted) return;
    if (!settings.onboardingCompleted) {
      context.go('/onboarding');
      return;
    }

    try {
      final account = await ref.read(authSessionProvider.future);
      if (!mounted) return;
      context.go(account == null ? '/login' : '/');
    } catch (_) {
      if (mounted) context.go('/login?restoreFailed=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.sky,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsDuotone.firstAidKit,
                    size: 38,
                    color: MedicalBoxColors.skyDeep,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '안전하게 보관함을 여는 중',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '이 기기의 로그인 상태를 확인하고 있어요.',
                  style: TextStyle(color: MedicalBoxColors.muted),
                ),
                const SizedBox(height: 22),
                const CircularProgressIndicator(strokeWidth: 2.5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
