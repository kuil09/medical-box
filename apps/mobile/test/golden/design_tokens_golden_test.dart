import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/theme.dart';

void main() {
  testWidgets('hinged attention deck color and radius tokens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: MedicalBoxColors.ivory,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.sky,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 164,
                        decoration: BoxDecoration(
                          color: MedicalBoxColors.paper,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: MedicalBoxColors.line),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 164,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD8C8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.orange,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/hinged_attention_deck.png'),
    );
  });
}
