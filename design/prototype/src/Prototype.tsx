import { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import {
  ArchiveIcon,
  BellIcon,
  CameraIcon,
  CheckCircledIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ClockIcon,
  Cross2Icon,
  EyeNoneIcon,
  ExitIcon,
  GearIcon,
  LockClosedIcon,
  MagnifyingGlassIcon,
  Pencil2Icon,
  PersonIcon,
  PlusIcon,
  Share2Icon,
  TrashIcon,
} from "@radix-ui/react-icons";
import {
  BottomSheet,
  Carousel,
  FlowStack,
  KeyboardInput,
  MobileScroll,
  type FlowControls,
  type FlowScreen,
} from "./mobile";
import { MedicineChestUI } from "./MedicineChestUI";

type PouchTone = "mint" | "blush" | "blue";
type ContainerId = "shared" | string;
type InventoryKind = "medicine" | "firstAid";

const medicineReadinessAreas = [
  "열·통증",
  "감기·기침",
  "알레르기",
  "소화·제산",
  "설사·수분",
  "멀미·구토",
  "눈·코 관리",
  "구강·인후",
  "피부·벌레",
  "근육·관절",
  "기타",
];

const firstAidReadinessAreas = [
  "상처 관리",
  "소독·세정",
  "체온·냉찜질",
  "보호·도구",
  "기타",
];

type InventoryItem = {
  id: string;
  name: string;
  category: string;
  kind?: InventoryKind;
  meta: string;
  state: "ok" | "soon" | "low";
  note: string;
  official?: {
    itemSeq: string;
    appearance: string;
    identification: string;
    useMethod: string;
    source: string;
    updatedAt: string;
  };
};

type FamilyMember = {
  id: string;
  name: string;
  tone: PouchTone;
  items: InventoryItem[];
};

type KitContextValue = {
  sharedItems: InventoryItem[];
  members: FamilyMember[];
  addMember: (name: string) => void;
  renameMember: (memberId: string, name: string) => void;
  removeMember: (memberId: string) => void;
  saveItem: (containerId: ContainerId, item: InventoryItem) => void;
  deleteItem: (containerId: ContainerId, itemId: string) => void;
};

type AuthContextValue = {
  signIn: () => void;
  signOut: () => void;
};

const KitContext = createContext<KitContextValue | null>(null);
const AuthContext = createContext<AuthContextValue | null>(null);
const pouchTones: PouchTone[] = ["mint", "blush", "blue"];

const initialSharedItems: InventoryItem[] = [
  {
    id: "shared-pain",
    name: "타이레놀정500밀리그램",
    category: "열·통증",
    meta: "2026.08까지",
    state: "soon",
    note: "",
    official: {
      itemSeq: "200000001",
      appearance: "제품 허가정보의 성상·외형 설명이 여기에 표시됩니다.",
      identification: "모양 · 색상 · 앞면/뒷면 식별문자",
      useMethod: "e약은요 원문의 사용 방법을 변경 없이 표시합니다.",
      source: "식품의약품안전처 의약품 허가정보 · e약은요 · 낱알식별",
      updatedAt: "2026-07-25",
    },
  },
  {
    id: "shared-pain-2",
    name: "이지엔6 이브",
    category: "열·통증",
    meta: "2026.08까지",
    state: "soon",
    note: "",
  },
  {
    id: "shared-enzyme",
    name: "베아제정",
    category: "소화·제산",
    meta: "상태 양호",
    state: "ok",
    note: "",
  },
  {
    id: "shared-ointment",
    name: "후시딘연고",
    category: "피부·벌레",
    meta: "상태 양호",
    state: "ok",
    note: "",
  },
];

const initialMembers: FamilyMember[] = [
  {
    id: "hajun",
    name: "나",
    tone: "mint",
    items: [
      {
        id: "hajun-allergy",
        name: "알레르기 처방약",
        category: "다음 진료 준비",
        meta: "8월 12일 방문 예정",
        state: "ok",
        note: "진료 전 처방전과 약 봉투 확인",
      },
      {
        id: "hajun-thermometer",
        name: "어린이 체온계",
        category: "개인 용품",
        meta: "배터리 확인 완료",
        state: "ok",
        note: "",
      },
    ],
  },
  {
    id: "minseo",
    name: "엄마",
    tone: "blush",
    items: [
      {
        id: "minseo-ointment",
        name: "피부 연고",
        category: "개인 용품",
        meta: "2027.01까지",
        state: "ok",
        note: "",
      },
    ],
  },
  {
    id: "youngsoo",
    name: "아이",
    tone: "blue",
    items: [
      {
        id: "youngsoo-eye-drops",
        name: "인공눈물",
        category: "개인 용품",
        meta: "보관 상태 확인됨",
        state: "ok",
        note: "",
      },
    ],
  },
];

function useKit() {
  const context = useContext(KitContext);
  if (!context) throw new Error("useKit must be used inside KitContext.");
  return context;
}

function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthContext.");
  return context;
}

export default function Prototype() {
  const [sharedItems, setSharedItems] = useState(initialSharedItems);
  const [members, setMembers] = useState(initialMembers);
  const initial = useMemo<FlowScreen>(() => createWelcomeScreen(), []);

  const value = useMemo<KitContextValue>(
    () => ({
      sharedItems,
      members,
      addMember: (name) => {
        setMembers((current) =>
          current.length >= 10
            ? current
            : [
                ...current,
                {
                  id: `member-${Date.now()}`,
                  name,
                  tone: pouchTones[current.length % pouchTones.length],
                  items: [],
                },
              ],
        );
      },
      renameMember: (memberId, name) => {
        setMembers((current) =>
          current.map((member) => (member.id === memberId ? { ...member, name } : member)),
        );
      },
      removeMember: (memberId) => {
        setMembers((current) => current.filter((member) => member.id !== memberId));
      },
      saveItem: (containerId, item) => {
        const upsert = (items: InventoryItem[]) =>
          items.some((current) => current.id === item.id)
            ? items.map((current) => (current.id === item.id ? item : current))
            : [...items, item];

        if (containerId === "shared") {
          setSharedItems(upsert);
          return;
        }
        setMembers((current) =>
          current.map((member) =>
            member.id === containerId ? { ...member, items: upsert(member.items) } : member,
          ),
        );
      },
      deleteItem: (containerId, itemId) => {
        if (containerId === "shared") {
          setSharedItems((current) => current.filter((item) => item.id !== itemId));
          return;
        }
        setMembers((current) =>
          current.map((member) =>
            member.id === containerId
              ? { ...member, items: member.items.filter((item) => item.id !== itemId) }
              : member,
          ),
        );
      },
    }),
    [members, sharedItems],
  );

  return (
    <KitContext.Provider value={value}>
      <PrototypeFlow initial={initial} />
    </KitContext.Provider>
  );
}

function PrototypeFlow({ initial }: { initial: FlowScreen }) {
  const [authenticated, setAuthenticated] = useState(false);
  const auth = useMemo<AuthContextValue>(
    () => ({
      signIn: () => setAuthenticated(true),
      signOut: () => setAuthenticated(false),
    }),
    [],
  );

  return (
    <AuthContext.Provider value={auth}>
      <FlowStack initial={authenticated ? createHomeScreen() : initial} />
    </AuthContext.Provider>
  );
}

function createWelcomeScreen(): FlowScreen {
  return {
    id: "welcome",
    render: (flow) => <WelcomeScreen flow={flow} />,
  };
}

function createLoginScreen(): FlowScreen {
  return {
    id: "login",
    headerHeight: 58,
    header: (flow) => <ScreenHeader title="가입 또는 로그인" flow={flow} />,
    render: (flow) => <LoginScreen flow={flow} />,
  };
}

function createHomeScreen(): FlowScreen {
  return {
    id: "home",
    footerHeight: 72,
    footer: (flow) => <HomeBottomNavigation flow={flow} />,
    render: (flow) => <HomeScreen flow={flow} />,
  };
}

