import {
  defineRailway,
  fn,
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

  const catalogSyncSources = [
    "mfds_product",
    "mfds_product_detail",
    "mfds_product_ingredient",
    "mfds_easy",
    "mfds_pill",
    "mfds_dur",
    "mfds_dur_product_concomitant",
    "mfds_dur_product_elderly",
    "mfds_dur_product_age",
    "mfds_dur_product_dose",
    "mfds_dur_product_duration",
    "mfds_dur_product_duplicate",
    "mfds_dur_product_split",
    "mfds_dur_product_pregnancy",
    "mfds_dur_ingredient_concomitant",
    "mfds_dur_ingredient_pregnancy",
    "mfds_dur_ingredient_dose",
    "mfds_dur_ingredient_duration",
    "mfds_dur_ingredient_elderly",
    "mfds_dur_ingredient_age",
    "mfds_dur_ingredient_duplicate",
    "hira_standard_code",
  ].join(",");

  const catalogRuntimeEnv = {
    APP_ENV: "production",
    APP_ROLE: "catalog_sync",
    DATABASE_URL: database.env.DATABASE_URL,
    CATALOG_SYNC_SOURCE_ALLOWLIST: catalogSyncSources,
    CATALOG_DATABASE_CAPACITY_BYTES: "5000000000",
    CATALOG_MIN_FREE_BYTES: "750000000",
    MFDS_RECALL_URL:
      "https://apis.data.go.kr/1471000/MdcinRtrvlSleStpgeInfoService04/getMdcinRtrvlSleStpgelList03",
    MFDS_SHORTAGE_URL:
      "https://apis.data.go.kr/1471000/MdcinPrdctnIncmeSuplyService2/getMdcinPrdctnIncmeSuplyList",
    HIRA_PRICE_URL:
      "https://apis.data.go.kr/B551182/dgamtCrtrInfoService1.2/getDgamtList",
    HIRA_STANDARD_CODE_URL:
      "https://www.data.go.kr/cmm/cmm/fileDownload.do?atchFileId=FILE_000000003550228&fileDetailSn=1&insertDataPrcus=N",
  };

  const apiRuntimeEnv = {
    ...catalogRuntimeEnv,
    APP_ROLE: "api",
    DATA_GO_KR_SERVICE_KEY: preserve(),
    PUBLIC_ORIGIN: publicOrigin,
    ALLOWED_HOSTS: allowedHosts,
    JWT_ISSUER: "https://medicalbox.outoftokens.ai",
    JWT_AUDIENCE: "com.medicalbox.app",
    JWT_SECRET: preserve(),
    CATALOG_ACCESS_EMAIL_ALLOWLIST: preserve(),
    GOOGLE_CLIENT_ID: preserve(),
    APPLE_CLIENT_ID: "com.medicalbox.app",
    KAKAO_APP_ID: preserve(),
    APPLE_TEAM_ID: preserve(),
    ANDROID_CERT_SHA256: preserve(),
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
      ...apiRuntimeEnv,
      PORT: "8080",
    },
  });

  const catalogSync = fn("catalog-sync", {
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
    start: "uv run --no-sync medical-box-sync all-sources",
    replicas: { [SINGAPORE]: 1 },
    deploy: {
      cronSchedule: "10 18 * * *",
      restartPolicyType: "NEVER",
      restartPolicyMaxRetries: 0,
    },
    env: {
      ...catalogRuntimeEnv,
      DATA_GO_KR_SERVICE_KEY: api.env.DATA_GO_KR_SERVICE_KEY,
    },
  });

  const backend = group("Backend", [api, catalogSync, database]);

  return project("medical-box", {
    resources: [backend],
  });
});
