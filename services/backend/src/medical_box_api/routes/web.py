from html import escape
from urllib.parse import quote

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse, JSONResponse

from ..config import Settings, get_settings

router = APIRouter(tags=["web"])
APP_LINK_PATHS = (
    "/app",
    "/app/inventory",
    "/app/reminders",
    "/app/settings",
    "/app/login",
)


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


def support_email_link(settings: Settings, *, subject: str) -> str:
    if settings.support_email is None:
        return (
            "<p><strong>외부 요청 연락처가 아직 구성되지 않았습니다.</strong> "
            "이 상태에서는 외부 베타 배포를 진행하지 않습니다.</p>"
        )
    address = escape(settings.support_email, quote=True)
    mailto = (
        f"mailto:{quote(settings.support_email, safe='@._+-')}"
        f"?subject={quote(subject)}"
    )
    return (
        f'<p><a href="{escape(mailto, quote=True)}">{address}로 이메일 보내기</a></p>'
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
        "<h2>기기 안에만 저장되는 정보</h2>"
        "<p>가족, 보유 의약품, 수량, 유효기간, 메모, 방문 일정과 알림 정보는 "
        "사용자의 암호화된 기기 데이터베이스에만 저장됩니다. 계정 서버로 "
        "동기화하지 않습니다.</p>"
        "<h2>선택적 계정</h2>"
        "<p>로그인을 선택하면 로그인 제공자, 제공자 계정 식별자, 표시 이름, "
        "이메일, 약관 동의 기록, 검색 권한과 로그인 세션 해시를 처리합니다. "
        "로그인하지 않아도 기기 안의 구급키트 기능을 사용할 수 있습니다.</p>"
        "<h2>국외 처리위탁·보관</h2>"
        "<p>계정 정보는 로그인 및 계정 관리, 의약품 검색 권한 확인을 위해 "
        "암호화 통신으로 전송됩니다. Railway Corporation(548 Market St PMB "
        "68956, San Francisco, CA 94104, privacy@railway.com)이 싱가포르 "
        "리전에서 보관하며, Railway와 승인된 하위처리자의 미국 내 운영 "
        "과정에서도 처리될 수 있습니다.</p>"
        "<p>계정 정보는 계정이 유지되는 동안 보관하고 계정 삭제 시 삭제합니다. "
        "국외 이전을 원하지 않으면 로그인하지 않거나 계정을 삭제할 수 있으며, "
        "이 경우 공식 의약품 검색은 사용할 수 없지만 기기 안의 정리 기능은 "
        "계속 사용할 수 있습니다.</p>"
        "<h2>검색과 로그</h2>"
        "<p>의약품 검색어, 요청 본문과 응답 본문은 애플리케이션 로그나 분석 "
        "시스템에 저장하지 않습니다.</p>",
    )


@router.get("/terms", response_class=HTMLResponse)
def terms(settings: Settings = Depends(get_settings)) -> HTMLResponse:
    return page(
        "이용약관",
        f"<p>시행일: {escape(settings.terms_version)}</p>"
        "<p>서비스의 의약품 정보는 공식 공공데이터를 정리한 참고 정보입니다.</p>"
        "<p>의료적 판단, 진단, 처방, 복용량 결정 또는 대체약 선택에 사용해서는 안 됩니다.</p>",
    )


@router.get("/support", response_class=HTMLResponse)
def support(settings: Settings = Depends(get_settings)) -> HTMLResponse:
    return page(
        "지원",
        "<p>앱 설정에서 기기 데이터 내보내기, 계정 삭제와 기기 데이터 삭제를 "
        "각각 실행할 수 있습니다.</p>"
        + support_email_link(settings, subject="우리집 구급키트 지원 요청"),
    )


@router.get("/account-deletion", response_class=HTMLResponse)
def account_deletion(settings: Settings = Depends(get_settings)) -> HTMLResponse:
    return page(
        "계정 삭제 안내",
        "<h2>앱에서 삭제</h2>"
        "<p>앱의 설정 → 계정 → 계정 삭제에서 소셜 로그인을 다시 확인한 뒤 "
        "계정을 삭제할 수 있습니다.</p>"
        "<h2>앱을 사용할 수 없는 경우</h2>"
        "<p>아래 이메일로 계정 삭제를 요청할 수 있습니다. 가입에 사용한 "
        "로그인 제공자와 이메일 주소만 적어 주세요. 비밀번호, 인증 토큰, "
        "의약품 또는 건강 정보는 보내지 마세요. 본인 확인 방법과 처리 결과는 "
        "회신으로 안내합니다.</p>"
        + support_email_link(settings, subject="우리집 구급키트 계정 삭제 요청")
        + "<h2>기기 데이터</h2>"
        "<p>기기에 저장된 구급키트 데이터는 별도로 삭제하거나 계정 삭제와 함께 "
        "삭제할 수 있습니다. 이 데이터는 서버로 전송되지 않으므로 운영자가 "
        "원격으로 삭제할 수 없습니다.</p>",
    )


@router.get("/app", response_class=HTMLResponse)
@router.get("/app/inventory", response_class=HTMLResponse)
@router.get("/app/reminders", response_class=HTMLResponse)
@router.get("/app/settings", response_class=HTMLResponse)
@router.get("/app/login", response_class=HTMLResponse)
def app_link_fallback() -> HTMLResponse:
    return page(
        "앱에서 열기",
        "<p>우리집 구급키트 앱이 설치되어 있으면 이 링크가 앱의 해당 화면을 엽니다.</p>"
        "<p>앱이 열리지 않으면 홈 화면에서 직접 원하는 메뉴를 선택해 주세요.</p>",
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
    return JSONResponse(
        {
            "applinks": {
                "apps": [],
                "details": [{"appID": app_id, "paths": list(APP_LINK_PATHS)}],
            }
        }
    )


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
