import 'package:flutter_test/flutter_test.dart';
import 'package:medical_box/services/monetization_service.dart';

void main() {
  test('access tiers use the approved provider-independent identifiers', () {
    for (final tier in AccountAccessTier.values) {
      expect(accountAccessTierFromWireValue(tier.wireValue), tier);
    }
    expect(AccountAccessTier.values.map((tier) => tier.wireValue), [
      'free_with_ads',
      'ad_free_lifetime',
      'family_plus',
    ]);
  });

  test('only the three approved banner placements exist', () {
    expect(BannerAdPlacement.values, [
      BannerAdPlacement.homeAfterSummary,
      BannerAdPlacement.inventoryListEnd,
      BannerAdPlacement.settingsGeneralFooter,
    ]);
  });

  test('only free accounts are eligible for ads', () {
    expect(const MonetizationState.free().showsAds, isTrue);
    expect(
      const MonetizationState(
        accessTier: AccountAccessTier.adFreeLifetime,
      ).showsAds,
      isFalse,
    );
    expect(
      const MonetizationState(
        accessTier: AccountAccessTier.familyPlus,
      ).showsAds,
      isFalse,
    );
    expect(const DisabledBannerAdAdapter().isAvailable, isFalse);
  });
}
