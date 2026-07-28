const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
const appleSignInFeatureEnabled = bool.fromEnvironment(
  'APPLE_SIGN_IN_ENABLED',
  defaultValue: false,
);
