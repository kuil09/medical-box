from html import escape

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse, JSONResponse

from ..config import Settings, get_settings

router = APIRouter(tags=["web"])


def page(title: str, content: str) -> HTMLResponse:
    return HTMLResponse(
        f"""<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escape(title)} · 우리집 구급키트</title>
  <style>
    body {{
      margin: 0;
      background: #f5efe6;
      color: #403b35;
      font-family: -apple-system, sans-serif;
    }}
    main {{ max-width: 720px; margin: 0 auto; padding: 72px 24px; }}
    h1 {{ font-size: 40px; letter-spacing: -.04em; }}
    article {{
      background: #fffdf9;
      border: 1px solid #ded5ca;
      border-radius: 24px;
      padding: 28px;
      line-height: 1.75;
    }}
    a {{ color: #b81d18; }}
  </style>
</head>
<body><main><p>우리집 구급키트</p><h1>{escape(title)}</h1><article>{content}</article></main></body>
</html>"""
    )


@router.get("/", response_class=HTMLResponse)
def home() -> HTMLResponse:
    return page(
        "가족 구급키트를 한눈에",
        "<p>공용 트레이와 개인 파우치를 정리하고, 재고와 다음 점검을 기기 안에서 관리합니다.</p>"
        "<p>진단, 복용량 계산, 대체약 또는 치료 추천은 제공하지 않습니다.</p>",
    )


@router.get("/privacy", response_class=HTMLResponse)
def privacy() -> HTMLResponse:
    return page(
        "개인정보 처리방침",
        "<p>가족, 보유 의약품, 수량, 방문 일정과 알림 정보는 사용자의 기기에만 저장됩니다.</p>"
        "<p>선택적 소셜 로그인 시 계정 식별자와 이메일 등 최소 정보가 "
        "Railway 싱가포르 리전에서 처리될 수 있습니다.</p>"
        "<p>의약품 검색어는 계정과 연결하거나 로그에 저장하지 않습니다.</p>",
    )


@router.get("/terms", response_class=HTMLResponse)
def terms() -> HTMLResponse:
    return page(
        "이용약관",
        "<p>서비스의 의약품 정보는 공식 공공데이터를 정리한 참고 정보입니다.</p>"
        "<p>의료적 판단, 진단, 처방, 복용량 결정 또는 대체약 선택에 사용해서는 안 됩니다.</p>",
    )


@router.get("/support", response_class=HTMLResponse)
def support() -> HTMLResponse:
    return page(
        "지원",
        "<p>앱 설정에서 기기 데이터 내보내기, 계정 삭제와 기기 데이터 삭제를 "
        "각각 실행할 수 있습니다.</p>"
        "<p>지원 연락처는 베타 배포 전에 이 페이지에 추가됩니다.</p>",
    )


@router.get("/account-deletion", response_class=HTMLResponse)
def account_deletion() -> HTMLResponse:
    return page(
        "계정 삭제 안내",
        "<p>앱의 설정 → 계정 → 계정 삭제에서 소셜 로그인을 다시 확인한 뒤 "
        "계정을 삭제할 수 있습니다.</p>"
        "<p>기기에 저장된 구급키트 데이터는 별도로 삭제하거나 계정 삭제와 함께 "
        "삭제할 수 있습니다.</p>",
    )


@router.get("/.well-known/apple-app-site-association")
def apple_app_site_association(
    settings: Settings = Depends(get_settings),
) -> JSONResponse:
    app_id = (
        f"{settings.apple_team_id}.com.medicalbox.app"
        if settings.apple_team_id
        else "UNCONFIGURED.com.medicalbox.app"
    )
    return JSONResponse({"applinks": {"apps": [], "details": [{"appID": app_id, "paths": ["*"]}]}})


@router.get("/.well-known/assetlinks.json")
def android_asset_links(settings: Settings = Depends(get_settings)) -> JSONResponse:
    fingerprints = [settings.android_cert_sha256] if settings.android_cert_sha256 else []
    return JSONResponse(
        [
            {
                "relation": ["delegate_permission/common.handle_all_urls"],
                "target": {
                    "namespace": "android_app",
                    "package_name": "com.medicalbox.app",
                    "sha256_cert_fingerprints": fingerprints,
                },
            }
        ]
    )