function WelcomeScreen({ flow }: { flow: FlowControls }) {
  return (
    <MobileScroll className="app-screen">
      <main className="access-screen" data-testid="welcome-screen">
        <span className="access-kicker">
          <LockClosedIcon />
          회원 전용 보관함
        </span>
        <section className="access-hero">
          <span className="access-kit-mark">
            <ArchiveIcon />
          </span>
          <div>
            <h1>우리 집 약을,<br />꺼내 보기 쉽게.</h1>
            <p>
              앱을 사용하려면 계정이 필요해요. 가족·보관약·메모는 로그인 후에도 이 기기의 암호화
              보관함에만 저장합니다.
            </p>
          </div>
        </section>
        <section className="access-principles" aria-label="계정과 개인정보 원칙">
          <div>
            <CheckCircledIcon />
            <span><strong>기본 기능은 무료</strong><small>의약품 수나 안전정보를 제한하지 않아요.</small></span>
          </div>
          <div>
            <EyeNoneIcon />
            <span><strong>건강정보는 광고에 사용하지 않음</strong><small>초기 광고는 비개인화 배너만 허용해요.</small></span>
          </div>
        </section>
        <button className="primary-cta" onClick={() => flow.push(createLoginScreen())}>
          가입 또는 로그인하고 시작
          <ChevronRightIcon />
        </button>
      </main>
    </MobileScroll>
  );
}

function LoginScreen({ flow }: { flow: FlowControls }) {
  const { signIn } = useAuth();
  const [termsAccepted, setTermsAccepted] = useState(false);
  const complete = () => {
    if (!termsAccepted) return;
    signIn();
    flow.replace(createHomeScreen());
  };

  return (
    <MobileScroll className="app-screen">
      <main className="access-screen access-screen--login" data-testid="login-screen">
        <section className="login-heading">
          <span className="access-kit-mark access-kit-mark--small"><LockClosedIcon /></span>
          <h1>안전한 보관함을 열어볼까요?</h1>
          <p>계정은 앱 접근과 구매 권한 복원에 사용하고, 개인 보관 데이터는 서버로 보내지 않아요.</p>
        </section>
        <label className="terms-check">
          <input
            type="checkbox"
            checked={termsAccepted}
            onChange={(event) => setTermsAccepted(event.target.checked)}
          />
          <span>
            <strong>이용약관과 개인정보 처리방침에 동의합니다</strong>
            <small>계정을 만들기 전에 필수 문서를 확인해 주세요.</small>
          </span>
        </label>
        <section className="provider-buttons" aria-label="소셜 계정 선택">
          <button disabled={!termsAccepted} onClick={complete}><span>K</span>카카오로 계속</button>
          <button disabled={!termsAccepted} onClick={complete}><span>G</span>Google로 계속</button>
          <button disabled={!termsAccepted} onClick={complete}><span></span>Apple로 계속</button>
        </section>
        <p className="access-footnote">
          로그인하지 않으면 홈, 의약품 검색, 사진 자동인식, 보관함에 접근할 수 없어요.
        </p>
      </main>
    </MobileScroll>
  );
}

function createInventoryScreen(): FlowScreen {
  return {
    id: "inventory",
    headerHeight: 58,
    header: (flow) => <ScreenHeader title="공용 트레이" flow={flow} />,
    render: (flow) => <InventoryScreen flow={flow} />,
  };
}

function createItemEditorScreen(
  containerId: ContainerId,
  itemId?: string,
  initialCategory?: string,
  initialKind?: InventoryKind,
): FlowScreen {
  return {
    id: `item-editor-${containerId}-${itemId ?? "new"}-${initialCategory ?? "default"}-${
      initialKind ?? "medicine"
    }`,
    headerHeight: 58,
    header: (flow) => <ScreenHeader title={itemId ? "물품 편집" : "물품 추가"} flow={flow} />,
    render: (flow) => (
      <ItemEditorScreen
        flow={flow}
        containerId={containerId}
        itemId={itemId}
        initialCategory={initialCategory}
        initialKind={initialKind}
      />
    ),
  };
}

function createItemDetailScreen(containerId: ContainerId, itemId: string): FlowScreen {
  return {
    id: `item-detail-${containerId}-${itemId}`,
    headerHeight: 58,
    header: (flow) => <ScreenHeader title="의약품 상세" flow={flow} />,
    render: (flow) => <ItemDetailScreen flow={flow} containerId={containerId} itemId={itemId} />,
  };
}

function createPouchScreen(memberId: string): FlowScreen {
  return {
    id: `pouch-${memberId}`,
    headerHeight: 58,
    header: (flow) => <PouchHeader flow={flow} memberId={memberId} />,
    render: (flow) => <PouchScreen flow={flow} memberId={memberId} />,
  };
}

function createSettingsScreen(): FlowScreen {
  return {
    id: "settings",
    headerHeight: 58,
    header: (flow) => <ScreenHeader title="설정" flow={flow} />,
    render: (flow) => <SettingsScreen flow={flow} />,
  };
}

function createRemindersScreen(): FlowScreen {
  return {
    id: "reminders",
    headerHeight: 58,
    header: (flow) => <ScreenHeader title="알림" flow={flow} />,
    render: () => (
      <MobileScroll className="app-screen">
        <main className="sub-screen reminder-screen">
          <section className="empty-inventory">
            <BellIcon />
            <strong>예약된 알림이 없어요</strong>
            <small>의약품 상세에서 사용기한 알림을 추가할 수 있어요.</small>
          </section>
        </main>
      </MobileScroll>
    ),
  };
}

function HomeBottomNavigation({ flow }: { flow: FlowControls }) {
  return (
    <nav className="home-bottom-navigation" aria-label="주요 메뉴">
      <button className="is-active" type="button" aria-current="page">
        <ArchiveIcon />
        <span>홈</span>
      </button>
      <button type="button" onClick={() => flow.push(createRemindersScreen())}>
        <BellIcon />
        <span>알림</span>
      </button>
      <button type="button" onClick={() => flow.push(createSettingsScreen())}>
        <GearIcon />
        <span>설정</span>
      </button>
    </nav>
  );
}

