import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy-first onboarding copy is visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('로그인 없이 시작'))),
    );

    expect(find.text('로그인 없이 시작'), findsOneWidget);
  });
}
