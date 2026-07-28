import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/auth/auth_repository.dart';
import 'package:medical_box/data/auth/social_auth_gateway.dart';
import 'package:medical_box/data/local/database_key_store.dart';

void main() {
  test('sign-in requires explicit current terms acceptance', () async {
    final harness = _TestHarness();

    await expectLater(
      harness.repository.signIn(LoginProvider.google, termsAccepted: false),
      throwsA(isA<StateError>()),
    );

    expect(harness.events, isEmpty);
    expect(harness.exchangeBodies, isEmpty);
    expect(harness.keyStore.tokens, isEmpty);
  });

  test('sign-in submits the exact accepted terms version', () async {
    final harness = _TestHarness();

    await harness.repository.signIn(LoginProvider.google, termsAccepted: true);

    expect(harness.exchangeBodies.single, containsPair('termsAccepted', true));
    expect(
      harness.exchangeBodies.single,
      containsPair('termsVersion', currentTermsVersion),
    );
  });

  for (final provider in [LoginProvider.google, LoginProvider.kakao]) {
    test(
      '${provider.apiName} deletion removes server and local sessions before provider cleanup',
      () async {
        final harness = _TestHarness();
        harness.seedSession();

        final result = await harness.repository.deleteAccount(provider);

        expect(harness.events, [
          'provider:${provider.apiName}:authenticate:reauth',
          'server:${provider.apiName}:reauth',
          'server:delete',
          'local:clear',
          'provider:${provider.apiName}:disconnect',
        ]);
        expect(harness.deleteBodies.single, {'reauthGrant': 'reauth-grant'});
        expect(harness.keyStore.tokens, isEmpty);
        expect(result.providerCleanupCompleted, isTrue);
      },
    );
  }

  test('Apple deletion sends the authorization code to the server', () async {
    final harness = _TestHarness();
    harness.seedSession();

    await harness.repository.deleteAccount(LoginProvider.apple);

    expect(harness.events, [
      'provider:apple:authenticate:reauth',
      'server:apple:reauth',
      'server:delete',
      'local:clear',
    ]);
    expect(harness.deleteBodies.single, {
      'reauthGrant': 'reauth-grant',
      'appleAuthorizationCode': 'fresh-apple-code',
    });
    expect(harness.keyStore.tokens, isEmpty);
  });

  test(
    'missing Apple authorization code fails before server mutation',
    () async {
      final harness = _TestHarness(
        proofs: {
          LoginProvider.apple: const ProviderProof(idToken: 'apple-id-token'),
        },
      );
      harness.seedSession();

      await expectLater(
        harness.repository.deleteAccount(LoginProvider.apple),
        throwsA(isA<StateError>()),
      );

      expect(harness.events, ['provider:apple:authenticate:reauth']);
      expect(harness.deleteBodies, isEmpty);
      expect(harness.keyStore.tokens, {
        'access': 'access-token',
        'refresh': 'refresh-token',
      });
    },
  );

  test(
    'provider cleanup failure preserves completed server deletion',
    () async {
      final harness = _TestHarness(disconnectFailureFor: LoginProvider.kakao);
      harness.seedSession();

      final result = await harness.repository.deleteAccount(
        LoginProvider.kakao,
      );

      expect(harness.events, [
        'provider:kakao:authenticate:reauth',
        'server:kakao:reauth',
        'server:delete',
        'local:clear',
        'provider:kakao:disconnect',
      ]);
      expect(harness.deleteBodies, hasLength(1));
      expect(harness.keyStore.tokens, isEmpty);
      expect(result.requiresProviderCleanupAttention, isTrue);
    },
  );

  test('server deletion failure preserves the app session', () async {
    final harness = _TestHarness(serverDeleteFailure: true);
    harness.seedSession();

    await expectLater(
      harness.repository.deleteAccount(LoginProvider.google),
      throwsA(isA<ApiException>()),
    );

    expect(harness.events, [
      'provider:google:authenticate:reauth',
      'server:google:reauth',
      'server:delete',
    ]);
    expect(harness.keyStore.tokens, {
      'access': 'access-token',
      'refresh': 'refresh-token',
    });
  });

  test(
    'local clear failure preserves the successful server deletion result',
    () async {
      final harness = _TestHarness(localClearFailure: true);
      harness.seedSession();

      final result = await harness.repository.deleteAccount(
        LoginProvider.google,
      );

      expect(harness.events, [
        'provider:google:authenticate:reauth',
        'server:google:reauth',
        'server:delete',
        'local:clear',
        'provider:google:disconnect',
      ]);
      expect(result.requiresLocalSessionCleanupAttention, isTrue);
      expect(result.providerCleanupCompleted, isTrue);
      expect(harness.deleteBodies, hasLength(1));
    },
  );

  test('server reauthentication failure preserves the app session', () async {
    final harness = _TestHarness(serverReauthFailure: true);
    harness.seedSession();

    await expectLater(
      harness.repository.deleteAccount(LoginProvider.google),
      throwsA(isA<ApiException>()),
    );

    expect(harness.events, [
      'provider:google:authenticate:reauth',
      'server:google:reauth',
    ]);
    expect(harness.deleteBodies, isEmpty);
    expect(harness.keyStore.tokens, {
      'access': 'access-token',
      'refresh': 'refresh-token',
    });
  });

  test('logout is best-effort and never disconnects the provider', () async {
    final harness = _TestHarness(
      serverLogoutFailure: true,
      logoutFailureFor: LoginProvider.kakao,
    );
    await harness.repository.signIn(LoginProvider.kakao, termsAccepted: true);
    harness.events.clear();

    await harness.repository.signOut();

    expect(harness.events, [
      'local:clear',
      'server:logout',
      'provider:kakao:logout',
    ]);
    expect(
      harness.events.where((event) => event.contains('disconnect')),
      isEmpty,
    );
    expect(harness.keyStore.tokens, isEmpty);
    expect(harness.repository.account, isNull);
  });

  test('a late restore cannot resurrect an account after sign-out', () async {
    final pendingMe = Completer<http.Response>();
    final harness = _TestHarness(pendingMeResponse: pendingMe);
    harness.seedSession();

    final restore = harness.repository.restore();
    await harness.meRequestStarted.future;
    await harness.repository.signOut();
    pendingMe.complete(
      http.Response(
        jsonEncode({
          'id': 'stale-account',
          'providers': ['google'],
          'permissions': <String>[],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await restore;

    expect(harness.repository.account, isNull);
    expect(harness.keyStore.tokens, isEmpty);
  });

  test('a late refresh cannot rewrite tokens after sign-out', () async {
    final pendingRefresh = Completer<http.Response>();
    final harness = _TestHarness(pendingRefreshResponse: pendingRefresh);
    harness.seedSession();

    final refresh = harness.repository.refreshAccessToken();
    await harness.refreshRequestStarted.future;
    await harness.repository.signOut();
    pendingRefresh.complete(
      http.Response(
        jsonEncode({
          'accessToken': 'late-access',
          'refreshToken': 'late-refresh',
          'account': {
            'id': 'stale-account',
            'providers': ['google'],
            'permissions': <String>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(await refresh, isNull);
    expect(harness.repository.account, isNull);
    expect(harness.keyStore.tokens, isEmpty);
  });
}

class _TestHarness {
  _TestHarness({
    Map<LoginProvider, ProviderProof>? proofs,
    this.disconnectFailureFor,
    this.logoutFailureFor,
    this.serverReauthFailure = false,
    this.serverDeleteFailure = false,
    this.serverLogoutFailure = false,
    this.pendingMeResponse,
    this.pendingRefreshResponse,
    this.localClearFailure = false,
  }) {
    gateway = _RecordingSocialAuthGateway(
      events,
      proofs:
          proofs ??
          {
            LoginProvider.google: const ProviderProof(
              idToken: 'google-id-token',
            ),
            LoginProvider.kakao: const ProviderProof(idToken: 'kakao-id-token'),
            LoginProvider.apple: const ProviderProof(
              idToken: 'apple-id-token',
              authorizationCode: 'fresh-apple-code',
            ),
          },
      disconnectFailureFor: disconnectFailureFor,
      logoutFailureFor: logoutFailureFor,
    );
    keyStore = _RecordingKeyStore(events, clearFailure: localClearFailure);
    repository = AuthRepository(
      ApiClient(
        client: MockClient(_handleRequest),
        baseUrl: 'https://medicalbox.example/api',
      ),
      keyStore,
      socialAuthGateway: gateway,
    );
  }

  final events = <String>[];
  final deleteBodies = <Map<String, dynamic>>[];
  final exchangeBodies = <Map<String, dynamic>>[];
  final LoginProvider? disconnectFailureFor;
  final LoginProvider? logoutFailureFor;
  final bool serverReauthFailure;
  final bool serverDeleteFailure;
  final bool serverLogoutFailure;
  final Completer<http.Response>? pendingMeResponse;
  final Completer<http.Response>? pendingRefreshResponse;
  final bool localClearFailure;
  final meRequestStarted = Completer<void>();
  final refreshRequestStarted = Completer<void>();
  late final _RecordingSocialAuthGateway gateway;
  late final _RecordingKeyStore keyStore;
  late final AuthRepository repository;

  void seedSession() {
    keyStore.tokens.addAll({
      'access': 'access-token',
      'refresh': 'refresh-token',
    });
  }

  Future<http.Response> _handleRequest(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'GET' && path.endsWith('/v1/me')) {
      events.add('server:me');
      if (!meRequestStarted.isCompleted) meRequestStarted.complete();
      final pending = pendingMeResponse;
      if (pending != null) return pending.future;
      return http.Response(
        jsonEncode({
          'id': 'account-id',
          'providers': ['google'],
          'permissions': <String>[],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.method == 'POST' && path.endsWith('/auth/refresh')) {
      events.add('server:refresh');
      if (!refreshRequestStarted.isCompleted) {
        refreshRequestStarted.complete();
      }
      final pending = pendingRefreshResponse;
      if (pending != null) return pending.future;
      return http.Response(
        jsonEncode({
          'accessToken': 'replacement-access',
          'refreshToken': 'replacement-refresh',
          'account': {
            'id': 'account-id',
            'providers': ['google'],
            'permissions': <String>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.method == 'POST' && path.contains('/auth/reauth/')) {
      final provider = path.split('/').last;
      events.add('server:$provider:reauth');
      return serverReauthFailure
          ? http.Response(
              jsonEncode({'detail': 'Reauthentication failed.'}),
              500,
            )
          : http.Response(
              jsonEncode({'grant': 'reauth-grant'}),
              200,
              headers: {'content-type': 'application/json'},
            );
    }
    if (request.method == 'DELETE' && path.endsWith('/v1/me')) {
      events.add('server:delete');
      deleteBodies.add(
        (jsonDecode(request.body) as Map).cast<String, dynamic>(),
      );
      return serverDeleteFailure
          ? http.Response(jsonEncode({'detail': 'Deletion failed.'}), 500)
          : http.Response('', 204);
    }
    if (request.method == 'POST' && path.endsWith('/auth/logout')) {
      events.add('server:logout');
      if (serverLogoutFailure) {
        throw http.ClientException('Network unavailable.');
      }
      return http.Response('', 204);
    }
    if (request.method == 'POST' && path.contains('/auth/exchange/')) {
      final provider = path.split('/').last;
      events.add('server:$provider:exchange');
      exchangeBodies.add(
        (jsonDecode(request.body) as Map).cast<String, dynamic>(),
      );
      return http.Response(
        jsonEncode({
          'accessToken': 'signed-in-access',
          'refreshToken': 'signed-in-refresh',
          'account': {
            'id': 'account-id',
            'providers': [provider],
            'permissions': <String>[],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    fail('Unexpected request: ${request.method} $path');
  }
}

class _RecordingSocialAuthGateway implements SocialAuthGateway {
  _RecordingSocialAuthGateway(
    this.events, {
    required this.proofs,
    this.disconnectFailureFor,
    this.logoutFailureFor,
  });

  final List<String> events;
  final Map<LoginProvider, ProviderProof> proofs;
  final LoginProvider? disconnectFailureFor;
  final LoginProvider? logoutFailureFor;

  @override
  bool supportsProvider(LoginProvider provider) => true;

  @override
  Future<ProviderProof> authenticate(
    LoginProvider provider, {
    required bool forceReauthentication,
  }) async {
    events.add(
      'provider:${provider.apiName}:authenticate:'
      '${forceReauthentication ? 'reauth' : 'sign-in'}',
    );
    final proof = proofs[provider];
    if (proof == null) {
      throw StateError('No proof configured for ${provider.apiName}.');
    }
    return proof;
  }

  @override
  Future<void> disconnect(LoginProvider provider) async {
    events.add('provider:${provider.apiName}:disconnect');
    if (provider == disconnectFailureFor) {
      throw StateError('Provider disconnect failed.');
    }
  }

  @override
  Future<void> logout(LoginProvider provider) async {
    events.add('provider:${provider.apiName}:logout');
    if (provider == logoutFailureFor) {
      throw StateError('Provider logout failed.');
    }
  }
}

class _RecordingKeyStore extends DatabaseKeyStore {
  _RecordingKeyStore(this.events, {this.clearFailure = false});

  final List<String> events;
  final bool clearFailure;
  final tokens = <String, String>{};

  @override
  Future<String?> readToken(String name) async => tokens[name];

  @override
  Future<void> writeToken(String name, String value) async {
    tokens[name] = value;
  }

  @override
  Future<void> clearTokens() async {
    events.add('local:clear');
    if (clearFailure) {
      throw StateError('Secure storage clear failed.');
    }
    tokens.clear();
  }
}
