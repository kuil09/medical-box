import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source manifest declares scheduled notification delivery components', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final entry in const [
      'android.permission.RECEIVE_BOOT_COMPLETED',
      'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      'android.intent.action.BOOT_COMPLETED',
      'android.intent.action.MY_PACKAGE_REPLACED',
    ]) {
      expect(manifest, contains(entry), reason: 'Missing $entry');
    }
  });

  test('merged manifest verifier checks the built manifest boundary', () {
    final verifier = File(
      'tool/verify_android_notification_manifest.sh',
    ).readAsStringSync();

    expect(verifier, contains('merged_manifests/debug'));
    expect(verifier, contains('ScheduledNotificationReceiver'));
    expect(verifier, contains('ScheduledNotificationBootReceiver'));
    expect(verifier, contains('RECEIVE_BOOT_COMPLETED'));
  });
}