function HomeScreen({ flow }: { flow: FlowControls }) {
  const { addMember, members, removeMember, renameMember, sharedItems } = useKit();
  const [activeContainerId, setActiveContainerId] = useState<ContainerId>("shared");
  const [memberSheet, setMemberSheet] = useState<"add" | string | null>(null);
  const [draftName, setDraftName] = useState("");
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [kitOpen, setKitOpen] = useState(false);
  const activeMember = members.find((member) => member.id === activeContainerId);
  const sheetMember =
    memberSheet && memberSheet !== "add"
      ? members.find((member) => member.id === memberSheet)
      : undefined;
  const activeItems = activeMember?.items ?? sharedItems;
  const attentionCount = activeItems.filter((item) => item.state === "soon").length;
  const activeContainerName = activeMember ? `${activeMember.name} 개인 파우치` : "공용 구급상자";

  const openAddMember = () => {
    setDraftName("");
    setConfirmingDelete(false);
    setMemberSheet("add");
  };

  const openEditMember = (member: FamilyMember) => {
    setDraftName(member.name);
    setConfirmingDelete(false);
    setMemberSheet(member.id);
  };

  const closeMemberSheet = () => {
    setMemberSheet(null);
    setDraftName("");
    setConfirmingDelete(false);
  };

  const saveMember = () => {
    const name = draftName.trim();
    if (!name) return;
    if (sheetMember) renameMember(sheetMember.id, name);
    else addMember(name);
    closeMemberSheet();
  };

  return (
    <MobileScroll className="app-screen">
      <main className="home-screen home-screen--storage-surface" data-testid="home-screen">
        <section className="home-heading">
          <h1>우리집 구급상자</h1>
        </section>

        <MedicineChestUI
          open={kitOpen}
          name={activeContainerName}
          items={activeItems}
          reviewCount={attentionCount}
          showReadinessGuide={activeContainerId === "shared"}
          onToggle={() => setKitOpen((current) => !current)}
          onItemSelect={(itemId) =>
            flow.push(createItemDetailScreen(activeContainerId, itemId))
          }
          onAdd={(suggestedCategory, suggestedKind) =>
            flow.push(
              createItemEditorScreen(
                activeContainerId,
                undefined,
                suggestedCategory,
                suggestedKind,
              ),
            )
          }
          tabs={
            <div className="cabinet-scope-rail" role="tablist" aria-label="보관함 선택">
              <button
                className={activeContainerId === "shared" ? "is-active" : ""}
                role="tab"
                aria-selected={activeContainerId === "shared"}
                onClick={() => setActiveContainerId("shared")}
              >
                공용
              </button>
              {members.map((member) => (
                <button
                  className={activeContainerId === member.id ? "is-active" : ""}
                  role="tab"
                  aria-selected={activeContainerId === member.id}
                  onClick={() => setActiveContainerId(member.id)}
                  key={member.id}
                >
                  {member.name}
                </button>
              ))}
              <button
                className="cabinet-scope-manage"
                onClick={() => (activeMember ? openEditMember(activeMember) : openAddMember())}
                aria-label={activeMember ? `${activeMember.name} 구성원 편집` : "가족 구성원 추가"}
              >
                <PersonIcon />
                <PlusIcon />
              </button>
            </div>
          }
        />
      </main>

      <BottomSheet
        open={memberSheet !== null}
        onOpenChange={(open) => {
          if (!open) closeMemberSheet();
        }}
        title={sheetMember ? "가족 구성원 편집" : "가족 구성원 추가"}
        description="이름과 파우치 내용은 이 기기 안에만 저장돼요."
        snap={0.54}
      >
        <div className="member-sheet">
          <label>
            <span>이름</span>
            <KeyboardInput
              value={draftName}
              onChange={(event) => setDraftName(event.target.value)}
              placeholder="예: 엄마"
              aria-label="가족 구성원 이름"
            />
          </label>
          <button className="primary-cta primary-cta--compact" disabled={!draftName.trim()} onClick={saveMember}>
            {sheetMember ? "이름 저장" : "파우치 만들기"}
          </button>
          {sheetMember ? (
            <>
              {confirmingDelete ? (
                <p className="delete-warning">파우치 안의 의약품도 이 기기에서 함께 삭제돼요.</p>
              ) : null}
              <button
                className={`danger-cta ${confirmingDelete ? "danger-cta--armed" : ""}`}
                onClick={() => {
                  if (!confirmingDelete) {
                    setConfirmingDelete(true);
                    return;
                  }
                  removeMember(sheetMember.id);
                  setActiveContainerId("shared");
                  closeMemberSheet();
                }}
              >
                <TrashIcon />
                {confirmingDelete ? "정말 삭제" : "구성원과 파우치 삭제"}
              </button>
            </>
          ) : null}
        </div>
      </BottomSheet>
    </MobileScroll>
  );
}

function LegacyHomeScreen({ flow }: { flow: FlowControls }) {
  const { addMember, members, removeMember, renameMember, sharedItems } = useKit();
  const [activeContainerId, setActiveContainerId] = useState<ContainerId>("shared");
  const [memberSheet, setMemberSheet] = useState<"add" | string | null>(null);
  const [draftName, setDraftName] = useState("");
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [kitOpen, setKitOpen] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  const [shareStatus, setShareStatus] = useState("");
  const [includePrivateNotes, setIncludePrivateNotes] = useState(false);
  const activeMember = members.find((member) => member.id === activeContainerId);
  const sheetMember =
    memberSheet && memberSheet !== "add"
      ? members.find((member) => member.id === memberSheet)
      : undefined;
  const activeItems = activeMember?.items ?? sharedItems;
  const attentionCount = activeItems.filter((item) => item.state === "soon").length;
  const activeContainerName = activeMember ? `${activeMember.name} 개인 파우치` : "공용 트레이";
  const shareText = buildPrototypeShareText(activeContainerName, activeItems, includePrivateNotes);
  const openActiveContainer = () => {
    if (activeMember) {
      flow.push(createPouchScreen(activeMember.id));
      return;
    }
    flow.push(createInventoryScreen());
  };

  const openAddMember = () => {
    setDraftName("");
    setConfirmingDelete(false);
    setMemberSheet("add");
  };

  const openEditMember = (member: FamilyMember) => {
    setDraftName(member.name);
    setConfirmingDelete(false);
    setMemberSheet(member.id);
  };

  const closeMemberSheet = () => {
    setMemberSheet(null);
    setDraftName("");
    setConfirmingDelete(false);
  };

  const saveMember = () => {
    const name = draftName.trim();
    if (!name) return;
    if (sheetMember) renameMember(sheetMember.id, name);
    else addMember(name);
    closeMemberSheet();
  };

  const openShare = () => {
    setShareStatus("");
    setShareOpen(true);
  };

  const handOffShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: `우리집 구급키트 · ${activeContainerName}`,
          text: shareText,
        });
        setShareStatus("공유 앱으로 전달했어요.");
        return;
      } catch {
        // The user can cancel the native share sheet without changing data.
      }
    }
    try {
      await navigator.clipboard.writeText(shareText);
      setShareStatus("문자에 붙여넣을 내용을 복사했어요.");
    } catch {
      setShareStatus("아래 미리보기를 길게 눌러 복사해 주세요.");
    }
  };

  return (
    <MobileScroll className="app-screen">
      <main className="home-screen" data-testid="home-screen">
        <section className="home-heading">
          <div>
            <h1>우리집 구급키트</h1>
            <time dateTime="2026-07-25">2026. 07. 25</time>
          </div>
          <span className="home-heading-actions">
            <button onClick={openShare} aria-label={`${activeContainerName} 공유`}>
              <Share2Icon />
            </button>
            <button onClick={() => flow.push(createSettingsScreen())} aria-label="설정 열기">
              <GearIcon />
            </button>
          </span>
        </section>

        <Carousel
          className="home-tab-carousel"
          contentClassName="home-tab-rail"
          ariaLabel="보관함 선택"
        >
          <button
            className={`home-tab ${activeContainerId === "shared" ? "home-tab--active" : ""}`}
            role="tab"
            aria-selected={activeContainerId === "shared"}
            onClick={() => setActiveContainerId("shared")}
          >
            <ArchiveIcon />
            <span>
              <strong>공용</strong>
              <small>{sharedItems.length}종</small>
            </span>
          </button>
          {members.map((member) => (
            <button
              className={`home-tab home-tab--${member.tone} ${
                activeContainerId === member.id ? "home-tab--active" : ""
              }`}
              role="tab"
              aria-selected={activeContainerId === member.id}
              onClick={() => setActiveContainerId(member.id)}
              key={member.id}
            >
              <PersonIcon />
              <span>
                <strong>{member.name}</strong>
                <small>{member.items.length}종</small>
              </span>
            </button>
          ))}
          <button className="home-tab home-tab--add" onClick={openAddMember} aria-label="가족 구성원 추가">
            <PlusIcon />
            <span>
              <strong>추가</strong>
              <small>파우치</small>
            </span>
          </button>
        </Carousel>

        {attentionCount ? (
          <>
            <h2 className="section-title">{activeMember ? `${activeMember.name} 파우치` : "확인할 내용"}</h2>
            <section className="attention-list" aria-label="오늘 확인할 항목">
              <button className="attention-card" onClick={openActiveContainer}>
                <span className="attention-icon attention-icon--sand">
                  <ClockIcon />
                </span>
                <span className="attention-copy">
                  <strong>{activeMember ? "진료·갱신 준비" : "유통기한 임박"}</strong>
                  <small>{attentionCount}개 항목 확인 필요</small>
                </span>
                <ChevronRightIcon className="chevron" />
              </button>
            </section>
          </>
        ) : null}

        <PrototypeBannerAd placement="홈 점검 요약 아래" />

        {activeMember ? (
          <section className={`tabbed-pouch-panel tabbed-pouch-panel--${activeMember.tone}`}>
            <div className="tabbed-pouch-heading">
              <span className="tabbed-pouch-icon">
                <PersonIcon />
              </span>
              <div>
                <small>기기 안에서만</small>
                <strong>{activeMember.name}의 개인 파우치</strong>
              </div>
              <button onClick={() => openEditMember(activeMember)} aria-label={`${activeMember.name} 구성원 편집`}>
                <Pencil2Icon />
              </button>
            </div>
            <div className="tabbed-pouch-items">
              {activeMember.items.length ? (
                activeMember.items.slice(0, 3).map((item) => (
                  <button
                    className="tabbed-pouch-item"
                    onClick={() => flow.push(createItemEditorScreen(activeMember.id, item.id))}
                    key={item.id}
                  >
                    <span>
                      <strong>{item.name}</strong>
                      <small>{item.meta}</small>
                    </span>
                    <ChevronRightIcon />
                  </button>
                ))
              ) : (
                <button
                  className="tabbed-pouch-empty"
                  onClick={() => flow.push(createItemEditorScreen(activeMember.id))}
                >
                  <PlusIcon />
                  첫 의약품을 추가해 주세요
                </button>
              )}
            </div>
            {activeMember.items.length ? (
              <div className="tabbed-pouch-actions">
                <button onClick={() => flow.push(createItemEditorScreen(activeMember.id))}>
                  <PlusIcon />
                  의약품 추가
                </button>
                <button onClick={() => flow.push(createPouchScreen(activeMember.id))}>
                  전체 파우치 열기
                  <ChevronRightIcon />
                </button>
              </div>
            ) : null}
          </section>
        ) : (
          <section className={`kit-card ${kitOpen ? "kit-card--open" : ""}`} aria-label="공용 의약품 구급상자">
            <MedicineChestUI
              open={kitOpen}
              items={sharedItems}
              onToggle={() => setKitOpen((current) => !current)}
              onItemSelect={(itemId) => flow.push(createItemEditorScreen("shared", itemId))}
              onAdd={() => flow.push(createItemEditorScreen("shared"))}
              onShowAll={() => flow.push(createInventoryScreen())}
            />
          </section>
        )}

        <p className="safety-note">의약품 정보는 보관과 확인을 돕기 위한 참고 자료예요.</p>
      </main>

      <BottomSheet
        open={memberSheet !== null}
        onOpenChange={(open) => {
          if (!open) closeMemberSheet();
        }}
        title={sheetMember ? "가족 구성원 편집" : "가족 구성원 추가"}
        description="이름과 파우치 내용은 이 기기 안에만 저장돼요."
        snap={0.54}
      >
        <div className="member-sheet">
          <label>
            <span>이름</span>
            <KeyboardInput
              value={draftName}
              onChange={(event) => setDraftName(event.target.value)}
              placeholder="예: 엄마"
              aria-label="가족 구성원 이름"
            />
          </label>
          <button className="primary-cta primary-cta--compact" disabled={!draftName.trim()} onClick={saveMember}>
            {sheetMember ? "이름 저장" : "파우치 만들기"}
          </button>
          {sheetMember ? (
            <>
              {confirmingDelete ? (
                <p className="delete-warning">파우치 안의 의약품도 이 기기에서 함께 삭제돼요.</p>
              ) : null}
              <button
                className={`danger-cta ${confirmingDelete ? "danger-cta--armed" : ""}`}
                onClick={() => {
                  if (!confirmingDelete) {
                    setConfirmingDelete(true);
                    return;
                  }
                  removeMember(sheetMember.id);
                  setActiveContainerId("shared");
                  closeMemberSheet();
                }}
              >
                <TrashIcon />
                {confirmingDelete ? "정말 삭제" : "구성원과 파우치 삭제"}
              </button>
            </>
          ) : null}
        </div>
      </BottomSheet>
      <BottomSheet
        open={shareOpen}
        onOpenChange={setShareOpen}
        title="공유 전에 확인해 주세요"
        description="제품명·사용기한·공식 링크를 기본으로 포함하고 기기에서 미리 보여드려요."
        snap={0.68}
      >
        <div className="share-sheet">
          <div className="share-options">
            <label>
              <span>
                <strong>개인 메모도 포함</strong>
                <small>민감할 수 있어 기본적으로 제외해요.</small>
              </span>
              <input
                type="checkbox"
                checked={includePrivateNotes}
                onChange={(event) => setIncludePrivateNotes(event.target.checked)}
              />
            </label>
          </div>
          <div className="share-preview" aria-label="공유 내용 미리보기">
            <small>미리보기</small>
            <pre>{shareText}</pre>
          </div>
          {shareStatus ? <p className="share-status">{shareStatus}</p> : null}
          <button className="primary-cta primary-cta--compact" onClick={handOffShare}>
            <Share2Icon />
            문자·공유 앱 열기
          </button>
        </div>
      </BottomSheet>
    </MobileScroll>
  );
}

