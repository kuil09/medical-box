import {
  defineRailway,
  group,
  postgres,
  project,
  service,
} from "railway/iac";

const SINGAPORE = "asia-southeast1-eqsg3a";
const BACKEND_ROOT = "services/backend";

export default defineRailway((ctx) => {
  const production = ctx.isEnvironment("production");
  const staging = ctx.isEnvironment("staging");
  if (!production && !staging) {
    throw new Error(
      "Medical Box IaC may only target the production or staging environment.",
    );
  }

  const publicOrigin = production
    ? "https://medicalbox.outoftokens.ai"
    : "https://staging.medicalbox.outoftokens.ai";
  const domain = production
    ? "medicalbox.outoftokens.ai"
    : "staging.medicalbox.outoftokens.ai";

  const database = postgres("postgres", { region: SINGAPORE });

  const sharedRuntimeEnv = {
    APP_ENV: production ? "production" : "staging",
    DATABASE_URL: database.env.DATABASE_URL,
    PUBLIC_ORIGIN: publicOrigin,
    ALLOWED_HOSTS: domain,
    JWT_ISSUER: production
      ? "https://medicalbox.outoftokens.ai"
      : "https://staging.medicalbox.outoftokens.ai",
    JWT_AUDIENCE: production
      ? "com.medicalbox.app"
      : "com.medicalbox.app.staging",
    JWT_SECRET: ctx.shared.JWT_SECRET,
    CATALOG_ACCESS_EMAIL_ALLOWLIST:
      ctx.shared.CATALOG_ACCESS_EMAIL_ALLOWLIST,
    DATA_GO_KR_SERVICE_KEY: ctx.shared.DATA_GO_KR_SERVICE_KEY,
    GOOGLE_CLIENT_ID: ctx.shared.GOOGLE_CLIENT_ID,
    APPLE_CLIENT_ID: "com.medicalbox.app",
    KAKAO_APP_ID: ctx.shared.KAKAO_APP_ID,
    APPLE_TEAM_ID: ctx.shared.APPLE_TEAM_ID,
    ANDROID_CERT_SHA256: ctx.shared.ANDROID_CERT_SHA256,
    MFDS_RECALL_URL: ctx.shared.MFDS_RECALL_URL,
    MFDS_SHORTAGE_URL: ctx.shared.MFDS_SHORTAGE_URL,
    HIRA_PRICE_URL: ctx.shared.HIRA_PRICE_URL,
    HIRA_STANDARD_CODE_URL: ctx.shared.HIRA_STANDARD_CODE_URL,
    ...(staging
      ? { STAGING_ACCESS_KEY: ctx.shared.STAGING_ACCESS_KEY }
      : {}),
  };

  const api = service("api", {
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
    domains: [{ domain, port: 8080 }],
    deploy: {
      restartPolicyType: "ON_FAILURE",
      restartPolicyMaxRetries: 5,
      overlapSeconds: 20,
      drainingSeconds: 15,
    },
    env: {
      ...sharedRuntimeEnv,
      PORT: "8080",
    },
  });

  const catalogSync = service("catalog-sync", {
    rootDirectory: BACKEND_ROOT,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile",
      watchPatterns: [
        "services/backend/**",
        ".railway/railway.ts",
      ],
    },
    start: "uv run --no-sync medical-box-sync all-sources",
    deploy: {
      cronSchedule: "10 18 * * *",
      region: SINGAPORE,
      restartPolicyType: "NEVER",
    },
    env: sharedRuntimeEnv,
  });

  const backend = group("Backend", [api, catalogSync, database]);

  return project("medical-box", {
    resources: [backend],
  });
});
