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
      '/reminders' => 1,
      '/settings' => 2,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: MedicalBoxColors.rail)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (selected) {
            context.go(switch (selected) {
              1 => '/reminders',
              2 => '/settings',
              _ => '/',
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.firstAidKit),
              selectedIcon: Icon(
                PhosphorIconsRegular.firstAidKit,
                color: MedicalBoxColors.accent,
              ),
              label: '약장',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.bell),
              selectedIcon: Icon(
                PhosphorIconsRegular.bell,
                color: MedicalBoxColors.accent,
              ),
              label: '알림',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.gear),
              selectedIcon: Icon(
                PhosphorIconsRegular.gear,
                color: MedicalBoxColors.accent,
              ),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
