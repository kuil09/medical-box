import {
  ArchiveIcon,
  ChevronRightIcon,
  Cross2Icon,
  HeartIcon,
  LayersIcon,
  PlusIcon,
} from "@radix-ui/react-icons";
import type { CSSProperties } from "react";

type MedicineCategory = "digestive" | "wound" | "other";

type MedicineChestItem = {
  id: string;
  name: string;
  category: string;
  meta: string;
};

type MedicineChestUIProps = {
  open: boolean;
  items: MedicineChestItem[];
  onToggle: () => void;
  onItemSelect: (itemId: string) => void;
  onAdd: () => void;
  onShowAll: () => void;
};

const categoryOrder: MedicineCategory[] = ["digestive", "wound", "other"];

const categoryLabels: Record<MedicineCategory, string> = {
  digestive: "소화",
  wound: "상처 관리",
  other: "기타",
};

function categoryFor(item: MedicineChestItem): MedicineCategory {
  if (item.category === "소화") return "digestive";
  if (item.category === "상처 관리") return "wound";
  return "other";
}

function CategoryIcon({ category }: { category: MedicineCategory }) {
  if (category === "digestive") return <LayersIcon />;
  if (category === "wound") return <HeartIcon />;
  return <ArchiveIcon />;
}

export function MedicineChestUI({
  open,
  items,
  onToggle,
  onItemSelect,
  onAdd,
  onShowAll,
}: MedicineChestUIProps) {
  const groupedItems: Record<MedicineCategory, MedicineChestItem[]> = {
    digestive: items.filter((item) => categoryFor(item) === "digestive"),
    wound: items.filter((item) => categoryFor(item) === "wound"),
    other: items.filter((item) => categoryFor(item) === "other"),
  };

  return (
    <section
      className={`medicine-chest-ui ${open ? "medicine-chest-ui--open" : ""}`}
      role="group"
      aria-label={
        open
          ? `열린 공용 구급상자, 의약품 ${items.length}종이 보임`
          : `닫힌 공용 구급상자, 의약품 ${items.length}종 보관 중`
      }
      data-testid="medicine-chest-ui"
    >
      <div className="medicine-chest-stage">
        <div className="medicine-chest-cast-shadow" aria-hidden="true" />

        <button
          className="medicine-chest-lid"
          type="button"
          aria-expanded={open}
          aria-label={open ? "공용 구급상자 닫기" : `공용 구급상자 열기, 의약품 ${items.length}종`}
          onClick={onToggle}
        >
          <span className="medicine-chest-lid-front" aria-hidden={open}>
            <span className="medicine-chest-mark">
              <Cross2Icon />
            </span>
            <span className="medicine-chest-lid-copy">
              <small>HOUSEHOLD MEDICAL BOX</small>
              <strong>공용 구급상자</strong>
              <span>{items.length}종 정리됨 · 눌러서 열기</span>
            </span>
          </span>
          <span className="medicine-chest-lid-inside" aria-hidden={!open}>
            <span className="medicine-chest-inside-mark">
              <Cross2Icon />
            </span>
            <span>
              <small>공용 트레이</small>
              <strong>{items.length}종 보관 중</strong>
              <span>칸별로 꺼내고 다시 놓기 쉽게 정리했어요</span>
            </span>
          </span>
        </button>

        <div className="medicine-chest-hinges" aria-hidden="true">
          <span />
          <span />
        </div>

        <div className="medicine-chest-base">
          <div className="medicine-chest-rim">
            <div className="medicine-chest-tray" aria-hidden={!open}>
              {open
                ? categoryOrder.map((category, categoryIndex) => {
                    const categoryItems = groupedItems[category];
                    const visibleItems = categoryItems.slice(0, 3);
                    return (
                      <div
                        className={`medicine-chest-compartment medicine-chest-compartment--${category}`}
                        style={{ "--compartment-index": categoryIndex } as CSSProperties}
                        role="group"
                        aria-label={`${categoryLabels[category]} 의약품 ${categoryItems.length}종`}
                        key={category}
                      >
                        <div className="medicine-chest-compartment-label">
                          <span>
                            <CategoryIcon category={category} />
                          </span>
                          <strong>{categoryLabels[category]}</strong>
                          <small>{categoryItems.length}종</small>
                        </div>
                        <div className="medicine-chest-compartment-items">
                          {visibleItems.map((item, itemIndex) => (
                            <button
                              className="medicine-chest-item"
                              type="button"
                              style={{ "--item-index": itemIndex } as CSSProperties}
                              aria-label={`${item.name}, 편집`}
                              data-item-id={item.id}
                              onClick={() => onItemSelect(item.id)}
                              key={item.id}
                            >
                              <span>
                                <strong>{item.name}</strong>
                                <small>{item.meta || item.category}</small>
                              </span>
                              <ChevronRightIcon />
                            </button>
                          ))}
                          {!categoryItems.length ? (
                            <span className="medicine-chest-empty-slot">비어 있음</span>
                          ) : null}
                          {categoryItems.length > visibleItems.length ? (
                            <button
                              className="medicine-chest-more"
                              type="button"
                              onClick={onShowAll}
                              aria-label={`${categoryLabels[category]} 의약품 전체 보기`}
                            >
                              +{categoryItems.length - visibleItems.length}종 보기
                            </button>
                          ) : null}
                        </div>
                      </div>
                    );
                  })
                : null}
            </div>
          </div>
          <span className="medicine-chest-latch" aria-hidden="true" />
        </div>
      </div>

      <div className="medicine-chest-summary">
        <span>
          <small>{open ? `상자 안 ${items.length}종` : "공용 구급상자"}</small>
          <strong>{open ? "칸 안의 의약품을 선택하세요" : "필요할 때 열어 바로 확인해요"}</strong>
        </span>
      </div>

      <div className="medicine-chest-actions" aria-hidden={!open}>
        {open ? (
          <button type="button" onClick={onAdd}>
            <PlusIcon />
            공용 트레이에 의약품 추가
          </button>
        ) : null}
      </div>
    </section>
  );
}
