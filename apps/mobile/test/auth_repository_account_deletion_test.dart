import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medical_box/data/api/api_client.dart';
import 'package:medical_box/data/auth/auth_repository.dart';
import 'package:medical_box/data/auth/social_auth_gateway.dart';
import 'package:medical_box/data/local/database_key_store.dart';

void main() {
  for (final provider in [LoginProvider.google, LoginProvider.kakao]) {
    test(
      '${provider.apiName} deletion reauthenticates, disconnects, then deletes',
      () async {
        final harness = _TestHarness();
        harness.seedSession();

        await harness.repository.deleteAccount(provider);

        expect(harness.events, [
          'provider:${provider.apiName}:authenticate:reauth',
          'server:${provider.apiName}:reauth',
          'provider:${provider.apiName}:disconnect',
          'server:delete',
          'local:clear',
        ]);
        expect(harness.deleteBodies.single, {'reauthGrant': 'reauth-grant'});
        expect(harness.keyStore.tokens, isEmpty);
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

  test('provider cleanup failure preserves the app session', () async {
    final harness = _TestHarness(disconnectFailureFor: LoginProvider.kakao);
    harness.seedSession();

    await expectLater(
      harness.repository.deleteAccount(LoginProvider.kakao),
      throwsA(isA<StateError>()),
    );

    expect(harness.events, [
      'provider:kakao:authenticate:reauth',
      'server:kakao:reauth',
      'provider:kakao:disconnect',
    ]);
    expect(harness.deleteBodies, isEmpty);
    expect(harness.keyStore.tokens, {
      'access': 'access-token',
      'refresh': 'refresh-token',
    });
  });

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
      'provider:google:disconnect',
      'server:delete',
    ]);
    expect(harness.keyStore.tokens, {
      'access': 'access-token',
      'refresh': 'refresh-token',
    });
  });

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
    await harness.repository.signIn(LoginProvider.kakao);
    harness.events.clear();

    await harness.repository.signOut();

    expect(harness.events, [
      'server:logout',
      'provider:kakao:logout',
      'local:clear',
    ]);
    expect(
      harness.events.where((event) => event.contains('disconnect')),
      isEmpty,
    );
    expect(harness.keyStore.tokens, isEmpty);
    expect(harness.repository.account, isNull);
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
    keyStore = _RecordingKeyStore(events);
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
  final LoginProvider? disconnectFailureFor;
  final LoginProvider? logoutFailureFor;
  final bool serverReauthFailure;
  final bool serverDeleteFailure;
  final bool serverLogoutFailure;
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
  _RecordingKeyStore(this.events);

  final List<String> events;
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
    tokens.clear();
  }
}
