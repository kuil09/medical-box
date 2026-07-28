import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/auth/auth_repository.dart';
import 'package:medical_box/data/auth/social_auth_gateway.dart';
import 'package:medical_box/data/local/database_key_store.dart';
import 'package:medical_box/features/auth/login_screen.dart';
import 'package:medical_box/providers.dart';

void main() {
  group('login provider platform support', () {
    test('Apple is fail-closed on iOS until explicitly enabled', () {
      expect(
        isLoginProviderSupported(LoginProvider.apple, TargetPlatform.iOS),
        isFalse,
      );
      expect(
        isLoginProviderSupported(
          LoginProvider.apple,
          TargetPlatform.iOS,
          appleSignInEnabled: true,
        ),
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

  test('Google forced reauthentication signs out before interactive auth', () {
    final source = File(
      'lib/data/auth/social_auth_gateway.dart',
    ).readAsStringSync();
    final googleCaseStart = source.indexOf('case LoginProvider.google:');
    final appleCaseStart = source.indexOf(
      'case LoginProvider.apple:',
      googleCaseStart,
    );
    final googleCase = source.substring(googleCaseStart, appleCaseStart);
    final forcedBranch = googleCase.indexOf('if (forceReauthentication)');
    final signOut = googleCase.indexOf('await google.signOut()');
    final interactiveAuth = googleCase.indexOf('await google.authenticate(');

    expect(forcedBranch, greaterThanOrEqualTo(0));
    expect(signOut, greaterThan(forcedBranch));
    expect(interactiveAuth, greaterThan(signOut));
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
      repository.signIn(LoginProvider.apple, termsAccepted: true),
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
    final googleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Google로 계속'),
    );
    expect(googleButton.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final enabledGoogleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Google로 계속'),
    );
    expect(enabledGoogleButton.onPressed, isNotNull);
  });

  testWidgets('iOS hides Apple sign-in by default', (tester) async {
    await tester.pumpWidget(_loginApp(targetPlatform: TargetPlatform.iOS));
    await tester.pump();

    expect(find.text('Apple로 계속'), findsNothing);
  });

  testWidgets('iOS offers Apple sign-in only when the flag is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _loginApp(targetPlatform: TargetPlatform.iOS, appleSignInEnabled: true),
    );
    await tester.pump();

    expect(find.text('Apple로 계속'), findsOneWidget);
  });

  testWidgets('restore hides sign-in controls until the session resolves', (
    tester,
  ) async {
    final pendingSession = Completer<AccountProfile?>();
    await tester.pumpWidget(
      _loginApp(
        targetPlatform: TargetPlatform.android,
        session: pendingSession.future,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Google로 계속'), findsNothing);

    pendingSession.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Google로 계속'), findsOneWidget);
  });

  testWidgets('a restored account only shows account management controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _loginApp(
        targetPlatform: TargetPlatform.android,
        session: Future<AccountProfile?>.value(_account),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('서버 계정 삭제'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Google로 계속'), findsNothing);
  });

  testWidgets('sign-out resets terms acceptance before another sign-in', (
    tester,
  ) async {
    final keyStore = _MemoryKeyStore();
    final repository = AuthRepository(
      ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/v1/auth/exchange/google')) {
            return _jsonResponse(
              '{"accessToken":"access","refreshToken":"refresh",'
              '"account":$_accountJson}',
            );
          }
          if (request.url.path.endsWith('/v1/me')) {
            return _jsonResponse(_accountJson);
          }
          if (request.url.path.endsWith('/v1/auth/logout')) {
            return _jsonResponse('{}');
          }
          return _jsonResponse('{}', statusCode: 404);
        }),
        baseUrl: 'https://medicalbox.example/api',
      ),
      keyStore,
      socialAuthGateway: _GoogleGateway(),
    );
    await tester.pumpWidget(_loginApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Google로 계속'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    final googleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Google로 계속'),
    );
    expect(checkbox.value, isFalse);
    expect(googleButton.onPressed, isNull);
  });
}

Widget _loginApp({
  TargetPlatform targetPlatform = TargetPlatform.android,
  bool appleSignInEnabled = false,
  Future<AccountProfile?>? session,
  AuthRepository? repository,
}) {
  final resolvedRepository =
      repository ??
      AuthRepository(
        ApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          baseUrl: 'https://medicalbox.example/api',
        ),
        DatabaseKeyStore(),
        targetPlatform: targetPlatform,
        appleSignInEnabled: appleSignInEnabled,
      );
  final overrides = [
    authRepositoryProvider.overrideWithValue(resolvedRepository),
    if (session != null)
      authSessionProvider.overrideWith((ref) => session)
    else if (repository == null)
      authSessionProvider.overrideWith((ref) async => null),
  ];
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: LoginScreen()),
  );
}

const _account = AccountProfile(
  id: 'account-id',
  providers: ['google'],
  permissions: ['catalog:read'],
  displayName: 'Test User',
  email: 'test@example.com',
);

const _accountJson =
    '{"id":"account-id","providers":["google"],'
    '"permissions":["catalog:read"],"displayName":"Test User",'
    '"email":"test@example.com"}';

http.Response _jsonResponse(String body, {int statusCode = 200}) {
  return http.Response(
    body,
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

class _MemoryKeyStore extends DatabaseKeyStore {
  final Map<String, String> _tokens = {};

  @override
  Future<void> writeToken(String name, String value) async {
    _tokens[name] = value;
  }

  @override
  Future<String?> readToken(String name) async => _tokens[name];

  @override
  Future<void> clearTokens() async {
    _tokens.clear();
  }
}

class _GoogleGateway implements SocialAuthGateway {
  @override
  bool supportsProvider(LoginProvider provider) {
    return provider == LoginProvider.google;
  }

  @override
  Future<ProviderProof> authenticate(
    LoginProvider provider, {
    required bool forceReauthentication,
  }) async {
    return const ProviderProof(idToken: 'provider-proof');
  }

  @override
  Future<void> disconnect(LoginProvider provider) async {}

  @override
  Future<void> logout(LoginProvider provider) async {}
}
