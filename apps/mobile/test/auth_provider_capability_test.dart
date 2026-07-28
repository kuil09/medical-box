import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/auth/auth_repository.dart';
import 'package:medical_box/data/local/database_key_store.dart';
import 'package:medical_box/features/auth/login_screen.dart';
import 'package:medical_box/providers.dart';

void main() {
  group('login provider platform support', () {
    test('Apple remains available on iOS', () {
      expect(
        isLoginProviderSupported(LoginProvider.apple, TargetPlatform.iOS),
        isTrue,
      );
    });

    test('Apple is unavailable on Android without a Service ID web flow', () {
      expect(
        isLoginProviderSupported(LoginProvider.apple, TargetPlatform.android),
        isFalse,
      );
    });

    test('Google and Kakao remain available on both mobile platforms', () {
      for (final provider in [LoginProvider.google, LoginProvider.kakao]) {
        expect(isLoginProviderSupported(provider, TargetPlatform.iOS), isTrue);
        expect(
          isLoginProviderSupported(provider, TargetPlatform.android),
          isTrue,
        );
      }
    });
  });

  test('Android rejects Apple before provider or API invocation', () async {
    var networkInvoked = false;
    final repository = AuthRepository(
      ApiClient(
        client: MockClient((_) async {
          networkInvoked = true;
          return http.Response('{}', 200);
        }),
        baseUrl: 'https://medicalbox.example/api',
      ),
      DatabaseKeyStore(),
      targetPlatform: TargetPlatform.android,
    );

    await expectLater(
      repository.signIn(LoginProvider.apple),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('apple sign-in is not supported on android'),
        ),
      ),
    );
    expect(networkInvoked, isFalse);
  });

  testWidgets('Android does not offer Apple sign-in', (tester) async {
    await tester.pumpWidget(_loginApp(targetPlatform: TargetPlatform.android));
    await tester.pump();

    expect(find.text('Apple로 계속'), findsNothing);
    expect(find.text('Google로 계속'), findsOneWidget);
    expect(find.text('카카오로 계속'), findsOneWidget);
  });

  testWidgets('iOS continues to offer Apple sign-in', (tester) async {
    await tester.pumpWidget(_loginApp(targetPlatform: TargetPlatform.iOS));
    await tester.pump();

    expect(find.text('Apple로 계속'), findsOneWidget);
  });
}

Widget _loginApp({required TargetPlatform targetPlatform}) {
  final repository = AuthRepository(
    ApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'https://medicalbox.example/api',
    ),
    DatabaseKeyStore(),
    targetPlatform: targetPlatform,
  );
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authSessionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}
