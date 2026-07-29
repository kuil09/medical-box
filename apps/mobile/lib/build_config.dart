const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
final kakaoNativeAppConfigured =
    kakaoNativeAppKey.isNotEmpty && kakaoNativeAppKey != 'unconfigured';
const appleSignInFeatureEnabled = bool.fromEnvironment(
  'APPLE_SIGN_IN_ENABLED',
  defaultValue: false,
);
const bannerAdvertisingEnabled = bool.fromEnvironment(
  'MEDICAL_BOX_BANNER_ADS_ENABLED',
  defaultValue: false,
);
