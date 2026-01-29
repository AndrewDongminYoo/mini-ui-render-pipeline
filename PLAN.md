# Mini UI Render Pipeline - 설계 및 구현 계획

## 1. 과제 요약

UI 트리 구조와 상태 변경 이벤트를 입력받아, 각 이벤트 처리 후 다음을 판단하고 출력하는 시스템을 설계·구현합니다:

- **Structure Change**: 어떤 노드에서 구조 변경이 발생했는지
- **Layout/State Recompute**: 어떤 노드들이 재계산 대상이 되었는지
- **Paint Order**: 최종적으로 어떤 순서로 출력이 이루어지는지

---

## 2. 요구사항 상세 분석

### 2.1 Input 스펙

```json
{
  "tree": {
    "root": "노드ID",
    "nodes": {
      "노드ID": {
        "type": "Row|Column|Box|Stack|...",
        "children": ["자식노드ID", ...],  // optional
        "size": { "w": number, "h": number },  // optional
        "position": { "x": number, "y": number },  // optional
        "state": { ... }  // optional, 커스텀 상태
      }
    }
  },
  "events": [
    { "type": "이벤트타입", "target": "노드ID", ...params }
  ]
}
```

### 2.2 Output 스펙

```json
[
  {
    "afterEvent": 0,  // 이벤트 인덱스 (0-based)
    "recomputeStructure": ["노드ID", ...],  // 구조 변경된 노드
    "recomputeLayout": ["노드ID", ...],  // 레이아웃 재계산된 노드
    "paintOrder": ["노드ID", ...]  // 최종 페인트 순서
  },
  ...
]
```

### 2.3 지원할 이벤트 타입

| 이벤트 타입   | 설명                | 영향 범위                   |
| ------------- | ------------------- | --------------------------- |
| `setSize`     | 노드 크기 변경      | Layout (본인 + 부모 + 형제) |
| `setPosition` | 노드 위치 변경      | Layout (본인만)             |
| `setState`    | 커스텀 상태 변경    | Layout (본인)               |
| `addChild`    | 자식 노드 추가      | Structure + Layout          |
| `removeChild` | 자식 노드 제거      | Structure + Layout          |
| `moveChild`   | 자식 노드 순서 변경 | Structure + Layout          |

### 2.4 지원할 노드 타입

| 노드 타입 | 설명                  | 레이아웃 특성                 |
| --------- | --------------------- | ----------------------------- |
| `Box`     | 단일 박스 (리프 노드) | 고정 크기                     |
| `Row`     | 가로 방향 배치        | 자식들의 너비 합 = 본인 너비  |
| `Column`  | 세로 방향 배치        | 자식들의 높이 합 = 본인 높이  |
| `Stack`   | 겹침 배치             | 자식 중 최대 크기 = 본인 크기 |

---

## 3. 핵심 설계 결정사항

### 3.1 Dirty Flag 기반 증분 업데이트

전체 트리 재계산을 피하기 위해 Dirty Flag 패턴을 사용합니다:

```diagram
[Event 발생]
    ↓
[대상 노드에 dirty flag 설정]
    ↓
[영향 전파 규칙에 따라 관련 노드에 dirty 전파]
    ↓
[dirty 노드만 재계산]
    ↓
[dirty flag 초기화]
```

### 3.2 영향 전파 규칙

#### Size 변경 시:

1. 본인 노드: Layout dirty
2. 부모 노드: Layout dirty (부모의 크기가 자식에 의존하는 경우)
3. 형제 노드: Layout dirty (Row/Column에서 위치 재배치 필요)

#### Position 변경 시:

1. 본인 노드만: Layout dirty

#### 구조 변경 시 (addChild, removeChild, moveChild):

1. 대상 부모 노드: Structure dirty + Layout dirty
2. 추가/제거된 노드와 그 자손: Structure dirty
3. 형제 노드: Layout dirty

### 3.3 Paint Order 결정 규칙

Pre-order DFS 순회 (부모 → 자식 순서):

```diagram
R (root)
├── A (첫째 자식)
│   ├── A1
│   └── A2
└── B (둘째 자식)

Paint Order: [R, A, A1, A2, B]
```

### 3.4 최적화: Skip 조건

이벤트 처리 시 변경이 없는 경우를 감지하여 불필요한 계산 방지:

- `setSize`로 동일한 크기 설정 → 변경 없음 (예제 Case 1의 첫 번째 이벤트)
- 존재하지 않는 노드 대상 이벤트 → 에러 또는 무시

---

## 4. 아키텍처 설계

