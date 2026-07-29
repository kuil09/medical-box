import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/data/local/app_database.dart';
import 'package:medical_box/features/onboarding/onboarding_screen.dart';
import 'package:medical_box/providers.dart';

void main() {
  testWidgets('onboarding requires an account before app entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('가입 또는 로그인하고 시작'), findsOneWidget);
    expect(find.text('로그인 없이 시작'), findsNothing);
    expect(find.textContaining('개인 보관 데이터는 서버로 동기화되지 않아요'), findsOneWidget);
  });
}
