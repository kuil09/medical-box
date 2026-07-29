const appLinkRedirects = <String, String>{
  '/app': '/',
  '/app/inventory': '/inventory',
  '/app/reminders': '/reminders',
  '/app/settings': '/settings',
  '/app/login': '/login',
};

String? appAccessRedirect({
  required String path,
  required bool onboardingCompleted,
  required bool authenticated,
}) {
  if (path == '/gate') return null;

  if (!onboardingCompleted) {
    return path == '/onboarding' ? null : '/onboarding';
  }

  if (path == '/onboarding') {
    return authenticated ? '/' : '/login';
  }

  if (authenticated || path == '/login' || path == '/app/login') {
    return null;
  }

  return Uri(path: '/login', queryParameters: {'from': path}).toString();
}

String? safePostLoginLocation(String? value) {
  if (value == null ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      value == '/login' ||
      value == '/onboarding' ||
      value == '/gate') {
    return null;
  }
  return value;
}
