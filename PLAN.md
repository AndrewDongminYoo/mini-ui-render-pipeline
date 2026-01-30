# PLAN: Mini UI Render Pipeline 설계·구현 계획

## 1. 과제 개요

에이피알 앱 개발 직무 과제로, **UI 트리 구조 + 상태 변경 이벤트**를 입력받아 각 이벤트 처리 후 다음을 판단·출력하는 시스템을 Dart로 설계·구현한다:

- **Structure Change**: 구조 변경이 발생한 노드 목록
- **Layout Recompute**: 레이아웃 재계산 대상 노드 목록
- **Paint Order**: 최종 출력 순서

> **평가 기준**: 결과보다 **문제 정의 과정과 설계 판단 근거**를 중요하게 평가

---

## 2. 요구사항 정의

### 2.1 기능 요구사항 (Functional Requirements)

| ID   | 요구사항                 | 설명                                                                    |
| ---- | ------------------------ | ----------------------------------------------------------------------- |
| FR-1 | 트리 구조 모델링         | 노드 ID, 부모-자식 관계, 타입, 속성(size, position, state)을 표현       |
| FR-2 | 이벤트 입력 처리         | `setSize`, `setState`, `addChild`, `removeChild` 등 이벤트 순차 처리    |
| FR-3 | Dirty 기반 증분 업데이트 | 변경 영향을 받는 노드만 식별하여 부분 재계산                            |
| FR-4 | 결과 JSON 출력           | 각 이벤트 후 `recomputeStructure`, `recomputeLayout`, `paintOrder` 출력 |
| FR-5 | CLI 실행 진입점          | README 안내대로 실행 시 정상 동작                                       |

### 2.2 비기능 요구사항 (Non-Functional Requirements)

| ID    | 요구사항    | 설명                                             |
| ----- | ----------- | ------------------------------------------------ |
| NFR-1 | 결정성      | 동일 입력 → 동일 출력 (랜덤/시간 의존 로직 금지) |
| NFR-2 | 부분 재계산 | 전체 트리 매번 재계산 금지, dirty 노드만 처리    |
| NFR-3 | 순수 Dart   | Flutter/프레임워크 비의존, 라이브러리 구조       |
| NFR-4 | 문서화      | README, 설계 문서, PLAN 포함                     |

### 2.3 Input/Output 스펙

**Input:**

```json
{
  "tree": {
    "root": "R",
    "nodes": {
      "R": { "type": "Row", "children": ["A", "B"] },
      "A": { "type": "Box", "size": { "w": 50, "h": 20 } },
      "B": { "type": "Box", "size": { "w": 30, "h": 20 } }
    }
  },
  "events": [
    { "type": "setSize", "target": "A", "size": { "w": 50, "h": 20 } },
    { "type": "setSize", "target": "A", "size": { "w": 60, "h": 20 } }
  ]
}
```

**Output:**

```json
[
  {
    "afterEvent": 0,
    "recomputeStructure": [],
    "recomputeLayout": [],
    "paintOrder": ["R", "A", "B"]
  },
  {
    "afterEvent": 1,
    "recomputeStructure": [],
    "recomputeLayout": ["A", "R", "B"],
    "paintOrder": ["R", "A", "B"]
  }
]
```

### 2.4 지원 노드 타입

| 타입     | 설명             | 레이아웃 규칙                            |
| -------- | ---------------- | ---------------------------------------- |
| `Box`    | 리프 노드        | 명시적 고정 크기                         |
| `Row`    | 가로 배치        | 너비 = Σ자식 너비, 높이 = max(자식 높이) |
| `Column` | 세로 배치        | 너비 = max(자식 너비), 높이 = Σ자식 높이 |
| `Stack`  | 겹침 배치 (선택) | 너비/높이 = max(자식)                    |

### 2.5 지원 이벤트 타입

| 타입          | 설명             | 영향 범위                  |
| ------------- | ---------------- | -------------------------- |
| `setSize`     | 노드 크기 변경   | Layout: 본인 + 부모 + 형제 |
| `setState`    | 커스텀 상태 변경 | Layout: 본인               |
| `addChild`    | 자식 노드 추가   | Structure + Layout         |
| `removeChild` | 자식 노드 제거   | Structure + Layout         |