function buildPrototypeShareText(
  containerName: string,
  items: InventoryItem[],
  includePrivateNotes: boolean,
) {
  const lines = [`우리집 구급키트 · ${containerName}`, "공유 전에 선택한 정보만 포함했어요.", ""];
  if (!items.length) lines.push("등록된 의약품이 없어요.");
  items.forEach((item) => {
    lines.push(`• ${item.name}`);
    lines.push(`  사용기한·상태: ${item.meta || "미입력"}`);
    if (includePrivateNotes && item.note) lines.push(`  개인 메모: ${item.note}`);
    if (item.official?.itemSeq) {
      lines.push(
        `  공식 제품 정보: https://medicalbox.outoftokens.ai/api/v1/drugs/${item.official.itemSeq}`,
      );
    }
  });
  lines.push("", "응급 상황이나 의학적 판단이 필요한 경우 의료기관 또는 약사에게 문의하세요.");
  return lines.join("\n");
}

type MedicineCategory = "digestive" | "wound" | "other";

function medicineCategory(item: InventoryItem): MedicineCategory {
  if (item.category === "소화") return "digestive";
  if (item.category === "상처 관리") return "wound";
  return "other";
}

function MedicineChest3D({
  open,
  items,
  onToggle,
  onItemSelect,
}: {
  open: boolean;
  items: InventoryItem[];
  onToggle: () => void;
  onItemSelect: (itemId: string) => void;
}) {
  const hostRef = useRef<HTMLDivElement>(null);
  const openRef = useRef(open);
  const toggleRef = useRef(onToggle);
  const itemSelectRef = useRef(onItemSelect);
  const itemKey = items
    .map((item) => `${item.id}:${item.name}:${item.category}:${item.meta}`)
    .join("|");

  useEffect(() => {
    openRef.current = open;
    toggleRef.current = onToggle;
    itemSelectRef.current = onItemSelect;
  }, [onItemSelect, onToggle, open]);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 100);
    camera.position.set(5.8, 5.3, 7.4);
    camera.lookAt(0, 0.3, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFShadowMap;
    renderer.domElement.setAttribute("aria-hidden", "true");
    renderer.domElement.dataset.testid = "medicine-chest-canvas";
    host.appendChild(renderer.domElement);

    scene.add(new THREE.HemisphereLight(0xfffbef, 0x6e5b47, 2.4));
    const keyLight = new THREE.DirectionalLight(0xffffff, 3.4);
    keyLight.position.set(4, 8, 5);
    keyLight.castShadow = true;
    scene.add(keyLight);
    const rimLight = new THREE.DirectionalLight(0x9cc9eb, 1.15);
    rimLight.position.set(-5, 4, -3);
    scene.add(rimLight);

    const shellMaterial = new THREE.MeshPhysicalMaterial({
      color: 0xefe3d0,
      roughness: 0.42,
      metalness: 0.02,
      clearcoat: 0.3,
      clearcoatRoughness: 0.55,
    });
    const edgeMaterial = new THREE.MeshStandardMaterial({
      color: 0xb69d7c,
      roughness: 0.48,
    });
    const redMaterial = new THREE.MeshPhysicalMaterial({
      color: 0xdc3d32,
      roughness: 0.35,
      clearcoat: 0.45,
    });

    const addBox = (
      size: [number, number, number],
      position: [number, number, number],
      material: THREE.Material,
      parent: THREE.Object3D = scene,
    ) => {
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(...size), material);
      mesh.position.set(...position);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      parent.add(mesh);
      return mesh;
    };

    addBox([5.7, 0.52, 3.55], [0, -0.12, 0], shellMaterial);
    addBox([5.72, 0.15, 0.15], [0, 0.43, 1.72], edgeMaterial);
    addBox([5.72, 0.15, 0.15], [0, 0.43, -1.72], edgeMaterial);
    addBox([0.15, 0.58, 3.4], [-2.78, 0.28, 0], edgeMaterial);
    addBox([0.15, 0.58, 3.4], [2.78, 0.28, 0], edgeMaterial);
    addBox([5.35, 0.45, 0.12], [0, 0.28, -0.5], edgeMaterial);
    addBox([5.35, 0.45, 0.12], [0, 0.28, 0.68], edgeMaterial);

    const compartmentMaterials = {
      digestive: new THREE.MeshPhysicalMaterial({ color: 0xf9f3e8, roughness: 0.55 }),
      wound: new THREE.MeshPhysicalMaterial({ color: 0xf2cfc4, roughness: 0.55 }),
      other: new THREE.MeshPhysicalMaterial({ color: 0xc6d9e9, roughness: 0.55 }),
    };
    addBox([5.2, 0.18, 0.98], [0, 0.22, -1.1], compartmentMaterials.digestive);
    addBox([5.2, 0.18, 0.98], [0, 0.22, 0.09], compartmentMaterials.wound);
    addBox([5.2, 0.18, 0.84], [0, 0.22, 1.18], compartmentMaterials.other);

    const lidPivot = new THREE.Group();
    lidPivot.position.set(0, 0.52, -1.72);
    scene.add(lidPivot);
    addBox([5.9, 0.28, 3.65], [0, 0, 1.82], shellMaterial, lidPivot);
    addBox([0.72, 0.15, 1.75], [0, 0.2, 1.82], redMaterial, lidPivot);
    addBox([1.75, 0.15, 0.72], [0, 0.2, 1.82], redMaterial, lidPivot);
    addBox([1.4, 0.24, 0.24], [-1.55, 0.05, 0], edgeMaterial);
    addBox([1.4, 0.24, 0.24], [1.55, 0.05, 0], edgeMaterial);

    const itemStage = new THREE.Group();
    scene.add(itemStage);
    const interactiveMeshes: THREE.Object3D[] = [];
    const textures: THREE.Texture[] = [];
    const visibleItems = items.slice(0, 8);
    const groupedItems: Record<MedicineCategory, InventoryItem[]> = {
      digestive: visibleItems.filter((item) => medicineCategory(item) === "digestive"),
      wound: visibleItems.filter((item) => medicineCategory(item) === "wound"),
      other: visibleItems.filter((item) => medicineCategory(item) === "other"),
    };
    const categoryZ: Record<MedicineCategory, number> = {
      digestive: -1.1,
      wound: 0.09,
      other: 1.18,
    };

    const tagItem = (object: THREE.Object3D, itemId: string) => {
      object.traverse((child) => {
        child.userData.itemId = itemId;
        interactiveMeshes.push(child);
      });
    };

    const createLabel = (item: InventoryItem) => {
      const canvas = document.createElement("canvas");
      canvas.width = 512;
      canvas.height = 160;
      const context = canvas.getContext("2d");
      if (!context) return null;
      context.fillStyle = "rgba(255, 253, 248, 0.94)";
      context.fillRect(0, 0, canvas.width, canvas.height);
      context.strokeStyle = "rgba(97, 76, 54, 0.22)";
      context.lineWidth = 4;
      context.strokeRect(2, 2, canvas.width - 4, canvas.height - 4);
      context.fillStyle = "#403b35";
      context.font = "700 40px -apple-system, BlinkMacSystemFont, sans-serif";
      const shortName = item.name.length > 12 ? `${item.name.slice(0, 11)}…` : item.name;
      context.fillText(shortName, 24, 66);
      context.fillStyle = "#786f65";
      context.font = "600 29px -apple-system, BlinkMacSystemFont, sans-serif";
      context.fillText(item.meta || item.category, 24, 119);
      const texture = new THREE.CanvasTexture(canvas);
      texture.colorSpace = THREE.SRGBColorSpace;
      textures.push(texture);
      const sprite = new THREE.Sprite(
        new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false }),
      );
      sprite.scale.set(1.48, 0.46, 1);
      sprite.position.set(0, 1.28, 0);
      sprite.renderOrder = 5;
      return sprite;
    };

    const addMedicineVisual = (item: InventoryItem, parent: THREE.Group) => {
      const name = item.name;
      const paperMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xfffdf8,
        roughness: 0.68,
      });
      const blushMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xeabfb2,
        roughness: 0.55,
      });
      const blueMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xaecce1,
        roughness: 0.55,
      });
      const bottleMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xd9b77f,
        roughness: 0.35,
        transmission: 0.03,
      });

      if (name.includes("거즈")) {
        const roll = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.34, 0.9, 24), paperMaterial);
        roll.rotation.z = Math.PI / 2;
        roll.position.y = 0.72;
        roll.castShadow = true;
        parent.add(roll);
      } else if (name.includes("밴드")) {
        addBox([0.9, 0.72, 0.48], [0, 0.66, 0], blushMaterial, parent);
        addBox([0.5, 0.04, 0.14], [0, 1.04, 0.08], paperMaterial, parent).rotation.y = -0.18;
      } else if (name.includes("티슈") || name.includes("소독")) {
        const pack = addBox([0.96, 0.52, 0.42], [0, 0.55, 0], blueMaterial, parent);
        pack.rotation.y = -0.08;
        addBox([0.46, 0.04, 0.2], [0, 0.83, 0], paperMaterial, parent);
      } else {
        const body = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.38, 0.82, 28), bottleMaterial);
        body.position.y = 0.72;
        body.castShadow = true;
        parent.add(body);
        const bottleLabel = new THREE.Mesh(
          new THREE.CylinderGeometry(0.385, 0.385, 0.28, 28),
          blueMaterial,
        );
        bottleLabel.position.y = 0.74;
        parent.add(bottleLabel);
        const cap = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.4, 0.2, 28), redMaterial);
        cap.position.y = 1.22;
        cap.castShadow = true;
        parent.add(cap);
      }

      const label = createLabel(item);
      if (label) parent.add(label);
      tagItem(parent, item.id);
    };

    (Object.keys(groupedItems) as MedicineCategory[]).forEach((category) => {
      const categoryItems = groupedItems[category];
      const spacing = categoryItems.length <= 1 ? 0 : Math.min(1.55, 4.2 / (categoryItems.length - 1));
      categoryItems.forEach((item, index) => {
        const itemRoot = new THREE.Group();
        const x = (index - (categoryItems.length - 1) / 2) * spacing;
        itemRoot.position.set(x, 0.24, categoryZ[category]);
        const targetScale = categoryItems.length > 3 ? 0.67 : categoryItems.length > 2 ? 0.76 : 0.86;
        itemRoot.userData.baseY = itemRoot.position.y;
        itemRoot.userData.targetScale = targetScale;
        itemRoot.userData.revealDelay = index * 0.06;
        itemRoot.scale.setScalar(openRef.current ? targetScale : 0.001);
        addMedicineVisual(item, itemRoot);
        itemStage.add(itemRoot);
      });
    });

    const ground = new THREE.Mesh(
      new THREE.PlaneGeometry(18, 14),
      new THREE.ShadowMaterial({ color: 0x563f29, opacity: 0.2 }),
    );
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -0.42;
    ground.receiveShadow = true;
    scene.add(ground);

    const raycaster = new THREE.Raycaster();
    const pointer = new THREE.Vector2();
    let pointerStart: { x: number; y: number } | null = null;
    const hitItem = (event: PointerEvent) => {
      const bounds = renderer.domElement.getBoundingClientRect();
      pointer.x = ((event.clientX - bounds.left) / bounds.width) * 2 - 1;
      pointer.y = -((event.clientY - bounds.top) / bounds.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      return raycaster
        .intersectObjects(interactiveMeshes, true)
        .find((hit) => typeof hit.object.userData.itemId === "string");
    };
    const handlePointerDown = (event: PointerEvent) => {
      pointerStart = { x: event.clientX, y: event.clientY };
    };
    const handlePointerMove = (event: PointerEvent) => {
      renderer.domElement.style.cursor =
        openRef.current && hitItem(event) ? "pointer" : "default";
    };
    const handlePointerUp = (event: PointerEvent) => {
      if (!pointerStart) return;
      const movement = Math.hypot(event.clientX - pointerStart.x, event.clientY - pointerStart.y);
      pointerStart = null;
      if (movement > 8 || !openRef.current) return;
      const hit = hitItem(event);
      const itemId = hit?.object.userData.itemId;
      if (typeof itemId === "string") itemSelectRef.current(itemId);
    };
    renderer.domElement.addEventListener("pointerdown", handlePointerDown);
    renderer.domElement.addEventListener("pointermove", handlePointerMove);
    renderer.domElement.addEventListener("pointerup", handlePointerUp);

    const resize = () => {
      const width = Math.max(1, host.clientWidth);
      const height = Math.max(1, host.clientHeight);
      renderer.setSize(width, height, false);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    };
    const resizeObserver = new ResizeObserver(resize);
    resizeObserver.observe(host);
    resize();

    let frame = 0;
    let reveal = openRef.current ? 1 : 0;
    const animate = () => {
      const openTarget = openRef.current ? 1 : 0;
      reveal += (openTarget - reveal) * 0.11;
      lidPivot.rotation.x += ((openRef.current ? -1.28 : 0) - lidPivot.rotation.x) * 0.11;
      itemStage.visible = reveal > 0.015;
      itemStage.children.forEach((itemRoot) => {
        const delay = itemRoot.userData.revealDelay as number;
        const targetScale = itemRoot.userData.targetScale as number;
        const progress = Math.max(0, Math.min(1, (reveal - delay) / Math.max(0.01, 1 - delay)));
        const eased = 1 - (1 - progress) ** 3;
        itemRoot.scale.setScalar(Math.max(0.001, targetScale * eased));
        itemRoot.position.y = (itemRoot.userData.baseY as number) - (1 - eased) * 0.32;
      });
      scene.rotation.y = Math.sin(performance.now() * 0.00035) * 0.02;
      renderer.render(scene, camera);
      frame = requestAnimationFrame(animate);
    };
    animate();

    return () => {
      cancelAnimationFrame(frame);
      resizeObserver.disconnect();
      renderer.domElement.removeEventListener("pointerdown", handlePointerDown);
      renderer.domElement.removeEventListener("pointermove", handlePointerMove);
      renderer.domElement.removeEventListener("pointerup", handlePointerUp);
      textures.forEach((texture) => texture.dispose());
      scene.traverse((object) => {
        if (object instanceof THREE.Mesh) {
          object.geometry.dispose();
          if (Array.isArray(object.material)) object.material.forEach((material) => material.dispose());
          else object.material.dispose();
        }
        if (object instanceof THREE.Sprite) object.material.dispose();
      });
      renderer.dispose();
      renderer.domElement.remove();
    };
  }, [itemKey]);

  return (
    <div
      className={`medicine-chest-3d ${open ? "medicine-chest-3d--open" : ""}`}
      ref={hostRef}
      role="group"
      aria-label={open ? `열린 공용 구급상자, 의약품 ${items.length}종이 보임` : "닫힌 공용 구급상자"}
      data-testid="medicine-chest-3d"
    >
      {!open ? (
        <button
          className="medicine-chest-open-hitarea"
          type="button"
          aria-label={`공용 구급상자 열기, 의약품 ${items.length}종`}
          onPointerDown={(event) => event.preventDefault()}
          onClick={onToggle}
        >
          <span className="visually-hidden">공용 구급상자 열기</span>
        </button>
      ) : null}
    </div>
  );
}

