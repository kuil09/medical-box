import {
  defineRailway,
  github,
  group,
  postgres,
  preserve,
  project,
  service,
} from "railway/iac";

const SINGAPORE = "asia-southeast1-eqsg3a";
const BACKEND_ROOT = "services/backend";

export default defineRailway((ctx) => {
  if (!ctx.isEnvironment("production")) {
    throw new Error("Medical Box IaC may only target the production environment.");
  }

  const publicOrigin = "https://medicalbox.outoftokens.ai";
  const domain = "medicalbox.outoftokens.ai";
  const allowedHosts = [
    domain,
    "medical-box.railway.internal",
    "healthcheck.railway.app",
  ].join(",");

  const database = postgres("Postgres", {
    region: SINGAPORE,
  });

  const sharedRuntimeEnv = {
    APP_ENV: "production",
    DATABASE_URL: database.env.DATABASE_URL,
    PUBLIC_ORIGIN: publicOrigin,
    ALLOWED_HOSTS: allowedHosts,
    JWT_ISSUER: "https://medicalbox.outoftokens.ai",
    JWT_AUDIENCE: "com.medicalbox.app",
    JWT_SECRET: preserve(),
    CATALOG_ACCESS_EMAIL_ALLOWLIST: preserve(),
    DATA_GO_KR_SERVICE_KEY: preserve(),
    GOOGLE_CLIENT_ID: preserve(),
    APPLE_CLIENT_ID: "com.medicalbox.app",
    KAKAO_APP_ID: preserve(),
    APPLE_TEAM_ID: preserve(),
    ANDROID_CERT_SHA256: preserve(),
    MFDS_RECALL_URL: preserve(),
    MFDS_SHORTAGE_URL: preserve(),
    HIRA_PRICE_URL: preserve(),
    HIRA_STANDARD_CODE_URL: preserve(),
  };

  const api = service("medical-box", {
    source: github("kuil09/medical-box"),
    rootDirectory: BACKEND_ROOT,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile",
      watchPatterns: [
        "services/backend/**",
        ".railway/railway.ts",
      ],
    },
    start:
      "uv run --no-sync uvicorn medical_box_api.main:app --host 0.0.0.0 --port 8080 --no-access-log",
    preDeploy: "uv run --no-sync alembic upgrade head",
    healthcheck: "/api/health/ready",
    healthcheckTimeout: 300,
    replicas: { [SINGAPORE]: 1 },
    deploy: {
      restartPolicyMaxRetries: 5,
      overlapSeconds: 20,
      drainingSeconds: 15,
    },
    env: {
      ...sharedRuntimeEnv,
      PORT: "8080",
    },
  });

  // The promoted catalog is served from production. Automated full refreshes
  // remain disabled until the 5 GB volume or ingestion transaction strategy is
  // expanded enough to preserve operational headroom.
  const backend = group("Backend", [api, database]);

  return project("medical-box", {
    resources: [backend],
  });
});