### 2.6 범위 밖 (Out of Scope)

- 실제 화면 렌더링 (paintOrder는 논리적 순서만 제공)
- Flutter 위젯/RenderObject 연동
- 복잡한 레이아웃 엔진 (Constraints, Flex factor 등)

### 2.7 가정 (Assumptions)

- 입력 JSON은 유효하며, 존재하지 않는 노드 ID 참조 없음
- 트리는 단일 루트를 가지며, 루트는 삭제되지 않음
- 노드 타입은 `Row`, `Column`, `Box` (필요시 `Stack`)로 제한

---

## 3. 예제 케이스 상세 분석

### Example Case 1 분석

**초기 트리 구조:**

```diagram
R (Row)
├── A (Box, 50×20)
└── B (Box, 30×20)
```

**Event 0: `setSize(A, {w:50, h:20})`** - 동일 값 설정

| 단계       | 동작                                                       |
| ---------- | ---------------------------------------------------------- |
| 변경 감지  | 현재 크기(50×20) == 새 크기(50×20) → **변경 없음 (No-op)** |
| Dirty 전파 | 없음                                                       |
| 재계산     | 없음                                                       |
| 결과       | `recomputeStructure: []`, `recomputeLayout: []`            |

> **핵심 인사이트**: 동일 값 설정은 no-op으로 처리하여 불필요한 재계산 방지

**Event 1: `setSize(A, {w:60, h:20})`** - 실제 크기 변경

| 단계        | 동작                                                       |
| ----------- | ---------------------------------------------------------- |
| 변경 감지   | 현재 크기(50×20) ≠ 새 크기(60×20) → **변경 있음**          |
| Dirty 전파  | A(직접 변경) → R(부모, Row 너비 영향) → B(형제, 위치 영향) |
| 재계산 순서 | A → R → B (영향 발생 순서)                                 |
| 결과        | `recomputeLayout: ["A", "R", "B"]`                         |

> **핵심 인사이트**: `recomputeLayout` 순서는 "직접 변경 노드 → 전파된 노드" 순서

---

## 4. 핵심 설계 결정

### 4.1 Dirty Flag 기반 증분 업데이트

전체 트리 재계산을 피하기 위해 Dirty Flag 패턴 적용:

```diagram
[Event 발생]
    ↓
[변경 감지: 실제 변경 여부 확인]
    ↓ (변경 있음)
[대상 노드에 dirty flag 설정]
    ↓
[영향 전파 규칙에 따라 관련 노드에 dirty 전파]
    ↓
[dirty 노드만 재계산]
    ↓
[dirty flag 초기화 + 결과 기록]
```

### 4.2 Dirty 전파 규칙

**Size 변경 시:**

1. 본인 노드: `layoutDirty = true`
2. 부모 노드: `layoutDirty = true` (부모 크기가 자식에 의존하므로)
3. 형제 노드: `layoutDirty = true` (Row/Column에서 위치 재배치 필요)

**구조 변경 시 (addChild, removeChild):**

1. 대상 부모 노드: `structureDirty = true`, `layoutDirty = true`
2. 추가/제거된 노드와 자손: `structureDirty = true`
3. 형제 노드: `layoutDirty = true`

### 4.3 레이아웃 계산 방향

2-Pass 레이아웃 패턴:

- **Size 계산**: Bottom-up (자식 → 부모)
- **Position 계산**: Top-down (부모 → 자식)

### 4.4 Paint Order 규칙

**Pre-order DFS** (부모 → 자식 순서):

```diagram
R (root)
├── A (첫째)
│   ├── A1
│   └── A2
└── B (둘째)

Paint Order: [R, A, A1, A2, B]
```

### 4.5 recomputeLayout 순서 규칙

1. 이벤트에서 직접 영향받은 노드
2. 부모 방향으로 전파된 노드
3. 형제 노드

예: A 크기 변경 → `["A", "R", "B"]`

---

## 5. 아키텍처 설계

