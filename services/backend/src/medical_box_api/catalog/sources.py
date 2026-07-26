from dataclasses import dataclass

from ..config import Settings


@dataclass(frozen=True)
class SourceDefinition:
    code: str
    name: str
    portal_url: str
    api_url: str | None
    record_key_fields: tuple[str, ...]
    kind: str
    license_name: str
    attribution: str
    composite_key_fields: tuple[str, ...] = ()
    rule_type: str | None = None
    hash_record_key: bool = False
    allow_identical_duplicates: bool = False


DUR_PRODUCT_OPERATIONS = (
    (
        "mfds_dur",
        "DUR product information",
        "getDurPrdlstInfoList03",
        "product",
        (),
    ),
    (
        "mfds_dur_product_concomitant",
        "DUR product concomitant contraindications",
        "getUsjntTabooInfoList03",
        "concomitant_contraindication",
        ("DUR_SEQ", "ITEM_SEQ", "MIXTURE_DUR_SEQ", "MIXTURE_ITEM_SEQ"),
    ),
    (
        "mfds_dur_product_elderly",
        "DUR product elderly cautions",
        "getOdsnAtentInfoList03",
        "elderly_caution",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_age",
        "DUR product age contraindications",
        "getSpcifyAgrdeTabooInfoList03",
        "age_contraindication",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_dose",
        "DUR product dose cautions",
        "getCpctyAtentInfoList03",
        "dose_caution",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_duration",
        "DUR product duration cautions",
        "getMdctnPdAtentInfoList03",
        "duration_caution",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_duplicate",
        "DUR product efficacy-group duplication cautions",
        "getEfcyDplctInfoList03",
        "efficacy_group_duplication",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_split",
        "DUR product extended-release split cautions",
        "getSeobangjeongPartitnAtentInfoList03",
        "extended_release_split_caution",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_product_pregnancy",
        "DUR product pregnancy contraindications",
        "getPwnmTabooInfoList03",
        "pregnancy_contraindication",
        ("ITEM_SEQ", "INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
)

DUR_INGREDIENT_OPERATIONS = (
    (
        "mfds_dur_ingredient_concomitant",
        "DUR ingredient concomitant contraindications",
        "getUsjntTabooInfoList02",
        "concomitant_contraindication",
        ("INGR_CODE", "MIXTURE_INGR_CODE", "NOTIFICATION_DATE", "TYPE_NAME"),
    ),
    (
        "mfds_dur_ingredient_pregnancy",
        "DUR ingredient pregnancy contraindications",
        "getPwnmTabooInfoList02",
        "pregnancy_contraindication",
        ("DUR_SEQ",),
    ),
    (
        "mfds_dur_ingredient_dose",
        "DUR ingredient dose cautions",
        "getCpctyAtentInfoList02",
        "dose_caution",
        ("DUR_SEQ",),
    ),
    (
        "mfds_dur_ingredient_duration",
        "DUR ingredient duration cautions",
        "getMdctnPdAtentInfoList02",
        "duration_caution",
        ("DUR_SEQ",),
    ),
    (
        "mfds_dur_ingredient_elderly",
        "DUR ingredient elderly cautions",
        "getOdsnAtentInfoList02",
        "elderly_caution",
        ("DUR_SEQ",),
    ),
    (
        "mfds_dur_ingredient_age",
        "DUR ingredient age contraindications",
        "getSpcifyAgrdeTabooInfoList02",
        "age_contraindication",
        ("DUR_SEQ",),
    ),
    (
        "mfds_dur_ingredient_duplicate",
        "DUR ingredient efficacy-group duplication cautions",
        "getEfcyDplctInfoList02",
        "efficacy_group_duplication",
        ("DUR_SEQ",),
    ),
)


def dur_sources(settings: Settings) -> list[SourceDefinition]:
    record_key_fields = (
        "DUR_SEQ",
        "durSeq",
        "ITEM_SEQ",
        "itemSeq",
        "INGR_CODE",
        "ingrCode",
        "DUR_INGR_CODE",
        "durIngrCode",
    )
    product_portal = "https://www.data.go.kr/data/15059486/openapi.do"
    ingredient_portal = "https://www.data.go.kr/data/15056780/openapi.do"
    sources = [
        SourceDefinition(
            code=code,
            name=f"MFDS {name}",
            portal_url=product_portal,
            api_url=f"{settings.mfds_dur_product_base_url}/{operation}",
            record_key_fields=record_key_fields,
            kind="dur",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
            composite_key_fields=composite_key_fields,
            rule_type=rule_type,
            hash_record_key=rule_type != "product",
            allow_identical_duplicates=rule_type != "product",
        )
        for code, name, operation, rule_type, composite_key_fields in DUR_PRODUCT_OPERATIONS
    ]
    sources.extend(
        SourceDefinition(
            code=code,
            name=f"MFDS {name}",
            portal_url=ingredient_portal,
            api_url=f"{settings.mfds_dur_ingredient_base_url}/{operation}",
            record_key_fields=record_key_fields,
            kind="dur",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
            composite_key_fields=composite_key_fields,
            rule_type=rule_type,
            hash_record_key=True,
            allow_identical_duplicates=True,
        )
        for code, name, operation, rule_type, composite_key_fields in DUR_INGREDIENT_OPERATIONS
    )
    return sources


def official_sources(settings: Settings) -> list[SourceDefinition]:
    sources = [
        SourceDefinition(
            code="mfds_product",
            name="MFDS pharmaceutical product authorization",
            portal_url="https://www.data.go.kr/data/15095677/openapi.do",
            api_url=settings.mfds_product_url,
            record_key_fields=("ITEM_SEQ", "itemSeq", "prdlst_Stdr_code"),
            kind="product_catalog",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
        ),
        SourceDefinition(
            code="mfds_product_detail",
            name="MFDS pharmaceutical product authorization detail",
            portal_url="https://www.data.go.kr/data/15095677/openapi.do",
            api_url=settings.mfds_product_detail_url,
            record_key_fields=("ITEM_SEQ", "itemSeq"),
            kind="product_detail",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
        ),
        SourceDefinition(
            code="mfds_product_ingredient",
            name="MFDS pharmaceutical product ingredient detail",
            portal_url="https://www.data.go.kr/data/15095677/openapi.do",
            api_url=settings.mfds_product_ingredient_url,
            record_key_fields=("ITEM_SEQ", "itemSeq"),
            kind="product_ingredient",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
            composite_key_fields=("ITEM_SEQ", "TAMT_SEQ", "MTRAL_SN"),
        ),
        SourceDefinition(
            code="mfds_easy",
            name="MFDS e약은요 consumer information",
            portal_url="https://www.data.go.kr/data/15075057/openapi.do",
            api_url=settings.mfds_easy_url,
            record_key_fields=("itemSeq", "ITEM_SEQ"),
            kind="consumer",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
            composite_key_fields=("itemSeq", "itemImage"),
        ),
        SourceDefinition(
            code="mfds_pill",
            name="MFDS pill identification",
            portal_url="https://www.data.go.kr/data/15057639/openapi.do",
            api_url=settings.mfds_pill_url,
            record_key_fields=("ITEM_SEQ", "itemSeq"),
            kind="identification",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
            composite_key_fields=("ITEM_SEQ", "ITEM_IMAGE"),
            hash_record_key=True,
            allow_identical_duplicates=True,
        ),
        SourceDefinition(
            code="mfds_recall",
            name="MFDS recall and sale suspension",
            portal_url="https://www.data.go.kr/data/15059114/openapi.do",
            api_url=settings.mfds_recall_url,
            record_key_fields=("SEQ", "seq", "ITEM_SEQ", "itemSeq"),
            kind="status_recall",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
        ),
        SourceDefinition(
            code="mfds_shortage",
            name="MFDS supply shortage",
            portal_url="https://www.data.go.kr/data/15057899/openapi.do",
            api_url=settings.mfds_shortage_url,
            record_key_fields=("SEQ", "seq", "ITEM_SEQ", "itemSeq"),
            kind="status_shortage",
            license_name="Public data, unrestricted use",
            attribution="Source: Ministry of Food and Drug Safety",
        ),
        SourceDefinition(
            code="hira_price",
            name="HIRA drug reimbursement price",
            portal_url="https://www.data.go.kr/data/15054445/openapi.do",
            api_url=settings.hira_price_url,
            record_key_fields=("mdsCd", "MD_CODE", "ediCode"),
            kind="price",
            license_name="Korea Open Government License Type 1",
            attribution="Source: Health Insurance Review & Assessment Service",
        ),
        SourceDefinition(
            code="hira_standard_code",
            name="HIRA medicine standard code",
            portal_url="https://www.data.go.kr/data/15067462/fileData.do",
            api_url=settings.hira_standard_code_url,
            record_key_fields=("표준코드", "standardCode", "품목기준코드", "itemSeq"),
            kind="code",
            license_name="Korea Open Government License Type 1",
            attribution="Source: Health Insurance Review & Assessment Service",
        ),
    ]
    sources[5:5] = dur_sources(settings)
    return sources
