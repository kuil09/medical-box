import {
  ArchiveIcon,
  CheckCircledIcon,
  ChevronRightIcon,
  ChevronUpIcon,
  Cross2Icon,
  HeartIcon,
  LayersIcon,
  PlusIcon,
} from "@radix-ui/react-icons";
import type { CSSProperties, ReactNode } from "react";

type MedicineCategory =
  | "pain"
  | "cold"
  | "allergy"
  | "digestive"
  | "hydration"
  | "nausea"
  | "eyeNose"
  | "mouthThroat"
  | "skin"
  | "muscle"
  | "wound"
  | "cleaning"
  | "temperature"
  | "tools"
  | "other";

type MedicineChestItem = {
  id: string;
  name: string;
  category: string;
  meta: string;
  kind?: "medicine" | "firstAid";
  state?: "ok" | "soon" | "low";
};

type MedicineChestUIProps = {
  open: boolean;
  items: MedicineChestItem[];
  onToggle: () => void;
  onItemSelect: (itemId: string) => void;
  onAdd: (
    suggestedCategory?: string,
    suggestedKind?: "medicine" | "firstAid",
  ) => void;
  name?: string;
  reviewCount?: number;
  showReadinessGuide?: boolean;
  tabs?: ReactNode;
  onShowAll?: () => void;
};

const medicineGuide: MedicineCategory[] = [
  "pain",
  "cold",
  "allergy",
  "digestive",
  "hydration",
  "nausea",
  "eyeNose",
  "mouthThroat",
  "skin",
  "muscle",
];
const firstAidGuide: MedicineCategory[] = [
  "wound",
  "cleaning",
  "temperature",
  "tools",
];
const readinessCategories = [...medicineGuide, ...firstAidGuide];
const categoryOrder: MedicineCategory[] = [...readinessCategories, "other"];

const categoryLabels: Record<MedicineCategory, string> = {
  pain: "열·통증",
  cold: "감기·기침",
  allergy: "알레르기",
  digestive: "소화·제산",
  hydration: "설사·수분",
  nausea: "멀미·구토",
  eyeNose: "눈·코 관리",
  mouthThroat: "구강·인후",
  skin: "피부·벌레",
  muscle: "근육·관절",
  wound: "상처 관리",
  cleaning: "소독·세정",
  temperature: "체온·냉찜질",
  tools: "보호·도구",
  other: "기타",
};

function categoryFor(item: MedicineChestItem): MedicineCategory {
  if (item.category.includes("해열") || item.category.includes("통증")) return "pain";
  if (item.category.includes("감기") || item.category.includes("기침")) return "cold";
  if (item.category.includes("알레르기")) return "allergy";
  if (item.category.includes("소화")) return "digestive";
  if (item.category.includes("설사") || item.category.includes("수분")) return "hydration";
  if (item.category.includes("멀미") || item.category.includes("구토")) return "nausea";
  if (item.category.includes("눈·코") || item.category.includes("인공눈물")) {
    return "eyeNose";
  }
  if (item.category.includes("구강") || item.category.includes("인후")) {
    return "mouthThroat";
  }
  if (item.category.includes("피부") || item.category.includes("벌레")) return "skin";
  if (
    item.category.includes("근육") ||
    item.category.includes("관절") ||
    item.category.includes("파스")
  ) {
    return "muscle";
  }
  if (item.category.includes("소독") || item.category.includes("세정")) return "cleaning";
  if (item.category.includes("체온") || item.category.includes("냉찜질")) {
    return "temperature";
  }
  if (item.category.includes("보호") || item.category.includes("도구")) return "tools";
  if (item.category.includes("상처")) return "wound";
  return "other";
}

function CategoryIcon({ category }: { category: MedicineCategory }) {
  if (category === "pain") return <Cross2Icon />;
  if (category === "digestive") return <LayersIcon />;
  if (category === "wound") return <HeartIcon />;
  return <ArchiveIcon />;
}

function ReadinessGuideSection({
  title,
  categories,
  kind,
  items,
  onAdd,
}: {
  title: string;
  categories: MedicineCategory[];
  kind: "medicine" | "firstAid";
  items: MedicineChestItem[];
  onAdd: (
    suggestedCategory?: string,
    suggestedKind?: "medicine" | "firstAid",
  ) => void;
}) {
  return (
    <section className="storage-readiness-section" aria-label={`${title} 준비 항목`}>
      <strong>{title}</strong>
      <div className="storage-readiness-grid">
        {categories.map((category) => {
          const registered = items.some(
            (item) =>
              categoryFor(item) === category &&
              (item.kind ?? "medicine") === kind,
          );
          return (
            <button
              className={registered ? "is-registered" : ""}
              type="button"
              disabled={registered}
              onClick={() => onAdd(categoryLabels[category], kind)}
              aria-label={`${categoryLabels[category]}, ${
                registered ? "등록됨" : "비어 있음, 선택해서 추가"
              }`}
              key={category}
            >
              {registered ? <CheckCircledIcon /> : <PlusIcon />}
              <small>{registered ? "등록됨" : "비어 있음"}</small>
              <span>{categoryLabels[category]}</span>
            </button>
          );
        })}
      </div>
    </section>
  );
}