```diagram
┌────────────────────────────────────────────────────────────┐
│                      RenderPipeline                        │
├────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Parser    │───▶│  NodeTree   │───▶│   Engine    │     │
│  │ (JSON→Tree) │    │ (트리 관리)   │    │ (이벤트 처리)  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                            │                  │            │
│                            ▼                  ▼            │
│                     ┌─────────────┐    ┌─────────────┐     │
│                     │    Node     │    │ DirtyTracker│     │
│                     │  (노드 모델)  │    │ (Dirty 관리) │     │
│                     └─────────────┘    └─────────────┘     │
│                                               │            │
│                                               ▼            │
│                     ┌─────────────┐    ┌─────────────┐     │
│                     │  Layout     │◀───│  Scheduler  │     │
│                     │ Calculator  │    │  (계산 순서)  │     │
│                     └─────────────┘    └─────────────┘     │
│                                               │            │
│                                               ▼            │
│                                        ┌─────────────┐     │
│                                        │  Renderer   │     │
│                                        │ (결과 JSON)  │     │
│                                        └─────────────┘     │
└────────────────────────────────────────────────────────────┘
```

### 모듈 책임

| 모듈               | 책임                                        |
| ------------------ | ------------------------------------------- |
| `Parser`           | JSON 입력 파싱, UiTree + `List<Event>` 생성 |
| `Node`             | 노드 데이터 모델, 속성 관리                 |
| `NodeTree`         | 트리 구조 관리, 노드 검색/추가/삭제, 순회   |
| `Engine`           | 이벤트 적용, 변경 감지                      |
| `DirtyTracker`     | dirty flag 관리, 전파 규칙 실행             |
| `Scheduler`        | dirty 노드 수집, 재계산 순서 결정           |
| `LayoutCalculator` | 노드 타입별 size/position 계산              |
| `Renderer`         | `EventResult` 생성, JSON 직렬화             |

---

## 6. 디렉토리 구조

```diagram
apr-app-assignment/
├── bin/
│   └── main.dart                  # CLI 엔트리포인트
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── node.dart          # Node 모델 (Box, Row, Column)
│   │   │   ├── event.dart         # Event 모델
│   │   │   └── result.dart        # EventResult 모델
│   │   ├── core/
│   │   │   ├── node_tree.dart     # 트리 관리
│   │   │   ├── engine.dart        # 이벤트 처리 엔진
│   │   │   ├── dirty_tracker.dart # Dirty flag 관리
│   │   │   └── scheduler.dart     # 재계산 스케줄링
│   │   ├── layout/
│   │   │   └── calculator.dart    # 레이아웃 계산
│   │   └── parser/
│   │       └── json_parser.dart   # JSON 파싱
│   └── render_pipeline.dart       # Public API
├── test/
│   ├── models/
│   ├── core/
│   └── integration/
│       └── example_case_test.dart
├── examples/
│   ├── case1.json                 # 과제 예제
│   └── case2_structure.json       # 구조 변경 예제
├── docs/
│   └── DESIGN.md                  # 설계 문서
├── pubspec.yaml
├── README.md
└── PLAN.md
```

---

## 7. 구현 태스크 체크리스트

### Phase 1: 프로젝트 세팅

- [ ] GitHub `apr-app-assignment` private 레포 생성
- [ ] `APRCORPORATION` collaborator 추가
- [ ] Dart 프로젝트 초기화 (`dart create -t console-full`)
- [ ] 디렉토리 구조 생성
- [ ] `pubspec.yaml` 의존성 설정 (test)

### Phase 2: 도메인 모델 (models/)

- [ ] `Node` abstract class 정의
  - [ ] `id`, `type`, `size`, `position`, `state` 필드
  - [ ] `structureDirty`, `layoutDirty` 플래그
- [ ] `BoxNode` 구현
- [ ] `RowNode` 구현 (children 포함)
- [ ] `ColumnNode` 구현
- [ ] `Event` abstract class 정의
- [ ] `SetSizeEvent` 구현
- [ ] `SetStateEvent` 구현
- [ ] `AddChildEvent` 구현
- [ ] `RemoveChildEvent` 구현
- [ ] `EventResult` 데이터 클래스 정의

### Phase 3: 핵심 로직 (core/)

