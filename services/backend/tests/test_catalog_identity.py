"""Verify stable catalog identity hashing across storage backends."""

from medical_box_api.catalog.identity import catalog_identity_hash


def test_catalog_identity_hash_is_stable() -> None:
    assert catalog_identity_hash("mfds_product", "200000001") == (
        -18196292544617695
    )
    assert catalog_identity_hash("한글_소스", "키:123") == 803936667978801673


def test_catalog_identity_hash_separates_boundaries() -> None:
    assert catalog_identity_hash("ab", "c") != catalog_identity_hash(
        "a",
        "bc",
    )