function InventoryScreen({ flow }: { flow: FlowControls }) {
  const { sharedItems } = useKit();

  return (
    <MobileScroll className="app-screen">
      <main className="sub-screen inventory-screen" data-testid="inventory-screen">
        <section className="progress-card">
          <span>
            <ArchiveIcon />
          </span>
          <div>
            <strong>보관약을 한눈에 확인해요</strong>
            <small>항목 전체를 누르면 이름·사용기한·메모를 편집할 수 있어요.</small>
          </div>
        </section>

        <section className="inventory-list">
          {sharedItems.map((item) => (
            <button
              className="inventory-row inventory-row--open"
              onClick={() => flow.push(createItemDetailScreen("shared", item.id))}
              aria-label={`${item.name} 상세 보기`}
              key={item.id}
            >
              <span className="inventory-copy">
                  <small>{item.category}</small>
                  <strong>{item.name}</strong>
                  <span className={`state-pill state-pill--${item.state}`}>{item.meta || "정보 없음"}</span>
              </span>
              <ChevronRightIcon />
            </button>
          ))}
          {!sharedItems.length ? (
            <div className="empty-inventory">
              <strong>공용 트레이가 비어 있어요</strong>
              <small>아래 버튼으로 첫 의약품을 등록해 주세요.</small>
            </div>
          ) : null}
        </section>

        <PrototypeBannerAd placement="보관약 목록 끝" />

        <button className="secondary-cta" onClick={() => flow.push(createItemEditorScreen("shared"))}>
          <PlusIcon />
          새 의약품 추가
        </button>
      </main>
    </MobileScroll>
  );
}

