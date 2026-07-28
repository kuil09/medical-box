const appLinkRedirects = <String, String>{
  '/app': '/',
  '/app/inventory': '/inventory',
  '/app/reminders': '/reminders',
  '/app/settings': '/settings',
  '/app/login': '/login',
};

String? onboardingGuardRedirect({
  required String path,
  required bool onboardingCompleted,
}) {
  if (onboardingCompleted ||
      path == '/onboarding' ||
      path == '/login' ||
      path == '/app/login') {
    return null;
  }
  return '/onboarding';
}
