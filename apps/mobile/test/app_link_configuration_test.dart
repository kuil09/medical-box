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

  test('onboarding and authentication both gate app routes', () {
    for (final path in [
      '/',
      '/inventory',
      '/reminders',
      '/settings',
      '/app',
      '/app/inventory',
    ]) {
      expect(
        appAccessRedirect(
          path: path,
          onboardingCompleted: false,
          authenticated: false,
        ),
        '/onboarding',
      );
    }
    expect(
      appAccessRedirect(
        path: '/onboarding',
        onboardingCompleted: false,
        authenticated: false,
      ),
      isNull,
    );
    expect(
      appAccessRedirect(
        path: '/login',
        onboardingCompleted: false,
        authenticated: false,
      ),
      '/onboarding',
    );
    expect(
      appAccessRedirect(
        path: '/inventory',
        onboardingCompleted: true,
        authenticated: false,
      ),
      '/login?from=%2Finventory',
    );
    expect(
      appAccessRedirect(
        path: '/inventory',
        onboardingCompleted: true,
        authenticated: true,
      ),
      isNull,
    );
    expect(
      appAccessRedirect(
        path: '/login',
        onboardingCompleted: true,
        authenticated: false,
      ),
      isNull,
    );
  });

  test('post-login locations cannot escape the app route boundary', () {
    expect(safePostLoginLocation('/inventory'), '/inventory');
    expect(
      safePostLoginLocation('/inventory/item/edit'),
      '/inventory/item/edit',
    );
    expect(safePostLoginLocation('//attacker.example'), isNull);
    expect(safePostLoginLocation('https://attacker.example'), isNull);
    expect(safePostLoginLocation('/login'), isNull);
    expect(safePostLoginLocation('/onboarding'), isNull);
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