function ItemDetailScreen({
  flow,
  containerId,
  itemId,
}: {
  flow: FlowControls;
  containerId: ContainerId;
  itemId: string;
}) {
  const { members, sharedItems } = useKit();
  const items =
    containerId === "shared"
      ? sharedItems
      : members.find((member) => member.id === containerId)?.items ?? [];
  const item = items.find((candidate) => candidate.id === itemId);

  if (!item) {
    return (
      <MobileScroll className="app-screen">
        <main className="sub-screen item-detail-screen">
          <section className="empty-inventory">
            <strong>의약품을 찾을 수 없어요</strong>
            <small>이미 삭제되었거나 다른 보관함으로 이동했을 수 있어요.</small>
          </section>
        </main>
      </MobileScroll>
    );
  }

  return (
    <MobileScroll className="app-screen">
      <main className="sub-screen item-detail-screen" data-testid="item-detail-screen">
        <section className="item-detail-hero">
          <small>{item.category}</small>
          <h1>{item.name}</h1>
          <span className={`state-pill state-pill--${item.state}`}>{item.meta || "상태 미입력"}</span>
        </section>

        <section className="item-detail-section">
          <div>
            <small>보관 메모</small>
            <p>{item.note || "등록한 메모가 없어요."}</p>
          </div>
          {item.official ? (
            <div>
              <small>공식 정보</small>
              <p>{item.official.appearance}</p>
              <p>{item.official.source} · 갱신 {item.official.updatedAt}</p>
            </div>
          ) : null}
        </section>

        <button
          className="secondary-cta"
          onClick={() => flow.push(createItemEditorScreen(containerId, item.id))}
        >
          <Pencil2Icon />
          수정
        </button>
      </main>
    </MobileScroll>
  );
}

