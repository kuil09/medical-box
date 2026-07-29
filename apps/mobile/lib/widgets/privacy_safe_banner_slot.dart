import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../build_config.dart';
import '../providers.dart';
import '../services/monetization_service.dart';
import '../theme.dart';

class PrivacySafeBannerSlot extends ConsumerWidget {
  const PrivacySafeBannerSlot({required this.placement, super.key});

  final BannerAdPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetization = ref.watch(monetizationStateProvider);
    final ads = ref.watch(bannerAdAdapterProvider);
    if (!bannerAdvertisingEnabled ||
        !monetization.showsAds ||
        !ads.isAvailable) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label: '광고',
      child: Container(
        height: 72,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          color: MedicalBoxColors.surfaceContainer,
          border: Border.all(color: MedicalBoxColors.rail),
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '광고 · 비개인화 광고',
              style: TextStyle(
                color: MedicalBoxColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(child: ads.buildBanner(placement)),
          ],
        ),
      ),
    );
  }
}