- [ ] `NodeTree` 클래스
  - [ ] 노드 등록/조회/삭제
  - [ ] 부모-자식 관계 관리
  - [ ] Pre-order DFS 순회 메서드
- [ ] `DirtyTracker` 클래스
  - [ ] dirty 노드 추적
  - [ ] 전파 규칙 구현 (부모/형제 방향)
  - [ ] dirty 노드 목록 반환
- [ ] `Scheduler` 클래스
  - [ ] dirty 노드 수집
  - [ ] 재계산 순서 결정
- [ ] `Engine` 클래스
  - [ ] 이벤트 적용
  - [ ] **변경 감지 (no-op 처리)**
  - [ ] DirtyTracker 연동

### Phase 4: 레이아웃 계산 (layout/)

- [ ] `LayoutCalculator` 클래스
  - [ ] `Box` 레이아웃 (고정 크기)
  - [ ] `Row` 레이아웃 (수평 배치, 너비 합산)
  - [ ] `Column` 레이아웃 (수직 배치, 높이 합산)
- [ ] dirty 노드 대상 부분 재계산 로직

### Phase 5: 입출력 (parser/, renderer)

- [ ] `JsonParser` 클래스
  - [ ] JSON → `NodeTree` 변환
  - [ ] JSON → `List<Event>` 변환
- [ ] `Renderer` 클래스
  - [ ] `recomputeStructure` 목록 생성
  - [ ] `recomputeLayout` 목록 생성 (순서 보장)
  - [ ] `paintOrder` 생성 (pre-order DFS)
  - [ ] JSON 직렬화

### Phase 6: 통합 (RenderPipeline)

- [ ] `RenderPipeline` 클래스
  - [ ] 전체 파이프라인 orchestration
  - [ ] `process(jsonInput) → jsonOutput`
- [ ] `bin/main.dart` CLI 구현
  - [ ] 파일 입력 지원
  - [ ] stdin 입력 지원
  - [ ] stdout JSON 출력

### Phase 7: 테스트

- [ ] 단위 테스트
  - [ ] Node 모델 테스트
  - [ ] Event 적용 테스트
  - [ ] DirtyTracker 전파 테스트
  - [ ] LayoutCalculator 테스트
- [ ] 통합 테스트
  - [ ] **Example Case 1 검증** (과제 예제)
  - [ ] Example Case 2 (구조 변경) 검증
  - [ ] Edge case: no-op 이벤트 검증

### Phase 8: 문서화

- [ ] `README.md`
  - [ ] 프로젝트 개요
  - [ ] 실행 방법 (`dart run`, `dart test`)
  - [ ] 입출력 포맷 설명
  - [ ] 예제 실행 결과
- [ ] `docs/DESIGN.md`
  - [ ] 아키텍처 다이어그램
  - [ ] 핵심 설계 결정 및 근거
  - [ ] Dirty 전파 규칙 상세
- [ ] `PLAN.md` 최종 정리

### Phase 9: 제출 전 점검

- [ ] `dart format .` 실행
- [ ] `dart analyze` 경고 해결
- [ ] `dart test` 전체 통과
- [ ] README 절차대로 실행 검증
- [ ] 불필요한 파일 제거
- [ ] GitHub 레포 상태 확인
- [ ] 레포지토리 URL 이메일 제출

---

## 8. 추가 테스트 케이스

### Case 2: 구조 변경 (addChild)

**Input:**

```json
{
  "tree": {
    "root": "R",
    "nodes": {
      "R": { "type": "Row", "children": ["A"] },
      "A": { "type": "Box", "size": { "w": 50, "h": 20 } }
    }
  },
  "events": [
    {
      "type": "addChild",
      "target": "R",
      "child": { "id": "B", "type": "Box", "size": { "w": 30, "h": 20 } }
    }
  ]
}
```

**Expected Output:**

```json
[
  {
    "afterEvent": 0,
    "recomputeStructure": ["R", "B"],
    "recomputeLayout": ["B", "R"],
    "paintOrder": ["R", "A", "B"]
  }
]
```

### Case 3: 중첩 구조 레이아웃

**Input:**