function ItemEditorScreen({
  flow,
  containerId,
  itemId,
  initialCategory,
  initialKind,
}: {
  flow: FlowControls;
  containerId: ContainerId;
  itemId?: string;
  initialCategory?: string;
  initialKind?: InventoryKind;
}) {
  const { deleteItem, members, saveItem, sharedItems } = useKit();
  const items =
    containerId === "shared"
      ? sharedItems
      : members.find((member) => member.id === containerId)?.items ?? [];
  const existing = itemId ? items.find((item) => item.id === itemId) : undefined;
  const [kind, setKind] = useState<InventoryKind>(
    existing?.kind ?? initialKind ?? "medicine",
  );
  const [name, setName] = useState(existing?.name ?? "");
  const [category, setCategory] = useState(
    existing?.category ?? initialCategory ?? "기타",
  );
  const [meta, setMeta] = useState(existing?.meta ?? "");
  const [note, setNote] = useState(existing?.note ?? "");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedOfficial, setSelectedOfficial] = useState(existing?.official);
  const [deleteArmed, setDeleteArmed] = useState(false);
  const [scannerOpen, setScannerOpen] = useState(false);
  const [scanComplete, setScanComplete] = useState(false);
  const [categorySheetOpen, setCategorySheetOpen] = useState(false);
  const categoryChoices =
    kind === "medicine" ? medicineReadinessAreas : firstAidReadinessAreas;
  const knownItems = [...sharedItems, ...members.flatMap((member) => member.items)];
  const normalizedQuery = searchQuery.trim().toLocaleLowerCase("ko");
  const searchResults =
    normalizedQuery.length < 2
      ? []
      : knownItems
          .filter((item) => item.name.toLocaleLowerCase("ko").includes(normalizedQuery))
          .filter((item, index, all) => all.findIndex((candidate) => candidate.name === item.name) === index)
          .slice(0, 4);

  const save = () => {
    const trimmedName = name.trim();
    if (!trimmedName) return;
    saveItem(containerId, {
      id: existing?.id ?? `item-${Date.now()}`,
      name: trimmedName,
      category,
      kind,
      meta: meta.trim(),
      state: existing?.state ?? "ok",
      note: note.trim(),
      official: selectedOfficial,
    });
    flow.pop();
  };

  return (
    <MobileScroll className="app-screen">
      <main className="sub-screen add-screen" data-testid="item-editor-screen">
        <button
          className="photo-scan-card"
          onClick={() => {
            setScanComplete(false);
            setScannerOpen(true);
          }}
        >
          <span><CameraIcon /></span>
          <span>
            <strong>사진으로 의약품 찾기</strong>
            <small>포장 글자를 기기에서 읽고 공식 데이터 후보를 보여드려요.</small>
          </span>
          <ChevronRightIcon />
        </button>
        <label className="search-field">
          <MagnifyingGlassIcon />
          <KeyboardInput
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            placeholder="제품명 또는 품목기준코드 검색"
            aria-label="의약품 검색"
          />
        </label>
        <p className="field-help">검색 결과는 계정과 연결하지 않으며 검색 기록도 저장하지 않아요.</p>
        {searchResults.length ? (
          <section className="search-results" aria-label="의약품 검색 결과">
            {searchResults.map((result) => (
              <button
                key={result.id}
                onClick={() => {
                  setName(result.name);
                  setCategory(result.category);
                  setMeta(result.meta);
                  setSelectedOfficial(result.official);
                  setSearchQuery("");
                }}
              >
                <span>
                  <strong>{result.name}</strong>
                  <small>{result.meta || result.category}</small>
                </span>
                <ChevronRightIcon />
              </button>
            ))}
          </section>
        ) : null}

        {selectedOfficial ? (
          <section className="official-drug-card" aria-label="공식 의약품 정보">
            <div className="official-drug-heading">
              <span>
                <MagnifyingGlassIcon />
              </span>
              <div>
                <small>품목기준코드 {selectedOfficial.itemSeq}</small>
                <strong>공식 복용·외형 정보</strong>
              </div>
            </div>
            <dl>
              <div>
                <dt>성상·외형</dt>
                <dd>{selectedOfficial.appearance}</dd>
              </div>
              <div>
                <dt>낱알 식별</dt>
                <dd>{selectedOfficial.identification}</dd>
              </div>
              <div>
                <dt>사용 방법</dt>
                <dd>{selectedOfficial.useMethod}</dd>
              </div>
            </dl>
            <p>
              {selectedOfficial.source} · 갱신 {selectedOfficial.updatedAt}
            </p>
            <small className="official-disclaimer">
              프로토타입 연결 예시이며 실제 앱은 공식 원문을 표시하고 복용량을 계산하거나 치료를 추천하지 않아요.
            </small>
          </section>
        ) : null}

        <section className="form-section">
          <div>
            <span className="form-label">물품 유형</span>
            <div className="choice-row">
              {[
                { value: "medicine" as const, label: "의약품" },
                { value: "firstAid" as const, label: "구급용품" },
              ].map((choice) => (
                <button
                  className={kind === choice.value ? "selected" : ""}
                  key={choice.value}
                  onClick={() => {
                    setKind(choice.value);
                    setCategory(
                      choice.value === "medicine" ? "열·통증" : "상처 관리",
                    );
                  }}
                >
                  {choice.label}
                </button>
              ))}
            </div>
          </div>
          <label>
            <span>이름</span>
            <KeyboardInput
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder={
                kind === "medicine"
                  ? "예: 타이레놀정500밀리그램"
                  : "예: 멸균거즈 5×5cm"
              }
              aria-label={kind === "medicine" ? "의약품 이름" : "구급용품 이름"}
            />
          </label>
          <div>
            <span className="form-label">준비 영역</span>
            <button
              type="button"
              className="readiness-area-trigger"
              aria-haspopup="dialog"
              aria-expanded={categorySheetOpen}
              onClick={() => setCategorySheetOpen(true)}
            >
              <strong>{category}</strong>
              <ChevronRightIcon />
            </button>
            <small className="readiness-area-help">
              제품에 맞는 대표 영역을 제안해요. 필요하면 바꿀 수 있어요.
            </small>
          </div>
          <label>
            <span>사용기한·상태</span>
            <KeyboardInput
              value={meta}
              onChange={(event) => setMeta(event.target.value)}
              placeholder="예: 2027.05까지"
              aria-label="사용기한 또는 상태"
            />
          </label>
          <label>
            <span>메모</span>
            <KeyboardInput
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="보관할 때 기억할 내용"
              aria-label="메모"
            />
          </label>
        </section>

        <button
          className="primary-cta primary-cta--compact"
          disabled={!name.trim()}
          onClick={save}
        >
          {existing
            ? "변경사항 저장"
            : `${kind === "medicine" ? "의약품" : "구급용품"} 추가`}
        </button>
        {existing ? (
          <>
            {deleteArmed ? (
              <p className="delete-warning">이 기기의 보관함에서 삭제되며 되돌릴 수 없어요.</p>
            ) : null}
            <button
              className={`danger-cta ${deleteArmed ? "danger-cta--armed" : ""}`}
              onClick={() => {
                if (!deleteArmed) {
                  setDeleteArmed(true);
                  return;
                }
                deleteItem(containerId, existing.id);
                flow.pop();
              }}
            >
              <TrashIcon />
              {deleteArmed ? "정말 삭제" : "이 의약품 삭제"}
            </button>
          </>
        ) : null}
      </main>
      <BottomSheet
        open={categorySheetOpen}
        onOpenChange={setCategorySheetOpen}
        title="준비 영역 선택"
        description="구급상자에서 찾기 쉬운 대표 영역 하나를 선택하세요."
        snap={kind === "medicine" ? 0.72 : 0.48}
      >
        <div className="readiness-area-grid" role="listbox" aria-label="준비 영역">
          {categoryChoices.map((choice) => {
            const selected = category === choice;
            return (
              <button
                type="button"
                className={selected ? "selected" : ""}
                role="option"
                aria-selected={selected}
                key={choice}
                onClick={() => {
                  setCategory(choice);
                  setCategorySheetOpen(false);
                }}
              >
                <span>{choice}</span>
                {selected ? <CheckCircledIcon /> : null}
              </button>
            );
          })}
        </div>
      </BottomSheet>
      <BottomSheet
        open={scannerOpen}
        onOpenChange={setScannerOpen}
        title={scanComplete ? "사진에서 찾은 등록 후보" : "제품명이 보이게 촬영"}
        description={
          scanComplete
            ? "자동인식은 틀릴 수 있어요. 실제 포장의 제품명과 제조사를 확인한 뒤 선택하세요."
            : "사진은 서버에 업로드하지 않고 인식이 끝나면 임시 파일을 삭제해요."
        }
        snap={scanComplete ? 0.72 : 0.5}
      >
        {scanComplete ? (
          <div className="scan-candidates">
            <span className="scan-term">인식 문구 · 타이레놀정 500밀리그람</span>
            {[
              ["타이레놀정500밀리그람", "한국얀센 · 품목기준코드 200000001"],
              ["어린이타이레놀산160밀리그람", "한국존슨앤드존슨판매 · 품목기준코드 200000002"],
            ].map(([candidateName, detail]) => (
              <button
                key={candidateName}
                onClick={() => {
                  setName(candidateName);
                  setScannerOpen(false);
                }}
              >
                <span><strong>{candidateName}</strong><small>{detail}</small></span>
                <ChevronRightIcon />
              </button>
            ))}
            <button className="scan-manual" onClick={() => setScannerOpen(false)}>직접 검색할게요</button>
          </div>
        ) : (
          <div className="scan-start">
            <span className="scan-frame"><CameraIcon /></span>
            <p>제품명이 화면을 크게 채우도록 밝은 곳에서 정면으로 촬영해 주세요.</p>
            <button className="primary-cta primary-cta--compact" onClick={() => setScanComplete(true)}>
              촬영하고 기기에서 읽기
            </button>
          </div>
        )}
      </BottomSheet>
    </MobileScroll>
  );
}

