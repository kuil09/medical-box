from fastapi import FastAPI, Request
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.base import RequestResponseEndpoint
from starlette.responses import Response

from .config import get_settings
from .routes import auth, catalog, health, me, web

settings = get_settings()

app = FastAPI(
    title="Medical Box API",
    version="0.1.0",
    docs_url="/api/docs" if settings.app_env != "production" else None,
    openapi_url="/api/openapi.json" if settings.app_env != "production" else None,
)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.allowed_host_list)


@app.middleware("http")
async def security_boundary(request: Request, call_next: RequestResponseEndpoint) -> Response:
    path = request.url.path
    response = await call_next(request)
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = (
        "no-store" if path.startswith("/api/v1/auth") or path == "/api/v1/me" else "private"
    )
    return response


app.include_router(auth.router)
app.include_router(me.router)
app.include_router(catalog.router)
app.include_router(health.router)
app.include_router(web.router)