```json
{
  "tree": {
    "root": "R",
    "nodes": {
      "R": { "type": "Column", "children": ["A", "B"] },
      "A": { "type": "Row", "children": ["A1", "A2"] },
      "A1": { "type": "Box", "size": { "w": 20, "h": 20 } },
      "A2": { "type": "Box", "size": { "w": 30, "h": 20 } },
      "B": { "type": "Box", "size": { "w": 50, "h": 30 } }
    }
  },
  "events": [
    { "type": "setSize", "target": "A1", "size": { "w": 40, "h": 20 } }
  ]
}
```

**Expected:** A1 변경 → A 영향 → R 영향 → A2 위치 변경, B 위치 변경

---

## 9. 설계 결정 근거 (Q&A)

### Q1: recomputeLayout 순서는 어떻게 결정?

**결정:** 이벤트 직접 영향 노드 → 부모 → 형제 순서

**근거:** 과제 예시 `["A", "R", "B"]`에서:

- A: 직접 변경됨
- R: A의 부모로 영향받음
- B: 형제로 위치 영향받음

### Q2: 동일 값 setSize는 어떻게 처리?

**결정:** 변경 감지 단계에서 no-op으로 처리

**근거:** 과제 예시 Event 0에서 `recomputeLayout: []`

### Q3: Structure Change는 언제 발생?

**결정:** 트리 구조 자체가 변경될 때만 (addChild, removeChild)

**근거:** 과제 예시에서 setSize는 `recomputeStructure: []`

### Q4: paintOrder는 언제 변경?

**결정:** 구조 변경 시에만 변경, 레이아웃 변경으로는 불변

**근거:** 과제 예시에서 크기 변경 후에도 paintOrder 동일

---

## 10. 일정 예상

| Phase                  | 예상 소요     |
| ---------------------- | ------------- |
| Phase 1: 프로젝트 세팅 | 30분          |
| Phase 2: 도메인 모델   | 2시간         |
| Phase 3: 핵심 로직     | 3시간         |
| Phase 4: 레이아웃 계산 | 2시간         |
| Phase 5: 입출력        | 1.5시간       |
| Phase 6: 통합          | 1시간         |
| Phase 7: 테스트        | 2시간         |
| Phase 8: 문서화        | 1.5시간       |
| Phase 9: 제출 전 점검  | 30분          |
| **Total**              | **약 14시간** |

---

## 11. 리스크 및 대응

| 리스크                    | 대응 방안                                              |
| ------------------------- | ------------------------------------------------------ |
| 요구사항 해석 오류        | 예제 케이스 철저히 분석, 불명확한 부분 가정으로 문서화 |
| Dirty 전파 규칙 복잡도    | 단계별 테스트, 예제 기반 검증                          |
| recomputeLayout 순서 오류 | 예제 출력과 정확히 일치하는지 테스트로 검증            |

---

## 12. Definition of Done

### 기능 완료 기준

- [ ] 과제 예제 입력 → 예제 출력과 동일한 JSON 생성
- [ ] 구조 변경 이벤트 (addChild) 케이스 정상 동작
- [ ] no-op 이벤트 (동일 값 설정) 시 recomputeLayout 빈 배열

### 품질 완료 기준

- [ ] dirty 기반 부분 재계산 구현 (전체 트리 재계산 아님)
- [ ] 동일 입력 → 동일 출력 결정성 보장
- [ ] `dart test` 전체 통과
- [ ] `dart analyze` 경고 없음

### 문서 완료 기준

- [ ] README.md에서 실행 방법 따라하면 정상 동작
- [ ] 설계 문서에 핵심 결정 근거 명시
- [ ] PLAN.md 포함

### 제출 완료 기준

- [ ] `apr-app-assignment` private 레포 생성
- [ ] `APRCORPORATION` collaborator 추가
- [ ] 2026년 2월 5일(목) 17:00 이전 URL 제출

---

## 변경 이력

| 날짜                 | 내용                                  |
| -------------------- | ------------------------------------- |
| 2026-01-29T08:27:23Z | OPUS 4.5의 해석 기반으로 PLAN.md 작성 |
| 2026-01-29T14:10:38Z | GPT 5.2의 DoD 반영하여 최종본 작성    |