function SettingsScreen({ flow }: { flow: FlowControls }) {
  const { signOut } = useAuth();
  const [hideMedicineNames, setHideMedicineNames] = useState(true);
  const [localReminders, setLocalReminders] = useState(true);

  return (
    <MobileScroll className="app-screen">
      <main className="sub-screen settings-screen" data-testid="settings-screen">
        <section className="settings-intro">
          <span>
            <GearIcon />
          </span>
          <div>
            <strong>설정은 별도 화면에서 관리해요</strong>
            <small>보관함 화면과 분리되어 실수로 바뀌지 않아요.</small>
          </div>
        </section>

        <h2>개인정보와 알림</h2>
        <section className="settings-group">
          <label className="settings-toggle">
            <span className="settings-row-icon">
              <EyeNoneIcon />
            </span>
            <span>
              <strong>잠금화면에서 의약품명 숨기기</strong>
              <small>일반적인 확인 문구만 표시해요.</small>
            </span>
            <input
              type="checkbox"
              checked={hideMedicineNames}
              onChange={(event) => setHideMedicineNames(event.target.checked)}
            />
          </label>
          <label className="settings-toggle">
            <span className="settings-row-icon">
              <BellIcon />
            </span>
            <span>
              <strong>알림을 기기에서만 예약</strong>
              <small>가족 이름과 의약품명은 서버로 보내지 않아요.</small>
            </span>
            <input
              type="checkbox"
              checked={localReminders}
              onChange={(event) => setLocalReminders(event.target.checked)}
            />
          </label>
        </section>

        <h2>계정</h2>
        <section className="settings-group">
          <div className="settings-static-row">
            <span className="settings-row-icon"><PersonIcon /></span>
            <span>
              <strong>무료 회원 · 비개인화 광고</strong>
              <small>구매 권한은 계정으로 복원하고 보관 데이터는 이 기기에 남아요.</small>
            </span>
            <CheckCircledIcon />
          </div>
          <button
            className="settings-link-row"
            onClick={() => {
              signOut();
              flow.replace(createWelcomeScreen());
            }}
          >
            <span><ExitIcon /> 로그아웃</span>
            <ChevronRightIcon />
          </button>
        </section>

        <h2>공유</h2>
        <section className="settings-group">
          <div className="settings-static-row">
            <span className="settings-row-icon">
              <Share2Icon />
            </span>
            <span>
              <strong>공유 전 항상 미리보기</strong>
              <small>개인 메모는 기본적으로 제외하고 사용자가 직접 선택해요.</small>
            </span>
            <CheckCircledIcon />
          </div>
        </section>

        <h2>데이터</h2>
        <section className="settings-group">
          {["암호화 백업 내보내기", ".medicalbox 백업 가져오기", "계정과 기기 데이터 삭제"].map(
            (label) => (
              <button className="settings-link-row" key={label}>
                <span>{label}</span>
                <ChevronRightIcon />
              </button>
            ),
          )}
        </section>
        <PrototypeBannerAd placement="설정 일반 정보 하단" />
        <p className="safety-note">
          가족·보관약·방문 일정·알림은 이 기기의 암호화 저장소에만 보관돼요.
        </p>
      </main>
    </MobileScroll>
  );
}

function PrototypeBannerAd({ placement }: { placement: string }) {
  return (
    <aside className="prototype-banner-ad" aria-label={`광고, ${placement}`}>
      <span>광고</span>
      <div>
        <strong>비개인화 배너 영역</strong>
        <small>건강정보·검색어·계정 식별자를 광고 요청에 사용하지 않아요.</small>
      </div>
    </aside>
  );
}

function PouchScreen({ flow, memberId }: { flow: FlowControls; memberId: string }) {
  const { members } = useKit();
  const member = members.find((entry) => entry.id === memberId);

  if (!member) {
    return (
      <MobileScroll className="app-screen">
        <main className="sub-screen empty-inventory">
          <strong>삭제된 파우치예요</strong>
          <button className="primary-cta primary-cta--compact" onClick={() => flow.replace(createHomeScreen())}>
            홈으로 돌아가기
          </button>
        </main>
      </MobileScroll>
    );
  }

  return (
    <MobileScroll className="app-screen">
      <main className="sub-screen pouch-screen" data-testid="pouch-screen">
        <section className={`pouch-hero pouch-hero--${member.tone}`}>
          <PersonIcon />
          <div>
            <small>개인 파우치</small>
            <h2>{member.name}</h2>
          </div>
          <span>{member.items.length}종</span>
        </section>

        <section className="pouch-items">
          {member.items.map((item) => (
            <button
              className="pouch-item-open"
              onClick={() => flow.push(createItemDetailScreen(member.id, item.id))}
              aria-label={`${item.name} 상세 보기`}
              key={item.id}
            >
              <div>
                <small>{item.category}</small>
                <strong>{item.name}</strong>
                <span>{item.meta || "상태 정보 없음"}</span>
              </div>
              <ChevronRightIcon />
            </button>
          ))}
          {!member.items.length ? (
            <div className="empty-inventory">
              <strong>파우치가 비어 있어요</strong>
              <small>아래 버튼으로 의약품을 추가해 주세요.</small>
            </div>
          ) : null}
        </section>

        <button className="secondary-cta" onClick={() => flow.push(createItemEditorScreen(member.id))}>
          <PlusIcon />
          파우치에 의약품 추가
        </button>
      </main>
    </MobileScroll>
  );
}

function PouchHeader({ flow, memberId }: { flow: FlowControls; memberId: string }) {
  const { members } = useKit();
  const member = members.find((entry) => entry.id === memberId);
  return <ScreenHeader title={member ? `${member.name}의 파우치` : "개인 파우치"} flow={flow} />;
}

function ScreenHeader({ title, flow }: { title: string; flow: FlowControls }) {
  return (
    <div className="screen-header">
      <button aria-label="뒤로 가기" onClick={flow.pop}>
        <ChevronLeftIcon />
      </button>
      <strong>{title}</strong>
      <span className="screen-header-spacer" aria-hidden="true" />
    </div>
  );
}
