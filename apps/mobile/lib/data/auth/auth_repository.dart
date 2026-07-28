import 'dart:async';
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

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.provider,
    required this.providerCleanupCompleted,
    required this.localSessionCleanupCompleted,
  });

  final LoginProvider provider;
  final bool providerCleanupCompleted;
  final bool localSessionCleanupCompleted;

  bool get requiresProviderCleanupAttention => !providerCleanupCompleted;
  bool get requiresLocalSessionCleanupAttention =>
      !localSessionCleanupCompleted;
}

class AuthRepository {
  AuthRepository(
    this._api,
    this._keyStore, {
    TargetPlatform? targetPlatform,
    SocialAuthGateway? socialAuthGateway,
    bool? appleSignInEnabled,
  }) : _socialAuthGateway =
           socialAuthGateway ??
           SdkSocialAuthGateway(
             targetPlatform: targetPlatform,
             appleSignInEnabled: appleSignInEnabled,
           );

  final ApiClient _api;
  final DatabaseKeyStore _keyStore;
  final SocialAuthGateway _socialAuthGateway;
  AccountProfile? _account;
  Future<String?>? _refreshInFlight;
  int? _refreshInFlightEpoch;
  Future<void> _sessionMutationTail = Future<void>.value();
  int _sessionEpoch = 0;

  AccountProfile? get account => _account;

  bool supportsProvider(LoginProvider provider) {
    return _socialAuthGateway.supportsProvider(provider);
  }

  Future<String?> accessToken() => _keyStore.readToken('access');

  Future<String?> refreshAccessToken() {
    final epoch = _sessionEpoch;
    final inFlight = _refreshInFlight;
    if (inFlight != null && _refreshInFlightEpoch == epoch) return inFlight;
    late final Future<String?> operation;
    operation = _refreshAccessTokenOnce(epoch).whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
        _refreshInFlightEpoch = null;
      }
    });
    _refreshInFlight = operation;
    _refreshInFlightEpoch = epoch;
    return operation;
  }

  Future<String?> _refreshAccessTokenOnce(int epoch) async {
    final refreshed = await _refresh(epoch);
    if (!refreshed || epoch != _sessionEpoch) return null;
    return _keyStore.readToken('access');
  }

  Future<AccountProfile> signIn(
    LoginProvider provider, {
    required bool termsAccepted,
  }) async {
    if (!termsAccepted) {
      throw StateError('The current terms must be accepted before sign-in.');
    }
    if (_account != null) {
      throw StateError('Sign out before signing in with another account.');
    }
    final epoch = ++_sessionEpoch;
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
    final profile = AccountProfile.fromJson(account.cast<String, dynamic>());
    final committed = await _commitSession(
      epoch: epoch,
      accessToken: accessToken,
      refreshToken: refreshToken,
      account: profile,
    );
    if (!committed) {
      throw StateError('The sign-in operation was superseded.');
    }
    return profile;
  }

  Future<void> restore() async {
    final epoch = _sessionEpoch;
    final accessToken = await _keyStore.readToken('access');
    if (accessToken == null || epoch != _sessionEpoch) return;
    try {
      final profile = await _api.getJson('/v1/me', accessToken: accessToken);
      await _setAccountIfCurrent(epoch, AccountProfile.fromJson(profile));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _refresh(epoch);
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    final linkedProviders = _linkedProviders();
    final refreshToken = await _keyStore.readToken('refresh');
    final epoch = ++_sessionEpoch;
    await _clearSessionIfCurrent(epoch);
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
  }

  Future<AccountDeletionResult> deleteAccount(LoginProvider provider) async {
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
    await _api.deleteJson(
      '/v1/me',
      accessToken: accessToken,
      body: {
        'reauthGrant': grant,
        if (provider == LoginProvider.apple)
          'appleAuthorizationCode': authorizationCode,
      },
    );
    final epoch = ++_sessionEpoch;
    var localSessionCleanupCompleted = true;
    try {
      await _clearSessionIfCurrent(epoch);
    } catch (_) {
      localSessionCleanupCompleted = false;
      _account = null;
    }

    var providerCleanupCompleted = true;
    if (provider != LoginProvider.apple) {
      try {
        await _socialAuthGateway.disconnect(provider);
      } catch (_) {
        providerCleanupCompleted = false;
      }
    }
    return AccountDeletionResult(
      provider: provider,
      providerCleanupCompleted: providerCleanupCompleted,
      localSessionCleanupCompleted: localSessionCleanupCompleted,
    );
  }

  Future<bool> _refresh(int epoch) async {
    final refreshToken = await _keyStore.readToken('refresh');
    if (refreshToken == null || epoch != _sessionEpoch) return false;
    late final Map<String, dynamic> response;
    try {
      response = await _api.postJson(
        '/v1/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSessionIfCurrent(epoch);
      }
      rethrow;
    }
    final accessToken = response['accessToken'];
    final replacement = response['refreshToken'];
    final account = response['account'];
    if (accessToken is! String || replacement is! String || account is! Map) {
      throw const FormatException('Invalid refresh response.');
    }
    return _commitSession(
      epoch: epoch,
      accessToken: accessToken,
      refreshToken: replacement,
      account: AccountProfile.fromJson(account.cast<String, dynamic>()),
    );
  }

  Future<String> _requiredAccessToken() async {
    final token = await _keyStore.readToken('access');
    if (token == null) throw StateError('No authenticated session.');
    return token;
  }

  Future<bool> _commitSession({
    required int epoch,
    required String accessToken,
    required String refreshToken,
    required AccountProfile account,
  }) {
    return _serializeSessionMutation(() async {
      if (epoch != _sessionEpoch) return false;
      try {
        await _keyStore.writeToken('access', accessToken);
        if (epoch != _sessionEpoch) {
          await _keyStore.clearTokens();
          return false;
        }
        await _keyStore.writeToken('refresh', refreshToken);
        if (epoch != _sessionEpoch) {
          await _keyStore.clearTokens();
          return false;
        }
      } catch (_) {
        await _keyStore.clearTokens();
        if (epoch == _sessionEpoch) _account = null;
        rethrow;
      }
      _account = account;
      return true;
    });
  }

  Future<bool> _setAccountIfCurrent(int epoch, AccountProfile account) {
    return _serializeSessionMutation(() async {
      if (epoch != _sessionEpoch) return false;
      _account = account;
      return true;
    });
  }

  Future<bool> _clearSessionIfCurrent(int epoch) {
    return _serializeSessionMutation(() async {
      if (epoch != _sessionEpoch) return false;
      await _keyStore.clearTokens();
      if (epoch == _sessionEpoch) _account = null;
      return true;
    });
  }

  Future<T> _serializeSessionMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _sessionMutationTail = _sessionMutationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
