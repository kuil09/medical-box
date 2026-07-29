import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/theme.dart';

void main() {
  testWidgets('cabinet index v2 color and radius tokens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: MedicalBoxColors.canvas,
          body: Padding(
            padding: const EdgeInsets.all(MedicalBoxSpacing.screen),
            child: Column(
              children: [
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.surface,
                    borderRadius: BorderRadius.circular(
                      MedicalBoxRadius.cabinet,
                    ),
                    border: Border.all(
                      color: MedicalBoxColors.railStrong,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A17191C),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MedicalBoxSpacing.x4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 164,
                        decoration: BoxDecoration(
                          color: MedicalBoxColors.surface,
                          borderRadius: BorderRadius.circular(
                            MedicalBoxRadius.group,
                          ),
                          border: Border.all(color: MedicalBoxColors.rail),
                        ),
                      ),
                    ),
                    const SizedBox(width: MedicalBoxSpacing.x3),
                    Expanded(
                      child: Container(
                        height: 164,
                        decoration: BoxDecoration(
                          color: MedicalBoxColors.accentSoft,
                          borderRadius: BorderRadius.circular(
                            MedicalBoxRadius.group,
                          ),
                          border: Border.all(color: MedicalBoxColors.rail),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MedicalBoxSpacing.x4),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: MedicalBoxColors.accent,
                    borderRadius: BorderRadius.circular(
                      MedicalBoxRadius.control,
                    ),
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
