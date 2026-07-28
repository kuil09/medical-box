import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/app_links.dart';

void main() {
  const expectedRedirects = <String, String>{
    '/app': '/',
    '/app/inventory': '/inventory',
    '/app/reminders': '/reminders',
    '/app/settings': '/settings',
    '/app/login': '/login',
  };

  test('only supported app routes are associated with the domain', () {
    expect(appLinkRedirects, expectedRedirects);
    expect(appLinkRedirects, isNot(contains('/privacy')));
    expect(appLinkRedirects, isNot(contains('/terms')));
    expect(appLinkRedirects, isNot(contains('/support')));
    expect(appLinkRedirects, isNot(contains('/account-deletion')));
  });

  test('local-data routes cannot bypass incomplete onboarding', () {
    for (final path in [
      '/',
      '/inventory',
      '/reminders',
      '/settings',
      '/app',
      '/app/inventory',
    ]) {
      expect(
        onboardingGuardRedirect(path: path, onboardingCompleted: false),
        '/onboarding',
      );
    }
    expect(
      onboardingGuardRedirect(path: '/onboarding', onboardingCompleted: false),
      isNull,
    );
    expect(
      onboardingGuardRedirect(path: '/login', onboardingCompleted: false),
      isNull,
    );
    expect(
      onboardingGuardRedirect(path: '/inventory', onboardingCompleted: true),
      isNull,
    );
  });

  test('Android verified-link paths match the Flutter route boundary', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final configuredPaths = RegExp(
      r'android:path="([^"]+)"',
    ).allMatches(manifest).map((match) => match.group(1)!).toSet();

    expect(configuredPaths, expectedRedirects.keys.toSet());
    expect(manifest, isNot(contains('android:pathPrefix="/')));
  });
}