export function MedicineChestUI({
  open,
  items,
  onToggle,
  onItemSelect,
  onAdd,
  name = "공용 구급상자",
  reviewCount = 0,
  showReadinessGuide = false,
  tabs,
}: MedicineChestUIProps) {
  const groupedItems = categoryOrder
    .map((category) => ({
      category,
      items: items.filter((item) => categoryFor(item) === category),
    }))
    .filter((group) => group.items.length > 0);
  const readinessCount =
    medicineGuide.filter((category) =>
      items.some(
        (item) =>
          categoryFor(item) === category &&
          (item.kind ?? "medicine") === "medicine",
      ),
    ).length +
    firstAidGuide.filter((category) =>
      items.some(
        (item) =>
          categoryFor(item) === category && item.kind === "firstAid",
      ),
    ).length;

  return (
    <section
      className={`storage-cabinet ${open ? "storage-cabinet--open" : ""}`}
      role="group"
      aria-label={
        open
          ? `${name} 열림, 의약품 ${items.length}종이 보임`
          : `${name} 닫힘, 의약품 ${items.length}종 보관 중`
      }
      data-testid="medicine-chest-ui"
    >
      <div className="storage-cabinet-lid">
        <div className="storage-cabinet-lid-inner">
          {tabs ?? (
            <span className="storage-cabinet-lid-label">
              <strong>{name}</strong>
              <small>{items.length}종</small>
            </span>
          )}
        </div>
      </div>

      <div className="storage-cabinet-hinges" aria-hidden="true">
        <span />
        <span />
      </div>

      <div className="storage-cabinet-base">
        {!open ? (
          <button
            className="storage-cabinet-door"
            type="button"
            aria-expanded="false"
            onClick={onToggle}
          >
            <span className="storage-cabinet-door-mark">
              <ArchiveIcon />
            </span>
            <span>
              <small>{name}</small>
              <strong>{reviewCount > 0 ? `확인할 약 ${reviewCount}개` : "보관약 확인"}</strong>
            </span>
            <span className="storage-cabinet-open-label">열기</span>
          </button>
        ) : (
          <div className="storage-cabinet-interior">
            {showReadinessGuide ? (
              <section className="storage-readiness-map" aria-label="가정용 준비 지도">
                <div className="storage-readiness-heading">
                  <strong>가정용 준비 지도</strong>
                  <span>{readinessCount}/{readinessCategories.length} 등록</span>
                </div>
                <ReadinessGuideSection
                  title="상비약"
                  categories={medicineGuide}
                  kind="medicine"
                  items={items}
                  onAdd={onAdd}
                />
                <ReadinessGuideSection
                  title="구급용품"
                  categories={firstAidGuide}
                  kind="firstAid"
                  items={items}
                  onAdd={onAdd}
                />
              </section>
            ) : null}
            {groupedItems.length ? (
              <>
                {showReadinessGuide ? (
                  <strong className="storage-inventory-heading">보관 중인 물품</strong>
                ) : null}
              {groupedItems.map(({ category, items: categoryItems }, groupIndex) => (
                <section
                  className={`storage-compartment storage-compartment--${category}`}
                  style={{ "--group-index": groupIndex } as CSSProperties}
                  aria-label={`${categoryLabels[category]} 의약품 ${categoryItems.length}종`}
                  key={category}
                >
                  <div className="storage-compartment-label">
                    <strong>{categoryLabels[category]}</strong>
                    <CategoryIcon category={category} />
                  </div>
                  <div className="storage-compartment-items">
                    {categoryItems.map((item, itemIndex) => {
                      const needsReview = item.state === "soon";
                      return (
                        <button
                          className={`storage-medicine-row ${
                            needsReview ? "storage-medicine-row--review" : ""
                          }`}
                          style={{ "--item-index": itemIndex } as CSSProperties}
                          type="button"
                          onClick={() => onItemSelect(item.id)}
                          aria-label={`${item.name}, 상세 보기`}
                          key={item.id}
                        >
                          <span className="storage-medicine-icon">
                            <ArchiveIcon />
                          </span>
                          <span className="storage-medicine-copy">
                            <strong>{item.name}</strong>
                            <small>{needsReview ? "확인 필요" : item.meta || "상태 양호"}</small>
                          </span>
                          <ChevronRightIcon />
                        </button>
                      );
                    })}
                  </div>
                </section>
              ))}
              </>
            ) : (
              <div className="storage-cabinet-empty">
                <ArchiveIcon />
                <strong>아직 보관한 약이 없어요</strong>
              </div>
            )}

            {showReadinessGuide ? (
              <p className="storage-readiness-note">
                보건복지부와 공공 보건기관의 가정용 준비 항목 참고 · 필수 목록이
                아니며 가족 상황에 맞게 약사와 확인하세요.
              </p>
            ) : null}

            <button
              className="storage-cabinet-add"
              type="button"
              onClick={() => onAdd()}
            >
              <PlusIcon />
              물품 추가
            </button>
          </div>
        )}

        {open ? (
          <button
            className="storage-cabinet-toggle"
            type="button"
            aria-expanded="true"
            onClick={onToggle}
          >
            닫기
            <ChevronUpIcon aria-hidden="true" />
          </button>
        ) : null}
      </div>
    </section>
  );
}
