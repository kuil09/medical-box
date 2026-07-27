import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/api_client.dart';
import '../local/database_key_store.dart';

const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

enum LoginProvider { kakao, apple, google }

extension LoginProviderApiName on LoginProvider {
  String get apiName => switch (this) {
    LoginProvider.kakao => 'kakao',
    LoginProvider.apple => 'apple',
    LoginProvider.google => 'google',
  };
}

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
  AuthRepository(this._api, this._keyStore);

  final ApiClient _api;
  final DatabaseKeyStore _keyStore;
  AccountProfile? _account;
  Future<String?>? _refreshInFlight;

  AccountProfile? get account => _account;

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

  Future<AccountProfile> signIn(LoginProvider provider) async {
    final providerToken = await _providerToken(provider);
    final response = await _api.postJson(
      '/v1/auth/exchange/${provider.apiName}',
      body: {
        'providerToken': providerToken,
        'termsVersion': '2026-07-25',
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
    final refreshToken = await _keyStore.readToken('refresh');
    if (refreshToken != null) {
      try {
        await _api.postJson(
          '/v1/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      } on ApiException {
        // Local sign-out must remain available when the network is unavailable.
      }
    }
    await _keyStore.clearTokens();
    _account = null;
    await _googleSignIn(requireConfiguration: false).signOut();
  }

  Future<void> deleteAccount(LoginProvider provider) async {
    final accessToken = await _requiredAccessToken();
    final providerToken = await _providerToken(provider);
    final response = await _api.postJson(
      '/v1/auth/reauth/${provider.apiName}',
      accessToken: accessToken,
      body: {'providerToken': providerToken},
    );
    final grant = response['grant'];
    if (grant is! String) {
      throw const FormatException('Missing reauthentication grant.');
    }
    await _api.deleteJson(
      '/v1/me',
      accessToken: accessToken,
      body: {'reauthGrant': grant},
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

  Future<String> _providerToken(LoginProvider provider) async {
    switch (provider) {
      case LoginProvider.google:
        final user = await _googleSignIn().signIn();
        final token = (await user?.authentication)?.idToken;
        if (token == null) throw StateError('Google sign-in was cancelled.');
        return token;
      case LoginProvider.apple:
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final token = credential.identityToken;
        if (token == null) {
          throw StateError('Apple did not return an ID token.');
        }
        return token;
      case LoginProvider.kakao:
        final available = await isKakaoTalkInstalled();
        final token = available
            ? await UserApi.instance.loginWithKakaoTalk()
            : await UserApi.instance.loginWithKakaoAccount();
        if (token.idToken == null) {
          throw StateError('Kakao OpenID Connect must be enabled.');
        }
        return token.idToken!;
    }
  }

  GoogleSignIn _googleSignIn({bool requireConfiguration = true}) {
    if (requireConfiguration && googleServerClientId.isEmpty) {
      throw StateError('GOOGLE_SERVER_CLIENT_ID is not configured.');
    }
    if (requireConfiguration && Platform.isIOS && googleIosClientId.isEmpty) {
      throw StateError('GOOGLE_IOS_CLIENT_ID is not configured.');
    }
    return GoogleSignIn(
      scopes: const ['email'],
      serverClientId: googleServerClientId.isEmpty
          ? null
          : googleServerClientId,
      clientId: Platform.isIOS && googleIosClientId.isNotEmpty
          ? googleIosClientId
          : null,
    );
  }
}
