import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../build_config.dart';
import 'login_provider.dart';

class ProviderProof {
  const ProviderProof({required this.idToken, this.authorizationCode});

  final String idToken;
  final String? authorizationCode;
}

abstract interface class SocialAuthGateway {
  bool supportsProvider(LoginProvider provider);

  Future<ProviderProof> authenticate(
    LoginProvider provider, {
    required bool forceReauthentication,
  });

  Future<void> logout(LoginProvider provider);

  Future<void> disconnect(LoginProvider provider);
}

class SdkSocialAuthGateway implements SocialAuthGateway {
  SdkSocialAuthGateway({
    TargetPlatform? targetPlatform,
    bool? appleSignInEnabled,
  }) : _targetPlatform = targetPlatform ?? defaultTargetPlatform,
       _appleSignInEnabled = appleSignInEnabled ?? appleSignInFeatureEnabled;

  static Future<void>? _googleInitialization;

  final TargetPlatform _targetPlatform;
  final bool _appleSignInEnabled;

  @override
  bool supportsProvider(LoginProvider provider) {
    if (provider == LoginProvider.kakao && !kakaoNativeAppConfigured) {
      return false;
    }
    return isLoginProviderSupported(
      provider,
      _targetPlatform,
      appleSignInEnabled: _appleSignInEnabled,
    );
  }

  @override
  Future<ProviderProof> authenticate(
    LoginProvider provider, {
    required bool forceReauthentication,
  }) async {
    if (!supportsProvider(provider)) {
      throw UnsupportedError(
        '${provider.apiName} sign-in is not supported on '
        '${_targetPlatform.name}.',
      );
    }
    switch (provider) {
      case LoginProvider.google:
        final google = await _googleSignIn();
        if (forceReauthentication) {
          await google.signOut();
        }
        final user = await google.authenticate(scopeHint: const ['email']);
        final token = user.authentication.idToken;
        if (token == null) {
          throw StateError('Google sign-in was cancelled.');
        }
        return ProviderProof(idToken: token);
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
        return ProviderProof(
          idToken: token,
          authorizationCode: credential.authorizationCode,
        );
      case LoginProvider.kakao:
        if (!kakaoNativeAppConfigured) {
          throw StateError('KAKAO_NATIVE_APP_KEY is not configured.');
        }
        final token = forceReauthentication
            ? await UserApi.instance.loginWithKakaoAccount(
                prompts: const [Prompt.login],
              )
            : await _regularKakaoLogin();
        if (token.idToken == null) {
          throw StateError('Kakao OpenID Connect must be enabled.');
        }
        return ProviderProof(idToken: token.idToken!);
    }
  }

  @override
  Future<void> logout(LoginProvider provider) async {
    switch (provider) {
      case LoginProvider.google:
        final google = await _googleSignIn(requireConfiguration: false);
        await google.signOut();
        return;
      case LoginProvider.kakao:
        await UserApi.instance.logout();
        return;
      case LoginProvider.apple:
        // Apple exposes no client-side logout operation.
        return;
    }
  }

  @override
  Future<void> disconnect(LoginProvider provider) async {
    switch (provider) {
      case LoginProvider.google:
        final google = await _googleSignIn();
        await google.disconnect();
        return;
      case LoginProvider.kakao:
        await UserApi.instance.unlink();
        return;
      case LoginProvider.apple:
        // Apple authorization is revoked by the server using the fresh code.
        return;
    }
  }

  Future<OAuthToken> _regularKakaoLogin() async {
    final available = await isKakaoTalkInstalled();
    return available
        ? UserApi.instance.loginWithKakaoTalk()
        : UserApi.instance.loginWithKakaoAccount();
  }

  Future<GoogleSignIn> _googleSignIn({bool requireConfiguration = true}) async {
    if (requireConfiguration && googleServerClientId.isEmpty) {
      throw StateError('GOOGLE_SERVER_CLIENT_ID is not configured.');
    }
    if (requireConfiguration &&
        _targetPlatform == TargetPlatform.iOS &&
        googleIosClientId.isEmpty) {
      throw StateError('GOOGLE_IOS_CLIENT_ID is not configured.');
    }
    final google = GoogleSignIn.instance;
    _googleInitialization ??= google.initialize(
      serverClientId: googleServerClientId.isEmpty
          ? null
          : googleServerClientId,
      clientId:
          _targetPlatform == TargetPlatform.iOS && googleIosClientId.isNotEmpty
          ? googleIosClientId
          : null,
    );
    await _googleInitialization;
    return google;
  }
}
