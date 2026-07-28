import 'dart:io';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../local/database_key_store.dart';
import 'login_provider.dart';
import 'social_auth_gateway.dart';

export 'login_provider.dart';

const currentTermsVersion = '2026-07-25';

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.providers,
    required this.permissions,
    this.displayName,
    this.email,
  });

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: json['id'] as String,
      providers: (json['providers'] as List? ?? const []).cast<String>(),
      permissions: (json['permissions'] as List? ?? const []).cast<String>(),
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
    );
  }

  final String id;
  final List<String> providers;
  final List<String> permissions;
  final String? displayName;
  final String? email;

  bool get canReadCatalog => permissions.contains('catalog:read');
}

class AuthRepository {
  AuthRepository(
    this._api,
    this._keyStore, {
    TargetPlatform? targetPlatform,
    SocialAuthGateway? socialAuthGateway,
  }) : _socialAuthGateway =
           socialAuthGateway ??
           SdkSocialAuthGateway(targetPlatform: targetPlatform);

  final ApiClient _api;
  final DatabaseKeyStore _keyStore;
  final SocialAuthGateway _socialAuthGateway;
  AccountProfile? _account;
  Future<String?>? _refreshInFlight;

  AccountProfile? get account => _account;

  bool supportsProvider(LoginProvider provider) {
    return _socialAuthGateway.supportsProvider(provider);
  }

  Future<String?> accessToken() => _keyStore.readToken('access');

  Future<String?> refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final operation = _refreshAccessTokenOnce();
    _refreshInFlight = operation;
    return operation;
  }

  Future<String?> _refreshAccessTokenOnce() async {
    try {
      await _refresh();
      return _keyStore.readToken('access');
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<AccountProfile> signIn(
    LoginProvider provider, {
    required bool termsAccepted,
  }) async {
    if (!termsAccepted) {
      throw StateError('The current terms must be accepted before sign-in.');
    }
    final proof = await _socialAuthGateway.authenticate(
      provider,
      forceReauthentication: false,
    );
    final response = await _api.postJson(
      '/v1/auth/exchange/${provider.apiName}',
      body: {
        'providerToken': proof.idToken,
        'termsVersion': currentTermsVersion,
        'termsAccepted': true,
        'deviceLabel': Platform.operatingSystem,
      },
    );
    final accessToken = response['accessToken'];
    final refreshToken = response['refreshToken'];
    final account = response['account'];
    if (accessToken is! String || refreshToken is! String || account is! Map) {
      throw const FormatException('Invalid authentication response.');
    }
    await _keyStore.writeToken('access', accessToken);
    await _keyStore.writeToken('refresh', refreshToken);
    _account = AccountProfile.fromJson(account.cast<String, dynamic>());
    return _account!;
  }

  Future<void> restore() async {
    final accessToken = await _keyStore.readToken('access');
    if (accessToken == null) return;
    try {
      final profile = await _api.getJson('/v1/me', accessToken: accessToken);
      _account = AccountProfile.fromJson(profile);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _refresh();
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    final linkedProviders = _linkedProviders();
    final refreshToken = await _keyStore.readToken('refresh');
    if (refreshToken != null) {
      try {
        await _api.postJson(
          '/v1/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // Local sign-out must remain available when the network is unavailable.
      }
    }
    for (final provider in linkedProviders) {
      try {
        await _socialAuthGateway.logout(provider);
      } catch (_) {
        // Provider logout is best-effort and must never become an unlink.
      }
    }
    await _keyStore.clearTokens();
    _account = null;
  }

  Future<void> deleteAccount(LoginProvider provider) async {
    final accessToken = await _requiredAccessToken();
    final proof = await _socialAuthGateway.authenticate(
      provider,
      forceReauthentication: true,
    );
    final authorizationCode = proof.authorizationCode;
    if (provider == LoginProvider.apple &&
        (authorizationCode == null || authorizationCode.isEmpty)) {
      throw StateError('Apple did not return an authorization code.');
    }
    final response = await _api.postJson(
      '/v1/auth/reauth/${provider.apiName}',
      accessToken: accessToken,
      body: {'providerToken': proof.idToken},
    );
    final grant = response['grant'];
    if (grant is! String) {
      throw const FormatException('Missing reauthentication grant.');
    }
    if (provider != LoginProvider.apple) {
      // Keep the server account recoverable when provider cleanup fails.
      await _socialAuthGateway.disconnect(provider);
    }
    await _api.deleteJson(
      '/v1/me',
      accessToken: accessToken,
      body: {
        'reauthGrant': grant,
        if (provider == LoginProvider.apple)
          'appleAuthorizationCode': authorizationCode,
      },
    );
    await _keyStore.clearTokens();
    _account = null;
  }

  Future<void> _refresh() async {
    final refreshToken = await _keyStore.readToken('refresh');
    if (refreshToken == null) return;
    late final Map<String, dynamic> response;
    try {
      response = await _api.postJson(
        '/v1/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _keyStore.clearTokens();
        _account = null;
      }
      rethrow;
    }
    final accessToken = response['accessToken'];
    final replacement = response['refreshToken'];
    final account = response['account'];
    if (accessToken is! String || replacement is! String || account is! Map) {
      throw const FormatException('Invalid refresh response.');
    }
    await _keyStore.writeToken('access', accessToken);
    await _keyStore.writeToken('refresh', replacement);
    _account = AccountProfile.fromJson(account.cast<String, dynamic>());
  }

  Future<String> _requiredAccessToken() async {
    final token = await _keyStore.readToken('access');
    if (token == null) throw StateError('No authenticated session.');
    return token;
  }

  Set<LoginProvider> _linkedProviders() {
    final providerNames = _account?.providers.toSet();
    if (providerNames == null || providerNames.isEmpty) {
      return {LoginProvider.google, LoginProvider.kakao};
    }
    return LoginProvider.values
        .where((provider) => providerNames.contains(provider.apiName))
        .toSet();
  }
}
