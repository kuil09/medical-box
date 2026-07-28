import 'package:flutter/foundation.dart';

enum LoginProvider { kakao, apple, google }

extension LoginProviderApiName on LoginProvider {
  String get apiName => switch (this) {
    LoginProvider.kakao => 'kakao',
    LoginProvider.apple => 'apple',
    LoginProvider.google => 'google',
  };
}

bool isLoginProviderSupported(LoginProvider provider, TargetPlatform platform) {
  return switch (provider) {
    // Android requires an Apple Service ID web flow, which is not implemented.
    LoginProvider.apple => platform == TargetPlatform.iOS,
    LoginProvider.google || LoginProvider.kakao =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.android,
  };
}