```diagram
┌─────────────────────────────────────────────────────────────┐
│                      RenderPipeline                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Parser    │───▶│  NodeTree   │───▶│   Engine    │     │
│  │ (JSON→Tree) │    │ (트리 관리)  │    │ (이벤트처리) │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                            │                   │            │
│                            ▼                   ▼            │
│                     ┌─────────────┐    ┌─────────────┐     │
│                     │    Node     │    │  Scheduler  │     │
│                     │ (노드 모델)  │    │ (계산 스케줄)│     │
│                     └─────────────┘    └─────────────┘     │
│                                               │            │
│                                               ▼            │
│                                        ┌─────────────┐     │
│                                        │  Renderer   │     │
│                                        │(결과 생성)   │     │
│                                        └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 4.1 모듈 책임

| 모듈        | 책임                                   |
| ----------- | -------------------------------------- |
| `Parser`    | JSON 입력 파싱, 트리 구조 생성         |
| `Node`      | 개별 노드 데이터 모델, dirty flag 관리 |
| `NodeTree`  | 트리 구조 관리, 노드 검색/추가/삭제    |
| `Engine`    | 이벤트 처리, dirty 전파                |
| `Scheduler` | dirty 노드 수집, 계산 순서 결정        |
| `Renderer`  | 최종 출력 JSON 생성                    |

---

## 5. 상세 구현 계획

### Phase 1: 기본 구조 (Core)

- [ ] **Task 1.1**: 프로젝트 구조 설정
  - Dart 프로젝트 초기화
  - 디렉토리 구조 생성
  - 기본 의존성 설정 (test, json_serializable 등)

- [ ] **Task 1.2**: Node 모델 구현
  - `Node` abstract class
  - `BoxNode`, `RowNode`, `ColumnNode`, `StackNode` 구현
  - dirty flag (structure, layout) 필드
  - 부모/자식 참조 관리

- [ ] **Task 1.3**: NodeTree 구현
  - 노드 추가/삭제/검색 메서드
  - 트리 순회 메서드 (DFS pre-order)
  - 부모-자식 관계 관리

### Phase 2: 이벤트 처리 (Events)

- [ ] **Task 2.1**: Event 모델 구현
  - `Event` abstract class
  - `SetSizeEvent`, `SetPositionEvent`, `SetStateEvent`
  - `AddChildEvent`, `RemoveChildEvent`, `MoveChildEvent`

- [ ] **Task 2.2**: Engine 구현
  - 이벤트 핸들러 등록/실행
  - dirty flag 전파 로직
  - 변경 감지 (no-op 처리)

- [ ] **Task 2.3**: Dirty 전파 규칙 구현
  - `propagateDirty(node, type)` 메서드
  - 각 노드 타입별 전파 규칙

### Phase 3: 레이아웃 계산 (Layout)

- [ ] **Task 3.1**: Layout Calculator 구현
  - 각 노드 타입별 레이아웃 계산 로직
  - Row: 수평 배치, 너비 합산
  - Column: 수직 배치, 높이 합산
  - Stack: 겹침 배치, 최대 크기

- [ ] **Task 3.2**: Scheduler 구현
  - dirty 노드 수집
  - 계산 순서 결정 (bottom-up for size, top-down for position)
  - 재계산 실행

### Phase 4: 출력 생성 (Output)

- [ ] **Task 4.1**: Renderer 구현
  - `recomputeStructure` 목록 생성
  - `recomputeLayout` 목록 생성
  - `paintOrder` 생성 (pre-order DFS)

- [ ] **Task 4.2**: JSON Serialization
  - 출력 JSON 포맷 생성
  - 결정론적 순서 보장

### Phase 5: 통합 및 CLI (Integration)

- [ ] **Task 5.1**: RenderPipeline 클래스 구현
  - 전체 파이프라인 orchestration
  - 입력 JSON 파싱 → 이벤트 처리 → 출력 생성

- [ ] **Task 5.2**: CLI 인터페이스
  - JSON 파일 입력 지원
  - stdin 입력 지원
  - stdout JSON 출력

### Phase 6: 테스트 및 문서화

- [ ] **Task 6.1**: 단위 테스트
  - Node 모델 테스트
  - Event 처리 테스트
  - Layout 계산 테스트

- [ ] **Task 6.2**: 통합 테스트
  - Example Case 1 검증
  - 추가 테스트 케이스 작성

- [ ] **Task 6.3**: 문서화
  - README.md 작성 (실행 방법 포함)
  - 설계 문서 작성 (다이어그램 포함)

---

## 6. 디렉토리 구조

```diagram
apr-app-assignment/
├── bin/
│   └── main.dart              # CLI 엔트리포인트
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── node.dart      # Node 모델
│   │   │   ├── event.dart     # Event 모델
│   │   │   └── result.dart    # Output 모델
│   │   ├── core/
│   │   │   ├── node_tree.dart # 트리 관리
│   │   │   ├── engine.dart    # 이벤트 처리
│   │   │   ├── scheduler.dart # 계산 스케줄링
│   │   │   └── renderer.dart  # 출력 생성
│   │   ├── layout/
│   │   │   └── calculator.dart # 레이아웃 계산
│   │   └── parser/
│   │       └── json_parser.dart # JSON 파싱
│   └── render_pipeline.dart    # Public API
├── test/
│   ├── models/
│   ├── core/
│   └── integration/
├── examples/
│   └── case1.json             # 예제 입력
├── docs/
│   └── DESIGN.md              # 설계 문서
├── pubspec.yaml
├── README.md
└── PLAN.md                    # 이 문서
```

---

## 7. 예제 케이스 분석

### Example Case 1 상세 분석

**초기 상태**:

```diagram
R (Row)
├── A (Box, 50x20)
└── B (Box, 30x20)
```

**Event 0**: `setSize(A, 50x20)` - 동일 크기 설정

- 변경 감지: 크기 동일 → **변경 없음**
- `recomputeStructure`: []
- `recomputeLayout`: []
- `paintOrder`: [R, A, B] (항상 출력)

**Event 1**: `setSize(A, 60x20)` - 크기 변경

- 변경 감지: 너비 50→60 → **변경 있음**
- A의 크기 변경 → A dirty
- A의 부모 R도 dirty (Row의 총 너비가 변경됨)
- B도 dirty (Row에서 B의 위치가 변경될 수 있음)
- `recomputeStructure`: []
- `recomputeLayout`: [A, R, B] (변경된 순서대로 또는 계산 순서대로)
- `paintOrder`: [R, A, B]

---

## 8. 설계 결정 근거

### Q1: recomputeLayout의 순서는?

**결정**: 이벤트에서 직접 영향받은 노드 우선, 그 다음 전파된 노드 순서

**근거**:

- 과제 예시에서 `["A", "R", "B"]` 순서로 출력됨
- A가 직접 변경됨 → R이 A의 부모로 영향받음 → B가 형제로 영향받음

### Q2: 부모 노드의 크기는 어떻게 계산?

**결정**: 노드 타입별 규칙 적용

- Row: 자식 너비 합, 자식 중 최대 높이
- Column: 자식 중 최대 너비, 자식 높이 합
- Stack: 자식 중 최대 너비, 자식 중 최대 높이
- Box: 명시적 크기 사용

**근거**: 일반적인 UI 프레임워크 관례 (Flutter, CSS Flexbox 등)

### Q3: Structure Change는 언제 발생?

**결정**: 트리 구조 자체가 변경될 때만

- addChild, removeChild, moveChild 이벤트
- 노드의 속성(크기, 위치) 변경은 Structure가 아닌 Layout 변경

**근거**: 과제 예시에서 setSize는 recomputeStructure가 빈 배열

---

## 9. 추가 테스트 케이스 (구현 후 검증용)

### Case 2: 구조 변경 (addChild)

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

예상 출력:

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

예상: A1 변경 → A 영향 (Row 너비 변경) → R 영향 (Column 너비 변경 가능) → A2 위치 변경

---

## 10. 일정 예상

| Phase                | 예상 소요 시간 |
| -------------------- | -------------- |
| Phase 1: Core        | 2-3시간        |
| Phase 2: Events      | 2-3시간        |
| Phase 3: Layout      | 2-3시간        |
| Phase 4: Output      | 1-2시간        |
| Phase 5: Integration | 1-2시간        |
| Phase 6: Test & Docs | 2-3시간        |
| **Total**            | **10-16시간**  |

---

## 11. 리스크 및 대응

| 리스크             | 대응 방안                                     |
| ------------------ | --------------------------------------------- |
| 요구사항 해석 오류 | 예제 케이스 철저히 분석, 불명확한 부분 문서화 |
| 복잡한 전파 규칙   | 단계별 테스트, 시각화 도구 활용               |
| 성능 이슈          | 작은 테스트 케이스부터 시작, 프로파일링       |

---

## 변경 이력

| 날짜       | 내용      |
| ---------- | --------- |
| 2025-01-29 | 초안 작성 |
