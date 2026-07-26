import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = switch (location) {
      '/inventory' => 1,
      '/reminders' => 2,
      '/settings' => 3,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: MedicalBoxColors.paper,
        indicatorColor: MedicalBoxColors.sky,
        onDestinationSelected: (selected) {
          context.go(switch (selected) {
            1 => '/inventory',
            2 => '/reminders',
            3 => '/settings',
            _ => '/',
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.house),
            selectedIcon: Icon(PhosphorIconsFill.house),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.firstAidKit),
            selectedIcon: Icon(PhosphorIconsFill.firstAidKit),
            label: '보유약',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.bell),
            selectedIcon: Icon(PhosphorIconsFill.bell),
            label: '알림',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.gear),
            selectedIcon: Icon(PhosphorIconsFill.gear),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
