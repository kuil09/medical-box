import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_links.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/edit_inventory_item_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/pouch/pouch_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/renewal/renewal_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers.dart';
import 'theme.dart';
import 'widgets/app_shell.dart';

class MedicalBoxApp extends ConsumerStatefulWidget {
  const MedicalBoxApp({super.key});

  @override
  ConsumerState<MedicalBoxApp> createState() => _MedicalBoxAppState();
}

class _MedicalBoxAppState extends ConsumerState<MedicalBoxApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final settings = await ref.read(databaseProvider).getSettings();
      return onboardingGuardRedirect(
        path: state.uri.path,
        onboardingCompleted: settings.onboardingCompleted,
      );
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/inventory/new',
        builder: (context, state) => EditInventoryItemScreen(
          containerId: state.uri.queryParameters['containerId'],
        ),
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) =>
            EditInventoryItemScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(path: '/pouch', builder: (context, state) => const PouchScreen()),
      GoRoute(
        path: '/pouch/:containerId',
        builder: (context, state) => PouchDetailScreen(
          containerId: state.pathParameters['containerId']!,
        ),
      ),
      GoRoute(
        path: '/renewal',
        builder: (context, state) => const RenewalScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      for (final entry in appLinkRedirects.entries)
        GoRoute(path: entry.key, redirect: (context, state) => entry.value),
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshReminderState());
    }
  }

  Future<void> _refreshReminderState() async {
    try {
      await ref.read(localDataLifecycleProvider).handleAppResumed();
    } catch (_) {
      // Keep the app usable; the next resume or restart retries reconciliation.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '우리집 구급키트',
      debugShowCheckedModeBanner: false,
      theme: buildMedicalBoxTheme(),
      routerConfig: _router,
    );
  }
}
