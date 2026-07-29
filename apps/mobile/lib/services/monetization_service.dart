import 'package:flutter/widgets.dart';

enum AccountAccessTier { freeWithAds, adFreeLifetime, familyPlus }

extension AccountAccessTierWireValue on AccountAccessTier {
  String get wireValue => switch (this) {
    AccountAccessTier.freeWithAds => 'free_with_ads',
    AccountAccessTier.adFreeLifetime => 'ad_free_lifetime',
    AccountAccessTier.familyPlus => 'family_plus',
  };
}

AccountAccessTier accountAccessTierFromWireValue(String value) {
  return switch (value) {
    'free_with_ads' => AccountAccessTier.freeWithAds,
    'ad_free_lifetime' => AccountAccessTier.adFreeLifetime,
    'family_plus' => AccountAccessTier.familyPlus,
    _ => throw FormatException('Unknown account access tier: $value'),
  };
}

enum BannerAdPlacement {
  homeAfterSummary,
  inventoryListEnd,
  settingsGeneralFooter,
}

class MonetizationState {
  const MonetizationState({
    required this.accessTier,
    this.verifiedAt,
    this.offlineValidUntil,
  });

  const MonetizationState.free()
    : accessTier = AccountAccessTier.freeWithAds,
      verifiedAt = null,
      offlineValidUntil = null;

  final AccountAccessTier accessTier;
  final DateTime? verifiedAt;
  final DateTime? offlineValidUntil;

  bool get showsAds => accessTier == AccountAccessTier.freeWithAds;
}

abstract interface class BannerAdAdapter {
  bool get isAvailable;

  Widget buildBanner(BannerAdPlacement placement);
}

class DisabledBannerAdAdapter implements BannerAdAdapter {
  const DisabledBannerAdAdapter();

  @override
  bool get isAvailable => false;

  @override
  Widget buildBanner(BannerAdPlacement placement) {
    return const SizedBox.shrink();
  }
}
