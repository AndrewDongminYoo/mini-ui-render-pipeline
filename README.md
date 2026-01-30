# Mini UI Render Pipeline

> **에이피알 앱 개발 직무 과제**
> UI 트리 구조와 상태 변경 이벤트를 처리하여 증분 업데이트를 수행하는 렌더링 파이프라인

A Dart library that processes UI tree structures and state change events to determine structure changes, layout recomputation, and paint order. This is an educational implementation of a UI rendering system similar to frameworks like Flutter, focusing on **dirty flag optimization** and **incremental updates**.

---

## 📋 목차

- [프로젝트 개요](#-프로젝트-개요)
- [핵심 기능](#-핵심-기능)
- [요구사항](#-요구사항)
- [빠른 시작](#-빠른-시작)
- [아키텍처](#️-아키텍처)
- [입출력 형식](#-입출력-형식)
- [설계 결정](#-설계-결정)
- [개발 가이드](#️-개발-가이드)
- [테스트](#-테스트)
- [문서](#-문서)

---

## 🎯 프로젝트 개요

### 배경

이 프로젝트는 **UI 렌더링 시스템의 핵심 개념**을 구현하는 교육용 프로젝트입니다. Flutter, React 등의 현대 UI 프레임워크에서 사용되는 **Dirty Flag 패턴**과 **증분 업데이트** 전략을 Dart로 구현했습니다.

### 목적

주어진 UI 트리 구조와 상태 변경 이벤트를 처리하여 다음을 결정합니다:

1. **Structure Change** (`recomputeStructure`): 트리 구조가 변경된 노드 목록
2. **Layout Recompute** (`recomputeLayout`): 레이아웃 재계산이 필요한 노드 목록
3. **Paint Order** (`paintOrder`): 최종 렌더링 순서

### 핵심 가치

- ✅ **증분 업데이트**: 변경된 부분만 재계산 (전체 트리 재계산 회피)
- ✅ **결정성**: 동일 입력 → 동일 출력 보장
- ✅ **명확성**: 설계 결정의 근거를 문서화
- ✅ **테스트 가능성**: 217개 테스트로 검증된 구현

---

## ✨ 핵심 기능

### Event-Driven Architecture

```diagram
[이벤트 발생] → [변경 감지] → [Dirty 전파] → [재계산] → [Paint Order 생성]
```

### 주요 기능

- 🎯 **6가지 이벤트 타입**: setSize, setPosition, setState, addChild, removeChild, moveChild
- 🔍 **No-op Detection**: 동일 값 설정 시 재계산 건너뛰기
- 🌳 **4가지 노드 타입**: Box, Row, Column, Stack
- 🔄 **Cascading Updates**: 자식 변경이 부모에 자동 전파
- 📊 **JSON I/O**: 표준 JSON 형식 입출력
- 🖥️ **CLI 도구**: 커맨드라인 인터페이스 제공
- ✅ **217개 테스트**: 완전한 테스트 커버리지

---

## 📝 요구사항

### 기능 요구사항 (Functional Requirements)

| ID   | 요구사항                 | 구현 상태 |
| ---- | ------------------------ | --------- |
| FR-1 | 트리 구조 모델링         | ✅        |
| FR-2 | 이벤트 입력 처리         | ✅        |
| FR-3 | Dirty 기반 증분 업데이트 | ✅        |
| FR-4 | 결과 JSON 출력           | ✅        |
| FR-5 | CLI 실행 진입점          | ✅        |

### 비기능 요구사항 (Non-Functional Requirements)

| ID    | 요구사항    | 구현 상태 |
| ----- | ----------- | --------- |
| NFR-1 | 결정성      | ✅        |
| NFR-2 | 부분 재계산 | ✅        |
| NFR-3 | 순수 Dart   | ✅        |
| NFR-4 | 문서화      | ✅        |

### 지원 노드 타입

| 타입     | 설명      | 레이아웃 규칙                            |
| -------- | --------- | ---------------------------------------- |
| `Box`    | 리프 노드 | 명시적 고정 크기                         |
| `Row`    | 가로 배치 | 너비 = Σ자식 너비, 높이 = max(자식 높이) |
| `Column` | 세로 배치 | 너비 = max(자식 너비), 높이 = Σ자식 높이 |
| `Stack`  | 겹침 배치 | 너비/높이 = max(자식)                    |

### 지원 이벤트 타입

| 타입          | 설명             | 영향 범위                  |
| ------------- | ---------------- | -------------------------- |
| `setSize`     | 노드 크기 변경   | Layout: 본인 + 부모 + 형제 |
| `setPosition` | 노드 위치 변경   | Layout: 본인               |
| `setState`    | 커스텀 상태 변경 | Layout: 본인               |
| `addChild`    | 자식 노드 추가   | Structure + Layout         |
| `removeChild` | 자식 노드 제거   | Structure + Layout         |
| `moveChild`   | 자식 노드 이동   | Structure + Layout         |

---

## 🚀 빠른 시작

### 설치

#### 프로젝트 클론

```bash
git clone https://github.com/AndrewDongminYoo/apr-app-assignment.git
cd apr-app-assignment
dart pub get
```

#### derry 스크립트 사용 (권장)

```bash
# Bootstrap (의존성 설치 + 코드 생성)
derry bootstrap

# 테스트 실행
derry test

# 코드 포맷팅
derry format
```

### CLI 사용

```bash
# 파일에서 읽기, stdout으로 출력
dart run bin/main.dart example/input_example.json

# 파일에서 읽고 파일로 쓰기
dart run bin/main.dart -i input.json -o output.json

# stdin에서 읽기
cat input.json | dart run bin/main.dart -o output.json

# 도움말 보기
dart run bin/main.dart --help

# 버전 확인
dart run bin/main.dart --version
```

### 라이브러리로 사용

```dart
import 'package:mini_ui/render_pipeline.dart';
import 'dart:convert';

void main() {
  final pipeline = RenderPipeline();

  final inputJson = jsonEncode({
    'tree': {
      'root': 'R',
      'nodes': {
        'R': {'type': 'Row', 'children': ['A', 'B']},
        'A': {'type': 'Box', 'size': {'w': 50, 'h': 20}},
        'B': {'type': 'Box', 'size': {'w': 30, 'h': 20}},
      },
    },
    'events': [
      {
        'type': 'setSize',
        'target': 'A',
        'newSize': {'w': 100, 'h': 30},
      },
    ],
  });

  final outputJson = pipeline.processJson(inputJson);
  final results = jsonDecode(outputJson) as List;

  print('Event 0 결과:');
  print('  recomputeLayout: ${results[0]['recomputeLayout']}');
  print('  paintOrder: ${results[0]['paintOrder']}');
}
```

---

## 🏗️ 아키텍처

### 시스템 구조

```diagram
┌──────────────────────────────────────────┐
│           RenderPipeline                 │
├──────────────────────────────────────────┤
│┌──────────┐  ┌──────────┐  ┌──────────┐  │
││ Parser   │─→│ NodeTree │─→│ Engine   │  │
│└──────────┘  └──────────┘  └──────────┘  │
│                    ↓             ↓       │
│              ┌──────────┐  ┌──────────┐  │
│              │Scheduler │─→│Calculator│  │
│              └──────────┘  └──────────┘  │
│                    ↓                     │
│              ┌──────────┐                │
│              │ Renderer │                │
│              └──────────┘                │
└──────────────────────────────────────────┘
```

### 모듈 책임

| 모듈               | 책임                                      |
| ------------------ | ----------------------------------------- |
| `JsonParser`       | JSON 입력 파싱, 트리 + 이벤트 생성        |
| `NodeTree`         | 트리 구조 관리, 노드 검색/추가/삭제, 순회 |
| `Engine`           | 이벤트 적용, 변경 감지, Dirty 전파        |
| `Scheduler`        | Dirty 노드 수집, 재계산 순서 결정         |
| `LayoutCalculator` | 노드 타입별 레이아웃 계산                 |
| `Renderer`         | EventResult 생성, JSON 직렬화             |
| `RenderPipeline`   | 전체 파이프라인 통합, Cascading 업데이트  |

### 데이터 플로우

```diagram
[JSON Input]
    ↓
[Parser] → 트리 구조 + 이벤트 리스트
    ↓
[For each event]
    ↓
[Engine] → 이벤트 처리, Dirty 표시
    ↓
[Scheduler] → Dirty 노드 수집
    ↓
[Calculator] → 레이아웃 재계산 (Fixed-point iteration)
    ↓
[Renderer] → 결과 생성
    ↓
[JSON Output]
```

---

## 📊 입출력 형식

### 입력 JSON

```json
{
  "tree": {
    "root": "R",
    "nodes": {
      "R": {
        "type": "Row",
        "children": ["A", "B"]
      },
      "A": {
        "type": "Box",
        "size": { "w": 50, "h": 20 }
      },
      "B": {
        "type": "Box",
        "size": { "w": 30, "h": 20 }
      }
    }
  },
  "events": [
    {
      "type": "setSize",
      "target": "A",
      "newSize": { "w": 60, "h": 20 }
    }
  ]
}
```

### 출력 JSON

```json
[
  {
    "afterEvent": 0,
    "recomputeStructure": [],
    "recomputeLayout": ["A", "R", "B"],
    "paintOrder": ["R", "A", "B"]
  }
]
```

### 출력 필드 설명

- **`afterEvent`**: 이벤트 인덱스 (0부터 시작)
- **`recomputeStructure`**: 트리 구조가 변경된 노드 ID 목록
- **`recomputeLayout`**: 레이아웃 재계산이 필요한 노드 ID 목록 (순서 보장)
- **`paintOrder`**: Pre-order DFS 순서로 렌더링할 노드 ID 목록

---

## 🎨 설계 결정

### 1. Two-Tier Dirty Flags

**결정**: `structureDirty`와 `layoutDirty` 두 가지 플래그 사용

```dart
abstract class Node {
  bool structureDirty = false;  // 트리 구조 변경
  bool layoutDirty = false;     // 레이아웃 재계산 필요
}
```

**근거**: 구조 변경(addChild)과 속성 변경(setSize)의 영향 범위가 다르기 때문

**효과**:

- ✅ 구조 변경과 속성 변경을 명확히 구분
- ✅ 불필요한 재계산 방지
- ✅ 결과 리스트 생성 단순화

### 2. No-op Detection

**결정**: 이벤트 처리 전 변경 감지 단계에서 no-op 검출

```dart
void _processSetSize(SetSizeEvent event) {
  final node = tree.findNode(event.targetId);

  // No-op detection
  if (node.size == event.newSize) {
    return; // 변경 없음, Dirty 표시 건너뛰기
  }

  // 실제 변경 처리
  node.size = event.newSize;
  _markDirty(node);
}
```

**예시**:

```jsonc
// Event 0: 동일한 크기 설정
{
  "type": "setSize",
  "target": "A",
  "newSize": { "w": 50, "h": 20 }  // 현재 크기와 동일
}

// 결과: 변경 없음
{
  "afterEvent": 0,
  "recomputeStructure": [],
  "recomputeLayout": [],  // 비어있음!
  "paintOrder": ["R", "A", "B"]
}
```

**효과**:

- ✅ 불필요한 Dirty 전파 방지
- ✅ 성능 최적화
- ✅ 출력 정확성 보장

### 3. recomputeLayout 순서 규칙

**결정**: 직접 타겟 → 부모들 → 형제들 순서

```diagram
이벤트 타겟 (A) → 부모 방향 (R) → 형제 (B)
```

**예시**:

```diagram
트리 구조:
R (Row)
├── A (Box, 50×20)  ← setSize 타겟
└── B (Box, 30×20)

Event: setSize(A, {w:60, h:20})

Dirty 전파:
1. A.layoutDirty = true    (직접 변경)
2. R.layoutDirty = true    (부모: Row 너비 재계산)
3. B.layoutDirty = true    (형제: 위치 재배치)

결과: recomputeLayout = ["A", "R", "B"]
       ↑직접  ↑부모  ↑형제
```

**효과**:

- ✅ 영향 전파 순서와 일치
- ✅ 직관적인 결과 해석
- ✅ 디버깅 용이

### 4. Cascading Layout Updates

**결정**: Fixed-point iteration으로 연쇄 레이아웃 업데이트 처리

```dart
void _recalculateLayoutsCascading(NodeTree tree, Scheduler scheduler) {
  const maxIterations = 10;
  int iteration = 0;

  while (iteration < maxIterations) {
    final updated = scheduler.recalculateDirtyLayouts();
    if (updated.isEmpty) break;  // 수렴

    // 부모 노드들을 다음 iteration을 위해 Dirty 표시
    for (final nodeId in updated) {
      final node = tree.findNode(nodeId);
      node?.parent?.markLayoutDirty();
    }

    iteration++;
  }
}
```

**효과**:

- ✅ 중첩 구조에서 레이아웃 정확성 보장
- ✅ 무한 루프 방지 (maxIterations)
- ✅ 단순한 로직 구조

### 5. Pre-order DFS for Paint Order

**결정**: 부모 → 자식 순서로 paintOrder 생성

```diagram
트리:
R
├── A
│   ├── A1
│   └── A2
└── B

Paint Order: [R, A, A1, A2, B]
             ↑부모 먼저, 자식은 나중에
```

**근거**: 일반적인 렌더링 시스템에서 부모가 먼저 그려진 후 자식이 그려짐

---

## 🛠️ 개발 가이드

### 프로젝트 구조

```diagram
lib/
├── src/
│   ├── core/                 # 핵심 로직
│   │   ├── node_tree.dart    # 트리 관리
│   │   ├── engine.dart       # 이벤트 처리
│   │   ├── scheduler.dart    # 스케줄링
│   │   └── renderer.dart     # 결과 생성
│   ├── models/               # 데이터 모델
│   │   ├── node.dart         # Node 계층 (Box, Row, Column, Stack)
│   │   ├── event.dart        # Event 타입들
│   │   └── result.dart       # EventResult
│   ├── layout/               # 레이아웃 계산
│   │   └── calculator.dart
│   ├── parser/               # 입출력 변환
│   │   └── json_parser.dart
│   └── render_pipeline.dart  # Public API
└── render_pipeline.dart      # 라이브러리 진입점

bin/
└── main.dart                 # CLI 도구

test/
├── models/                   # 모델 단위 테스트
├── core/                     # 핵심 로직 단위 테스트
├── layout/                   # 레이아웃 단위 테스트
├── parser/                   # 파서 단위 테스트
├── integration/              # 통합 테스트
└── validation/               # PLAN.md 검증 테스트

example/
├── simple_example.dart       # 기본 사용 예시
├── complex_example.dart      # 복잡한 예시
└── input_example.json        # 샘플 입력 파일
```

### derry 스크립트

```bash
# Bootstrap: 의존성 설치 + 코드 생성
derry bootstrap

# 테스트 실행
derry test

# 코드 포맷팅
derry format

# 코드 생성 (build_runner)
derry generate

# 커버리지 확인
derry coverage
```

### 개발 워크플로우

1. **기능 개발**

   ```bash
   # 브랜치 생성
   git checkout -b feature/new-feature

   # 코드 작성
   # ...

   # 포맷팅
   derry format

   # 테스트
   derry test
   ```

2. **테스트 작성**

   ```bash
   # 특정 테스트 실행
   dart test test/path/to/test.dart

   # 상세 출력
   dart test --reporter=expanded
   ```

3. **커밋**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

---

## ✅ 테스트

### 테스트 현황

| 모듈             | 테스트 수 | 상태            |
| ---------------- | --------- | --------------- |
| Node Model       | 25        | ✅ PASSING      |
| NodeTree         | 19        | ✅ PASSING      |
| Event Model      | 34        | ✅ PASSING      |
| Engine           | 28        | ✅ PASSING      |
| LayoutCalculator | 22        | ✅ PASSING      |
| Scheduler        | 17        | ✅ PASSING      |
| Renderer         | 15        | ✅ PASSING      |
| JSON Parser      | 31        | ✅ PASSING      |
| RenderPipeline   | 13        | ✅ PASSING      |
| CLI              | 11        | ✅ PASSING      |
| PLAN Validation  | 2         | ✅ PASSING      |
| **TOTAL**        | **217**   | **ALL PASSING** |

### 테스트 실행

```bash
# 전체 테스트
derry test

# 특정 테스트 파일
dart test test/core/engine_test.dart

# 상세 출력
dart test --reporter=expanded

# 커버리지
derry coverage
```

### 주요 테스트 케이스

1. **No-op Detection**: 동일 값 설정 시 재계산 건너뛰기
2. **Dirty Propagation**: 이벤트별 Dirty 전파 규칙 검증
3. **Layout Calculation**: 노드 타입별 레이아웃 계산 정확성
4. **Cascading Updates**: 연쇄 업데이트 수렴 검증
5. **recomputeLayout Order**: PLAN.md 요구사항 준수 확인

---

## 📚 문서

### 주요 문서

- **[PLAN.md](PLAN.md)**: 전체 프로젝트 계획 및 요구사항 정의
- **[DESIGN.md](docs/DESIGN.md)**: 상세 설계 문서 (1,140줄, 13개 다이어그램)
- **[CLAUDE.md](CLAUDE.md)**: Claude Code를 위한 프로젝트 가이드
- **[CHANGELOG.md](CHANGELOG.md)**: 버전 히스토리

### DESIGN.md 주요 내용

1. **시스템 아키텍처**: Mermaid 다이어그램으로 시각화
2. **핵심 설계 결정**: 5가지 주요 설계 선택과 근거
3. **Dirty Flag 패턴**: 이벤트별 전파 규칙 상세
4. **데이터 플로우**: 시퀀스 다이어그램 포함
5. **클래스 설계**: Node/Event 계층 구조
6. **레이아웃 계산**: 노드 타입별 알고리즘
7. **설계 트레이드오프**: 4가지 주요 선택지 분석
8. **구현 세부사항**: 핵심 코드 설명

### 예제 파일

- `example/simple_example.dart`: 기본 사용 예시
- `example/complex_example.dart`: 복잡한 트리 구조 예시
- `example/input_example.json`: 샘플 입력 파일

---

## 🔍 예제 실행

### Simple Example

```bash
dart run example/simple_example.dart
```

**출력**:

```log
=== Mini UI Render Pipeline Example ===

Event 0: Resize Box A
─────────────────────────────────
recomputeLayout: [A, R, B]
paintOrder: [R, A, B]
```

### Complex Example

```bash
dart run example/complex_example.dart
```

**출력**:

```log
=== Complex UI Layout Example ===

Initial Tree Structure:
App [Column]
├── Header [Row]
│   ├── Logo [Box] (100x50)
│   └── Nav [Row]
│       ├── NavItem1 [Box] (80x30)
│       └── NavItem2 [Box] (80x30)
└── Body [Column]
    ├── Content [Box] (300x400)
    └── Footer [Box] (300x50)

Event 0: Resize Logo
─────────────────────────────────
Layout dirty: [Logo, Header, App, Nav]
```

---

## 📄 라이선스

MIT License - 교육 목적으로 자유롭게 사용 가능

---

## 🙏 감사의 글

이 프로젝트는 다음에서 영감을 받았습니다:

- **Flutter Rendering Pipeline**: 레이아웃 계산 및 Dirty Flag 패턴
- **React Fiber**: 증분 업데이트 및 스케줄링 개념
- **APR Corporation**: 프로젝트 기회 제공

---

**작성자**: Claude Sonnet 4.5 & Dongmin Yu
**작성일**: 2026-01-29
**버전**: 1.0.0
